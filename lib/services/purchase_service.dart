import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/billing/offers.dart';

class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.sku,
    required this.amountFcfa,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String sku;
  final int amountFcfa;
  final String status;
  final DateTime createdAt;
}

class PurchaseService {
  PurchaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<PurchaseRecord> createPending(Offer offer) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException('Connecte-toi pour acheter une offre.');
    }
    final row = await _client
        .from('purchases')
        .insert({
          'player_id': uid,
          'sku': offer.dbValue,
          'amount_fcfa': offer.amountFcfa,
          'status': 'pending',
        })
        .select('id, sku, amount_fcfa, status, created_at')
        .single();
    return _map(row);
  }

  Future<List<PurchaseRecord>> mine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('purchases')
        .select('id, sku, amount_fcfa, status, created_at')
        .eq('player_id', uid)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => _map(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  PurchaseRecord _map(Map<String, dynamic> row) {
    return PurchaseRecord(
      id: row['id'] as String,
      sku: row['sku'] as String,
      amountFcfa: row['amount_fcfa'] as int,
      status: row['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
