// ===================================
// WXO Labs - Interactive Features
// ===================================

document.addEventListener('DOMContentLoaded', function() {
    
    // ===================================
    // Smooth Scrolling for Navigation
    // ===================================
    
    const navLinks = document.querySelectorAll('.nav-link');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href');
            
            // Only handle anchor links on the current page
            if (targetId && targetId.startsWith('#') && targetId.length > 1) {
                const targetSection = document.querySelector(targetId);
                
                if (targetSection) {
                    e.preventDefault();
                    
                    const navHeight = document.querySelector('.navbar').offsetHeight;
                    const targetPosition = targetSection.offsetTop - navHeight;
                    
                    window.scrollTo({
                        top: targetPosition,
                        behavior: 'smooth'
                    });
                    
                    // Update active state
                    navLinks.forEach(l => l.classList.remove('active'));
                    this.classList.add('active');
                }
            }
        });
    });
    
    // ===================================
    // Active Navigation on Scroll
    // ===================================
    
    const sections = document.querySelectorAll('section[id]');
    
    function updateActiveNav() {
        const scrollPosition = window.scrollY + 100;
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.offsetHeight;
            const sectionId = section.getAttribute('id');
            
            if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
                navLinks.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === `#${sectionId}`) {
                        link.classList.add('active');
                    }
                });
            }
        });
    }
    
    window.addEventListener('scroll', updateActiveNav);
    
    // ===================================
    // Mobile Menu Toggle
    // ===================================
    
    const mobileMenuBtn = document.getElementById('mobileMenuBtn');
    const navLinksContainer = document.querySelector('.nav-links');
    
    if (mobileMenuBtn) {
        mobileMenuBtn.addEventListener('click', function() {
            navLinksContainer.classList.toggle('active');
            this.classList.toggle('active');
        });
        
        // Close menu when clicking a link
        navLinks.forEach(link => {
            link.addEventListener('click', function() {
                navLinksContainer.classList.remove('active');
                mobileMenuBtn.classList.remove('active');
            });
        });
    }
    
    // ===================================
    // Lab Card Hover Effects
    // ===================================
    
    const labCards = document.querySelectorAll('.lab-card');
    
    labCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-8px)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
    
    // ===================================
    // Scroll Reveal Animation
    // ===================================
    
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe all lab cards and resource cards
    const animatedElements = document.querySelectorAll('.lab-card, .resource-card, .timeline-item');
    
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
    
    // ===================================
    // Progress Indicator
    // ===================================
    
    function updateProgressBar() {
        const windowHeight = window.innerHeight;
        const documentHeight = document.documentElement.scrollHeight - windowHeight;
        const scrolled = window.scrollY;
        const progress = (scrolled / documentHeight) * 100;
        
        let progressBar = document.querySelector('.progress-bar');
        
        if (!progressBar) {
            progressBar = document.createElement('div');
            progressBar.className = 'progress-bar';
            progressBar.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                height: 3px;
                background: linear-gradient(90deg, #0f62fe 0%, #8a3ffc 100%);
                z-index: 9999;
                transition: width 0.1s ease;
            `;
            document.body.appendChild(progressBar);
        }
        
        progressBar.style.width = progress + '%';
    }
    
    window.addEventListener('scroll', updateProgressBar);
    updateProgressBar();
    
    // ===================================
    // Copy Code Button (for future code blocks)
    // ===================================
    
    function addCopyButtons() {
        const codeBlocks = document.querySelectorAll('pre code');
        
        codeBlocks.forEach(block => {
            const button = document.createElement('button');
            button.className = 'copy-code-btn';
            button.textContent = 'Copy';
            button.style.cssText = `
                position: absolute;
                top: 0.5rem;
                right: 0.5rem;
                padding: 0.5rem 1rem;
                background: var(--primary);
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 0.875rem;
                opacity: 0;
                transition: opacity 0.2s;
            `;
            
            const pre = block.parentElement;
            pre.style.position = 'relative';
            pre.appendChild(button);
            
            pre.addEventListener('mouseenter', () => {
                button.style.opacity = '1';
            });
            
            pre.addEventListener('mouseleave', () => {
                button.style.opacity = '0';
            });
            
            button.addEventListener('click', async () => {
                const code = block.textContent;
                await navigator.clipboard.writeText(code);
                button.textContent = 'Copied!';
                setTimeout(() => {
                    button.textContent = 'Copy';
                }, 2000);
            });
        });
    }
    
    addCopyButtons();
    
    // ===================================
    // Search Functionality (placeholder)
    // ===================================
    
    function initSearch() {
        const searchInput = document.getElementById('searchInput');
        
        if (searchInput) {
            searchInput.addEventListener('input', function(e) {
                const searchTerm = e.target.value.toLowerCase();
                const labCards = document.querySelectorAll('.lab-card');
                
                labCards.forEach(card => {
                    const title = card.querySelector('.lab-title').textContent.toLowerCase();
                    const description = card.querySelector('.lab-description').textContent.toLowerCase();
                    const tags = Array.from(card.querySelectorAll('.tag')).map(tag => tag.textContent.toLowerCase()).join(' ');
                    
                    const matches = title.includes(searchTerm) || 
                                  description.includes(searchTerm) || 
                                  tags.includes(searchTerm);
                    
                    if (matches || searchTerm === '') {
                        card.style.display = 'flex';
                    } else {
                        card.style.display = 'none';
                    }
                });
            });
        }
    }
    
    initSearch();
    
    // ===================================
    // Difficulty Filter
    // ===================================
    
    function initDifficultyFilter() {
        const filterButtons = document.querySelectorAll('.filter-btn');
        
        filterButtons.forEach(button => {
            button.addEventListener('click', function() {
                const difficulty = this.dataset.difficulty;
                
                // Update active button
                filterButtons.forEach(btn => btn.classList.remove('active'));
                this.classList.add('active');
                
                // Filter labs
                const labSections = document.querySelectorAll('.labs-section');
                
                if (difficulty === 'all') {
                    labSections.forEach(section => section.style.display = 'block');
                } else {
                    labSections.forEach(section => {
                        const sectionId = section.getAttribute('id');
                        if (sectionId === difficulty) {
                            section.style.display = 'block';
                        } else {
                            section.style.display = 'none';
                        }
                    });
                }
            });
        });
    }
    
    initDifficultyFilter();
    
    // ===================================
    // Stats Counter Animation
    // ===================================
    
    function animateCounter(element, target, duration = 2000) {
        const start = 0;
        const increment = target / (duration / 16);
        let current = start;
        
        const timer = setInterval(() => {
            current += increment;
            if (current >= target) {
                element.textContent = target;
                clearInterval(timer);
            } else {
                element.textContent = Math.floor(current);
            }
        }, 16);
    }
    
    // Animate stats when they come into view
    const statsObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const statNumber = entry.target.querySelector('.stat-number');
                const target = parseInt(statNumber.textContent);
                animateCounter(statNumber, target);
                statsObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });
    
    document.querySelectorAll('.stat-card').forEach(card => {
        statsObserver.observe(card);
    });
    
    // ===================================
    // Keyboard Navigation
    // ===================================
    
    document.addEventListener('keydown', function(e) {
        // Press 'h' to go home
        if (e.key === 'h' && !e.ctrlKey && !e.metaKey) {
            const homeLink = document.querySelector('a[href="#home"]');
            if (homeLink && document.activeElement.tagName !== 'INPUT') {
                homeLink.click();
            }
        }
        
        // Press '/' to focus search (if implemented)
        if (e.key === '/' && !e.ctrlKey && !e.metaKey) {
            const searchInput = document.getElementById('searchInput');
            if (searchInput && document.activeElement !== searchInput) {
                e.preventDefault();
                searchInput.focus();
            }
        }
    });
    
    // ===================================
    // Theme Toggle (optional future feature)
    // ===================================
    
    function initThemeToggle() {
        const themeToggle = document.getElementById('themeToggle');
        
        if (themeToggle) {
            const currentTheme = localStorage.getItem('theme') || 'light';
            document.documentElement.setAttribute('data-theme', currentTheme);
            
            themeToggle.addEventListener('click', function() {
                const theme = document.documentElement.getAttribute('data-theme');
                const newTheme = theme === 'light' ? 'dark' : 'light';
                
                document.documentElement.setAttribute('data-theme', newTheme);
                localStorage.setItem('theme', newTheme);
            });
        }
    }
    
    initThemeToggle();
    
    // ===================================
    // Print Styles
    // ===================================
    
    window.addEventListener('beforeprint', function() {
        // Expand all collapsed sections before printing
        document.querySelectorAll('.lab-card').forEach(card => {
            card.style.pageBreakInside = 'avoid';
        });
    });
    
    // ===================================
    // Analytics (placeholder)
    // ===================================
    
    function trackLabClick(labNumber) {
        // Placeholder for analytics tracking
        console.log(`Lab ${labNumber} clicked`);
        
        // Example: Send to analytics service
        // gtag('event', 'lab_click', { lab_number: labNumber });
    }
    
    // Add click tracking to lab links
    document.querySelectorAll('.lab-link').forEach(link => {
        link.addEventListener('click', function() {
            const labCard = this.closest('.lab-card');
            const labNumber = labCard.dataset.lab;
            trackLabClick(labNumber);
        });
    });
    
    // ===================================
    // Performance Monitoring
    // ===================================
    
    if ('PerformanceObserver' in window) {
        const perfObserver = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
                if (entry.entryType === 'largest-contentful-paint') {
                    console.log('LCP:', entry.renderTime || entry.loadTime);
                }
            }
        });
        
        perfObserver.observe({ entryTypes: ['largest-contentful-paint'] });
    }
    
    // ===================================
    // Accessibility Enhancements
    // ===================================
    
    // Add skip to content link
    const skipLink = document.createElement('a');
    skipLink.href = '#home';
    skipLink.className = 'skip-link';
    skipLink.textContent = 'Skip to content';
    skipLink.style.cssText = `
        position: absolute;
        top: -40px;
        left: 0;
        background: var(--primary);
        color: white;
        padding: 8px;
        text-decoration: none;
        z-index: 10000;
    `;
    skipLink.addEventListener('focus', function() {
        this.style.top = '0';
    });
    skipLink.addEventListener('blur', function() {
        this.style.top = '-40px';
    });
    document.body.insertBefore(skipLink, document.body.firstChild);
    
    // Announce page changes to screen readers
    function announcePageChange(message) {
        const announcement = document.createElement('div');
        announcement.setAttribute('role', 'status');
        announcement.setAttribute('aria-live', 'polite');
        announcement.className = 'sr-only';
        announcement.textContent = message;
        document.body.appendChild(announcement);
        
        setTimeout(() => {
            document.body.removeChild(announcement);
        }, 1000);
    }
    
    // ===================================
    // Console Easter Egg
    // ===================================
    
    console.log('%c🎓 WXO Labs & Tutorial Guide', 'font-size: 24px; font-weight: bold; color: #0f62fe;');
    console.log('%cNo bug too small, no syntax too weird.', 'font-size: 14px; color: #525252; font-style: italic;');
    console.log('%cInterested in contributing? Check out our GitHub repo!', 'font-size: 12px; color: #8a3ffc;');
    console.log('https://github.ibm.com/mvankempen/wxo-testing-scripts');
    
});

// Made with Bob
