// Work Hours Management JavaScript

class WorkHoursManager {
    constructor() {
        this.workHours = [];
        this.summary = [];
        this.currentView = 'daily';
        this.userHoursChart = null;
        this.trendChart = null;
        this.employees = [];
        this.selectedEmployee = '';
        this.selectedDay = 'today';
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadEmployees();
        this.loadData();
    }

    setupEventListeners() {
        // Employee filter
        const employeeFilter = document.getElementById('employeeFilter');
        if (employeeFilter) {
            employeeFilter.addEventListener('change', () => {
                this.selectedEmployee = employeeFilter.value;
                this.loadData();
            });
        }

        // Day select
        const daySelect = document.getElementById('daySelect');
        if (daySelect) {
            daySelect.addEventListener('change', () => {
                this.selectedDay = daySelect.value;
                this.handleDaySelect(daySelect.value);
            });
        }

        // Custom date input
        const customDate = document.getElementById('customDate');
        if (customDate) {
            customDate.addEventListener('change', () => {
                this.loadData();
            });
        }

        // View mode toggle
        const dailyView = document.getElementById('dailyView');
        const summaryView = document.getElementById('summaryView');
        if (dailyView) {
            dailyView.addEventListener('change', () => {
                this.currentView = 'daily';
                this.loadData();
            });
        }
        if (summaryView) {
            summaryView.addEventListener('change', () => {
                this.currentView = 'summary';
                this.loadData();
            });
        }
    }

