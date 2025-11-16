# OncoNutri+ Development Setup Guide

Follow these steps to get your development environment running!

## 📋 Prerequisites Checklist

### Required Software:
- [x] Git - ✅ Installed
- [ ] PostgreSQL 13+ - **NEED TO INSTALL**
- [ ] Node.js 16+ - **NEED TO CHECK**
- [ ] Python 3.8+ - **NEED TO CHECK**
- [ ] Flutter SDK 3.0+ - **NEED TO CHECK**

---

## 🗄️ Step 1: Install PostgreSQL

### Windows Installation:
1. Download from: https://www.postgresql.org/download/windows/
2. Run the installer
3. Default port: 5432
4. Set a password (remember it!)
5. Add to PATH during installation

### Verify Installation:
```powershell
psql --version
```

### Create Database:
```powershell
# Connect to PostgreSQL
psql -U postgres

# In psql prompt:
CREATE DATABASE onconutri;
\q
```

### Initialize Schema:
```powershell
cd C:\OncoNutri+
psql -U postgres -d onconutri -f backend/database/schema.sql
```

### (Optional) Load Sample Data:
```powershell
psql -U postgres -d onconutri -f backend/database/seeds/sample_data.sql
```

---

## 📦 Step 2: Install Node.js Backend

### Install Node.js:
1. Download from: https://nodejs.org/ (LTS version)
2. Verify: `node --version` (should be v16+)

### Setup Backend:
```powershell
cd C:\OncoNutri+\backend\node_server

# Install dependencies
npm install

# Create environment file
copy .env.example .env

# Edit .env file with your settings:
# - DB_PASSWORD=your_postgres_password
# - JWT_SECRET=your-secret-key

# Start the server
npm start
```

**Expected Output:**
```
Server is running on port 3000
PostgreSQL connected successfully
```

**Test API:**
```powershell
curl http://localhost:3000/health
```

---

## 🤖 Step 3: Install Python ML Service

### Install Python:
1. Download from: https://python.org/ (3.8+)
2. ✅ Check "Add to PATH"
3. Verify: `python --version`

### Setup ML Service:
```powershell
cd C:\OncoNutri+\backend\fastapi_ml

# Create virtual environment
python -m venv venv

# Activate it
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create logs directory
mkdir logs

# Start the service
python main.py
```

**Expected Output:**
```
INFO: Uvicorn running on http://0.0.0.0:8000
```

**Test ML Service:**
```powershell
curl http://localhost:8000/health
```

---

## 📱 Step 4: Install Flutter Frontend

### Install Flutter:
1. Download: https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter`
3. Add to PATH: `C:\flutter\bin`
4. Run: `flutter doctor`

### Setup Frontend:
```powershell
cd C:\OncoNutri+\frontend

# Get dependencies
flutter pub get

# Update API URL if needed (in lib/utils/constants.dart)
# static const String apiBaseUrl = 'http://localhost:3000/api';

# Connect device/emulator and run
flutter run
```

---

## 🐳 Alternative: Use Docker (Easier!)

If you have Docker Desktop installed:

```powershell
cd C:\OncoNutri+

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

This starts:
- PostgreSQL on port 5432
- Node.js API on port 3000
- ML Service on port 8000
- pgAdmin on port 5050

---

## ✅ Verification Checklist

Run these commands to verify everything works:

```powershell
# Check PostgreSQL
psql -U postgres -d onconutri -c "SELECT COUNT(*) FROM users;"

# Check Node.js API
curl http://localhost:3000/health

# Check ML Service
curl http://localhost:8000/health

# Check Flutter
flutter doctor
```

---

## 🧪 Quick Test Flow

### 1. Create Test User:
```powershell
curl -X POST http://localhost:3000/api/auth/signup `
  -H "Content-Type: application/json" `
  -d '{\"name\":\"Test User\",\"email\":\"test@example.com\",\"password\":\"password123\"}'
```

### 2. Save the token from response

### 3. Create Patient Profile:
```powershell
curl -X POST http://localhost:3000/api/patient/profile `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer YOUR_TOKEN_HERE" `
  -d '{\"age\":45,\"weight\":70.5,\"cancer_type\":\"Breast Cancer\",\"stage\":\"Stage II\"}'
```

### 4. Get Recommendation:
```powershell
curl http://localhost:3000/api/diet/recommendation `
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🆘 Troubleshooting

### Port Already in Use:
```powershell
# Find process on port
netstat -ano | findstr :3000

# Kill process
taskkill /PID <PID> /F
```

### PostgreSQL Connection Issues:
- Check if PostgreSQL service is running
- Verify password in .env file
- Check firewall settings

### Python Module Not Found:
```powershell
# Ensure virtual environment is activated
.\venv\Scripts\activate

# Reinstall requirements
pip install -r requirements.txt
```

---

## 📚 Additional Resources

- **Project Documentation**: `/README.md`
- **API Reference**: `/docs/API.md`
- **Database Docs**: `/backend/database/README.md`
- **Quick Start**: `/QUICKSTART.md`

---

## 🎯 Next Steps After Setup:

1. ✅ Verify all services are running
2. 📱 Test the Flutter app on emulator
3. 🧪 Run the test API calls
4. 📖 Read the API documentation
5. 💻 Start developing!

---

**Need Help?** Check the documentation files or create an issue on GitHub!
