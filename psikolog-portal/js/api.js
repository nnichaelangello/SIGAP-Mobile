/**
 * SIGAP Psikolog Portal — API Client
 * Handles all HTTP communication with the Go backend.
 *
 * FIX: `request` kini diekspos sebagai method publik (`SigapAPI.request`)
 * agar app.js dapat memanggil endpoint kustom (stats-psikolog, session-notes, dll)
 * tanpa menyebabkan TypeError: SigapAPI.request is not a function.
 */

const SigapAPI = (() => {
  let BASE_URL = localStorage.getItem('sigap_server_url') || 'http://localhost:8080';
  let authToken = localStorage.getItem('sigap_token') || null;
  let currentUser = JSON.parse(localStorage.getItem('sigap_user') || 'null');

  function getHeaders() {
    const h = { 'Content-Type': 'application/json' };
    if (authToken) h['Authorization'] = `Bearer ${authToken}`;
    return h;
  }

  async function request(method, path, body = null) {
    try {
      const opts = { method, headers: getHeaders() };
      if (body) opts.body = JSON.stringify(body);
      const resp = await fetch(`${BASE_URL}${path}`, opts);
      const data = await resp.json().catch(() => ({}));
      return { ok: resp.ok, status: resp.status, data };
    } catch (e) {
      return { ok: false, status: 0, data: { error: 'Server tidak dapat dihubungi' } };
    }
  }

  return {
    get baseUrl() { return BASE_URL; },
    get token() { return authToken; },
    get user() { return currentUser; },
    get isLoggedIn() { return !!authToken; },

    // ── WAJIB: Expose request() secara publik ────────────────────────────────
    // app.js memanggil SigapAPI.request(...) langsung untuk endpoint kustom
    // seperti /api/dashboard/stats-psikolog, /api/session-notes, dll.
    // Tanpa ini, setiap panggilan akan throw TypeError dan halaman stuck di
    // "Memuat data...".
    request,

    setBaseUrl(url) {
      BASE_URL = url.replace(/\/+$/, '');
      localStorage.setItem('sigap_server_url', BASE_URL);
    },

    async health() {
      return request('GET', '/api/health');
    },

    async login(email, password) {
      const resp = await request('POST', '/api/auth/login', { email, password });
      if (resp.ok) {
        authToken = resp.data.token;
        currentUser = resp.data.user;
        localStorage.setItem('sigap_token', authToken);
        localStorage.setItem('sigap_user', JSON.stringify(currentUser));
      }
      return resp;
    },

    logout() {
      authToken = null;
      currentUser = null;
      localStorage.removeItem('sigap_token');
      localStorage.removeItem('sigap_user');
    },

    // User
    async getMe()        { return request('GET', '/api/auth/me'); },
    async getUsers(role) { return request('GET', `/api/users${role ? '?role=' + role : ''}`); },
    async getStats()     { return request('GET', '/api/dashboard/stats'); },

    // Reports
    async getReports(status)       { return request('GET', `/api/reports${status ? '?status=' + status : ''}`); },
    async getReport(id)            { return request('GET', `/api/reports/${id}`); },
    async updateReportStatus(body) { return request('PUT', '/api/reports/status', body); },

    // Emergency
    async getPendingEmergencies()      { return request('GET', '/api/emergency/pending'); },
    async getAllEmergencies()          { return request('GET', '/api/emergency/pending?status=all'); },
    async getEmergencyDetail(dbId)    { return request('GET', `/api/emergency/${dbId}/location`); },
    async getEmergencyAudios(incidentId) {
      return request('GET', `/api/emergency/audio?incident_id=${encodeURIComponent(incidentId)}`);
    },
    async resolveEmergency(id) { return request('POST', '/api/emergency/resolve', { incident_db_id: id }); },

    // Notifications
    async getNotifications() { return request('GET', '/api/notifications'); },
    async markRead(id)       { return request('POST', '/api/notifications/read', { notification_id: id }); },

    // Database viewer
    async getDatabase(table) { return request('GET', `/api/database${table ? '?table=' + table : ''}`); },

    // Appointments
    async getAppointments() { return request('GET', '/api/appointments'); },
    async initiateAppointment(reportId, psikologId) {
      return request('POST', '/api/appointments/initiate', { report_id: reportId, psikolog_id: psikologId });
    },
    async completeSession(appointmentId) {
      return request('POST', '/api/appointments/complete', { appointment_id: appointmentId });
    },
    async selectAppointment(appointmentId, tanggal, jamMulai, jamSelesai) {
      return request('POST', '/api/appointments/select', {
        appointment_id: appointmentId, tanggal, jam_mulai: jamMulai, jam_selesai: jamSelesai
      });
    },
    async respondAppointment(appointmentId, action, catatan, linkLokasi) {
      return request('POST', '/api/appointments/respond', {
        appointment_id: appointmentId, action, catatan: catatan || '', link_lokasi: linkLokasi || ''
      });
    },
    async completeAppointment(appointmentId) {
      return request('POST', '/api/appointments/complete', { appointment_id: appointmentId });
    },

    // Psikolog schedules
    async getPsikologList()                { return request('GET', '/api/users?role=psikolog'); },
    async getPsikologSchedules(psikologId) { return request('GET', `/api/schedules/psikolog?psikolog_id=${psikologId}`); },
    async addPsikologSchedule(hari, jamMulai, jamSelesai) {
      return request('POST', '/api/schedules/psikolog', { hari, jam_mulai: jamMulai, jam_selesai: jamSelesai });
    },
    async deletePsikologSchedule(scheduleId) {
      return request('DELETE', '/api/schedules/psikolog', { schedule_id: scheduleId });
    },
  };
})();
