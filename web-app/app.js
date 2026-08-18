// Aplicação principal - Diário de Trade
// Gerencia a lógica de navegação, calendário, trades e relatórios

class TradeApp {
    constructor() {
        this.currentDate = new Date();
        this.selectedDate = this.dateOnly(new Date());
        this.trades = {};
        this.chart = null;
        this.currentPeriod = 'monthly';

        this.initializeElements();
        this.attachEventListeners();
        this.checkAuth();
    }

    // Inicializa referências aos elementos DOM
    initializeElements() {
        // Screens
        this.authScreen = document.getElementById('authScreen');
        this.homeScreen = document.getElementById('homeScreen');
        this.reportsScreen = document.getElementById('reportsScreen');

        // Auth
        this.loginForm = document.getElementById('loginForm');
        this.signupForm = document.getElementById('signupForm');
        this.authMessage = document.getElementById('authMessage');
        this.tabButtons = document.querySelectorAll('.tab-btn');

        // Home
        this.calendar = document.getElementById('calendar');
        this.selectedDateDisplay = document.getElementById('selectedDate');
        this.tradeForm = document.getElementById('tradeForm');
        this.tradeMessage = document.getElementById('tradeMessage');
        this.dayResult = document.getElementById('dayResult');
        this.dayAmount = document.getElementById('dayAmount');
        this.reportsBtn = document.getElementById('reportsBtn');
        this.logoutBtn = document.getElementById('logoutBtn');

        // Reports
        this.backBtn = document.getElementById('backBtn');
        this.periodButtons = document.querySelectorAll('.period-btn');
        this.periodTotal = document.getElementById('periodTotal');
        this.positiveDays = document.getElementById('positiveDays');
        this.negativeDays = document.getElementById('negativeDays');
        this.performanceChart = document.getElementById('performanceChart');
        this.tableBody = document.getElementById('tableBody');
    }

    // Anexa listeners aos elementos
    attachEventListeners() {
        // Auth
        this.tabButtons.forEach(btn => {
            btn.addEventListener('click', (e) => this.switchAuthTab(e.target.dataset.tab));
        });

        this.loginForm.addEventListener('submit', (e) => this.handleLogin(e));
        this.signupForm.addEventListener('submit', (e) => this.handleSignup(e));

        // Password toggles
        document.querySelectorAll('.toggle-password').forEach(btn => {
            btn.addEventListener('click', (e) => this.togglePasswordVisibility(e));
        });

        // Home
        this.tradeForm.addEventListener('submit', (e) => this.handleSaveTrade(e));
        this.reportsBtn.addEventListener('click', () => this.showReports());
        this.logoutBtn.addEventListener('click', () => this.handleLogout());

        // Reports
        this.backBtn.addEventListener('click', () => this.showHome());
        this.periodButtons.forEach(btn => {
            btn.addEventListener('click', (e) => this.changePeriod(e.target.dataset.period));
        });
    }

    // ===== AUTENTICAÇÃO =====

    checkAuth() {
        if (supabase.restoreSession()) {
            this.showHome();
            this.loadCalendar();
        } else {
            this.showAuth();
        }
    }

