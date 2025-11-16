# OncoNutri+ Complete Project Structure

This document provides a comprehensive overview of the complete project structure.

## 📁 Project Tree

```
OncoNutri+/
│
├── README.md                      # Main project documentation
├── LICENSE                        # MIT License
├── CHANGELOG.md                   # Version history and changes
├── CONTRIBUTING.md                # Contribution guidelines
├── .gitignore                     # Git ignore rules
├── docker-compose.yml             # Docker orchestration
├── OncoNutri_Project_Structure.txt  # Original requirements
│
├── frontend/                      # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart              # App entry point
│   │   ├── routes/
│   │   │   └── app_routes.dart    # Navigation routes
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── patient_profile_screen.dart
│   │   │   ├── diet_recommendation_screen.dart
│   │   │   └── progress_history_screen.dart
│   │   ├── widgets/
│   │   │   ├── custom_button.dart
│   │   │   └── custom_text_field.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── patient_profile.dart
│   │   │   ├── diet_recommendation.dart
│   │   │   └── progress_entry.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── notification_service.dart
│   │   │   └── cache_service.dart
│   │   ├── utils/
│   │   │   ├── constants.dart
│   │   │   └── helpers.dart
│   │   └── l10n/                  # Internationalization
│   │       ├── app_en.arb         # English translations
│   │       ├── app_hi.arb         # Hindi translations
│   │       └── app_es.arb         # Spanish translations
│   ├── pubspec.yaml               # Flutter dependencies
│   ├── README.md                  # Frontend documentation
│   └── .gitignore
│
├── backend/                       # Backend Services
│   │
│   ├── node_server/               # Node.js + Express API
│   │   ├── app.js                 # Server entry point
│   │   ├── config/
│   │   │   └── database.js        # Database configuration
│   │   ├── routes/
│   │   │   ├── authRoutes.js      # Authentication routes
│   │   │   ├── userRoutes.js      # User management routes
│   │   │   ├── dietRoutes.js      # Diet recommendation routes
│   │   │   ├── patientRoutes.js   # Patient profile routes
│   │   │   └── progressRoutes.js  # Progress tracking routes
│   │   ├── controllers/
│   │   │   ├── authController.js
│   │   │   ├── userController.js
│   │   │   ├── patientController.js
│   │   │   ├── dietController.js
│   │   │   └── progressController.js
│   │   ├── utils/
│   │   │   ├── authMiddleware.js  # JWT authentication
│   │   │   ├── asyncHandler.js    # Async error handling
│   │   │   ├── errorHandler.js    # Error middleware
│   │   │   └── logger.js          # Winston logger
│   │   ├── package.json           # Node.js dependencies
│   │   ├── .env.example           # Environment template
│   │   ├── Dockerfile             # Docker configuration
│   │   ├── .dockerignore
│   │   ├── README.md
│   │   └── .gitignore
│   │
│   ├── fastapi_ml/                # FastAPI ML Service
│   │   ├── main.py                # FastAPI entry point
│   │   ├── models/
│   │   │   └── recommender.py     # Diet recommendation model
│   │   ├── utils/
│   │   │   ├── preprocessor.py    # Data preprocessing
│   │   │   └── logger.py          # Python logger
│   │   ├── requirements.txt       # Python dependencies
│   │   ├── .env.example           # Environment template
│   │   ├── Dockerfile             # Docker configuration
│   │   ├── .dockerignore
│   │   ├── README.md
│   │   └── .gitignore
│   │
│   └── database/                  # PostgreSQL Database
│       ├── schema.sql             # Complete database schema
│       ├── migrations/
│       │   ├── V1__initial_schema.sql
│       │   └── V2__add_patient_summary_view.sql
│       ├── seeds/
│       │   └── sample_data.sql    # Test data
│       └── README.md              # Database documentation
│
└── docs/                          # Documentation
    ├── API.md                     # Complete API reference
    └── DEPLOYMENT.md              # Deployment guide
```

## 📊 Project Statistics

### Frontend (Flutter)
- **Screens**: 6 (Splash, Login, Signup, Profile, Recommendations, History)
- **Widgets**: 2 reusable components
- **Models**: 4 data models
- **Services**: 3 (API, Notifications, Cache)
- **Languages**: 3 (English, Hindi, Spanish)
- **Lines of Code**: ~2,000+

### Backend (Node.js)
- **Controllers**: 5
- **Routes**: 5 route groups
- **Endpoints**: ~20 API endpoints
- **Middleware**: 3
- **Dependencies**: 9 major packages
- **Lines of Code**: ~1,500+

### ML Service (FastAPI)
- **Models**: 1 recommender system
- **Utilities**: 2
- **Endpoints**: 3
- **Dependencies**: 8+ packages
- **Lines of Code**: ~800+

