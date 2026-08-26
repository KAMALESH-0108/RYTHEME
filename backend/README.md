# 🎵 RYTHEME Node.js Backend API

Production-ready Node.js / Express backend service for the **Rytheme** music application. It provides unified orchestration between **Supabase** (PostgreSQL, Auth, Realtime) and the **JioSaavn Open-Source Music API** (Search, 320kbps streams, lyrics, metadata, and API key proxying).

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and fill in your keys:
```bash
cp .env.example .env
```

```env
PORT=5000
NODE_ENV=development

# Supabase Credentials (from https://app.supabase.com)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key-here

# JioSaavn Open-Source API
JIOSAAVN_API_URL=https://saavn.dev
JIOSAAVN_API_KEY=
JIOSAAVN_RAPIDAPI_HOST=
```

### 3. Run the Server
```bash
# Development mode (auto-reload with nodemon)
npm run dev

# Production mode
npm start
```

The API will be live at `http://localhost:5000`.

---

## 📡 API Endpoints

### 🩺 Health & Diagnostics
- `GET /api/health` - Inspects backend status, Supabase connectivity, and JioSaavn API ping.

### 🎵 Music Endpoints (JioSaavn Proxy)
- `GET /api/music/trending` - Fetch trending / global hit songs.
- `GET /api/music/search?query=synthwave&page=1&limit=20` - Search songs.
- `GET /api/music/song/:id` - Get high-res 500x500 artwork & 320kbps direct audio stream link.
- `GET /api/music/song/:id/lyrics` - Fetch synchronized / plaintext lyrics.
- `GET /api/music/song/:id/recommendations` - Get related tracks.
- `GET /api/music/albums/search?query=xxx` - Search albums.
- `GET /api/music/album/:id` - Get album tracks and artwork.
- `GET /api/music/playlists/search?query=xxx` - Search playlists.
- `GET /api/music/playlist/:id` - Get playlist tracks.

### 👤 User & Library Endpoints (Supabase)
- `GET /api/user/profile` - Fetch current user profile & Rhythm DNA.
- `PUT /api/user/profile` - Update profile, hours, or theme preferences.
- `GET /api/user/likes` - Fetch liked songs.
- `POST /api/user/likes/toggle` - Like or unlike a song.
- `GET /api/user/playlists` - Fetch user playlists.
- `POST /api/user/playlists` - Create a new playlist.
- `GET /api/user/journal` - Fetch Sound Journal entries.
- `POST /api/user/journal` - Save a sound journal entry.

### 👥 Live JAMS Endpoints
- `GET /api/jams/active` - List all live listening rooms.
- `POST /api/jams/create` - Start a new live listening room.

---

## 🐳 Docker Deployment (Optional)

You can run this backend anywhere with Docker:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```
