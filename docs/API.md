# OncoNutri+ API Documentation

Complete API reference for the OncoNutri+ application.

## Base URLs

- **Node.js API**: `http://localhost:3000/api`
- **ML Service**: `http://localhost:8000`

## Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

---

## Authentication Endpoints

### POST /api/auth/signup

Create a new user account.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "language_preference": "en"
}
```

**Response (201):**
```json
{
  "message": "User created successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "language_preference": "en"
  }
}
```

### POST /api/auth/login

Login to existing account.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "language_preference": "en"
  }
}
```

### POST /api/auth/logout

Logout current user.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "message": "Logout successful"
}
```

---

## User Management

### GET /api/user/profile

Get current user's profile.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "language_preference": "en",
  "created_at": "2025-11-16T10:30:00Z",
  "updated_at": "2025-11-16T10:30:00Z"
}
```

### PUT /api/user/profile

Update user profile.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "name": "John Updated",
  "language_preference": "hi"
}
```

**Response (200):**
```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": 1,
    "name": "John Updated",
    "email": "john@example.com",
    "language_preference": "hi",
    "updated_at": "2025-11-16T11:00:00Z"
  }
}
```

### DELETE /api/user/account

Delete user account permanently.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "message": "Account deleted successfully"
}
```

---

## Patient Profile

### POST /api/patient/profile

Create patient medical profile.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "age": 45,
  "weight": 70.5,
  "cancer_type": "Breast Cancer",
  "stage": "Stage II",
  "allergies": "peanuts, shellfish",
  "other_conditions": "diabetes"
}
```

**Response (201):**
```json
{
  "message": "Profile created successfully",
  "profile": {
    "id": 1,
    "user_id": 1,
    "age": 45,
    "weight": 70.5,
    "cancer_type": "Breast Cancer",
    "stage": "Stage II",
    "allergies": "peanuts, shellfish",
    "other_conditions": "diabetes",
    "created_at": "2025-11-16T10:30:00Z",
    "updated_at": "2025-11-16T10:30:00Z"
  }
}
```

### GET /api/patient/profile

Get patient profile.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "id": 1,
  "user_id": 1,
  "age": 45,
  "weight": 70.5,
  "cancer_type": "Breast Cancer",
  "stage": "Stage II",
  "allergies": "peanuts, shellfish",
  "other_conditions": "diabetes",
  "created_at": "2025-11-16T10:30:00Z",
  "updated_at": "2025-11-16T10:30:00Z"
}
```

### PUT /api/patient/profile

Update patient profile.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "weight": 72.0,
  "stage": "Stage III"
}
```

**Response (200):**
```json
{
  "message": "Profile updated successfully",
  "profile": {
    "id": 1,
    "user_id": 1,
    "age": 45,
    "weight": 72.0,
    "cancer_type": "Breast Cancer",
    "stage": "Stage III",
    "allergies": "peanuts, shellfish",
    "other_conditions": "diabetes",
    "updated_at": "2025-11-16T11:00:00Z"
  }
}
```

---

## Diet Recommendations

### GET /api/diet/recommendation

Get diet recommendation for patient. Returns cached if recent (< 24 hours), otherwise generates new.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "id": 1,
  "patient_id": 1,
  "recommendation": {
    "breakfast": [
      "Greek yogurt with berries and honey",
      "Scrambled eggs with whole wheat toast",
      "Oatmeal with nuts and banana"
    ],
    "lunch": [
      "Grilled chicken with quinoa and vegetables",
      "Lentil soup with whole grain bread",
      "Baked salmon with sweet potato"
    ],
    "dinner": [
      "Grilled chicken breast with steamed broccoli",
      "Chicken curry with brown rice",
      "Mixed vegetable khichdi"
    ],
    "snacks": [
      "Fresh fruit salad",
      "Mixed nuts",
      "Hummus with vegetables",
      "Greek yogurt"
    ],
    "notes": "Stay hydrated. Include antioxidant-rich foods. Consult your oncologist."
  },
  "created_at": "2025-11-16T10:30:00Z"
}
```

### POST /api/diet/recommendation/refresh

