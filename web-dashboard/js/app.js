/**
 * SIGAP Dashboard — Main App Controller
 * Handles navigation, state, polling, SOS alert, and emergency monitoring.
 */

let currentPage = 'overview';
let dbTables = [];
let activeDbTable = '';
let pollInterval = null;

// State emergency monitor
let _emCurrentDbId = null;
let _emCurrentIncidentId = null;
let _emAudioPollTimer = null;
let _emPlayedAudioIds = new Set();
let _emAudioQueue = [];
let _emIsListening = false;
let _emPrevSosCount = 0;

// ══════════════════════════════════════════
// INIT
// ══════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('topbar-date').textContent =
    new Date().toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

  if (SigapAPI.isLoggedIn) {
    if (SigapAPI.user?.role === 'admin') {
      showDashboard();
    } else {
      SigapAPI.logout();
      showLogin();
    }
  } else {
    showLogin();
  }

  document.getElementById('login-form').addEventListener('submit', handleLogin);
  document.getElementById('btn-logout').addEventListener('click', handleLogout);
  document.getElementById('btn-refresh').addEventListener('click', refreshPage);
  document.getElementById('btn-menu').addEventListener('click', toggleSidebar);

  document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      navigateTo(item.dataset.page);
    });
  });

  document.getElementById('server-url-input').value = SigapAPI.baseUrl;
  checkServerStatus();
});

// ══════════════════════════════════════════
// AUTH
// ══════════════════════════════════════════

async function handleLogin(e) {
  e.preventDefault();
  const btn = document.getElementById('login-btn');
  const errorEl = document.getElementById('login-error');
  const btnText = btn.querySelector('.btn-text');
  const btnLoader = btn.querySelector('.btn-loader');

  btnText.style.display = 'none';
  btnLoader.style.display = 'inline-flex';
  errorEl.style.display = 'none';
  btn.disabled = true;

  const email = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;

  const resp = await SigapAPI.login(email, password);

  btnText.style.display = 'inline';
  btnLoader.style.display = 'none';
  btn.disabled = false;

  if (resp.ok) {
    const role = SigapAPI.user?.role;
    if (role !== 'admin') {
      SigapAPI.logout();
      errorEl.textContent = 'Akses Ditolak: Halaman ini hanya untuk Admin. Psikolog menggunakan Portal Psikolog.';
      errorEl.style.display = 'block';
      return;
    }
    showDashboard();
  } else {
    errorEl.textContent = resp.data?.error || 'Login gagal. Periksa email dan password.';
    errorEl.style.display = 'block';
  }
}

function handleLogout() {
  if (confirm("Apakah Anda yakin ingin keluar dari aplikasi?")) {
    SigapAPI.logout();
    if (pollInterval) clearInterval(pollInterval);
    stopEmergencyAudioPolling();
    showLogin();
  }
}

function showLogin() {
  document.getElementById('login-screen').style.display = 'flex';
  document.getElementById('dashboard').style.display = 'none';
}

function showDashboard() {
  document.getElementById('login-screen').style.display = 'none';
  document.getElementById('dashboard').style.display = 'flex';

  const user = SigapAPI.user;
  if (user) {
    document.getElementById('user-name').textContent = user.nama_lengkap || user.email;
    document.getElementById('user-role').textContent = 'Admin';
    document.getElementById('user-avatar').textContent = (user.nama_lengkap || 'A')[0].toUpperCase();
  }

  navigateTo('overview');
  startPolling();
}

// ══════════════════════════════════════════
// NAVIGATION
// ══════════════════════════════════════════

function navigateTo(page) {
  currentPage = page;

  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.toggle('active', item.dataset.page === page);
  });

  const titles = {
    overview: 'Overview',
    users: 'Pengguna',
    reports: 'Laporan',
    emergency: 'Darurat',
    appointments: 'Janji Temu Konsultasi',
    schedules: 'Jadwal Saya',
    pantau: 'Pantauan',
    database: 'Database Viewer',
  };
  document.getElementById('page-title').textContent = titles[page] || page;
  document.getElementById('sidebar').classList.remove('open');

  loadPage(page);
}

