/* ============================================
   XYZ Corp Dashboard - JavaScript
   ============================================ */

const API_URL = 'http://localhost:3000/api';

// Initialize dashboard
document.addEventListener('DOMContentLoaded', () => {
    loadProjects();
    loadEmployees();
    loadStatistics();
});

// ============================================
// TAB MANAGEMENT
// ============================================

function showTab(tabName) {
    // Hide all tabs
    const tabs = document.querySelectorAll('.tab-content');
    tabs.forEach(tab => tab.classList.remove('active'));

    // Remove active class from all buttons
    const buttons = document.querySelectorAll('.nav-btn');
    buttons.forEach(btn => btn.classList.remove('active'));

    // Show selected tab
    const selectedTab = document.getElementById(tabName);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }

    // Mark button as active
    event.target.classList.add('active');
}

// ============================================
// PROJECTS MANAGEMENT
// ============================================

async function loadProjects() {
    try {
        const response = await fetch(`${API_URL}/projects`);
        const data = await response.json();

        if (data.success) {
            displayProjects(data.data);
        }
    } catch (error) {
        console.error('Error loading projects:', error);
        showNotification('Error loading projects', 'error');
    }
}

function displayProjects(projects) {
    const tbody = document.querySelector('#projectsTable tbody');
    tbody.innerHTML = '';

    projects.forEach(project => {
        const row = document.createElement('tr');
        const progressPercent = project.progress || 0;

        row.innerHTML = `
            <td>${project.id}</td>
            <td><strong>${project.name}</strong></td>
            <td>${project.team}</td>
            <td>${project.country}</td>
            <td>
                <span class="status-badge ${project.status}">
                    ${project.status}
                </span>
            </td>
            <td>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${progressPercent}%">
                        ${progressPercent}%
                    </div>
                </div>
            </td>
            <td>${formatDate(project.deadline)}</td>
            <td>
                <div class="actions-cell">
                    <button onclick="openEditModal(${project.id})" class="btn btn-warning">Edit</button>
                    <button onclick="deleteProject(${project.id})" class="btn btn-danger">Delete</button>
                </div>
            </td>
        `;

        tbody.appendChild(row);
    });
}

function toggleAddForm() {
    const form = document.getElementById('addProjectForm');
    form.classList.toggle('hidden');

    if (!form.classList.contains('hidden')) {
        form.scrollIntoView({ behavior: 'smooth' });
    }
}

async function addProject(event) {
    event.preventDefault();

    const project = {
        name: document.getElementById('projectName').value,
        team: document.getElementById('projectTeam').value,
        country: document.getElementById('projectCountry').value,
        deadline: document.getElementById('projectDeadline').value,
        progress: parseInt(document.getElementById('projectProgress').value),
        status: document.getElementById('projectStatus').value
    };

    try {
        const response = await fetch(`${API_URL}/projects`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(project)
        });

        const data = await response.json();

        if (data.success) {
            showNotification('Project created successfully!', 'success');
            document.querySelector('form').reset();
            toggleAddForm();
            loadProjects();
        } else {
            showNotification(data.message, 'error');
        }
    } catch (error) {
        console.error('Error creating project:', error);
        showNotification('Error creating project', 'error');
    }
}

function openEditModal(projectId) {
    // Get project data from table
    const rows = document.querySelectorAll('#projectsTable tbody tr');
    let projectData = null;

    rows.forEach(row => {
        if (parseInt(row.cells[0].textContent) === projectId) {
            projectData = {
                id: projectId,
                name: row.cells[1].textContent,
                team: row.cells[2].textContent,
                country: row.cells[3].textContent,
                status: row.cells[4].textContent.trim().toLowerCase(),
                deadline: row.cells[6].textContent
            };
        }
    });

    if (projectData) {
        document.getElementById('editId').value = projectData.id;
        document.getElementById('editName').value = projectData.name;
        document.getElementById('editTeam').value = projectData.team;
        document.getElementById('editCountry').value = projectData.country;
        document.getElementById('editStatus').value = projectData.status;
        // Parse date back to input format
        const dateStr = projectData.deadline.split('/').reverse().join('-');
        document.getElementById('editDeadline').value = dateStr;

        document.getElementById('editModal').classList.remove('hidden');
    }
}

function closeEditModal() {
    document.getElementById('editModal').classList.add('hidden');
}

