# Cloud Run Deployment Guide

## Prerequisites

1. GCP Project with billing enabled
2. gcloud CLI installed and authenticated
3. Required APIs enabled:
   - Cloud Run
   - Cloud SQL Admin
   - Secret Manager
   - Artifact Registry
   - Cloud Build

## Initial Setup

### 1. Enable APIs

```bash
gcloud services enable \
    run.googleapis.com \
    sqladmin.googleapis.com \
    secretmanager.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com
```

### 2. Create Artifact Registry Repository

```bash
export PROJECT_ID="your-project-id"
export REGION="us-central1"

gcloud artifacts repositories create listonit \
    --repository-format=docker \
    --location=$REGION \
    --project=$PROJECT_ID
```

### 3. Create Cloud SQL Instance

```bash
gcloud sql instances create listonit-db \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=$REGION \
    --database-flags=cloudsql.iam_authentication=on

# Create database
gcloud sql databases create listonit \
    --instance=listonit-db

# Create user (store password in Secret Manager)
gcloud sql users create listonit \
    --instance=listonit-db \
    --password=<generate-secure-password>
```

### 4. Store Secrets

```bash
# Database password
echo -n "your-db-password" | gcloud secrets create db-password --data-file=-

# JWT secret key (generate with: openssl rand -hex 32)
echo -n "your-jwt-secret" | gcloud secrets create jwt-secret-key --data-file=-

# Grant Cloud Run access to secrets
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

gcloud secrets add-iam-policy-binding db-password \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding jwt-secret-key \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

## Build and Deploy

### 1. Build Container

```bash
gcloud builds submit --tag $REGION-docker.pkg.dev/$PROJECT_ID/listonit/api:latest
```

### 2. Run Migrations

Get Cloud SQL connection name:
```bash
INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe listonit-db --format="value(connectionName)")
```

Run migrations using Cloud SQL Proxy:
```bash
# Install Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.arm64
chmod +x cloud-sql-proxy

# Start proxy
./cloud-sql-proxy $INSTANCE_CONNECTION_NAME &

# Run migrations
DATABASE_URL="postgresql://listonit:<password>@localhost:5432/listonit" alembic upgrade head
```

### 3. Deploy to Cloud Run

```bash
gcloud run deploy listonit-api \
    --image=$REGION-docker.pkg.dev/$PROJECT_ID/listonit/api:latest \
    --region=$REGION \
    --platform=managed \
    --allow-unauthenticated \
    --add-cloudsql-instances=$INSTANCE_CONNECTION_NAME \
    --set-env-vars="ENVIRONMENT=production,DB_NAME=listonit,DB_USER=listonit,CLOUD_SQL_CONNECTION_NAME=$INSTANCE_CONNECTION_NAME" \
    --set-secrets="DB_PASSWORD=db-password:latest,JWT_SECRET_KEY=jwt-secret-key:latest" \
    --min-instances=0 \
    --max-instances=10 \
    --cpu=1 \
    --memory=512Mi
```

## Testing

```bash
# Get service URL
SERVICE_URL=$(gcloud run services describe listonit-api --region=$REGION --format="value(status.url)")

# Test health endpoint
curl $SERVICE_URL/

# View API docs
open $SERVICE_URL/docs
```

## Monitoring

```bash
# View logs
gcloud run services logs read listonit-api --region=$REGION

# View metrics in Cloud Console
open "https://console.cloud.google.com/run/detail/$REGION/listonit-api/metrics"
```

## Cost Optimization

- **Scale to zero**: Set `--min-instances=0` for development
- **Right-size**: Start with `db-f1-micro` and `512Mi` memory
- **Monitor usage**: Check Cloud Run usage metrics monthly

Estimated costs for low-traffic MVP: $15-25/month
