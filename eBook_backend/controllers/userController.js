const bcrypt = require('bcryptjs');
const pool = require('../config/database');

const userController = {
    // 用户注册
    async register(req, res) {
        try {
            const { username, password } = req.body;

            // 验证必填字段
            if (!username || !password) {
                return res.status(400).json({ message: '请填写所有必填字段' });
            }

            // 检查用户名是否已存在
            const [existingUser] = await pool.query(
                'SELECT * FROM users WHERE username = ?',
                [username]
            );

            if (existingUser.length > 0) {
                return res.status(400).json({ message: '用户名已存在' });
            }

            // 加密密码
            const hashedPassword = await bcrypt.hash(password, 10);

            // 创建新用户
            const [result] = await pool.query(
                'INSERT INTO users (username, password) VALUES (?, ?)',
                [username, hashedPassword]
            );

            res.status(201).json({
                message: '注册成功',
                userId: result.insertId
            });
        } catch (error) {
            console.error('注册错误:', error);
            res.status(500).json({ message: '服务器内部错误' });
        }
    },

    // 用户登录
    async login(req, res) {
        try {
            const { username, password } = req.body;

            // 验证必填字段
            if (!username || !password) {
                return res.status(400).json({ message: '请填写用户名和密码' });
            }

            // 查找用户
            const [users] = await pool.query(
                'SELECT * FROM users WHERE username = ?',
                [username]
            );

            if (users.length === 0) {
                return res.status(401).json({ message: '用户名或密码错误' });
            }

            const user = users[0];

            // 验证密码
            const isValidPassword = await bcrypt.compare(password, user.password);
            if (!isValidPassword) {
                return res.status(401).json({ message: '用户名或密码错误' });
            }

            // 登录成功，返回用户信息（不包含密码）
            const { password: _, ...userWithoutPassword } = user;
            res.json({
                message: '登录成功',
                user: userWithoutPassword
            });
        } catch (error) {
            console.error('登录错误:', error);
            res.status(500).json({ message: '服务器内部错误' });
        }
    },

    // 获取用户列表
    async getUsers(req, res) {
        try {
            const { page = 1, limit = 10, status } = req.query;
            const offset = (page - 1) * limit;

            let query = 'SELECT id, username, status, created_at, updated_at FROM users';
            let countQuery = 'SELECT COUNT(*) as total FROM users';
            const params = [];

            if (status) {
                query += ' WHERE status = ?';
                countQuery += ' WHERE status = ?';
                params.push(status);
            }

            query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
            params.push(parseInt(limit), offset);

            const [users] = await pool.query(query, params);
            const [[{ total }]] = await pool.query(countQuery, params.slice(0, -2));

            res.json({
                users,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    totalPages: Math.ceil(total / limit)
                }
            });
        } catch (error) {
            console.error('获取用户列表错误:', error);
            res.status(500).json({ message: '服务器内部错误' });
        }
    },

    // 获取用户详情
    async getUserById(req, res) {
        try {
            const { id } = req.params;
            const [users] = await pool.query(
                'SELECT id, username, status, created_at, updated_at FROM users WHERE id = ?',
                [id]
            );

            if (users.length === 0) {
                return res.status(404).json({ message: '用户不存在' });
            }

            res.json(users[0]);
        } catch (error) {
            console.error('获取用户详情错误:', error);
            res.status(500).json({ message: '服务器内部错误' });
        }
    },

    // 更新用户状态
    async updateUserStatus(req, res) {
        try {
            const { id } = req.params;
            const { status } = req.body;

            if (!['active', 'inactive', 'banned'].includes(status)) {
                return res.status(400).json({ message: '无效的状态值' });
            }

            const [result] = await pool.query(
                'UPDATE users SET status = ? WHERE id = ?',
                [status, id]
            );

            if (result.affectedRows === 0) {
                return res.status(404).json({ message: '用户不存在' });
            }

            res.json({ message: '状态更新成功' });
        } catch (error) {
            console.error('更新用户状态错误:', error);
            res.status(500).json({ message: '服务器内部错误' });
        }
    },

    // 删除用户
    async deleteUser(req, res) {
        try {
            const { id } = req.params;
            const [result] = await pool.query(
                'DELETE FROM users WHERE id = ?',
                [id]
            );

            if (result.affectedRows === 0) {
                return res.status(404).json({ message: '用户不存在' });
            }

            res.json({ message: '用户删除成功' });
        } catch (error) {
            console.error('删除用户错误:', error);
            res.status(500).json({ message: '服务器内部错误' });
        }
    }
};

module.exports = userController; 