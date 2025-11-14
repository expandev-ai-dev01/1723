import sql from 'mssql';
import { config } from '@/config';

/**
 * @summary Database connection pool
 * @description Singleton database connection pool for SQL Server
 */
let pool: sql.ConnectionPool | null = null;

/**
 * @summary Get database connection pool
 * @description Returns existing pool or creates new one
 *
 * @returns {Promise<sql.ConnectionPool>} Database connection pool
 */
export async function getPool(): Promise<sql.ConnectionPool> {
  if (!pool) {
    pool = await sql.connect(config.database);
    console.log('Database connection pool established');
  }
  return pool;
}

/**
 * @summary Close database connection pool
 * @description Closes the database connection pool
 */
export async function closePool(): Promise<void> {
  if (pool) {
    await pool.close();
    pool = null;
    console.log('Database connection pool closed');
  }
}

export default { getPool, closePool };
