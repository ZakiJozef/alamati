const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

// Get reviews for a store
router.get('/store/:storeId', async (req, res) => {
    try {
        const { storeId } = req.params;
        const { limit = 20, offset = 0 } = req.query;

        const [reviews] = await db.query(`
      SELECT r.*, u.username, u.profile_pic, u.pseudoname
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.store_id = ?
      ORDER BY r.created_at DESC
      LIMIT ? OFFSET ?
    `, [storeId, parseInt(limit), parseInt(offset)]);

        res.json(reviews);
    } catch (error) {
        console.error('Get reviews error:', error);
        res.status(500).json({ error: 'Failed to fetch reviews' });
    }
});

// Create review
router.post('/', authenticateToken, async (req, res) => {
    try {
        const { store_id, rating, comment } = req.body;

        if (!store_id || !rating) {
            return res.status(400).json({ error: 'Store ID and rating are required' });
        }

        if (rating < 1 || rating > 5) {
            return res.status(400).json({ error: 'Rating must be between 1 and 5' });
        }

        // Check if store exists
        const [stores] = await db.query('SELECT id FROM stores WHERE id = ?', [store_id]);
        if (stores.length === 0) {
            return res.status(404).json({ error: 'Store not found' });
        }

        // Check if user already reviewed this store
        const [existing] = await db.query(
            'SELECT id FROM reviews WHERE store_id = ? AND user_id = ?',
            [store_id, req.user.id]
        );

        if (existing.length > 0) {
            // Update existing review
            await db.query(
                'UPDATE reviews SET rating = ?, comment = ? WHERE id = ?',
                [rating, comment, existing[0].id]
            );
        } else {
            // Create new review
            await db.query(
                'INSERT INTO reviews (store_id, user_id, rating, comment) VALUES (?, ?, ?, ?)',
                [store_id, req.user.id, rating, comment]
            );
        }

        // Update store rating
        const [avgRating] = await db.query(`
      SELECT AVG(rating) as avg_rating, COUNT(*) as count 
      FROM reviews WHERE store_id = ?
    `, [store_id]);

        await db.query(
            'UPDATE stores SET rating = ?, review_count = ? WHERE id = ?',
            [avgRating[0].avg_rating || 0, avgRating[0].count, store_id]
        );

        // Get the review with user info
        const [reviews] = await db.query(`
      SELECT r.*, u.username, u.profile_pic, u.pseudoname
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.store_id = ? AND r.user_id = ?
    `, [store_id, req.user.id]);

        res.status(201).json(reviews[0]);
    } catch (error) {
        console.error('Create review error:', error);
        res.status(500).json({ error: 'Failed to create review' });
    }
});

// Delete review
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        const [reviews] = await db.query(
            'SELECT * FROM reviews WHERE id = ?',
            [id]
        );

        if (reviews.length === 0) {
            return res.status(404).json({ error: 'Review not found' });
        }

        if (reviews[0].user_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized' });
        }

        const storeId = reviews[0].store_id;

        await db.query('DELETE FROM reviews WHERE id = ?', [id]);

        // Update store rating
        const [avgRating] = await db.query(`
      SELECT AVG(rating) as avg_rating, COUNT(*) as count 
      FROM reviews WHERE store_id = ?
    `, [storeId]);

        await db.query(
            'UPDATE stores SET rating = ?, review_count = ? WHERE id = ?',
            [avgRating[0].avg_rating || 0, avgRating[0].count, storeId]
        );

        res.json({ message: 'Review deleted successfully' });
    } catch (error) {
        console.error('Delete review error:', error);
        res.status(500).json({ error: 'Failed to delete review' });
    }
});

module.exports = router;
