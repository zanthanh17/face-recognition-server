// Attendance Management JavaScript

class AttendanceManager {
    constructor() {
        this.logs = [];
        this.filteredLogs = [];
        this.currentPage = 1;
        this.itemsPerPage = 20;
        this.statusChart = null;
        this.hourlyChart = null;
        this.init();
    }

    init() {
        this.loadData();
        this.setupEventListeners();
        this.setDefaultDates();
    }

    setupEventListeners() {
        // Filter event listeners
        document.getElementById('startDate').addEventListener('change', () => this.filterData());
        document.getElementById('endDate').addEventListener('change', () => this.filterData());
        document.getElementById('statusFilter').addEventListener('change', () => this.filterData());
        document.getElementById('userFilter').addEventListener('change', () => this.filterData());
    }

    setDefaultDates() {
        const today = new Date();
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(today.getDate() - 7);
        
        document.getElementById('startDate').value = sevenDaysAgo.toISOString().split('T')[0];
        document.getElementById('endDate').value = today.toISOString().split('T')[0];
    }

    async loadData() {
        try {
            const response = await fetch('/attendance/get?limit=1000');
            const data = await response.json();
            
            this.logs = data.items || [];
            // Sắp xếp logs theo thời gian mới nhất trước
            this.logs.sort((a, b) => b.ts - a.ts);
            this.filteredLogs = [...this.logs];
            
            this.updateStats();
            this.renderTable();
            this.updateCharts();
            this.populateUserFilter();
        } catch (error) {
            console.error('Error loading attendance data:', error);
            this.showError('Lỗi tải dữ liệu attendance');
        }
    }

    updateStats() {
        const totalLogs = this.logs.length;
        const successLogs = this.logs.filter(log => log.matched).length;
        const failedLogs = this.logs.filter(log => !log.matched).length;
        const uniqueUsers = new Set(this.logs.filter(log => log.matched).map(log => log.user_id)).size;

        document.getElementById('total-logs').textContent = totalLogs;
        document.getElementById('success-logs').textContent = successLogs;
        document.getElementById('failed-logs').textContent = failedLogs;
        document.getElementById('unique-users').textContent = uniqueUsers;
    }

    filterData() {
        const startDate = document.getElementById('startDate').value;
        const endDate = document.getElementById('endDate').value;
        const statusFilter = document.getElementById('statusFilter').value;
        const userFilter = document.getElementById('userFilter').value;

        this.filteredLogs = this.logs.filter(log => {
            const logDate = new Date(log.ts * 1000).toISOString().split('T')[0];
            
            const matchesDate = (!startDate || logDate >= startDate) && 
                              (!endDate || logDate <= endDate);
            
            const matchesStatus = !statusFilter || 
                                (statusFilter === 'success' && log.matched) ||
                                (statusFilter === 'failed' && !log.matched);
            
            const matchesUser = !userFilter || log.user_id === userFilter;

            return matchesDate && matchesStatus && matchesUser;
        });

        // Sắp xếp logs theo thời gian mới nhất trước
        this.filteredLogs.sort((a, b) => b.ts - a.ts);

        this.currentPage = 1;
        this.renderTable();
        this.updateCharts();
    }