async function loadPage(page) {
  const content = document.getElementById('page-content');
  content.innerHTML = '<div style="text-align:center;padding:40px;color:var(--text-muted);">Memuat data...</div>';

  switch (page) {
    case 'overview':
      await loadOverview(content);
      break;
    case 'users':
      await loadUsers(content);
      break;
    case 'reports':
      await loadReports(content);
      break;
    case 'emergency':
      await loadEmergency(content);
      break;
    case 'appointments':
      await loadAppointments(content);
      break;
    case 'pantau':
      content.innerHTML = Pages.pantau();
      break;
    case 'database':
      await loadDatabase(content);
      break;
    default:
      content.innerHTML = '<div class="empty-state"><h4>Halaman tidak ditemukan</h4></div>';
  }
}

async function refreshPage() {
  await loadPage(currentPage);
}

// ══════════════════════════════════════════
// PAGE LOADERS
// ══════════════════════════════════════════

async function loadOverview(el) {
  const statsResp = await SigapAPI.getStats();
  if (!statsResp.ok) {
    el.innerHTML = '<div class="empty-state"><h4>Gagal memuat data</h4><p>' + (statsResp.data?.error || '') + '</p></div>';
    return;
  }

  el.innerHTML = Pages.overview(statsResp.data);

  const [reportsResp, emergencyResp] = await Promise.all([
    SigapAPI.getReports(),
    SigapAPI.getPendingEmergencies(),
  ]);

  if (reportsResp.ok) {
    document.getElementById('overview-reports').innerHTML = Pages.miniReportTable(reportsResp.data?.data);
    updateBadge('report-badge', reportsResp.data?.data?.filter(r => r.status === 'pending').length || 0);
  }
  if (emergencyResp.ok) {
    document.getElementById('overview-emergencies').innerHTML = Pages.miniEmergencyTable(emergencyResp.data?.data);
    updateBadge('emergency-badge', emergencyResp.data?.data?.length || 0);
  }
}

async function loadUsers(el, roleFilter = '') {
  const resp = await SigapAPI.getUsers(roleFilter);
  if (resp.ok) {
    el.innerHTML = Pages.users(resp.data?.data || []);
  } else {
    el.innerHTML = '<div class="empty-state"><h4>Gagal memuat pengguna</h4></div>';
  }
}

async function filterUsers(role) {
  await loadUsers(document.getElementById('page-content'), role);
  const sel = document.getElementById('user-role-filter');
  if (sel) sel.value = role;
}

async function loadReports(el, statusFilter = '') {
  const resp = await SigapAPI.getReports(statusFilter);
  if (resp.ok) {
    el.innerHTML = Pages.reports(resp.data?.data || []);
    updateBadge('report-badge', (resp.data?.data || []).filter(r => r.status === 'pending').length);
  } else {
    el.innerHTML = '<div class="empty-state"><h4>Gagal memuat laporan</h4></div>';
  }
}

async function filterReports(status) {
  await loadReports(document.getElementById('page-content'), status);
  const sel = document.getElementById('report-status-filter');
  if (sel) sel.value = status;
}

async function loadEmergency(el) {
  const resp = await SigapAPI.getAllEmergencies();
  if (resp.ok) {
    el.innerHTML = Pages.emergency(resp.data?.data || []);
  } else {
    el.innerHTML = '<div class="empty-state"><h4>Gagal memuat data darurat</h4></div>';
  }
}

async function loadAppointments(el) {
  const resp = await SigapAPI.getAppointments();
  if (resp.ok) {
    const data = resp.data?.data || [];
    el.innerHTML = Pages.appointments(data);
    // Update badge: jumlah yang perlu tindakan
    const pending = data.filter(a => ['menunggu_user','menunggu_psikolog','reschedule'].includes(a.status)).length;
    updateBadge('appointment-badge', pending);
  } else {
    el.innerHTML = '<div class="empty-state"><h4>Gagal memuat janji temu</h4></div>';
  }
}

