/**
 * SIGAP Psikolog Portal — Main App Controller
 */

let currentPage = 'overview';
let pollInterval = null;

// ══════════════════════════════════════════
// INIT
// ══════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('topbar-date').textContent =
    new Date().toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

  if (SigapAPI.isLoggedIn) {
    if (SigapAPI.user?.role === 'psikolog') {
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
    if (role !== 'psikolog') {
      SigapAPI.logout();
      errorEl.textContent = 'Hanya Psikolog yang dapat mengakses portal ini.';
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
    document.getElementById('user-role').textContent = 'Psikolog';
    document.getElementById('user-avatar').textContent = (user.nama_lengkap || 'P')[0].toUpperCase();
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
    schedules: 'Jadwal Konsultasi',
    availability: 'Jadwal Aktif Saya',
    unavailability: 'Cuti / Libur',
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
    case 'schedules':
      await loadSchedules(content);
      break;
    case 'availability':
      await loadAvailability(content);
      break;
    case 'unavailability':
      await loadUnavailability(content);
      break;
  }
}

async function refreshPage() {
  await loadPage(currentPage);
}

// ══════════════════════════════════════════
// PAGE LOADERS
// ══════════════════════════════════════════

async function loadOverview(el) {
  // Panggil stats khusus psikolog
  const statsResp = await SigapAPI.request('GET', '/api/dashboard/stats-psikolog');
  let statsData = {};
  if (statsResp.ok) {
    statsData = statsResp.data;
  }

  el.innerHTML = Pages.overview(statsData);

  // Load upcoming appointments — dengan fallback jika gagal
  const apptEl = document.getElementById('overview-appointments');
  if (!apptEl) return;

  const apptResp = await SigapAPI.getAppointments();
  if (apptResp.ok) {
    const data = apptResp.data?.data || [];
    // Hanya tampilkan yang relevan: menunggu konfirmasi psikolog atau sudah diterima
    const relevant = data.filter(a => ['diterima', 'menunggu_psikolog'].includes(a.status));
    apptEl.innerHTML = Pages.miniAppointmentTable(relevant);
  } else {
    apptEl.innerHTML = '<div class="empty-state"><p>Gagal memuat jadwal mendatang.</p></div>';
  }
}

async function loadSchedules(el) {
  const resp = await SigapAPI.getAppointments();
  if (resp.ok) {
    const data = resp.data?.data || [];
    el.innerHTML = Pages.appointments(data);
    const pending = data.filter(a => ['menunggu_psikolog'].includes(a.status)).length;
    updateBadge('appointment-badge', pending);
  } else {
    el.innerHTML = '<div class="empty-state"><h4>Gagal memuat jadwal</h4></div>';
  }
}

async function loadAvailability(el) {
  const user = SigapAPI.user;
  const resp = await SigapAPI.getPsikologSchedules(user?.id);
  let schedules = [];
  if (resp.ok && resp.data?.data) {
    schedules = resp.data.data;
  }
  el.innerHTML = Pages.availability(schedules);
}

async function submitAvailability(e) {
  e.preventDefault();
  const formData = new FormData(e.target);
  const hari = formData.get('hari');
  const jamMulai = formData.get('jam_mulai');
  const jamSelesai = formData.get('jam_selesai');

  const resp = await SigapAPI.addPsikologSchedule(hari, jamMulai, jamSelesai);
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal menambah jadwal: ' + (resp.data?.error || 'Unknown error'));
  }
}

async function deleteAvailability(id) {
  if (!confirm('Hapus slot jadwal ini?')) return;
  const resp = await SigapAPI.deletePsikologSchedule(id);
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal menghapus jadwal: ' + (resp.data?.error || 'Unknown error'));
  }
}

async function loadUnavailability(el) {
  // Endpoint psikolog/unavailability mungkin belum diimplementasi di backend.
  // Gunakan fallback graceful agar halaman tidak stuck.
  const user = SigapAPI.user;
  const resp = await SigapAPI.request('GET', '/api/psikolog/unavailability?psikolog_id=' + (user?.id || ''));
  let dates = [];
  if (resp.ok && resp.data?.data) {
    dates = resp.data.data;
  }
  el.innerHTML = Pages.unavailability(dates);
}

// ══════════════════════════════════════════
// ACTIONS
// ══════════════════════════════════════════

async function acceptAppointment(id, tipeLokasi) {
  let linkLokasi = '';
  if (tipeLokasi === 'offline') {
    linkLokasi = prompt('Metode konsultasi: OFFLINE\n\nSilakan masukkan alamat lengkap tempat pertemuan:');
  } else {
    linkLokasi = prompt('Metode konsultasi: ONLINE\n\nSilakan masukkan Link Video Call (Zoom/Google Meet):');
  }
  
  if (linkLokasi === null) return; // User cancelled
  
  const resp = await SigapAPI.respondAppointment(id, 'terima', '', linkLokasi);
  if (resp.ok) await refreshPage();
  else alert('Gagal: ' + (resp.data?.error || ''));
}

async function rejectAppointment(id) {
  const alasan = prompt('Alasan penolakan / reschedule?');
  if (!alasan) return;
  const resp = await SigapAPI.respondAppointment(id, 'reschedule', alasan);
  if (resp.ok) await refreshPage();
  else alert('Gagal: ' + (resp.data?.error || ''));
}

async function noShowAppointment(id) {
  const type = prompt("Ketik 'user' jika pasien tidak hadir, atau 'psikolog' jika Anda tidak hadir:", "user");
  if (type !== 'user' && type !== 'psikolog') return;
  if (!confirm('Tandai sebagai No-Show?')) return;
  
  const resp = await SigapAPI.request('POST', '/api/appointments/noshow', { appointment_id: id, no_show_type: type });
  if (resp.ok) await refreshPage();
  else alert('Gagal: ' + (resp.data?.error || ''));
}

