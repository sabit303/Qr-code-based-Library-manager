import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'library_manager',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,

  connectTimeout: 60000
});

const DEFAULT_RETRY_ATTEMPTS = 5;
const DEFAULT_RETRY_DELAY_MS = 3000;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Test database connection
export async function testConnection(
  retryAttempts = DEFAULT_RETRY_ATTEMPTS,
  retryDelayMs = DEFAULT_RETRY_DELAY_MS
): Promise<void> {
  for (let attempt = 1; attempt <= retryAttempts; attempt += 1) {
    try {
      const connection = await pool.getConnection();
      console.log('✅ MySQL Database connected successfully');
      connection.release();
      return;
    } catch (error) {
      if (attempt < retryAttempts) {
        console.warn(
          `⚠️ MySQL Database connection failed. Retry ${attempt}/${retryAttempts - 1} in ${retryDelayMs}ms...`
        );
        await delay(retryDelayMs);
        continue;
      }

      console.error('❌ MySQL Database connection failed:', error);
      throw error;
    }
  }
}

export default pool;