async function loadMySchedules(el) {
  const user = SigapAPI.user;
  if (!user || user.role !== 'psikolog') {
    el.innerHTML = '<div class="empty-state"><h4>Akses Ditolak</h4></div>';
    return;
  }
  const resp = await SigapAPI.getPsikologSchedules(user.id);
  if (resp.ok) {
    el.innerHTML = Pages.mySchedules(resp.data?.data || []);
  } else {
    el.innerHTML = '<div class="empty-state"><h4>Gagal memuat jadwal</h4></div>';
  }
}

async function submitSchedule(event) {
  event.preventDefault();
  const form = event.target;
  const submitBtn = form.querySelector('button[type="submit"]');
  submitBtn.disabled = true;

  const hari = form.hari.value;
  const jamMulai = form.jam_mulai.value;
  const jamSelesai = form.jam_selesai.value;

  const resp = await SigapAPI.addPsikologSchedule(hari, jamMulai, jamSelesai);
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal menambah jadwal: ' + (resp.data?.error || ''));
    submitBtn.disabled = false;
  }
}

async function deleteSchedule(scheduleId) {
  if (!confirm('Hapus slot jadwal ini?')) return;
  const resp = await SigapAPI.deletePsikologSchedule(scheduleId);
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal menghapus jadwal: ' + (resp.data?.error || ''));
  }
}

// ══════════════════════════════════════════
// SCHEDULE MODAL — Admin jadwalkan psikolog
// ══════════════════════════════════════════

let _schedReportId = null;
let _schedSelectedPsikologId = null;

async function showScheduleModal(reportId, trackingCode, hasFollowUp = false) {
  if (!hasFollowUp) {
    if (!confirm("Psikolog tidak/belum menandai (mencentang) perlunya sesi lanjutan untuk laporan ini.\n\nApakah Anda yakin tetap ingin menjadwalkan sesi lanjutan?")) {
      return; // Batalkan aksi jika admin memilih cancel
    }
  }

  _schedReportId = reportId;
  _schedSelectedPsikologId = null;

  document.getElementById('sched-report-info').textContent = `Laporan: ${trackingCode || '#' + reportId}`;
  document.getElementById('sched-psikolog-select').innerHTML = '<option value="">-- Memuat psikolog... --</option>';
  document.getElementById('sched-psikolog-schedules').innerHTML = '';
  document.getElementById('sched-submit-btn').disabled = true;
  document.getElementById('sched-error').style.display = 'none';

  document.getElementById('schedule-modal').style.display = 'flex';

  // Fetch daftar psikolog
  const resp = await SigapAPI.getPsikologList();
  const select = document.getElementById('sched-psikolog-select');
  if (resp.ok && resp.data?.data?.length > 0) {
    select.innerHTML = '<option value="">-- Pilih Psikolog --</option>' +
      resp.data.data.map(p => `<option value="${p.id}">${p.nama_lengkap} (${p.email})</option>`).join('');
  } else {
    select.innerHTML = '<option value="">Tidak ada psikolog terdaftar</option>';
  }
}

async function onPsikologSelected(psikologId) {
  const schedDiv = document.getElementById('sched-psikolog-schedules');
  const submitBtn = document.getElementById('sched-submit-btn');
  _schedSelectedPsikologId = psikologId || null;

  if (!psikologId) {
    schedDiv.innerHTML = '';
    submitBtn.disabled = true;
    return;
  }

  schedDiv.innerHTML = '<div style="color:#888;font-size:0.85rem;">Memuat jadwal psikolog...</div>';
  const resp = await SigapAPI.getPsikologSchedules(psikologId);

  if (!resp.ok || !resp.data?.data?.length) {
    schedDiv.innerHTML = '<div style="background:#fef3c7;border:1px solid #f59e0b;border-radius:8px;padding:12px;font-size:0.85rem;color:#92400e;"><strong>⚠️ Psikolog ini belum memiliki slot jadwal aktif.</strong><br>Minta psikolog untuk mengatur jadwal terlebih dahulu di menu Jadwal Saya (Web Dashboard).</div>';
    submitBtn.disabled = true;
    return;
  }

  const hariMap = { senin:'Senin', selasa:'Selasa', rabu:'Rabu', kamis:'Kamis', jumat:'Jumat', sabtu:'Sabtu' };
  const slots = resp.data.data.map(s =>
    `<div style="display:inline-block;background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:6px 14px;margin:4px;font-size:0.82rem;color:#1d4ed8;font-weight:600;">${hariMap[s.hari] || s.hari}: ${s.jam_mulai}–${s.jam_selesai}</div>`
  ).join('');

  schedDiv.innerHTML = `
    <div style="margin-bottom:8px;font-size:0.78rem;font-weight:700;color:#374151;text-transform:uppercase;letter-spacing:0.04em;">Slot Jadwal Tersedia:</div>
    <div style="margin-bottom:4px;">${slots}</div>
    <div style="font-size:0.75rem;color:#6b7280;margin-top:6px;">User akan dapat memilih tanggal spesifik berdasarkan slot di atas.</div>
  `;
  submitBtn.disabled = false;
}

