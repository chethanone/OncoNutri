# Quick Start Guide - OncoNutri+

Get OncoNutri+ up and running in minutes!

## 🚀 Prerequisites

Before you begin, ensure you have:

- [ ] **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
- [ ] **Python** (3.8 or higher) - [Download](https://python.org/)
- [ ] **PostgreSQL** (13 or higher) - [Download](https://postgresql.org/)
- [ ] **Flutter SDK** (3.0 or higher) - [Install Guide](https://flutter.dev/docs/get-started/install)
- [ ] **Git** (optional but recommended) - [Download](https://git-scm.com/)

## ⚡ Quick Setup (5 Minutes)

### Step 1: Database Setup (1 minute)

```bash
# Create database
createdb onconutri

# Initialize schema
psql -U postgres -d onconutri -f backend/database/schema.sql

# (Optional) Load sample data
psql -U postgres -d onconutri -f backend/database/seeds/sample_data.sql
```

### Step 2: Backend API Setup (2 minutes)

```bash
# Navigate to Node.js backend
cd backend/node_server

# Install dependencies
npm install

# Create environment file
copy .env.example .env
# Edit .env with your database credentials

# Start the server
npm start
```

The API should now be running at `http://localhost:3000`

### Step 3: ML Service Setup (2 minutes)

Open a new terminal:

```bash
# Navigate to FastAPI ML service
cd backend/fastapi_ml

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Mac/Linux:
# source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create logs directory
mkdir logs

# Start the service
python main.py
```

The ML service should now be running at `http://localhost:8000`

### Step 4: Frontend Setup (Flutter will download packages)

Open another terminal:

```bash
# Navigate to frontend
cd frontend

# Get dependencies
flutter pub get

# Run the app (connects to emulator/device)
flutter run
```

## ✅ Verify Installation

### Check Backend API
```bash
curl http://localhost:3000/health
# Should return: {"status": "OK", "message": "OncoNutri+ API is running"}
```

### Check ML Service
```bash
curl http://localhost:8000/health
# Should return: {"status": "healthy"}
```

### Check Database
```bash
psql -U postgres -d onconutri -c "SELECT COUNT(*) FROM users;"
# Should return: count (0 or more if sample data loaded)
```

## 🐳 Alternative: Docker Setup (Easiest!)

If you have Docker installed:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

This will start:
- PostgreSQL on port 5432
- Node.js API on port 3000
- FastAPI ML service on port 8000
- pgAdmin on port 5050 (optional database UI)

## 📱 Test the Application

### 1. Create a Test User

```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }'
```

Save the returned token for next steps.

### 2. Create Patient Profile

```bash
curl -X POST http://localhost:3000/api/patient/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "age": 45,
    "weight": 70.5,
    "cancer_type": "Breast Cancer",
    "stage": "Stage II",
    "allergies": "peanuts",
    "other_conditions": ""
  }'
```

### 3. Get Diet Recommendation

```bash
curl -X GET http://localhost:3000/api/diet/recommendation \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 🎨 Access Points

After setup, you can access:

- **Mobile App**: Running on your emulator/device
- **API Documentation**: `http://localhost:8000/docs` (ML Service Swagger UI)
- **pgAdmin**: `http://localhost:5050` (if using Docker, credentials in docker-compose.yml)
- **Health Checks**:
  - API: `http://localhost:3000/health`
  - ML: `http://localhost:8000/health`

## 🔧 Troubleshooting

### Database Connection Issues

**Problem**: Can't connect to PostgreSQL

**Solutions**:
1. Ensure PostgreSQL is running: `pg_isready`
2. Check credentials in `.env` file
3. Verify database exists: `psql -l`
4. Check firewall settings

### Port Already in Use

**Problem**: Port 3000 or 8000 already in use

**Solutions**:
1. Change port in `.env` or `main.py`
2. Kill process using port:
   ```bash
   # Windows
   netstat -ano | findstr :3000
   taskkill /PID <PID> /F
   
   # Mac/Linux
   lsof -ti:3000 | xargs kill -9
   ```

### Flutter Build Issues

**Problem**: Flutter dependencies not installing

**Solutions**:
1. Run `flutter doctor` to check setup
2. Update Flutter: `flutter upgrade`
3. Clear cache: `flutter clean && flutter pub get`
4. Check internet connection

### API Returns 401

**Problem**: Authorization errors

**Solutions**:
1. Ensure you're using the token from login/signup
2. Check token format: `Bearer <token>`
3. Token may have expired - login again

## 📚 Next Steps

1. **Read Documentation**:
   - Main README: `/README.md`
   - API Docs: `/docs/API.md`
   - Deployment: `/docs/DEPLOYMENT.md`

2. **Explore the Code**:
   - Frontend: `/frontend/lib/`
   - Backend: `/backend/node_server/`
   - ML Service: `/backend/fastapi_ml/`

3. **Try Features**:
   - Create user accounts
   - Add patient profiles
   - Get recommendations
   - Track progress

4. **Customize**:
   - Modify UI in Flutter
   - Add API endpoints
   - Enhance ML model
   - Add more languages

## 🎓 Learning Resources

- **Flutter**: https://flutter.dev/docs
- **Node.js**: https://nodejs.org/docs
- **FastAPI**: https://fastapi.tiangolo.com/
- **PostgreSQL**: https://postgresql.org/docs

## 🆘 Getting Help

- Check `/docs` folder for detailed documentation
- Review error logs in console
- Search existing GitHub issues
- Create new issue with:
  - Error message
  - Steps to reproduce
  - Environment details

## 🎉 You're All Set!

The OncoNutri+ application is now running locally. Start exploring and building!

---

**Remember**: This is a healthcare application. Always consult medical professionals before making dietary changes.
