# DU-Alert

DU-Alert is a campus safety and incident management platform built for Dhaka University. It combines a mobile-first Flutter client with a Node.js and PostgreSQL backend to support emergency SOS reporting, complaint tracking, anonymous public alerts, moderation workflows, notifications, analytics, and AI-assisted complaint summaries.

## Overview

The platform is designed to help students, proctors, and administrators report incidents, review cases, and coordinate faster responses. It supports authenticated workflows for private actions, optional public feed access for community visibility, and role-based administration for moderation and analytics.

## Key Features

### Authentication and Account Management

- Registration with OTP verification and password setup
- Login and profile access for authenticated users
- Password reset flow for forgotten credentials
- Department lookup for university-specific onboarding

### Emergency Response

- Emergency SOS creation with location data
- Personal emergency history for the reporting user
- Proctor and admin dashboards for monitoring active cases
- Emergency status updates and acknowledgements

### Complaint Management

- Complaint submission with up to 5 media attachments
- Complaint history for the reporting user
- Complaint detail views and status timelines
- AI-powered complaint summaries with Bangla, English, and mixed-language support
- Complaint review and status management for proctors and admins

### Public Alerts and Community Feed

- User-authored public alert posting with an optional anonymous display mode
- Public feed browsing with optional authentication
- Media uploads for alerts, including images, video, and PDF attachments
- Reactions and threaded comments on alerts
- Alert review and moderation tools for proctors and admins

### Notifications and Announcements

- User-specific notifications
- Mark individual notifications as read
- Mark all notifications as read
- Admin-created announcements delivered through the notification system

### Administration and Analytics

- User management for administrators
- Proctor account creation by admins
- Complaint, emergency, and public alert analytics
- Role-based access control for admin and proctor workflows

### Platform and Data Handling

- PostgreSQL-backed persistence using Sequelize
- Uploaded files served from the backend `/uploads` directory
- Secure media handling with file type and size validation
- Email delivery for OTP and reset flows
- AI summary integration through OpenRouter-compatible APIs

## Tech Stack

- Frontend: Flutter, Provider, Material Design
- Backend: Node.js, Express, Sequelize
- Database: PostgreSQL
- Messaging and email: Nodemailer
- Media uploads: Multer
- AI summaries: OpenRouter-compatible chat completions

## Repository Structure

```text
backend/
	app.js                     # Express server entry point
	.env.example               # Backend environment template
	config/                    # Database and runtime config
	database/                  # Schema, seeds, and migration scripts
	src/
		controllers/             # Request handlers
		middleware/              # Auth, validation, upload, and role guards
		models/                  # Sequelize models
		routes/                  # REST endpoints
		services/                # Email, AI, notification, and summary logic
		scripts/                 # Utility and backfill scripts
		utils/                   # Shared helpers

Frontend/
	main.dart                  # Flutter app entry point
	config/                    # API constants and theme setup
	models/                    # Client-side data models
	providers/                 # State management
	screens/                   # Auth, admin, proctor, student, and alert screens
	services/                  # API client and shared services
	widgets/                   # Reusable UI components
```

## Backend Setup

1. Copy `backend/.env.example` to `backend/.env`.
2. Fill in PostgreSQL, JWT, email, and AI provider credentials.
3. Install the backend dependencies required by the Node.js app.
4. Start the server from `backend/app.js`.

### Environment Variables

The backend expects the following core variables:

```env
APP_PORT=3000
NODE_ENV=development

DB_NAME=dualert
DB_USER=postgres
DB_PASSWORD=your_db_password
DB_HOST=localhost
DB_PORT=5432

JWT_SECRET=change_this_secret
JWT_EXPIRE=7d

EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-email-password

OPENAI_API_KEY=YOUR_OPENROUTER_KEY
OPENROUTER_MODEL=openai/gpt-4o-mini
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_HTTP_REFERER=http://localhost:3000
OPENROUTER_APP_NAME=DU Alert

CORS_ORIGIN=http://localhost:8080
```

Notes:

- `OPENAI_API_KEY` is used as the environment variable name for compatibility, but the value should be your OpenRouter key.
- Set `AUTH_ONLY=true` if you want the backend to expose authentication routes only.
- Uploaded files are stored in `backend/uploads` and served through `/uploads`.

## API Summary

### Authentication

- `POST /auth/register`
- `POST /auth/verify-otp`
- `POST /auth/complete-registration`
- `POST /auth/login`
- `POST /auth/request-password-reset`
- `POST /auth/reset-password`
- `GET /auth/departments`
- `GET /auth/profile`

### Emergencies

- `POST /emergency`
- `GET /emergency/my`
- `GET /emergency`
- `GET /emergency/:id`
- `PATCH /emergency/:id`

### Complaints

- `POST /complaints`
- `GET /complaints/my`
- `POST /complaints/:id/summary`
- `GET /complaints/:id`
- `GET /complaints`
- `PATCH /complaints/:id/status`

### Public Alerts and Social Feed

- `POST /public-alerts`
- `GET /public-alerts/feed`
- `GET /public-alerts/:id`
- `GET /public-alerts/my`
- `PATCH /public-alerts/:id/review`
- `POST /public-alerts/:id/reactions`
- `DELETE /public-alerts/:id/reactions`
- `POST /public-alerts/:id/comments`
- `DELETE /public-alerts/comments/:commentId`

Compatibility routes are also available through `/alerts`, `/comments`, and `/api/complaints`.

### Notifications and Admin

- `GET /notifications`
- `POST /notifications`
- `PATCH /notifications/:id/read`
- `POST /notifications/mark-all-read`
- `GET /admin/users`
- `POST /admin/proctors`
- `DELETE /admin/users/:id`
- `GET /admin/analytics`

## Frontend Notes

The Flutter client is organized around shared providers for auth, emergencies, complaints, public alerts, notifications, and admin state. By default it resolves the backend base URL from `API_BASE_URL` and falls back to `http://localhost:3000` on web or `http://10.0.2.2:3000` for Android emulators.

## Database And Data Flow

- Schema and seed files live under `backend/database/`.
- Startup sync logic in `backend/app.js` performs compatibility updates for complaint summaries, emergency acknowledgements, and status normalization.
- Migration scripts are included for complaint summary and managed-to-resolved status conversion.

## License

No license file is included in this repository yet. Add one if you want to define usage and distribution terms.
