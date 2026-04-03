# Google Tag Manager + GA4 + Search Console Setup
# Site: ceo.grouperms.com
# April 2026
#
# IMPORTANT: G-483SEQM9JJ belongs to www.grouperms.com
# ceo.grouperms.com needs its OWN GA4 property for separate analytics.
# ═══════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — CREATE GA4 PROPERTY FOR ceo.grouperms.com
# ═══════════════════════════════════════════════════════════════════════════════

STEP 1: Open Google Analytics
  → analytics.google.com
  → Sign in with your Google account

STEP 2: Create a new Property
  → Admin (gear icon, bottom left)
  → "+ Create" → Property
  → Property name:  "Modeste AGONNOUDE — ceo.grouperms.com"
  → Reporting timezone: Europe/Paris (or Africa/Porto-Novo)
  → Currency: EUR

STEP 3: Business details
  → Industry: Business & Industrial Markets
  → Size: Small (1–10 employees)

STEP 4: Business objectives
  → Select: "Generate leads" and "Examine user behavior"

STEP 5: Create data stream
  → Platform: Web
  → URL: https://ceo.grouperms.com
  → Stream name: "ceo.grouperms.com"
  → Enable "Enhanced measurement" (ON)

STEP 6: Note your new Measurement ID
  → It will look like: G-XXXXXXXXXX
  → Copy it — you will need it in Phase 2 and Phase 4


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — CREATE GOOGLE TAG MANAGER CONTAINER
# ═══════════════════════════════════════════════════════════════════════════════

STEP 1: Open Google Tag Manager
  → tagmanager.google.com

STEP 2: Create a new Account
  → Account name: "RMS International Group"
  → Country: France
  → Container name: "ceo.grouperms.com"
  → Target platform: Web
  → Click "Create" → Accept TOS

STEP 3: Note your GTM container ID
  → It will look like: GTM-XXXXXXX
  → GTM gives you two code snippets to add to every page:

  ── Snippet 1: In <head> (as high as possible) ──
  <!-- Google Tag Manager -->
  <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
  new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
  j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
  'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
  })(window,document,'script','dataLayer','GTM-XXXXXXX');</script>
  <!-- End Google Tag Manager -->

  ── Snippet 2: Immediately after <body> ──
  <!-- Google Tag Manager (noscript) -->
  <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-XXXXXXX"
  height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
  <!-- End Google Tag Manager (noscript) -->

  NOTE: Currently the site uses gtag.js directly (G-483SEQM9JJ).
  With GTM you move GA4 configuration INTO GTM. You have two options:

  OPTION A (Simpler) — Keep direct gtag.js, just create a new GA4 property
    → Replace G-483SEQM9JJ with your new G-XXXXXXXXXX in all HTML files
    → No GTM needed

  OPTION B (Recommended for growth) — Use GTM to manage all tags
    → Add GTM snippets to header.html and footer.html
    → Configure GA4 tag inside GTM (see Phase 3)
    → Remove direct gtag.js from all HTML files
    → Future: add LinkedIn Insight Tag, Facebook Pixel, etc. without touching code

  ✅ RECOMMENDATION: Use OPTION B (GTM) — it gives you flexibility
     to add/change tracking tags without redeploying the site.


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — CONFIGURE GA4 TAG IN GTM
# ═══════════════════════════════════════════════════════════════════════════════

STEP 1: In GTM → Tags → New
  → Tag type: "Google Tag"
  → Tag ID: G-XXXXXXXXXX (your new GA4 Measurement ID)
  → Triggering: All Pages
  → Name: "GA4 — ceo.grouperms.com"
  → Save

STEP 2: Configure GA4 Events in GTM

  Event: Contact Form Submit
  → Tags → New → Tag type: "GA4 Event"
  → Measurement ID: G-XXXXXXXXXX
  → Event name: contact_form_submit
  → Parameters: interest = {{DL - interest}}
  → Trigger: Custom Event → Event name: contact_form_submit
  → Name: "GA4 Event — Contact Form Submit"

  Event: PDF Download
  → Tag type: GA4 Event
  → Event name: file_download
  → Trigger: Click — Just Links → Click URL contains ".pdf"
  → Name: "GA4 Event — PDF Download"

  Event: Outbound Click
  → Tag type: GA4 Event
  → Event name: outbound_click
  → Trigger: Click — Just Links → Click URL does not contain "ceo.grouperms.com"
  → Name: "GA4 Event — Outbound Click"

  Event: WhatsApp Click
  → Tag type: GA4 Event
  → Event name: whatsapp_click
  → Trigger: Click — All Elements → Click URL contains "wa.me"
  → Name: "GA4 Event — WhatsApp Click"

