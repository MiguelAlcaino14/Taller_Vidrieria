import express, { Router } from 'express';
import pool from '../config/database';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router: Router = express.Router();

router.use(authenticateToken);

router.get('/', async (req: AuthRequest, res) => {
  try {
    const result = await pool.query(`
      SELECT o.*, c.name as customer_name
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;

    const orderResult = await pool.query(`
      SELECT o.*, c.name as customer_name
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.id = $1
    `, [id]);

    if (orderResult.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const itemsResult = await pool.query(
      'SELECT * FROM order_items WHERE order_id = $1 ORDER BY created_at',
      [id]
    );

    const order = orderResult.rows[0];
    order.items = itemsResult.rows;

    res.json(order);
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/', async (req: AuthRequest, res) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const {
      customer_id,
      order_number,
      status = 'pending',
      notes,
      items = []
    } = req.body;

    if (!customer_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Customer ID is required' });
    }

    const orderResult = await client.query(
      'INSERT INTO orders (customer_id, order_number, status, notes, created_at, created_by) VALUES ($1, $2, $3, $4, NOW(), $5) RETURNING *',
      [customer_id, order_number, status, notes, req.userId]
    );

    const order = orderResult.rows[0];

    if (items.length > 0) {
      for (const item of items) {
        await client.query(
          'INSERT INTO order_items (order_id, width, height, quantity, glass_type, thickness, notes) VALUES ($1, $2, $3, $4, $5, $6, $7)',
          [order.id, item.width, item.height, item.quantity, item.glass_type, item.thickness, item.notes]
        );
      }
    }

    await client.query('COMMIT');

    const fullOrderResult = await pool.query(`
      SELECT o.*, c.name as customer_name
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.id = $1
    `, [order.id]);

    const itemsResult = await pool.query(
      'SELECT * FROM order_items WHERE order_id = $1 ORDER BY created_at',
      [order.id]
    );

    const fullOrder = fullOrderResult.rows[0];
    fullOrder.items = itemsResult.rows;

    res.status(201).json(fullOrder);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

router.put('/:id', async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;
    const { customer_id, order_number, status, notes } = req.body;

    const result = await pool.query(
      'UPDATE orders SET customer_id = $1, order_number = $2, status = $3, notes = $4, updated_at = NOW() WHERE id = $5 RETURNING *',
      [customer_id, order_number, status, notes, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.delete('/:id', async (req: AuthRequest, res) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { id } = req.params;

    await client.query('DELETE FROM order_items WHERE order_id = $1', [id]);

    const result = await client.query(
      'DELETE FROM orders WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Order not found' });
    }

    await client.query('COMMIT');
    res.json({ message: 'Order deleted successfully' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Delete order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

export default router;
