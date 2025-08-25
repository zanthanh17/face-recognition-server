// Users Management JavaScript

class UsersManager {
    constructor() {
        this.users = [];
        this.filteredUsers = [];
        this.init();
    }

    init() {
        this.loadUsers();
        this.setupEventListeners();
        this.loadStats();
    }

    setupEventListeners() {
        // Search functionality
        document.getElementById('searchInput').addEventListener('input', 
            FaceLogUtils.debounce(() => this.filterUsers(), 300)
        );

        // Filter functionality
        document.getElementById('statusFilter').addEventListener('change', () => this.filterUsers());
        document.getElementById('modelFilter').addEventListener('change', () => this.filterUsers());

        // Add user form
        document.getElementById('saveUserBtn').addEventListener('click', () => this.saveUser());
        
        // Image preview
        document.getElementById('userImage').addEventListener('change', (e) => this.handleImagePreview(e));
        
        // Edit user form
        document.getElementById('updateUserBtn').addEventListener('click', () => this.updateUser());
        
        // Edit image preview
        document.getElementById('editUserImage').addEventListener('change', (e) => this.handleEditImagePreview(e));
    }

    async loadUsers() {
        try {
            const response = await fetch('/api/users');
            const data = await response.json();
            
            this.users = data.users || [];
            this.filteredUsers = [...this.users];
            this.renderUsers();
        } catch (error) {
            console.error('Error loading users:', error);
            this.showError('Lỗi tải danh sách users');
        }
    }

    async loadStats() {
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();
            
            document.getElementById('total-users').textContent = data.total_users;
            document.getElementById('active-users').textContent = data.active_users;
            document.getElementById('threshold').textContent = data.recognition_threshold;
            
            // Calculate recent users (last 7 days)
            const sevenDaysAgo = new Date();
            sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
            
            const recentUsers = this.users.filter(user => {
                const createdDate = new Date(user.created_at);
                return createdDate >= sevenDaysAgo;
            }).length;
            
            document.getElementById('recent-users').textContent = recentUsers;
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    filterUsers() {
        const searchTerm = document.getElementById('searchInput').value.toLowerCase();
        const statusFilter = document.getElementById('statusFilter').value;
        const modelFilter = document.getElementById('modelFilter').value;

        this.filteredUsers = this.users.filter(user => {
            const matchesSearch = user.name.toLowerCase().includes(searchTerm) ||
                                (user.position && user.position.toLowerCase().includes(searchTerm));
            
            const matchesStatus = !statusFilter || 
                                (statusFilter === 'active' && user.active) ||
                                (statusFilter === 'inactive' && !user.active);
            
            const matchesModel = !modelFilter || user.model === modelFilter;

            return matchesSearch && matchesStatus && matchesModel;
        });

        this.renderUsers();
    }

    renderUsers() {
        const tbody = document.getElementById('usersTableBody');
        
        if (this.filteredUsers.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-muted">
                        <i class="fas fa-inbox fa-2x mb-2"></i>
                        <p>Không tìm thấy users nào</p>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.filteredUsers.map(user => this.createUserRow(user)).join('');
    }

    createUserRow(user) {
        const createdDate = new Date(user.created_at).toLocaleDateString('vi-VN');
        const statusBadge = user.active ? 
            '<span class="badge bg-success">Active</span>' : 
            '<span class="badge bg-secondary">Inactive</span>';
        
        const avatarSrc = user.image_base64 ? 
            `data:image/jpeg;base64,${user.image_base64}` : 
            'https://via.placeholder.com/40x40?text=U';

        return `
            <tr class="fade-in">
                <td>
                    <img src="${avatarSrc}" class="user-avatar" alt="${user.name}" 
                         onclick="usersManager.showUserDetail('${user.id}')" 
                         style="cursor: pointer;" title="Click để xem chi tiết">
                </td>
                <td>
                    <div>
                        <strong>${user.name}</strong>
                        <br>
                        <small class="text-muted">ID: ${user.id.substring(0, 8)}...</small>
                    </div>
                </td>
                <td>${user.position || '-'}</td>
                <td>
                    <span class="badge bg-info">${user.model}</span>
                </td>
                <td>${createdDate}</td>
                <td>${statusBadge}</td>
                <td>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-primary" onclick="usersManager.showUserDetail('${user.id}')" 
                                title="Xem chi tiết">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-outline-warning" onclick="usersManager.editUser('${user.id}')" 
                                title="Chỉnh sửa user">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-outline-danger" onclick="usersManager.deleteUser('${user.id}')" 
                                title="Xóa user">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }

    handleImagePreview(event) {
        const file = event.target.files[0];
        const preview = document.getElementById('imagePreview');
        const previewImg = document.getElementById('previewImg');

        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImg.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        } else {
            preview.style.display = 'none';
        }
    }

    handleEditImagePreview(event) {
        const file = event.target.files[0];
        const preview = document.getElementById('editImagePreview');
        const previewImg = document.getElementById('editPreviewImg');

        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImg.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        } else {
            preview.style.display = 'none';
        }
    }

    async saveUser() {
        const name = document.getElementById('userName').value.trim();
        const position = document.getElementById('userPosition').value.trim();
        const imageFile = document.getElementById('userImage').files[0];

        if (!name) {
            this.showError('Vui lòng nhập tên user');
            return;
        }

        if (!imageFile) {
            this.showError('Vui lòng chọn ảnh khuôn mặt');
            return;
        }

        const saveBtn = document.getElementById('saveUserBtn');
        const originalText = saveBtn.innerHTML;
        saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Đang lưu...';
        saveBtn.disabled = true;

        try {
            const base64 = await this.fileToBase64(imageFile);
            
            const response = await fetch('/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    name: name,
                    position: position,
                    image_base64: base64
                })
            });

            const data = await response.json();

            if (response.ok) {
                this.showSuccess(`User "${name}" đã được đăng ký thành công!`);
                this.resetForm();
                this.loadUsers();
                this.loadStats();
                
                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('addUserModal'));
                modal.hide();
            } else {
                this.showError(`Lỗi: ${data.detail || 'Không thể đăng ký user'}`);
            }
        } catch (error) {
            console.error('Error saving user:', error);
            this.showError('Lỗi kết nối server');
        } finally {
            saveBtn.innerHTML = originalText;
            saveBtn.disabled = false;
        }
    }

    async deleteUser(userId) {
        const user = this.users.find(u => u.id === userId);
        if (!user) return;

        const backupOption = confirm(`Bạn có chắc chắn muốn xóa user "${user.name}"?\n\nChọn OK để tạo backup trước khi xóa.\nChọn Cancel để xóa không backup.`);
        
        if (backupOption === null) {
            return; // User cancelled
        }

        try {
            const response = await fetch(`/users/${userId}?backup=${backupOption}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                const result = await response.json();
                let message = `User "${user.name}" đã được xóa thành công!`;
                if (result.backup_created) {
                    message += `\nĐã tạo backup với ${result.attendance_logs_removed} attendance logs.`;
                }
                this.showSuccess(message);
                this.loadUsers();
                this.loadStats();
            } else {
                const error = await response.json();
                this.showError(`Lỗi: ${error.detail || 'Không thể xóa user'}`);
            }
        } catch (error) {
            console.error('Error deleting user:', error);
            this.showError('Lỗi kết nối server');
        }
    }

