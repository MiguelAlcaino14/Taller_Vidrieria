import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import pool from '../config/database';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('Starting database migration...');

    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf-8');

    const lines = schema.split('\n');
    let currentStatement = '';
    let lineNumber = 0;

    for (const line of lines) {
      lineNumber++;
      const trimmedLine = line.trim();

      if (trimmedLine.startsWith('--') || trimmedLine.length === 0) {
        continue;
      }

      currentStatement += line + '\n';

      if (trimmedLine.endsWith(';')) {
        const statement = currentStatement.trim();

        if (statement.includes('INSERT INTO user_profiles') && statement.includes('$2a$10$')) {
          console.log('Skipping default user insert (will create with bcrypt)...');
          currentStatement = '';
          continue;
        }

        try {
          console.log(`Executing: ${statement.substring(0, 80)}...`);
          await client.query(statement);
          console.log('✓ Success');
        } catch (error: any) {
          if (error.message.includes('already exists')) {
            console.log('✓ Object already exists (skipping)');
          } else if (error.message.includes('duplicate key')) {
            console.log('✓ Duplicate key (skipping)');
          } else {
            console.error(`✗ Error at line ${lineNumber}: ${error.message}`);
            console.error(`Statement: ${statement.substring(0, 200)}`);
            throw error;
          }
        }

        currentStatement = '';
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