### Database (PostgreSQL)
- **Tables**: 5 main tables
- **Views**: 1 summary view
- **Indexes**: 15+ indexes
- **Migrations**: 2 migration scripts
- **Triggers**: 2 update triggers

## 🔑 Key Features Implemented

### ✅ Authentication & Authorization
- User registration and login
- JWT-based authentication
- Password hashing with bcrypt
- Token refresh mechanism

### ✅ Patient Management
- Comprehensive patient profiles
- Medical history tracking
- Cancer type and stage tracking
- Allergy management

### ✅ Diet Recommendations
- ML-powered personalized recommendations
- Cancer-type specific meal plans
- Allergen filtering
- BMI-based adjustments
- Meal categorization (breakfast, lunch, dinner, snacks)

### ✅ Progress Tracking
- Daily adherence scores
- Historical progress data
- Notes and observations
- Analytics logging

### ✅ Multilingual Support
- English, Hindi, Spanish
- Easy to add more languages
- Complete translation coverage

### ✅ Offline Capabilities
- Local caching with SharedPreferences
- Offline profile access
- Cached recommendations

### ✅ Notifications
- Meal reminders
- Custom notification scheduling
- Background notifications

### ✅ Security
- Password hashing
- JWT authentication
- SQL injection prevention
- Input validation
- CORS configuration

## 📦 Dependencies Summary

### Flutter Dependencies
```yaml
- provider: ^6.1.1              # State management
- http: ^1.1.0                  # HTTP requests
- dio: ^5.4.0                   # Advanced HTTP
- shared_preferences: ^2.2.2    # Local storage
- flutter_local_notifications   # Push notifications
- intl: ^0.18.1                 # Internationalization
```

### Node.js Dependencies
```json
- express: ^4.18.2              # Web framework
- pg: ^8.11.3                   # PostgreSQL client
- bcrypt: ^5.1.1                # Password hashing
- jsonwebtoken: ^9.0.2          # JWT authentication
- cors: ^2.8.5                  # CORS middleware
- helmet: ^7.1.0                # Security headers
- morgan: ^1.10.0               # HTTP logger
- winston: ^3.11.0              # Application logger
```

### Python Dependencies
```
- fastapi==0.104.1              # Web framework
- uvicorn==0.24.0               # ASGI server
- pydantic==2.5.0               # Data validation
- numpy==1.24.3                 # Numerical computing
- pandas==2.0.3                 # Data manipulation
- scikit-learn==1.3.2           # Machine learning
```

## 🗄️ Database Schema

### Tables
1. **users** - User accounts and authentication
2. **patient_profiles** - Medical information
3. **diet_recommendations** - Generated meal plans
4. **progress_history** - Adherence tracking
5. **analytics_logs** - Usage analytics

### Relationships
- users 1:1 patient_profiles
- patient_profiles 1:N diet_recommendations
- patient_profiles 1:N progress_history
- patient_profiles 1:N analytics_logs

## 🚀 Deployment Options

### 1. Docker Deployment
- Complete docker-compose setup
- PostgreSQL, Node.js, FastAPI containers
- Easy to deploy and scale

### 2. Cloud Deployment
- AWS: EC2 + RDS
- Google Cloud: Cloud Run + Cloud SQL
- DigitalOcean: Droplets + Managed Database
- Azure: App Service + Azure Database

### 3. Mobile App Deployment
- Google Play Store (Android)
- Apple App Store (iOS)
- Flutter Web (future)

## 📖 Documentation Files

1. **README.md** - Main project overview
2. **docs/API.md** - Complete API documentation
3. **docs/DEPLOYMENT.md** - Deployment instructions
4. **CONTRIBUTING.md** - Contribution guidelines
5. **CHANGELOG.md** - Version history
6. **LICENSE** - MIT License
7. **Component READMEs** - Specific documentation for each component

## 🎯 Next Steps

### Immediate
1. Install Git and commit the project
2. Set up local development environment
3. Run database migrations
4. Test all API endpoints
5. Build and test Flutter app

### Short-term
1. Implement comprehensive testing
2. Add CI/CD pipeline
3. Deploy to staging environment
4. Conduct security audit
5. Optimize performance

### Long-term
1. Train actual ML models
2. Add advanced analytics
3. Implement healthcare provider portal
4. Add community features
5. Deploy to production
6. Submit to app stores

## 🛠️ Development Commands

### Backend Setup
```bash
# Node.js
cd backend/node_server
npm install
npm start

# FastAPI
cd backend/fastapi_ml
pip install -r requirements.txt
python main.py

# Database
createdb onconutri
psql -U postgres -d onconutri -f backend/database/schema.sql
```

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

### Docker
```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
```

## 📞 Support & Contact

- **Email**: support@onconutri.com
- **Documentation**: See /docs folder
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions

---

**Project Status**: ✅ Complete Structure Built
**Version**: 1.0.0
**Last Updated**: November 16, 2025
