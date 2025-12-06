# OncoNutri+

A personalized nutrition recommendation platform for cancer patients, combining machine learning with expert nutritional guidelines to help patients make informed dietary choices during their treatment journey.

---

## What This Project Does

OncoNutri+ addresses a critical gap in cancer care: personalized nutrition guidance. Cancer patients often struggle with dietary decisions during treatment—what foods are safe, which ones provide the nutrients they need, and how to manage treatment side effects through diet. This application provides:

- **Personalized food recommendations** based on cancer type, treatment stage, dietary restrictions, and allergies
- **AI-powered meal suggestions** using Google Gemini API for context-aware recommendations
- **Educational video resources** curated from YouTube with quota-managed caching
- **Multi-language support** across 10 Indian languages plus Spanish and English
- **Progress tracking** to monitor dietary intake and nutritional goals
- **Smart allergen detection** to ensure patient safety

The platform doesn't just suggest generic healthy foods—it understands that a breast cancer patient on chemotherapy has different nutritional needs than someone with thyroid cancer in post-treatment recovery.

---

## Architecture

The project follows a three-tier architecture:

```
┌─────────────────────────────────────────────────────┐
│              Flutter Mobile App                     │
│  (Android/iOS - Multi-language UI)                  │
└─────────────────┬───────────────────────────────────┘
                  │
                  ├──────────────┬──────────────────┐
                  ▼              ▼                  ▼
         ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
         │  Node.js    │  │  FastAPI    │  │ PostgreSQL  │
         │   Backend   │  │  ML Service │  │  Database   │
         │  (Port 5000)│  │ (Port 8000) │  │ (Port 5432) │
         └─────────────┘  └─────────────┘  └─────────────┘
                │                │
                └────────┬───────┘
                         ▼
              ┌──────────────────────┐
              │  External APIs       │
              │  - YouTube Data v3   │
              │  - Google Gemini AI  │
              └──────────────────────┘
```

### Components

**Frontend (Flutter)**
- Cross-platform mobile app (Android/iOS)
- 14 intake screens to capture patient profile
- Real-time food recommendations with nutritional information
- Video education library with intelligent caching
- Multi-language localization (10 languages)
- Offline-first architecture with SharedPreferences

**Node.js Backend**
- RESTful API for authentication, patient data, and recommendations
- JWT-based authentication with 7-day token expiry
- Database pooling for efficient PostgreSQL connections
- YouTube video API with quota management (24-hour caching)
- Structured logging with Winston
- CORS-enabled for mobile access

**FastAPI ML Service**
- Hybrid recommendation engine combining:
  - Curated cancer-nutrition database (113 foods)
  - Google Gemini AI for dynamic suggestions
  - FoodData Central database integration (planned)
- Dietary preference filtering (vegetarian/non-vegetarian/vegan)
- Allergen detection and exclusion
- Nutritional scoring based on cancer type
- RESTful endpoints for food search and recommendations

**PostgreSQL Database**
- Patient profiles with medical history
- Dietary intake tracking
- Saved food preferences
- User authentication data
- Normalized schema with proper foreign keys

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile** | Flutter 3.0+ | Cross-platform app development |
| | Dart | Programming language |
| | Provider | State management |
| | flutter_gen for l10n | Internationalization |
| **Backend** | Node.js 16+ | API server runtime |
| | Express.js | Web framework |
| | JWT | Authentication tokens |
| | pg (node-postgres) | PostgreSQL client |
| | axios | HTTP client for external APIs |
| **ML Service** | Python 3.8+ | ML service runtime |
| | FastAPI | Modern async API framework |
| | Google Gemini API | AI-powered recommendations |
| | pandas/numpy | Data processing |
| **Database** | PostgreSQL 13+ | Relational data storage |
| **External APIs** | YouTube Data API v3 | Educational video search |
| | Google Gemini 2.0 | AI food recommendations |

---

## Features

### Patient Intake Flow
- Age and weight tracking with BMI calculation
- Cancer type selection (12 types + custom input)
- Treatment stage identification
- Symptom tracking (10 common symptoms)
- Allergen declaration (16 common allergens)
- Dietary preference (veg/non-veg/vegan)
- Eating ability assessment (5 levels)
- Water intake monitoring

### Food Recommendations
- Context-aware suggestions based on complete patient profile
- Real-time allergen filtering
- Nutritional breakdown (calories, protein, carbs, fats)
- Cancer-specific nutrient recommendations
- Dietary restriction compliance
- Save/unsave favorite foods
- Search functionality across 100+ foods

### Educational Resources
- Curated cancer-nutrition videos from YouTube
- Language-specific video search
- 24-hour response caching to manage API quota
- Automatic fallback to pre-vetted videos
- Category-based organization (Nutrition, Treatment, Wellness)

### Multi-language Support
Languages: English, Hindi, Kannada, Tamil, Telugu, Malayalam, Marathi, Gujarati, Bengali, Punjabi, Spanish

- 354 translation keys covering entire app
- Right-to-left (RTL) support for applicable languages
- Localized cancer types, symptoms, and allergens
- Language-specific video recommendations
- Real-time language switching

### Security & Privacy
- JWT authentication with secure token storage
- Password encryption (bcrypt)
- Environment variable management for secrets
- Input validation on all forms
- SQL injection prevention with parameterized queries
- CORS configured for mobile access only

---

## Installation & Setup