async function submitScheduleAppointment() {
  if (!_schedReportId || !_schedSelectedPsikologId) return;

  const submitBtn = document.getElementById('sched-submit-btn');
  const errDiv = document.getElementById('sched-error');
  const loadDiv = document.getElementById('sched-loading');

  submitBtn.disabled = true;
  loadDiv.style.display = 'block';
  errDiv.style.display = 'none';

  const resp = await SigapAPI.initiateAppointment(_schedReportId, parseInt(_schedSelectedPsikologId));

  loadDiv.style.display = 'none';

  if (resp.ok) {
    closeModal('schedule-modal');
    alert('✅ Konsultasi berhasil dijadwalkan! User akan mendapat notifikasi.');
    await refreshPage();
  } else {
    errDiv.textContent = '❌ Gagal: ' + (resp.data?.error || 'Terjadi kesalahan.');
    errDiv.style.display = 'block';
    submitBtn.disabled = false;
  }
}

// ══════════════════════════════════════════
// APPOINTMENT ACTIONS
// ══════════════════════════════════════════

async function respondAppointment(appointmentId, action) {
  let catatan = '';
  if (action === 'reschedule') {
    catatan = prompt('Masukkan alasan reschedule (wajib):');
    if (!catatan) return;
  }
  const resp = await SigapAPI.respondAppointment(appointmentId, action, catatan);
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal: ' + (resp.data?.error || ''));
  }
}

async function completeAppointment(appointmentId) {
  if (!confirm('Tandai janji temu ini sebagai selesai?')) return;
  const resp = await SigapAPI.completeAppointment(appointmentId);
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal: ' + (resp.data?.error || ''));
  }
}

async function loadDatabase(el) {
  if (dbTables.length === 0) {
    const resp = await SigapAPI.getDatabase();
    if (resp.ok) dbTables = resp.data?.tables || [];
  }

  if (!activeDbTable && dbTables.length > 0) {
    activeDbTable = typeof dbTables[0] === 'object' ? dbTables[0].name : dbTables[0];
  }

  let tableData = null;
  if (activeDbTable) {
    const resp = await SigapAPI.getDatabase(activeDbTable);
    if (resp.ok) tableData = resp.data;
  }

  el.innerHTML = Pages.database(dbTables, activeDbTable, tableData);
}

async function loadTable(tableName) {
  activeDbTable = tableName;
  await loadDatabase(document.getElementById('page-content'));
}

// ══════════════════════════════════════════
// REPORT ACTIONS
// ══════════════════════════════════════════

async function showReportDetail(id) {
  const resp = await SigapAPI.getReport(id);
  if (!resp.ok) {
    alert('Gagal memuat detail: ' + (resp.data?.error || ''));
    return;
  }

  const detail = Pages.reportDetail(resp.data);
  document.getElementById('detail-modal-title').textContent = detail.title;
  document.getElementById('detail-modal-body').innerHTML = detail.body;
  document.getElementById('detail-modal-footer').innerHTML = detail.footer;
  document.getElementById('detail-modal').style.display = 'flex';
}

