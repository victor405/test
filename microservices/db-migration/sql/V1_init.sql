-- Create database
CREATE DATABASE IF NOT EXISTS demodb;

-- Use it
USE demodb;

-- Create table
CREATE TABLE IF NOT EXISTS prompt_history (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  prompt TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);