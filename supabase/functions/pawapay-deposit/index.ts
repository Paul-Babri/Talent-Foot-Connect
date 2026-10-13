import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const xofCountries = new Set(["CIV", "SEN", "BEN", "BFA", "MLI", "TGO", "NER", "GNB"]);

const descriptions: Record<string, string> = {
  video_unit: "TalentFoot 1 video",
  pack_5: "TalentFoot 5 videos",
  pack_10: "TalentFoot 10 videos",
  pro_month: "TalentFoot PRO",
};

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Méthode refusée." }, 405);
  }

  const token = Deno.env.get("PAWAPAY_API_TOKEN");
  const base = (Deno.env.get("PAWAPAY_BASE_URL") ?? "https://api.sandbox.pawapay.io")
    .replace(/\/$/, "");
  if (!token) {
    return json({
      error: "pawaPay n'est pas configuré. Ajoute le secret PAWAPAY_API_TOKEN.",
    }, 503);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return json({ error: "Configuration Supabase incomplète." }, 500);
  }

  const authorization = req.headers.get("Authorization") ?? "";
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: "Connecte-toi pour payer." }, 401);
  }

  const body = await req.json();
  const purchaseId = body.purchaseId as string | undefined;
  const phone = body.phone as string | undefined;
  if (!purchaseId) return json({ error: "Achat introuvable." }, 400);

  const admin = createClient(supabaseUrl, serviceKey);
  const { data: purchase, error: purchaseError } = await admin
    .from("purchases")
    .select("id, player_id, sku, amount_fcfa, status, provider_ref")
    .eq("id", purchaseId)
    .maybeSingle();
  if (purchaseError || !purchase) return json({ error: "Achat introuvable." }, 404);
  if (purchase.player_id !== userData.user.id) {
    return json({ error: "Cet achat ne t'appartient pas." }, 403);
  }
  if (purchase.status === "paid") return json({ status: "paid" });
  if (purchase.status === "failed") {
    return json({ status: "failed", message: "Le paiement a été refusé." });
  }

  const depositId = (purchase.provider_ref as string | null) ?? purchase.id;
  if (!purchase.provider_ref) {
    if (!phone) return json({ error: "Numéro mobile money requis." }, 400);
    const msisdn = toMsisdn(phone);
    if (!msisdn) {
      return json({ error: "Numéro mobile money invalide." }, 400);
    }

    const predicted = await pawapay(base, token, "/v1/predict-correspondent", {
      msisdn,
    });
    if (!predicted.ok) return json({ error: predicted.error }, predicted.status);
    const correspondent = predicted.body.correspondent as string | undefined;
    const country = predicted.body.country as string | undefined;
    if (!correspondent || !country || !xofCountries.has(country)) {
      return json({
        error: "Ce numéro n'est pas un mobile money FCFA reconnu.",
      }, 400);
    }

    const initiated = await pawapay(base, token, "/deposits", {
      depositId,
      amount: String(purchase.amount_fcfa),
      currency: "XOF",
      country,
      correspondent,
      payer: { type: "MSISDN", address: { value: msisdn } },
      customerTimestamp: new Date().toISOString(),
      statementDescription: descriptions[purchase.sku as string] ?? "TalentFoot",
      metadata: [{ fieldName: "purchaseId", fieldValue: purchase.id }],
    });
    if (!initiated.ok) return json({ error: initiated.error }, initiated.status);

    const initial = String(initiated.body.status ?? "");
    if (initial === "REJECTED") {
      await admin.rpc("mark_purchase_failed", {
        p_id: purchase.id,
        p_provider: "pawapay",
        p_ref: depositId,
      });
      return json({
        status: "failed",
        message: String(
          initiated.body.rejectionReason ?? "Le paiement a été refusé.",
        ),
      });
    }

    await admin
      .from("purchases")
      .update({ provider: "pawapay", provider_ref: depositId })
      .eq("id", purchase.id);
  }

  const checked = await pawapay(base, token, `/deposits/${depositId}`);
  if (!checked.ok) return json({ error: checked.error }, checked.status);
  const row = Array.isArray(checked.body) ? checked.body[0] : checked.body;
  const status = String(row?.status ?? "ACCEPTED");

  if (status === "COMPLETED") {
    const deposited = Number(row.depositedAmount ?? row.requestedAmount ?? 0);
    if (deposited + 0.01 < Number(purchase.amount_fcfa)) {
      await admin.rpc("mark_purchase_failed", {
        p_id: purchase.id,
        p_provider: "pawapay",
        p_ref: depositId,
      });
      return json({
        status: "failed",
        message: "Le montant reçu ne correspond pas à l'offre.",
      });
    }
    const { error } = await admin.rpc("apply_paid_purchase", {
      p_id: purchase.id,
      p_provider: "pawapay",
      p_ref: depositId,
    });
    if (error) return json({ error: error.message }, 400);
    return json({ status: "paid" });
  }

  if (status === "FAILED" || status === "REJECTED") {
    await admin.rpc("mark_purchase_failed", {
      p_id: purchase.id,
      p_provider: "pawapay",
      p_ref: depositId,
    });
    return json({
      status: "failed",
      message: String(row?.failureReason ?? row?.rejectionReason ?? "Paiement refusé."),
    });
  }

  return json({
    status: "pending",
    message: "Valide la demande sur ton téléphone.",
  });
});

function toMsisdn(phone: string): string | null {
  let digits = phone.replace(/\D/g, "");
  if (digits.startsWith("00")) digits = digits.slice(2);
  if (digits.startsWith("0") && digits.length === 10) digits = `225${digits}`;
  if (digits.length < 11) return null;
  return digits;
}

async function pawapay(
  base: string,
  token: string,
  path: string,
  body?: Record<string, unknown>,
): Promise<{ ok: true; body: any; status: number } | { ok: false; error: string; status: number }> {
  const response = await fetch(`${base}${path}`, {
    method: body ? "POST" : "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      ...(body ? { "Content-Type": "application/json" } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = payload?.errorMessage ?? payload?.message ?? "pawaPay a refusé la demande.";
    return { ok: false, error: String(message), status: response.status };
  }
  return { ok: true, body: payload, status: response.status };
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
