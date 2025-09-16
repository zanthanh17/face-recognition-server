// Dashboard JavaScript functionality

function formatTime(timestamp) {
    if (!timestamp) return '-';
    const date = new Date(timestamp * 1000);
    return date.toLocaleString('en-US');
}

async function loadData() {
    const content = document.getElementById('data-content');
    content.innerHTML = '<div class="spinner-border"></div>';
    
    try {
        const response = await fetch('/attendance/get?limit=10');
        const data = await response.json();
        
        if (data.items && data.items.length > 0) {
            content.innerHTML = data.items.map(item => `
                <div class="border rounded p-3 mb-2">
                    <p><strong>Time:</strong> <span class="time-badge">${formatTime(item.ts)}</span></p>
                    <p><strong>User:</strong> ${item.name || 'Unknown'}</p>
                    <p><strong>Status:</strong> 
                        <span class="badge ${item.matched ? 'bg-success' : 'bg-danger'}">
                            ${item.matched ? 'Success' : 'Failed'}
                        </span>
                    </p>
                </div>
            `).join('');
        } else {
            content.innerHTML = '<p class="text-muted">No data available</p>';
        }
    } catch(e) {
        content.innerHTML = '<div class="alert alert-danger">Error: ' + e.message + '</div>';
    }
}

// Load data when page loads
document.addEventListener('DOMContentLoaded', loadData);

