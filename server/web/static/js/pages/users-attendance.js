// Minimal Users Manager for Attendance Page
// Only contains functions needed for attendance.html

class UsersManager {
    constructor() {
        // Minimal initialization - no DOM manipulation
    }

    async cleanupOrphanedData() {
        if (!confirm('Are you sure you want to clean up all attendance logs that have no corresponding users?\n\nThis action will permanently delete logs of previously deleted users.')) {
            return;
        }

        try {
            const token = localStorage.getItem('access_token');
            const response = await fetch('/admin/cleanup-orphaned-data', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const result = await response.json();

            if (response.ok) {
                this.showSuccess(`Cleanup successful!\nRemoved: ${result.removed_logs} logs\nRemaining: ${result.remaining_logs} logs`);
                // Refresh attendance data if available
                if (window.attendanceManager) {
                    window.attendanceManager.refreshData();
                }
            } else {
                this.showError(`Error: ${result.detail}`);
            }
        } catch (error) {
            this.showError('Server connection error');
        }
    }

    async resetAllData() {
        const confirmText = prompt('To reset all data, please type "RESET" (uppercase):');
        
        if (confirmText !== 'RESET') {
            this.showError('Confirmation incorrect. Operation cancelled.');
            return;
        }

        if (!confirm('⚠️ WARNING: This action will delete EVERYTHING:\n- Users\n- Attendance logs\n- Backups\n\nAre you ABSOLUTELY SURE you want to continue?')) {
            return;
        }

        try {
            const token = localStorage.getItem('access_token');
            const response = await fetch('/admin/reset-all-data', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            const result = await response.json();

            if (response.ok) {
                this.showSuccess('Reset all data successful!\nSystem has been completely cleaned.');
                // Refresh attendance data if available
                if (window.attendanceManager) {
                    window.attendanceManager.refreshData();
                }
            } else {
                this.showError(`Error: ${result.detail}`);
            }
        } catch (error) {
            this.showError('Server connection error');
        }
    }

    showSuccess(message) {
        if (window.faceLogApp) {
            window.faceLogApp.showNotification(message, 'success');
        } else {
            alert(message);
        }
    }

    showError(message) {
        if (window.faceLogApp) {
            window.faceLogApp.showNotification(message, 'danger');
        } else {
            alert(message);
        }
    }
}

// Initialize users manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    try {
        window.usersManager = new UsersManager();
    } catch (error) {
        console.error('Error initializing UsersManager:', error);
    }
});

