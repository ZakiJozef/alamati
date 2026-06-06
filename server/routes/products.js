const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, requireStoreOwner } = require('../middleware/auth');

// Get products for a store
router.get('/store/:storeId', async (req, res) => {
    try {
        const { storeId } = req.params;
        const { type } = req.query;

        let query = 'SELECT * FROM products WHERE store_id = ?';
        const params = [storeId];

        if (type) {
            query += ' AND type = ?';
            params.push(type);
        }

        query += ' ORDER BY type, name';

        const [products] = await db.query(query, params);
        res.json(products);
    } catch (error) {
        console.error('Get products error:', error);
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

// Create product
router.post('/', authenticateToken, requireStoreOwner, async (req, res) => {
    try {
        const { store_id, name, description, price, image, type = 'product' } = req.body;

        // Verify ownership
        const [stores] = await db.query('SELECT owner_id FROM stores WHERE id = ?', [store_id]);
        if (stores.length === 0) {
            return res.status(404).json({ error: 'Store not found' });
        }
        if (stores[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized' });
        }

        const [result] = await db.query(
            'INSERT INTO products (store_id, name, description, price, image, type) VALUES (?, ?, ?, ?, ?, ?)',
            [store_id, name, description, price, image, type]
        );

        const [products] = await db.query('SELECT * FROM products WHERE id = ?', [result.insertId]);
        res.status(201).json(products[0]);
    } catch (error) {
        console.error('Create product error:', error);
        res.status(500).json({ error: 'Failed to create product' });
    }
});

// Update product
router.put('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, price, image, type } = req.body;

        // Get product and verify ownership
        const [products] = await db.query(`
      SELECT p.*, s.owner_id FROM products p
      JOIN stores s ON p.store_id = s.id
      WHERE p.id = ?
    `, [id]);

        if (products.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        if (products[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized' });
        }

        await db.query(`
      UPDATE products SET
        name = COALESCE(?, name),
        description = COALESCE(?, description),
        price = COALESCE(?, price),
        image = COALESCE(?, image),
        type = COALESCE(?, type)
      WHERE id = ?
    `, [name, description, price, image, type, id]);

        const [updated] = await db.query('SELECT * FROM products WHERE id = ?', [id]);
        res.json(updated[0]);
    } catch (error) {
        console.error('Update product error:', error);
        res.status(500).json({ error: 'Failed to update product' });
    }
});

// Delete product
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        const [products] = await db.query(`
      SELECT p.*, s.owner_id FROM products p
      JOIN stores s ON p.store_id = s.id
      WHERE p.id = ?
    `, [id]);

        if (products.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        if (products[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized' });
        }

        await db.query('DELETE FROM products WHERE id = ?', [id]);
        res.json({ message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Delete product error:', error);
        res.status(500).json({ error: 'Failed to delete product' });
    }
});

module.exports = router;
