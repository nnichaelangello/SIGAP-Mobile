/**
 * SIGAP Psikolog Portal — Pages Templates
 */

const Pages = {
  overview: (stats) => {
    return `
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon purple">👥</div>
          <div class="stat-info">
            <div class="stat-label">Total Klien</div>
            <div class="stat-value">${stats.total_klien || 0}</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon yellow">📅</div>
          <div class="stat-info">
            <div class="stat-label">Sesi Hari Ini</div>
            <div class="stat-value">${stats.sesi_hari_ini || 0}</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon blue">📆</div>
          <div class="stat-info">
            <div class="stat-label">Sesi Minggu Ini</div>
            <div class="stat-value">${stats.sesi_minggu_ini || 0}</div>
          </div>
        </div>
        <div class="stat-card">
          <div class="stat-icon red">⏳</div>
          <div class="stat-info">
            <div class="stat-label">Menunggu Respon</div>
            <div class="stat-value">${stats.sesi_menunggu || 0}</div>
          </div>
        </div>
      </div>
      
      <div class="card">
        <div class="card-header">
          <h3>Jadwal Mendatang</h3>
          <button class="btn-secondary btn-sm" onclick="navigateTo('schedules')">Lihat Semua</button>
        </div>
        <div class="card-body">
          <div id="overview-appointments"><div class="empty-state"><p>Menyiapkan data...</p></div></div>
        </div>
      </div>
    `;
  },

  miniAppointmentTable: (appointments) => {
    if (!appointments || appointments.length === 0) return `<div class="empty-state"><p>Tidak ada jadwal terdekat.</p></div>`;
    
    // Sort by tanggal
    appointments.sort((a,b) => new Date(a.tanggal) - new Date(b.tanggal));

    return `
      <table class="data-table">
        <thead>
          <tr>
            <th>Tanggal</th>
            <th>Jam</th>
            <th>Metode</th>
            <th>Klien</th>
            <th>Status</th>
            <th>Aksi</th>
          </tr>
        </thead>
        <tbody>
          ${appointments.slice(0, 5).map(a => `
            <tr>
              <td><strong>${Pages.formatDate(a.tanggal)}</strong></td>
              <td>${a.jam_mulai} - ${a.jam_selesai}</td>
              <td style="text-transform: capitalize;">${a.tipe_lokasi || 'Online'}</td>
              <td>${a.user_nama}</td>
              <td>${Pages.badgeStatus(a.status)}</td>
              <td>
                <div style="display:flex;gap:4px;">
                  ${a.status === 'menunggu_psikolog' ? `
                    <button class="btn-success btn-sm" onclick="acceptAppointment(${a.id}, '${a.tipe_lokasi}')">Terima</button>
                    <button class="btn-danger btn-sm" onclick="rejectAppointment(${a.id})">Tolak</button>
                  ` : ''}
                  ${a.status === 'diterima' ? `
                    <button class="btn-primary btn-sm" onclick="showSessionNote(${a.id})">Catatan</button>
                    <button class="btn-success btn-sm" onclick="completeAppointment(${a.id})">Selesai</button>
                    <button class="btn-danger btn-sm" onclick="noShowAppointment(${a.id})">No-Show</button>
                  ` : ''}
                  ${a.status === 'selesai' ? `
                    <button class="btn-primary btn-sm" onclick="showSessionNote(${a.id})">Lihat Catatan</button>
                  ` : ''}
                </div>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  },

  appointments: (appointments) => {
    if (!appointments || appointments.length === 0) {
      return `<div class="empty-state"><h4>Tidak ada jadwal</h4></div>`;
    }

    appointments.sort((a,b) => new Date(b.tanggal) - new Date(a.tanggal));

    return `
      <div class="card">
        <div class="card-header">
          <h3>Semua Jadwal Konsultasi</h3>
        </div>
        <div class="card-body" style="overflow-x:auto;">
          <table class="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Tanggal & Jam</th>
                <th>Metode / Lokasi</th>
                <th>Klien</th>
                <th>Status</th>
                <th>Aksi</th>
              </tr>
            </thead>
            <tbody>
              ${appointments.map(a => `
                <tr>
                  <td>#${a.id}</td>
                  <td>
                    <strong>${Pages.formatDate(a.tanggal)}</strong><br>
                    <span style="color:var(--text-muted);font-size:0.8rem;">${a.jam_mulai} - ${a.jam_selesai}</span>
                  </td>
                  <td>
                    <span style="text-transform: capitalize; font-weight: 500;">${a.tipe_lokasi || 'Online'}</span>
                    ${a.link_lokasi ? `<br><a href="${a.link_lokasi.startsWith('http') ? a.link_lokasi : '#'}" style="font-size: 0.8rem; color: var(--primary);">${a.link_lokasi}</a>` : ''}
                  </td>
                  <td>${a.user_nama}</td>
                  <td>${Pages.badgeStatus(a.status)}</td>
                  <td>
                    <div style="display:flex;gap:4px;">
                      ${a.status === 'menunggu_psikolog' ? `
                        <button class="btn-success btn-sm" onclick="acceptAppointment(${a.id}, '${a.tipe_lokasi}')">Terima</button>
                        <button class="btn-danger btn-sm" onclick="rejectAppointment(${a.id})">Tolak</button>
                      ` : ''}
                      ${a.status === 'diterima' ? `
                        <button class="btn-primary btn-sm" onclick="showSessionNote(${a.id})">Catatan</button>
                        <button class="btn-success btn-sm" onclick="completeAppointment(${a.id})">Selesai</button>
                        <button class="btn-danger btn-sm" onclick="noShowAppointment(${a.id})">No-Show</button>
                      ` : ''}
                      ${a.status === 'selesai' ? `
                        <button class="btn-primary btn-sm" onclick="showSessionNote(${a.id})">Lihat Catatan</button>
                      ` : ''}
                    </div>
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  },

  availability: (schedules) => {
    return `
      <div class="detail-grid">
        <div class="card">
          <div class="card-header">
            <h3>Atur Jadwal Konsultasi (Slot Aktif)</h3>
          </div>
          <div class="card-body" style="padding:20px;">
            <form onsubmit="submitAvailability(event)">
              <div class="form-group" style="margin-bottom:16px;">
                <label>Hari</label>
                <select name="hari" class="input-full" required>
                  <option value="senin">Senin</option>
                  <option value="selasa">Selasa</option>
                  <option value="rabu">Rabu</option>
                  <option value="kamis">Kamis</option>
                  <option value="jumat">Jumat</option>
                  <option value="sabtu">Sabtu</option>
                </select>
              </div>
              <div style="display:flex;gap:16px;margin-bottom:16px;">
                <div class="form-group" style="flex:1;">
                  <label>Jam Mulai</label>
                  <input type="time" name="jam_mulai" class="input-full" required>
                </div>
                <div class="form-group" style="flex:1;">
                  <label>Jam Selesai</label>
                  <input type="time" name="jam_selesai" class="input-full" required>
                </div>
              </div>
              <button type="submit" class="btn-primary btn-full">Tambah Jadwal</button>
            </form>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h3>Daftar Slot Aktif</h3>
          </div>
          <div class="card-body" style="padding:0;">
            ${(!schedules || schedules.length === 0) 
              ? '<div style="padding:20px;text-align:center;color:var(--text-muted);">Belum ada jadwal slot aktif.</div>'
              : `
              <table class="data-table">
                <thead>
                  <tr>
                    <th>Hari</th>
                    <th>Jam</th>
                    <th>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  ${schedules.map(s => `
                    <tr>
                      <td style="text-transform:capitalize;font-weight:600;">${s.hari}</td>
                      <td>${s.jam_mulai} - ${s.jam_selesai}</td>
                      <td>
                        <button class="btn-danger btn-sm" onclick="deleteAvailability(${s.id})">Hapus</button>
                      </td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            `}
          </div>
        </div>
      </div>
    `;
  },

  unavailability: (dates) => {
    return `
      <div class="detail-grid">
        <div class="card">
          <div class="card-header">
            <h3>Atur Cuti / Libur</h3>
          </div>
          <div class="card-body" style="padding:20px;">
            <form onsubmit="submitUnavailability(event)">
              <div class="form-group" style="margin-bottom:16px;">
                <label>Tanggal Libur</label>
                <input type="date" name="tanggal" class="input-full" required>
              </div>
              <div class="form-group" style="margin-bottom:16px;">
                <label>Alasan / Keterangan</label>
                <input type="text" name="alasan" class="input-full" placeholder="Cuti sakit, libur nasional, dll.">
              </div>
              <button type="submit" class="btn-primary btn-full">Simpan Tanggal Libur</button>
            </form>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h3>Daftar Cuti Mendatang</h3>
          </div>
          <div class="card-body">
            ${(!dates || dates.length === 0) ? `<div style="padding:20px;text-align:center;color:#888;">Tidak ada cuti terjadwal.</div>` : `
              <table class="data-table">
                <thead><tr><th>Tanggal</th><th>Alasan</th><th>Aksi</th></tr></thead>
                <tbody>
                  ${dates.map(d => `
                    <tr>
                      <td><strong>${Pages.formatDate(d.tanggal)}</strong></td>
                      <td>${d.alasan || '-'}</td>
                      <td><button class="btn-danger btn-sm" onclick="deleteUnavailability(${d.id})">Hapus</button></td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            `}
          </div>
        </div>
      </div>
    `;
  },

  badgeStatus: (status) => {
    const s = (status || '').toLowerCase();
    let cls = 'badge-pending';
    let txt = s;
    
    if (s === 'menunggu_psikolog') { cls = 'badge-pending'; txt = 'Menunggu Psikolog'; }
    else if (s === 'diterima') { cls = 'badge-diproses'; txt = 'Akan Datang'; }
    else if (s === 'selesai') { cls = 'badge-selesai'; txt = 'Selesai'; }
    else if (s === 'batal') { cls = 'badge-ditolak'; txt = 'Batal'; }
    else if (s.startsWith('no_show')) { cls = 'badge-ditolak'; txt = 'No-Show'; }
    else if (s === 'menunggu_user') { cls = 'badge-pending'; txt = 'Menunggu User'; }
    
    return `<span class="badge ${cls}">${txt}</span>`;
  },

  formatDate: (dateStr) => {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
  }
};
