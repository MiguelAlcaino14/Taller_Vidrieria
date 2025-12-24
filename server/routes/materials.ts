import express, { Router } from 'express';
import pool from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router: Router = express.Router();

router.use(authenticateToken);

router.get('/catalog', async (req: AuthRequest, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM materials_catalog ORDER BY type, name'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Get materials catalog error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/inventory', async (req: AuthRequest, res) => {
  try {
    const result = await pool.query(`
      SELECT mi.*, mc.name as material_name, mc.type as material_type
      FROM material_inventory mi
      JOIN materials_catalog mc ON mi.material_id = mc.id
      ORDER BY mc.name, mi.length DESC, mi.width DESC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Get inventory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/inventory/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT mi.*, mc.name as material_name, mc.type as material_type
      FROM material_inventory mi
      JOIN materials_catalog mc ON mi.material_id = mc.id
      WHERE mi.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Inventory item not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get inventory item error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/inventory', async (req: AuthRequest, res) => {
  try {
    const { material_id, length, width, quantity, location } = req.body;

    if (!material_id || !length || !width) {
      return res.status(400).json({ error: 'Material ID, length, and width are required' });
    }

    const result = await pool.query(
      'INSERT INTO material_inventory (material_id, length, width, quantity, location, added_at, added_by) VALUES ($1, $2, $3, $4, $5, NOW(), $6) RETURNING *',
      [material_id, length, width, quantity || 1, location, req.userId]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Add inventory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.put('/inventory/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;
    const { quantity, location, is_remnant } = req.body;

    const result = await pool.query(
      'UPDATE material_inventory SET quantity = $1, location = $2, is_remnant = $3, updated_at = NOW() WHERE id = $4 RETURNING *',
      [quantity, location, is_remnant, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Inventory item not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update inventory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/inventory/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'DELETE FROM material_inventory WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Inventory item not found' });
    }

    res.json({ message: 'Inventory item deleted successfully' });
  } catch (error) {
    console.error('Delete inventory error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