async function updateProject(event) {
    event.preventDefault();

    const projectId = document.getElementById('editId').value;
    const updates = {
        name: document.getElementById('editName').value,
        team: document.getElementById('editTeam').value,
        country: document.getElementById('editCountry').value,
        status: document.getElementById('editStatus').value,
        deadline: document.getElementById('editDeadline').value,
        progress: parseInt(document.getElementById('editProgress').value) || 0
    };

    try {
        const response = await fetch(`${API_URL}/projects/${projectId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(updates)
        });

        const data = await response.json();

        if (data.success) {
            showNotification('Project updated successfully!', 'success');
            closeEditModal();
            loadProjects();
        } else {
            showNotification(data.message, 'error');
        }
    } catch (error) {
        console.error('Error updating project:', error);
        showNotification('Error updating project', 'error');
    }
}

async function deleteProject(projectId) {
    if (confirm('Are you sure you want to delete this project?')) {
        try {
            const response = await fetch(`${API_URL}/projects/${projectId}`, {
                method: 'DELETE'
            });

            const data = await response.json();

            if (data.success) {
                showNotification('Project deleted successfully!', 'success');
                loadProjects();
            } else {
                showNotification(data.message, 'error');
            }
        } catch (error) {
            console.error('Error deleting project:', error);
            showNotification('Error deleting project', 'error');
        }
    }
}

// ============================================
// EMPLOYEES MANAGEMENT
// ============================================

async function loadEmployees() {
    try {
        const response = await fetch(`${API_URL}/employees`);
        const data = await response.json();

        if (data.success) {
            displayEmployees(data.data);
            document.getElementById('totalEmployees').textContent = data.count;
        }
    } catch (error) {
        console.error('Error loading employees:', error);
        showNotification('Error loading employees', 'error');
    }
}

function displayEmployees(employees) {
    const grid = document.getElementById('employeesGrid');
    grid.innerHTML = '';

    employees.forEach(emp => {
        const card = document.createElement('div');
        card.className = 'employee-card';
        card.innerHTML = `
            <h4>${emp.name}</h4>
            <div class="employee-info">
                <strong>Role:</strong> ${emp.role}
            </div>
            <div class="employee-info">
                <strong>Country:</strong> ${emp.country}
            </div>
            <div class="employee-info">
                <strong>Timezone:</strong> ${emp.timezone}
            </div>
        `;
        grid.appendChild(card);
    });
}

// ============================================
// STATISTICS
// ============================================

async function loadStatistics() {
    try {
        const response = await fetch(`${API_URL}/stats`);
        const data = await response.json();

        if (data.success) {
            displayStatistics(data.summary);
            displayProgressChart(data.breakdown.by_progress);
        }
    } catch (error) {
        console.error('Error loading statistics:', error);
        showNotification('Error loading statistics', 'error');
    }
}

function displayStatistics(summary) {
    document.getElementById('statTotal').textContent = summary.total_projects;
    document.getElementById('statActive').textContent = summary.active;
    document.getElementById('statCompleted').textContent = summary.completed;
    document.getElementById('statPending').textContent = summary.pending;
    document.getElementById('statAvgProgress').textContent = summary.avg_progress + '%';
}

function displayProgressChart(breakdown) {
    const chartDiv = document.getElementById('progressChart');
    chartDiv.innerHTML = '';

    const total = Object.values(breakdown).reduce((a, b) => a + b, 0);

    Object.entries(breakdown).forEach(([range, count]) => {
        const percentage = total > 0 ? (count / total) * 100 : 0;

        const chartRow = document.createElement('div');
        chartRow.className = 'chart-row';
        chartRow.innerHTML = `
            <div class="chart-label">${range}</div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${percentage}%; background: linear-gradient(90deg, #3b82f6, #60a5fa);">
                </div>
            </div>
            <div class="chart-percentage">${count} projects</div>
        `;
        chartDiv.appendChild(chartRow);
    });
}

// ============================================
// UTILITY FUNCTIONS
// ============================================

function formatDate(dateStr) {
    try {
        const date = new Date(dateStr);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    } catch {
        return dateStr;
    }
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
        color: white;
        border-radius: 6px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        z-index: 1000;
        animation: slideIn 0.3s ease;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);

    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Add animation styles
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(400px);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(400px);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// ============================================
// Auto-refresh data every 30 seconds
// ============================================

setInterval(() => {
    if (document.getElementById('projects').classList.contains('active')) {
        loadProjects();
    }
    if (document.getElementById('employees').classList.contains('active')) {
        loadEmployees();
    }
    if (document.getElementById('stats').classList.contains('active')) {
        loadStatistics();
    }
}, 30000);