async function updateReport(id, status, extra = {}) {
  const noteEl = document.getElementById('report-note');
  const catatan = noteEl ? noteEl.value.trim() : '';

  const body = { report_id: id, status: status, ...extra };

  if (catatan) {
    const user = SigapAPI.user;
    if (user?.role === 'admin') body.catatan_admin = catatan;
    else if (user?.role === 'psikolog') body.catatan_psikolog = catatan;
  }

  const resp = await SigapAPI.updateReportStatus(body);
  if (resp.ok) {
    closeModal('detail-modal');
    await refreshPage();
  } else {
    alert('Gagal update: ' + (resp.data?.error || ''));
  }
}

async function showCompleteForm(id) {
  if (confirm("Apakah Anda yakin ingin menutup laporan ini secara permanen?\n\n(Pastikan Psikolog sudah menyelesaikan sesinya, atau tidak diperlukan sesi lanjutan lagi)")) {
    const note = document.getElementById('report-note')?.value || '';
    const resp = await SigapAPI.updateReportStatus({ report_id: id, status: 'selesai', catatan_admin: note });
    if (resp.ok) {
      alert("Laporan berhasil ditutup (selesai).");
      closeModal('detail-modal');
      await refreshPage();
    } else {
      alert('Gagal menutup laporan: ' + (resp.data?.error || 'Unknown error'));
    }
  }
}

function showRejectForm(id) {
  const reason = prompt('Masukkan alasan penolakan:');
  if (reason) updateReport(id, 'ditolak', { alasan_tolak: reason });
}


// ══════════════════════════════════════════
// EMERGENCY MONITOR MODAL
// ══════════════════════════════════════════

async function showEmergencyMonitor(dbId) {
  _emCurrentDbId = dbId;
  _emPlayedAudioIds = new Set();
  _emAudioQueue = [];
  _emIsListening = false;

  // Reset UI
  document.getElementById('em-audio-list').innerHTML = '<div style="color:#aaa;font-size:0.8rem;text-align:center;padding:12px;">Memuat...</div>';
  document.getElementById('em-responders-list').innerHTML = 'Memuat...';
  document.getElementById('em-audio-player').style.display = 'none';
  document.getElementById('em-audio-toggle').textContent = '▶ Mulai Dengarkan';
  document.getElementById('em-audio-toggle').style.background = '#16a34a';
  document.getElementById('em-audio-indicator').textContent = '⏸ Berhenti';
  document.getElementById('em-audio-status').textContent = '';

  // Setup resolve button
  document.getElementById('em-resolve-btn').onclick = () => {
    if (confirm('Selesaikan insiden ini? Semua pihak akan mendapat notifikasi.')) {
      resolveFromMonitor(dbId);
    }
  };

  document.getElementById('emergency-monitor-modal').style.display = 'flex';
  await refreshEmergencyMonitor();
}

async function refreshEmergencyMonitor() {
  if (!_emCurrentDbId) return;

  const resp = await SigapAPI.getEmergencyDetail(_emCurrentDbId);
  if (!resp.ok) {
    document.getElementById('em-korban-nama').textContent = 'Gagal memuat data';
    return;
  }

  const d = resp.data;
  _emCurrentIncidentId = d.incident_id;

  document.getElementById('em-title').textContent = `🚨 Monitor: ${d.incident_id || 'Insiden'}`;
  document.getElementById('em-incident-id').textContent = `DB ID: ${_emCurrentDbId}`;
  document.getElementById('em-korban-nama').textContent = d.korban_nama || '-';
  document.getElementById('em-korban-hp').textContent = d.korban_no_hp || 'No HP tidak tersedia';

  // Status badge
  const statusColor = { 
    active: '#dc2626', 
    responding: '#d97706', 
    resolved: '#16a34a',
    cancelled: '#991b1b',
    stopped_by_user: '#4b5563'
  }[d.status] || '#888';
  
  const bgStyle = d.status === 'stopped_by_user' ? `background:#f3f4f6;color:${statusColor};border:1px solid #d1d5db;` : `background:${statusColor};color:white;`;

  document.getElementById('em-status-dur').innerHTML =
    `<span style="${bgStyle}padding:3px 10px;border-radius:8px;font-size:0.78rem;font-weight:700;">${(d.status||'').toUpperCase()}</span>`;

  // Maps link
  if (d.korban_lat && d.korban_lng) {
    document.getElementById('em-maps-link').href = `https://www.google.com/maps?q=${d.korban_lat},${d.korban_lng}`;
  }

  // Responders
  const responders = d.responders || [];
  if (responders.length === 0) {
    document.getElementById('em-responders-list').innerHTML =
      '<span style="color:#aaa;font-size:0.85rem;">Belum ada responder yang merespon.</span>';
  } else {
    document.getElementById('em-responders-list').innerHTML = responders.map(r => `
      <div style="display:flex;align-items:center;gap:10px;padding:8px;background:#f9fafb;border-radius:8px;margin-bottom:6px;">
        <span style="font-size:1.2rem;">${r.is_primary ? '⭐' : '🏃'}</span>
        <div style="flex:1;">
          <div style="font-weight:600;font-size:0.85rem;">${r.nama || 'Responder'}</div>
          <div style="font-size:0.75rem;color:#888;">Status: <strong>${r.status || '-'}</strong> ${r.is_primary ? '· Responder Utama' : ''}</div>
        </div>
        ${(r.lat || r.responder_lat) ? `<a href="https://www.google.com/maps?q=${r.lat||r.responder_lat},${r.lng||r.responder_lng}" target="_blank" style="font-size:0.75rem;color:#2563eb;text-decoration:none;">📍 Lokasi</a>` : ''}
      </div>
    `).join('');
  }

  // Load audio list (non-live, just history)
  await refreshEmergencyAudioList();
}