Force generate new diet recommendation.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "id": 2,
  "patient_id": 1,
  "recommendation": { ... },
  "created_at": "2025-11-16T12:00:00Z"
}
```

### GET /api/diet/history

Get all past diet recommendations.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
[
  {
    "id": 2,
    "patient_id": 1,
    "recommendation": { ... },
    "created_at": "2025-11-16T12:00:00Z"
  },
  {
    "id": 1,
    "patient_id": 1,
    "recommendation": { ... },
    "created_at": "2025-11-16T10:30:00Z"
  }
]
```

---

## Progress Tracking

### GET /api/progress/history

Get all progress entries.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
[
  {
    "id": 1,
    "patient_id": 1,
    "date": "2025-11-16",
    "adherence_score": 85,
    "notes": "Followed diet plan well today"
  },
  {
    "id": 2,
    "patient_id": 1,
    "date": "2025-11-15",
    "adherence_score": 90,
    "notes": "Great day, all meals on track"
  }
]
```

### POST /api/progress/add

Add new progress entry.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "date": "2025-11-16",
  "adherence_score": 85,
  "notes": "Followed diet plan well today"
}
```

**Response (201):**
```json
{
  "message": "Progress entry added successfully",
  "entry": {
    "id": 1,
    "patient_id": 1,
    "date": "2025-11-16",
    "adherence_score": 85,
    "notes": "Followed diet plan well today"
  }
}
```

### PUT /api/progress/:id

Update existing progress entry.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "adherence_score": 90,
  "notes": "Updated notes"
}
```

**Response (200):**
```json
{
  "message": "Progress entry updated successfully",
  "entry": {
    "id": 1,
    "patient_id": 1,
    "date": "2025-11-16",
    "adherence_score": 90,
    "notes": "Updated notes"
  }
}
```

### DELETE /api/progress/:id

Delete progress entry.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**
```json
{
  "message": "Progress entry deleted successfully"
}
```

---

## ML Service Endpoints

### GET /health

Health check endpoint.

**Response (200):**
```json
{
  "status": "healthy"
}
```

### POST /recommend

Generate diet recommendation based on patient data.

**Request Body:**
```json
{
  "age": 45,
  "weight": 70.5,
  "cancer_type": "Breast Cancer",
  "stage": "Stage II",
  "allergies": "peanuts, shellfish",
  "other_conditions": "diabetes"
}
```

**Response (200):**
```json
{
  "breakfast": [
    "Greek yogurt with berries and honey",
    "Scrambled eggs with whole wheat toast",
    "Oatmeal with nuts and banana"
  ],
  "lunch": [
    "Grilled chicken with quinoa and vegetables",
    "Lentil soup with whole grain bread",
    "Baked salmon with sweet potato"
  ],
  "dinner": [
    "Grilled chicken breast with steamed broccoli",
    "Chicken curry with brown rice",
    "Mixed vegetable khichdi"
  ],
  "snacks": [
    "Fresh fruit salad",
    "Mixed nuts (almonds, walnuts, cashews)",
    "Hummus with carrot and cucumber sticks",
    "Greek yogurt with berries"
  ],
  "notes": "Stay hydrated - drink at least 8 glasses of water daily. Include foods rich in antioxidants like berries and leafy greens. Always consult with your oncologist before making major dietary changes."
}
```

### POST /feedback

Submit feedback for model improvement.

**Request Body:**
```json
{
  "patient_id": 1,
  "recommendation_id": 1,
  "rating": 5,
  "comments": "Very helpful recommendations"
}
```

**Response (200):**
```json
{
  "message": "Feedback recorded successfully"
}
```

---

## Error Responses

All endpoints may return these error responses:

### 400 Bad Request
```json
{
  "error": "Invalid input data"
}
```

### 401 Unauthorized
```json
{
  "error": "Access token required"
}
```

### 403 Forbidden
```json
{
  "error": "Invalid or expired token"
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 409 Conflict
```json
{
  "error": "User already exists"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

### 503 Service Unavailable
```json
{
  "error": "Unable to generate recommendation at this time"
}
```

---

## Rate Limiting

*Coming soon*

- 100 requests per 15 minutes per IP
- 1000 requests per hour per user

---

## Testing with cURL

### Sign up
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"password123"}'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

### Get recommendation (with token)
```bash
curl -X GET http://localhost:3000/api/diet/recommendation \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## SDKs and Client Libraries

*Coming soon*

- JavaScript/TypeScript SDK
- Python SDK
- Dart/Flutter package

---

For questions or support, contact: api-support@onconutri.com
