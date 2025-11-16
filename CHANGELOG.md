# Changelog

All notable changes to the OncoNutri+ project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-16

### Added
- Initial project structure
- Flutter mobile application
  - User authentication (login/signup)
  - Patient profile management
  - Diet recommendation display
  - Progress tracking
  - Multilingual support (English, Hindi, Spanish)
  - Push notifications
  - Offline caching
- Node.js backend API
  - RESTful API endpoints
  - JWT authentication
  - PostgreSQL integration
  - User management
  - Patient profile CRUD
  - Progress tracking endpoints
- FastAPI ML service
  - Diet recommendation engine
  - Rule-based recommendation system
  - Cancer-type specific recommendations
  - Allergen filtering
  - BMI calculations
- PostgreSQL database
  - Complete schema with 5 tables
  - Indexes for performance
  - Triggers for timestamps
  - Sample data seeds
  - Migration scripts
- Documentation
  - Comprehensive README files
  - API documentation
  - Setup instructions
  - Database schema documentation
- Deployment configuration
  - Docker support
  - Docker Compose setup
  - Environment templates

### Security
- Password hashing with bcrypt
- JWT-based authentication
- SQL injection prevention
- Input validation

## [Unreleased]

### Planned
- Advanced ML model integration
- Healthcare provider portal
- Meal planning calendar
- Shopping list generator
- Community support forum
- Advanced analytics dashboard
- Mobile app deployment to app stores
- API rate limiting
- Enhanced security features
- Automated testing suite
- CI/CD pipeline

---

## Version History

### Version Numbering
- **Major version**: Breaking changes
- **Minor version**: New features, backwards compatible
- **Patch version**: Bug fixes, backwards compatible