async function refreshEmergencyAudioList() {
  if (!_emCurrentIncidentId) return;

  const resp = await SigapAPI.getEmergencyAudios(_emCurrentIncidentId);
  const audios = (resp.ok && resp.data?.data?.data) ? resp.data.data.data : [];

  if (!Array.isArray(audios) || audios.length === 0) {
    document.getElementById('em-audio-list').innerHTML =
      '<div style="color:#aaa;font-size:0.8rem;text-align:center;padding:12px;">Belum ada rekaman audio.</div>';
    return;
  }

  // Render audio list — setiap chunk bisa diklik untuk diputar
  document.getElementById('em-audio-list').innerHTML = audios.map((a, i) => {
    const t = new Date(a.created_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    const url = `${SigapAPI.baseUrl}/${a.file_path}`;
    return `
      <div style="display:flex;align-items:center;gap:8px;padding:8px 12px;background:#fff;border-radius:8px;border:1px solid #e5e7eb;box-shadow:0 1px 2px rgba(0,0,0,0.05);">
        <span style="font-size:0.75rem;color:#16a34a;font-weight:700;min-width:32px;background:#f0fdf4;padding:2px 6px;border-radius:4px;text-align:center;">#${i+1}</span>
        <span style="font-size:0.8rem;color:#555;flex:1;font-weight:500;">Waktu: ${t}</span>
        <audio src="${url}" controls style="height:32px;width:200px;"></audio>
      </div>
    `;
  }).join('');

  // Jika streaming aktif, tambah chunk baru ke queue
  if (_emIsListening) {
    audios.forEach(a => {
      if (!_emPlayedAudioIds.has(a.id)) {
        _emPlayedAudioIds.add(a.id);
        _emAudioQueue.push(`${SigapAPI.baseUrl}/${a.file_path}`);
      }
    });
    _playNextEmergencyChunk();
  }
}

function toggleEmergencyAudio() {
  const player = document.getElementById('em-audio-player');
  if (_emIsListening) {
    stopEmergencyAudioPolling();
    document.getElementById('em-audio-toggle').textContent = '▶ Dengarkan Real-Time';
    document.getElementById('em-audio-toggle').style.background = '#16a34a';
    document.getElementById('em-audio-indicator').textContent = '⏸ Berhenti';
    document.getElementById('em-audio-status').textContent = 'Live streaming dihentikan.';
    player.pause();
    player.src = '';
  } else {
    // Unlock audio context untuk browser autoplay policy (dengan user gesture)
    player.src = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';
    player.play().then(() => {
      player.pause();
      player.src = '';
    }).catch(e => console.warn('Unlock failed:', e));

    startEmergencyAudioStreaming();
    document.getElementById('em-audio-toggle').textContent = '⏹ Stop Mendengarkan';
    document.getElementById('em-audio-toggle').style.background = '#dc2626';
    document.getElementById('em-audio-indicator').textContent = '🔴 LIVE';
    document.getElementById('em-audio-status').textContent = 'Menunggu potongan rekaman audio berikutnya...';
  }
}

function startEmergencyAudioStreaming() {
  _emIsListening = true;
  _emPlayedAudioIds = new Set();
  _emAudioQueue = [];

  // Langsung fetch pertama kali
  refreshEmergencyAudioList();

  // Polling setiap 3 detik untuk chunk baru
  _emAudioPollTimer = setInterval(() => {
    refreshEmergencyAudioList();
  }, 3000);
}

function stopEmergencyAudioPolling() {
  _emIsListening = false;
  if (_emAudioPollTimer) { clearInterval(_emAudioPollTimer); _emAudioPollTimer = null; }
}

function _playNextEmergencyChunk() {
  if (!_emIsListening || _emAudioQueue.length === 0) return;

  const player = document.getElementById('em-audio-player');
  if (player.paused || player.ended || player.src === '' || player.src.startsWith('data:audio')) {
    const url = _emAudioQueue.shift();
    player.style.display = 'block';
    player.src = url;
    player.play().then(() => {
        document.getElementById('em-audio-status').textContent = `🔊 Sedang memutar: ${url.split('/').pop()}`;
    }).catch((e) => {
        console.error('Audio play error:', e);
        document.getElementById('em-audio-status').textContent = '❌ Gagal memutar audio otomatis (Browser memblokir autoplay). Klik player untuk memutar.';
    });

    // Saat selesai, langsung mainkan chunk berikutnya
    player.onended = () => { 
        document.getElementById('em-audio-status').textContent = 'Menunggu potongan rekaman audio berikutnya...';
        _playNextEmergencyChunk(); 
    };
  }
}

function closeEmergencyMonitor() {
  stopEmergencyAudioPolling();
  const player = document.getElementById('em-audio-player');
  player.pause();
  player.src = '';
  _emCurrentDbId = null;
  _emCurrentIncidentId = null;
  document.getElementById('emergency-monitor-modal').style.display = 'none';
}

async function resolveFromMonitor(id) {
  const resp = await SigapAPI.resolveEmergency(id);
  if (resp.ok) {
    closeEmergencyMonitor();
    await refreshPage();
    alert('✅ Insiden berhasil diselesaikan. Semua pihak telah mendapat notifikasi.');
  } else {
    alert('Gagal menyelesaikan: ' + (resp.data?.error || ''));
  }
}

// ══════════════════════════════════════════
// EMERGENCY ACTIONS (halaman)
// ══════════════════════════════════════════

async function resolveIncident(id) {
  if (!confirm('Selesaikan insiden ini? Semua responder akan diberitahu.')) return;
  const resp = await SigapAPI.resolveEmergency(id);
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal: ' + (resp.data?.error || ''));
  }
}

