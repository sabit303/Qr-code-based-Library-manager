# 📚 QR Code Based Library Manager

A comprehensive library management system with QR code integration, built with a modern tech stack. This project combines a robust Node.js/TypeScript backend API with a Flutter mobile frontend for seamless library operations.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-v16+-green)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue)](https://flutter.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-Latest-blue)](https://www.typescriptlang.org/)

## 🎯 Project Overview

QR Code Based Library Manager is a full-stack application designed to streamline library operations. It provides:

- **Digital Book Catalog** with QR code generation
- **Student & Librarian Management** with role-based access
- **Book Borrowing System** with transaction tracking
- **Real-time QR Code Scanning** for check-ins and check-outs
- **User Authentication & Authorization** with JWT tokens
- **Mobile-First Interface** using Flutter

## ✨ Features

### Backend API (Node.js/TypeScript)
- ✅ RESTful API design with comprehensive endpoints
- ✅ JWT-based authentication & role-based access control (RBAC)
- ✅ MySQL database with optimized queries
- ✅ QR code generation for student identification
- ✅ Book borrowing and transaction management
- ✅ Pagination & advanced search functionality
- ✅ Centralized error handling
- ✅ Request logging & monitoring
- ✅ Docker support for easy deployment
- ✅ Clean architecture with SOLID principles
- ✅ Dependency injection pattern
- ✅ Environment-based configuration

### Mobile App (Flutter)
- ✅ Modern, responsive UI design
- ✅ QR code scanning capability
- ✅ Student/Librarian authentication
- ✅ Book search and browsing
- ✅ Borrowing history tracking
- ✅ Student QR code generation
- ✅ Real-time notifications
- ✅ Offline support with local caching
- ✅ Cross-platform (iOS, Android, Web)

## 📁 Project Structure

```
Qr-code-based-Library-manager/
├── api/                          # Backend (Node.js/TypeScript)
│   ├── src/
│   │   ├── app.ts               # Express app configuration
│   │   ├── server.ts            # Server entry point
│   │   ├── config/              # Database configuration
│   │   ├── Controller/          # Route handlers
│   │   ├── Services/            # Business logic
│   │   ├── Repositories/        # Data access layer
│   │   ├── Entities/            # Database models
│   │   ├── DTOs/                # Data transfer objects
│   │   ├── Interfaces/          # TypeScript interfaces
│   │   ├── middlewares/         # Express middlewares
│   │   ├── errors/              # Custom error classes
│   │   ├── utils/               # Utility functions
│   │   └── validators/          # Input validation
│   ├── docker-compose.yml       # Docker configuration
│   ├── Dockerfile               # Container setup
│   ├── package.json             # Dependencies
│   └── tsconfig.json            # TypeScript config
│
├── ui/                           # Frontend (Flutter)
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── screens/             # UI screens
│   │   ├── widgets/             # Reusable widgets
│   │   ├── data/                # API & local data handling
│   │   └── core/                # Core utilities & helpers
│   ├── pubspec.yaml             # Flutter dependencies
│   ├── android/                 # Android configuration
│   ├── ios/                     # iOS configuration
│   └── web/                     # Web platform support
│
└── README.md                     # This file
```

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Mobile App (Flutter)                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │    Screens: Login, Dashboard, Books, Borrow      │  │
│  │    Widgets: QR Scanner, Book Cards, History      │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────┘
                           │ HTTP/HTTPS
                           │ REST API
┌──────────────────────────▼──────────────────────────────┐
│              Backend API (Express/TypeScript)           │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Routes → Controllers → Services → Repositories  │  │
│  │                                                   │  │
│  │  Authentication │ Books │ Students │ Borrowing   │  │
│  │  Error Handling │ Logging │ Validation          │  │
│  └──────────────────────────────────────────────────┘  │
└──────────────────────────┬──────────────────────────────┘
                           │ SQL
┌──────────────────────────▼──────────────────────────────┐
│              MySQL Database                             │
│  ├── Students (ID, Name, Roll, QR Code)               │
│  ├── Librarians (ID, Name, Role)                      │
│  ├── Books (ISBN, Title, Author, Quantity, QR Code)  │
│  └── Transactions (Borrowing, Returning)              │
└──────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

#### For Full Stack Setup:
- **Node.js** (v16 or higher)
- **npm** or **yarn**
- **MySQL** (v5.7 or higher)
- **Flutter SDK** (v3.10.4 or higher)
- **Dart** (included with Flutter)
- **Git**

#### For Docker Setup (Backend Only):
- **Docker**
- **Docker Compose**

### Option 1: Using Docker (Recommended for Backend)

#### 1. Navigate to API directory
```bash
cd api
```

#### 2. Create `.env` file
```bash
cat > .env << EOF
PORT=3000
DB_HOST=db
DB_PORT=3306
DB_USER=youruser
DB_PASSWORD=yourpassword
DB_NAME=library_manager
JWT_SECRET=your_secret_key_here
JWT_EXPIRES_IN=7d
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_API_TOKEN=your_api_token
EOF
```

#### 3. Start services with Docker Compose
```bash
docker-compose up -d
```

The API will be available at `http://localhost:3000`

#### 4. Run database initialization (if needed)
```bash
docker-compose exec api npm run db:init
```

### Option 2: Local Development Setup

#### Backend Setup

1. **Navigate to API directory**
   ```bash
   cd api
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Initialize database**
   ```bash
   npm run db:init
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```
   
   You should see:
   ```
   ✅ MySQL Database connected successfully
   🚀 Server is running on port 3000
   ```

#### Frontend Setup

1. **Navigate to UI directory**
   ```bash
   cd ui
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on emulator/device**
   ```bash
   # List available devices
   flutter devices
   
   # Run app
   flutter run
   
   # Run on specific device
   flutter run -d <device_id>
   ```

4. **For web (optional)**
   ```bash
   flutter run -d chrome
   ```

## ⚙️ Configuration

### Backend (.env file)

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=library_manager

# JWT Configuration
JWT_SECRET=your_secret_key_here_min_32_chars
JWT_EXPIRES_IN=7d

# Cloudflare Images (Optional)
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_API_TOKEN=your_api_token

# CORS
CORS_ORIGIN=*
```

### Frontend Configuration

Update API base URL in `lib/data/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

## 📡 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration

### Students
- `GET /api/students` - Get all students
- `GET /api/students/:id` - Get student by ID
- `POST /api/students` - Create student
- `PUT /api/students/:id` - Update student
- `DELETE /api/students/:id` - Delete student

### Librarians
- `GET /api/librarians` - Get all librarians
- `GET /api/librarians/:id` - Get librarian by ID
- `POST /api/librarians` - Create librarian
- `PUT /api/librarians/:id` - Update librarian
- `DELETE /api/librarians/:id` - Delete librarian

### Books
- `GET /api/books` - Get all books
- `GET /api/books/:id` - Get book by ID
- `POST /api/books` - Create book
- `PUT /api/books/:id` - Update book
- `DELETE /api/books/:id` - Delete book
- `GET /api/books/search` - Search books

### Borrowing
- `POST /api/borrows/borrow` - Borrow book
- `POST /api/borrows/return` - Return book
- `GET /api/borrows/history/:studentId` - Get borrowing history
- `GET /api/borrows/active` - Get active borrowings

### Health Check
- `GET /health` - API health status

For detailed API documentation, see [Library-Manager.postman_collection.json](./api/Library-Manager.postman_collection.json)

## 🔐 Authentication & Authorization

### JWT Implementation
The API uses JWT (JSON Web Tokens) for secure authentication:

1. **Login** - User provides credentials, receives JWT token
2. **Token Storage** - Token stored in Flutter local storage
3. **Authorization** - Token sent with each request in `Authorization: Bearer <token>` header
4. **Token Validation** - Server validates token and checks user role

### Role-Based Access Control (RBAC)

**Student Role:**
- View own profile
- Search available books
- Borrow/return books
- View own borrowing history

**Librarian Role:**
- Manage all students
- Manage book catalog
- Process book transactions
- View all borrowing history

## 📦 Dependencies

### Backend
- **express** - Web framework
- **typescript** - Type safety
- **mysql2** - Database driver
- **jsonwebtoken** - JWT authentication
- **bcryptjs** - Password hashing
- **qrcode** - QR code generation
- **dotenv** - Environment variable management

### Frontend
- **flutter** - UI framework
- **provider** - State management
- **http** - HTTP client
- **shared_preferences** - Local storage
- **qr_flutter** - QR code display
- **mobile_scanner** - QR code scanning
- **google_fonts** - Font management

## 🐛 Troubleshooting

### Backend Issues

**Issue: Database connection failed**
- Check MySQL is running
- Verify `.env` credentials match your MySQL setup
- Ensure `library_manager` database exists

**Issue: Port 3000 already in use**
- Change `PORT` in `.env` to another port
- Or kill the process: `lsof -ti:3000 | xargs kill -9`

**Issue: Node modules issues**
- Delete `node_modules` and `package-lock.json`
- Run `npm install` again

### Frontend Issues

**Issue: Flutter packages not found**
```bash
flutter clean
flutter pub get
```

**Issue: API connection refused**
- Ensure backend is running
- Check API base URL in `lib/data/api_service.dart`
- Verify network connectivity

**Issue: QR scanning not working**
- Grant camera permissions
- Test on physical device (emulator may have issues)

## 📚 Additional Documentation

- [API Setup Guide](./api/DATABASE_SETUP.md)
- [Quick Start Guide](./api/QUICKSTART.md)
- [Error Handling](./api/ERROR_HANDLING.md)
- [Implementation Summary](./api/IMPLEMENTATION_SUMMARY.md)

## 🧪 Testing

### Backend Testing
```bash
cd api
npm test
```

### Frontend Testing
```bash
cd ui
flutter test
```

## 📝 Development Workflow

### Backend Development
1. Create feature branch: `git checkout -b feature/feature-name`
2. Make changes in `src/` directory
3. Run `npm run dev` to test
4. Commit changes: `git commit -m "feat: description"`
5. Push to GitHub: `git push origin feature/feature-name`
6. Create Pull Request

### Frontend Development
1. Create feature branch: `git checkout -b feature/feature-name`
2. Make changes in `lib/` directory
3. Run `flutter run` to test
4. Commit changes: `git commit -m "feat: description"`
5. Push to GitHub: `git push origin feature/feature-name`
6. Create Pull Request

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Standards
- Follow TypeScript/Dart style guides
- Write meaningful commit messages
- Add comments for complex logic
- Test your changes before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./api/LICENSE) file for details.

## 👨‍💻 Authors

- **arks** - Initial development and architecture

## 🙏 Acknowledgments

- Express.js and Flask communities
- Flutter and Dart teams
- MySQL documentation
- All contributors and users

## 📞 Support & Contact

For support, questions, or suggestions:
- Open an [Issue](https://github.com/sabit303/Qr-code-based-Library-manager/issues)
- Create a [Discussion](https://github.com/sabit303/Qr-code-based-Library-manager/discussions)

## 🗺️ Roadmap

- [ ] Admin dashboard
- [ ] Email notifications
- [ ] Fine calculation system
- [ ] Book recommendations
- [ ] Analytics and reports
- [ ] Multi-language support
- [ ] PWA support
- [ ] Advanced search filters

## 📊 Project Statistics

- **Backend**: TypeScript + Express.js
- **Frontend**: Flutter (Cross-platform)
- **Database**: MySQL
- **Total Lines of Code**: 5000+
- **API Endpoints**: 20+

---

**⭐ If you find this project helpful, please consider giving it a star!**

Last updated: May 2026
