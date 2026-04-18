// Sentralyx Trading Terminal - Main JavaScript
// Dynamic Header Loading System

document.addEventListener('DOMContentLoaded', function() {
    loadHeader();
    setActiveNavigation();
});

// Load header content dynamically
async function loadHeader() {
    const headerElement = document.getElementById('main-header');
    
    if (!headerElement) {
        console.error('Header element with id "main-header" not found');
        return;
    }

    try {
        // Determine the correct path to header.html based on current page depth
        const currentPath = window.location.pathname;
        const pathDepth = currentPath.split('/').length - 1;
        const relativePath = '../'.repeat(pathDepth) + 'assets/includes/header.html';
        
        const response = await fetch(relativePath);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const headerContent = await response.text();
        headerElement.innerHTML = headerContent;
        
        // Re-initialize Bootstrap components after header load
        initializeBootstrap();
        
        // Set active navigation
        setActiveNavigation();
        
    } catch (error) {
        console.error('Error loading header:', error);
        // Fallback: create a simple header
        headerElement.innerHTML = `
            <nav class="navbar navbar-expand-lg sticky-top" style="background: rgba(11, 17, 27, 0.95); backdrop-filter: blur(10px); border-bottom: 1px solid var(--border-color);">
                <div class="container">
                    <a class="navbar-brand d-flex align-items-center" href="/">
                        <img src="/sentralyx_logo_master.svg" alt="Sentralyx Logo" style="height: 40px; margin-right: 10px;">
                        <span class="fw-bold text-white">SENTRALYX</span>
                    </a>
                </div>
            </nav>
        `;
    }
}

// Initialize Bootstrap components after dynamic content load
function initializeBootstrap() {
    // Initialize dropdowns
    const dropdownElements = document.querySelectorAll('[data-bs-toggle="dropdown"]');
    dropdownElements.forEach(element => {
        new bootstrap.Dropdown(element);
    });
    
    // Initialize tooltips if any
    const tooltipElements = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    tooltipElements.forEach(element => {
        new bootstrap.Tooltip(element);
    });
}

// Set active navigation based on current page
function setActiveNavigation() {
    const currentPath = window.location.pathname;
    const currentPage = currentPath.split('/').pop() || 'index.html';
    
    // Remove all active classes
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => link.classList.remove('active'));
    
    // Add active class to current page link
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href && href.includes(currentPage)) {
            link.classList.add('active');
        }
    });
    
    // Special case for home page
    if (currentPage === 'index.html' && currentPath.endsWith('/site/')) {
        navLinks.forEach(link => {
            if (link.textContent.trim() === 'Ana Sayfa') {
                link.classList.add('active');
            }
        });
    }
}

// Utility function to update navigation when page changes
function updateNavigation(pageName) {
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => link.classList.remove('active'));
    
    navLinks.forEach(link => {
        if (link.textContent.trim().toLowerCase() === pageName.toLowerCase()) {
            link.classList.add('active');
        }
    });
}

// Handle mobile menu toggle
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('navbar-toggler') || e.target.closest('.navbar-toggler')) {
        const navbarCollapse = document.querySelector('.navbar-collapse');
        if (navbarCollapse) {
            navbarCollapse.classList.toggle('show');
            // Add animation class for smooth transition
            navbarCollapse.style.transition = 'all 0.3s ease';
        }
    }
});

// Close mobile menu when clicking outside
document.addEventListener('click', function(e) {
    const navbar = document.querySelector('.navbar');
    const navbarCollapse = document.querySelector('.navbar-collapse');
    const navbarToggler = document.querySelector('.navbar-toggler');
    
    if (navbarCollapse && navbarCollapse.classList.contains('show') && 
        !navbar.contains(e.target) && 
        !e.target.closest('.navbar-toggler') &&
        !e.target.closest('.navbar-collapse')) {
        navbarCollapse.classList.remove('show');
    }
});

// Close mobile menu when clicking on a nav link (for better UX)
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('nav-link') && window.innerWidth < 992) {
        const navbarCollapse = document.querySelector('.navbar-collapse');
        if (navbarCollapse && navbarCollapse.classList.contains('show')) {
            setTimeout(() => {
                navbarCollapse.classList.remove('show');
            }, 300); // Small delay to allow navigation to start
        }
    }
});

// Handle dropdown menus on mobile
document.addEventListener('click', function(e) {
    if (window.innerWidth < 992) {
        const dropdownToggle = e.target.closest('.dropdown-toggle');
        if (dropdownToggle) {
            e.preventDefault();
            const dropdownMenu = dropdownToggle.nextElementSibling;
            if (dropdownMenu && dropdownMenu.classList.contains('dropdown-menu')) {
                // Toggle dropdown visibility
                dropdownMenu.classList.toggle('show');
                dropdownMenu.style.position = 'static';
                dropdownMenu.style.transform = 'none';
                dropdownMenu.style.boxShadow = 'none';
                dropdownMenu.style.border = '1px solid var(--border-color)';
                dropdownMenu.style.marginTop = '10px';
                dropdownMenu.style.width = '100%';
            }
        }
    }
});

// Add mobile-specific CSS improvements
function addMobileStyles() {
    if (window.innerWidth < 992) {
        const style = document.createElement('style');
        style.textContent = `
            .navbar-collapse {
                background: var(--panel-dark) !important;
                border: 1px solid var(--border-color) !important;
                border-radius: 8px !important;
                margin-top: 10px !important;
                padding: 15px !important;
            }
            
            .navbar-nav {
                margin: 0 !important;
            }
            
            .nav-link {
                padding: 12px 15px !important;
                margin: 5px 0 !important;
                border-radius: 6px !important;
                transition: all 0.2s ease !important;
            }
            
            .nav-link:hover {
                background: rgba(52, 152, 219, 0.1) !important;
            }
            
            .dropdown-menu {
                background: rgba(42, 49, 66, 0.5) !important;
                border: 1px solid var(--border-color) !important;
                border-radius: 6px !important;
                margin: 10px 0 !important;
                padding: 10px !important;
            }
            
            .dropdown-item {
                padding: 10px 15px !important;
                margin: 2px 0 !important;
                border-radius: 4px !important;
            }
            
            .dropdown-item:hover {
                background: rgba(52, 152, 219, 0.2) !important;
            }
            
            .navbar-toggler {
                padding: 8px 12px !important;
                border: 1px solid var(--border-color) !important;
                border-radius: 6px !important;
            }
            
            .navbar-toggler:focus {
                box-shadow: 0 0 10px rgba(52, 152, 219, 0.3) !important;
            }
        `;
        
        // Only add the style if it doesn't exist
        if (!document.getElementById('mobile-styles')) {
            style.id = 'mobile-styles';
            document.head.appendChild(style);
        }
    }
}

// Initialize mobile styles and handle resize
window.addEventListener('load', addMobileStyles);
window.addEventListener('resize', function() {
    addMobileStyles();
    
    // Reset dropdown styles on desktop
    if (window.innerWidth >= 992) {
        const dropdownMenus = document.querySelectorAll('.dropdown-menu');
        dropdownMenus.forEach(menu => {
            menu.style.position = '';
            menu.style.transform = '';
            menu.style.boxShadow = '';
            menu.style.border = '';
            menu.style.marginTop = '';
            menu.style.width = '';
        });
    }
});
