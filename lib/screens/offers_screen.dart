import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/billing/offers.dart';
import 'package:talent_foot_connect/services/purchase_service.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final _purchases = PurchaseService();
  Offer? _busy;

  Future<String?> _askPhone() async {
    final controller = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Mobile money',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '07 00 00 00 00',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Payer'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return phone;
  }

  Future<void> _buy(Offer offer) async {
    final phone = await _askPhone();
    if (phone == null || phone.trim().isEmpty || !mounted) return;

    setState(() => _busy = offer);
    try {
      final purchase = await _purchases.createPending(offer);
      var payment = await _purchases.payWithPawapay(
        purchaseId: purchase.id,
        phone: phone.trim(),
      );
      for (var attempt = 0; attempt < 20 && payment.pending && mounted; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        payment = await _purchases.refreshPawapay(purchase.id);
      }
      if (!mounted) return;
      if (payment.paid) {
        await showAppSuccess(
          context,
          title: 'Paiement confirmé',
          message: '${offer.title} est activé sur ton compte.',
        );
      } else if (payment.failed) {
        await showAppError(
          context,
          payment.message ?? 'Le paiement a été refusé.',
        );
      } else {
        await showAppSuccess(
          context,
          title: 'Paiement en attente',
          message:
              'Valide la demande sur ton téléphone. '
              'L\'offre sera activée dès que le paiement est confirmé.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'OFFRES',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Le pack gratuit inclut 3 vidéos et 10 photos. Les offres se paient par mobile money (Orange, MTN, Wave) via pawaPay.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          for (final offer in offers) ...[
            _OfferCard(
              offer: offer,
              loading: _busy == offer,
              onTap: _busy == null ? () => _buy(offer) : null,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.loading,
    required this.onTap,
  });

  final Offer offer;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pro = offer.sku == OfferSku.proMonth;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: pro ? AppColors.orange : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.detail,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      offer.priceLabel,
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mint,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
