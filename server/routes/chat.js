const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticateToken } = require('../middleware/auth');

// Get conversations
router.get('/conversations', authenticateToken, async (req, res) => {
    try {
        const [conversations] = await db.query(`
      SELECT 
        c.*,
        CASE 
          WHEN c.user1_id = ? THEN u2.id 
          ELSE u1.id 
        END as other_user_id,
        CASE 
          WHEN c.user1_id = ? THEN u2.username 
          ELSE u1.username 
        END as other_username,
        CASE 
          WHEN c.user1_id = ? THEN u2.profile_pic 
          ELSE u1.profile_pic 
        END as other_profile_pic,
        CASE 
          WHEN c.user1_id = ? THEN u2.pseudoname 
          ELSE u1.pseudoname 
        END as other_pseudoname,
        s.name as store_name,
        s.profile_image as store_image,
        m.content as last_message_content,
        m.created_at as last_message_time,
        (SELECT COUNT(*) FROM messages WHERE 
          ((sender_id = c.user1_id AND receiver_id = c.user2_id) OR 
           (sender_id = c.user2_id AND receiver_id = c.user1_id))
          AND receiver_id = ? AND is_read = FALSE
        ) as unread_count
      FROM conversations c
      JOIN users u1 ON c.user1_id = u1.id
      JOIN users u2 ON c.user2_id = u2.id
      LEFT JOIN stores s ON c.store_id = s.id
      LEFT JOIN messages m ON c.last_message_id = m.id
      WHERE c.user1_id = ? OR c.user2_id = ?
      ORDER BY c.updated_at DESC
    `, [req.user.id, req.user.id, req.user.id, req.user.id, req.user.id, req.user.id, req.user.id]);

        res.json(conversations);
    } catch (error) {
        console.error('Get conversations error:', error);
        res.status(500).json({ error: 'Failed to fetch conversations' });
    }
});

// Get messages for a conversation
router.get('/messages/:otherUserId', authenticateToken, async (req, res) => {
    try {
        const { otherUserId } = req.params;
        const { limit = 50, before } = req.query;

        let query = `
      SELECT m.*, 
        u.username as sender_username, 
        u.profile_pic as sender_profile_pic
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE (
        (m.sender_id = ? AND m.receiver_id = ?) OR
        (m.sender_id = ? AND m.receiver_id = ?)
      )
    `;
        const params = [req.user.id, otherUserId, otherUserId, req.user.id];

        if (before) {
            query += ' AND m.id < ?';
            params.push(before);
        }

        query += ' ORDER BY m.created_at DESC LIMIT ?';
        params.push(parseInt(limit));

        const [messages] = await db.query(query, params);

        // Mark messages as read
        await db.query(`
      UPDATE messages SET is_read = TRUE 
      WHERE sender_id = ? AND receiver_id = ? AND is_read = FALSE
    `, [otherUserId, req.user.id]);

        res.json(messages.reverse());
    } catch (error) {
        console.error('Get messages error:', error);
        res.status(500).json({ error: 'Failed to fetch messages' });
    }
});

// Send message (REST fallback, prefer Socket.IO)
router.post('/messages', authenticateToken, async (req, res) => {
    try {
        const { receiver_id, store_id, content } = req.body;

        if (!receiver_id || !content) {
            return res.status(400).json({ error: 'Receiver and content are required' });
        }

        // Create message
        const [result] = await db.query(
            'INSERT INTO messages (sender_id, receiver_id, store_id, content) VALUES (?, ?, ?, ?)',
            [req.user.id, receiver_id, store_id || null, content]
        );

        // Update or create conversation
        const user1 = Math.min(req.user.id, receiver_id);
        const user2 = Math.max(req.user.id, receiver_id);

        await db.query(`
      INSERT INTO conversations (user1_id, user2_id, store_id, last_message_id)
      VALUES (?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE last_message_id = ?, updated_at = CURRENT_TIMESTAMP
    `, [user1, user2, store_id || null, result.insertId, result.insertId]);

        const [messages] = await db.query(`
      SELECT m.*, u.username as sender_username, u.profile_pic as sender_profile_pic
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.id = ?
    `, [result.insertId]);

        res.status(201).json(messages[0]);
    } catch (error) {
        console.error('Send message error:', error);
        res.status(500).json({ error: 'Failed to send message' });
    }
});

// Get unread count
router.get('/unread-count', authenticateToken, async (req, res) => {
    try {
        const [[result]] = await db.query(
            'SELECT COUNT(*) as count FROM messages WHERE receiver_id = ? AND is_read = FALSE',
            [req.user.id]
        );
        res.json({ unread: result.count });
    } catch (error) {
        console.error('Get unread count error:', error);
        res.status(500).json({ error: 'Failed to get unread count' });
    }
});

module.exports = router;
