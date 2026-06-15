/**
 * SIGAP Dashboard — Page Renderers
 * Each function returns HTML string for a specific page.
 */

const Pages = (() => {
  // ══════════════════════════════════════════
  // OVERVIEW
  // ══════════════════════════════════════════
  function overview(stats) {
    const u = stats.users || {};
    const r = stats.reports || {};
    const e = stats.emergency || {};
    const p = stats.pantau || {};

    return `
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon purple">👥</div>
          <div class="stat-info">
            <div class="stat-label">Total Pengguna</div>
            <div class="stat-value">${u.total || 0}</div>
            <div class="stat-sub">${u.user||0} user · ${u.admin||0} admin · ${u.psikolog||0} psikolog</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon yellow">📋</div>
          <div class="stat-info">
            <div class="stat-label">Laporan Masuk</div>
            <div class="stat-value">${r.total || 0}</div>
            <div class="stat-sub">${r.pending||0} pending · ${r.processed||0} diproses · ${r.completed||0} selesai</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon red">🚨</div>
          <div class="stat-info">
            <div class="stat-label">Darurat Aktif</div>
            <div class="stat-value">${e.active || 0}</div>
            <div class="stat-sub">${e.total || 0} total insiden tercatat</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon green">👁️</div>
          <div class="stat-info">
            <div class="stat-label">Pantauan Aktif</div>
            <div class="stat-value">${p.active || 0}</div>
            <div class="stat-sub">Sesi pantau yang sedang berjalan</div>
          </div>
        </div>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
        <div class="card" id="overview-reports-card">
          <div class="card-header">
            <h3>📋 Laporan Terbaru</h3>
            <button class="btn-secondary btn-sm" onclick="navigateTo('reports')">Lihat Semua</button>
          </div>
          <div class="card-body" id="overview-reports">
            <div class="empty-state"><p>Memuat...</p></div>
          </div>
        </div>
        <div class="card" id="overview-emergency-card">
          <div class="card-header">
            <h3>🚨 Insiden Darurat Aktif</h3>
            <button class="btn-secondary btn-sm" onclick="navigateTo('emergency')">Lihat Semua</button>
          </div>
          <div class="card-body" id="overview-emergencies">
            <div class="empty-state"><p>Memuat...</p></div>
          </div>
        </div>
      </div>
    `;
  }

  // ══════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════
  function users(data) {
    if (!data || data.length === 0) {
      return `<div class="card"><div class="empty-state"><div class="icon">👥</div><h4>Belum ada pengguna</h4></div></div>`;
    }

    const rows = data.map(u => `
      <tr>
        <td><strong>${u.id}</strong></td>
        <td>
          <div style="display:flex;align-items:center;gap:8px;">
            <div class="user-avatar" style="width:28px;height:28px;font-size:0.7rem;">${(u.nama_lengkap||'?')[0].toUpperCase()}</div>
            <div>
              <div style="font-weight:600;font-size:0.85rem;">${u.nama_lengkap || '-'}</div>
              <div style="font-size:0.75rem;color:var(--text-muted);">${u.email}</div>
            </div>
          </div>
        </td>
        <td><span class="badge badge-${u.role}">${u.role}</span></td>
        <td>${u.sub_role ? `<span class="badge badge-${u.sub_role}">${u.sub_role}</span>` : '-'}</td>
        <td class="mono">${u.nim_nidn_nik || '-'}</td>
        <td>${u.no_hp || '-'}</td>
        <td>${u.prodi_unit || '-'}</td>
        <td><span class="badge ${u.is_active ? 'badge-selesai' : 'badge-ditolak'}">${u.is_active ? 'Aktif' : 'Nonaktif'}</span></td>
        <td class="mono" style="font-size:0.75rem;">${formatDate(u.created_at)}</td>
      </tr>
    `).join('');

    return `
      <div class="card">
        <div class="card-header">
          <h3>👥 Daftar Pengguna (${data.length})</h3>
          <div style="display:flex;gap:8px;">
            <select class="input-full" style="width:auto;padding:6px 30px 6px 12px;" onchange="filterUsers(this.value)" id="user-role-filter">
              <option value="">Semua Role</option>
              <option value="user">User</option>
              <option value="admin">Admin</option>
              <option value="psikolog">Psikolog</option>
            </select>
          </div>
        </div>
        <div class="card-body table-scroll">
          <table class="data-table">
            <thead><tr><th>ID</th><th>Nama / Email</th><th>Role</th><th>Sub-Role</th><th>NIM/NIDN/NIK</th><th>No HP</th><th>Prodi/Unit</th><th>Status</th><th>Terdaftar</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ══════════════════════════════════════════
  // REPORTS
  // ══════════════════════════════════════════
  function reports(data) {
    if (!data || data.length === 0) {
      return `<div class="card"><div class="empty-state"><div class="icon">📋</div><h4>Belum ada laporan</h4><p>Laporan akan muncul ketika pengguna mengirim melalui aplikasi.</p></div></div>`;
    }

    const rows = data.map(r => `
      <tr style="cursor:pointer;" onclick="showReportDetail(${r.id})">
        <td><strong>#${r.id}</strong></td>
        <td>
          <div style="font-weight:600;">${r.nama_pelapor || '-'}</div>
          <div style="font-size:0.75rem;color:var(--text-muted);">${r.email_pelapor || ''}</div>
        </td>
        <td>
          <span class="mono" style="background:#f0f4ff;color:#1d4ed8;padding:3px 8px;border-radius:6px;font-size:0.78rem;font-weight:700;letter-spacing:0.04em;cursor:pointer;" onclick="event.stopPropagation();navigator.clipboard.writeText('${r.tracking_code||''}').then(()=>alert('Kode disalin: ${r.tracking_code||''}'))" title="Klik untuk menyalin">
            ${r.tracking_code || '-'}
          </span>
        </td>
        <td>${r.kategori_kekhawatiran || '-'}</td>
        <td><span class="badge badge-${r.status}">${r.status}</span></td>
        <td>${r.jenis_penyintas || '-'}</td>
        <td class="mono" style="font-size:0.75rem;">${formatDate(r.created_at)}</td>
        <td>
          <button class="btn-primary btn-sm" onclick="event.stopPropagation();showReportDetail(${r.id})">Detail</button>
        </td>
      </tr>
    `).join('');

    return `
      <div class="card">
        <div class="card-header">
          <h3>📋 Laporan Pelecehan (${data.length})</h3>
          <div style="display:flex;gap:8px;">
            <select class="input-full" style="width:auto;padding:6px 30px 6px 12px;" onchange="filterReports(this.value)" id="report-status-filter">
              <option value="">Semua Status</option>
              <option value="pending">Pending</option>
              <option value="diterima">Diterima</option>
              <option value="dijadwalkan">Dijadwalkan</option>
              <option value="diproses">Diproses</option>
              <option value="selesai">Selesai</option>
              <option value="ditolak">Ditolak</option>
            </select>
          </div>
        </div>
        <div class="card-body table-scroll">
          <table class="data-table">
            <thead><tr><th>ID</th><th>Pelapor</th><th>Kode Lacak</th><th>Kategori</th><th>Status</th><th>Jenis</th><th>Tanggal</th><th>Aksi</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  }

  function reportDetail(report) {
    const d = report.data || report;
    const audits = d.audit_trail || [];

    const auditHTML = audits.length > 0
      ? `<div class="audit-timeline">${audits.map(a => `
          <div class="audit-entry">
            <div class="action">${a.action}</div>
            <div class="detail">${a.detail}</div>
            <div class="meta">oleh ${a.actor} · ${formatDate(a.created_at)}</div>
          </div>
        `).join('')}</div>`
      : '<p style="color:var(--text-muted);font-size:0.85rem;">Belum ada riwayat.</p>';

    return {
      title: `Laporan #${d.id} — ${d.tracking_code || ''}`,
      body: `
        <div style="background:linear-gradient(135deg,#eff6ff,#dbeafe);border:1.5px solid #93c5fd;border-radius:12px;padding:16px 20px;margin-bottom:20px;display:flex;align-items:center;justify-content:space-between;gap:12px;">
          <div>
            <div style="font-size:0.7rem;font-weight:700;color:#1d4ed8;text-transform:uppercase;letter-spacing:0.08em;margin-bottom:4px;">🔑 Kode Pelacakan Laporan</div>
            <div style="font-family:monospace;font-size:1.25rem;font-weight:800;color:#1e3a8a;letter-spacing:0.12em;">${d.tracking_code || '-'}</div>
            <div style="font-size:0.72rem;color:#3b82f6;margin-top:2px;">Kode ini digunakan pelapor untuk memantau status laporan di aplikasi.</div>
          </div>
          <button onclick="navigator.clipboard.writeText('${d.tracking_code||''}').then(()=>{this.textContent='✅ Disalin!';setTimeout(()=>this.textContent='📋 Salin',2000)})" style="background:#2563eb;color:white;border:none;border-radius:8px;padding:8px 16px;font-size:0.8rem;font-weight:600;cursor:pointer;white-space:nowrap;flex-shrink:0;">📋 Salin</button>
        </div>
        <div class="detail-grid">
          <div class="detail-item"><div class="label">Pelapor</div><div class="value">${d.nama_pelapor}</div></div>
          <div class="detail-item"><div class="label">Email</div><div class="value">${d.email_pelapor}</div></div>
          <div class="detail-item"><div class="label">Status</div><div class="value"><span class="badge badge-${d.status}">${d.status}</span></div></div>
          <div class="detail-item"><div class="label">Tanggal Lapor</div><div class="value">${formatDate(d.created_at)}</div></div>
          <div class="detail-item"><div class="label">Jenis Penyintas</div><div class="value">${d.jenis_penyintas || '-'}</div></div>
          <div class="detail-item"><div class="label">Kategori</div><div class="value">${d.kategori_kekhawatiran || '-'}</div></div>
          <div class="detail-item"><div class="label">Gender Pelaku</div><div class="value">${d.gender_pelaku || '-'}</div></div>
          <div class="detail-item"><div class="label">Hubungan</div><div class="value">${d.hubungan_pelaku || '-'}</div></div>
        </div>
        <div style="margin-top:16px;">
          <div class="label" style="font-size:0.75rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.04em;margin-bottom:4px;">Detail Kejadian</div>
          <div class="detail-full">${d.detail_kejadian || 'Tidak ada detail.'}</div>
        </div>
        ${d.catatan_admin ? `<div style="margin-top:12px;"><div class="label" style="font-size:0.75rem;color:var(--text-muted);">CATATAN ADMIN</div><div class="detail-full">${d.catatan_admin}</div></div>` : ''}
        ${d.catatan_psikolog ? `<div style="margin-top:12px;"><div class="label" style="font-size:0.75rem;color:var(--text-muted);">CATATAN PSIKOLOG</div><div class="detail-full">${d.catatan_psikolog}</div></div>` : ''}
        ${d.alasan_tolak ? `<div style="margin-top:12px;"><div class="label" style="font-size:0.75rem;color:var(--text-muted);">ALASAN DITOLAK</div><div class="detail-full" style="background:var(--danger-bg);color:#991b1b;">${d.alasan_tolak}</div></div>` : ''}
        <div style="margin-top:20px;">
          <h4 style="font-size:0.9rem;margin-bottom:8px;">📜 Riwayat Audit</h4>
          ${auditHTML}
        </div>
      `,
      footer: buildReportActions(d),
    };
  }

  function buildReportActions(d) {
    if (d.status === 'selesai' || d.status === 'ditolak') return '';

    let actions = '';
    if (d.status === 'pending') {
      actions = `
        <button class="btn-success btn-sm" onclick="updateReport(${d.id}, 'diterima')">✅ Terima</button>
        <button class="btn-danger btn-sm" onclick="showRejectForm(${d.id})">❌ Tolak</button>
      `;
    } else if (d.status === 'diterima') {
      // Admin harus menjadwalkan konsultasi dulu sebelum bisa lanjut
      actions = `
        <button class="btn-primary btn-sm" onclick="closeModal('detail-modal');showScheduleModal(${d.id}, '${d.tracking_code}', true)" style="background:#2563eb;">📅 Jadwalkan Konsultasi</button>
        <button class="btn-danger btn-sm" onclick="showRejectForm(${d.id})">❌ Tolak</button>
      `;
    } else if (d.status === 'dijadwalkan') {
      // Sudah dijadwalkan — menunggu user pilih slot
      actions = `
        <span style="font-size:0.85rem;color:#2563eb;font-weight:600;">⏳ Menunggu user memilih jadwal...</span>
        <button class="btn-danger btn-sm" onclick="showRejectForm(${d.id})">❌ Tolak</button>
      `;
    } else if (d.status === 'diproses') {
      actions = `
        <button class="btn-success btn-sm" onclick="showCompleteForm(${d.id})">✅ Selesai</button>
        <button class="btn-primary btn-sm" onclick="closeModal('detail-modal');showScheduleModal(${d.id}, '${d.tracking_code}', ${d.perlu_tindak_lanjut === true || d.perlu_tindak_lanjut === 1 || d.perlu_tindak_lanjut === 'true'})" style="background:#2563eb; margin-left: 8px;">📅 Jadwalkan Sesi Lanjutan</button>
      `;
    }

    return `
      <div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">
        <input type="text" id="report-note" class="input-full" placeholder="Tambah catatan..." style="flex:1;min-width:180px;">
        ${actions}
      </div>
    `;
  }

  // ══════════════════════════════════════════
  // APPOINTMENTS
  // ══════════════════════════════════════════
  function appointments(data) {
    const statusLabel = {
      menunggu_user:      { label: 'Menunggu User Pilih Jadwal', color: '#d97706', bg: '#fffbeb' },
      menunggu_psikolog:  { label: 'Menunggu Konfirmasi Psikolog', color: '#2563eb', bg: '#eff6ff' },
      reschedule:         { label: 'Perlu Reschedule', color: '#ea580c', bg: '#fff7ed' },
      diterima:           { label: 'Jadwal Dikonfirmasi', color: '#16a34a', bg: '#f0fdf4' },
      ditolak:            { label: 'Ditolak', color: '#dc2626', bg: '#fef2f2' },
      selesai:            { label: 'Selesai', color: '#6b7280', bg: '#f9fafb' },
    };

    if (!data || data.length === 0) {
      return `<div class="card"><div class="empty-state"><div class="icon">📅</div><h4>Belum ada janji temu</h4><p>Jadwalkan konsultasi dari halaman Laporan.</p></div></div>`;
    }

    const rows = data.map(a => {
      const s = statusLabel[a.status] || { label: a.status, color: '#888', bg: '#f9fafb' };
      const jadwal = a.tanggal
        ? `${a.tanggal} · ${a.jam_mulai || ''}–${a.jam_selesai || ''}`
        : '<span style="color:#aaa">Belum dipilih</span>';
      return `
        <tr>
          <td class="mono" style="font-size:0.8rem;">${a.tracking_code || '#'+a.report_id}</td>
          <td>
            <div style="font-weight:600;font-size:0.85rem;">${a.nama_user || '-'}</div>
          </td>
          <td style="font-size:0.85rem;">${a.nama_psikolog || '-'}</td>
          <td style="font-size:0.83rem;">${jadwal}</td>
          <td>
            <span style="background:${s.bg};color:${s.color};padding:3px 10px;border-radius:20px;font-size:0.75rem;font-weight:700;">${s.label}</span>
          </td>
          <td>
            ${a.status === 'menunggu_psikolog' && SigapAPI.user?.role === 'psikolog' ? `
              <div style="display:flex;gap:6px;">
                <button class="btn-success btn-sm" onclick="respondAppointment(${a.id}, 'terima')">✅ Terima</button>
                <button class="btn-secondary btn-sm" onclick="respondAppointment(${a.id}, 'reschedule')">🔄 Reschedule</button>
              </div>
            ` : a.status === 'diterima' && SigapAPI.user?.role === 'psikolog' ? `
              <button class="btn-success btn-sm" onclick="completeAppointment(${a.id})">✅ Selesaikan</button>
            ` : '<span style="color:#aaa;font-size:0.8rem;">—</span>'}
          </td>
        </tr>
      `;
    }).join('');

    const pending = data.filter(a => ['menunggu_user','menunggu_psikolog','reschedule'].includes(a.status)).length;

    return `
      <div class="card">
        <div class="card-header">
          <h3>📅 Janji Temu Konsultasi (${data.length})</h3>
          <div style="display:flex;gap:8px;align-items:center;">
            ${pending > 0 ? `<span style="background:#fef3c7;color:#d97706;padding:4px 12px;border-radius:20px;font-size:0.8rem;font-weight:700;">${pending} menunggu tindakan</span>` : ''}
            <button class="btn-secondary btn-sm" onclick="refreshPage()">🔄 Refresh</button>
          </div>
        </div>
        <div class="card-body table-scroll">
          <table class="data-table">
            <thead><tr><th>Kode Laporan</th><th>Pelapor</th><th>Psikolog</th><th>Jadwal</th><th>Status</th><th>Aksi</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ══════════════════════════════════════════
  // EMERGENCY
  // ══════════════════════════════════════════
  function emergency(data) {
    if (!data || data.length === 0) {
      return `<div class="card"><div class="empty-state"><div class="icon">🛡️</div><h4>Tidak ada darurat aktif</h4><p>Semua aman — tidak ada panggilan SOS yang aktif saat ini.</p></div></div>`;
    }

    const rows = data.map(e => `
      <tr>
        <td class="mono"><strong>${e.incident_id || '#'+e.id}</strong></td>
        <td>
          <div style="font-weight:600;">${e.nama_korban || '-'}</div>
          <div style="font-size:0.75rem;color:var(--text-muted);">${e.no_hp_korban || ''}</div>
        </td>
        <td><span class="badge badge-${e.status}">${e.status}</span></td>
        <td>${e.lat ? e.lat.toFixed(5) : '-'}, ${e.lng ? e.lng.toFixed(5) : '-'}</td>
        <td>
          <span style="font-weight:600;color:${(e.responder_count||0) > 0 ? 'var(--success)' : '#aaa'};">
            ${e.responder_count || 0} responder
          </span>
        </td>
        <td style="font-size:0.78rem;color:var(--text-muted);">${e.duration || '-'}</td>
        <td class="mono" style="font-size:0.75rem;">${formatDate(e.created_at)}</td>
        <td>
          <div style="display:flex;gap:6px;flex-wrap:wrap;">
            <button class="btn-primary btn-sm" onclick="showEmergencyMonitor(${e.id})" style="background:#7c3aed;">🎧 Pantau</button>
            ${e.status !== 'resolved' ? `
              <button class="btn-success btn-sm" onclick="resolveIncident(${e.id})">✅ Selesai</button>
              <a href="https://www.google.com/maps?q=${e.lat},${e.lng}" target="_blank" class="btn-secondary btn-sm" style="text-decoration:none;">📍 Maps</a>
            ` : '<span style="color:var(--text-muted);">—</span>'}
          </div>
        </td>
      </tr>
    `).join('');

    return `
      <div class="card">
        <div class="card-header">
          <h3>🚨 Insiden Darurat (${data.length})</h3>
          <div style="display:flex;gap:8px;align-items:center;">
            <span style="font-size:0.75rem;color:var(--text-muted);">Auto-refresh 5 detik</span>
            <button class="btn-secondary btn-sm" onclick="refreshPage()">🔄 Refresh</button>
          </div>
        </div>
        <div class="card-body table-scroll">
          <table class="data-table">
            <thead><tr><th>Incident ID</th><th>Korban</th><th>Status</th><th>Lokasi GPS</th><th>Responder</th><th>Durasi</th><th>Waktu</th><th>Aksi</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;
  }

  // ══════════════════════════════════════════
  // PANTAU
  // ══════════════════════════════════════════
  function pantau(data) {
    return `
      <div class="card">
        <div class="card-header">
          <h3>👁️ Sesi Pantauan</h3>
        </div>
        <div class="card-body">
          <div class="empty-state">
            <div class="icon">👁️</div>
            <h4>Pantauan dikelola dari aplikasi mobile</h4>
            <p>Data sesi pantauan dapat dilihat melalui tab Database → tabel pantau_sessions</p>
          </div>
        </div>
      </div>
    `;
  }

  // ══════════════════════════════════════════
  // DATABASE VIEWER
  // ══════════════════════════════════════════
  function database(tables, activeTable, tableData) {
    const tabsHTML = (tables || []).map(t => {
      const name = typeof t === 'object' ? t.name : t;
      const count = typeof t === 'object' && t.count !== undefined ? ` <span style="font-size:0.7em;opacity:0.7">(${t.count})</span>` : '';
      return `<button class="db-tab ${name === activeTable ? 'active' : ''}" onclick="loadTable('${name}')">${name}${count}</button>`;
    }).join('');

    let tableHTML = '';
    if (tableData && tableData.columns && tableData.data) {
      const headers = tableData.columns.map(c => `<th>${typeof c === 'object' ? c.name : c}</th>`).join('');
      const rows = tableData.data.map(row => {
        const cells = tableData.columns.map(c => {
          const colName = typeof c === 'object' ? c.name : c;
          let val = row[colName];
          if (val === null || val === undefined) val = '<span style="color:var(--text-muted)">NULL</span>';
          else if (typeof val === 'object') val = JSON.stringify(val);
          else if (typeof val === 'string' && val.length > 60) val = val.substring(0, 60) + '...';
          return `<td class="mono">${val}</td>`;
        }).join('');
        return `<tr>${cells}</tr>`;
      }).join('');

      tableHTML = `
        <div class="card" style="margin-top:16px;">
          <div class="card-header">
            <h3>📊 ${activeTable} (${tableData.total} rows)</h3>
          </div>
          <div class="card-body table-scroll">
            <table class="data-table">
              <thead><tr>${headers}</tr></thead>
              <tbody>${rows || '<tr><td colspan="100%" class="empty-state">Tabel kosong</td></tr>'}</tbody>
            </table>
          </div>
        </div>
      `;
    }

    return `
      <div class="card">
        <div class="card-header"><h3>🗄️ Database Viewer</h3></div>
        <div style="padding:16px;">
          <div class="db-tabs">${tabsHTML || '<p style="color:var(--text-muted);">Memuat tabel...</p>'}</div>
        </div>
      </div>
      ${tableHTML}
    `;
  }

  // ══════════════════════════════════════════
  // MINI TABLE (untuk overview)
  // ══════════════════════════════════════════
  function miniReportTable(data) {
    if (!data || data.length === 0) return '<div class="empty-state"><p>Belum ada laporan.</p></div>';
    return `<table class="data-table">
      <thead><tr><th>ID</th><th>Pelapor</th><th>Kode Lacak</th><th>Status</th><th>Tanggal</th></tr></thead>
      <tbody>${data.slice(0, 5).map(r => `
        <tr style="cursor:pointer;" onclick="navigateTo('reports');setTimeout(()=>showReportDetail(${r.id}),300);">
          <td>#${r.id}</td><td>${r.nama_pelapor||'-'}</td>
          <td class="mono" style="font-size:0.75rem;font-weight:700;color:#1d4ed8;">${r.tracking_code||'-'}</td>
          <td><span class="badge badge-${r.status}">${r.status}</span></td>
          <td class="mono" style="font-size:0.75rem;">${formatDate(r.created_at)}</td>
        </tr>`).join('')}</tbody></table>`;
  }

  function miniEmergencyTable(data) {
    if (!data || data.length === 0) return '<div class="empty-state"><p>Tidak ada insiden aktif 🛡️</p></div>';
    return `<table class="data-table">
      <thead><tr><th>ID</th><th>Korban</th><th>Status</th><th>Waktu</th></tr></thead>
      <tbody>${data.slice(0, 5).map(e => `
        <tr>
          <td class="mono">${(e.incident_id||'').substring(0,12)}</td><td>${e.nama_korban||'-'}</td>
          <td><span class="badge badge-${e.status}">${e.status}</span></td>
          <td class="mono" style="font-size:0.75rem;">${formatDate(e.created_at)}</td>
        </tr>`).join('')}</tbody></table>`;
  }

  // ══════════════════════════════════════════
  // MY SCHEDULES
  // ══════════════════════════════════════════
  function mySchedules(data) {
    const hariOptions = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'].map(h => `<option value="${h}">${h.charAt(0).toUpperCase() + h.slice(1)}</option>`).join('');

    const formHTML = `
      <div class="card" style="margin-bottom: 20px;">
        <div class="card-header">
          <h3>➕ Tambah Slot Jadwal</h3>
        </div>
        <div class="card-body">
          <form onsubmit="submitSchedule(event)" style="display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;">
            <div style="flex:1;min-width:150px;">
              <label style="font-size:0.8rem;font-weight:600;margin-bottom:4px;display:block;">Hari</label>
              <select name="hari" required class="input-full">${hariOptions}</select>
            </div>
            <div style="flex:1;min-width:150px;">
              <label style="font-size:0.8rem;font-weight:600;margin-bottom:4px;display:block;">Jam Mulai (HH:MM)</label>
              <input type="time" name="jam_mulai" required class="input-full">
            </div>
            <div style="flex:1;min-width:150px;">
              <label style="font-size:0.8rem;font-weight:600;margin-bottom:4px;display:block;">Jam Selesai (HH:MM)</label>
              <input type="time" name="jam_selesai" required class="input-full">
            </div>
            <div>
              <button type="submit" class="btn-primary" style="height:42px;padding:0 24px;">Simpan</button>
            </div>
          </form>
        </div>
      </div>
    `;

    if (!data || data.length === 0) {
      return formHTML + `<div class="card"><div class="empty-state"><div class="icon">📅</div><h4>Belum ada jadwal</h4><p>Tambahkan slot jadwal ketersediaan Anda di atas.</p></div></div>`;
    }

    const rows = data.map(s => `
      <tr>
        <td style="text-transform:capitalize;font-weight:600;">${s.hari}</td>
        <td class="mono">${s.jam_mulai}</td>
        <td class="mono">${s.jam_selesai}</td>
        <td>
          <span style="background:${s.is_active ? '#dcfce7' : '#fee2e2'};color:${s.is_active ? '#166534' : '#991b1b'};padding:3px 10px;border-radius:20px;font-size:0.75rem;font-weight:700;">
            ${s.is_active ? 'Aktif' : 'Non-Aktif'}
          </span>
        </td>
        <td>
          <button class="btn-danger btn-sm" onclick="deleteSchedule(${s.id})">🗑️ Hapus</button>
        </td>
      </tr>
    `).join('');

    const tableHTML = `
      <div class="card">
        <div class="card-header">
          <h3>📅 Daftar Ketersediaan Anda</h3>
        </div>
        <div class="card-body table-scroll">
          <table class="data-table">
            <thead><tr><th>Hari</th><th>Jam Mulai</th><th>Jam Selesai</th><th>Status</th><th>Aksi</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>
    `;

    return formHTML + tableHTML;
  }

  // Helper
  function formatDate(dt) {
    if (!dt) return '-';
    try {
      const d = new Date(dt);
      return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
        + ' ' + d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    } catch { return dt; }
  }

  return { overview, users, reports, reportDetail, appointments, emergency, pantau, database, miniReportTable, miniEmergencyTable, mySchedules, formatDate };
})();
