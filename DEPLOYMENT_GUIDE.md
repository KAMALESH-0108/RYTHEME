# 🚀 RYTHEME Production Deployment Guide
Comprehensive guide to deploying the **Frontend (Flutter Web)**, **Backend (Node.js Express + Supabase)**, and **API (JioSaavn Engine)** across cloud platforms.

---

## 🏛️ Stack Architecture Overview

```
                               ┌────────────────────────────────────────┐
                               │             USER BROWSER               │
                               │        (Flutter Web App UI)            │
                               └──────────────────┬─────────────────────┘
                                                  │
                                          HTTPS (Port 5000)
                                                  │
                                                  ▼
                        ┌───────────────────────────────────────────────────────┐
                        │              RYTHEME UNIFIED CONTAINER                │
                        │                                                       │
                        │  ┌─────────────────────────────────────────────────┐  │
                        │  │          Node.js Express Web & API Server       │  │
                        │  │  - Serves static Flutter Web build (SPA)        │  │
                        │  │  - REST Endpoints (/api/music/*, /api/user/*)   │  │
                        │  └───────────────┬─────────────────┬───────────────┘  │
                        │                  │                 │                  │
                        │      Local IPC (Port 3000)         │                  │
                        │                  ▼                 │                  │
                        │  ┌──────────────────────────────┐  │                  │
                        │  │   JioSaavn Music API Engine  │  │                  │
                        │  │   - 320kbps Audio Streams    │  │                  │
                        │  │   - Song & Artist Search     │  │                  │
                        │  └──────────────────────────────┘  │                  │
                        └────────────────────────────────────┼──────────────────┘
                                                             │
                                                   Direct Cloud Queries
                                                             │
                                                             ▼
                                                ┌─────────────────────────┐
                                                │    SUPABASE DATABASE    │
                                                │  - PostgreSQL Tables    │
                                                │  - Google & Email Auth  │
                                                │  - Realtime Channels    │
                                                └─────────────────────────┘
```

---

## 🎯 Deployment Options

| Option | Best For | Complexity | Cost |
| :--- | :--- | :--- | :--- |
| **1. Render Blueprint** *(Recommended)* | 1-click cloud hosting with automated SSL & CI/CD | ⭐ Very Easy | **Free tier** |
| **2. Railway** | Fast containerized deployment from GitHub repo | ⭐ Very Easy | Free trial / \$5/mo |
| **3. Docker / VPS (DigitalOcean / AWS / GCP)** | Full control, scalable, dedicated hosting | ⭐⭐ Moderate | \$4 – \$10/mo |
| **4. Split Jamstack (Vercel + Render)** | Ultra-fast CDN frontend + separate API backend | ⭐⭐ Moderate | **Free tier** |

---

## 🟢 Option 1: 1-Click Render Deployment (Recommended)

Render uses the included [`render.yaml`](./render.yaml) blueprint to deploy the unified container automatically.

