// Teste básico de widget do Diário de Trade.
//
// Sem as credenciais do Supabase configuradas, o app exibe a tela de
// "Configuração necessária". Este teste apenas garante que o app monta
// sem erros nesse estado inicial.

import 'package:flutter_test/flutter_test.dart';

import 'package:diario_trade/main.dart';

void main() {
  testWidgets('App inicia exibindo aviso de configuração', (
    WidgetTester tester,
  ) async {
    // Monta o app raiz.
    await tester.pumpWidget(const DiarioTradeApp());
    await tester.pump();

    // Como o Supabase não está configurado no ambiente de teste,
    // deve aparecer a tela de configuração necessária.
    expect(find.text('Configuração necessária'), findsOneWidget);
  });
}
