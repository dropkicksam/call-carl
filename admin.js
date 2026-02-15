// Admin Panel JavaScript
// Handles authentication and signups display

// Initialize Supabase client
const supabaseUrl = CONFIG.SUPABASE_URL;
const supabaseKey = CONFIG.SUPABASE_ANON_KEY;
const adminPassword = CONFIG.ADMIN_PASSWORD;

if (!supabaseUrl || !supabaseKey) {
    console.error('Supabase configuration missing. Please set SUPABASE_URL and SUPABASE_ANON_KEY in config.js');
}

if (!adminPassword) {
    console.error('Admin password not set. Please set ADMIN_PASSWORD in config.js');
}

let supabase = null;
if (supabaseUrl && supabaseKey && typeof window.supabase !== 'undefined') {
    try {
        supabase = window.supabase.createClient(supabaseUrl, supabaseKey);
    } catch (error) {
        console.error('Error creating Supabase client:', error);
    }
} else {
    if (!supabaseUrl || !supabaseKey) {
        console.error('Supabase URL or key missing in config.js');
    }
    if (typeof window.supabase === 'undefined') {
        console.error('Supabase library not loaded. Check that the script tag is present in admin.html');
    }
}

// Session management
const SESSION_KEY = 'call_carl_admin_session';
const SESSION_DURATION = 8 * 60 * 60 * 1000; // 8 hours

// Check if user is already logged in
function checkAuth() {
    const session = localStorage.getItem(SESSION_KEY);
    if (session) {
        const sessionData = JSON.parse(session);
        const now = Date.now();
        if (now - sessionData.timestamp < SESSION_DURATION) {
            showDashboard();
            return true;
        } else {
            localStorage.removeItem(SESSION_KEY);
        }
    }
    return false;
}

// Show login screen
function showLogin() {
    document.getElementById('login-screen').style.display = 'block';
    document.getElementById('admin-dashboard').style.display = 'none';
    document.getElementById('admin-password').value = '';
}

// Show dashboard
function showDashboard() {
    document.getElementById('login-screen').style.display = 'none';
    document.getElementById('admin-dashboard').style.display = 'block';
    loadSignups();
}

// Initialize event listeners when DOM is ready
function initializeEventListeners() {
    // Handle login
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        loginForm.addEventListener('submit', function(e) {
            e.preventDefault();
            const password = document.getElementById('admin-password').value;
            const messageDiv = document.getElementById('login-message');
            
            if (!adminPassword) {
                messageDiv.textContent = 'Admin password not configured. Please set ADMIN_PASSWORD in config.js';
                messageDiv.style.color = '#ff6b6b';
                return;
            }
            
            if (password === adminPassword) {
                // Store session
                localStorage.setItem(SESSION_KEY, JSON.stringify({
                    timestamp: Date.now()
                }));
                showDashboard();
            } else {
                messageDiv.textContent = 'Incorrect password. Please try again.';
                messageDiv.style.color = '#ff6b6b';
                document.getElementById('admin-password').value = '';
            }
        });
    }

    // Handle logout
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', function() {
            localStorage.removeItem(SESSION_KEY);
            showLogin();
        });
    }

    // Refresh button
    const refreshBtn = document.getElementById('refresh-btn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', function() {
            const searchInput = document.getElementById('search-input');
            if (searchInput) {
                searchInput.value = '';
            }
            loadSignups();
        });
    }

    // Search functionality
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        let searchTimeout;
        searchInput.addEventListener('input', function(e) {
            clearTimeout(searchTimeout);
            const searchTerm = e.target.value.trim();

            searchTimeout = setTimeout(() => {
                loadSignups(searchTerm);
            }, 300); // Debounce search
        });
    }
}

// Load signups from Supabase
async function loadSignups(searchTerm = '') {
    if (!supabase) {
        document.getElementById('signups-tbody').innerHTML = 
            '<tr><td colspan="5" class="error">Supabase not configured. Please check config.js</td></tr>';
        return;
    }
    
    try {
        let query = supabase
            .from('waitlist_signups')
            .select('*')
            .order('created_at', { ascending: false });
        
        // Apply search filter if provided
        if (searchTerm) {
            query = query.or(`first_name.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%,zip_code.ilike.%${searchTerm}%`);
        }
        
        const { data, error } = await query;
        
        if (error) {
            throw error;
        }
        
        displaySignups(data || []);
        updateStats(data || []);
    } catch (error) {
        console.error('Error loading signups:', error);
        document.getElementById('signups-tbody').innerHTML = 
            '<tr><td colspan="5" class="error">Error loading signups. Please check console for details.</td></tr>';
    }
}

// Display signups in table
function displaySignups(signups) {
    const tbody = document.getElementById('signups-tbody');
    const noSignups = document.getElementById('no-signups');
    
    if (signups.length === 0) {
        tbody.innerHTML = '';
        noSignups.style.display = 'block';
        return;
    }
    
    noSignups.style.display = 'none';
    
    tbody.innerHTML = signups.map(signup => {
        const date = new Date(signup.created_at);
        const formattedDate = date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        return `
            <tr>
                <td>${formattedDate}</td>
                <td>${escapeHtml(signup.first_name)}</td>
                <td><a href="mailto:${escapeHtml(signup.email)}">${escapeHtml(signup.email)}</a></td>
                <td><a href="tel:${escapeHtml(signup.phone)}">${escapeHtml(signup.phone)}</a></td>
                <td>${escapeHtml(signup.zip_code)}</td>
            </tr>
        `;
    }).join('');
}

// Update statistics
function updateStats(signups) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    
    const todaySignups = signups.filter(s => new Date(s.created_at) >= today).length;
    const weekSignups = signups.filter(s => new Date(s.created_at) >= weekAgo).length;
    
    document.getElementById('total-signups').textContent = signups.length;
    document.getElementById('today-signups').textContent = todaySignups;
    document.getElementById('week-signups').textContent = weekSignups;
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Initialize on page load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        initializeEventListeners();
        if (!checkAuth()) {
            showLogin();
        }
    });
} else {
    // DOM already loaded
    initializeEventListeners();
    if (!checkAuth()) {
        showLogin();
    }
}
