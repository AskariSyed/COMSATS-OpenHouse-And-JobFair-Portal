# GitHub Actions CI/CD Setup Guide

This guide walks you through setting up the automated build and deploy workflow for your JobFair Portal.

## Quick Setup (5 minutes)

### Step 1: Add GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Click **New repository secret** and add these secrets:

**Important:** For `BACKEND_URL`, use:
- **Production:** `https://api.jfair.tech` (requires DNS A record pointing to your EC2 IP)
- **Or:** `http://52.221.35.144:5158` (direct IP address)

| Secret Name | Value | Example |
|-------------|-------|---------|
| `EC2_HOST` | Your EC2 instance IP or domain | `52.221.35.144` |
| `EC2_USER` | SSH user (usually `ubuntu`) | `ubuntu` |
| `EC2_PEM_KEY` | Your private SSH key contents | (paste entire .pem file) |
| `BACKEND_URL` | Your backend API URL | `https://api.jfair.tech` or `http://52.221.35.144:5158` |
| `FIREBASE_API_KEY` | From Firebase Console | *get from .env* |
| `FIREBASE_AUTH_DOMAIN` | From Firebase Console | `hirebridge-c28e9.firebaseapp.com` |
| `FIREBASE_PROJECT_ID` | From Firebase Console | `hirebridge-c28e9` |
| `FIREBASE_STORAGE_BUCKET` | From Firebase Console | `hirebridge-c28e9.appspot.com` |
| `FIREBASE_MESSAGING_SENDER_ID` | From Firebase Console | *get from .env* |
| `FIREBASE_APP_ID` | From Firebase Console | *get from .env* |
| `FIREBASE_VAPID_KEY` | From Firebase Console Cloud Messaging | *get from .env* |

### Step 2: Copy EC2 SSH Key

1. Get your private SSH key (`jobfair-key.pem`)
2. Open it with a text editor
3. Copy the entire contents (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
4. Paste into GitHub Secret `EC2_PEM_KEY`

### Step 3: Get Firebase Values

Get Firebase values from your `.env` file:
```bash
# From: company-portal/.env
cat company-portal/.env | grep VITE_FIREBASE
```

Or from Firebase Console:
1. Go to https://console.firebase.google.com
2. Select your project
3. Settings → General → Your apps → Web app
4. Copy the configuration

### Step 3.5: Setup DNS (Optional but Recommended)

To use `https://api.jfair.tech` instead of the raw IP:

1. Go to your domain registrar (GoDaddy, Namecheap, Google Domains, etc.)
2. Add a DNS **A record**:
   - **Name/Host:** `api`
   - **Type:** `A`
   - **Value/Points to:** Your EC2 IP (`52.221.35.144`)
   - **TTL:** 3600 (or default)

This creates the subdomain `api.jfair.tech` pointing to your backend.

### Step 4: Test the Workflow

Push a change to your `main` branch:
```bash
git add .
git commit -m "trigger CI/CD"
git push origin main
```

Watch it run: Go to your GitHub repo → **Actions** tab

## Workflow Details

**Triggers:**
- Automatically on every `push` to `main` branch
- Manual trigger via **Actions** tab → "Build and Deploy to EC2" → **Run workflow**

**What it does:**
1. ✅ Checks out your code
2. ✅ Sets up Node.js, Flutter, and .NET environments
3. ✅ Builds all 5 apps (Admin, Company, Student, Landing, Backend)
4. ✅ Packages each as a .tar.gz artifact
5. ✅ Uploads to EC2 via SCP
6. ✅ Extracts and deploys all apps
7. ✅ Reloads Nginx

**Deployment targets on EC2:**
- `/var/www/admin/` → https://admin.jfair.tech
- `/var/www/company/` → https://company.jfair.tech
- `/var/www/student/` → https://student.jfair.tech
- `/var/www/jfair/` → https://jfair.tech (landing page)
- `/var/www/api/` → Backend API

## Troubleshooting

### Workflow fails with SSH error
- Verify `EC2_PEM_KEY` is the complete private key (includes begin/end markers)
- Check `EC2_HOST` and `EC2_USER` are correct
- Ensure EC2 security group allows SSH (port 22)

### Build failures
- Check the **Actions** tab error logs
- Common: Firebase env vars missing → Verify all FIREBASE_* secrets are set
- Student web build fails → Update Flutter env if using custom versions

### Deployment timeout
- Reduce artifact size or increase timeout in workflow
- Check EC2 has sufficient disk space: `df -h`

### Changes don't appear on website
- Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
- Clear CloudFront cache if using CDN
- Check Nginx is reloaded: Workflow logs should show "Reloading Nginx"

## Modify Workflow

Edit `.github/workflows/build-and-deploy.yml` to:
- Change trigger branch (currently `main`)
- Add additional build steps
- Modify deployment paths
- Add Slack/Email notifications

## Disable Workflow

To temporarily disable:
1. GitHub repo → **Actions** → Click workflow
2. **...** menu → **Disable workflow**

To re-enable:
1. Same location → **Enable workflow**

## Next Steps

1. Add all secrets (takes 5 minutes)
2. Make a test push to trigger the first deployment
3. Monitor the **Actions** tab
4. Verify all apps are accessible via HTTPS

---

**Need help?** Check GitHub Actions logs in your repo → **Actions** → Latest workflow run
