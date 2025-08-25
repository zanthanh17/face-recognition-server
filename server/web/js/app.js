// Main JavaScript for FaceLog Web Interface

class FaceLogApp {
    constructor() {
        this.init();
    }

    init() {
        this.loadStats();
        this.loadRecentActivity();
        this.initChart();
        this.startAutoRefresh();
    }

    async loadStats() {
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();
            
            document.getElementById('total-users').textContent = data.total_users;
            document.getElementById('active-users').textContent = data.active_users;
            document.getElementById('attendance-logs').textContent = data.attendance_logs;
            document.getElementById('threshold').textContent = data.recognition_threshold;
            
            // Add animation
            this.animateNumbers();
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    async loadRecentActivity() {
        try {
            const response = await fetch('/attendance/get?limit=10');
            const data = await response.json();
            
            const activityContainer = document.getElementById('recent-activity');
            
            if (data.items && data.items.length > 0) {
                activityContainer.innerHTML = data.items.map(item => this.createActivityItem(item)).join('');
            } else {
                activityContainer.innerHTML = `
                    <div class="text-center text-muted">
                        <i class="fas fa-inbox fa-3x mb-3"></i>
                        <p>Chưa có hoạt động nào</p>
                    </div>
                `;
            }
        } catch (error) {
            console.error('Error loading recent activity:', error);
            document.getElementById('recent-activity').innerHTML = `
                <div class="text-center text-danger">
                    <i class="fas fa-exclamation-triangle fa-2x mb-2"></i>
                    <p>Lỗi tải dữ liệu</p>
                </div>
            `;
        }
    }

    createActivityItem(item) {
        const timestamp = new Date(item.ts * 1000);
        const timeString = timestamp.toLocaleString('vi-VN');
        const statusClass = item.matched ? 'success' : 'failed';
        const statusText = item.matched ? 'Thành công' : 'Thất bại';
        const icon = item.matched ? 'fa-check-circle' : 'fa-times-circle';
        
        return `
            <div class="activity-item fade-in">
                <div class="d-flex justify-content-between align-items-start">
                    <div class="flex-grow-1">
                        <div class="d-flex align-items-center mb-1">
                            <i class="fas ${icon} text-${statusClass} me-2"></i>
                            <strong>${item.name || 'Unknown'}</strong>
                            <span class="activity-status ${statusClass} ms-2">${statusText}</span>
                        </div>
                        <div class="activity-time">
                            <i class="fas fa-clock me-1"></i>${timeString}
                        </div>
                        ${item.distance ? `<small class="text-muted">Distance: ${item.distance.toFixed(3)}</small>` : ''}
                    </div>
                </div>
            </div>
        `;
    }

    initChart() {
        const ctx = document.getElementById('statsChart');
        if (!ctx) return;

        this.chart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Thành công', 'Thất bại'],
                datasets: [{
                    data: [0, 0],
                    backgroundColor: [
                        '#198754',
                        '#dc3545'
                    ],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true
                        }
                    }
                }
            }
        });

        this.updateChart();
    }

    async updateChart() {
        try {
            const response = await fetch('/attendance/get?limit=100');
            const data = await response.json();
            
            if (data.items && data.items.length > 0) {
                const successCount = data.items.filter(item => item.matched).length;
                const failedCount = data.items.filter(item => !item.matched).length;
                
                this.chart.data.datasets[0].data = [successCount, failedCount];
                this.chart.update();
            }
        } catch (error) {
            console.error('Error updating chart:', error);
        }
    }

    animateNumbers() {
        const elements = document.querySelectorAll('#total-users, #active-users, #attendance-logs');
        
        elements.forEach(element => {
            const finalValue = parseInt(element.textContent);
            const duration = 1000;
            const step = finalValue / (duration / 16);
            let currentValue = 0;
            
            const timer = setInterval(() => {
                currentValue += step;
                if (currentValue >= finalValue) {
                    currentValue = finalValue;
                    clearInterval(timer);
                }
                element.textContent = Math.floor(currentValue);
            }, 16);
        });
    }

    startAutoRefresh() {
        // Refresh data every 30 seconds
        setInterval(() => {
            this.loadStats();
            this.loadRecentActivity();
            this.updateChart();
        }, 30000);
    }

    showNotification(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `alert alert-${type} alert-dismissible fade show position-fixed`;
        toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
        toast.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        document.body.appendChild(toast);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }
}

// Utility functions
const FaceLogUtils = {
    formatDateTime(timestamp) {
        return new Date(timestamp * 1000).toLocaleString('vi-VN');
    },

    formatDuration(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return `${hours}h ${minutes}m`;
    },

    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    async apiCall(url, options = {}) {
        try {
            const response = await fetch(url, {
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                ...options
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('API call failed:', error);
            throw error;
        }
    }
};

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.faceLogApp = new FaceLogApp();
    
    // Add global error handler
    window.addEventListener('error', (event) => {
        console.error('Global error:', event.error);
        if (window.faceLogApp) {
            window.faceLogApp.showNotification('Có lỗi xảy ra', 'danger');
        }
    });
});

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { FaceLogApp, FaceLogUtils };
}
