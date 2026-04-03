# ceo.grouperms.com — Personal Branding Site v2.1

[![Website](https://img.shields.io/badge/website-ceo.grouperms.com-blue)](https://ceo.grouperms.com)
[![Version](https://img.shields.io/badge/version-2.1.0-green)](https://ceo.grouperms.com)

## Overview

Personal branding site for **Modeste AGONNOUDE** — Former ENGIE Group CDIO | MIT CTO Certified | Founder & CEO of RMS International Group.

This site (`ceo.grouperms.com`) is the personal brand hub. The company site lives at [www.grouperms.com](https://www.grouperms.com).

## Features

- **Personal branding identity** — Modeste AGONNOUDE, Energy & Digital Advisor
- **Bilingual support** (FR/EN) with flag-based language switcher
- **Dynamic header & footer** loaded via JavaScript (works from both root and `articles/` subdirectory)
- **Responsive design** for all devices — mobile, tablet, desktop
- **Contact form** with reCAPTCHA v3 and email fallback
- **Newsletter subscription** with API + localStorage fallback
- **Floating WhatsApp button** — appears on all pages, expands on hover
- **Google Analytics GA4** integration with scroll depth and event tracking
- **PWA** — manifest.json + service worker (sw.js)
- **SEO** — canonical URLs, Open Graph, Schema.org Person, sitemap.xml
- **Security headers** — X-Content-Type-Options, X-Frame-Options, XSS Protection

## Technology Stack

| Category | Technologies |
|----------|-------------|
| **Frontend** | HTML5, CSS3, JavaScript (ES6+) |
| **Fonts** | Google Fonts — Playfair Display + DM Sans |
| **Icons** | Font Awesome 6.4 |
| **Hosting** | AWS S3 + CloudFront CDN |
| **Analytics** | Google Analytics GA4 (G-483SEQM9JJ) |
| **Security** | reCAPTCHA v3 |
| **LMS** | Moodle (academy.grouperms.com) |

## Project Structure

```
ceo.grouperms.com/
├── index.html              # Homepage — personal branding hero
├── about.html              # Full biography — Bull (12yr) + ENGIE (16yr) + education
├── advisory.html           # Strategic advisory services
├── academy.html            # RMS Digital Academy
├── blog.html               # Insights listing (6 articles)
├── contact.html            # Contact form + social links
├── header.html             # Dynamic header component
├── footer.html             # Dynamic footer component
├── css/
│   └── styles.css          # Main stylesheet (20 sections)
├── js/
│   └── main.js             # Main JS — header/footer loading, forms, WhatsApp button
├── articles/               # Blog articles
│   ├── ransomware-2025.html
│   ├── erp-africa-sme.html
│   ├── cloud-migration-steps.html
│   ├── energy-transition-cio.html
│   ├── devsecops-secure-by-design.html
│   └── finops-cloud-costs.html
├── images/                 # Profile photo, logo
├── flags/                  # FR/EN flag icons
├── pdfs/                   # Resume, legal documents
├── sw.js                   # Service Worker (PWA)
├── manifest.json           # Web App Manifest
├── sitemap.xml             # XML sitemap
└── robots.txt              # Search engine directives
```

## Deployment

Hosted on **AWS S3** with **CloudFront** CDN.

```bash
# Deploy to S3
aws s3 sync . s3://ceo.grouperms.com/ --delete --exclude ".git/*"

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

## Contact

- **Email:** modeste.agonnoude@grouperms.com
- **LinkedIn:** [linkedin.com/in/magonnoude](https://www.linkedin.com/in/magonnoude/)
- **Phone (France):** +33 6 74 43 76 09
- **WhatsApp (Benin):** +229 01 61 95 04 15

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 2.1.0 | April 2026 | Personal branding redesign, 6 articles, WhatsApp integration, full consistency audit |
| 2.0.0 | March 2026 | Initial personal site launch |

---

© 2021-2026 Modeste Agonnoudé — RMS International Group. All rights reserved.
