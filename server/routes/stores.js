const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken, optionalAuth, requireStoreOwner, requireAdmin } = require('../middleware/auth');

// Get all stores with filters
router.get('/', optionalAuth, async (req, res) => {
    try {
        const { category, city, state, search, featured, sponsored, limit = 20, offset = 0 } = req.query;

        let query = `
      SELECT s.*, u.username as owner_name, u.profile_pic as owner_pic
      FROM stores s
      JOIN users u ON s.owner_id = u.id
      WHERE 1=1
    `;
        const params = [];

        if (category) {
            query += ' AND s.category = ?';
            params.push(category);
        }

        if (city) {
            query += ' AND s.city = ?';
            params.push(city);
        }

        if (state) {
            query += ' AND s.state = ?';
            params.push(state);
        }

        if (search) {
            query += ' AND (s.name LIKE ? OR s.description LIKE ?)';
            params.push(`%${search}%`, `%${search}%`);
        }

        if (featured === 'true') {
            query += ' AND s.is_featured = TRUE';
        }

        if (sponsored === 'true') {
            query += ' AND s.is_sponsored = TRUE';
        }

        query += ' ORDER BY s.is_featured DESC, s.rating DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), parseInt(offset));

        const [stores] = await db.query(query, params);

        // Parse JSON fields
        stores.forEach(store => {
            store.phones = JSON.parse(store.phones || '[]');
            store.social_links = JSON.parse(store.social_links || '{}');
        });

        res.json(stores);
    } catch (error) {
        console.error('Get stores error:', error);
        res.status(500).json({ error: 'Failed to fetch stores' });
    }
});

// Get featured stores
router.get('/featured', async (req, res) => {
    try {
        const [stores] = await db.query(`
      SELECT s.*, u.username as owner_name
      FROM stores s
      JOIN users u ON s.owner_id = u.id
      WHERE s.is_featured = TRUE
      ORDER BY s.rating DESC
      LIMIT 10
    `);

        stores.forEach(store => {
            store.phones = JSON.parse(store.phones || '[]');
            store.social_links = JSON.parse(store.social_links || '{}');
        });

        res.json(stores);
    } catch (error) {
        console.error('Get featured stores error:', error);
        res.status(500).json({ error: 'Failed to fetch featured stores' });
    }
});

// Get sponsored stores
router.get('/sponsored', async (req, res) => {
    try {
        const [stores] = await db.query(`
      SELECT s.*, u.username as owner_name
      FROM stores s
      JOIN users u ON s.owner_id = u.id
      WHERE s.is_sponsored = TRUE
      ORDER BY RAND()
      LIMIT 5
    `);

        stores.forEach(store => {
            store.phones = JSON.parse(store.phones || '[]');
            store.social_links = JSON.parse(store.social_links || '{}');
        });

        res.json(stores);
    } catch (error) {
        console.error('Get sponsored stores error:', error);
        res.status(500).json({ error: 'Failed to fetch sponsored stores' });
    }
});

// Get categories
router.get('/categories', async (req, res) => {
    try {
        const [categories] = await db.query(`
      SELECT DISTINCT category, COUNT(*) as count 
      FROM stores 
      GROUP BY category 
      ORDER BY count DESC
    `);
        res.json(categories);
    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({ error: 'Failed to fetch categories' });
    }
});

// Get cities
router.get('/cities', async (req, res) => {
    try {
        const [cities] = await db.query(`
      SELECT DISTINCT city, state, COUNT(*) as count 
      FROM stores 
      GROUP BY city, state 
      ORDER BY count DESC
    `);
        res.json(cities);
    } catch (error) {
        console.error('Get cities error:', error);
        res.status(500).json({ error: 'Failed to fetch cities' });
    }
});

// Get single store by ID
router.get('/:id', optionalAuth, async (req, res) => {
    try {
        const { id } = req.params;

        const [stores] = await db.query(`
      SELECT s.*, u.username as owner_name, u.profile_pic as owner_pic, u.email as owner_email
      FROM stores s
      JOIN users u ON s.owner_id = u.id
      WHERE s.id = ?
    `, [id]);

        if (stores.length === 0) {
            return res.status(404).json({ error: 'Store not found' });
        }

        const store = stores[0];
        store.phones = JSON.parse(store.phones || '[]');
        store.social_links = JSON.parse(store.social_links || '{}');

        // Check if current user has saved this store
        if (req.user) {
            const [saved] = await db.query(
                'SELECT 1 FROM saved_stores WHERE user_id = ? AND store_id = ?',
                [req.user.id, id]
            );
            store.is_saved = saved.length > 0;
        }

        // Get portfolio items
        const [portfolio] = await db.query(
            'SELECT * FROM portfolio_items WHERE store_id = ? ORDER BY created_at DESC',
            [id]
        );
        store.portfolio = portfolio;

        // Get products
        const [products] = await db.query(
            'SELECT * FROM products WHERE store_id = ? ORDER BY type, name',
            [id]
        );
        store.products = products;

        // Get reviews
        const [reviews] = await db.query(`
      SELECT r.*, u.username, u.profile_pic, u.pseudoname
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.store_id = ?
      ORDER BY r.created_at DESC
      LIMIT 20
    `, [id]);
        store.reviews = reviews;

        res.json(store);
    } catch (error) {
        console.error('Get store error:', error);
        res.status(500).json({ error: 'Failed to fetch store' });
    }
});

