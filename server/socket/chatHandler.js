const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');

// Connected users map: { odirekt1: socket.id }
const connectedUsers = new Map();

module.exports = (io) => {
    io.use((socket, next) => {
        const token = socket.handshake.auth.token;

        if (!token) {
            return next(new Error('Authentication required'));
        }

        try {
            const user = jwt.verify(token, JWT_SECRET);
            socket.user = user;
            next();
        } catch (err) {
            next(new Error('Invalid token'));
        }
    });

    io.on('connection', (socket) => {
        console.log(`✅ User connected: ${socket.user.username} (${socket.user.id})`);

        // Add to connected users
        connectedUsers.set(socket.user.id, socket.id);

        // Broadcast online status
        socket.broadcast.emit('user:online', { userId: socket.user.id });

        // Join personal room
        socket.join(`user:${socket.user.id}`);

        // Send message
        socket.on('message:send', async (data) => {
            try {
                const { receiver_id, store_id, content } = data;

                if (!receiver_id || !content) {
                    return socket.emit('error', { message: 'Receiver and content are required' });
                }

                // Save message to database
                const [result] = await db.query(
                    'INSERT INTO messages (sender_id, receiver_id, store_id, content) VALUES (?, ?, ?, ?)',
                    [socket.user.id, receiver_id, store_id || null, content]
                );

                // Update conversation
                const user1 = Math.min(socket.user.id, receiver_id);
                const user2 = Math.max(socket.user.id, receiver_id);

                await db.query(`
          INSERT INTO conversations (user1_id, user2_id, store_id, last_message_id)
          VALUES (?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE last_message_id = ?, updated_at = CURRENT_TIMESTAMP
        `, [user1, user2, store_id || null, result.insertId, result.insertId]);

                // Get full message with sender info
                const [messages] = await db.query(`
          SELECT m.*, u.username as sender_username, u.profile_pic as sender_profile_pic
          FROM messages m
          JOIN users u ON m.sender_id = u.id
          WHERE m.id = ?
        `, [result.insertId]);

                const message = messages[0];

                // Send to receiver if online
                io.to(`user:${receiver_id}`).emit('message:receive', message);

                // Confirm to sender
                socket.emit('message:sent', message);

            } catch (error) {
                console.error('Socket message error:', error);
                socket.emit('error', { message: 'Failed to send message' });
            }
        });

        // Mark messages as read
        socket.on('messages:read', async (data) => {
            try {
                const { sender_id } = data;

                await db.query(`
          UPDATE messages SET is_read = TRUE 
          WHERE sender_id = ? AND receiver_id = ? AND is_read = FALSE
        `, [sender_id, socket.user.id]);

                // Notify sender that messages were read
                io.to(`user:${sender_id}`).emit('messages:read', {
                    by: socket.user.id
                });

            } catch (error) {
                console.error('Mark read error:', error);
            }
        });

        // Typing indicator
        socket.on('typing:start', (data) => {
            const { receiver_id } = data;
            io.to(`user:${receiver_id}`).emit('typing:start', {
                userId: socket.user.id,
                username: socket.user.username
            });
        });

        socket.on('typing:stop', (data) => {
            const { receiver_id } = data;
            io.to(`user:${receiver_id}`).emit('typing:stop', {
                userId: socket.user.id
            });
        });

        // Get online users
        socket.on('users:online', () => {
            socket.emit('users:online', Array.from(connectedUsers.keys()));
        });

        // Disconnect
        socket.on('disconnect', () => {
            console.log(`❌ User disconnected: ${socket.user.username}`);
            connectedUsers.delete(socket.user.id);
            socket.broadcast.emit('user:offline', { userId: socket.user.id });
        });
    });

    return io;
};
