# OncoNutri+ Node.js Backend

Node.js + Express backend server for OncoNutri+ application.

## Features

- RESTful API endpoints
- JWT-based authentication
- PostgreSQL database integration
- User and patient profile management
- Diet recommendation routing to ML service
- Progress tracking and analytics
- Comprehensive logging with Winston

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- PostgreSQL (v13 or higher)
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Set up the database:
```bash
# Run the SQL schema file in PostgreSQL
psql -U postgres -d onconutri -f ../database/schema.sql
```

4. Start the server:
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Create new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `POST /api/auth/refresh-token` - Refresh JWT token

### User Management
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update user profile
- `DELETE /api/user/account` - Delete user account

### Patient Profile
- `POST /api/patient/profile` - Create patient profile
- `GET /api/patient/profile` - Get patient profile
- `PUT /api/patient/profile` - Update patient profile

### Diet Recommendations
- `GET /api/diet/recommendation` - Get diet recommendation
- `POST /api/diet/recommendation/refresh` - Force refresh recommendation
- `GET /api/diet/history` - Get recommendation history

### Progress Tracking
- `GET /api/progress/history` - Get progress history
- `POST /api/progress/add` - Add progress entry
- `PUT /api/progress/:id` - Update progress entry
- `DELETE /api/progress/:id` - Delete progress entry

## Project Structure

```
node_server/
├── app.js                    # Entry point
├── config/                   # Configuration files
│   └── database.js
├── routes/                   # API routes
├── controllers/              # Request handlers
├── utils/                    # Utilities and middleware
└── package.json
```

## Environment Variables

See `.env.example` for required environment variables.

## License

This project is part of the OncoNutri+ healthcare application.