async function completeAppointment(id) {
  const closeReport = confirm('Sesi ini selesai. Apakah Anda juga ingin MENUTUP (Close) laporan ini?\n\nOK = Tutup Laporan sepenuhnya.\nCancel = Sesi selesai, tapi laporan tetap terbuka untuk jadwal lanjutan.');
  const resp = await SigapAPI.request('POST', '/api/appointments/complete', { appointment_id: id, close_report: closeReport });
  if (resp.ok) await refreshPage();
  else alert('Gagal: ' + (resp.data?.error || ''));
}

// ══════════════════════════════════════════
// SESSION NOTES
// ══════════════════════════════════════════

let currentNoteApptId = null;

async function showSessionNote(apptId) {
  currentNoteApptId = apptId;
  
  // Clear form
  document.getElementById('sn-appointment-id').value = apptId;
  document.getElementById('sn-subjective').value = '';
  document.getElementById('sn-objective').value = '';
  document.getElementById('sn-assessment').value = '';
  document.getElementById('sn-plan').value = '';
  document.getElementById('sn-risk-level').value = 'low';
  document.getElementById('sn-mood-score').value = '';
  document.getElementById('sn-followup').checked = false;

  // Load existing note
  const resp = await SigapAPI.request('GET', '/api/session-notes?appointment_id=' + apptId);
  if (resp.ok && resp.data?.data) {
    const d = resp.data.data;
    document.getElementById('sn-subjective').value = d.subjective || '';
    document.getElementById('sn-objective').value = d.objective || '';
    document.getElementById('sn-assessment').value = d.assessment || '';
    document.getElementById('sn-plan').value = d.plan || '';
    document.getElementById('sn-risk-level').value = d.risk_level || 'low';
    document.getElementById('sn-mood-score').value = d.mood_score || '';
    document.getElementById('sn-followup').checked = d.follow_up_needed;
  }

  document.getElementById('session-note-modal').style.display = 'flex';
}

async function saveSessionNote() {
  const apptId = document.getElementById('sn-appointment-id').value;
  const btn = document.getElementById('sn-save-btn');
  const btnText = document.getElementById('sn-save-text');
  const btnLoader = document.getElementById('sn-save-loader');

  // Loading state
  btn.disabled = true;
  btnText.style.display = 'none';
  btnLoader.style.display = 'inline';

  const body = {
    appointment_id: parseInt(apptId),
    subjective: document.getElementById('sn-subjective').value,
    objective: document.getElementById('sn-objective').value,
    assessment: document.getElementById('sn-assessment').value,
    plan: document.getElementById('sn-plan').value,
    risk_level: document.getElementById('sn-risk-level').value,
    mood_score: parseInt(document.getElementById('sn-mood-score').value) || 0,
    follow_up_needed: document.getElementById('sn-followup').checked
  };

  const resp = await SigapAPI.request('POST', '/api/session-notes', body);
  
  // Restore state
  btn.disabled = false;
  btnText.style.display = 'inline';
  btnLoader.style.display = 'none';

  if (resp.ok) {
    alert('Catatan berhasil disimpan & terkirim ke klien');
    closeModal('session-note-modal');
  } else {
    alert('Gagal menyimpan: ' + (resp.data?.error || ''));
  }
}

async function endSession() {
  const apptId = document.getElementById('sn-appointment-id').value;
  if (!confirm("Apakah Anda yakin ingin mengakhiri sesi ini? Klien akan diminta mengisi feedback dan Admin dapat menyelesaikan laporan ini.")) return;

  const btn = document.getElementById('sn-end-btn');
  const originalText = btn.innerHTML;
  btn.innerHTML = '⏳ Memproses...';
  btn.disabled = true;

  const resp = await SigapAPI.completeSession(parseInt(apptId));
  
  btn.innerHTML = originalText;
  btn.disabled = false;

  if (resp.ok) {
    alert('Sesi berhasil diakhiri!');
    closeModal('session-note-modal');
    loadDashboardData(); // Refresh data
  } else {
    alert('Gagal mengakhiri sesi: ' + (resp.data?.error || ''));
  }
}

// ══════════════════════════════════════════
// UNAVAILABILITY (CUTI)
// ══════════════════════════════════════════

async function submitUnavailability(event) {
  event.preventDefault();
  const form = event.target;
  const tgl = form.tanggal.value;
  const alasan = form.alasan.value;

  const resp = await SigapAPI.request('POST', '/api/psikolog/unavailability', { tanggal: tgl, alasan: alasan });
  if (resp.ok) {
    await refreshPage();
  } else {
    alert('Gagal menyimpan: ' + (resp.data?.error || ''));
  }
}

async function deleteUnavailability(id) {
  if (!confirm('Hapus tanggal libur ini?')) return;
  const resp = await SigapAPI.request('DELETE', '/api/psikolog/unavailability', { id: id });
  if (resp.ok) await refreshPage();
  else alert('Gagal menghapus: ' + (resp.data?.error || ''));
}


// ══════════════════════════════════════════
// UTILS
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

function startPolling() {
  if (pollInterval) clearInterval(pollInterval);
  pollInterval = setInterval(async () => {
    await checkServerStatus();
    
    // Refresh badges
    if(currentPage !== 'schedules') {
      const apptResp = await SigapAPI.getAppointments();
      if (apptResp.ok) {
        const pending = (apptResp.data?.data || []).filter(a => ['menunggu_psikolog'].includes(a.status)).length;
        updateBadge('appointment-badge', pending);
      }
    }
  }, 30000);
}
