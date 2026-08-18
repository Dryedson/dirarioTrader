import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Tela de carregamento (splash) exibida na abertura do app.
//
// Mostra a logo do aplicativo com uma animação suave e um indicador de
// progresso enquanto a inicialização acontece. Após [duration], chama
// [onFinish] para navegar à próxima tela (login ou home).
class SplashScreen extends StatefulWidget {
  // Callback executado quando o tempo de splash termina.
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controlador da animação de fade/scale da logo.
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // Configura a animação de entrada da logo (fade + leve zoom).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Aguarda um tempo mínimo de exibição e então avança.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo animada com fade e escala.
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(scale: _scale, child: const _Logo()),
            ),
            const SizedBox(height: 24),
            const Text(
              'Diário de Trade',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            // Indicador de carregamento na parte inferior.
            const Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget que exibe a logo do app.
//
// Tenta carregar assets/images/logo.png; caso a imagem ainda não tenha
// sido adicionada, exibe um placeholder para não quebrar a interface.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: 140,
      height: 140,
      // Fallback exibido caso a logo ainda não exista no projeto.
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.primary, width: 2),
          ),
          child: const Icon(
            Icons.candlestick_chart,
            size: 72,
            color: AppTheme.primary,
          ),
        );
      },
    );
  }
}
