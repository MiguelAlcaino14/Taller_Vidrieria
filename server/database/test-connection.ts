import { Pool } from 'pg';
import dotenv from 'dotenv';
import net from 'net';

dotenv.config();

async function checkPortOpen(host: string, port: number): Promise<boolean> {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    socket.setTimeout(3000);

    socket.on('connect', () => {
      socket.destroy();
      resolve(true);
    });

    socket.on('timeout', () => {
      socket.destroy();
      resolve(false);
    });

    socket.on('error', () => {
      resolve(false);
    });

    socket.connect(port, host);
  });
}

async function testConnection() {
  console.log('🔍 Testing PostgreSQL connection...');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Connection details:');
  console.log(`  Host: ${process.env.DB_HOST}`);
  console.log(`  Port: ${process.env.DB_PORT}`);
  console.log(`  User: ${process.env.DB_USER}`);
  console.log(`  Database: ${process.env.DB_NAME}`);
  console.log(`  SSL: ${process.env.DB_SSL}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const host = process.env.DB_HOST!;
  const port = parseInt(process.env.DB_PORT || '5432');

  console.log('Step 1: Checking if port is open...');
  const portOpen = await checkPortOpen(host, port);

  if (!portOpen) {
    console.error('❌ Cannot reach server at', `${host}:${port}`);
    console.error('\n🔧 Troubleshooting steps:');
    console.error('  1. Verify PostgreSQL is running on the server:');
    console.error('     sudo systemctl status postgresql');
    console.error('  2. Check PostgreSQL is listening on all interfaces:');
    console.error('     sudo netstat -tuln | grep 5432');
    console.error('     (Should show 0.0.0.0:5432, not 127.0.0.1:5432)');
    console.error('  3. Check firewall on the server:');
    console.error('     sudo ufw status');
    console.error('     sudo ufw allow 5432/tcp');
    console.error('  4. Check cloud provider firewall (DigitalOcean/AWS/Azure)');
    console.error('  5. Review CONFIGURAR_POSTGRESQL.md for detailed steps');
    process.exit(1);
  }

  console.log('✅ Port is open and reachable\n');

  console.log('Step 2: Attempting PostgreSQL connection...');

  const pool = new Pool({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432'),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? {
      rejectUnauthorized: false
    } : false,
    connectionTimeoutMillis: 10000,
  });

  try {
    const client = await pool.connect();
    console.log('✅ PostgreSQL connection successful!\n');

    console.log('Step 3: Verifying database information...');
    const versionResult = await client.query('SELECT version()');
    console.log('📊 PostgreSQL version:', versionResult.rows[0].version);

    const dbSizeResult = await client.query(`
      SELECT pg_size_pretty(pg_database_size($1)) as size
    `, [process.env.DB_NAME]);
    console.log('💾 Database size:', dbSizeResult.rows[0].size);

    const tablesResult = await client.query(`
      SELECT COUNT(*) as count
      FROM information_schema.tables
      WHERE table_schema = 'public'
    `);
    console.log('📋 Tables in database:', tablesResult.rows[0].count);

    client.release();

    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✨ All checks passed! Your PostgreSQL server is ready.');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (tablesResult.rows[0].count === '0') {
      console.log('\n⚠️  No tables found. Run migration to create schema:');
      console.log('   npm run migrate');
    }

  } catch (error: any) {
    console.error('\n❌ PostgreSQL connection failed');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('Error:', error.message);
    if (error.code) {
      console.error('Code:', error.code);
    }

    console.error('\n🔧 Troubleshooting:');

    if (error.code === 'ECONNREFUSED') {
      console.error('  Connection refused - port is open but PostgreSQL rejected connection');
      console.error('  1. Check pg_hba.conf allows SSL connections:');
      console.error('     Should have: hostssl all all 0.0.0.0/0 md5');
      console.error('  2. Restart PostgreSQL after changes:');
      console.error('     sudo systemctl restart postgresql');
    } else if (error.code === 'ENOTFOUND') {
      console.error('  DNS lookup failed - cannot resolve hostname');
      console.error('  Check DB_HOST value in .env file');
    } else if (error.code === '28P01') {
      console.error('  Authentication failed');
      console.error('  1. Verify password is correct');
      console.error('  2. Check user exists and has permissions:');
      console.error('     sudo -u postgres psql');
      console.error('     ALTER USER postgres WITH PASSWORD \'your_password\';');
    } else if (error.code === '3D000') {
      console.error('  Database does not exist');
      console.error('  Create it with:');
      console.error('     sudo -u postgres psql');
      console.error('     CREATE DATABASE VidrieriaTaller;');
    } else if (error.message.includes('SSL')) {
      console.error('  SSL connection issue');
      console.error('  1. Verify SSL is enabled in postgresql.conf:');
      console.error('     ssl = on');
      console.error('  2. Check SSL certificate files exist');
    }

    console.error('\n📖 See CONFIGURAR_POSTGRESQL.md for complete setup guide');
    process.exit(1);
  } finally {
    await pool.end();
  }
}

testConnection();
