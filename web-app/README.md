# Diário de Trade - Website

Website moderno para registro e análise de operações de trading, construído com HTML, CSS e JavaScript puro.

## 🚀 Características

- 📅 Calendário interativo para seleção de datas
- 💰 Registro de ganhos/perdas diárias
- 📊 Relatórios por período (semanal, mensal, trimestral, semestral, anual)
- 📈 Gráficos de desempenho em tempo real
- 🔐 Autenticação segura com Supabase
- 🌙 Interface dark mode moderna
- 📱 Totalmente responsivo (mobile, tablet, desktop)
- ⚡ Sem dependências externas (exceto Chart.js)

## 🛠️ Tecnologias

- **HTML5** - Estrutura
- **CSS3** - Estilos e animações
- **JavaScript Vanilla** - Lógica da aplicação
- **Supabase** - Backend e autenticação
- **Chart.js** - Gráficos

## 📋 Pré-requisitos

- Conta no Supabase com tabela `trades` configurada
- Navegador moderno (Chrome, Firefox, Safari, Edge)

## 🔧 Setup Local

### 1. Clonar ou copiar os arquivos
```bash
# Copie os arquivos para uma pasta local
cp -r web-app ~/seu-projeto
cd ~/seu-projeto
```

### 2. Configurar credenciais do Supabase
Edite `supabase.js` e preencha:
```javascript
const SUPABASE_URL = 'sua_url_aqui';
const SUPABASE_ANON_KEY = 'sua_chave_aqui';
```

### 3. Executar localmente
```bash
# Usando Python 3
python3 -m http.server 8000

# Ou usando Node.js
npx http-server

# Ou usando Live Server no VS Code
```

Acesse: `http://localhost:8000`

## 🌐 Deploy no Vercel

### Opção 1: Usando Git

1. Crie um repositório GitHub com apenas a pasta `web-app`
2. Acesse https://vercel.com/dashboard
3. Clique em "Add New Project"
4. Selecione o repositório
5. Configure as variáveis de ambiente:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
6. Deploy automático será acionado

### Opção 2: Drag & Drop

1. Acesse https://vercel.com/new
2. Arraste a pasta `web-app` para fazer upload
3. Vercel fará o deploy automaticamente

## 📁 Estrutura

```
web-app/
├── index.html          # Estrutura HTML
├── styles.css          # Estilos CSS
├── app.js              # Lógica principal
├── supabase.js         # Integração com Supabase
├── vercel.json         # Configuração Vercel
└── README.md           # Este arquivo
```

## 🔐 Segurança

- As credenciais do Supabase são públicas (chave anon) - isso é normal
- Use Row Level Security (RLS) no Supabase para proteger dados
- Senhas são criptografadas pelo Supabase

## 📊 Schema do Supabase

Tabela `trades`:
```sql
CREATE TABLE trades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Índices
CREATE INDEX idx_trades_user_date ON trades(user_id, date);

-- RLS
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own trades"
  ON trades FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own trades"
  ON trades FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trades"
  ON trades FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trades"
  ON trades FOR DELETE
  USING (auth.uid() = user_id);
```

## 🐛 Troubleshooting

### "Invalid login credentials"
- Verifique email e senha
- Confirme que a conta foi criada

### "Erro ao carregar trades"
- Verifique se as credenciais do Supabase estão corretas
- Verifique se a tabela `trades` existe
- Verifique as políticas RLS

### Gráfico não aparece
- Verifique se Chart.js foi carregado
- Abra o console (F12) para ver erros

## 📝 Licença

MIT

## 👨‍💻 Autor

Dryedson