    async loadEmployees() {
        try {
            const token = localStorage.getItem('access_token');
            const response = await fetch('/users', {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                signal: AbortSignal.timeout(10000) // 10 second timeout
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            this.employees = data.users || [];
            this.populateEmployeeFilter();
        } catch (error) {
            console.error('Error loading employees:', error);
            // Fallback: create employee from work hours data
            this.createEmployeeFromWorkHours();
        }
    }

    populateEmployeeFilter() {
        const employeeFilter = document.getElementById('employeeFilter');
        if (employeeFilter) {
            employeeFilter.innerHTML = '<option value="">All Employees</option>';
            this.employees.forEach(employee => {
                const option = document.createElement('option');
                option.value = employee.id;
                option.textContent = employee.name;
                employeeFilter.appendChild(option);
            });
        }
    }

    createEmployeeFromWorkHours() {
        // Create employee list from work hours data as fallback
        const uniqueEmployees = new Map();
        
        // Add employees from current work hours data
        this.workHours.forEach(item => {
            if (item.user_id && item.name) {
                uniqueEmployees.set(item.user_id, {
                    id: item.user_id,
                    name: item.name
                });
            }
        });
        
        // Add employees from summary data
        this.summary.forEach(item => {
            if (item.user_id && item.name) {
                uniqueEmployees.set(item.user_id, {
                    id: item.user_id,
                    name: item.name
                });
            }
        });
        
        this.employees = Array.from(uniqueEmployees.values());
        this.populateEmployeeFilter();
    }

    handleDaySelect(value) {
        const customDate = document.getElementById('customDate');
        
        if (value === 'custom') {
            // Show custom date input
            if (customDate) {
                customDate.style.display = 'block';
            }
            return;
        } else {
            // Hide custom date input
            if (customDate) {
                customDate.style.display = 'none';
            }
        }
        
        this.loadData();
    }

    getSelectedDate() {
        const customDate = document.getElementById('customDate');
        
        if (this.selectedDay === 'custom' && customDate && customDate.value) {
            return customDate.value;
        }
        
        const today = new Date();
        let selectedDate;
        
        switch (this.selectedDay) {
            case 'today':
                selectedDate = new Date(today);
                break;
            case 'yesterday':
                selectedDate = new Date(today.getTime() - 24 * 60 * 60 * 1000);
                break;
            case 'thisWeek':
                // Get Monday of current week
                const dayOfWeek = today.getDay();
                const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek; // Sunday = 0, Monday = 1
                selectedDate = new Date(today.getTime() + mondayOffset * 24 * 60 * 60 * 1000);
                break;
            case 'lastWeek':
                // Get Monday of last week
                const lastWeekMonday = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
                const lastWeekDayOfWeek = lastWeekMonday.getDay();
                const lastWeekMondayOffset = lastWeekDayOfWeek === 0 ? -6 : 1 - lastWeekDayOfWeek;
                selectedDate = new Date(lastWeekMonday.getTime() + lastWeekMondayOffset * 24 * 60 * 60 * 1000);
                break;
            case 'thisMonth':
                selectedDate = new Date(today.getFullYear(), today.getMonth(), 1);
                break;
            case 'lastMonth':
                selectedDate = new Date(today.getFullYear(), today.getMonth() - 1, 1);
                break;
            default:
                selectedDate = new Date(today);
        }
        
        return selectedDate.toISOString().split('T')[0];
    }

    async loadData() {
        // Destroy existing charts before loading new data
        this.destroyAllCharts();
        
        // Wait a bit to ensure charts are fully destroyed
        await new Promise(resolve => setTimeout(resolve, 100));
        
        if (this.currentView === 'daily') {
            await this.loadDailyData();
        } else {
            await this.loadSummaryData();
        }
    }

    async loadDailyData() {
        const selectedDate = this.getSelectedDate();
        
        if (!selectedDate) return;

        try {
            // Show loading state
            this.showLoadingState();
            
            // Build API URL with filters
            let apiUrl = `/attendance/work-hours?date=${selectedDate}`;
            if (this.selectedEmployee) {
                apiUrl += `&user_id=${this.selectedEmployee}`;
            }
            const response = await fetch(apiUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
                // Add timeout and better error handling
                signal: AbortSignal.timeout(10000) // 10 second timeout
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            
            // Process and validate data
            this.workHours = this.processWorkHoursData(data.users || []);
            this.updateStats();
            this.renderTable();
            this.updateCharts();
            
            // Update employee filter after loading data
            if (this.employees.length === 0) {
                this.createEmployeeFromWorkHours();
            }
            
            // Show success message if no data
            if (this.workHours.length === 0) {
                this.showInfo('No work hours data for selected date');
            }
        } catch (error) {
            console.error('Error loading daily data:', error);
            this.showError('Error loading work hours data: ' + error.message);
            this.showEmptyState();
        }
    }

    async loadSummaryData() {
        const selectedDate = this.getSelectedDate();
        
        if (!selectedDate) return;

        try {
            // For summary view, use the selected date as both start and end
            let apiUrl = `/attendance/work-hours/summary?start_date=${selectedDate}&end_date=${selectedDate}`;
            if (this.selectedEmployee) {
                apiUrl += `&user_id=${this.selectedEmployee}`;
            }
            
            const response = await fetch(apiUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
                signal: AbortSignal.timeout(10000) // 10 second timeout
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            
            this.summary = data.summary || [];
            this.updateStats();
            this.renderTable();
            this.updateCharts();
        } catch (error) {
            this.showError('Error loading summary data');
        }
    }

    processWorkHoursData(rawData) {
        if (!Array.isArray(rawData)) {
            console.warn('Invalid data format:', rawData);
            return [];
        }

        return rawData.map(item => {
            // Validate and fix timestamp issues
            const now = Math.floor(Date.now() / 1000);
            const currentYear = new Date().getFullYear();
            
            // Fix future timestamps (likely from test data)
            let firstCheckIn = item.first_check_in;
            let lastCheckOut = item.last_check_out;
            
            if (firstCheckIn > now) {
                // If timestamp is in the future, adjust to current time
                firstCheckIn = now - (item.work_hours * 3600); // Subtract work hours
            }
            
            if (lastCheckOut > now) {
                lastCheckOut = now;
            }
            
            // Ensure work_hours is reasonable
            let workHours = parseFloat(item.work_hours) || 0;
            if (workHours < 0) workHours = 0;
            if (workHours > 24) workHours = 24; // Max 24 hours per day
            
            // Use real avatar if available, otherwise generate from initials
            let avatar = item.avatar;
            if (!avatar && item.name) {
                // Generate avatar from user name using UI Avatars service
                const initials = item.name.split(' ').map(n => n.charAt(0)).join('').toUpperCase();
                avatar = `https://ui-avatars.com/api/?name=${encodeURIComponent(initials)}&background=007bff&color=fff&size=40&bold=true`;
            }
            
            return {
                ...item,
                first_check_in: firstCheckIn,
                last_check_out: lastCheckOut,
                work_hours: workHours,
                check_ins: parseInt(item.check_ins) || 0,
                avatar: avatar
            };
        });
    }

    showLoadingState() {
        const tbody = document.getElementById('workHoursTableBody');
        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center">
                        <div class="spinner-border text-primary" role="status">
                            <span class="visually-hidden">Loading...</span>
                        </div>
                        <p class="mt-2 text-muted">Đang tải dữ liệu...</p>
                    </td>
                </tr>
            `;
        }
    }

    showEmptyState() {
        const tbody = document.getElementById('workHoursTableBody');
        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-muted">
                        <i class="fas fa-inbox fa-2x mb-2"></i>
                        <p>Không có dữ liệu giờ làm</p>
                    </td>
                </tr>
            `;
        }
    }

    updateStats() {
        const data = this.currentView === 'daily' ? this.workHours : this.summary;
        
        const totalWorkers = data.length;
        const totalHours = data.reduce((sum, item) => sum + (item.work_hours || 0), 0);
        const activeWorkers = data.filter(item => (item.work_hours || 0) > 0).length;
        const avgHours = totalWorkers > 0 ? (totalHours / totalWorkers).toFixed(1) : 0;

        // Update stats elements with null checks
        const totalWorkersEl = document.getElementById('total-workers');
        const totalHoursEl = document.getElementById('total-hours');
        const avgHoursEl = document.getElementById('avg-hours');
        const activeWorkersEl = document.getElementById('active-workers');
        
        if (totalWorkersEl) totalWorkersEl.textContent = totalWorkers;
        if (totalHoursEl) totalHoursEl.textContent = `${totalHours.toFixed(1)}h`;
        if (avgHoursEl) avgHoursEl.textContent = `${avgHours}h`;
        if (activeWorkersEl) activeWorkersEl.textContent = activeWorkers;
    }

    renderTable() {
        // This method is no longer needed - using updateTableDisplay() instead
        this.updateTableDisplay();
    }

    createWorkHoursRow(item) {
        // Method removed - using updateTableDisplay() instead
    }

    updateCharts() {
        // Charts removed - using table display instead
        this.updateTableDisplay();
    }

    updateTableDisplay() {
        const data = this.currentView === 'daily' ? this.workHours : this.summary;
        const tableContainer = document.getElementById('workHoursTable');
        
        if (!tableContainer) return;
        
        if (data.length === 0) {
            tableContainer.innerHTML = `
                <div class="text-center py-4">
                    <i class="fas fa-chart-bar fa-3x text-muted mb-3"></i>
                    <h5 class="text-muted">No Data</h5>
                    <p class="text-muted">No work hours data for this time period</p>
                </div>
            `;
            return;
        }
        
        let tableHTML = `
            <div class="table-responsive">
                <table class="table table-hover">
                    <thead class="table-dark">
                        <tr>
                            <th>Employee</th>
                            <th>Date</th>
                            <th>First Check In</th>
                            <th>Last Check Out</th>
                            <th>Total Hours</th>
                            <th>Check-ins</th>
                        </tr>
                    </thead>
                    <tbody>
        `;
        
        data.forEach(item => {
            const firstCheckIn = item.first_check_in ? new Date(item.first_check_in * 1000).toLocaleTimeString('en-US', {hour12: false}) : 'N/A';
            const lastCheckOut = item.last_check_out ? new Date(item.last_check_out * 1000).toLocaleTimeString('en-US', {hour12: false}) : 'N/A';
            const workHours = item.work_hours ? item.work_hours.toFixed(1) + 'h' : '0h';
            const checkIns = item.check_ins || 0;
            // Use first_check_in timestamp to get the date, fallback to date field
            const date = item.first_check_in ? 
                new Date(item.first_check_in * 1000).toLocaleDateString('en-US') : 
                (item.date ? new Date(item.date).toLocaleDateString('en-US') : 'N/A');
            
            tableHTML += `
                <tr>
                    <td>
                        <div class="d-flex align-items-center">
                            <div class="me-2" style="width: 40px; height: 40px;">
                                ${item.avatar ? 
                                    `<img src="${item.avatar}" alt="${item.name}" class="rounded-circle" style="width: 100%; height: 100%; object-fit: cover; border: 2px solid #dee2e6;">` :
                                    `<div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center" style="width: 100%; height: 100%; font-size: 16px; font-weight: bold;">${item.name ? item.name.split(' ').map(n => n.charAt(0)).join('').toUpperCase() : 'U'}</div>`
                                }
                            </div>
                            <div>
                                <div class="fw-bold">${item.name || 'Unknown'}</div>
                                <small class="text-muted">ID: ${item.user_id ? item.user_id.substring(0, 8) + '...' : 'N/A'}</small>
                            </div>
                        </div>
                    </td>
                    <td>${date}</td>
                    <td>${firstCheckIn}</td>
                    <td>${lastCheckOut}</td>
                    <td>
                        <span class="badge bg-success">${workHours}</span>
                    </td>
                    <td>
                        <span class="badge bg-info">${checkIns}</span>
                    </td>
                </tr>
            `;
        });
        
        tableHTML += `
                    </tbody>
                </table>
            </div>
        `;
        
        tableContainer.innerHTML = tableHTML;
    }

    destroyAllCharts() {
        // Charts removed - no need to destroy anything
    }

    updateUserHoursChart() {
        // Chart removed - using table display instead
    }

    updateTrendChart() {
        // Chart removed - using table display instead
    }

    exportData() {
        const data = this.currentView === 'daily' ? this.workHours : this.summary;
        
        if (data.length === 0) {
            this.showError('No data to export');
            return;
        }

        const headers = ['Employee', 'Date', 'First Check In', 'Last Check Out', 'Total Hours', 'Check-ins'];
        const csvContent = [
            headers.join(','),
            ...data.map(item => {
                const firstCheckIn = new Date(item.first_check_in * 1000).toLocaleTimeString('en-US');
                const lastCheckOut = new Date(item.last_check_out * 1000).toLocaleTimeString('en-US');
                const date = new Date(item.first_check_in * 1000).toLocaleDateString('en-US');
                
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

    showInfo(message) {
        if (window.faceLogApp) {
            window.faceLogApp.showNotification(message, 'info');
        } else {
        }
    }

    refreshData() {
        this.loadData();
    }
}

// Initialize work hours manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.workHoursManager = new WorkHoursManager();
});