    switchAuthTab(tab) {
        document.querySelectorAll('.auth-form').forEach(f => f.classList.remove('active'));
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));

        document.querySelector(`[data-form="${tab}"]`).classList.add('active');
        document.querySelector(`[data-tab="${tab}"]`).classList.add('active');

        this.clearAuthMessage();
    }

    async handleLogin(e) {
        e.preventDefault();

        const email = document.getElementById('loginEmail').value;
        const password = document.getElementById('loginPassword').value;

        try {
            this.showAuthMessage('Entrando...', 'loading');
            await supabase.signIn(email, password);
            this.showAuthMessage('Login realizado com sucesso!', 'success');
            setTimeout(() => this.showHome(), 1000);
        } catch (error) {
            this.showAuthMessage(this.translateError(error.message), 'error');
        }
    }

    async handleSignup(e) {
        e.preventDefault();

        const email = document.getElementById('signupEmail').value;
        const password = document.getElementById('signupPassword').value;
        const confirm = document.getElementById('signupConfirm').value;

        if (password !== confirm) {
            this.showAuthMessage('As senhas não correspondem', 'error');
            return;
        }

        if (password.length < 6) {
            this.showAuthMessage('A senha deve ter pelo menos 6 caracteres', 'error');
            return;
        }

        try {
            this.showAuthMessage('Criando conta...', 'loading');
            await supabase.signUp(email, password);
            this.showAuthMessage('Conta criada! Verifique seu email para confirmar.', 'success');
            setTimeout(() => this.switchAuthTab('login'), 2000);
        } catch (error) {
            this.showAuthMessage(this.translateError(error.message), 'error');
        }
    }

    async handleLogout() {
        await supabase.signOut();
        this.showAuth();
        this.clearAuthMessage();
    }

    togglePasswordVisibility(e) {
        e.preventDefault();
        const inputId = e.target.dataset.input;
        const input = document.getElementById(inputId);
        const isPassword = input.type === 'password';
        input.type = isPassword ? 'text' : 'password';
        e.target.textContent = isPassword ? '🙈' : '👁️';
    }

    showAuthMessage(message, type) {
        this.authMessage.textContent = message;
        this.authMessage.className = `message show ${type}`;
    }

    clearAuthMessage() {
        this.authMessage.textContent = '';
        this.authMessage.className = 'message';
    }

    translateError(error) {
        const translations = {
            'Invalid login credentials': 'Email ou senha incorretos',
            'User already registered': 'Este email já está cadastrado',
            'Email not confirmed': 'Confirme seu email antes de fazer login',
            'Password should be at least 6 characters': 'A senha deve ter pelo menos 6 caracteres',
        };

        return translations[error] || error || 'Erro desconhecido';
    }

    // ===== NAVEGAÇÃO =====

    showAuth() {
        this.authScreen.classList.add('active');
        this.homeScreen.classList.remove('active');
        this.reportsScreen.classList.remove('active');
    }

    showHome() {
        this.authScreen.classList.remove('active');
        this.homeScreen.classList.add('active');
        this.reportsScreen.classList.remove('active');
        this.loadCalendar();
    }

    showReports() {
        this.authScreen.classList.remove('active');
        this.homeScreen.classList.remove('active');
        this.reportsScreen.classList.add('active');
        this.loadReports();
    }

    // ===== CALENDÁRIO =====

    loadCalendar() {
        this.calendar.innerHTML = '';
        this.renderCalendar(this.currentDate);
    }

    renderCalendar(date) {
        const year = date.getFullYear();
        const month = date.getMonth();

        // Header com navegação
        const header = document.createElement('div');
        header.className = 'calendar-header';
        header.innerHTML = `
            <button id="prevMonth">← Anterior</button>
            <h3>${this.monthName(month)} ${year}</h3>
            <button id="nextMonth">Próximo →</button>
        `;
        this.calendar.appendChild(header);

        document.getElementById('prevMonth').addEventListener('click', () => {
            this.currentDate.setMonth(this.currentDate.getMonth() - 1);
            this.loadCalendar();
        });

        document.getElementById('nextMonth').addEventListener('click', () => {
            this.currentDate.setMonth(this.currentDate.getMonth() + 1);
            this.loadCalendar();
        });

        // Grid do calendário
        const grid = document.createElement('div');
        grid.className = 'calendar-grid';

        // Dias da semana
        const weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];
        weekdays.forEach(day => {
            const dayEl = document.createElement('div');
            dayEl.className = 'calendar-weekday';
            dayEl.textContent = day;
            grid.appendChild(dayEl);
        });

        // Primeiro dia do mês
        const firstDay = new Date(year, month, 1);
        const lastDay = new Date(year, month + 1, 0);
        const prevLastDay = new Date(year, month, 0);

        // Dias do mês anterior
        for (let i = firstDay.getDay() - 1; i >= 0; i--) {
            const day = prevLastDay.getDate() - i;
            const dayEl = this.createDayElement(day, true);
            grid.appendChild(dayEl);
        }

        // Dias do mês atual
        for (let day = 1; day <= lastDay.getDate(); day++) {
            const dayEl = this.createDayElement(day, false, year, month);
            grid.appendChild(dayEl);
        }

        // Dias do próximo mês
        const totalCells = grid.children.length - 7; // Subtrai header
        const remainingCells = 42 - totalCells; // 6 linhas * 7 dias
        for (let day = 1; day <= remainingCells; day++) {
            const dayEl = this.createDayElement(day, true);
            grid.appendChild(dayEl);
        }

        this.calendar.appendChild(grid);
    }

    createDayElement(day, isOtherMonth, year = null, month = null) {
        const dayEl = document.createElement('div');
        dayEl.className = 'calendar-day';
        dayEl.textContent = day;

        if (isOtherMonth) {
            dayEl.classList.add('other-month');
        } else {
            const dateStr = this.formatDate(new Date(year, month, day));
            const trade = this.trades[dateStr];

            if (trade) {
                dayEl.classList.add('has-trade');
                if (trade.amount >= 0) {
                    dayEl.classList.add('positive');
                } else {
                    dayEl.classList.add('negative');
                }
            }

            dayEl.addEventListener('click', () => this.selectDate(new Date(year, month, day)));

            if (this.dateOnly(new Date()).toISOString() === dateStr) {
                dayEl.classList.add('selected');
            }
        }

        return dayEl;
    }

    selectDate(date) {
        this.selectedDate = this.dateOnly(date);
        this.loadCalendar();
        this.loadDayTrade();
    }

    // ===== TRADES =====

    async loadDayTrade() {
        const dateStr = this.formatDate(this.selectedDate);
        this.selectedDateDisplay.textContent = this.formatDateDisplay(this.selectedDate);

        const trade = this.trades[dateStr];

        if (trade) {
            document.getElementById('tradeAmount').value = trade.amount;
            document.getElementById('tradeNotes').value = trade.notes || '';
            this.showDayResult(trade.amount);
        } else {
            document.getElementById('tradeAmount').value = '';
            document.getElementById('tradeNotes').value = '';
            this.hideDayResult();
        }
    }

    async handleSaveTrade(e) {
        e.preventDefault();

        const amount = parseFloat(document.getElementById('tradeAmount').value);
        const notes = document.getElementById('tradeNotes').value;

        if (isNaN(amount)) {
            this.showTradeMessage('Digite um valor válido', 'error');
            return;
        }

        try {
            const dateStr = this.formatDate(this.selectedDate);
            await supabase.saveTrade(dateStr, amount, notes);

            this.trades[dateStr] = { amount, notes };
            this.showTradeMessage('Registro salvo com sucesso!', 'success');
            this.showDayResult(amount);
            this.loadCalendar();

            setTimeout(() => this.showTradeMessage('', ''), 2000);
        } catch (error) {
            this.showTradeMessage('Erro ao salvar: ' + error.message, 'error');
        }
    }

    showDayResult(amount) {
        this.dayResult.classList.remove('hidden');
        this.dayAmount.textContent = this.formatCurrency(amount);
        this.dayAmount.className = 'result-amount ' + (amount >= 0 ? 'positive' : 'negative');
    }

    hideDayResult() {
        this.dayResult.classList.add('hidden');
    }

    showTradeMessage(message, type) {
        this.tradeMessage.textContent = message;
        this.tradeMessage.className = `message show ${type}`;
    }

    // ===== RELATÓRIOS =====

    async loadReports() {
        await this.loadTradesForPeriod();
        this.renderReportData();
    }

    async loadTradesForPeriod() {
        const period = this.getPeriodDates();
        const startDate = this.formatDate(period.start);
        const endDate = this.formatDate(period.end);

        try {
            const trades = await supabase.getTrades(startDate, endDate);
            this.trades = {};
            trades.forEach(trade => {
                this.trades[trade.date] = trade;
            });
        } catch (error) {
            console.error('Erro ao carregar trades:', error);
        }
    }

    changePeriod(period) {
        this.currentPeriod = period;
        document.querySelectorAll('.period-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-period="${period}"]`).classList.add('active');
        this.loadReports();
    }

    renderReportData() {
        const period = this.getPeriodDates();
        const trades = Object.values(this.trades);

        // Calcula totais
        const total = trades.reduce((sum, t) => sum + t.amount, 0);
        const positive = trades.filter(t => t.amount > 0).length;
        const negative = trades.filter(t => t.amount < 0).length;

        this.periodTotal.textContent = this.formatCurrency(total);
        this.periodTotal.className = 'summary-amount ' + (total >= 0 ? 'positive' : 'negative');
        this.positiveDays.textContent = positive;
        this.negativeDays.textContent = negative;

        // Renderiza gráfico
        this.renderChart(trades, period);

        // Renderiza tabela
        this.renderTable(trades);
    }

    renderChart(trades, period) {
        const ctx = this.performanceChart.getContext('2d');

        // Agrupa trades por dia
        const dailyData = {};
        trades.forEach(trade => {
            dailyData[trade.date] = trade.amount;
        });

        // Gera labels e dados
        const labels = [];
        const data = [];
        let current = new Date(period.start);

        while (current <= period.end) {
            const dateStr = this.formatDate(current);
            labels.push(this.formatDateShort(current));
            data.push(dailyData[dateStr] || 0);
            current.setDate(current.getDate() + 1);
        }

        if (this.chart) {
            this.chart.destroy();
        }

        this.chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels,
                datasets: [{
                    label: 'Resultado (R$)',
                    data,
                    backgroundColor: data.map(v => v >= 0 ? '#10b981' : '#ef4444'),
                    borderColor: data.map(v => v >= 0 ? '#059669' : '#dc2626'),
                    borderWidth: 1,
                    borderRadius: 6,
                }],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false,
                    },
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: {
                            color: '#334155',
                        },
                        ticks: {
                            color: '#cbd5e1',
                            callback: (value) => 'R$ ' + value.toFixed(2),
                        },
                    },
                    x: {
                        grid: {
                            display: false,
                        },
                        ticks: {
                            color: '#cbd5e1',
                        },
                    },
                },
            },
        });
    }

    renderTable(trades) {
        this.tableBody.innerHTML = '';

        trades.sort((a, b) => new Date(b.date) - new Date(a.date)).forEach(trade => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${this.formatDateDisplay(new Date(trade.date))}</td>
                <td class="${trade.amount >= 0 ? 'positive' : 'negative'}">
                    ${this.formatCurrency(trade.amount)}
                </td>
            `;
            this.tableBody.appendChild(row);
        });
    }

    getPeriodDates() {
        const today = new Date();
        let start, end;

        switch (this.currentPeriod) {
            case 'weekly':
                start = new Date(today);
                start.setDate(today.getDate() - today.getDay());
                end = new Date(start);
                end.setDate(start.getDate() + 6);
                break;
            case 'monthly':
                start = new Date(today.getFullYear(), today.getMonth(), 1);
                end = new Date(today.getFullYear(), today.getMonth() + 1, 0);
                break;
            case 'quarterly':
                const quarter = Math.floor(today.getMonth() / 3);
                start = new Date(today.getFullYear(), quarter * 3, 1);
                end = new Date(today.getFullYear(), quarter * 3 + 3, 0);
                break;
            case 'semiannual':
                const half = today.getMonth() < 6 ? 0 : 6;
                start = new Date(today.getFullYear(), half, 1);
                end = new Date(today.getFullYear(), half + 6, 0);
                break;
            case 'annual':
                start = new Date(today.getFullYear(), 0, 1);
                end = new Date(today.getFullYear(), 11, 31);
                break;
        }

        return { start, end };
    }

    // ===== UTILITÁRIOS =====

    dateOnly(date) {
        const d = new Date(date);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    formatDate(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    formatDateDisplay(date) {
        return date.toLocaleDateString('pt-BR', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric',
        });
    }

    formatDateShort(date) {
        return date.toLocaleDateString('pt-BR', {
            month: 'short',
            day: 'numeric',
        });
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('pt-BR', {
            style: 'currency',
            currency: 'BRL',
        }).format(value);
    }

    monthName(month) {
        const months = [
            'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
            'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
        ];
        return months[month];
    }
}

// Inicializa a aplicação quando o DOM está pronto
document.addEventListener('DOMContentLoaded', () => {
    window.app = new TradeApp();
});
