# GitHub Repository Setup + CI/CD — Step-by-Step Guide
# Site: ceo.grouperms.com | April 2026
# ═══════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — PREPARE YOUR LOCAL FILES
# ═══════════════════════════════════════════════════════════════════════════════

# Your final file structure should look like this:
#
# ceo-grouperms/                    ← root of repository
# ├── index.html
# ├── about.html
# ├── advisory.html
# ├── academy.html
# ├── blog.html
# ├── contact.html
# ├── header.html
# ├── footer.html
# ├── sitemap.xml
# ├── robots.txt
# ├── manifest.json
# ├── sw.js
# ├── favicon.ico
# ├── css/
# │   └── styles.css
# ├── js/
# │   └── main.js
# ├── articles/
# │   ├── ransomware-2025.html
# │   ├── erp-africa-sme.html
# │   ├── cloud-migration-steps.html
# │   ├── energy-transition-cio.html
# │   ├── devsecops-secure-by-design.html
# │   └── finops-cloud-costs.html
# ├── images/                       ← Modeste_AGONNOUDE.jpg, rms.jpg, icons
# ├── flags/                        ← fr.png, en.png
# ├── pdfs/                         ← resume, legal docs
# ├── devops/
# │   ├── lambda/
# │   │   ├── lambda_function.py
# │   │   ├── iam-policy.json
# │   │   └── DEPLOY.sh
# │   └── GOOGLE_SETUP.md
# ├── .github/
# │   └── workflows/
# │       └── deploy.yml
# ├── .gitignore
# └── README.md


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — CREATE GITHUB REPOSITORY
# ═══════════════════════════════════════════════════════════════════════════════

STEP 1: Go to github.com → Sign in as magonnoude

STEP 2: Create new repository
  → Click "+" → "New repository"
  → Repository name:  ceo-grouperms-com
  → Description:      Personal branding site — ceo.grouperms.com
  → Visibility:       Private  ← keep code private
  → DO NOT initialize with README (you'll push your own)
  → Click "Create repository"

STEP 3: Note your repository URL
  → https://github.com/magonnoude/ceo-grouperms-com


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — INITIALIZE GIT LOCALLY
# ═══════════════════════════════════════════════════════════════════════════════

# Open Terminal and navigate to your site folder
cd /path/to/your/ceo-grouperms/

# Copy devops files into the right places
cp devops/.gitignore .gitignore
mkdir -p .github/workflows
cp devops/.github/workflows/deploy.yml .github/workflows/deploy.yml

# Initialize git
git init

# Set your identity (if not already configured globally)
git config user.email "modeste.agonnoude@grouperms.com"
git config user.name "Modeste AGONNOUDE"

# Add all files
git add .

# Check what will be committed
git status

# Initial commit
git commit -m "feat: initial release ceo.grouperms.com v2.1.0

- Personal branding redesign (Playfair Display + DM Sans)
- Split-screen hero with photo
- 12yr Bull + 16yr ENGIE career narrative
- Full education section (MIT, McCombs, Ponts, CNAM)
- Advisory, Academy, Blog, Contact pages
- 6 full articles on cybersecurity, cloud, energy, ERP, DevSecOps, FinOps
- Floating WhatsApp button
- Dynamic header/footer with subdirectory support
- reCAPTCHA v3 contact form + newsletter
- PWA (manifest + service worker)
- SEO: canonical, OG, Schema.org, sitemap"

# Connect to GitHub
git remote add origin https://github.com/magonnoude/ceo-grouperms-com.git

# Push
git branch -M main
git push -u origin main


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4 — CREATE AWS IAM USER FOR GITHUB ACTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# In AWS Console → IAM → Users → Create user
#
# User name:    github-actions-ceo
# Access type:  Programmatic access (access key + secret)
#
# Attach policy (create new inline policy):

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3DeployAccess",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::ceo.grouperms.com",
        "arn:aws:s3:::ceo.grouperms.com/*"
      ]
    },
    {
      "Sid": "CloudFrontInvalidation",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetDistribution"
      ],
      "Resource": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DIST_ID"
    }
  ]
}

# After creating the user:
# → Save the Access Key ID and Secret Access Key
# → You will need these in Phase 5


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5 — ADD SECRETS TO GITHUB REPOSITORY
# ═══════════════════════════════════════════════════════════════════════════════

# GitHub → your repo → Settings → Secrets and variables → Actions
# → "New repository secret" for each:

Secret name                    Value
─────────────────────────────────────────────────────────────
AWS_ACCESS_KEY_ID              AKIA...  (from Phase 4)
AWS_SECRET_ACCESS_KEY          ...      (from Phase 4)
S3_BUCKET                      ceo.grouperms.com
CLOUDFRONT_DISTRIBUTION_ID     EXXXXXXXXXX  (your CloudFront dist ID)

# To find your CloudFront distribution ID:
aws cloudfront list-distributions \
  --query "DistributionList.Items[?DomainName=='ceo.grouperms.com.cloudfront.net'].Id" \
  --output text


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 6 — TEST THE PIPELINE
# ═══════════════════════════════════════════════════════════════════════════════

# Make a small change to trigger deployment
echo "<!-- v2.1.0 deployed $(date) -->" >> index.html
git add index.html
git commit -m "test: trigger CI/CD pipeline"
git push

# Watch the deployment:
# GitHub → your repo → Actions → "Deploy ceo.grouperms.com → S3 + CloudFront"
# You should see all steps turn green within 60-90 seconds

# Verify live site
curl -I https://ceo.grouperms.com/
# Should return: HTTP/2 200


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 7 — ONGOING WORKFLOW
# ═══════════════════════════════════════════════════════════════════════════════

# For every update to the site, the workflow is:

# 1. Make changes locally
# 2. Test in browser (open index.html directly)
# 3. Stage and commit
git add .
git commit -m "content: update [describe what changed]"

# 4. Push → triggers automatic deployment
git push

# 5. Deployment completes in ~60 seconds
# 6. CloudFront cache cleared → live in <5 minutes

# BRANCH STRATEGY (recommended as site grows):
#
# main         → production (auto-deploys)
# develop      → staging / work in progress
# feature/xxx  → individual features
#
# git checkout -b feature/new-article-fintech
# ... make changes ...
# git push origin feature/new-article-fintech
# → Open Pull Request on GitHub → merge to main → auto-deploys


# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 8 — USEFUL GIT COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

# See recent commits
git log --oneline -10

# See what changed in last commit
git show --stat HEAD

# Undo last commit (keep files)
git reset --soft HEAD~1

# Discard all local changes (careful!)
git checkout -- .

# Pull latest from GitHub
git pull origin main

# Tag a release
git tag -a v2.1.0 -m "Release v2.1.0 — full personal branding site"
git push origin v2.1.0
