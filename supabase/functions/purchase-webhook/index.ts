import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const secret = Deno.env.get("PURCHASE_WEBHOOK_SECRET");
  const header = req.headers.get("x-webhook-secret");
  if (!secret || header !== secret) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const body = await req.json();
  const purchaseId = body.purchase_id as string | undefined;
  const provider = (body.provider as string | undefined) ?? "partner";
  const providerRef = (body.provider_ref as string | undefined) ?? "";
  const status = (body.status as string | undefined) ?? "paid";

  if (!purchaseId) {
    return new Response(JSON.stringify({ error: "purchase_id_required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const rpc = status === "failed" ? "mark_purchase_failed" : "apply_paid_purchase";
  const { error } = await supabase.rpc(rpc, {
    p_id: purchaseId,
    p_provider: provider,
    p_ref: providerRef,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
