# SERP Hawk CRM V2

AI-Powered CRM for SEO Agencies | Next.js + FastAPI + PostgreSQL + OpenAI

## Overview

SERP Hawk CRM V2 is a comprehensive customer relationship management system designed specifically for SEO agencies and digital marketing firms. It manages the entire client lifecycle from cold outreach to project delivery, billing, and SEO monitoring.

### Key Features

- **Role-Based Access**: Admin, Employee, Intern, Client roles with appropriate permissions
- **AI Email Agent**: Automated company research and personalized email generation
- **Real-Time Messaging**: WebSocket-based chat system
- **Service Management**: Catalog, quotes, invoicing, and billing
- **SEO Tools**: Keyword rankings, competitor analysis, SEO audits
- **Document Management**: File uploads, OCR for business cards
- **Reporting**: PDF exports, monitoring dashboards

## Tech Stack

- **Frontend**: Next.js 16, React 19, TypeScript, Tailwind CSS 4, Framer Motion
- **Backend**: FastAPI (Python 3.13), SQLModel ORM, Uvicorn with WebSocket
- **Database**: PostgreSQL (Neon Serverless)
- **AI**: OpenAI GPT-4o-mini, Google Gemini (OCR)
- **Integrations**: Outlook SMTP/IMAP, Webhooks, ReportLab PDFs

## AWS deployment overview

This assignment deploys the Next.js frontend, FastAPI backend, and PostgreSQL database in `ap-south-1` using one Ubuntu 24.04 `t3.micro` EC2 instance, Nginx, ECR, and one private single-AZ RDS PostgreSQL 16 `db.t3.micro` instance. The design avoids EKS, load balancers, NAT Gateway, Multi-AZ RDS, Secrets Manager, ElastiCache, and extra EBS volumes.

## Architecture

```mermaid
flowchart LR
   Browser --> EIP[Elastic IP]
   EIP --> Nginx[Nginx on EC2]
   Nginx -->|/| Next[Next.js :3000]
   Nginx -->|/api/ strips /api| API[FastAPI :8000]
   API --> RDS[(Private RDS PostgreSQL 16)]
   ECR[(ECR)] -. pull via IAM role .-> EC2[EC2 t3.micro]
```

## Prerequisites

- AWS account with MFA and a budget alert configured.
- AWS CLI, Terraform 1.6+, Docker Desktop, Git, Node.js 20+, and Python 3.10+.
- An EC2 key pair created in `ap-south-1`.
- Your public IP in CIDR form, such as `203.0.113.10/32`.
- GitHub repository with Actions enabled.

## Run locally

```powershell
Copy-Item .env.example .env
docker compose -f docker-compose.local.yml up --build
```

Open `http://localhost:3000`, `http://localhost:8000/docs`, and use the persistent Compose volume for PostgreSQL data. Stop with `docker compose -f docker-compose.local.yml down`; add `-v` only when you intentionally want to remove local database data.

## AWS deployment steps

Run these commands from the repository root. Do not commit `.env`, Terraform state, private keys, or credentials.

```powershell
aws configure
aws sts get-caller-identity
$env:TF_VAR_db_password = "use-a-long-unique-password"
terraform -chdir=infra init
terraform -chdir=infra validate
terraform -chdir=infra plan -var="my_ip_cidr=YOUR_PUBLIC_IP/32" -var="key_name=YOUR_EC2_KEY_NAME"
terraform -chdir=infra apply -var="my_ip_cidr=YOUR_PUBLIC_IP/32" -var="key_name=YOUR_EC2_KEY_NAME"
```

Record the Terraform outputs, create `/opt/crm/.env` on the EC2 instance with the database endpoint and application values, then build and deploy:

