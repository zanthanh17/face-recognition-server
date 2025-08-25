// Work Hours Management JavaScript

class WorkHoursManager {
    constructor() {
        this.workHours = [];
        this.summary = [];
        this.currentView = 'daily';
        this.userHoursChart = null;
        this.trendChart = null;
        this.init();
    }

    init() {
        this.setDefaultDates();
        this.setupEventListeners();
        this.loadData();
    }

    setupEventListeners() {
        // Date selection
        document.getElementById('selectedDate').addEventListener('change', () => this.loadDailyData());
        document.getElementById('startDate').addEventListener('change', () => this.loadSummaryData());
        document.getElementById('endDate').addEventListener('change', () => this.loadSummaryData());

        // View mode toggle
        document.getElementById('dailyView').addEventListener('change', () => {
            this.currentView = 'daily';
            this.loadDailyData();
        });
        document.getElementById('summaryView').addEventListener('change', () => {
            this.currentView = 'summary';
            this.loadSummaryData();
        });
    }

    setDefaultDates() {
        const today = new Date();
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(today.getDate() - 7);
        
        document.getElementById('selectedDate').value = today.toISOString().split('T')[0];
        document.getElementById('startDate').value = sevenDaysAgo.toISOString().split('T')[0];
        document.getElementById('endDate').value = today.toISOString().split('T')[0];
    }

    async loadData() {
        if (this.currentView === 'daily') {
            await this.loadDailyData();
        } else {
            await this.loadSummaryData();
        }
    }

    async loadDailyData() {
        const selectedDate = document.getElementById('selectedDate').value;
        if (!selectedDate) return;

        try {
            const response = await fetch(`/attendance/work-hours?date=${selectedDate}`);
            const data = await response.json();
            
            this.workHours = data.users || [];
            this.updateStats();
            this.renderTable();
            this.updateCharts();
        } catch (error) {
            this.showError('Lỗi tải dữ liệu giờ làm');
        }
    }

    async loadSummaryData() {
        const startDate = document.getElementById('startDate').value;
        const endDate = document.getElementById('endDate').value;
        
        if (!startDate || !endDate) return;

        try {
            const response = await fetch(`/attendance/work-hours/summary?start_date=${startDate}&end_date=${endDate}`);
            const data = await response.json();
            
            this.summary = data.summary || [];
            this.updateStats();
            this.renderTable();
            this.updateCharts();
        } catch (error) {
            this.showError('Lỗi tải dữ liệu tổng hợp');
        }
    }

    updateStats() {
        const data = this.currentView === 'daily' ? this.workHours : this.summary;
        
        const totalWorkers = data.length;
        const totalHours = data.reduce((sum, item) => sum + item.work_hours, 0);
        const activeWorkers = data.filter(item => item.work_hours > 0).length;
        const avgHours = totalWorkers > 0 ? (totalHours / totalWorkers).toFixed(1) : 0;

        document.getElementById('total-workers').textContent = totalWorkers;
        document.getElementById('total-hours').textContent = `${totalHours.toFixed(1)}h`;
        document.getElementById('active-workers').textContent = activeWorkers;
        document.getElementById('avg-hours').textContent = `${avgHours}h`;
    }

