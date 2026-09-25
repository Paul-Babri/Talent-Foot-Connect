import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/services/admin_service.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = AdminService();
  late Future<_AdminData> _future = _load();

  Future<_AdminData> _load() async {
    final kpis = await _admin.kpis();
    final players = await _admin.players();
    final purchases = await _admin.purchases();
    return _AdminData(kpis: kpis, players: players, purchases: purchases);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _run(Future<void> action) async {
    try {
      await action;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, mapAuthError(e));
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
          'TABLEAU DE BORD',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<_AdminData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.mint),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Accès refusé ou erreur de chargement.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }
          final data = snapshot.data!;
          final kpis = data.kpis;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Kpi(label: 'Joueurs', value: '${kpis['players'] ?? 0}'),
                  _Kpi(
                    label: 'Avec vidéo',
                    value: '${kpis['players_with_video'] ?? 0}',
                  ),
                  _Kpi(label: 'Vidéos moy.', value: '${kpis['avg_videos'] ?? 0}'),
                  _Kpi(
                    label: 'Achats vidéo',
                    value: '${kpis['video_purchases'] ?? 0}',
                  ),
                  _Kpi(label: 'PRO', value: '${kpis['pro_subscribers'] ?? 0}'),
                  _Kpi(
                    label: 'FREE → PRO',
                    value: '${kpis['free_to_pro_rate'] ?? 0}',
                  ),
                  _Kpi(label: 'Vues profil', value: '${kpis['profile_views'] ?? 0}'),
                  _Kpi(
                    label: 'Contacts',
                    value: '${kpis['contacts_generated'] ?? 0}',
                  ),
                  _Kpi(
                    label: 'Paiements en attente',
                    value: '${kpis['pending_purchases'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Paiements',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final purchase in data.purchases)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${purchase.sku} · ${purchase.amountFcfa} FCFA',
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    purchase.status,
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                  trailing: purchase.status == 'pending'
                      ? TextButton(
                          onPressed: () => _run(_admin.fulfillPurchase(purchase.id)),
                          child: const Text('Valider'),
                        )
                      : null,
                ),
              const SizedBox(height: 16),
              Text(
                'Joueurs',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              for (final player in data.players)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    player.name,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${player.plan} · ${player.videos} vidéos · ${player.videoCredits} crédits',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: player.verified ? 'Retirer vérifié' : 'Vérifier',
                        onPressed: () => _run(
                          _admin.setVerified(
                            playerId: player.id,
                            verified: !player.verified,
                          ),
                        ),
                        icon: Icon(
                          Icons.verified,
                          color: player.verified ? AppColors.mint : AppColors.textMuted,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ajouter 1 crédit vidéo',
                        onPressed: () => _run(
                          _admin.adjustCredits(playerId: player.id, delta: 1),
                        ),
                        icon: const Icon(Icons.add, color: AppColors.orange),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminData {
  const _AdminData({
    required this.kpis,
    required this.players,
    required this.purchases,
  });

  final Map<String, dynamic> kpis;
  final List<AdminPlayerRow> players;
  final List<AdminPurchaseRow> purchases;
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.mint,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