STEP 3: Preview and publish
  → GTM → Preview → Enter https://ceo.grouperms.com → verify tags fire
  → Submit → Version name: "v1 — GA4 + Events"
  → Publish


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4 — UPDATE HTML FILES WITH NEW GA4 ID
# ═══════════════════════════════════════════════════════════════════════════════

If using OPTION A (direct gtag.js — no GTM):
  Replace G-483SEQM9JJ with your new G-XXXXXXXXXX in ALL files:

  Files to update:
    about.html, academy.html, advisory.html, blog.html, contact.html,
    index.html, articles/ransomware-2025.html, articles/erp-africa-sme.html,
    articles/cloud-migration-steps.html, articles/energy-transition-cio.html,
    articles/devsecops-secure-by-design.html, articles/finops-cloud-costs.html

  Quick find & replace in VS Code:
    Find:    G-483SEQM9JJ
    Replace: G-XXXXXXXXXX (your new ID)

If using OPTION B (GTM):
  1. Add GTM <head> snippet to header.html (top of <div class="container header-container">)
  2. Add GTM <noscript> snippet to footer.html (top of footer div)
  3. Remove the gtag.js <script> blocks from ALL html files
  4. Keep the dataLayer push in main.js — GTM will pick it up automatically


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5 — GOOGLE SEARCH CONSOLE + SITEMAP
# ═══════════════════════════════════════════════════════════════════════════════

STEP 1: Open Google Search Console
  → search.google.com/search-console
  → "+ Add property"
  → Choose "URL prefix": https://ceo.grouperms.com
  → Click Continue

STEP 2: Verify ownership
  Choose ONE method:

  METHOD A — Google Analytics (easiest if GA4 is already set up)
    → Select "Google Analytics" verification
    → Verify → Done

  METHOD B — HTML tag
    → Copy the meta tag: <meta name="google-site-verification" content="XXXXXXXXXXXX">
    → Add it to the <head> of index.html BEFORE the canonical tag
    → Deploy the file to S3
    → Return to Search Console → Verify

  METHOD C — DNS record (most reliable for subdomains)
    → Google provides a TXT record: google-site-verification=XXXXXXXXXXXX
    → Add to DNS for ceo.grouperms.com (or grouperms.com with subdomain scope)
    → In AWS Route 53:
       aws route53 change-resource-record-sets \
         --hosted-zone-id YOUR_ZONE_ID \
         --change-batch '{
           "Changes": [{
             "Action": "CREATE",
             "ResourceRecordSet": {
               "Name": "ceo.grouperms.com",
               "Type": "TXT",
               "TTL": 300,
               "ResourceRecords": [{"Value": "\"google-site-verification=XXXXXXXXXXXX\""}]
             }
           }]
         }'
    → Wait 10–15 minutes → Verify

STEP 3: Submit sitemap
  → Search Console → Left sidebar → Indexing → Sitemaps
  → "Add a new sitemap"
  → Enter: sitemap.xml
  → Full URL becomes: https://ceo.grouperms.com/sitemap.xml
  → Submit

STEP 4: Request indexing of key pages
  → Search Console → URL Inspection
  → Enter each URL → "Request Indexing"
  Priority order:
    1. https://ceo.grouperms.com/
    2. https://ceo.grouperms.com/about.html
    3. https://ceo.grouperms.com/advisory.html
    4. https://ceo.grouperms.com/blog.html

STEP 5: Verify sitemap is accessible
  curl https://ceo.grouperms.com/sitemap.xml

STEP 6: Link Search Console to GA4
  → GA4 → Admin → Property Settings → Search Console Links
  → "Link" → Choose your Search Console property → ceo.grouperms.com
  → Next → Save
  → This enables the "Search Console" reports in GA4
