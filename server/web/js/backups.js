class BackupManager {
    constructor() {
        this.backups = [];
        this.init();
    }

    init() {
        this.loadBackups();
        this.setupEventListeners();
    }

    setupEventListeners() {
        // Restore confirmation
        document.getElementById('confirmRestoreBtn').addEventListener('click', () => {
            this.confirmRestore();
        });
    }

    async loadBackups() {
        try {
            this.showLoading();
            const response = await fetch('/backups');
            const data = await response.json();
            
            this.backups = data.backups || [];
            this.renderBackups();
            this.updateStats();
        } catch (error) {
            console.error('Error loading backups:', error);
            this.showError('Lỗi tải danh sách backups');
        } finally {
            this.hideLoading();
        }
    }

    renderBackups() {
        const tbody = document.getElementById('backupsTableBody');
        
        if (this.backups.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center text-muted py-4">
                        <i class="fas fa-database me-2"></i>
                        Không có backup nào
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.backups.map(backup => `
            <tr>
                <td>
                    <div class="d-flex align-items-center">
                        <div class="avatar-sm bg-primary rounded-circle d-flex align-items-center justify-content-center me-3">
                            <i class="fas fa-user text-white"></i>
                        </div>
                        <div>
                            <h6 class="mb-0">${backup.user_name}</h6>
                            <small class="text-muted">User ID: ${backup.user_id.substring(0, 8)}...</small>
                        </div>
                    </div>
                </td>
                <td>
                    <code class="small">${backup.user_id}</code>
                </td>
                <td>
                    <div>
                        <div class="fw-medium">${this.formatDate(backup.deleted_at)}</div>
                        <small class="text-muted">${this.formatTime(backup.deleted_at)}</small>
                    </div>
                </td>
                <td>
                    <span class="badge bg-info">
                        <i class="fas fa-history me-1"></i>
                        ${backup.attendance_logs_count} logs
                    </span>
                </td>
                <td>
                    <small class="text-muted">${backup.filename}</small>
                </td>
                <td>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-warning" onclick="backupManager.restoreBackup('${backup.filename}', '${backup.user_name}')">
                            <i class="fas fa-undo me-1"></i>Khôi phục
                        </button>
                        <button class="btn btn-outline-info" onclick="backupManager.viewBackupDetails('${backup.filename}')">
                            <i class="fas fa-eye me-1"></i>Chi tiết
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
    }

    updateStats() {
        document.getElementById('totalBackups').textContent = this.backups.length;
        document.getElementById('deletedUsers').textContent = this.backups.length;
        
        const totalLogs = this.backups.reduce((sum, backup) => sum + backup.attendance_logs_count, 0);
        document.getElementById('totalLogs').textContent = totalLogs;
        
        if (this.backups.length > 0) {
            const latestBackup = this.backups[0];
            document.getElementById('latestBackup').textContent = this.formatDate(latestBackup.deleted_at);
        } else {
            document.getElementById('latestBackup').textContent = '-';
        }
    }

    restoreBackup(filename, userName) {
        document.getElementById('restoreUserName').textContent = userName;
        this.currentRestoreFile = filename;
        
        const modal = new bootstrap.Modal(document.getElementById('restoreModal'));
        modal.show();
    }

    async confirmRestore() {
        if (!this.currentRestoreFile) return;

        try {
            this.showLoading();
            const response = await fetch(`/backups/${this.currentRestoreFile}/restore`, {
                method: 'POST'
            });

            const result = await response.json();

            if (response.ok) {
                this.showSuccess(`Khôi phục thành công! ${result.attendance_logs_restored} attendance logs đã được khôi phục.`);
                
                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('restoreModal'));
                modal.hide();
                
                // Refresh backups list
                this.loadBackups();
            } else {
                this.showError(`Lỗi: ${result.detail || 'Không thể khôi phục'}`);
            }
        } catch (error) {
            console.error('Error restoring backup:', error);
            this.showError('Lỗi kết nối server');
        } finally {
            this.hideLoading();
        }
    }

    async viewBackupDetails(filename) {
        try {
            const response = await fetch(`/backups/${filename}/details`);
            const data = await response.json();
            
            // Show details in a modal or alert
            let details = `User: ${data.user.name}\n`;
            details += `ID: ${data.user.id}\n`;
            details += `Position: ${data.user.position || 'N/A'}\n`;
            details += `Deleted at: ${this.formatDate(data.deleted_at)}\n`;
            details += `Attendance logs: ${data.attendance_logs.length}`;
            
            alert(details);
        } catch (error) {
            this.showError('Không thể xem chi tiết backup');
        }
    }

    refreshBackups() {
        this.loadBackups();
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('vi-VN');
    }

    formatTime(dateString) {
        const date = new Date(dateString);
        return date.toLocaleTimeString('vi-VN');
    }

    showLoading() {
        const tbody = document.getElementById('backupsTableBody');
        tbody.innerHTML = `
            <tr>
                <td colspan="6" class="text-center text-muted py-4">
                    <i class="fas fa-spinner fa-spin me-2"></i>
                    Đang tải...
                </td>
            </tr>
        `;
    }

    hideLoading() {
        // Loading is handled in renderBackups
    }

    showSuccess(message) {
        this.showNotification(message, 'success');
    }

    showError(message) {
        this.showNotification(message, 'error');
    }

    showNotification(message, type) {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `alert alert-${type === 'success' ? 'success' : 'danger'} alert-dismissible fade show position-fixed`;
        notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
        notification.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check-circle' : 'exclamation-circle'} me-2"></i>
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        document.body.appendChild(notification);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
        }, 5000);
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    window.backupManager = new BackupManager();
});
