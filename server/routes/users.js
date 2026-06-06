const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// Get all users (admin only)
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { role, search, limit = 50, offset = 0 } = req.query;

        let query = `
      SELECT id, username, email, profile_pic, role, pseudoname, created_at
      FROM users WHERE 1=1
    `;
        const params = [];

        if (role) {
            query += ' AND role = ?';
            params.push(role);
        }

        if (search) {
            query += ' AND (username LIKE ? OR email LIKE ? OR pseudoname LIKE ?)';
            params.push(`%${search}%`, `%${search}%`, `%${search}%`);
        }

        query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const [users] = await db.query(query, params);
        res.json(users);
    } catch (error) {
        console.error('Get users error:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// Get user by ID
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        const [users] = await db.query(`
      SELECT id, username, email, profile_pic, role, pseudoname, created_at
      FROM users WHERE id = ?
    `, [id]);

        if (users.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(users[0]);
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
});

// Update user profile
router.put('/profile', authenticateToken, async (req, res) => {
    try {
        const { username, pseudoname, profile_pic } = req.body;

        await db.query(`
      UPDATE users SET
        username = COALESCE(?, username),
        pseudoname = COALESCE(?, pseudoname),
        profile_pic = COALESCE(?, profile_pic)
      WHERE id = ?
    `, [username, pseudoname, profile_pic, req.user.id]);

        const [users] = await db.query(
            'SELECT id, username, email, profile_pic, role, pseudoname FROM users WHERE id = ?',
            [req.user.id]
        );

        res.json(users[0]);
    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

// Get saved stores
router.get('/saved/stores', authenticateToken, async (req, res) => {
    try {
        const [stores] = await db.query(`
      SELECT s.*, ss.created_at as saved_at
      FROM saved_stores ss
      JOIN stores s ON ss.store_id = s.id
      WHERE ss.user_id = ?
      ORDER BY ss.created_at DESC
    `, [req.user.id]);

        stores.forEach(store => {
            store.phones = JSON.parse(store.phones || '[]');
            store.social_links = JSON.parse(store.social_links || '{}');
        });

        res.json(stores);
    } catch (error) {
        console.error('Get saved stores error:', error);
        res.status(500).json({ error: 'Failed to fetch saved stores' });
    }
});

// Save/unsave store
router.post('/save-store/:storeId', authenticateToken, async (req, res) => {
    try {
        const { storeId } = req.params;

        // Check if already saved
        const [existing] = await db.query(
            'SELECT 1 FROM saved_stores WHERE user_id = ? AND store_id = ?',
            [req.user.id, storeId]
        );

        if (existing.length > 0) {
            // Unsave
            await db.query(
                'DELETE FROM saved_stores WHERE user_id = ? AND store_id = ?',
                [req.user.id, storeId]
            );
            res.json({ saved: false, message: 'Store removed from saved' });
        } else {
            // Save
            await db.query(
                'INSERT INTO saved_stores (user_id, store_id) VALUES (?, ?)',
                [req.user.id, storeId]
            );
            res.json({ saved: true, message: 'Store saved' });
        }
    } catch (error) {
        console.error('Save store error:', error);
        res.status(500).json({ error: 'Failed to save/unsave store' });
    }
});

// Get connections
router.get('/connections/list', authenticateToken, async (req, res) => {
    try {
        const [connections] = await db.query(`
      SELECT c.*, 
        u.id as user_id, u.username, u.profile_pic, u.pseudoname, u.role
      FROM connections c
      JOIN users u ON (
        CASE WHEN c.user_id = ? THEN c.connected_user_id ELSE c.user_id END
      ) = u.id
      WHERE (c.user_id = ? OR c.connected_user_id = ?) AND c.status = 'accepted'
    `, [req.user.id, req.user.id, req.user.id]);

        res.json(connections);
    } catch (error) {
        console.error('Get connections error:', error);
        res.status(500).json({ error: 'Failed to fetch connections' });
    }
});

// Get suggested connections
router.get('/connections/suggestions', authenticateToken, async (req, res) => {
    try {
        const [suggestions] = await db.query(`
      SELECT id, username, email, profile_pic, pseudoname, role
      FROM users
      WHERE id != ?
      AND id NOT IN (
        SELECT connected_user_id FROM connections WHERE user_id = ?
        UNION
        SELECT user_id FROM connections WHERE connected_user_id = ?
      )
      ORDER BY RAND()
      LIMIT 10
    `, [req.user.id, req.user.id, req.user.id]);

        res.json(suggestions);
    } catch (error) {
        console.error('Get suggestions error:', error);
        res.status(500).json({ error: 'Failed to fetch suggestions' });
    }
});

// Send connection request
router.post('/connections/:userId', authenticateToken, async (req, res) => {
    try {
        const { userId } = req.params;

        if (parseInt(userId) === req.user.id) {
            return res.status(400).json({ error: 'Cannot connect to yourself' });
        }

        // Check if connection exists
        const [existing] = await db.query(`
      SELECT * FROM connections 
      WHERE (user_id = ? AND connected_user_id = ?) 
      OR (user_id = ? AND connected_user_id = ?)
    `, [req.user.id, userId, userId, req.user.id]);

        if (existing.length > 0) {
            return res.status(409).json({ error: 'Connection already exists' });
        }

        await db.query(
            'INSERT INTO connections (user_id, connected_user_id, status) VALUES (?, ?, ?)',
            [req.user.id, userId, 'pending']
        );

        res.status(201).json({ message: 'Connection request sent' });
    } catch (error) {
        console.error('Send connection error:', error);
        res.status(500).json({ error: 'Failed to send connection request' });
    }
});

// Accept/reject connection
router.put('/connections/:connectionId', authenticateToken, async (req, res) => {
    try {
        const { connectionId } = req.params;
        const { status } = req.body; // 'accepted' or 'rejected'

        if (!['accepted', 'rejected'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status' });
        }

        const [connections] = await db.query(
            'SELECT * FROM connections WHERE id = ? AND connected_user_id = ?',
            [connectionId, req.user.id]
        );

        if (connections.length === 0) {
            return res.status(404).json({ error: 'Connection request not found' });
        }

        await db.query(
            'UPDATE connections SET status = ? WHERE id = ?',
            [status, connectionId]
        );

        res.json({ message: `Connection ${status}` });
    } catch (error) {
        console.error('Update connection error:', error);
        res.status(500).json({ error: 'Failed to update connection' });
    }
});

// Get admin statistics
router.get('/admin/stats', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const [[userStats]] = await db.query(`
      SELECT 
        COUNT(*) as total_users,
        SUM(CASE WHEN role = 'store_owner' THEN 1 ELSE 0 END) as store_owners,
        SUM(CASE WHEN role = 'visitor' THEN 1 ELSE 0 END) as visitors
      FROM users
    `);

        const [[storeStats]] = await db.query(`
      SELECT 
        COUNT(*) as total_stores,
        SUM(CASE WHEN is_featured THEN 1 ELSE 0 END) as featured,
        AVG(rating) as avg_rating
      FROM stores
    `);

        const [[reviewStats]] = await db.query('SELECT COUNT(*) as total_reviews FROM reviews');
        const [[messageStats]] = await db.query('SELECT COUNT(*) as total_messages FROM messages');

        res.json({
            users: userStats,
            stores: storeStats,
            reviews: reviewStats.total_reviews,
            messages: messageStats.total_messages
        });
    } catch (error) {
        console.error('Get stats error:', error);
        res.status(500).json({ error: 'Failed to fetch statistics' });
    }
});

module.exports = router;
