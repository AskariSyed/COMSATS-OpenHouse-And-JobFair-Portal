# Docker Setup Guide - Job Fair Portal

This comprehensive guide covers setting up and running the Job Fair Portal using Docker and Docker Compose.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Structure](#project-structure)
3. [Local Development Setup](#local-development-setup)
4. [Production Deployment](#production-deployment)
5. [Docker Commands Reference](#docker-commands-reference)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Docker**: v20.10+ ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose**: v2.0+ (included with Docker Desktop)
- **Git**: For cloning repositories
- **OpenSSL**: For generating secrets (optional)

### System Requirements
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: 10GB free disk space
- **CPU**: 2+ cores recommended

### Check Installation
```bash
docker --version          # Docker version
docker-compose --version  # Docker Compose version
docker ps                 # Test Docker daemon
```

---

## Project Structure

```
jobfair-portal/
├── Backend/                    # .NET 8 ASP.NET Core API
│   ├── Controllers/
│   ├── Services/
│   ├── Dockerfile             # Backend build configuration
│   └── Program.cs
├── admin-portal/              # React admin dashboard
│   ├── src/
│   ├── Dockerfile             # Admin portal build
│   └── vite.config.js
├── company-portal/            # React company dashboard
│   ├── src/
│   ├── Dockerfile             # Company portal build
│   └── vite.config.js
├── student-portal/            # Flutter web student app
│   ├── lib/
│   ├── Dockerfile.web         # Flutter web build
│   └── pubspec.yaml
├── docker-compose.yml         # Main compose file (production base)
├── docker-compose.override.yml # Development overrides
├── docker-compose.prod.yml    # Production configuration
├── nginx.conf                 # Nginx reverse proxy config
├── .env.example              # Environment variables template
└── .dockerignore             # Files to exclude from builds
```

---

## Local Development Setup

### Step 1: Clone and Prepare

```bash
# Navigate to project root
cd jobfair-portal

# Copy environment file
cp .env.example .env

# Edit .env with your development values
# For local development, defaults are usually fine:
# - DB_USER: devuser
# - DB_PASSWORD: devpassword
# - DB_NAME: jobfair_dev
# - API_BASE_URL: http://localhost:5158
```

### Step 2: Build Docker Images

```bash
# Build all images (first time - takes 10-15 minutes)
docker-compose build

# Output:
# [+] Building 12.5s (45/45) FINISHED
# ...
# => Successfully built backend, admin-portal, company-portal, student-portal
```

### Step 3: Start Services

```bash
# Start all services in background
docker-compose up -d

# Watch logs
docker-compose logs -f

# Output:
# postgres_1        | 2024-04-02 06:30:00 ready to accept connections
# backend_1        | info: Application started. Press Ctrl+C to shut down.
# admin-portal_1   | nginx: master process started
```

### Step 4: Verify Services Running

```bash
# Check container status
docker-compose ps

# Expected output:
# NAME                COMMAND                  SERVICE        STATUS       PORTS
# jobfair-postgres    postgres                postgres       Up 2 min     0.0.0.0:5432
# jobfair-backend     dotnet /app/Backend... backend         Up 1 min     0.0.0.0:5158
# jobfair-admin       nginx -g daemon off     admin-portal   Up 1 min     0.0.0.0:3001
# jobfair-company     nginx -g daemon off     company-portal Up 1 min     0.0.0.0:3002
# jobfair-student     nginx -g daemon off     student-portal Up 1 min     0.0.0.0:3003
# jobfair-nginx       nginx -g daemon off     nginx          Up 1 min     0.0.0.0:80
```

### Step 5: Access Applications

```bash
# Admin Portal:       http://localhost:3001
# Company Portal:     http://localhost:3002
# Student Portal:     http://localhost:3003
# Backend API:        http://localhost:5158
# Nginx Proxy:        http://localhost:80
# PostgreSQL:         localhost:5432
```

### Step 6: Database Initialization (First Run Only)

```bash
# Run database migrations
docker-compose exec backend dotnet ef database update

# Or seed sample data
docker-compose exec backend dotnet run --seedData

# Verify database connection
docker-compose exec postgres psql -U devuser -d jobfair_dev -c "SELECT version();"
```

---

## Production Deployment

### Step 1: Prepare Production Environment

```bash
# Generate strong secrets
mkdir -p secrets/

# Generate secure JWT key
openssl rand -base64 32 > secrets/jwt_secret.txt

# Generate secure database password
openssl rand -base64 24 > secrets/db_password.txt

# Update .env for production
cat .env.example > .env.production
# Edit with production values:
# - DB_PASSWORD: (from secrets/db_password.txt)
# - JWT_SECRET_KEY: (from secrets/jwt_secret.txt)
# - API_BASE_URL: https://api.jfair.tech
# - CORS_ALLOWED_ORIGINS: https://admin.jfair.tech,...
```

### Step 2: Build for Production

```bash
# Build with production overrides
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml build

# Output shows build with resource limits applied
```

### Step 3: Deploy to AWS EC2

```bash
# Option 1: Direct deployment to EC2
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml up -d

# Option 2: Push to Docker Hub/ECR then pull
docker tag jobfair-backend:latest your-registry/jobfair-backend:v1.0
docker push your-registry/jobfair-backend:v1.0

# Then on EC2:
docker pull your-registry/jobfair-backend:v1.0
docker-compose up -d
```

### Step 4: Configure SSL/TLS

```bash
# Update nginx.conf for HTTPS
# Add certificate paths to docker-compose.prod.yml
# Volume map: /etc/letsencrypt:/etc/letsencrypt:ro

# Restart Nginx
docker-compose restart nginx

# Verify HTTPS
curl -I https://api.jfair.tech
# Expected: HTTP/2 200
```

### Step 5: Monitor Production

```bash
# View logs
docker-compose logs -f backend

# Check resource usage
docker stats

# Backup database
docker-compose exec postgres pg_dump -U $DB_USER $DB_NAME > backup.sql

# View service health
docker-compose ps
```

---

## Docker Commands Reference

### Basic Commands

```bash
# Start services
docker-compose up -d

# Stop services (keeps containers)
docker-compose stop

# Stop and remove containers
docker-compose down

# Remove everything including volumes (CAUTION: Data loss!)
docker-compose down -v

# View logs
docker-compose logs                 # All services
docker-compose logs backend         # Specific service
docker-compose logs -f backend      # Follow logs
docker-compose logs --tail=50 backend # Last 50 lines
```

### Build Commands

```bash
# Build all images
docker-compose build

# Build specific service
docker-compose build backend

# Build without cache (fresh build)
docker-compose build --no-cache

# Build with build arguments
docker-compose build --build-arg VITE_API_BASE_URL=https://api.jfair.tech
```

### Container Management

```bash
# Execute command in container
docker-compose exec backend bash
docker-compose exec backend dotnet ef database update
docker-compose exec postgres psql -U $DB_USER -d $DB_NAME

# Get container information
docker-compose ps                        # Status
docker-compose info                      # Detailed info
docker inspect jobfair-backend_1        # Full container details

# View resource usage
docker stats

# Restart services
docker-compose restart              # All services
docker-compose restart backend      # Specific service
```

### Network and Connectivity

```bash
# Inspect network
docker network ls
docker network inspect jobfair-network

# Test connectivity between containers
docker-compose exec backend ping postgres
docker-compose exec admin-portal curl http://backend:5158/health

# Check DNS resolution (Docker's embedded DNS)
docker-compose exec backend nslookup postgres
```

### Cleanup Commands

```bash
# Remove unused images, networks, dangling volumes
docker system prune

# Remove everything including unused images
docker system prune -a

# Remove specific image
docker rmi jobfair-backend:latest

# Clear build cache
docker builder prune
```

---

## Troubleshooting

### Issue: Container Won't Start

**Problem**: Backend container exits immediately
```bash
# Check logs
docker-compose logs backend

# Typical causes:
# - Database connection failed
# - Environment variables not set
# - Port already in use
```

**Solution**:
```bash
# Verify database started first
docker-compose logs postgres
# Wait for: "database system is ready to accept connections"

# Restart in correct order
docker-compose down
docker-compose up -d postgres
sleep 5
docker-compose up -d backend

# Check if ports are available
netstat -an | grep 5432  # PostgreSQL
netstat -an | grep 5158  # Backend
netstat -an | grep 3001  # Admin Portal
```

### Issue: Database Connection Refused

**Problem**: `Connection refused: 127.0.0.1:5432`

**Cause**: Services trying to connect via localhost instead of service name

**Solution**:
```bash
# This is WRONG (localhost won't work in Docker):
Server=localhost;Port=5432;...

# This is CORRECT (use service name):
Server=postgres;Port=5432;...

# Verify connection string in docker-compose.yml
docker-compose exec backend cat /app/appSettings.json | grep ConnectionString
```

### Issue: Port Already in Use

**Problem**: `Error response from daemon: bind: address already in use :::5158`

**Solution**:
```bash
# Find what's using the port
netstat -ano | findstr :5158  # Windows
lsof -i :5158                  # Linux/Mac

# Kill process
taskkill /PID <PID> /F         # Windows
kill -9 <PID>                  # Linux/Mac

# Or change port in docker-compose.yml:
# ports:
#   - "5159:5158"  # Map to different external port
```

### Issue: Out of Memory

**Problem**: `Unable to allocate 2.5 GB for an object heap`

**Solution**:
```bash
# Increase Docker memory limit
# - Windows/Mac: Docker Desktop → Settings → Resources → Memory (increase to 8GB)
# - Linux: Ensure sufficient free RAM

# Reduce memory limits in docker-compose.prod.yml:
# deploy:
#   resources:
#     limits:
#       memory: 1G  # Reduce from 2G

# Clear unused containers/images
docker system prune -a
```

### Issue: Slow Performance in Development

**Problem**: Builds take too long, containers run slowly

**Solutions**:
```bash
# 1. Use .dockerignore to exclude unnecessary files
# Already configured, but verify it exists

# 2. Build only changed services
docker-compose build backend  # Instead of build all

# 3. Use development overrides (includes volume mounts for hot reload)
docker-compose -f docker-compose.yml \
               -f docker-compose.override.yml up

# 4. Increase Docker resources allocation
# Similar to memory issue above
```

### Issue: Database Data Not Persisting

**Problem**: Data disappeared after container restart

**Cause**: No volume mapping, data stored in ephemeral container storage

**Solution**:
```bash
# Verify volumes in docker-compose.yml
docker volume ls

# Check volume content
docker volume inspect jobfair_postgres_data
docker inspect jobfair-postgres_1 | grep Mounts

# If volumes missing, recreate:
docker-compose down -v  # Remove all volumes
docker-compose up -d    # Recreate with volumes
```

### Issue: Cannot Access Web UI (Blank Page)

**Problem**: Loading http://localhost:3001 shows nothing

**Check logs**:
```bash
docker-compose logs admin-portal
# Look for: nginx errors, static file not found

# Verify Nginx is serving files
docker-compose exec admin-portal ls -la /usr/share/nginx/html
# Should show: index.html, main.dart.js, etc.

# Test directly
docker-compose exec admin-portal curl -I http://localhost:80
# Should return: 200 OK
```

### Issue: API Calls Return 404

**Problem**: Frontend makes request, backend returns 404

**Diagnosis**:
```bash
# Check if backend is running
docker-compose ps backend

# Verify backend health
docker-compose exec backend curl http://localhost:5158/health

# Check CORS configuration
docker-compose exec backend cat /app/appsettings.json | grep -A5 CORS

# View backend logs
docker-compose logs -f backend
# Look for routing errors
```

---

## Useful Development Tips

### Hot Reload for Frontend

```bash
# For React apps (with docker-compose.override.yml):
docker-compose exec admin-portal npm run dev

# Changes in ./admin-portal/src will auto-reload
```

### Running Database Migrations

```bash
# Create new migration
docker-compose exec backend dotnet ef migrations add "MigrationName"

# Apply migrations
docker-compose exec backend dotnet ef database update

# Revert migration
docker-compose exec backend dotnet ef database update "PreviousMigration"
```

### Backup and Restore Database

```bash
# Backup
docker-compose exec postgres pg_dump -U $DB_USER $DB_NAME > backup.sql

# Restore
docker-compose exec -T postgres psql -U $DB_USER $DB_NAME < backup.sql

# Compressed backup (smaller size)
docker-compose exec postgres pg_dump -Fc -U $DB_USER $DB_NAME > backup.dump
docker-compose exec -T postgres pg_restore -Fc -U $DB_USER $DB_NAME < backup.dump
```

### Debugging with Interactive Bash

```bash
# Get shell access to container
docker-compose exec backend bash

# Inside container:
cd /app
dotnet build
dotnet run

# Or for Node containers
docker-compose exec admin-portal sh
npm list
npm install package-name
```

---

## Next Steps

1. **SSL/TLS Setup**: Configure certificates using Let's Encrypt
2. **CI/CD Pipeline**: Set up GitHub Actions to build and push images
3. **Monitoring**: Add Prometheus + Grafana for metrics
4. **Logging**: Integrate ELK stack (Elasticsearch, Logstash, Kibana)
5. **Backup Strategy**: Automated database backups to S3
6. **Load Balancing**: Set up health checks for horizontal scaling

---

## Support & Documentation

- [Docker Compose Official Docs](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx Official Docs](https://nginx.org/en/)
- [Stack Overflow: Docker + Docker Compose](https://stackoverflow.com/questions/tagged/docker-compose)
