/// Backend configuration.
///
/// Defaults point at the SAME Supabase project the web staff portal uses
/// (project `ieqizooravdkcyujgiot`). Override at build time with:
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ieqizooravdkcyujgiot.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllcWl6b29yYXZka2N5dWpnaW90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NTI1MzIsImV4cCI6MjA4MDMyODUzMn0.pvNw3TFUgj79Pwir2VBqfsm4REi_swPGo2hNv_DR_uo',
  );
}
