# DU Alert - Backend

Prerequisites: Node.js, PostgreSQL

## Setup

1. Copy `.env.example` to `.env` and fill DB and email credentials:

```bash
cp .env.example .env
```

2. Install dependencies:

```bash
npm install
```

3. Seed database with departments, roles, and 4 test users:

```bash
npm run seed:data
```

**Test User Credentials:**
- **Student**: username: `ahmedali`, password: `password123`
- **Proctor**: username: `fatimaKhan`, password: `password123`
- **Admin**: username: `mhassan`, password: `admin123`
- **Superadmin**: username: `superadmin`, password: `superadmin123`

4. Run server (development):

```bash
npm run dev
```

Or production:

```bash
npm start
```

## API

Base URL: `http://localhost:3000/api`

### Endpoints

- **Auth**: `POST /auth/login`, `POST /auth/register`
- **OTP**: `POST /otp/send`, `POST /otp/verify`
- **Users**: `POST /user/set-credentials`, `POST /user/reset-password`
- **Alerts**: `GET /alerts`, `POST /alerts`, `PUT /alerts/:id`, `DELETE /alerts/:id`
- **Notifications**: `GET /notifications`, `POST /notifications/:id/read`
- **Roles**: `GET /roles`, `POST /roles`, `POST /roles/assign`
- **Admin**: `GET /admin/users`
- **Departments**: `GET /departments`