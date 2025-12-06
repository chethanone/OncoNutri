# OncoNutri+ Quick Start Guide

Get the application running in under 10 minutes.

## Prerequisites Check

Verify you have these installed:

```bash
flutter --version    # Should be 3.0+
node --version       # Should be 16+
python --version     # Should be 3.8+
psql --version       # Should be 13+
```

---

## Step 1: Environment Configuration (2 minutes)

**This is the most important step!** All credentials are in ONE file.

```bash
# Navigate to project root
cd OncoNutri+

# Copy environment template
cp .env.example .env
```

Edit `.env` and update:

```env
# Your PostgreSQL password
DB_PASSWORD=your_actual_database_password_here

# YouTube API key (get from: https://console.cloud.google.com/apis/credentials)
YOUTUBE_API_KEY=your-youtube-api-key-here

# Gemini API key (get from: https://makersuite.google.com/app/apikey)
GOOGLE_API_KEY=your-google-gemini-api-key-here

# JWT Secret (generate with command below)
JWT_SECRET=your-generated-secret-here
```

Generate JWT secret:
```powershell
# Windows PowerShell
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

---

## Step 2: Database Setup (2 minutes)

```bash
# Create database
createdb onconutri

# Load schema
psql -U postgres -d onconutri -f backend/database/schema.sql

# Apply migrations
cd backend/database
node run_migration_v5.js
cd ../..
```

---

## Step 3: Install Dependencies (3 minutes)

```bash
# Node.js backend
cd backend/node_server
npm install
cd ../..

# Python ML service
cd backend/fastapi_ml
python -m venv venv
venv\Scripts\activate  # Windows (or: source venv/bin/activate on Mac/Linux)
pip install -r requirements.txt
deactivate
cd ../..

# Flutter app
cd frontend
flutter pub get
flutter pub run flutter_gen:build
cd ..
```

---

## Step 4: Run the Application (3 terminals)

### Terminal 1: Node.js Backend
```bash
cd backend/node_server
node app.js
```
✅ Wait for: "Backend server running on port 5000"

### Terminal 2: FastAPI ML Service
```bash
cd backend/fastapi_ml
venv\Scripts\activate  # Windows
python main.py
```
✅ Wait for: "Application startup complete"

### Terminal 3: Flutter App
```bash
cd frontend
flutter run
```
✅ App should launch on your device/emulator

---

## Verify Installation

1. **Backend Health:** http://localhost:5000/health
2. **ML Service:** http://localhost:8000
3. **App:** Create account → Complete intake → View recommendations

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Cannot find module" | Run `npm install` in node_server |
| "PostgreSQL connection failed" | Check DB_PASSWORD in `.env` |
| "Port 5000 in use" | `taskkill /PID <pid> /F` |
| "API key not valid" | Verify keys in `.env` |

---

**Done! See README.md for detailed documentation.**
