/// Configuración de Supabase para Clock.Do
///
/// Reemplaza [supabaseUrl] y [supabaseAnonKey] con las credenciales de tu proyecto
/// de Supabase (Settings -> API en el panel de Supabase).
class SupabaseConfig {
  /// URL del proyecto de Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dnebkmqpqsdgwuguaomw.supabase.co',
  );

  /// Anon Key pública de Supabase
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuZWJrbXFwcXNkZ3d1Z3Vhb213Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5MjI5MjAsImV4cCI6MjA4MDQ5ODkyMH0.xMiRyRStvsuZc3qYwYCaTBH2_l_9trxqFyqmQcbHlPI',
  );

  /// Verifica si las credenciales han sido configuradas
  static bool get isConfigured =>
      supabaseUrl != 'https://tu-proyecto.supabase.co' &&
      supabaseAnonKey != 'tu-anon-key-aqui' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
