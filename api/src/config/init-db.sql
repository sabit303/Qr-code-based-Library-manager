-- Create database if not exists
CREATE DATABASE IF NOT EXISTS library_manager;

USE library_manager;

-- Create students table
CREATE TABLE IF NOT EXISTS students (
  id VARCHAR(36) PRIMARY KEY,
  Name VARCHAR(255) NOT NULL,
  Roll VARCHAR(50) NOT NULL UNIQUE,
  Registration VARCHAR(50) NOT NULL UNIQUE,
  Department VARCHAR(100) NOT NULL,
  Session VARCHAR(50) NOT NULL,
  ContactNumber VARCHAR(20),
  Address TEXT,
  qrCode VARCHAR(500) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_roll (Roll),
  INDEX idx_registration (Registration),
  INDEX idx_qrcode (qrCode),
  INDEX idx_department (Department)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
