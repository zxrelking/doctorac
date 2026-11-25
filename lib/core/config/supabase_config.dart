import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase configuration for Doctorac (دكتوراك).
///
/// Provide your project credentials via `--dart-define`:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
/// ```
/// Or replace the default fallback constants below before building.
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hzxgxlhxzzjwkxnyvzge.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6eGd4bGh4enpqd2t4bnl2emdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU1MjM3MjEsImV4cCI6MjExMTA5OTcyMX0.AwFiy-AbuAHNSp74iXD-AxapQdaswMy4Do94ye29VvY',
  );

  /// Deep link redirect URI for OAuth (Google / Apple) & password recovery.
  static const String oauthRedirectUrl = 'io.doctorac.app://login-callback/';

  /// Returns `true` when real Supabase credentials have been provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT_ID') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint(
        '[Doctorac] Supabase credentials not set — running in interactive preview mode. '
        'Supply SUPABASE_URL and SUPABASE_ANON_KEY to connect live.',
      );
      return;
    }
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[Doctorac] Supabase initialization failed: $e');
      _initialized = false;
    }
  }

  static SupabaseClient? get clientOrNull =>
      _initialized ? Supabase.instance.client : null;
}