```bash
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID=YOUR_ACCOUNT_ID
export EC2_HOST=YOUR_ELASTIC_IP
export SSH_KEY_PATH=/path/to/key.pem
export ECR_BACKEND_IMAGE=YOUR_BACKEND_ECR_URL:TAG
export ECR_FRONTEND_IMAGE=YOUR_FRONTEND_ECR_URL:TAG
bash scripts/build_push.sh
bash scripts/deploy.sh
```

The deploy script runs only `python create_tables.py`. It never runs the legacy migration, cleanup, force-fix, or force-migrate scripts. The optional safe admin seed requires `SEED_ADMIN_EMAIL` and `SEED_ADMIN_PASSWORD` of at least 12 characters and is run manually with `python seed_db.py` inside the backend container.

## Environment variables

See `.env.example`. Required production values include `DATABASE_URL`, `SECRET_KEY`, and `JWT_SECRET_KEY`. OpenAI, Gemini, and SMTP variables are optional; the related features fail or fall back when they are absent. Production frontend images use `NEXT_PUBLIC_API_URL=/api` at build time.

## GitHub Actions secrets

Add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_ACCOUNT_ID`, `EC2_HOST`, `EC2_USER`, and `EC2_SSH_KEY`. The EC2 role is used for ECR pulls; the workflow credentials are only for CI image pushes. The application `.env` remains on the server and is not committed.

## Verification checklist

- `terraform output elastic_ip` is attached to the EC2 instance.
- RDS is not publicly accessible and its security group allows port 5432 only from the EC2 security group.
- `http://ELASTIC_IP/` loads the frontend.
- `http://ELASTIC_IP/api/docs` loads Swagger UI after Nginx prefix stripping.
- Login and API calls work through `/api`.
- WebSocket chat connects through the Nginx proxy.
- Restarting containers preserves uploaded files and database records.
- ECR contains no more than the last three images per repository.

## Cost and free-tier notes

This is a constrained assignment architecture: one `t3.micro`, one 20 GB gp3 root volume, one `db.t3.micro` RDS instance with 20 GB gp3, one attached Elastic IP, and no NAT Gateway, ALB/NLB, EKS, Multi-AZ RDS, extra EBS, Secrets Manager, or ElastiCache. AWS free-tier eligibility depends on account age, region, quotas, and current AWS terms. Set a $1 budget alert and stop resources when not testing.

## Teardown

```powershell
terraform -chdir=infra destroy -var="my_ip_cidr=YOUR_PUBLIC_IP/32" -var="key_name=YOUR_EC2_KEY_NAME"
```

Confirm the RDS instance, EC2 instance, EIP association, and both ECR repositories are removed. If an Elastic IP remains allocated after teardown, release it in the EC2 console or with the AWS CLI using its allocation ID.

## Troubleshooting

- Check containers with `docker compose -f docker-compose.prod.yml ps` and logs with `docker compose -f docker-compose.prod.yml logs --tail=100`.
- Check Nginx with `sudo nginx -t` and `sudo journalctl -u nginx`.
- A database timeout usually means the RDS security group does not reference the EC2 security group or the endpoint in `DATABASE_URL` is wrong.
- ECR pull failures usually mean the instance profile is missing or the repository URL/tag is wrong.
- A blank frontend API call usually means the image was built without `NEXT_PUBLIC_API_URL=/api`.

## Legacy hosting notes

The Railway, Heroku, and Vercel notes below are historical project documentation and are not part of this AWS deployment. `Procfile`, `railway.json`, and `passenger_wsgi.py` are intentionally ignored by the deployment design.

## Deployment Guide

### Prerequisites

- Node.js 18+
- Python 3.13+
- PostgreSQL database (Neon recommended)
- GitHub account
- OpenAI API key
- Google Gemini API key (for OCR)

### Backend Deployment

#### Option 1: Railway (Recommended)

