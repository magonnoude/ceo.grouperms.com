/**
 * RMS International Group - Main JavaScript
 * Version: 2.0.0
 * Last Updated: March 2026
 */

document.addEventListener('DOMContentLoaded', async () => {

    // ============================================
    // 1. DYNAMIC HEADER & FOOTER LOADING
    // ============================================
    
    // Detect if we're in a subdirectory (articles/)
    const isSubPage = window.location.pathname.includes('/articles/');
    const basePath = isSubPage ? '../' : '';

    async function loadComponent(selector, filePath) {
        const element = document.querySelector(selector);
        if (!element) return;
        
        try {
            const response = await fetch(basePath + filePath);
            if (response.ok) {
                element.innerHTML = await response.text();
                
                // Fix all relative links in header/footer when in subdirectory
                if (isSubPage) {
                    element.querySelectorAll('a[href]').forEach(a => {
                        const href = a.getAttribute('href');
                        if (href && !href.startsWith('http') && !href.startsWith('#') && !href.startsWith('mailto') && !href.startsWith('tel') && !href.startsWith('/') && !href.startsWith('../')) {
                            a.setAttribute('href', '../' + href);
                        }
                    });
                    element.querySelectorAll('img[src]').forEach(img => {
                        const src = img.getAttribute('src');
                        if (src && !src.startsWith('http') && !src.startsWith('/') && !src.startsWith('../')) {
                            img.setAttribute('src', '../' + src);
                        }
                    });
                }

                if (selector === 'header') {
                    setActiveNavLink();
                }
                if (selector === 'footer') {
                    initNewsletterForm();
                }
            } else {
                console.error(`Failed to load ${filePath}: ${response.status}`);
            }
        } catch (error) {
            console.error(`Error loading ${selector}:`, error);
        }
    }

    function setActiveNavLink() {
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        const navLinks = document.querySelectorAll('nav ul li a');
        
        navLinks.forEach(link => {
            const href = link.getAttribute('href');
            if (href === currentPage || (currentPage === '' && href === 'index.html')) {
                link.classList.add('active');
            }
        });
    }

    await Promise.all([
        loadComponent('header', 'header.html'),
        loadComponent('footer', 'footer.html')
    ]);

    // ============================================
    // 2. MOBILE MENU TOGGLE
    // ============================================
    
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    if (mobileMenuBtn) {
        mobileMenuBtn.addEventListener('click', () => {
            const navMenu = document.querySelector('nav ul');
            if (navMenu) navMenu.classList.toggle('show');
        });
    }

    // ============================================
    // 3. LANGUAGE SWITCHER (with flags)
    // ============================================
    
    const langButtons = document.querySelectorAll('.lang-btn');
    const htmlElement = document.documentElement;

    function switchLanguage(lang) {
        htmlElement.lang = lang;
        langButtons.forEach(btn => btn.classList.remove('active'));
        const activeBtn = document.querySelector(`.lang-btn[data-lang="${lang}"]`);
        if (activeBtn) activeBtn.classList.add('active');
        
        document.querySelectorAll('.lang-fr, .lang-en').forEach(el => {
            el.style.display = el.classList.contains(`lang-${lang}`) ? '' : 'none';
        });
        
        localStorage.setItem('preferred-language', lang);
    }

    const savedLang = localStorage.getItem('preferred-language') || 'fr';
    if (langButtons.length) switchLanguage(savedLang);

    langButtons.forEach(btn => {
        btn.addEventListener('click', () => switchLanguage(btn.dataset.lang));
    });

     
   // ============================================
    // 4. CONTACT FORM HANDLER - reCAPTCHA v3
    // ============================================

const contactForm = document.getElementById('contactForm');
if (contactForm) {
    contactForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const submitBtn = contactForm.querySelector('button[type="submit"]');
        const originalText = submitBtn.textContent;
        const statusDiv = document.getElementById('formStatus');
        
        submitBtn.disabled = true;
        submitBtn.textContent = 'Envoi en cours...';
        
        // Get reCAPTCHA v3 token
        if (typeof grecaptcha !== 'undefined') {
            try {
                const token = await grecaptcha.execute('6LePUZ0sAAAAAK2QgwgDvTI7q0ZoATGnsDRwb3xy', { action: 'submit' });
                document.getElementById('recaptchaToken').value = token;
            } catch (error) {
                console.error('reCAPTCHA error:', error);
            }
        }

        const formData = {
            name: document.getElementById('name')?.value || '',
            email: document.getElementById('email')?.value || '',
            company: document.getElementById('company')?.value || '',
            interest: document.getElementById('interest')?.value || '',
            message: document.getElementById('message')?.value || '',
            recaptcha_token: document.getElementById('recaptchaToken')?.value || '',
            timestamp: new Date().toISOString(),
            page: window.location.pathname
        };

        try {
            const response = await fetch('https://e9hpqlfmz2.execute-api.us-east-1.amazonaws.com/prod/contact/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });

            const result = await response.json();
            
            if (response.ok && result.success) {
                if (statusDiv) {
                    statusDiv.style.display = 'block';
                    statusDiv.style.color = '#28a745';
                    statusDiv.textContent = 'Message envoyé avec succès ! Nous vous répondrons dans les 24h. / Message sent successfully! We will respond within 24 hours.';
                    setTimeout(() => { statusDiv.style.display = 'none'; }, 5000);
                }
                contactForm.reset();
                
                // Track in GA
                if (typeof gtag !== 'undefined') {
                    gtag('event', 'contact_form_submit', {
                        'event_category': 'engagement',
                        'event_label': formData.interest || 'general'
                    });
                }
            } else if (result.score && result.score < 0.5) {
                if (statusDiv) {
                    statusDiv.style.display = 'block';
                    statusDiv.style.color = '#f5a623';
                    statusDiv.textContent = 'Votre message a été marqué comme suspect. Veuillez nous contacter directement par email. / Your message was flagged. Please contact us directly by email.';
                }
            } else {
                throw new Error('Server error');
            }
        } catch (error) {
            console.error('Contact form error:', error);
            // Fallback: open email client
            const emailBody = `Name: ${formData.name}%0AEmail: ${formData.email}%0ACompany: ${formData.company}%0AInterest: ${formData.interest}%0AMessage: ${formData.message}`;
            window.location.href = `mailto:modeste.agonnoude@grouperms.com?subject=Contact from ${formData.name}&body=${emailBody}`;
            if (statusDiv) {
                statusDiv.style.display = 'block';
                statusDiv.style.color = '#f5a623';
                statusDiv.textContent = 'Envoi via formulaire temporairement indisponible. Votre client email va s\'ouvrir. / Form temporarily unavailable. Your email client will open.';
                setTimeout(() => { statusDiv.style.display = 'none'; }, 5000);
            }
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
        }
    });
}

// ============================================
// ANALYTICS EVENT TRACKING
// ============================================

// Track newsletter subscriptions (ajouter dans initNewsletterForm)
function trackNewsletterSubscription(email) {
    if (typeof gtag !== 'undefined') {
        gtag('event', 'newsletter_subscribe', {
            'event_category': 'engagement',
            'event_label': 'newsletter'
        });
    }
}

// Track scroll depth
let maxScroll = 0;
let scrollTracked = {
    '25%': false,
    '50%': false,
    '75%': false,
    '90%': false
};

window.addEventListener('scroll', () => {
    const scrollPercent = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
    
    if (scrollPercent >= 25 && !scrollTracked['25%']) {
        scrollTracked['25%'] = true;
        gtag('event', 'scroll_depth', { 'event_category': 'engagement', 'event_label': '25%' });
    }
    if (scrollPercent >= 50 && !scrollTracked['50%']) {
        scrollTracked['50%'] = true;
        gtag('event', 'scroll_depth', { 'event_category': 'engagement', 'event_label': '50%' });
    }
    if (scrollPercent >= 75 && !scrollTracked['75%']) {
        scrollTracked['75%'] = true;
        gtag('event', 'scroll_depth', { 'event_category': 'engagement', 'event_label': '75%' });
    }
    if (scrollPercent >= 90 && !scrollTracked['90%']) {
        scrollTracked['90%'] = true;
        gtag('event', 'scroll_depth', { 'event_category': 'engagement', 'event_label': '90%' });
    }
});

// Track outbound links
document.querySelectorAll('a[href^="http"]').forEach(link => {
    // Skip internal links
    if (link.hostname === window.location.hostname) return;
    
    link.addEventListener('click', () => {
        if (typeof gtag !== 'undefined') {
            gtag('event', 'outbound_click', {
                'event_category': 'engagement',
                'event_label': link.href
            });
        }
    });
});

// Track PDF downloads
document.querySelectorAll('a[href$=".pdf"]').forEach(link => {
    link.addEventListener('click', () => {
        if (typeof gtag !== 'undefined') {
            gtag('event', 'pdf_download', {
                'event_category': 'engagement',
                'event_label': link.href.split('/').pop()
            });
        }
    });
});

      
    // ============================================
    // 5. NEWSLETTER FORM HANDLER (with GA tracking)
    // ============================================

function trackNewsletterSubscription(email) {
    if (typeof gtag !== 'undefined') {
        gtag('event', 'newsletter_subscribe', {
            'event_category': 'engagement',
            'event_label': 'newsletter',
            'value': 1
        });
        console.log('Newsletter subscription tracked for:', email);
    } else {
        console.log('GTag not available');
    }
}

function initNewsletterForm() {
    const newsletterForm = document.getElementById('newsletterForm');
    if (!newsletterForm) return;
    
    newsletterForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const emailInput = document.getElementById('newsletterEmail');
        const email = emailInput?.value.trim();
        const messageDiv = document.getElementById('newsletterMessage');
        
        if (!email || !email.includes('@')) {
            if (messageDiv) {
                messageDiv.style.display = 'block';
                messageDiv.style.color = '#f5a623';
                messageDiv.textContent = 'Veuillez entrer une adresse email valide. / Please enter a valid email address.';
                setTimeout(() => { messageDiv.style.display = 'none'; }, 3000);
            }
            return;
        }
        
        const submitBtn = document.getElementById('newsletterSubmitBtn');
        const originalText = submitBtn.textContent;
        submitBtn.disabled = true;
        submitBtn.textContent = 'Envoi...';
        
        const formData = {
            email: email,
            timestamp: new Date().toISOString(),
            source: window.location.pathname
        };
        
        try {
            const response = await fetch('https://e9hpqlfmz2.execute-api.us-east-1.amazonaws.com/prod/newsletter', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            if (response.ok) {
                if (messageDiv) {
                    messageDiv.style.display = 'block';
                    messageDiv.style.color = '#28a745';
                    messageDiv.textContent = 'Merci pour votre inscription ! / Thank you for subscribing!';
                    setTimeout(() => { messageDiv.style.display = 'none'; }, 3000);
                }
                newsletterForm.reset();
                
                // Track subscription
                trackNewsletterSubscription(email);
                
            } else {
                throw new Error('API error');
            }
        } catch (error) {
            console.error('Newsletter error:', error);
            // Fallback: store in localStorage
            let subscribers = JSON.parse(localStorage.getItem('newsletter_subscribers') || '[]');
            if (!subscribers.includes(email)) {
                subscribers.push(email);
                localStorage.setItem('newsletter_subscribers', JSON.stringify(subscribers));
            }
            if (messageDiv) {
                messageDiv.style.display = 'block';
                messageDiv.style.color = '#f5a623';
                messageDiv.textContent = 'Inscription enregistrée localement. / Subscription saved locally.';
                setTimeout(() => { messageDiv.style.display = 'none'; }, 3000);
            }
            newsletterForm.reset();
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = originalText;
        }
    });
}

    // ============================================
    // 6. SMOOTH SCROLL
    // ============================================
    
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href && href.length > 1 && href !== '#') {
                const target = document.querySelector(href);
                if (target) {
                    e.preventDefault();
                    window.scrollTo({ top: target.offsetTop - 80, behavior: 'smooth' });
                }
            }
        });
    });

    // ============================================
    // 7. COPYRIGHT YEAR UPDATE
    // ============================================
    
    const copyright = document.querySelector('.copyright p');
    if (copyright) {
        const year = new Date().getFullYear();
        copyright.innerHTML = copyright.innerHTML.replace(/2021-\d{4}/, `2021-${year}`);
    }

    // ============================================
    // 8. FLOATING WHATSAPP BUTTON
    // ============================================

    const waNumber = '2290161950415';
    const waMessage = encodeURIComponent('Hello Modeste, I would like to discuss an advisory engagement.');

    const waBtn = document.createElement('a');
    waBtn.href = `https://wa.me/${waNumber}?text=${waMessage}`;
    waBtn.target = '_blank';
    waBtn.rel = 'noopener';
    waBtn.id = 'whatsapp-float';
    waBtn.setAttribute('aria-label', 'Chat on WhatsApp');
    waBtn.innerHTML = `
        <span class="wa-float-icon"><i class="fab fa-whatsapp"></i></span>
        <span class="wa-float-label">WhatsApp</span>
    `;
    document.body.appendChild(waBtn);

    // Show tooltip on first visit
    if (!localStorage.getItem('wa-tooltip-seen')) {
        waBtn.classList.add('wa-pulse');
        setTimeout(() => {
            waBtn.classList.remove('wa-pulse');
            localStorage.setItem('wa-tooltip-seen', '1');
        }, 4000);
    }
});


// Register Service Worker
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('Service Worker registered:', registration);
            })
            .catch(error => {
                console.error('Service Worker registration failed:', error);
            });
    });
}