### Prerequisites
- **Flutter SDK** 3.0 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Node.js** 16.x or higher ([Install Node](https://nodejs.org/))
- **Python** 3.8 or higher ([Install Python](https://www.python.org/downloads/))
- **PostgreSQL** 13 or higher ([Install PostgreSQL](https://www.postgresql.org/download/))
- **Android Studio** or **Xcode** (for mobile development)
- **Git** for version control

### Step 1: Clone the Repository
```bash
git clone https://github.com/chethanone/OncoNutri.git
cd OncoNutri+
```

### Step 2: Configure Environment Variables
```bash
# Copy the template
cp .env.example .env

# Edit .env with your credentials
# Required: DB_PASSWORD, YOUTUBE_API_KEY, GOOGLE_API_KEY
```

The `.env` file contains all credentials for the entire project:
- Database connection (host, port, user, password)
- API keys (YouTube, Google Gemini)
- JWT secret for authentication
- Service ports and URLs

**Important:** Never commit the `.env` file to version control. It's already in `.gitignore`.

### Step 3: Setup PostgreSQL Database
```bash
# Create database
createdb onconutri

# Run initial schema
psql -U postgres -d onconutri -f backend/database/schema.sql

# Apply migrations (if needed)
cd backend/database
node run_migration_v5.js
```

Database schema includes:
- `users` - Authentication and basic user info
- `patient_profiles` - Medical and dietary information
- `saved_diet_items` - User-saved food preferences
- `patient_summary_view` - Consolidated patient data view

### Step 4: Install Node.js Backend
```bash
cd backend/node_server
npm install
```

Dependencies:
- express (API framework)
- pg (PostgreSQL client)
- jsonwebtoken (JWT auth)
- bcrypt (password hashing)
- cors (cross-origin support)
- dotenv (environment config)
- winston (logging)
- axios (HTTP client)

### Step 5: Install Python ML Service
```bash
cd backend/fastapi_ml
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt
```

Dependencies:
- fastapi (async API framework)
- uvicorn (ASGI server)
- google-generativeai (Gemini API)
- pandas, numpy (data processing)
- python-dotenv (environment config)

### Step 6: Install Flutter App
```bash
cd frontend
flutter pub get
flutter pub run flutter_gen:build  # Generate localizations
```

Dependencies:
- http (API calls)
- provider (state management)
- shared_preferences (local storage)
- intl (internationalization)
- flutter_localizations (built-in)

---

## Running the Application

You need to run three services simultaneously:

### Terminal 1: Start PostgreSQL
```bash
# PostgreSQL should be running as a service
# Verify with:
psql -U postgres -d onconutri -c "SELECT version();"
```

### Terminal 2: Start Node.js Backend
```bash
cd backend/node_server
node app.js
```
Server runs on `http://localhost:5000`

Endpoints:
- `GET /health` - Health check
- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User login
- `GET /api/dashboard/overview` - Patient dashboard
- `GET /api/recommendations` - Food recommendations
- `GET /api/videos/:cancerType` - Video recommendations

### Terminal 3: Start FastAPI ML Service
```bash
cd backend/fastapi_ml
python main.py
```
Server runs on `http://localhost:8000`

Endpoints:
- `GET /` - Service info
- `POST /recommend` - AI-powered food recommendations
- `GET /search` - Search food database
- `POST /feedback` - Submit recommendation feedback

### Terminal 4: Run Flutter App
```bash
cd frontend

# For Android
flutter run

# For iOS (macOS only)
flutter run -d ios

# For Windows
flutter run -d windows
```

---

## Configuration Guide

### Database Configuration
Edit `.env` in the project root:
```env
DB_HOST=localhost       # Database server
DB_PORT=5432           # PostgreSQL default port
DB_NAME=onconutri      # Database name
DB_USER=postgres       # Database user
DB_PASSWORD=your_password_here  # Your PostgreSQL password
```

### API Keys Setup

**YouTube Data API v3:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable "YouTube Data API v3"
4. Create credentials → API Key
5. Add to `.env`: `YOUTUBE_API_KEY=your_key_here`

**Google Gemini API:**
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create API key
3. Add to `.env`: `GOOGLE_API_KEY=your_key_here`

### JWT Configuration
```env
JWT_SECRET=change-this-to-a-long-random-string
JWT_EXPIRY=7d  # Token validity period
```

Generate a secure JWT secret:
```bash
# Linux/macOS
openssl rand -base64 64

# Windows (PowerShell)
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

---

## Troubleshooting

### Common Issues

**Database Connection Errors**
```
Error: password authentication failed for user "postgres"
```
Solution: Check `.env` file has correct `DB_PASSWORD`. Verify PostgreSQL is running:
```bash
pg_isready -h localhost -p 5432
```

**YouTube API Quota Exceeded**
```
Error: 403 - You have exceeded your quota
```
Solution: The app automatically falls back to pre-vetted videos. Quota resets daily. Check logs for "YouTube API quota used: X/9500"

**Gemini API Key Invalid**
```
Error: 401 - API key not valid
```
Solution:
1. Verify `GOOGLE_API_KEY` in `.env`
2. Check key is enabled at Google AI Studio
3. Ensure Gemini API is enabled for your project

**Port Already in Use**
```
Error: listen EADDRINUSE: address already in use :::5000
```
Solution: Kill process using the port:
```bash
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# macOS/Linux
lsof -ti:5000 | xargs kill -9
```

---

## License

This project is licensed under the MIT License. See `LICENSE` file for details.

---

## Contact & Support

**Developer:** Chethan  
**Repository:** [github.com/chethanone/OncoNutri](https://github.com/chethanone/OncoNutri)

For medical emergencies, always consult a healthcare professional. This app provides nutritional guidance only and is not a substitute for medical advice.

---

**Built with care for cancer patients and their families.**
