import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/trade_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

// Ponto de entrada do aplicativo.
//
// Faz as inicializações assíncronas necessárias (formatação de datas em
// PT-BR e conexão com o Supabase) antes de rodar o app.
Future<void> main() async {
  // Garante que os bindings do Flutter estejam prontos para chamadas async.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa os dados de localização para formatação de datas em PT-BR
  // (necessário para o calendário e formatadores).
  await initializeDateFormatting('pt_BR', null);

  // Inicializa o Supabase apenas se as credenciais estiverem configuradas.
  // Isso evita que o app quebre antes de você preencher a config.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      // A chave anon/public agora é passada como publishableKey na API atual.
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  runApp(const DiarioTradeApp());
}

// Widget raiz do aplicativo.
class DiarioTradeApp extends StatelessWidget {
  const DiarioTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Se o Supabase não foi configurado, mostramos uma tela de aviso amigável
    // explicando como configurar, sem depender dos providers.
    if (!SupabaseConfig.isConfigured) {
      return const _ConfigWarningApp();
    }

    // Disponibiliza os providers de autenticação e de trades para toda a árvore.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TradeProvider()),
      ],
      child: MaterialApp(
        title: 'Diário de Trade',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        // Configura o idioma PT-BR para os widgets do Material e o calendário.
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _AppRoot(),
      ),
    );
  }
}

// Widget que controla o fluxo inicial: splash -> (login ou home).
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  // Enquanto true, exibimos a splash screen.
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    // Exibe a splash até o tempo mínimo terminar.
    if (_showSplash) {
      return SplashScreen(
        onFinish: () => setState(() => _showSplash = false),
      );
    }

    // Após a splash, decide entre login e home conforme a autenticação.
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}

// App mínimo exibido quando as credenciais do Supabase não foram preenchidas.
class _ConfigWarningApp extends StatelessWidget {
  const _ConfigWarningApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diário de Trade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.settings, size: 56, color: AppTheme.primary),
                SizedBox(height: 16),
                Text(
                  'Configuração necessária',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Preencha a URL e a anon key do Supabase no arquivo\n'
                  'lib/config/supabase_config.dart e reinicie o app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
