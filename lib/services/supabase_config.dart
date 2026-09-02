/// Configuración de Supabase para Clock.Do
///
/// Reemplaza [supabaseUrl] y [supabaseAnonKey] con las credenciales de tu proyecto
/// de Supabase (Settings -> API en el panel de Supabase).
class SupabaseConfig {
  /// URL del proyecto de Supabase (ej: https://xyzcompany.supabase.co)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tu-proyecto.supabase.co',
  );

  /// Anon Key pública de Supabase
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'tu-anon-key-aqui',
  );

  /// Verifica si las credenciales han sido configuradas
  static bool get isConfigured =>
      supabaseUrl != 'https://tu-proyecto.supabase.co' &&
      supabaseAnonKey != 'tu-anon-key-aqui' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
