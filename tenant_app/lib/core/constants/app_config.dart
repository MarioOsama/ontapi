class AppConfig {
  static const String baseUrl = bool.fromEnvironment('dart.vm.product')
      ? 'https://admin.ontapi.com'
      : 'http://localhost:3000'; // Default port for local development

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );
}
