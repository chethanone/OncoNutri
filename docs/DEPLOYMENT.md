# Deployment Guide

This guide covers deploying OncoNutri+ to production environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [Backend Deployment](#backend-deployment)
4. [ML Service Deployment](#ml-service-deployment)
5. [Frontend Deployment](#frontend-deployment)
6. [Docker Deployment](#docker-deployment)
7. [Cloud Deployment](#cloud-deployment)
8. [Monitoring](#monitoring)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

- Domain name with SSL certificate
- Cloud hosting account (AWS, GCP, Azure, or DigitalOcean)
- PostgreSQL database (managed or self-hosted)
- Docker (optional)
- CI/CD pipeline (optional)

## Database Setup

### Production PostgreSQL

1. **Create production database:**
```bash
createdb onconutri_prod
```

2. **Run migrations:**
```bash
psql -U postgres -d onconutri_prod -f backend/database/schema.sql
```

3. **Set up database backups:**
```bash
# Daily backup cron job
0 2 * * * pg_dump -U postgres onconutri_prod > /backup/onconutri_$(date +\%Y\%m\%d).sql
```

4. **Configure connection pooling:**
- Use PgBouncer or similar
- Set max connections appropriately

### Managed Database Options

- **AWS RDS**: PostgreSQL instance
- **Google Cloud SQL**: PostgreSQL
- **Azure Database**: PostgreSQL
- **DigitalOcean Managed Database**

## Backend Deployment

### Node.js API Server

1. **Set environment variables:**
```bash
export NODE_ENV=production
export PORT=3000
export DB_HOST=your-db-host
export DB_NAME=onconutri_prod
export JWT_SECRET=your-secure-secret
export ML_SERVICE_URL=https://ml.yourdomain.com
```

2. **Install dependencies:**
```bash
cd backend/node_server
npm ci --only=production
```

3. **Start with PM2:**
```bash
npm install -g pm2
pm2 start app.js --name onconutri-api
pm2 save
pm2 startup
```

4. **Set up reverse proxy (Nginx):**
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

5. **Enable SSL:**
```bash
sudo certbot --nginx -d api.yourdomain.com
```

## ML Service Deployment

### FastAPI Service

1. **Set environment variables:**
```bash
export ML_SERVICE_PORT=8000
export LOG_LEVEL=INFO
```

2. **Install dependencies:**
```bash
cd backend/fastapi_ml
pip install -r requirements.txt
```

3. **Run with Gunicorn:**
```bash
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000
```

4. **Create systemd service:**
```ini
[Unit]
Description=OncoNutri ML Service
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/onconutri/fastapi_ml
ExecStart=/var/www/onconutri/fastapi_ml/venv/bin/gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

## Frontend Deployment

### Flutter Mobile App

1. **Build for Android:**
```bash
cd frontend
flutter build apk --release
flutter build appbundle --release
```

2. **Build for iOS:**
```bash
flutter build ios --release
```

3. **Deploy to stores:**
- Google Play Store: Upload .aab file
- Apple App Store: Archive and upload via Xcode

4. **Update API endpoints:**
```dart
// In lib/utils/constants.dart
static const String apiBaseUrl = 'https://api.yourdomain.com';
```

## Docker Deployment

### Using Docker Compose

1. **Update docker-compose.yml for production:**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  node_backend:
    build: ./backend/node_server
    environment:
      NODE_ENV: production
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
    restart: always

  ml_service:
    build: ./backend/fastapi_ml
    restart: always
```

2. **Deploy:**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Cloud Deployment

### AWS Deployment

1. **EC2 instances:**
   - t3.medium for API server
   - t3.small for ML service
   - Use Auto Scaling Groups

2. **RDS PostgreSQL:**
   - db.t3.medium instance
   - Multi-AZ for high availability
   - Automated backups enabled

3. **Load Balancer:**
   - Application Load Balancer
   - SSL termination
   - Health checks

4. **S3 for static files**

### Google Cloud Platform

1. **Cloud Run:**
   - Deploy containerized services
   - Auto-scaling
   - Pay per use

2. **Cloud SQL:**
   - Managed PostgreSQL
   - Automatic backups

3. **Cloud Load Balancing**

### DigitalOcean

1. **Droplets:**
   - 2GB RAM minimum
   - Use managed database

2. **App Platform:**
   - Deploy from GitHub
   - Auto-deploy on push

## Monitoring

### Application Monitoring

1. **PM2 Monitoring:**
```bash
pm2 monitor
```

2. **Logs:**
```bash
pm2 logs onconutri-api
```

3. **Health checks:**
```bash
curl http://localhost:3000/health
curl http://localhost:8000/health
```

### Performance Monitoring

- Use New Relic, DataDog, or similar
- Monitor API response times
- Track database queries
- Monitor memory/CPU usage

### Error Tracking

- Sentry for error tracking
- Log aggregation (ELK stack, CloudWatch)

## Security Checklist

- [ ] HTTPS enabled everywhere
- [ ] JWT secrets are strong and rotated
- [ ] Database passwords are secure
- [ ] CORS configured properly
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention
- [ ] XSS protection
- [ ] Regular security updates
- [ ] Backup strategy in place

## Troubleshooting

### Common Issues

1. **Database connection fails:**
   - Check firewall rules
   - Verify credentials
   - Check connection pooling

2. **API returns 502:**
   - Check if service is running
   - Verify reverse proxy config
   - Check logs

3. **ML service timeout:**
   - Increase worker count
   - Add caching layer
   - Optimize model

### Logs Location

- Node.js: `/var/log/onconutri/api.log`
- ML Service: `/var/log/onconutri/ml.log`
- Nginx: `/var/log/nginx/`
- PostgreSQL: `/var/log/postgresql/`

## Backup and Recovery

1. **Database backup:**
```bash
pg_dump onconutri_prod > backup.sql
```

2. **Restore:**
```bash
psql onconutri_prod < backup.sql
```

3. **Automated backups:**
   - Daily full backup
   - Hourly incremental
   - 30-day retention

## Scaling

### Horizontal Scaling

- Load balancer with multiple API servers
- Read replicas for database
- ML service behind load balancer

### Vertical Scaling

- Upgrade server resources as needed
- Monitor resource usage

## Maintenance

- Regular security updates
- Database maintenance (VACUUM, ANALYZE)
- Log rotation
- Certificate renewal
- Dependency updates

---

For questions, contact: devops@onconutri.com
