# OncoNutri+ Database

PostgreSQL database schema and migrations for the OncoNutri+ application.

## Overview

This directory contains all database-related files including:
- Complete schema definitions
- Migration scripts
- Seed data for testing
- Backup and restore scripts

## Database Structure

### Tables

1. **users**
   - User authentication and profile information
   - Fields: id, name, email, password_hash, language_preference, timestamps

2. **patient_profiles**
   - Detailed patient medical information
   - Fields: id, user_id, age, weight, cancer_type, stage, allergies, other_conditions, timestamps

3. **diet_recommendations**
   - ML-generated diet recommendations
   - Fields: id, patient_id, recommendation (JSONB), created_at

4. **progress_history**
   - Patient adherence tracking
   - Fields: id, patient_id, date, adherence_score, notes

5. **analytics_logs**
   - Application usage analytics
   - Fields: id, patient_id, action, metadata (JSONB), timestamp

### Views

- **patient_summary**: Aggregated view of patient data with statistics

## Setup Instructions

### Prerequisites

- PostgreSQL 13 or higher
- psql command-line tool

### Initial Setup

1. Create database:
```bash
createdb onconutri
```

2. Run schema:
```bash
psql -U postgres -d onconutri -f schema.sql
```

3. (Optional) Insert seed data:
```bash
psql -U postgres -d onconutri -f seeds/sample_data.sql
```

### Using Migrations

Migrations are located in the `migrations/` directory and should be run in order:

```bash
# Run migration 1
psql -U postgres -d onconutri -f migrations/V1__initial_schema.sql

# Run migration 2
psql -U postgres -d onconutri -f migrations/V2__add_patient_summary_view.sql
```

## Database Configuration

### Environment Variables

```env
DB_USER=postgres
DB_HOST=localhost
DB_NAME=onconutri
DB_PASSWORD=your_password
DB_PORT=5432
```

### Connection String

```
postgresql://postgres:password@localhost:5432/onconutri
```

## Common Queries

### Get user with profile
```sql
SELECT u.*, pp.* 
FROM users u
LEFT JOIN patient_profiles pp ON u.id = pp.user_id
WHERE u.email = 'user@example.com';
```

### Get latest recommendation for patient
```sql
SELECT dr.* 
FROM diet_recommendations dr
JOIN patient_profiles pp ON dr.patient_id = pp.id
WHERE pp.user_id = 1
ORDER BY dr.created_at DESC
LIMIT 1;
```

### Calculate average adherence
```sql
SELECT 
    pp.id,
    u.name,
    AVG(ph.adherence_score) as avg_score
FROM patient_profiles pp
JOIN users u ON pp.user_id = u.id
JOIN progress_history ph ON ph.patient_id = pp.id
GROUP BY pp.id, u.name;
```

## Backup and Restore

### Backup
```bash
pg_dump -U postgres onconutri > backup_$(date +%Y%m%d).sql
```

### Restore
```bash
psql -U postgres onconutri < backup_20251116.sql
```

## Indexes

All tables are optimized with appropriate indexes:
- B-tree indexes for primary keys and foreign keys
- GIN indexes for JSONB columns
- Composite indexes for common query patterns

## Security

- All passwords are hashed using bcrypt
- Foreign keys enforce referential integrity
- CASCADE delete ensures data consistency
- Proper indexes prevent performance issues
- Prepared statements prevent SQL injection

## Maintenance

### Vacuum Database
```sql
VACUUM ANALYZE;
```

### Check Table Sizes
```sql
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Monitor Active Connections
```sql
SELECT * FROM pg_stat_activity WHERE datname = 'onconutri';
```

## License

This project is part of the OncoNutri+ healthcare application.
