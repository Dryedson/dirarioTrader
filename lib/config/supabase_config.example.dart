// MODELO de configuração do Supabase (arquivo versionável, SEM chaves reais).
//
// Como usar:
// 1. Copie este arquivo para: lib/config/supabase_config.dart
// 2. Preencha a URL e a anon key do seu projeto (Project Settings -> API).
//
// O arquivo real (supabase_config.dart) está no .gitignore por segurança,
// então não é enviado ao repositório.
class SupabaseConfig {
  // URL do projeto Supabase.
  static const String supabaseUrl = 'COLE_AQUI_SUA_PROJECT_URL';

  // Chave pública (anon) do projeto Supabase.
  static const String supabaseAnonKey = 'COLE_AQUI_SUA_ANON_KEY';

  // Retorna true quando as credenciais ainda não foram configuradas.
  static bool get isConfigured =>
      !supabaseUrl.startsWith('COLE_AQUI') &&
      !supabaseAnonKey.startsWith('COLE_AQUI');
}
