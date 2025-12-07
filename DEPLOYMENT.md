# OncoNutri+ Cloud Deployment Guide

## 🚀 Deploy to Render (Free)

### Prerequisites
- GitHub account
- Render account (sign up at https://render.com)
- Your code pushed to GitHub ✅ (Already done!)

### Step 1: Create Render Account
1. Go to https://render.com
2. Sign up with your GitHub account
3. Authorize Render to access your repositories

### Step 2: Create PostgreSQL Database
1. Click **"New +"** → **"PostgreSQL"**
2. Settings:
   - Name: `onconutri-db`
   - Database: `onconutri`
   - User: `onconutri_user`
   - Region: `Oregon (US West)`
   - Plan: **Free**
3. Click **"Create Database"**
4. Wait 2-3 minutes for provisioning
5. **Copy the connection details** (you'll need them)

### Step 3: Deploy Node.js Server
1. Click **"New +"** → **"Web Service"**
2. Connect to your GitHub repository: `chethanone/OncoNutri`
3. Settings:
   - Name: `onconutri-node-api`
   - Region: `Oregon (US West)`
   - Branch: `main`
   - Root Directory: `backend/node_server`
   - Environment: `Node`
   - Build Command: `npm install`
   - Start Command: `node app.js`
   - Plan: **Free**
4. Click **"Advanced"** → Add Environment Variables:
   ```
   NODE_ENV=production
   PORT=5000
   DB_HOST=[from database internal connection]
   DB_PORT=5432
   DB_NAME=onconutri
   DB_USER=onconutri_user
   DB_PASSWORD=[from database]
   JWT_SECRET=[generate random 32-char string]
   YOUTUBE_API_KEY=AIzaSyBpbF-Z3KdsNUkZ6Eg1O2gvZn171lE3xsE
   GOOGLE_API_KEY=AIzaSyBpbF-Z3KdsNUkZ6Eg1O2gvZn171lE3xsE
   ```
5. Click **"Create Web Service"**

### Step 4: Deploy FastAPI ML Server
1. Click **"New +"** → **"Web Service"**
2. Connect to your GitHub repository: `chethanone/OncoNutri`
3. Settings:
   - Name: `onconutri-ml-api`
   - Region: `Oregon (US West)`
   - Branch: `main`
   - Root Directory: `backend/fastapi_ml`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn main:app --host 0.0.0.0 --port 8000`
   - Plan: **Free**
4. Click **"Advanced"** → Add Environment Variables:
   ```
   PYTHON_VERSION=3.11.0
   PORT=8000
   GOOGLE_API_KEY=AIzaSyBpbF-Z3KdsNUkZ6Eg1O2gvZn171lE3xsE
   ```
5. Click **"Create Web Service"**

### Step 5: Run Database Migrations
1. Go to your `onconutri-db` database in Render
2. Click **"Connect"** → Copy the **"External Connection String"**
3. On your computer, run:
   ```bash
   # Install PostgreSQL client (if not installed)
   # Windows: Download from postgresql.org
   
   # Connect to database
   psql [paste-connection-string-here]
   
   # Run schema
   \i backend/database/schema.sql
   
   # Run migrations
   \i backend/database/migrations/V1__initial_schema.sql
   \i backend/database/migrations/V2__add_patient_summary_view.sql
   \i backend/database/migrations/V3__add_dietary_preference.sql
   \i backend/database/migrations/V4__add_height_and_dietary_preference.sql
   \i backend/database/migrations/V5__add_intake_fields.sql
   ```

### Step 6: Update Flutter App
1. Get your deployed URLs from Render:
   - Node API: `https://onconutri-node-api.onrender.com`
   - ML API: `https://onconutri-ml-api.onrender.com`

2. Update `frontend/lib/services/api_service.dart`:
   ```dart
   // Change from:
   static const String apiUrl = 'http://localhost:5000';
   static const String mlApiUrl = 'http://localhost:8000';
   
   // To:
   static const String apiUrl = 'https://onconutri-node-api.onrender.com';
   static const String mlApiUrl = 'https://onconutri-ml-api.onrender.com';
   ```

3. Update `frontend/lib/services/auth_service.dart`:
   ```dart
   // Change from:
   static const String _baseUrl = 'http://localhost:5000/api';
   
   // To:
   static const String _baseUrl = 'https://onconutri-node-api.onrender.com/api';
   ```

### Step 7: Build & Deploy Flutter App
1. **For Android APK:**
   ```bash
   cd frontend
   flutter build apk --release
   ```
   APK location: `frontend/build/app/outputs/flutter-apk/app-release.apk`

2. **For Play Store:**
   ```bash
   flutter build appbundle --release
   ```

3. **For iOS (requires Mac):**
   ```bash
   flutter build ios --release
   ```

### Step 8: Test Your Deployed App
1. Install the APK on your phone
2. App will now connect to cloud servers
3. Works on any device with internet! 🎉

## 📱 Using the App

### On Any Android Device:
1. Download the APK from GitHub Releases
2. Install (enable "Install from Unknown Sources")
3. Open app - it connects to cloud servers automatically!

### Sharing the App:
1. Upload APK to Google Drive or GitHub Releases
2. Share the link with anyone
3. They can install and use it immediately!

## 🔧 Maintenance

### Viewing Logs:
- Go to Render Dashboard
- Click on your service
- Click **"Logs"** tab

### Updating Code:
1. Push changes to GitHub
2. Render auto-deploys in ~2 minutes!

### Free Tier Limits:
- **Database**: 1GB storage, 100 connections
- **Web Services**: 750 hours/month (enough for 1 service 24/7)
- **Multiple services**: Each gets 750 hours
- **Sleep after 15 min inactivity** (free tier)
- First request may be slow (30s wake-up time)

## 💡 Tips

### Keep Services Active:
Create a cron job to ping your services every 14 minutes:
```bash
curl https://onconutri-node-api.onrender.com/health
curl https://onconutri-ml-api.onrender.com/health
```

### Monitor Usage:
- Check Render dashboard for service health
- Database storage: Dashboard → Database → Metrics

## 🎉 Done!

Your app is now:
✅ Deployed to the cloud
✅ Accessible from any device
✅ No laptop needed
✅ Free to use!

### Your Live URLs:
- **Node API**: https://onconutri-node-api.onrender.com
- **ML API**: https://onconutri-ml-api.onrender.com
- **Database**: Managed by Render
- **App**: Install APK on any Android device
