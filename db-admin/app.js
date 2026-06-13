// ════════════════════════════════════════════════════════════
//  SIGAP DB Admin — Application Logic
// ════════════════════════════════════════════════════════════

const API_BASE = window.location.origin;

const App = {
    token: null,
    currentTable: null,
    currentPage: 1,
    tableSchema: [],
    columnNames: [],
    editingRow: null,
    deletingRow: null,
    searchTimeout: null,

    // ═══ INIT ═══
    init() {
        this.token = localStorage.getItem('db_admin_token');
        if (this.token) {
            this.verifyToken();
        }
        document.getElementById('login-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.login();
        });
    },

    // ═══ AUTH ═══
    async login() {
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;
        const errEl = document.getElementById('login-error');
        const btn = document.getElementById('login-btn');

        btn.disabled = true;
        btn.innerHTML = '<span>Memproses...</span>';

        try {
            const res = await fetch(`${API_BASE}/api/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email, password })
            });
            const data = await res.json();

            if (!res.ok) throw new Error(data.error || 'Login gagal');
            if (data.user.role !== 'admin') throw new Error('Hanya admin yang bisa mengakses DB Manager');

            this.token = data.token;
            localStorage.setItem('db_admin_token', data.token);
            document.getElementById('user-info').textContent = `👤 ${data.user.nama_lengkap}`;
            this.showApp();
        } catch (err) {
            errEl.textContent = err.message;
            errEl.style.display = 'block';
        } finally {
            btn.disabled = false;
            btn.innerHTML = '<span>Masuk ke Database</span>';
        }
    },

    async verifyToken() {
        try {
            const res = await this.apiGet('/api/auth/me');
            if (res.data && res.data.role === 'admin') {
                document.getElementById('user-info').textContent = `👤 ${res.data.nama_lengkap}`;
                this.showApp();
            } else {
                this.logout();
            }
        } catch {
            this.logout();
        }
    },

    logout() {
        if (!confirm("Apakah Anda yakin ingin keluar dari aplikasi?")) return;
        this.token = null;
        localStorage.removeItem('db_admin_token');
        document.getElementById('app').style.display = 'none';
        document.getElementById('login-screen').style.display = 'flex';
    },

    showApp() {
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('app').style.display = 'flex';
        document.getElementById('app').style.flexDirection = 'column';
        this.loadTables();
    },

    // ═══ API HELPERS ═══
    async apiGet(path) {
        const res = await fetch(`${API_BASE}${path}`, {
            headers: { 'Authorization': `Bearer ${this.token}` }
        });
        if (res.status === 401) { this.logout(); throw new Error('Session expired'); }
        return res.json();
    },

    async apiPost(path, body) {
        const res = await fetch(`${API_BASE}${path}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.token}`
            },
            body: JSON.stringify(body)
        });
        if (res.status === 401) { this.logout(); throw new Error('Session expired'); }
        return res.json();
    },

    async apiPut(path, body) {
        const res = await fetch(`${API_BASE}${path}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.token}`
            },
            body: JSON.stringify(body)
        });
        if (res.status === 401) { this.logout(); throw new Error('Session expired'); }
        return res.json();
    },

    // ═══ TABLE LIST ═══
    async loadTables() {
        const listEl = document.getElementById('table-list');
        try {
            const data = await this.apiGet('/api/database');
            listEl.innerHTML = data.tables.map(t => `
                <div class="table-item ${this.currentTable === t.name ? 'active' : ''}" onclick="App.selectTable('${t.name}')">
                    <span class="table-item-name">${t.name}</span>
                    <span class="table-item-count">${t.count}</span>
                </div>
            `).join('');
        } catch (err) {
            listEl.innerHTML = `<div class="loading-spinner">Gagal memuat: ${err.message}</div>`;
        }
    },

    // ═══ SELECT TABLE ═══
    async selectTable(name) {
        this.currentTable = name;
        this.currentPage = 1;
        document.getElementById('search-input').value = '';
        this.loadTables();  // Refresh active state
        this.loadTableData();
    },

    // ═══ LOAD TABLE DATA ═══
    async loadTableData() {
        const tableView = document.getElementById('table-view');
        const welcome = document.getElementById('welcome-screen');
        const sqlView = document.getElementById('sql-view');

        welcome.style.display = 'none';
        sqlView.style.display = 'none';
        tableView.style.display = 'block';

        document.getElementById('table-title').textContent = this.currentTable;
        const container = document.getElementById('table-container');
        container.innerHTML = '<div class="loading-spinner">Memuat data...</div>';

        const search = document.getElementById('search-input').value;
        let url = `/api/database?table=${this.currentTable}&page=${this.currentPage}&limit=50`;
        if (search) url += `&search=${encodeURIComponent(search)}`;

        try {
            const data = await this.apiGet(url);
            this.tableSchema = data.columns || [];
            this.columnNames = data.column_names || [];

            document.getElementById('row-count').textContent = `${data.total} baris`;
            this.renderTable(data);
            this.renderPagination(data);
        } catch (err) {
            container.innerHTML = `<div class="loading-spinner">Error: ${err.message}</div>`;
        }
    },

    // ═══ RENDER TABLE ═══
    renderTable(data) {
        const container = document.getElementById('table-container');
        if (!data.data.length) {
            container.innerHTML = '<div class="loading-spinner">Tabel kosong — belum ada data</div>';
            return;
        }

        const cols = data.column_names || Object.keys(data.data[0]);
        const schemaMap = {};
        (data.columns || []).forEach(c => { schemaMap[c.name] = c; });

        let html = '<table class="data-table"><thead><tr>';
        html += '<th style="width:80px">#</th>';
        cols.forEach(col => {
            const schema = schemaMap[col] || {};
            let badges = '';
            if (schema.pk) badges += '<span class="schema-badge schema-pk">PK</span>';
            if (schema.notnull) badges += '<span class="schema-badge schema-notnull">NOT NULL</span>';
            if (schema.type) badges += '<span class="schema-badge schema-type">' + schema.type + '</span>';
            html += `<th>${col}${badges}</th>`;
        });
        html += '<th style="width:120px">Aksi</th></tr></thead><tbody>';

        data.data.forEach(row => {
            html += '<tr>';
            const rowId = row.id || row.ID;
            html += `<td class="cell-id">${rowId}</td>`;
            cols.forEach(col => {
                const val = row[col];
                if (val === null || val === undefined || val === '') {
                    html += '<td class="cell-null">NULL</td>';
                } else if (typeof val === 'number') {
                    html += `<td class="cell-number">${val}</td>`;
                } else {
                    const str = String(val);
                    const display = str.length > 60 ? str.substring(0, 60) + '…' : str;
                    html += `<td title="${this.escapeHtml(str)}">${this.escapeHtml(display)}</td>`;
                }
            });
            html += `<td class="row-actions">
                <button class="btn btn-xs btn-ghost" onclick="App.openEditModal(${rowId})">✏️</button>
                <button class="btn btn-xs btn-danger" onclick="App.openDeleteModal(${rowId})">🗑️</button>
            </td>`;
            html += '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    },

    // ═══ RENDER PAGINATION ═══
    renderPagination(data) {
        const pag = document.getElementById('pagination');
        if (data.total_pages <= 1) { pag.innerHTML = ''; return; }

        let html = '';
        if (this.currentPage > 1) {
            html += `<button class="btn btn-sm btn-ghost" onclick="App.goToPage(${this.currentPage - 1})">← Prev</button>`;
        }

        for (let i = 1; i <= Math.min(data.total_pages, 10); i++) {
            html += `<button class="btn btn-sm ${i === this.currentPage ? 'active' : 'btn-ghost'}" onclick="App.goToPage(${i})">${i}</button>`;
        }

        if (data.total_pages > 10) {
            html += `<span style="color:var(--text-muted)">... ${data.total_pages}</span>`;
        }

        if (this.currentPage < data.total_pages) {
            html += `<button class="btn btn-sm btn-ghost" onclick="App.goToPage(${this.currentPage + 1})">Next →</button>`;
        }

        pag.innerHTML = html;
    },

    goToPage(page) {
        this.currentPage = page;
        this.loadTableData();
    },

    // ═══ SEARCH ═══
    debounceSearch() {
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.currentPage = 1;
            this.loadTableData();
        }, 400);
    },

    // ═══ INSERT MODAL ═══
    openInsertModal() {
        const body = document.getElementById('insert-form-body');
        let html = '';
        this.tableSchema.forEach(col => {
            if (col.name === 'id') return; // Skip auto-increment
            if (col.name === 'created_at' || col.name === 'updated_at') return; // Skip timestamps
            const required = col.notnull && !col.default ? 'required' : '';
            const type = col.type.includes('INT') ? 'number' : 'text';
            html += `<div class="form-group">
                <label>${col.name} <span class="schema-badge schema-type">${col.type}</span>
                ${col.notnull ? '<span class="schema-badge schema-notnull">REQUIRED</span>' : ''}</label>
                <input type="${type}" name="${col.name}" placeholder="${col.name}" ${required}>
            </div>`;
        });
        body.innerHTML = html;
        document.getElementById('insert-modal').style.display = 'flex';
    },

    async submitInsert() {
        const formBody = document.getElementById('insert-form-body');
        const inputs = formBody.querySelectorAll('input, textarea, select');
        const data = {};

        inputs.forEach(input => {
            const val = input.value.trim();
            if (val !== '') {
                data[input.name] = input.type === 'number' ? Number(val) : val;
            }
        });

        try {
            const res = await this.apiPost('/api/database/insert', {
                table: this.currentTable,
                data: data
            });
            this.closeModal('insert-modal');
            this.toast('success', `Data berhasil ditambahkan (ID: ${res.inserted_id})`);
            this.loadTableData();
            this.loadTables();
        } catch (err) {
            this.toast('error', err.message);
        }
    },

    // ═══ EDIT MODAL ═══
    async openEditModal(id) {
        this.editingRow = id;
        const data = await this.apiGet(`/api/database?table=${this.currentTable}&search=${id}&limit=500`);
        const row = data.data.find(r => r.id === id || r.ID === id);
        if (!row) { this.toast('error', 'Data tidak ditemukan'); return; }

        const body = document.getElementById('edit-form-body');
        let html = '';
        this.tableSchema.forEach(col => {
            if (col.name === 'id') return;
            const val = row[col.name] ?? '';
            const type = col.type.includes('INT') ? 'number' : 'text';
            const isTimestamp = col.name === 'created_at' || col.name === 'updated_at';
            html += `<div class="form-group">
                <label>${col.name} <span class="schema-badge schema-type">${col.type}</span></label>
                <input type="${type}" name="${col.name}" value="${this.escapeHtml(String(val))}" ${isTimestamp ? 'disabled' : ''}>
            </div>`;
        });
        body.innerHTML = html;
        document.getElementById('edit-modal').style.display = 'flex';
    },

    async submitEdit() {
        const formBody = document.getElementById('edit-form-body');
        const inputs = formBody.querySelectorAll('input:not([disabled]), textarea:not([disabled]), select:not([disabled])');
        const data = {};

        inputs.forEach(input => {
            const val = input.value.trim();
            data[input.name] = input.type === 'number' && val !== '' ? Number(val) : val;
        });

        try {
            await this.apiPut('/api/database/update', {
                table: this.currentTable,
                id: this.editingRow,
                data: data
            });
            this.closeModal('edit-modal');
            this.toast('success', 'Data berhasil diperbarui');
            this.loadTableData();
        } catch (err) {
            this.toast('error', err.message);
        }
    },

    // ═══ DELETE ═══
    openDeleteModal(id) {
        this.deletingRow = id;
        document.getElementById('delete-message').textContent =
            `Apakah Anda yakin ingin menghapus baris ID #${id} dari tabel "${this.currentTable}"?`;
        document.getElementById('delete-modal').style.display = 'flex';
    },

    async confirmDelete() {
        try {
            await this.apiPost('/api/database/delete', {
                table: this.currentTable,
                id: this.deletingRow
            });
            this.closeModal('delete-modal');
            this.toast('success', `Baris #${this.deletingRow} berhasil dihapus`);
            this.loadTableData();
            this.loadTables();
        } catch (err) {
            this.toast('error', err.message);
        }
    },

    // ═══ SQL QUERY ═══
    openQueryEditor() {
        document.getElementById('welcome-screen').style.display = 'none';
        document.getElementById('table-view').style.display = 'none';
        document.getElementById('sql-view').style.display = 'block';
        document.getElementById('sql-result').innerHTML = '';

        // Deselect table in sidebar
        document.querySelectorAll('.table-item').forEach(el => el.classList.remove('active'));
    },

    closeSqlView() {
        document.getElementById('sql-view').style.display = 'none';
        if (this.currentTable) {
            document.getElementById('table-view').style.display = 'block';
        } else {
            document.getElementById('welcome-screen').style.display = 'flex';
        }
    },

    async executeQuery() {
        const sql = document.getElementById('sql-input').value.trim();
        if (!sql) return;

        const resultEl = document.getElementById('sql-result');
        resultEl.innerHTML = '<div class="loading-spinner">Menjalankan query...</div>';

        try {
            const data = await this.apiPost('/api/database/query', { sql });

            if (!data.data || !data.data.length) {
                resultEl.innerHTML = '<div class="loading-spinner">Query berhasil — 0 baris dikembalikan</div>';
                return;
            }

            const cols = data.columns || Object.keys(data.data[0]);
            let html = `<p style="margin-bottom:8px;color:var(--green)">✅ ${data.total} baris dikembalikan</p>`;
            html += '<div class="table-container" style="max-height:300px"><table class="data-table"><thead><tr>';
            cols.forEach(c => { html += `<th>${c}</th>`; });
            html += '</tr></thead><tbody>';

            data.data.forEach(row => {
                html += '<tr>';
                cols.forEach(c => {
                    const val = row[c];
                    if (val === null || val === undefined) {
                        html += '<td class="cell-null">NULL</td>';
                    } else if (typeof val === 'number') {
                        html += `<td class="cell-number">${val}</td>`;
                    } else {
                        html += `<td>${this.escapeHtml(String(val))}</td>`;
                    }
                });
                html += '</tr>';
            });

            html += '</tbody></table></div>';
            resultEl.innerHTML = html;
        } catch (err) {
            resultEl.innerHTML = `<div style="color:var(--red);padding:12px">❌ ${err.message}</div>`;
        }
    },

    // ═══ EXPORT CSV ═══
    async exportCSV() {
        try {
            const data = await this.apiGet(`/api/database?table=${this.currentTable}&limit=500`);
            if (!data.data.length) { this.toast('error', 'Tidak ada data untuk di-export'); return; }

            const cols = data.column_names || Object.keys(data.data[0]);
            let csv = cols.join(',') + '\n';
            data.data.forEach(row => {
                csv += cols.map(c => {
                    const val = row[c];
                    if (val === null || val === undefined) return '';
                    const str = String(val);
                    return str.includes(',') || str.includes('"') ? `"${str.replace(/"/g, '""')}"` : str;
                }).join(',') + '\n';
            });

            const blob = new Blob([csv], { type: 'text/csv' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `${this.currentTable}_${new Date().toISOString().split('T')[0]}.csv`;
            a.click();
            URL.revokeObjectURL(url);
            this.toast('success', 'CSV berhasil di-export');
        } catch (err) {
            this.toast('error', err.message);
        }
    },

    // ═══ REFRESH ═══
    refreshCurrentTable() {
        if (this.currentTable) {
            this.loadTableData();
            this.loadTables();
            this.toast('info', 'Data di-refresh');
        }
    },

    // ═══ UTILS ═══
    closeModal(id) {
        document.getElementById(id).style.display = 'none';
    },

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    toast(type, message) {
        const container = document.getElementById('toast-container');
        const el = document.createElement('div');
        el.className = `toast toast-${type}`;
        el.textContent = message;
        container.appendChild(el);
        setTimeout(() => el.remove(), 3500);
    }
};

// ═══ BOOTSTRAP ═══
document.addEventListener('DOMContentLoaded', () => App.init());
