/// Public Supabase client config.
/// Override at build time with:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rcpeireebmvgsidbnept.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_c8M6a9I65Qc6qNH8fc-ijw_CdBYCwMG',
  );
}