    renderTable() {
        const tbody = document.getElementById('attendanceTableBody');
        const startIndex = (this.currentPage - 1) * this.itemsPerPage;
        const endIndex = startIndex + this.itemsPerPage;
        const pageLogs = this.filteredLogs.slice(startIndex, endIndex);

        if (pageLogs.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center text-muted">
                        <i class="fas fa-inbox fa-2x mb-2"></i>
                        <p>Không có dữ liệu</p>
                    </td>
                </tr>
            `;
        } else {
            tbody.innerHTML = pageLogs.map(log => this.createLogRow(log)).join('');
        }

        this.updatePagination();
    }

    createLogRow(log) {
        const timestamp = new Date(log.ts * 1000);
        const timeString = timestamp.toLocaleString('vi-VN');
        const statusClass = log.matched ? 'success' : 'failed';
        const statusText = log.matched ? 'Thành công' : 'Thất bại';
        const icon = log.matched ? 'fa-check-circle' : 'fa-times-circle';
        const distance = log.distance ? log.distance.toFixed(3) : '-';

        // Create captured image HTML
        let imageHtml = '';
        if (log.captured_image) {
            imageHtml = `
                <img src="data:image/jpeg;base64,${log.captured_image}" 
                     class="captured-image" 
                     alt="Captured face"
                     title="Ảnh capture lúc quét - Click để xem chi tiết"
                     style="width: 40px; height: 40px; object-fit: cover; border-radius: 50%; border: 2px solid var(--primary-color); display: block;">
            `;
        } else {
            imageHtml = `
                <div class="captured-image-placeholder">
                    <i class="fas fa-user"></i>
                </div>
            `;
        }

        return `
            <tr class="fade-in">
                <td>
                    <div>
                        <strong>${timeString}</strong>
                        <br>
                        <small class="text-muted">${timestamp.toLocaleDateString('vi-VN')}</small>
                    </div>
                </td>
                <td class="text-center">
                    <div style="cursor: pointer;" onclick="attendanceManager.showImageDetail('${log.captured_image || ''}', '${log.name || 'Unknown'}')">
                        ${imageHtml}
                    </div>
                </td>
                <td>
                    <div>
                        <strong>${log.name || 'Unknown'}</strong>
                        <br>
                        <small class="text-muted">ID: ${log.user_id.substring(0, 8)}...</small>
                    </div>
                </td>
                <td>
                    <span class="badge bg-${statusClass}">
                        <i class="fas ${icon} me-1"></i>${statusText}
                    </span>
                </td>
                <td>
                    <code>${distance}</code>
                </td>
                <td>
                    <button class="btn btn-sm btn-outline-info" onclick="attendanceManager.showLogDetail('${log.ts}')" 
                            title="Xem chi tiết">
                        <i class="fas fa-eye"></i>
                    </button>
                </td>
            </tr>
        `;
    }

    updatePagination() {
        const totalPages = Math.ceil(this.filteredLogs.length / this.itemsPerPage);
        const startItem = (this.currentPage - 1) * this.itemsPerPage + 1;
        const endItem = Math.min(this.currentPage * this.itemsPerPage, this.filteredLogs.length);

        document.getElementById('showing-start').textContent = this.filteredLogs.length > 0 ? startItem : 0;
        document.getElementById('showing-end').textContent = endItem;
        document.getElementById('total-count').textContent = this.filteredLogs.length;

        document.getElementById('prevPage').disabled = this.currentPage === 1;
        document.getElementById('nextPage').disabled = this.currentPage === totalPages;
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.renderTable();
        }
    }

    nextPage() {
        const totalPages = Math.ceil(this.filteredLogs.length / this.itemsPerPage);
        if (this.currentPage < totalPages) {
            this.currentPage++;
            this.renderTable();
        }
    }

    populateUserFilter() {
        const userFilter = document.getElementById('userFilter');
        const uniqueUsers = [...new Set(this.logs.filter(log => log.matched).map(log => log.user_id))];
        
        // Clear existing options except the first one
        userFilter.innerHTML = '<option value="">Tất cả users</option>';
        
        uniqueUsers.forEach(userId => {
            const user = this.logs.find(log => log.user_id === userId);
            if (user) {
                const option = document.createElement('option');
                option.value = userId;
                option.textContent = user.name || 'Unknown';
                userFilter.appendChild(option);
            }
        });
    }

    updateCharts() {
        this.updateStatusChart();
        this.updateHourlyChart();
    }

    updateStatusChart() {
        const ctx = document.getElementById('statusChart');
        if (!ctx) return;

        if (this.statusChart) {
            this.statusChart.destroy();
        }

        const successCount = this.filteredLogs.filter(log => log.matched).length;
        const failedCount = this.filteredLogs.filter(log => !log.matched).length;

        this.statusChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Thành công', 'Thất bại'],
                datasets: [{
                    data: [successCount, failedCount],
                    backgroundColor: ['#198754', '#dc3545'],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }

    updateHourlyChart() {
        const ctx = document.getElementById('hourlyChart');
        if (!ctx) return;

        if (this.hourlyChart) {
            this.hourlyChart.destroy();
        }

        // Group logs by hour
        const hourlyData = new Array(24).fill(0);
        this.filteredLogs.forEach(log => {
            const hour = new Date(log.ts * 1000).getHours();
            hourlyData[hour]++;
        });

        const labels = Array.from({length: 24}, (_, i) => `${i}:00`);

        this.hourlyChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Số lần quét',
                    data: hourlyData,
                    backgroundColor: '#0d6efd',
                    borderColor: '#0d6efd',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    showLogDetail(timestamp) {
        const log = this.logs.find(l => l.ts.toString() === timestamp);
        if (!log) return;

        const logDate = new Date(log.ts * 1000);
        const details = `
            <div class="row">
                <div class="col-md-6">
                    <h6>Thông tin cơ bản</h6>
                    <table class="table table-borderless">
                        <tr><td><strong>Thời gian:</strong></td><td>${logDate.toLocaleString('vi-VN')}</td></tr>
                        <tr><td><strong>User:</strong></td><td>${log.name || 'Unknown'}</td></tr>
                        <tr><td><strong>User ID:</strong></td><td><code>${log.user_id}</code></td></tr>
                        <tr><td><strong>Trạng thái:</strong></td><td>
                            <span class="badge bg-${log.matched ? 'success' : 'danger'}">
                                ${log.matched ? 'Thành công' : 'Thất bại'}
                            </span>
                        </td></tr>
                    </table>
                </div>
                <div class="col-md-6">
                    <h6>Chi tiết kỹ thuật</h6>
                    <table class="table table-borderless">
                        <tr><td><strong>Distance:</strong></td><td><code>${log.distance ? log.distance.toFixed(6) : 'N/A'}</code></td></tr>
                        <tr><td><strong>Timestamp:</strong></td><td><code>${log.ts}</code></td></tr>
                        <tr><td><strong>ISO Time:</strong></td><td><code>${log.timestamp}</code></td></tr>
                    </table>
                </div>
            </div>
        `;

        // Show in modal or alert
        alert(`Chi tiết log:\n\n${details.replace(/<[^>]*>/g, '')}`);
    }

    showImageDetail(capturedImage, userName) {
        const modal = new bootstrap.Modal(document.getElementById('imageModal'));
        const container = document.getElementById('modalImageContainer');
        
        if (capturedImage && capturedImage.trim() !== '') {
            container.innerHTML = `
                <div>
                    <h6 class="mb-3">Ảnh capture của: <strong>${userName}</strong></h6>
                    <img src="data:image/jpeg;base64,${capturedImage}" 
                         class="modal-image" 
                         alt="Captured face of ${userName}">
                    <p class="text-muted mt-2">
                        <small>Ảnh được capture tại thời điểm quét khuôn mặt</small>
                    </p>
                </div>
            `;
        } else {
            container.innerHTML = `
                <div>
                    <i class="fas fa-image fa-3x text-muted mb-3"></i>
                    <p class="text-muted">Không có ảnh capture cho log này</p>
                    <p class="text-muted">
                        <small>Ảnh capture chỉ có sẵn cho các log từ phiên bản mới</small>
                    </p>
                </div>
            `;
        }
        
        modal.show();
    }

    exportData() {
        if (this.filteredLogs.length === 0) {
            this.showError('Không có dữ liệu để export');
            return;
        }

        const headers = ['Thời gian', 'User', 'User ID', 'Trạng thái', 'Distance', 'Timestamp'];
        const csvContent = [
            headers.join(','),
            ...this.filteredLogs.map(log => [
                new Date(log.ts * 1000).toLocaleString('vi-VN'),
                log.name || 'Unknown',
                log.user_id,
                log.matched ? 'Thành công' : 'Thất bại',
                log.distance || '',
                log.timestamp
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `attendance_logs_${new Date().toISOString().split('T')[0]}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    refreshData() {
        this.loadData();
    }

    showError(message) {
        if (window.faceLogApp) {
            window.faceLogApp.showNotification(message, 'danger');
        } else {
            alert(message);
        }
    }

    showSuccess(message) {
        if (window.faceLogApp) {
            window.faceLogApp.showNotification(message, 'success');
        } else {
            alert(message);
        }
    }
}

// Initialize attendance manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.attendanceManager = new AttendanceManager();
});
