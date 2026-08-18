import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider responsável pelo estado de autenticação do usuário.
//
// Escuta as mudanças de sessão do Supabase (login/logout) e notifica a UI
// para reagir automaticamente (ex.: ir para a tela de login ou home).
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  // Sessão atual do usuário (null quando deslogado).
  Session? _session;
  Session? get session => _session;

  // Indica se há um usuário autenticado.
  bool get isAuthenticated => _session != null;

  // Mensagem de erro da última operação (login/cadastro), se houver.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Flag de carregamento para desabilitar botões durante requisições.
  bool _loading = false;
  bool get loading => _loading;

  AuthProvider() {
    // Recupera a sessão persistida (se o usuário já estava logado).
    _session = _client.auth.currentSession;

    // Escuta eventos de autenticação e atualiza o estado reativo.
    _client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      notifyListeners();
    });
  }

  // Realiza login com email e senha.
  Future<bool> signIn(String email, String password) async {
    return _runAuth(() async {
      await _client.auth.signInWithPassword(email: email, password: password);
    });
  }

  // Cadastra um novo usuário com email e senha.
  Future<bool> signUp(String email, String password) async {
    return _runAuth(() async {
      await _client.auth.signUp(email: email, password: password);
    });
  }

  // Encerra a sessão do usuário.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Limpa a mensagem de erro atual (ex.: ao alternar login/cadastro).
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Executa uma operação de autenticação tratando loading e erros de forma
  // padronizada, evitando repetição de código (DRY).
  Future<bool> _runAuth(Future<void> Function() action) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      // Erros específicos de autenticação: traduzimos para PT-BR amigável.
      _errorMessage = _translateAuthError(e);
      return false;
    } on Exception catch (e) {
      // Erros de rede/conexão (ex.: sem internet, host indisponível).
      _errorMessage = _translateGenericError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Converte a mensagem de erro do Supabase (em inglês) para uma mensagem
  // clara em português. Fazemos o casamento por trechos conhecidos da
  // mensagem, com um fallback genérico para casos não mapeados.
  String _translateAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    // Rate limit: "For security purposes, you can only request this after Xs".
    if (msg.contains('after') && msg.contains('second')) {
      // Tenta extrair o número de segundos da mensagem original.
      final match = RegExp(r'(\d+)\s*second').firstMatch(msg);
      final seconds = match?.group(1);
      return seconds != null
          ? 'Muitas tentativas. Aguarde $seconds segundos e tente novamente.'
          : 'Muitas tentativas. Aguarde alguns segundos e tente novamente.';
    }

    if (msg.contains('invalid login credentials')) {
      return 'Email ou senha incorretos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirme seu email antes de entrar. Verifique sua caixa de entrada.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Este email já está cadastrado. Faça login.';
    }
    if (msg.contains('password should be at least')) {
      return 'A senha é muito curta. Use ao menos 6 caracteres.';
    }
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid email')) {
      return 'Email inválido. Verifique e tente novamente.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Muitas tentativas. Aguarde um momento e tente novamente.';
    }

    // Fallback: usa a mensagem original se não reconhecermos o erro.
    return e.message;
  }

  // Traduz erros genéricos (normalmente de rede) para PT-BR.
  String _translateGenericError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection') ||
        msg.contains('network')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
