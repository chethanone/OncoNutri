# OncoNutri+ Setup Instructions

## 🔐 Security Configuration

### Environment Variables Setup

This project requires several API keys and credentials. **NEVER commit these to git!**

#### 1. Backend Node.js Server

Create `backend/node_server/.env`:
```env
PORT=5000
NODE_ENV=development

# PostgreSQL Database
DB_USER=postgres
DB_HOST=localhost
DB_NAME=onconutri
DB_PASSWORD=your_secure_password_here
DB_PORT=5432

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-minimum-32-characters
JWT_EXPIRY=7d

# ML Service URL
ML_SERVICE_URL=http://localhost:8000
```

#### 2. Backend FastAPI ML Service

Create `backend/fastapi_ml/.env`:
```env
# ML Service Configuration
ML_SERVICE_HOST=0.0.0.0
ML_SERVICE_PORT=8000

# Google Gemini API
GOOGLE_API_KEY=your_google_gemini_api_key_here

# Database (optional)
DATABASE_URL=postgresql://postgres:password@localhost:5432/onconutri
```

#### 3. Frontend Flutter App

Update the API keys in:
- `frontend/lib/services/gemini_service.dart` - Replace `YOUR_GEMINI_API_KEY_HERE`
- `frontend/lib/screens/chatbot_screen.dart` - Replace `YOUR_GEMINI_API_KEY_HERE`

**Note:** In production, these should be moved to secure storage or environment configuration.

### Getting API Keys

#### Google Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Copy and use in your `.env` files

## 📦 Installation

### Prerequisites
- Node.js (v16+)
- Python (v3.8+)
- PostgreSQL (v12+)
- Flutter (v3.0+)

### Database Setup
1. Install PostgreSQL
2. Create database: `CREATE DATABASE onconutri;`
3. Run migrations: `psql -U postgres -d onconutri -f backend/database/schema.sql`

### Backend Setup
```bash
# Node.js server
cd backend/node_server
npm install
cp .env.example .env
# Edit .env with your credentials
node app.js

# Python ML service
cd backend/fastapi_ml
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your API keys
python main.py
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

## 🚨 Security Checklist

Before pushing to GitHub:
- [ ] All `.env` files are in `.gitignore`
- [ ] No hardcoded API keys in source code
- [ ] Placeholder values in all `.env.example` files
- [ ] Database passwords changed from defaults
- [ ] JWT secret is random and secure (32+ characters)
- [ ] API keys are from personal accounts only

## 📝 Notes

- The `.env` files contain sensitive credentials and should NEVER be committed to version control
- Each developer should create their own `.env` files locally
- Use `.env.example` files as templates
- For production deployment, use environment variables from your hosting platform
