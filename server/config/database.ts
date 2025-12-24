import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: process.env.DB_SSL === 'true' ? {
    rejectUnauthorized: false
  } : false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
  console.log(`   Database: ${process.env.DB_NAME}`);
  console.log(`   Host: ${process.env.DB_HOST}:${process.env.DB_PORT}`);
  console.log(`   SSL: ${process.env.DB_SSL === 'true' ? 'Enabled' : 'Disabled'}`);
});

pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle PostgreSQL client:');
  console.error('   Error:', err.message);

  if (err.message.includes('ECONNREFUSED')) {
    console.error('\n🔧 Connection was refused by the server.');
    console.error('   This usually means the server is down or firewall is blocking.');
    console.error('   Run: npm run test:db for detailed diagnostics');
  } else if (err.message.includes('timeout')) {
    console.error('\n🔧 Connection timeout.');
    console.error('   The server is not responding. Check network connectivity.');
  }

  console.error('\n📖 See CONFIGURAR_POSTGRESQL.md for troubleshooting steps\n');
});

export default pool;