// ══════════════════════════════════════════
// MODALS
// ══════════════════════════════════════════

function closeModal(id) {
  document.getElementById(id).style.display = 'none';
}

function showServerConfig() {
  document.getElementById('server-url-input').value = SigapAPI.baseUrl;
  document.getElementById('server-modal').style.display = 'flex';
}

async function saveServerConfig() {
  const url = document.getElementById('server-url-input').value.trim();
  if (!url) return;
  SigapAPI.setBaseUrl(url);
  closeModal('server-modal');
  await checkServerStatus();
}

// ══════════════════════════════════════════
// SERVER STATUS
// ══════════════════════════════════════════

async function checkServerStatus() {
  const resp = await SigapAPI.health();
  const statusDot = document.getElementById('server-status');
  const urlDisplay = document.getElementById('server-url-display');
  const pulse = document.getElementById('server-pulse');
  const info = document.getElementById('server-info');

  if (resp.ok) {
    if (statusDot) statusDot.className = 'status-dot online';
    if (urlDisplay) urlDisplay.textContent = SigapAPI.baseUrl;
    if (pulse) pulse.style.background = 'var(--success)';
    if (info) info.textContent = 'Server Online';
  } else {
    if (statusDot) statusDot.className = 'status-dot offline';
    if (urlDisplay) urlDisplay.textContent = SigapAPI.baseUrl + ' (offline)';
    if (pulse) pulse.style.background = 'var(--danger)';
    if (info) info.textContent = 'Server Offline';
  }
}