    async showUserDetail(userId) {
        const user = this.users.find(u => u.id === userId);
        if (!user) return;

        const modal = new bootstrap.Modal(document.getElementById('userDetailModal'));
        const content = document.getElementById('userDetailContent');

        const createdDate = new Date(user.created_at).toLocaleString('vi-VN');
        const avatarSrc = user.image_base64 ? 
            `data:image/jpeg;base64,${user.image_base64}` : 
            'https://via.placeholder.com/200x200?text=U';

        content.innerHTML = `
            <div class="row">
                <div class="col-md-4 text-center">
                    <img src="${avatarSrc}" class="img-fluid rounded" style="max-width: 200px;">
                </div>
                <div class="col-md-8">
                    <h5>Thông tin User</h5>
                    <table class="table table-borderless">
                        <tr>
                            <td><strong>ID:</strong></td>
                            <td><code>${user.id}</code></td>
                        </tr>
                        <tr>
                            <td><strong>Tên:</strong></td>
                            <td>${user.name}</td>
                        </tr>
                        <tr>
                            <td><strong>Chức vụ:</strong></td>
                            <td>${user.position || '-'}</td>
                        </tr>
                        <tr>
                            <td><strong>Model:</strong></td>
                            <td><span class="badge bg-info">${user.model}</span></td>
                        </tr>
                        <tr>
                            <td><strong>Ngày tạo:</strong></td>
                            <td>${createdDate}</td>
                        </tr>
                        <tr>
                            <td><strong>Trạng thái:</strong></td>
                            <td>${user.active ? '<span class="badge bg-success">Active</span>' : '<span class="badge bg-secondary">Inactive</span>'}</td>
                        </tr>
                        <tr>
                            <td><strong>Embedding length:</strong></td>
                            <td>${user.embedding ? user.embedding.length : 'N/A'}</td>
                        </tr>
                    </table>
                </div>
            </div>
        `;

        modal.show();
    }

