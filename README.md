# Diário de Trade

Aplicação web para registro e análise de operações de trading com gráficos e relatórios por período.

## 🚀 Recursos

- 📅 Calendário interativo para seleção de datas
- 💰 Registro de ganhos/perdas diárias
- 📊 Relatórios por período (semanal, mensal, trimestral, semestral, anual)
- 📈 Gráficos de desempenho
- 🔐 Autenticação segura com Supabase
- 🌙 Interface dark mode moderna
- 📱 Responsivo para web, mobile e tablet

## 🛠️ Tecnologias

- **Flutter 3.41.7** - Framework UI
- **Dart 3.11.5** - Linguagem de programação
- **Supabase** - Backend e autenticação
- **Provider** - Gerenciamento de estado
- **fl_chart** - Gráficos
- **table_calendar** - Calendário

## 📋 Pré-requisitos

- Flutter 3.41.7+
- Dart 3.11.5+
- Conta no Supabase

## 🔧 Setup Local

### 1. Clonar o repositório
```bash
git clone https://github.com/Dryedson/dirarioTrader.git
cd dirarioTrader
```

### 2. Configurar Supabase
```bash
# Copie o arquivo de exemplo
cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart

# Edite e preencha com suas credenciais
nano lib/config/supabase_config.dart
```

### 3. Instalar dependências
```bash
flutter pub get
```

### 4. Executar a aplicação

**Web:**
```bash
flutter run -d chrome
```

**Mobile (iOS/Android):**
```bash
flutter run
```

## 🌐 Deploy no Vercel

A aplicação está configurada para deploy automático no Vercel:

1. Acesse [Vercel](https://vercel.com)
2. Conecte seu repositório GitHub
3. Configure as variáveis de ambiente:
   - `SUPABASE_URL`: URL do seu projeto Supabase
   - `SUPABASE_ANON_KEY`: Chave anon do Supabase
4. Deploy automático será acionado a cada push para `main`

## 📁 Estrutura do Projeto

```
lib/
├── config/          # Configurações (Supabase)
├── models/          # Modelos de dados
├── providers/       # Gerenciamento de estado
├── repositories/    # Acesso a dados
├── screens/         # Telas da aplicação
├── theme/           # Tema e estilos
└── utils/           # Utilitários
```

## 🔐 Segurança

- Credenciais do Supabase estão no `.gitignore`
- Use `lib/config/supabase_config.example.dart` como referência
- Nunca commite arquivos com chaves reais

## 📝 Licença

MIT