### Steps:
1. Push your repository to **GitHub** or **GitLab**.
2. Go to **[Render Dashboard](https://dashboard.render.com/)** and click **New +** → **Blueprint**.
3. Connect your repository (`rytheme_flutter`).
4. Render will detect `render.yaml` and set up the Web Service automatically.
5. Verify the following **Environment Variables** in the Render UI:
   - `NODE_ENV` = `production`
   - `PORT` = `5000`
   - `SUPABASE_URL` = `https://dpnxxrmvahyfzpfwhrey.supabase.co`
   - `SUPABASE_ANON_KEY` = `<YOUR_ANON_KEY>`
   - `SUPABASE_SERVICE_ROLE_KEY` = `<YOUR_SERVICE_ROLE_KEY>`
   - `JIOSAAVN_API_URL` = `http://localhost:3000`
6. Click **Apply**. Render will automatically build the multi-stage Docker container and give you a live HTTPS URL (e.g. `https://rytheme-music.onrender.com`).

---

## 🚂 Option 2: Railway Deployment

Railway detects the included [`railway.json`](./railway.json) and [`Dockerfile`](./Dockerfile).

### Steps:
1. Go to **[Railway.app](https://railway.app)** and click **New Project** → **Deploy from GitHub repo**.
2. Select your `rytheme_flutter` repository.
3. In **Variables**, add:
   - `SUPABASE_URL` = `https://dpnxxrmvahyfzpfwhrey.supabase.co`
   - `SUPABASE_ANON_KEY` = `<YOUR_ANON_KEY>`
   - `SUPABASE_SERVICE_ROLE_KEY` = `<YOUR_SERVICE_ROLE_KEY>`
   - `JIOSAAVN_API_URL` = `http://localhost:3000`
4. Railway will automatically build and deploy. Under **Settings** → **Domains**, generate a public domain (e.g. `rytheme.up.railway.app`).

---

## 🐳 Option 3: VPS / Ubuntu / Docker Host Deployment

Deploy directly on any Linux server (DigitalOcean Droplet, AWS EC2, GCP Compute Engine, Linode, or Hetzner).

### 1-Command Deployment via Docker Compose:
```bash
# Clone the repository
git clone https://github.com/<your-username>/rytheme_flutter.git
cd rytheme_flutter

# Launch the unified container in background
docker compose up -d --build
```

### Or native build with shell script:
```bash
chmod +x deploy.sh
./deploy.sh
```

### Nginx Reverse Proxy & SSL (Optional):
```nginx
server {
    server_name yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```
Obtain free SSL certificate via Certbot:
```bash
sudo certbot --nginx -d yourdomain.com
```

---

## ⚡ Option 4: Split Architecture (Vercel + Render/Fly.io)

If you prefer hosting the **Frontend on Vercel** and the **Backend & API on Render/Fly.io**:

1. **Deploy Backend & JioSaavn Engine**:
   - Deploy `backend/` and `jiosaavn-api/` to Render or Fly.io.
   - Get the backend public URL (e.g. `https://api.rytheme.com`).
2. **Deploy Frontend to Vercel**:
   - In `lib/config.dart`, update:
     ```dart
     static const String nodeBackendUrl = 'https://api.rytheme.com';
     ```
   - Build frontend: `flutter build web --release`.
   - Deploy `build/web` folder to Vercel via `vercel deploy --prod`.

---

## 🔐 Supabase Production Checklist

1. **Run Database Schema**:
   Ensure you have executed the full [`supabase_schema.sql`](./supabase_schema.sql) in your **Supabase SQL Editor**.
2. **Google OAuth Redirect URLs**:
   In your **Supabase Dashboard** → **Authentication** → **URL Configuration**:
   - **Site URL**: `https://your-production-domain.com`
   - **Redirect URLs**:
     - `https://your-production-domain.com/**`
     - `http://localhost:5000/**` (for local development)
3. **Google Cloud Console**:
   In [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials):
   - Add your Supabase auth callback URL: `https://<your-project-ref>.supabase.co/auth/v1/callback` under **Authorized redirect URIs**.

---

## 🛠️ Production Environment Variables Reference

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `NODE_ENV` | Runtime environment | `production` |
| `PORT` | Main HTTP port | `5000` |
| `SUPABASE_URL` | Supabase project URL | `https://dpnxxrmvahyfzpfwhrey.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anonymous public key | `eyJhbGci...` |
| `SUPABASE_SERVICE_ROLE_KEY`| Supabase service role secret key | `eyJhbGci...` |
| `JIOSAAVN_API_URL` | Local or remote JioSaavn API URL | `http://localhost:3000` |
| `CORS_ORIGIN` | Allowed CORS origins | `*` or `https://yourdomain.com` |

---

## 🧪 Health Verification

Once deployed, verify your deployment status:
- **Web App UI**: `https://your-production-domain.com/`
- **Backend Health Check**: `https://your-production-domain.com/api/health`
- **JioSaavn Search Test**: `https://your-production-domain.com/api/music/search?query=Starboy`