    resetForm() {
        document.getElementById('addUserForm').reset();
        document.getElementById('imagePreview').style.display = 'none';
    }

    editUser(userId) {
        const user = this.users.find(u => u.id === userId);
        if (!user) return;

        // Reset edit form first
        document.getElementById('editUserForm').reset();
        document.getElementById('editImagePreview').style.display = 'none';
        
        // Populate edit form with current user data
        document.getElementById('editUserId').value = user.id;
        document.getElementById('editUserName').value = user.name;
        document.getElementById('editUserPosition').value = user.position || '';
        
        // Show current image
        const currentImage = document.getElementById('editCurrentImage');
        if (user.image_base64) {
            currentImage.src = `data:image/jpeg;base64,${user.image_base64}`;
        } else {
            currentImage.src = 'https://via.placeholder.com/200x200?text=U';
        }
        
        // Show modal
        const modal = new bootstrap.Modal(document.getElementById('editUserModal'));
        modal.show();
    }

    async updateUser() {
        const userId = document.getElementById('editUserId').value;
        const name = document.getElementById('editUserName').value.trim();
        const position = document.getElementById('editUserPosition').value.trim();
        const imageFile = document.getElementById('editUserImage').files[0];

        if (!name) {
            this.showError('Vui lòng nhập tên user');
            return;
        }

        const updateBtn = document.getElementById('updateUserBtn');
        const originalText = updateBtn.innerHTML;
        updateBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Đang cập nhật...';
        updateBtn.disabled = true;

        try {
            const user = this.users.find(u => u.id === userId);
            if (!user) {
                this.showError('Không tìm thấy user');
                return;
            }

            const updateData = {
                name: name,
                position: position
            };

            // If new image is selected, include it
            if (imageFile) {
                const base64 = await this.fileToBase64(imageFile);
                updateData.image_base64 = base64;
            }

            const response = await fetch(`/users/${userId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(updateData)
            });

            const data = await response.json();

            if (response.ok) {
                this.showSuccess(`User "${name}" đã được cập nhật thành công!`);
                this.loadUsers();
                this.loadStats();
                
                // Close modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('editUserModal'));
                modal.hide();
            } else {
                this.showError(`Lỗi: ${data.detail || 'Không thể cập nhật user'}`);
            }
        } catch (error) {
            console.error('Error updating user:', error);
            this.showError('Lỗi kết nối server');
        } finally {
            updateBtn.innerHTML = originalText;
            updateBtn.disabled = false;
        }
    }

    fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = error => reject(error);
        });
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

    async cleanupOrphanedData() {
        if (!confirm('Bạn có chắc chắn muốn dọn dẹp tất cả dữ liệu attendance logs không có user tương ứng?\n\nHành động này sẽ xóa vĩnh viễn các logs của users đã bị xóa trước đó.')) {
            return;
        }

        try {
            const response = await fetch('/admin/cleanup-orphaned-data', {
                method: 'POST'
            });

            const result = await response.json();

            if (response.ok) {
                this.showSuccess(`Dọn dẹp thành công!\nĐã xóa: ${result.removed_logs} logs\nCòn lại: ${result.remaining_logs} logs`);
                this.loadStats();
            } else {
                this.showError(`Lỗi: ${result.detail}`);
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }

    async resetAllData() {
        const confirmText = prompt('Để reset tất cả dữ liệu, hãy nhập "RESET" (viết hoa):');
        
        if (confirmText !== 'RESET') {
            this.showError('Xác nhận không đúng. Hủy thao tác.');
            return;
        }

        if (!confirm('⚠️ CẢNH BÁO: Hành động này sẽ xóa TẤT CẢ:\n- Users\n- Attendance logs\n- Backups\n\nBạn có CHẮC CHẮN muốn tiếp tục?')) {
            return;
        }

        try {
            const response = await fetch('/admin/reset-all-data', {
                method: 'POST'
            });

            const result = await response.json();

            if (response.ok) {
                this.showSuccess('Reset tất cả dữ liệu thành công!\nHệ thống đã được làm sạch hoàn toàn.');
                this.loadUsers();
                this.loadStats();
            } else {
                this.showError(`Lỗi: ${result.detail}`);
            }
        } catch (error) {
            this.showError('Lỗi kết nối server');
        }
    }
}

// Initialize users manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.usersManager = new UsersManager();
});
