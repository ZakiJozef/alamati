const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const db = require('../config/db');
const { generateToken, authenticateToken, requireAdmin } = require('../middleware/auth');

// Register new user
router.post('/register', async (req, res) => {
    try {
        const { username, email, password, role = 'visitor', pseudoname } = req.body;

        // Validate input
        if (!username || !email || !password) {
            return res.status(400).json({ error: 'Username, email, and password are required' });
        }

        // Check if user exists
        const [existing] = await db.query(
            'SELECT id FROM users WHERE email = ? OR username = ?',
            [email, username]
        );

        if (existing.length > 0) {
            return res.status(409).json({ error: 'User already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        // Create user (prevent registering as super_admin)
        const safeRole = role === 'super_admin' ? 'visitor' : role;

        const [result] = await db.query(
            `INSERT INTO users (username, email, password_hash, role, pseudoname, profile_pic) 
       VALUES (?, ?, ?, ?, ?, ?)`,
            [username, email, passwordHash, safeRole, pseudoname || username,
                `https://ui-avatars.com/api/?name=${encodeURIComponent(username)}&background=137fec&color=fff`]
        );

        // Get created user
        const [users] = await db.query(
            'SELECT id, username, email, profile_pic, role, pseudoname, created_at FROM users WHERE id = ?',
            [result.insertId]
        );

        const user = users[0];
        const token = generateToken(user);

        res.status(201).json({
            message: 'User registered successfully',
            user,
            token
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

// Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        // Find user
        const [users] = await db.query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = users[0];

        // Check password
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Remove password from response
        delete user.password_hash;

        const token = generateToken(user);

        res.json({
            message: 'Login successful',
            user,
            token
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

// Get current user
router.get('/me', authenticateToken, async (req, res) => {
    try {
        const [users] = await db.query(
            'SELECT id, username, email, profile_pic, role, pseudoname, created_at FROM users WHERE id = ?',
            [req.user.id]
        );

        if (users.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(users[0]);
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
});

// Impersonate user (super_admin only)
router.post('/impersonate/:userId', authenticateToken, requireAdmin, async (req, res) => {
    try {
        const { userId } = req.params;

        const [users] = await db.query(
            'SELECT id, username, email, profile_pic, role, pseudoname FROM users WHERE id = ?',
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        const targetUser = users[0];

        // Generate token for target user but include original admin id
        const token = generateToken({
            ...targetUser,
            impersonatedBy: req.user.id
        });

        res.json({
            message: 'Impersonation successful',
            user: targetUser,
            token,
            originalAdminId: req.user.id
        });
    } catch (error) {
        console.error('Impersonation error:', error);
        res.status(500).json({ error: 'Impersonation failed' });
    }
});

// Stop impersonation - return to admin
router.post('/stop-impersonation', authenticateToken, async (req, res) => {
    try {
        const adminId = req.body.adminId;

        if (!adminId) {
            return res.status(400).json({ error: 'Admin ID required' });
        }

        const [admins] = await db.query(
            'SELECT id, username, email, profile_pic, role, pseudoname FROM users WHERE id = ? AND role = ?',
            [adminId, 'super_admin']
        );

        if (admins.length === 0) {
            return res.status(404).json({ error: 'Admin not found' });
        }

        const admin = admins[0];
        const token = generateToken(admin);

        res.json({
            message: 'Returned to admin account',
            user: admin,
            token
        });
    } catch (error) {
        console.error('Stop impersonation error:', error);
        res.status(500).json({ error: 'Failed to stop impersonation' });
    }
});

module.exports = router;