// ══════════════════════════════════════════
// SOS ALERT BANNER
// ══════════════════════════════════════════

function showSOSAlert(incidents) {
  const bar = document.getElementById('sos-alert-bar');
  bar.style.display = 'flex';
  document.getElementById('sos-alert-text').textContent =
    `🚨 ${incidents.length} Panggilan SOS AKTIF!`;
  document.getElementById('sos-alert-sub').textContent =
    incidents.map(i => `${i.nama_korban || 'Pengguna'} (${i.status})`).join(' · ');
}

function hideSOSAlert() {
  document.getElementById('sos-alert-bar').style.display = 'none';
}

// ══════════════════════════════════════════
// UTILITIES
// ══════════════════════════════════════════

function updateBadge(id, count) {
  const el = document.getElementById(id);
  if (!el) return;
  if (count > 0) {
    el.textContent = count;
    el.style.display = 'inline';
  } else {
    el.style.display = 'none';
  }
}

function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
}

// ══════════════════════════════════════════
// POLLING — 5 detik untuk emergency, 30 detik untuk laporan
// ══════════════════════════════════════════

function startPolling() {
  if (pollInterval) clearInterval(pollInterval);

  pollInterval = setInterval(async () => {
    await checkServerStatus();

    const emergencyResp = await SigapAPI.getPendingEmergencies();
    if (emergencyResp.ok) {
      const incidents = emergencyResp.data?.data || [];
      const count = incidents.length;

      updateBadge('emergency-badge', count);

      // Tampilkan/sembunyikan SOS alert bar
      if (count > 0) {
        showSOSAlert(incidents);

        // Jika jumlah SOS baru bertambah → mainkan bunyi notif
        if (count > _emPrevSosCount) {
          _playAlertSound();
        }
      } else {
        hideSOSAlert();
      }
      _emPrevSosCount = count;

      // Jika sedang di halaman emergency → auto refresh (tampilkan semua riwayat)
      if (currentPage === 'emergency') {
        const allResp = await SigapAPI.getAllEmergencies();
        if (allResp.ok) {
          const content = document.getElementById('page-content');
          // Update tanpa full reload agar tombol pantau tidak hilang
          if (content.querySelector('.data-table')) {
            content.innerHTML = Pages.emergency(allResp.data?.data || []);
            updateBadge('emergency-badge', count); // count tetap jumlah yang pending
          }
        }
      }

      // Jika monitor modal terbuka → refresh data
      if (_emCurrentDbId && document.getElementById('emergency-monitor-modal').style.display === 'flex') {
        await refreshEmergencyMonitor();
      }
    }

    // Update report badge (lebih jarang)
  }, 5000);

  // Report badge setiap 30 detik
  setInterval(async () => {
    const reportsResp = await SigapAPI.getReports();
    if (reportsResp.ok) {
      updateBadge('report-badge', (reportsResp.data?.data || []).filter(r => r.status === 'pending').length);
    }
  }, 30000);
}

function _playAlertSound() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.setValueAtTime(880, ctx.currentTime);
    osc.frequency.setValueAtTime(660, ctx.currentTime + 0.15);
    osc.frequency.setValueAtTime(880, ctx.currentTime + 0.3);
    gain.gain.setValueAtTime(0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.5);
  } catch (_) {}
}

// Close modals on escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal').forEach(m => m.style.display = 'none');
    closeEmergencyMonitor();
  }
});

// Close modals on backdrop click
document.addEventListener('click', (e) => {
  if (e.target.classList.contains('modal')) {
    if (e.target.id === 'emergency-monitor-modal') {
      closeEmergencyMonitor();
    } else {
      e.target.style.display = 'none';
    }
  }
});
