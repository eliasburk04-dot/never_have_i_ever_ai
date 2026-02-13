abstract final class AppEnv {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String? get validationError {
    final missing = <String>[];

    if (supabaseUrl.isEmpty) {
      missing.add('SUPABASE_URL');
    }

    if (supabaseAnonKey.isEmpty) {
      missing.add('SUPABASE_ANON_KEY');
    }

    if (missing.isEmpty) {
      return null;
    }

    return 'Missing required build-time variables: ${missing.join(', ')}.';
  }
}
