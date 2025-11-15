# Quick Start Guide - MySQL Setup

## 🚀 Quick Setup (3 Steps)

### Step 1: Install Dependencies
```bash
npm install
```

### Step 2: Configure Database
Create `.env` file:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=library_manager
```

### Step 3: Initialize Database
```bash
npm run db:init
```

### Step 4: Run the Server
```bash
npm run dev
```

## ✅ Success Indicators

You should see:
```
✅ MySQL Database connected successfully
🚀 Server is running on port 3000
📍 API endpoint: http://localhost:3000/api
❤️  Health check: http://localhost:3000/health
```

## 📝 Test the API

**Create a student:**
```bash
curl -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -d "{\"Name\":\"John Doe\",\"Roll\":\"2021001\",\"Registration\":\"REG2021001\",\"Department\":\"CS\",\"Session\":\"2021\",\"ContactNumber\":\"123456\",\"Address\":\"Address\"}"
```

**Get all students:**
```bash
curl http://localhost:3000/api/students
```

## 🔧 Troubleshooting

**MySQL not running?**
- Windows: Start MySQL service from Services app
- Or download from: https://dev.mysql.com/downloads/mysql/

**Connection refused?**
- Check MySQL is running on port 3306
- Verify credentials in `.env`

**Database doesn't exist?**
```bash
npm run db:init
```

That's it! You're ready to go! 🎉