1. Create a Railway account at [railway.app](https://railway.app)
2. Connect your GitHub repository
3. Add environment variables:
   - `DATABASE_URL`: Your PostgreSQL connection string
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `SECRET_KEY`: A random secret key for JWT
   - `SMTP_SERVER`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`: Email settings
4. Railway will automatically detect the `railway.json` and deploy

#### Option 2: Heroku

1. Create a Heroku account
2. Install Heroku CLI
3. Create a new app: `heroku create your-app-name`
4. Add PostgreSQL addon: `heroku addons:create heroku-postgresql:hobby-dev`
5. Set environment variables: `heroku config:set KEY=VALUE`
6. Deploy: `git push heroku main`

#### Option 3: Manual Server

1. Set up a server with Python 3.13+
2. Install dependencies: `pip install -r requirements.txt`
3. Set environment variables
4. Run with: `uvicorn main:app --host 0.0.0.0 --port 8000`

### Frontend Deployment

#### Option 1: Vercel (Recommended for Next.js)

1. Create a Vercel account at [vercel.com](https://vercel.com)
2. Connect your GitHub repository
3. Set the root directory to `frontend`
4. Add environment variables:
   - `wat `: Your backend API URL
5. Deploy automatically

#### Option 2: Netlify

1. Create a Netlify account
2. Connect GitHub repo
3. Set build command: `npm run build`
4. Set publish directory: `frontend/out` (for static export) or `frontend/.next` (for SSR)
5. Add environment variables

### Database Setup

1. Create a Neon PostgreSQL database at [neon.tech](https://neon.tech)
2. Run the database migrations: `python create_tables.py`
3. Seed initial data: `python seed_db.py`

### Environment Variables

Create a `.env` file in the root directory:

```
DATABASE_URL=postgresql://user:password@host:port/database
OPENAI_API_KEY=your_openai_key
GEMINI_API_KEY=your_gemini_key
SECRET_KEY=your_secret_key
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000  # local development

# In Vercel set Environment Variable (Production):
# NEXT_PUBLIC_API_BASE_URL=https://web-production-30b6.up.railway.app
```

## Local Development

### Backend

1. Create virtual environment: `python -m venv .venv`
2. Activate: `source .venv/bin/activate`
3. Install dependencies: `pip install -r requirements.txt`
4. Run migrations: `python create_tables.py`
5. Start server: `uvicorn main:app --reload`

### Frontend

1. Navigate to frontend: `cd frontend`
2. Install dependencies: `npm install`
3. Start dev server: `npm run dev`

## How to Add New Features

### Backend (FastAPI)

1. **Add Database Models**: 
   - Edit `database.py` to add new SQLModel classes
   - Run `python create_tables.py` to create tables

2. **Create API Endpoints**:
   - Add routes in `main.py` or create new modules
   - Follow RESTful conventions
   - Add proper authentication/authorization

3. **Add Business Logic**:
   - Create functions in appropriate modules under `modules/`
   - Use dependency injection for database sessions

4. **Update Dependencies**:
   - Add to `requirements.txt`
   - Test with `pip install -r requirements.txt`

### Frontend (Next.js)

1. **Create New Pages**:
   - Add to `frontend/src/app/` following the routing structure
   - Use TypeScript for type safety

2. **Add Components**:
   - Create reusable components in `frontend/src/components/`
   - Follow existing patterns for consistency

3. **API Integration**:
   - Use the existing API utilities in `frontend/src/lib/`
   - Add new API calls as needed

4. **Styling**:
   - Use Tailwind CSS classes
   - Follow the design system

### General Steps

1. Plan the feature and database changes
2. Implement backend API endpoints
3. Update frontend to consume the new APIs
4. Add proper error handling and validation
5. Test thoroughly
6. Update documentation

### Example: Adding a New Entity

1. Define the model in `database.py`
2. Create CRUD endpoints in `main.py`
3. Create frontend pages for list/view/edit
4. Add navigation links
5. Test the full flow

## API Documentation

The API documentation is available at `/docs` when the backend is running (Swagger UI) and `/redoc` for ReDoc.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is proprietary. All rights reserved.