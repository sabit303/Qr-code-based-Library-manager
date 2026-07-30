# 📚 QR Code Based Library Manager

A comprehensive, full-stack library management system with QR code integration. Combines a robust **Node.js/TypeScript** backend API with a **Flutter** cross-platform mobile frontend — designed for real-world university and institutional libraries.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-v16+-green)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue)](https://flutter.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)](https://www.typescriptlang.org/)
[![Mailgun](https://img.shields.io/badge/Email-Mailgun-F06B66)](https://www.mailgun.com/)
[![Cloudflare R2](https://img.shields.io/badge/Storage-Cloudflare%20R2-F38020)](https://developers.cloudflare.com/r2/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED)](https://www.docker.com/)

---

## 🎯 Project Overview

**QR Code Based Library Manager** is a production-ready application designed to digitize and streamline library operations. It covers the full lifecycle — from student registration and book cataloging, through QR-based borrowing and returning, to automated email reminders for overdue items.

### Key Capabilities

| Area | What It Does |
|---|---|
| **Book Catalog** | Full CRUD with cover image uploads to Cloudflare R2 |
| **Student & Librarian Mgmt** | Role-based accounts with profile photos |
| **QR Code System** | Auto-generated QR codes for students; QR scanning for check-in/check-out |
| **Book Request Workflow** | Students request → Librarians approve/issue → Track → Return |
| **Email Notifications** | Automated due-date reminders & overdue alerts via Mailgun |
| **Notification Tracking** | Deduplicated email log to prevent spam |
| **Authentication** | JWT-based auth with role-based access control (RBAC) |
| **Mobile-First** | Cross-platform Flutter app (Android, iOS, Web) |

---

## 🛠️ Tech Stack

![Tech Stack](./tech_stack.png)

### Backend

| Technology | Purpose |
|---|---|
| **Node.js** | Runtime environment |
| **TypeScript** | Type-safe application code |
| **Express.js** | REST API framework |
| **MySQL** | Relational database (InnoDB, utf8mb4) |
| **JWT** | Stateless authentication |
| **bcryptjs** | Password hashing |
| **Mailgun** | Transactional email delivery (due/overdue reminders) |
| **Cloudflare R2** | S3-compatible object storage for images (covers, photos) |
| **Docker** | Containerized deployment |
| **AWS SDK (S3 Client)** | R2 upload/delete via S3 API |

### Frontend

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform UI framework (Android / iOS / Web) |
| **Dart** | Application language |
| **Provider** | State management |
| **mobile_scanner** | Real-time QR code scanning |
| **qr_flutter** | QR code rendering |
| **cached_network_image** | Efficient image loading & caching |
| **image_picker** | Camera/gallery image selection |
| **flutter_animate** | Smooth micro-animations |
| **shimmer** | Loading skeleton effects |
| **Google Fonts** | Custom typography |

---

## ✨ Features

### Backend API (Node.js / TypeScript)

- ✅ RESTful API with clean architecture (Controller → Service → Repository)
- ✅ JWT-based authentication & role-based access control (RBAC)
- ✅ MySQL database with indexed queries and foreign key constraints
- ✅ QR code generation for student identification
- ✅ **Book request workflow** — request, approve/issue, return, delete
- ✅ **Mailgun email notifications** — automated due-date & overdue reminders
- ✅ **Email scheduler** — hourly background job checks all active borrowings
- ✅ **Notification deduplication** — tracks sent emails to prevent duplicates
- ✅ **Cloudflare R2 image storage** — book covers & student profile photos
- ✅ Late fee tracking on overdue transactions
- ✅ Pagination & advanced search
- ✅ Centralized error handling with custom error classes
- ✅ Request logging & monitoring
- ✅ Docker support for easy deployment
- ✅ Dependency injection pattern
- ✅ Environment-based configuration

### Mobile App (Flutter)

- ✅ Modern, responsive Material Design UI
- ✅ **Librarian dashboard** — overview stats, manage books/students/transactions
- ✅ **Student dashboard** — browse books, track borrowing history, view profile
- ✅ QR code scanning for book check-in/check-out
- ✅ Student QR code generation & display
- ✅ **Book request system** — request books directly from the app
- ✅ **Image upload** — camera/gallery for profile photos and book covers
- ✅ Cached network images with shimmer loading placeholders
- ✅ Smooth animations via `flutter_animate`
- ✅ Offline support with local caching (SharedPreferences)
- ✅ Cross-platform — Android, iOS, Web
- ✅ Custom typography with Google Fonts

---

## 📁 Project Structure

```
Qr-code-based-Library-manager/
├── api/                              # Backend (Node.js / TypeScript)
│   ├── src/
│   │   ├── app.ts                   # Express app configuration & middleware
│   │   ├── server.ts                # Entry point — DB connect, email scheduler, listen
│   │   ├── config/
│   │   │   ├── database.ts          # MySQL connection pool
│   │   │   └── init-db.sql          # Full database schema (5 tables)
│   │   ├── Controller/              # Route handlers (auth, books, students, borrow, librarian)
│   │   ├── Services/
│   │   │   ├── BookServices.ts      # Book CRUD + cover image upload
│   │   │   ├── BorrowServices.ts    # Request/issue/return workflow
│   │   │   ├── EmailService.ts      # Mailgun email templates (due/overdue)
│   │   │   ├── StudentService.ts    # Student CRUD + photo upload
│   │   │   ├── LibrarianService.ts  # Librarian management
│   │   │   ├── LoginService.ts      # Authentication logic
│   │   │   └── QRCodeService.ts     # QR code generation
│   │   ├── Repositories/            # MySQL data access layer
│   │   │   ├── MySQLBookRepository.ts
│   │   │   ├── MySQLBorrowRepository.ts
│   │   │   ├── MySQLStudentRepository.ts
│   │   │   ├── MySQLLibrarianRepository.ts
│   │   │   └── MySQLNotificationRepository.ts
│   │   ├── Entities/                # TypeScript entity models
│   │   ├── DTOs/                    # Data transfer objects
│   │   ├── Interfaces/              # TypeScript interfaces
│   │   ├── Routes/                  # Express route definitions
│   │   ├── middlewares/
│   │   │   ├── authMiddleware.ts         # JWT verification
│   │   │   ├── authorizeRoleMiddleware.ts # RBAC enforcement
│   │   │   ├── errorHandler.ts           # Global error handler + 404
│   │   │   └── requestLogger.ts          # HTTP request logging
│   │   ├── errors/                  # Custom error classes (NotFound, Forbidden, etc.)
│   │   ├── utils/
│   │   │   ├── CloudflareImages.ts  # R2 upload/delete via S3 SDK
│   │   │   ├── EmailScheduler.ts    # Hourly due/overdue email checker
│   │   │   └── logger.ts           # Logging utility
│   │   ├── types/                   # TypeScript type definitions
│   │   └── validators/              # Input validation
│   ├── docker-compose.yml           # Docker configuration (API + MySQL)
│   ├── Dockerfile                   # Container setup
│   ├── package.json                 # Dependencies
│   └── tsconfig.json                # TypeScript config
│
├── ui/                               # Frontend (Flutter)
│   ├── lib/
│   │   ├── main.dart                # App entry point
│   │   ├── screens/
│   │   │   ├── auth/                # Login screen
│   │   │   ├── librarian/           # Librarian dashboard, book/student detail, scanner
│   │   │   │   └── tabs/            # Dashboard, Books, Students, Transactions, Scanner
│   │   │   └── student/             # Student dashboard, scanner
│   │   │       └── tabs/            # Dashboard, Books, History, Profile, QR
│   │   ├── widgets/                 # Reusable UI components
│   │   ├── data/
│   │   │   ├── models/              # Data models
│   │   │   ├── providers/           # State management (Provider)
│   │   │   └── services/            # API client services
│   │   └── core/                    # Core utilities & theme helpers
│   ├── pubspec.yaml                 # Flutter dependencies
│   ├── android/                     # Android platform config
│   ├── ios/                         # iOS platform config
│   └── web/                         # Web platform support
│
├── tech_stack.png                    # Tech stack infographic
├── architecture_diagram.png          # Architecture diagram
├── LibraryManager-release.apk        # Pre-built Android APK
└── README.md                         # This file
```

---

## 🏗️ System Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                    Mobile App (Flutter)                        │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  Auth  │  Librarian Dashboard  │  Student Dashboard     │  │
│  │  QR Scanner  │  Book Request  │  Profile / History      │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────┬───────────────────────────────────┘
                            │ HTTP/HTTPS (REST)
┌───────────────────────────▼───────────────────────────────────┐
│               Backend API (Express / TypeScript)              │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  Routes → Controllers → Services → Repositories         │  │
│  │                                                          │  │
│  │  Auth  │  Books  │  Students  │  Borrow  │  Librarian   │  │
│  │  Middleware: JWT Auth │ RBAC │ Error Handler │ Logger    │  │
│  └─────────────────────────────────────────────────────────┘  │
└──────┬────────────────────┬───────────────────┬───────────────┘
       │ SQL                │ S3 API            │ HTTP API
┌──────▼──────┐    ┌────────▼────────┐   ┌──────▼──────────┐
│   MySQL DB  │    │ Cloudflare R2   │   │    Mailgun      │
│             │    │ (Image Storage) │   │ (Email Service) │
│ • students  │    │                 │   │                 │
│ • librarians│    │ • Book covers   │   │ • Due reminders │
│ • books     │    │ • Student photos│   │ • Overdue alerts│
│ • txns      │    │                 │   │                 │
│ • notifs    │    └─────────────────┘   └─────────────────┘
└─────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

#### Full Stack Setup
- **Node.js** v16+
- **npm** or **yarn**
- **MySQL** v5.7+
- **Flutter SDK** v3.10.4+
- **Dart** (included with Flutter)
- **Git**

#### Docker Setup (Backend Only)
- **Docker** & **Docker Compose**

### Option 1: Docker (Recommended for Backend)

```bash
cd api

# Create .env file (see Configuration section below for all variables)
cp .env.example .env
# Edit .env with your credentials

# Start services
docker-compose up -d

# Initialize database
docker-compose exec api npm run db:init
```

The API will be available at `http://localhost:3000`

### Option 2: Local Development

#### Backend

```bash
cd api
npm install
cp .env.example .env    # Edit with your credentials
npm run db:init          # Initialize database schema
npm run dev              # Start dev server with hot-reload (tsx watch)
```

You should see:
```
✅ MySQL Database connected successfully
[EmailScheduler] Starting email notification scheduler...
🚀 Server is running on port 3000
📍 API endpoint: http://localhost:3000/api
❤️  Health check: http://localhost:3000/health
```

#### Frontend

```bash
cd ui
flutter pub get
flutter run              # Run on connected device/emulator
flutter run -d chrome    # Run on web
```

---

## ⚙️ Configuration

### Backend Environment Variables (`.env`)

```env
# ── Server ──────────────────────────────────────
PORT=3000
NODE_ENV=development

# ── Database ────────────────────────────────────
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=library_manager

# ── Authentication ──────────────────────────────
JWT_SECRET=your_secret_key_here_min_32_chars
JWT_EXPIRES_IN=7d

# ── Cloudflare R2 (Image Storage) ──────────────
CF_R2_ACCOUNT_ID=your_account_id
CF_R2_ACCESS_KEY_ID=your_access_key
CF_R2_SECRET_ACCESS_KEY=your_secret_key
CF_R2_BUCKET_NAME=your_bucket_name
CF_R2_PUBLIC_URL=https://your-r2-public-url.com

# ── Mailgun (Email Notifications) ──────────────
MAILGUN_API_KEY=your_mailgun_api_key
MAILGUN_DOMAIN=your_domain.com
MAILGUN_FROM_EMAIL=noreply@yourdomain.com

# ── CORS ────────────────────────────────────────
CORS_ORIGIN=*
```

### Frontend Configuration

Update the API base URL in `lib/data/services/`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

---

## 📡 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/login` | User login (student or librarian) |
| `POST` | `/api/auth/register` | User registration |

### Students
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/students` | Get all students |
| `GET` | `/api/students/:id` | Get student by ID |
| `POST` | `/api/students` | Create student (Roll + Registration required) |
| `PUT` | `/api/students/:id` | Update student (with optional photo upload) |
| `DELETE` | `/api/students/:id` | Delete student |

### Librarians
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/librarian` | Get all librarians |
| `GET` | `/api/librarian/:id` | Get librarian by ID |
| `POST` | `/api/librarian` | Create librarian |
| `PUT` | `/api/librarian/:id` | Update librarian |
| `DELETE` | `/api/librarian/:id` | Delete librarian |

### Books
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/books` | Get all books |
| `GET` | `/api/books/:id` | Get book by ID |
| `POST` | `/api/books` | Create book (with optional cover image) |
| `PUT` | `/api/books/:id` | Update book |
| `DELETE` | `/api/books/:id` | Delete book |
| `GET` | `/api/books/search` | Search books |

### Borrowing
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/borrow/request` | Request to borrow a book |
| `POST` | `/api/borrow/confirm` | Approve/issue a book request (Librarian) |
| `POST` | `/api/borrow/return` | Return a borrowed book |
| `DELETE` | `/api/borrow/request` | Cancel a pending borrow request |
| `GET` | `/api/borrow/:status` | Get transactions by status (REQUESTED/ISSUED/RETURNED/OVERDUE) |

### Health Check
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | API health status |

> 📖 For detailed API documentation and example requests, see the [Postman Collection](./api/Library-Manager.postman_collection.json).

---

## 📧 Email Notification System

The backend includes a fully automated email notification system powered by **Mailgun**:

### How It Works

1. **Email Scheduler** starts automatically with the server
2. Runs a background check **every hour** (`setInterval`)
3. Scans all active (`ISSUED`) transactions for:
   - **Due reminders** — books due within the next 2 days
   - **Overdue reminders** — books past their due date
4. Sends beautifully templated HTML emails with book details
5. Logs each notification to the `notifications` table to prevent duplicates

### Email Templates

| Template | Trigger | Badge |
|----------|---------|-------|
| **Due Reminder** | Book due within 2 days | ⚠️ Due Soon (amber) |
| **Overdue Notice** | Book past due date | 🚨 Overdue (red) |

Both templates use a responsive HTML layout with:
- Clean header with Library Manager branding
- Book details card (title + due date)
- Color-coded warning/critical callouts
- Professional footer

---

## ☁️ Cloudflare R2 Image Storage

All image uploads (book covers, student profile photos) are stored on **Cloudflare R2** using the S3-compatible API:

- **Upload**: Base64 images → decoded → uploaded via `PutObjectCommand`
- **Delete**: Old images are cleaned up via `DeleteObjectCommand` when replaced
- **Public URLs**: Served through a configured public R2 URL
- **Supported formats**: JPEG, PNG, and other standard image types

---

## 🔐 Authentication & Authorization

### JWT Implementation
1. **Login** → User provides credentials, receives a JWT token
2. **Storage** → Token stored in Flutter's `SharedPreferences`
3. **Authorization** → Token sent as `Authorization: Bearer <token>` header
4. **Validation** → Server verifies token + checks user role

### Role-Based Access Control (RBAC)

| Permission | Student | Librarian |
|---|:---:|:---:|
| View own profile | ✅ | ✅ |
| Search & browse books | ✅ | ✅ |
| Request to borrow a book | ✅ | — |
| View own borrowing history | ✅ | — |
| Approve/issue book requests | — | ✅ |
| Manage all students | — | ✅ |
| Manage book catalog | — | ✅ |
| Process returns | — | ✅ |
| View all transactions | — | ✅ |

---

## 🗄️ Database Schema

The MySQL database uses **5 tables** with foreign key relationships:

```
students ──────────┐
  • id (UUID PK)   │
  • Roll (unique)  │  1:N
  • Registration ──┼──────→ transactions
  • Email          │          • id (auto PK)
  • PhotoUrl       │          • studentReg → students.Registration
  • Password       │          • bookId → books.id
                   │          • status (REQUESTED/ISSUED/RETURNED/OVERDUE)
books ─────────────┤          • dueDate, returnDate, lateFee
  • id (UUID PK)   │  1:N     │
  • name, author ──┘          │ 1:N
  • coverUrl                  ▼
  • totalCopies          notifications
  • availableCopies        • transactionId → transactions.id
                           • type (due_reminder / overdue_reminder)
librarians                 • sentAt
  • id (UUID PK)
  • name, email, password
```

---

## 📦 Dependencies

### Backend (`package.json`)
| Package | Purpose |
|---|---|
| `express` | Web framework |
| `typescript` | Type safety |
| `mysql2` | MySQL driver |
| `jsonwebtoken` | JWT authentication |
| `bcryptjs` | Password hashing |
| `qrcode` | QR code generation |
| `mailgun.js` | Mailgun SDK (email delivery) |
| `@aws-sdk/client-s3` | S3-compatible client for Cloudflare R2 |
| `axios` | HTTP client (Mailgun API calls) |
| `uuid` | UUID generation |
| `dotenv` | Environment variable management |
| `form-data` | Multipart form data handling |

### Frontend (`pubspec.yaml`)
| Package | Purpose |
|---|---|
| `flutter` | UI framework |
| `provider` | State management |
| `http` | HTTP client |
| `shared_preferences` | Local storage / token persistence |
| `qr_flutter` | QR code display widget |
| `mobile_scanner` | Camera-based QR code scanning |
| `cached_network_image` | Efficient image loading & caching |
| `image_picker` | Camera/gallery image selection |
| `flutter_animate` | Declarative animations |
| `shimmer` | Skeleton loading effects |
| `google_fonts` | Custom typography (Inter, Roboto, etc.) |
| `intl` | Date/number formatting |

---

## 🐛 Troubleshooting

### Backend

| Problem | Solution |
|---|---|
| Database connection failed | Check MySQL is running; verify `.env` credentials; ensure `library_manager` DB exists |
| Port 3000 in use | Change `PORT` in `.env` or kill existing process |
| Emails not sending | Verify `MAILGUN_API_KEY`, `MAILGUN_DOMAIN` in `.env`; check Mailgun dashboard for logs |
| Image upload fails | Verify all `CF_R2_*` environment variables are set correctly |
| Node modules issues | Delete `node_modules` + `package-lock.json`, re-run `npm install` |

### Frontend

| Problem | Solution |
|---|---|
| Packages not found | Run `flutter clean && flutter pub get` |
| API connection refused | Ensure backend is running; check base URL in `lib/data/services/` |
| QR scanning not working | Grant camera permissions; test on physical device |
| Images not loading | Check network connectivity; verify Cloudflare R2 public URL |

---

## 📚 Additional Documentation

- [API Database Setup Guide](./api/DATABASE_SETUP.md)
- [Quick Start Guide](./api/QUICKSTART.md)
- [Error Handling Documentation](./api/ERROR_HANDLING.md)
- [Implementation Summary](./api/IMPLEMENTATION_SUMMARY.md)
- [Postman Collection](./api/Library-Manager.postman_collection.json)

---

## 🧪 Testing

```bash
# Backend
cd api && npm test

# Frontend
cd ui && flutter test
```

---

## 📝 Development Workflow

1. Create a feature branch: `git checkout -b feature/feature-name`
2. Make changes in `api/src/` or `ui/lib/`
3. Test locally: `npm run dev` (backend) / `flutter run` (frontend)
4. Commit: `git commit -m "feat: description"`
5. Push & open a Pull Request

### Code Standards
- Follow TypeScript / Dart style guides
- Write meaningful commit messages (Conventional Commits)
- Add comments for complex logic
- Test changes before submitting PRs

---

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 🗺️ Roadmap

- [x] ~~Email notifications~~ ✅ *Implemented with Mailgun*
- [x] ~~Cloud image storage~~ ✅ *Implemented with Cloudflare R2*
- [x] ~~Book request workflow~~ ✅ *Request → Approve → Issue → Return*
- [x] ~~Late fee tracking~~ ✅ *Tracked per transaction*
- [ ] Admin analytics dashboard
- [ ] Book recommendations engine
- [ ] Multi-language support (i18n)
- [ ] PWA support
- [ ] Advanced search filters (genre, author, availability)
- [ ] Export reports (CSV/PDF)

---

## 📊 Project Statistics

| Metric | Value |
|---|---|
| **Backend** | TypeScript + Express.js |
| **Frontend** | Flutter (Cross-platform) |
| **Database** | MySQL 5.7+ (5 tables, InnoDB) |
| **Email** | Mailgun (automated scheduler) |
| **Storage** | Cloudflare R2 (S3-compatible) |
| **API Endpoints** | 20+ |
| **Flutter Screens** | 15+ |
| **Architecture** | Clean Architecture + DI |

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](./api/LICENSE) file for details.

## 👨‍💻 Authors

- **arks** — Initial development and architecture

## 🙏 Acknowledgments

- Express.js community
- Flutter and Dart teams
- MySQL documentation
- Mailgun & Cloudflare developer docs
- All contributors and users

## 📞 Support & Contact

- Open an [Issue](https://github.com/sabit303/Qr-code-based-Library-manager/issues)
- Start a [Discussion](https://github.com/sabit303/Qr-code-based-Library-manager/discussions)

---

**⭐ If you find this project helpful, please consider giving it a star!**

*Last updated: July 2026*
