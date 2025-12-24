import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

async function testConnection() {
  console.log('Testing PostgreSQL connection...');
  console.log('Connection details:');
  console.log(`  Host: ${process.env.DB_HOST}`);
  console.log(`  Port: ${process.env.DB_PORT}`);
  console.log(`  User: ${process.env.DB_USER}`);
  console.log(`  Database: ${process.env.DB_NAME}`);
  console.log(`  SSL: ${process.env.DB_SSL}`);
  console.log('');

  const pool = new Pool({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432'),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? {
      rejectUnauthorized: false
    } : false,
    connectionTimeoutMillis: 5000,
  });

  try {
    const client = await pool.connect();
    console.log('✅ Connection successful!');

    const result = await client.query('SELECT version()');
    console.log('PostgreSQL version:', result.rows[0].version);

    client.release();
  } catch (error: any) {
    console.error('❌ Connection failed:');
    console.error(`  Error: ${error.message}`);
    console.error(`  Code: ${error.code}`);

    if (error.code === 'ECONNREFUSED') {
      console.error('\nPossible causes:');
      console.error('  1. PostgreSQL server is not running');
      console.error('  2. Firewall is blocking port 5432');
      console.error('  3. PostgreSQL is not configured to accept remote connections');
      console.error('  4. Wrong host or port');
    } else if (error.code === 'ENOTFOUND') {
      console.error('\nThe host could not be found. Check the DB_HOST value.');
    } else if (error.code === '28P01') {
      console.error('\nAuthentication failed. Check username and password.');
    }
  } finally {
    await pool.end();
  }
}

testConnection();