    renderTable() {
        const tbody = document.getElementById('workHoursTableBody');
        const data = this.currentView === 'daily' ? this.workHours : this.summary;

        if (data.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-muted">
                        <i class="fas fa-inbox fa-2x mb-2"></i>
                        <p>Không có dữ liệu giờ làm</p>
                    </td>
                </tr>
            `;
        } else {
            tbody.innerHTML = data.map(item => this.createWorkHoursRow(item)).join('');
        }
    }

    createWorkHoursRow(item) {
        const firstCheckIn = new Date(item.first_check_in * 1000).toLocaleTimeString('vi-VN', {
            hour: '2-digit',
            minute: '2-digit'
        });
        const lastCheckOut = new Date(item.last_check_out * 1000).toLocaleTimeString('vi-VN', {
            hour: '2-digit',
            minute: '2-digit'
        });
        const date = new Date(item.first_check_in * 1000).toLocaleDateString('vi-VN');
        
        const statusClass = item.work_hours >= 8 ? 'success' : item.work_hours >= 4 ? 'warning' : 'danger';
        const statusText = item.work_hours >= 8 ? 'Đủ giờ' : item.work_hours >= 4 ? 'Thiếu giờ' : 'Ít giờ';

        // Add cross-day indicator
        const crossDayIndicator = item.cross_day ? 
            '<br><small class="text-warning"><i class="fas fa-moon me-1"></i>Qua ngày</small>' : '';

        return `
            <tr class="fade-in">
                <td>
                    <div>
                        <strong>${item.name}</strong>
                        <br>
                        <small class="text-muted">ID: ${item.user_id.substring(0, 8)}...</small>
                    </div>
                </td>
                <td>${date}</td>
                <td>
                    <span class="badge bg-info">${firstCheckIn}</span>
                </td>
                <td>
                    <span class="badge bg-secondary">${lastCheckOut}</span>
                    ${crossDayIndicator}
                </td>
                <td>
                    <strong class="text-primary">${item.work_hours}h</strong>
                </td>
                <td>
                    <span class="badge bg-light text-dark">${item.check_ins}</span>
                </td>
                <td>
                    <span class="badge bg-${statusClass}">${statusText}</span>
                </td>
            </tr>
        `;
    }

    updateCharts() {
        this.updateUserHoursChart();
        this.updateTrendChart();
    }

    updateUserHoursChart() {
        const ctx = document.getElementById('userHoursChart');
        if (!ctx) return;

        if (this.userHoursChart) {
            this.userHoursChart.destroy();
        }

        const data = this.currentView === 'daily' ? this.workHours : this.summary;
        
        if (data.length === 0) return;

        const labels = data.map(item => item.name);
        const hours = data.map(item => item.work_hours);

        this.userHoursChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Giờ làm việc',
                    data: hours,
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
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Giờ'
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }

    updateTrendChart() {
        const ctx = document.getElementById('trendChart');
        if (!ctx) return;

        if (this.trendChart) {
            this.trendChart.destroy();
        }

        if (this.currentView === 'summary' && this.summary.length > 0) {
            // Group by date and calculate average hours
            const dateGroups = {};
            this.summary.forEach(item => {
                const date = item.date;
                if (!dateGroups[date]) {
                    dateGroups[date] = [];
                }
                dateGroups[date].push(item.work_hours);
            });

            const dates = Object.keys(dateGroups).sort();
            const avgHours = dates.map(date => {
                const hours = dateGroups[date];
                return hours.reduce((sum, h) => sum + h, 0) / hours.length;
            });

            this.trendChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: dates.map(date => new Date(date).toLocaleDateString('vi-VN')),
                    datasets: [{
                        label: 'Trung bình giờ làm',
                        data: avgHours,
                        borderColor: '#198754',
                        backgroundColor: 'rgba(25, 135, 84, 0.1)',
                        borderWidth: 2,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Giờ'
                            }
                        }
                    }
                }
            });
        } else {
            // Show empty chart for daily view
            this.trendChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Không có dữ liệu',
                        data: [],
                        borderColor: '#6c757d',
                        backgroundColor: 'rgba(108, 117, 125, 0.1)'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });
        }
    }

    exportData() {
        const data = this.currentView === 'daily' ? this.workHours : this.summary;
        
        if (data.length === 0) {
            this.showError('Không có dữ liệu để export');
            return;
        }

        const headers = ['User', 'Ngày', 'Check In đầu', 'Check Out cuối', 'Tổng giờ', 'Số lần quét'];
        const csvContent = [
            headers.join(','),
            ...data.map(item => {
                const firstCheckIn = new Date(item.first_check_in * 1000).toLocaleTimeString('vi-VN');
                const lastCheckOut = new Date(item.last_check_out * 1000).toLocaleTimeString('vi-VN');
                const date = new Date(item.first_check_in * 1000).toLocaleDateString('vi-VN');
                
                return [
                    item.name,
                    date,
                    firstCheckIn,
                    lastCheckOut,
                    item.work_hours,
                    item.check_ins
                ].join(',');
            })
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', `work_hours_${this.currentView}_${new Date().toISOString().split('T')[0]}.csv`);
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

// Initialize work hours manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.workHoursManager = new WorkHoursManager();
});
