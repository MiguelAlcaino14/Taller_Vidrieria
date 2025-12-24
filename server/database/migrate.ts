import fs from 'fs';
import path from 'path';
import pool from '../config/database';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('Starting database migration...');

    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf-8');

    const statements = schema
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (const statement of statements) {
      if (statement.includes('INSERT INTO user_profiles') && statement.includes('$2a$10$')) {
        continue;
      }

      try {
        await client.query(statement);
      } catch (error: any) {
        if (!error.message.includes('already exists')) {
          throw error;
        }
      }
    }

    const adminHash = await bcrypt.hash('admin123', 10);
    const operatorHash = await bcrypt.hash('operator123', 10);

    await client.query(`
      INSERT INTO user_profiles (email, password_hash, full_name, role)
      VALUES ('admin@vidrieriataller.com', $1, 'Administrador', 'admin')
      ON CONFLICT (email) DO UPDATE SET password_hash = $1
    `, [adminHash]);

    await client.query(`
      INSERT INTO user_profiles (email, password_hash, full_name, role)
      VALUES ('operador@vidrieriataller.com', $1, 'Operador', 'operator')
      ON CONFLICT (email) DO UPDATE SET password_hash = $1
    `, [operatorHash]);

    console.log('Migration completed successfully!');
    console.log('\nDefault users:');
    console.log('  Admin: admin@vidrieriataller.com / admin123');
    console.log('  Operator: operador@vidrieriataller.com / operator123');

  } catch (error) {
    console.error('Migration failed:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch(console.error);
