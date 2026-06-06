const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

// Get portfolio items for a store
router.get('/store/:storeId', async (req, res) => {
    try {
        const { storeId } = req.params;

        const [items] = await db.query(
            'SELECT * FROM portfolio_items WHERE store_id = ? ORDER BY created_at DESC',
            [storeId]
        );

        res.json(items);
    } catch (error) {
        console.error('Get portfolio error:', error);
        res.status(500).json({ error: 'Failed to fetch portfolio items' });
    }
});

// Create portfolio item
router.post('/', authenticateToken, async (req, res) => {
    try {
        const { store_id, title, description, image } = req.body;

        // Verify ownership
        const [stores] = await db.query('SELECT owner_id FROM stores WHERE id = ?', [store_id]);
        if (stores.length === 0) {
            return res.status(404).json({ error: 'Store not found' });
        }
        if (stores[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized' });
        }

        const [result] = await db.query(
            'INSERT INTO portfolio_items (store_id, title, description, image) VALUES (?, ?, ?, ?)',
            [store_id, title, description, image]
        );

        const [items] = await db.query('SELECT * FROM portfolio_items WHERE id = ?', [result.insertId]);
        res.status(201).json(items[0]);
    } catch (error) {
        console.error('Create portfolio item error:', error);
        res.status(500).json({ error: 'Failed to create portfolio item' });
    }
});

// Update portfolio item
router.put('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, image } = req.body;

        // Get item and verify ownership
        const [items] = await db.query(`
      SELECT p.*, s.owner_id FROM portfolio_items p
      JOIN stores s ON p.store_id = s.id
      WHERE p.id = ?
    `, [id]);

        if (items.length === 0) {
            return res.status(404).json({ error: 'Portfolio item not found' });
        }

        if (items[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized' });
        }

        await db.query(`
      UPDATE portfolio_items SET
        title = COALESCE(?, title),
        description = COALESCE(?, description),
        image = COALESCE(?, image)
      WHERE id = ?
    `, [title, description, image, id]);

        const [updated] = await db.query('SELECT * FROM portfolio_items WHERE id = ?', [id]);
        res.json(updated[0]);
    } catch (error) {
        console.error('Update portfolio item error:', error);
        res.status(500).json({ error: 'Failed to update portfolio item' });
    }
});

// Delete portfolio item
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        const [items] = await db.query(`
      SELECT p.*, s.owner_id FROM portfolio_items p
      JOIN stores s ON p.store_id = s.id
      WHERE p.id = ?
    `, [id]);

        if (items.length === 0) {
            return res.status(404).json({ error: 'Portfolio item not found' });
        }

        if (items[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized' });
        }

        await db.query('DELETE FROM portfolio_items WHERE id = ?', [id]);
        res.json({ message: 'Portfolio item deleted successfully' });
    } catch (error) {
        console.error('Delete portfolio item error:', error);
        res.status(500).json({ error: 'Failed to delete portfolio item' });
    }
});

module.exports = router;
