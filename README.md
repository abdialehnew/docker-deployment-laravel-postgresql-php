# Laravel Docker - Production Ready Image

Image Docker production-ready untuk Laravel 12 dengan Nginx 1.27, PHP 8.3, dan PostgreSQL.

## 🎯 Stack Technology

- **Laravel**: 12.x (Latest)
- **Nginx**: 1.27-alpine
- **PHP**: 8.3-FPM
- **Database**: PostgreSQL client
- **Cache/Queue**: Redis support
- **Process Manager**: Supervisor

## 📁 Struktur Project

```
laravel-apps/
├── Dockerfile              # Multi-stage build
├── nginx/
│   └── default.conf       # Nginx production config
├── php/
│   ├── php.ini            # PHP configuration
│   └── php-fpm.conf       # PHP-FPM pool config
├── src/                   # Laravel 12 source code
│   ├── app/
│   ├── public/
│   ├── routes/
│   └── ...
├── .dockerignore
└── README.md
```

## ✨ Features

### 🔒 Security Hardening
- ✅ Security headers (X-Frame-Options, X-XSS-Protection, Content-Security-Policy)
- ✅ Hidden server tokens & PHP version exposure
- ✅ Disabled dangerous PHP functions (exec, shell_exec, system, etc.)
- ✅ Rate limiting (10 req/s per IP, burst 20)
- ✅ Secure session handling (httponly, secure, samesite)
- ✅ Protected sensitive files (.env, composer.json, .git)
- ✅ Minimal Alpine Linux base image

### ⚡ Performance Optimization
- ✅ OPcache fully optimized (256MB, 20K files, validate_timestamps=0)
- ✅ Gzip compression enabled (min 1KB)
- ✅ Static files caching (1 year)
- ✅ FastCGI buffering optimized
- ✅ Realpath cache 4MB (600s TTL)
- ✅ Laravel config/route/view pre-cached
- ✅ Composer classmap authoritative
- ✅ Multi-stage build (optimized image size)

### 📊 Monitoring & Health
- ✅ Health check endpoint (`/health`)
- ✅ PHP-FPM status page (`/fpm-status`)
- ✅ Slow query logging (>5s)
- ✅ Comprehensive access & error logs
- ✅ Supervisor process monitoring

### 🗄️ Database Support
- ✅ PostgreSQL (pdo_pgsql, pgsql extensions)
- ✅ PostgreSQL client tools included
- ✅ Redis extension for cache/queue/session

## 🚀 Quick Start

### Build Image
```bash
docker build -t laravel-app:latest .
```

### Run Container
```bash
docker run -d \
  --name laravel-app \
  -p 8000:80 \
  -e APP_ENV=production \
  -e APP_KEY=base64:your-app-key-here \
  -e DB_CONNECTION=pgsql \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_DATABASE=laravel \
  -e DB_USERNAME=laravel \
  -e DB_PASSWORD=secret \
  laravel-app:latest
```

### Access Application
```bash
# Main application
curl http://localhost:8000

# Health check
curl http://localhost:8000/health
# Response: healthy
```

## ⚙️ Configuration

### Environment Variables

#### Application
```env
APP_NAME=Laravel
APP_ENV=production
APP_KEY=base64:xxx
APP_DEBUG=false
APP_URL=https://example.com
```

#### Database (PostgreSQL)
```env
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

#### Cache & Queue (Redis)
```env
CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

## 🎛️ Performance Tuning

### PHP-FPM Pool Configuration
| Setting | Value | Description |
|---------|-------|-------------|
| Process Manager | Dynamic | Auto-scale based on load |
| Max Children | 50 | Maximum worker processes |
| Start Servers | 10 | Initial worker count |
| Min Spare Servers | 5 | Minimum idle workers |
| Max Spare Servers | 20 | Maximum idle workers |
| Max Requests | 1000 | Requests per worker (prevent memory leaks) |

### OPcache Configuration
| Setting | Value | Description |
|---------|-------|-------------|
| Memory | 256MB | OPcache memory allocation |
| Max Files | 20,000 | Maximum cached files |
| Validate Timestamps | 0 | Disabled in production |
| Revalidate Freq | 0 | Never check file timestamps |
| Huge Code Pages | 1 | Better CPU cache utilization |

### Nginx Configuration
| Setting | Value | Description |
|---------|-------|-------------|
| Rate Limit | 10 req/s | Per IP address |
| Rate Burst | 20 | Burst requests allowed |
| Keepalive Timeout | 15s | Connection reuse |
| Gzip | Enabled | Compress text files |
| Client Max Body | 20MB | Max upload size |

## 🐳 Docker Compose Example

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:80"
    environment:
      - APP_ENV=production
      - DB_CONNECTION=pgsql
      - DB_HOST=postgres
      - REDIS_HOST=redis
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-alpine
    environment:
      - POSTGRES_DB=laravel
      - POSTGRES_USER=laravel
      - POSTGRES_PASSWORD=secret
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data

volumes:
  postgres-data:
  redis-data:
```

## ☸️ Kubernetes Deployment

### Tag & Push Image
```bash
# Tag image
docker tag laravel-app:latest registry.example.com/laravel-app:v1.0.0