// Create new store
router.post('/', authenticateToken, requireStoreOwner, async (req, res) => {
    try {
        const {
            name, description, cover_image, profile_image, address, city, state,
            category, phone, phones, email, website, lat, lng, social_links
        } = req.body;

        if (!name) {
            return res.status(400).json({ error: 'Store name is required' });
        }

        const [result] = await db.query(`
      INSERT INTO stores (
        owner_id, name, description, cover_image, profile_image, address, city, state,
        category, phone, phones, email, website, lat, lng, social_links
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
            req.user.id, name, description, cover_image, profile_image, address, city, state,
            category, phone, JSON.stringify(phones || []), email, website, lat, lng,
            JSON.stringify(social_links || {})
        ]);

        const [stores] = await db.query('SELECT * FROM stores WHERE id = ?', [result.insertId]);
        const store = stores[0];
        store.phones = JSON.parse(store.phones || '[]');
        store.social_links = JSON.parse(store.social_links || '{}');

        res.status(201).json(store);
    } catch (error) {
        console.error('Create store error:', error);
        res.status(500).json({ error: 'Failed to create store' });
    }
});

// Update store
router.put('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        // Check ownership
        const [existing] = await db.query('SELECT owner_id FROM stores WHERE id = ?', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ error: 'Store not found' });
        }

        if (existing[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized to update this store' });
        }

        const {
            name, description, cover_image, profile_image, address, city, state,
            category, phone, phones, email, website, lat, lng, is_open, social_links
        } = req.body;

        await db.query(`
      UPDATE stores SET
        name = COALESCE(?, name),
        description = COALESCE(?, description),
        cover_image = COALESCE(?, cover_image),
        profile_image = COALESCE(?, profile_image),
        address = COALESCE(?, address),
        city = COALESCE(?, city),
        state = COALESCE(?, state),
        category = COALESCE(?, category),
        phone = COALESCE(?, phone),
        phones = COALESCE(?, phones),
        email = COALESCE(?, email),
        website = COALESCE(?, website),
        lat = COALESCE(?, lat),
        lng = COALESCE(?, lng),
        is_open = COALESCE(?, is_open),
        social_links = COALESCE(?, social_links)
      WHERE id = ?
    `, [
            name, description, cover_image, profile_image, address, city, state,
            category, phone, phones ? JSON.stringify(phones) : null, email, website,
            lat, lng, is_open, social_links ? JSON.stringify(social_links) : null, id
        ]);

        const [stores] = await db.query('SELECT * FROM stores WHERE id = ?', [id]);
        const store = stores[0];
        store.phones = JSON.parse(store.phones || '[]');
        store.social_links = JSON.parse(store.social_links || '{}');

        res.json(store);
    } catch (error) {
        console.error('Update store error:', error);
        res.status(500).json({ error: 'Failed to update store' });
    }
});

// Delete store
router.delete('/:id', authenticateToken, async (req, res) => {
    try {
        const { id } = req.params;

        const [existing] = await db.query('SELECT owner_id FROM stores WHERE id = ?', [id]);
        if (existing.length === 0) {
            return res.status(404).json({ error: 'Store not found' });
        }

        if (existing[0].owner_id !== req.user.id && req.user.role !== 'super_admin') {
            return res.status(403).json({ error: 'Not authorized to delete this store' });
        }

        await db.query('DELETE FROM stores WHERE id = ?', [id]);

        res.json({ message: 'Store deleted successfully' });
    } catch (error) {
        console.error('Delete store error:', error);
        res.status(500).json({ error: 'Failed to delete store' });
    }
});

// Get stores owned by current user
router.get('/my/stores', authenticateToken, async (req, res) => {
    try {
        const [stores] = await db.query(`
      SELECT * FROM stores WHERE owner_id = ? ORDER BY created_at DESC
    `, [req.user.id]);

        stores.forEach(store => {
            store.phones = JSON.parse(store.phones || '[]');
            store.social_links = JSON.parse(store.social_links || '{}');
        });

        res.json(stores);
    } catch (error) {
        console.error('Get my stores error:', error);
        res.status(500).json({ error: 'Failed to fetch stores' });
    }
});

module.exports = router;
