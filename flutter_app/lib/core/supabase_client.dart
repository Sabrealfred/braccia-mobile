import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Initializes Supabase against the same project the web staff portal uses.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

/// Convenience accessor for the shared client.
SupabaseClient get supabase => Supabase.instance.client;
