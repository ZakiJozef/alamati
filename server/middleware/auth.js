const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const LARAVEL_API_URL = process.env.LARAVEL_API_URL || 'http://localhost:3000/api';

// Generate JWT token (for Node.js-issued tokens)
const generateToken = (user) => {
    return jwt.sign(
        {
            id: user.id,
            email: user.email,
            role: user.role,
            username: user.username
        },
        JWT_SECRET,
        { expiresIn: '7d' }
    );
};

// Verify token by calling Laravel API (for Sanctum tokens)
const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    try {
        // Try to validate with Laravel Sanctum API
        const response = await fetch(`${LARAVEL_API_URL}/auth/me`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Accept': 'application/json'
            }
        });

        if (response.ok) {
            const user = await response.json();
            req.user = user;
            return next();
        }

        // If Laravel validation fails, try JWT validation as fallback
        jwt.verify(token, JWT_SECRET, (err, user) => {
            if (err) {
                return res.status(403).json({ error: 'Invalid or expired token' });
            }
            req.user = user;
            next();
        });
    } catch (error) {
        console.error('Auth error:', error.message);
        // Fallback to JWT if Laravel is unreachable
        jwt.verify(token, JWT_SECRET, (err, user) => {
            if (err) {
                return res.status(403).json({ error: 'Invalid or expired token' });
            }
            req.user = user;
            next();
        });
    }
};

// Optional authentication - doesn't fail if no token
const optionalAuth = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
        jwt.verify(token, JWT_SECRET, (err, user) => {
            if (!err) {
                req.user = user;
            }
        });
    }
    next();
};

// Role-based access control
const requireRole = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }
        next();
    };
};

// Super admin only
const requireAdmin = requireRole('super_admin');

// Store owner or admin
const requireStoreOwner = requireRole('super_admin', 'store_owner');

module.exports = {
    generateToken,
    authenticateToken,
    optionalAuth,
    requireRole,
    requireAdmin,
    requireStoreOwner,
    JWT_SECRET
};
