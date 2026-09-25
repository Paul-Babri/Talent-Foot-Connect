import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPlayerRow {
  const AdminPlayerRow({
    required this.id,
    required this.name,
    required this.verified,
    required this.plan,
    required this.videoCredits,
    required this.videos,
    required this.photos,
    this.position,
    this.email,
  });

  final String id;
  final String name;
  final bool verified;
  final String plan;
  final int videoCredits;
  final int videos;
  final int photos;
  final String? position;
  final String? email;

  factory AdminPlayerRow.fromJson(Map<String, dynamic> json) {
    return AdminPlayerRow(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Joueur',
      verified: json['verified'] as bool? ?? false,
      plan: (json['plan'] as String?) ?? 'free',
      videoCredits: (json['video_credits'] as num?)?.toInt() ?? 0,
      videos: (json['videos'] as num?)?.toInt() ?? 0,
      photos: (json['photos'] as num?)?.toInt() ?? 0,
      position: json['position'] as String?,
      email: json['email'] as String?,
    );
  }
}

class AdminPurchaseRow {
  const AdminPurchaseRow({
    required this.id,
    required this.playerId,
    required this.sku,
    required this.amountFcfa,
    required this.status,
  });

  final String id;
  final String playerId;
  final String sku;
  final int amountFcfa;
  final String status;

  factory AdminPurchaseRow.fromJson(Map<String, dynamic> json) {
    return AdminPurchaseRow(
      id: json['id'] as String,
      playerId: json['player_id'] as String,
      sku: json['sku'] as String,
      amountFcfa: (json['amount_fcfa'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'pending',
    );
  }
}

class AdminService {
  AdminService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> amIAdmin() async {
    final raw = await _client.rpc('am_i_admin');
    return raw == true;
  }

  Future<Map<String, dynamic>> kpis() async {
    final raw = await _client.rpc('admin_dashboard', params: {
      'action': 'kpis',
      'payload': {},
    });
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<List<AdminPlayerRow>> players() async {
    final raw = await _client.rpc('admin_dashboard', params: {
      'action': 'players',
      'payload': {},
    });
    return (raw as List)
        .map((row) => AdminPlayerRow.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<AdminPurchaseRow>> purchases() async {
    final raw = await _client.rpc('admin_dashboard', params: {
      'action': 'purchases',
      'payload': {},
    });
    return (raw as List)
        .map(
          (row) => AdminPurchaseRow.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> setVerified({required String playerId, required bool verified}) {
    return _client.rpc('admin_dashboard', params: {
      'action': 'set_verified',
      'payload': {'player_id': playerId, 'verified': verified},
    });
  }

  Future<void> adjustCredits({required String playerId, required int delta}) {
    return _client.rpc('admin_dashboard', params: {
      'action': 'adjust_credits',
      'payload': {'player_id': playerId, 'delta': delta},
    });
  }

  Future<void> fulfillPurchase(String purchaseId) {
    return _client.rpc('admin_dashboard', params: {
      'action': 'fulfill_purchase',
      'payload': {'purchase_id': purchaseId, 'provider': 'manual'},
    });
  }
}
