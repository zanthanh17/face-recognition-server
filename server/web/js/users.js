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
        let searchTimeout;
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.addEventListener('input', () => {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(() => this.filterUsers(), 300);
            });
        }

        // Filter functionality with null check
        const statusFilter = document.getElementById('statusFilter');
        if (statusFilter) {
            statusFilter.addEventListener('change', () => this.filterUsers());
        }

        // Add user form with null check
        const saveUserBtn = document.getElementById('saveUserBtn');
        if (saveUserBtn) {
            saveUserBtn.addEventListener('click', () => this.saveUser());
        }
        
        // Image preview with null check
        const userImageInput = document.getElementById('userImage');
        if (userImageInput) {
            userImageInput.addEventListener('change', (e) => this.handleImagePreview(e));
        }
        
        // Edit user form
        const updateUserBtn = document.getElementById('updateUserBtn');
        if (updateUserBtn) {
            updateUserBtn.addEventListener('click', () => this.updateUser());
        }
        
        // Edit image preview with null check
        const editUserImageInput = document.getElementById('editUserImage');
        if (editUserImageInput) {
            editUserImageInput.addEventListener('change', (e) => this.handleEditImagePreview(e));
        }
    }

    async loadUsers() {
        try {
            const token = localStorage.getItem('access_token');
            const headers = {
                'Authorization': `Bearer ${token}`
            };

            const response = await fetch('/users', { headers });
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
            const token = localStorage.getItem('access_token');
            const headers = {
                'Authorization': `Bearer ${token}`
            };

            const response = await fetch('/users', { headers });
            const data = await response.json();
            
            document.getElementById('totalUsers').textContent = data.total_users || 0;
            document.getElementById('activeUsers').textContent = data.active_users || 0;
            document.getElementById('inactiveUsers').textContent = (data.total_users || 0) - (data.active_users || 0);
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    updateStats() {
        // Update stats locally without API call
        const totalUsers = this.users.length;
        const activeUsers = this.users.filter(user => user.active).length;
        
        // Calculate recent users (last 7 days)
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        const recentUsers = this.users.filter(user => {
            const createdDate = new Date(user.created_at);
            return createdDate >= sevenDaysAgo;
        }).length;
        
        const totalUsersEl = document.getElementById('totalUsers');
        const activeUsersEl = document.getElementById('activeUsers');
        const inactiveUsersEl = document.getElementById('inactiveUsers');
        
        if (totalUsersEl) totalUsersEl.textContent = totalUsers;
        if (activeUsersEl) activeUsersEl.textContent = activeUsers;
        if (inactiveUsersEl) inactiveUsersEl.textContent = totalUsers - activeUsers;
    }

    filterUsers() {
        const searchTerm = document.getElementById('searchInput').value.toLowerCase();
        const statusFilter = document.getElementById('statusFilter').value;

        this.filteredUsers = this.users.filter(user => {
            const matchesSearch = user.name.toLowerCase().includes(searchTerm) ||
                                (user.position && user.position.toLowerCase().includes(searchTerm));
            
            const matchesStatus = !statusFilter || 
                                (statusFilter === 'active' && user.active) ||
                                (statusFilter === 'inactive' && !user.active);

            return matchesSearch && matchesStatus;
        });

        this.renderUsers();
    }

    renderUsers() {
        const tbody = document.getElementById('usersTableBody');
        
        if (this.filteredUsers.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="4" class="text-center text-muted">
                        <i class="fas fa-inbox fa-2x mb-2"></i>
                        <p>No users found</p>
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
                    <div class="d-flex align-items-center">
                        <img src="${avatarSrc}" class="user-avatar me-3" alt="${user.name}" 
                             onclick="usersManager.showUserDetail('${user.id}')" 
                             style="cursor: pointer;" title="Click to view details">
                        <div>
                            <strong>${user.name}</strong>
                            <br>
                            <small class="text-muted">ID: ${user.id.substring(0, 8)}...</small>
                            <br>
                            ${statusBadge}
                        </div>
                    </div>
                </td>
                <td>${user.position || '-'}</td>
                <td>${createdDate}</td>
                <td>
                    <div class="btn-group btn-group-sm">
                        <button class="btn btn-outline-warning" onclick="usersManager.editUser('${user.id}')" 
                                title="Edit user">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-outline-danger" onclick="usersManager.deleteUser('${user.id}')" 
                                title="Delete user">
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

        if (file && preview && previewImg) {
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImg.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        } else if (preview) {
            preview.style.display = 'none';
        }
    }

    handleEditImagePreview(event) {
        const file = event.target.files[0];
        const preview = document.getElementById('editImagePreview');
        const previewImg = document.getElementById('editPreviewImg');

        if (file && preview && previewImg) {
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImg.src = e.target.result;
                preview.style.display = 'block';
            };
            reader.readAsDataURL(file);
        } else if (preview) {
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
        saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Đang xử lý ảnh...';
        saveBtn.disabled = true;

        try {
            const base64 = await this.fileToBase64(imageFile);
            
            saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Đang lưu...';
            
            const token = localStorage.getItem('access_token');
            const response = await fetch('/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
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
                
                // Optimistic update - add user to list immediately
                const newUser = {
                    id: data.user_id,
                    name: name,
                    position: position,
                    model: data.model,
                    created_at: new Date().toISOString(),
                    active: true,
                    image_base64: base64
                };
                this.users.unshift(newUser);
                this.filteredUsers = [...this.users];
                this.renderUsers();
                this.updateStats();
                
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

        // Optimistic update - remove user from list immediately
        this.users = this.users.filter(u => u.id !== userId);
        this.filteredUsers = [...this.users];
        this.renderUsers();
        this.updateStats();

        try {
            const token = localStorage.getItem('access_token');
            const headers = {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            };

            const response = await fetch(`/users/${userId}?backup=${backupOption}`, {
                method: 'DELETE',
                headers: headers
            });

            if (response.ok) {
                const result = await response.json();
                let message = `User "${user.name}" đã được xóa thành công!`;
                if (result.backup_created) {
                    message += `\nĐã tạo backup với ${result.attendance_logs_removed} attendance logs.`;
                }
                this.showSuccess(message);
            } else {
                // Revert optimistic update on error
                this.users.push(user);
                this.filteredUsers = [...this.users];
                this.renderUsers();
                this.updateStats();
                
                const error = await response.json();
                this.showError(`Lỗi: ${error.detail || 'Không thể xóa user'}`);
            }
        } catch (error) {
            // Revert optimistic update on error
            this.users.push(user);
            this.filteredUsers = [...this.users];
            this.renderUsers();
            this.updateStats();
            
            console.error('Error deleting user:', error);
            this.showError('Lỗi kết nối server');
        }
    }

    async showUserDetail(userId) {
        const user = this.users.find(u => u.id === userId);
        if (!user) return;

        const modalElement = document.getElementById('userDetailModal');
        if (!modalElement) {
            console.error('userDetailModal not found');
            return;
        }

        const modal = new bootstrap.Modal(modalElement, {
            backdrop: true,
            keyboard: true,
            focus: true
        });
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
                    <table class="table table-borderless">
                        <tr>
                            <td><strong>ID:</strong></td>
                            <td><code>${user.id}</code></td>
                        </tr>
                        <tr>
                            <td><strong>Name:</strong></td>
                            <td>${user.name}</td>
                        </tr>
                        <tr>
                            <td><strong>Position:</strong></td>
                            <td>${user.position || '-'}</td>
                        </tr>
                        <tr>
                            <td><strong>Model:</strong></td>
                            <td><span class="badge bg-info">${user.model}</span></td>
                        </tr>
                        <tr>
                            <td><strong>Created Date:</strong></td>
                            <td>${createdDate}</td>
                        </tr>
                        <tr>
                            <td><strong>Status:</strong></td>
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
        const addUserForm = document.getElementById('addUserForm');
        const imagePreview = document.getElementById('imagePreview');
        
        if (addUserForm) {
            addUserForm.reset();
        }
        
        if (imagePreview) {
            imagePreview.style.display = 'none';
        }
    }

    editUser(userId) {
        const user = this.users.find(u => u.id === userId);
        if (!user) return;

        // Reset edit form first
        const editModal = document.getElementById('editUserModal');
        if (editModal) {
            const form = editModal.querySelector('form');
            if (form) form.reset();
        }
        
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
        const modalElement = document.getElementById('editUserModal');
        if (!modalElement) {
            console.error('editUserModal not found');
            return;
        }
        
        const modal = new bootstrap.Modal(modalElement, {
            backdrop: true,
            keyboard: true,
            focus: true
        });
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
            let base64 = null;
            if (imageFile) {
                base64 = await this.fileToBase64(imageFile);
                updateData.image_base64 = base64;
            }

            const token = localStorage.getItem('access_token');
            const response = await fetch(`/users/${userId}`, {
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(updateData)
            });

            const data = await response.json();

            if (response.ok) {
                this.showSuccess(`User "${name}" đã được cập nhật thành công!`);
                
                // Optimistic update - update user in list immediately
                const userIndex = this.users.findIndex(u => u.id === userId);
                if (userIndex !== -1) {
                    this.users[userIndex].name = name;
                    this.users[userIndex].position = position;
                    if (base64) {
                        this.users[userIndex].image_base64 = base64;
                    }
                    this.filteredUsers = [...this.users];
                    this.renderUsers();
                }
                
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
            // Compress image before converting to base64
            this.compressImage(file, 0.8, 800, 600).then(compressedFile => {
                const reader = new FileReader();
                reader.readAsDataURL(compressedFile);
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    resolve(base64);
                };
                reader.onerror = error => reject(error);
            }).catch(error => reject(error));
        });
    }

    compressImage(file, quality = 0.8, maxWidth = 800, maxHeight = 600) {
        return new Promise((resolve, reject) => {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            const img = new Image();
            
            img.onload = () => {
                // Calculate new dimensions
                let { width, height } = img;
                
                if (width > height) {
                    if (width > maxWidth) {
                        height = (height * maxWidth) / width;
                        width = maxWidth;
                    }
                } else {
                    if (height > maxHeight) {
                        width = (width * maxHeight) / height;
                        height = maxHeight;
                    }
                }
                
                canvas.width = width;
                canvas.height = height;
                
                // Draw and compress
                ctx.drawImage(img, 0, 0, width, height);
                canvas.toBlob(resolve, 'image/jpeg', quality);
            };
            
            img.onerror = reject;
            img.src = URL.createObjectURL(file);
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
            const token = localStorage.getItem('access_token');
            const response = await fetch('/admin/cleanup-orphaned-data', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
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
            const token = localStorage.getItem('access_token');
            const response = await fetch('/admin/reset-all-data', {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
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
    try {
        window.usersManager = new UsersManager();
    } catch (error) {
        console.error('Error initializing UsersManager:', error);
    }
});
