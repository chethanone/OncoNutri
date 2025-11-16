# OncoNutri+ 

A comprehensive mobile application for personalized cancer nutrition recommendations powered by machine learning.

## 🌟 Overview

OncoNutri+ is a healthcare application designed to provide personalized dietary recommendations for cancer patients. The application uses machine learning to generate customized meal plans based on:
- Cancer type and stage
- Patient demographics (age, weight)
- Allergies and dietary restrictions
- Other medical conditions

## 🏗️ Architecture

```
OncoNutri+/
├── frontend/              # Flutter mobile application
├── backend/
│   ├── node_server/       # Node.js + Express API server
│   ├── fastapi_ml/        # FastAPI ML service
│   └── database/          # PostgreSQL schema and migrations
└── docs/                  # Additional documentation
```

### Technology Stack

**Frontend:**
- Flutter 3.0+
- Provider for state management
- HTTP/Dio for API calls
- Flutter Local Notifications
- Multilingual support (English, Hindi, Spanish)

**Backend:**
- Node.js + Express (REST API)
- FastAPI (ML service)
- PostgreSQL (Database)
- JWT authentication
- Winston logging

**Machine Learning:**
- Python 3.8+
- scikit-learn
- pandas, numpy
- Rule-based system (placeholder for trained models)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Node.js (v16+)
- Python 3.8+
- PostgreSQL 13+
- Git

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/your-org/onconutri-plus.git
cd onconutri-plus
```

2. **Set up the database:**
```bash
createdb onconutri
psql -U postgres -d onconutri -f backend/database/schema.sql
```

3. **Set up Node.js backend:**
```bash
cd backend/node_server
npm install
cp .env.example .env
# Edit .env with your configuration
npm start
```

4. **Set up FastAPI ML service:**
```bash
cd backend/fastapi_ml
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
python main.py
```

5. **Set up Flutter frontend:**
```bash
cd frontend
flutter pub get
flutter run
```

## 📱 Features

### Current Features
- ✅ User authentication (signup/login)
- ✅ Patient profile management
- ✅ ML-powered diet recommendations
- ✅ Progress tracking with adherence scores
- ✅ Multilingual support
- ✅ Push notifications for meal reminders
- ✅ Offline mode with caching
- ✅ Diet history tracking

### Planned Features
- 📋 Meal planning calendar
- 🛒 Shopping list generation
- 📊 Advanced analytics dashboard
- 👨‍⚕️ Healthcare provider portal
- 🔔 Appointment reminders
- 💬 Community support forum

## 📚 API Documentation

### Node.js Backend API

Base URL: `http://localhost:3000/api`

**Authentication:**
- `POST /auth/signup` - Create new user
- `POST /auth/login` - Login user

**Patient Management:**
- `POST /patient/profile` - Create patient profile
- `GET /patient/profile` - Get patient profile
- `PUT /patient/profile` - Update patient profile

**Diet Recommendations:**
- `GET /diet/recommendation` - Get diet recommendation
- `POST /diet/recommendation/refresh` - Force new recommendation

**Progress Tracking:**
- `GET /progress/history` - Get progress history
- `POST /progress/add` - Add progress entry

### ML Service API

Base URL: `http://localhost:8000`

**Recommendation:**
- `POST /recommend` - Generate diet recommendation

For detailed API documentation, visit:
- Node.js API: `http://localhost:3000/api-docs` (coming soon)
- ML Service: `http://localhost:8000/docs` (Swagger UI)

## 🧪 Testing

### Backend Tests
```bash
cd backend/node_server
npm test
```

### Frontend Tests
```bash
cd frontend
flutter test
```

### ML Service Tests
```bash
cd backend/fastapi_ml
pytest
```

## 🐳 Docker Deployment

### Using Docker Compose
```bash
docker-compose up -d
```

This will start:
- PostgreSQL database
- Node.js backend
- FastAPI ML service
- (Frontend needs to be deployed separately for mobile)

## 📊 Database Schema

Key tables:
- **users**: User authentication data
- **patient_profiles**: Patient medical information
- **diet_recommendations**: Generated meal plans
- **progress_history**: Adherence tracking
- **analytics_logs**: Usage analytics

See `backend/database/README.md` for detailed schema documentation.

## 🔒 Security

- Passwords hashed with bcrypt
- JWT-based authentication
- HTTPS in production
- SQL injection prevention with parameterized queries
- Input validation on all endpoints
- CORS configuration
- Rate limiting (to be implemented)

## 🌍 Internationalization

Supported languages:
- English (en)
- Hindi (hi)
- Spanish (es)

To add a new language, add translation files in `frontend/lib/l10n/`

## 📈 Performance

- Database indexes for fast queries
- Caching for offline support
- Lazy loading of UI components
- Background task handling
- Optimized API responses

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

- **Project Lead**: [Your Name]
- **Backend Developer**: [Name]
- **ML Engineer**: [Name]
- **Mobile Developer**: [Name]

## 📞 Support

For support, email support@onconutri.com or join our Slack channel.

## 🙏 Acknowledgments

- Cancer nutrition guidelines from major oncology institutions
- Open-source communities for amazing tools and libraries
- Beta testers and early adopters

## 📝 Changelog

### Version 1.0.0 (2025-11-16)
- Initial release
- Core features implemented
- Multi-language support
- ML-based recommendations

---

**Note**: This application is intended to complement, not replace, professional medical advice. Always consult with your healthcare provider before making dietary changes.
