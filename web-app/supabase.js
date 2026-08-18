// Integração com Supabase para autenticação e dados
// Substitua as credenciais pelas suas

const SUPABASE_URL = 'https://frzvhhfqvaanoglehydn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZyenZoaGZxdmFhbm9nbGVoeWRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MjM3ODksImV4cCI6MjA5OTQ5OTc4OX0.ZBnXc782ASfZu7yLlexVdcIOUrvVFIeOsB7kNGk7Gvo';

// Classe para gerenciar requisições ao Supabase
class SupabaseClient {
    constructor(url, anonKey) {
        this.url = url;
        this.anonKey = anonKey;
        this.token = null;
        this.userId = null;
    }

    // Faz requisições autenticadas ao Supabase
    async request(method, endpoint, body = null) {
        const headers = {
            'Content-Type': 'application/json',
            'apikey': this.anonKey,
        };

        if (this.token) {
            headers['Authorization'] = `Bearer ${this.token}`;
        }

        const options = {
            method,
            headers,
        };

        if (body) {
            options.body = JSON.stringify(body);
        }

        const response = await fetch(`${this.url}/rest/v1${endpoint}`, options);
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.message || 'Erro na requisição');
        }

        return response.json();
    }

    // Autenticação - Sign Up
    async signUp(email, password) {
        const response = await fetch(`${this.url}/auth/v1/signup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': this.anonKey,
            },
            body: JSON.stringify({ email, password }),
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error_description || data.message || 'Erro ao criar conta');
        }

        return data;
    }

    // Autenticação - Sign In
    async signIn(email, password) {
        const response = await fetch(`${this.url}/auth/v1/token?grant_type=password`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': this.anonKey,
            },
            body: JSON.stringify({ email, password }),
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error_description || data.message || 'Erro ao fazer login');
        }

        this.token = data.access_token;
        this.userId = data.user.id;
        localStorage.setItem('token', this.token);
        localStorage.setItem('userId', this.userId);

        return data;
    }

    // Autenticação - Sign Out
    async signOut() {
        this.token = null;
        this.userId = null;
        localStorage.removeItem('token');
        localStorage.removeItem('userId');
    }

    // Restaura sessão do localStorage
    restoreSession() {
        const token = localStorage.getItem('token');
        const userId = localStorage.getItem('userId');

        if (token && userId) {
            this.token = token;
            this.userId = userId;
            return true;
        }

        return false;
    }

    // Obtém trades de um período
    async getTrades(startDate, endDate) {
        const query = `select=*&user_id=eq.${this.userId}&date=gte.${startDate}&date=lte.${endDate}&order=date.desc`;
        return this.request('GET', `/trades?${query}`);
    }

    // Salva ou atualiza um trade
    async saveTrade(date, amount, notes = '') {
        const existingTrades = await this.request(
            'GET',
            `/trades?user_id=eq.${this.userId}&date=eq.${date}`
        );

        if (existingTrades.length > 0) {
            // Atualiza trade existente
            return this.request('PATCH', `/trades?id=eq.${existingTrades[0].id}`, {
                amount,
                notes,
                updated_at: new Date().toISOString(),
            });
        } else {
            // Cria novo trade
            return this.request('POST', '/trades', {
                user_id: this.userId,
                date,
                amount,
                notes,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString(),
            });
        }
    }

    // Deleta um trade
    async deleteTrade(id) {
        return this.request('DELETE', `/trades?id=eq.${id}`);
    }

    // Obtém trade de um dia específico
    async getTradeByDate(date) {
        const trades = await this.request(
            'GET',
            `/trades?user_id=eq.${this.userId}&date=eq.${date}`
        );
        return trades.length > 0 ? trades[0] : null;
    }
}

// Instância global do cliente Supabase
const supabase = new SupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY);
