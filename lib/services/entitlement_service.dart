import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/models/publish_quota.dart';

class EntitlementService {
  EntitlementService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<PublishQuota> fetchQuota() async {
    final raw = await _client.rpc('my_publish_quota');
    return PublishQuota.fromJson(Map<String, dynamic>.from(raw as Map));
  }
}
