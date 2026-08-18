import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

// Tela de autenticação (login e cadastro na mesma tela).
//
// Visual moderno com cabeçalho em gradiente, cartão elevado, campos com
// ícones, senha com mostrar/ocultar e exibição elegante de erros.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Chave do formulário para validação dos campos.
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  // Controla se estamos no modo cadastro (true) ou login (false).
  bool _isSignUp = false;

  // Controla a visibilidade dos campos de senha.
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Mensagem de sucesso exibida após o cadastro (ex.: confirmar email).
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Alterna entre login e cadastro, limpando mensagens e o estado do form.
  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _successMessage = null;
      context.read<AuthProvider>().clearError();
      _formKey.currentState?.reset();
    });
  }

  // Envia o formulário: faz login ou cadastro conforme o modo atual.
  Future<void> _submit() async {
    // Fecha o teclado antes de enviar.
    FocusScope.of(context).unfocus();

    // Valida os campos antes de enviar.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _successMessage = null);

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = _isSignUp
        ? await auth.signUp(email, password)
        : await auth.signIn(email, password);

    if (!mounted) return;

    if (success && _isSignUp) {
      // No cadastro, o Supabase pode exigir confirmação por email.
      setState(() {
        _successMessage =
            'Conta criada! Se necessário, confirme pelo link enviado ao seu email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa o provider para refletir loading e erros na UI.
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        // Fundo com gradiente sutil para dar profundidade à tela.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10231A), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                // Limita a largura em telas grandes (web/desktop/tablet).
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: 32),
                    _buildCard(auth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Cabeçalho com a identidade visual do app (logo + nome).
  Widget _buildBrand() {
    return Column(
      children: [
        // Logo em um círculo com leve brilho verde.
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              // Fallback caso a logo ainda não tenha sido adicionada.
              errorBuilder: (context, error, stack) => const Icon(
                Icons.candlestick_chart,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Diário de Trade',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Controle seus ganhos e prejuízos',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }

  // Cartão que contém o formulário de autenticação.
  Widget _buildCard(AuthProvider auth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título do modo atual.
              Text(
                _isSignUp ? 'Criar conta' : 'Bem-vindo de volta',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignUp
                    ? 'Preencha os dados para começar.'
                    : 'Entre para acessar seu diário.',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Banner de erro (aparece só quando há mensagem de erro).
              if (auth.errorMessage != null) ...[
                _MessageBanner(
                  message: auth.errorMessage!,
                  color: AppTheme.danger,
                  icon: Icons.error_outline,
                ),
                const SizedBox(height: 16),
              ],

              // Banner de sucesso (após cadastro).
              if (_successMessage != null) ...[
                _MessageBanner(
                  message: _successMessage!,
                  color: AppTheme.primary,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 16),
              ],

              // Campo de email.
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'seu@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  // Validação simples de formato de email.
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(v)) {
                    return 'Informe um email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de senha com botão para mostrar/ocultar.
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: _isSignUp
                    ? TextInputAction.next
                    : TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'A senha deve ter ao menos 6 caracteres';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!_isSignUp) _submit();
                },
              ),

              // Campo de confirmação de senha (somente no cadastro).
              if (_isSignUp) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: 24),

              // Botão principal (entra ou cadastra) com estado de loading.
              ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(_isSignUp ? 'Cadastrar' : 'Entrar'),
              ),
              const SizedBox(height: 8),

              // Alterna entre login e cadastro.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp ? 'Já tem conta?' : 'Não tem conta?',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  TextButton(
                    onPressed: auth.loading ? null : _toggleMode,
                    child: Text(_isSignUp ? 'Entrar' : 'Criar agora'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Banner reutilizável para exibir mensagens de erro ou sucesso de forma
// destacada, com cor e ícone conforme o contexto.
class _MessageBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _MessageBanner({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Fundo translúcido na cor do tipo de mensagem.
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