# Push to registry
docker push registry.example.com/laravel-app:v1.0.0
```

### Deployment Example
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: laravel-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: laravel
  template:
    metadata:
      labels:
        app: laravel
    spec:
      containers:
      - name: laravel
        image: registry.example.com/laravel-app:v1.0.0
        ports:
        - containerPort: 80
        env:
        - name: APP_ENV
          value: "production"
        - name: DB_CONNECTION
          value: "pgsql"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 40
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
```

## 📊 Monitoring & Logs

### Log Locations
```
/var/log/nginx/access.log         # Nginx access log
/var/log/nginx/error.log          # Nginx error log
/var/log/php-fpm/access.log       # PHP-FPM access log
/var/log/php-fpm/error.log        # PHP error log
/var/log/php-fpm/slow.log         # Slow queries (>5s)
/var/log/supervisor/              # Supervisor logs
```

### View Logs
```bash
# Nginx access log
docker exec laravel-app tail -f /var/log/nginx/access.log

# PHP error log
docker exec laravel-app tail -f /var/log/php-fpm/error.log

# Slow query log
docker exec laravel-app tail -f /var/log/php-fpm/slow.log

# All supervisor logs
docker exec laravel-app tail -f /var/log/supervisor/*.log
```

### Monitoring Endpoints
```bash
# Application health
curl http://localhost:8000/health

# PHP-FPM status
curl http://localhost:8000/fpm-status

# PHP-FPM ping
curl http://localhost:8000/fpm-ping
# Response: pong
```

## 🔧 Troubleshooting

### Permission Issues
```bash
docker exec laravel-app chown -R nginx:nginx /var/www/html/storage
docker exec laravel-app chmod -R 775 /var/www/html/storage
docker exec laravel-app chmod -R 775 /var/www/html/bootstrap/cache
```

### Clear Laravel Cache
```bash
docker exec laravel-app php artisan cache:clear
docker exec laravel-app php artisan config:clear
docker exec laravel-app php artisan view:clear
docker exec laravel-app php artisan route:clear
```

### Restart Services
```bash
# Restart all services
docker exec laravel-app supervisorctl restart all

# Restart PHP-FPM only
docker exec laravel-app supervisorctl restart php-fpm

# Restart Nginx only
docker exec laravel-app supervisorctl restart nginx

# Check status
docker exec laravel-app supervisorctl status
```

### Database Connection Test
```bash
# Test PostgreSQL connection
docker exec laravel-app php artisan tinker
>>> DB::connection()->getPdo();

# Run migrations
docker exec laravel-app php artisan migrate --force
```

## ✅ Production Checklist

### Application
- [ ] Set `APP_ENV=production`
- [ ] Set `APP_DEBUG=false`
- [ ] Generate unique `APP_KEY` (php artisan key:generate)
- [ ] Set correct `APP_URL`
- [ ] Configure trusted proxies if behind load balancer

### Database
- [ ] Configure PostgreSQL connection
- [ ] Set strong database password
- [ ] Enable SSL/TLS for database connection
- [ ] Run migrations (`php artisan migrate --force`)
- [ ] Seed production data if needed

### Cache & Performance
- [ ] Set up Redis for cache/queue/session
- [ ] Enable OPcache (already configured)
- [ ] Pre-cache routes and config (already done in build)
- [ ] Configure queue workers if using queues

### Security
- [ ] Enable HTTPS/SSL (use reverse proxy/ingress)
- [ ] Set secure session cookies
- [ ] Configure CORS if needed
- [ ] Set up firewall rules
- [ ] Enable rate limiting
- [ ] Review and update security headers

### Monitoring & Logging
- [ ] Set up log aggregation (ELK, Loki, CloudWatch)
- [ ] Configure error tracking (Sentry, Bugsnag)
- [ ] Set up APM (New Relic, Datadog, Prometheus)
- [ ] Configure log rotation
- [ ] Set up alerts for errors/downtime

### Infrastructure
- [ ] Set resource limits (CPU, Memory)
- [ ] Configure auto-scaling (HPA in K8s)
- [ ] Set up backup strategy for database
- [ ] Configure health checks
- [ ] Set up CI/CD pipeline
- [ ] Plan disaster recovery

## 💾 Resource Requirements

### Minimum (Development/Testing)
- **CPU**: 0.5 core
- **Memory**: 512MB
- **Storage**: 2GB

### Recommended (Production)
- **CPU**: 1-2 cores
- **Memory**: 1-2GB
- **Storage**: 5-10GB

### High Traffic (Production)
- **CPU**: 2-4 cores
- **Memory**: 2-4GB
- **Storage**: 20GB+
- **Replicas**: 3+ instances

## 🔐 Security Best Practices

### PHP Security
- Dangerous functions disabled (exec, passthru, shell_exec, system, etc.)
- File uploads restricted to 20MB
- Allow URL include disabled
- Error display disabled in production
- Secure session cookies (httponly, secure, samesite)
- Assertions disabled in production

### Nginx Security
- Server version hidden
- Protected hidden files (.*) 
- Protected sensitive files (.env, composer.*, phpunit.xml)
- Security headers enabled
- XSS protection enabled
- Rate limiting active

### Container Security
- Non-root user (nginx)
- Minimal Alpine Linux base
- No unnecessary packages
- Regular security updates
- Multi-stage build (smaller attack surface)

## 📚 Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 📝 License

This Docker configuration is open-source software.

## 👥 Support

For issues or questions:
- Create an issue in the repository
- Contact DevOps team
