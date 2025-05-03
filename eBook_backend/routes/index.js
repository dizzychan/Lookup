const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

/**
 * @swagger
 * /hello:
 *   get:
 *     summary: 测试接口
 *     description: 返回一个简单的问候消息
 *     responses:
 *       200:
 *         description: 成功响应
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Hello from eBook backend!
 */
router.get('/hello', (req, res) => {
  res.json({ message: 'Hello from eBook backend!' });
});

/**
 * @swagger
 * /users/register:
 *   post:
 *     summary: 用户注册
 *     description: 创建新用户
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 description: 用户名
 *               password:
 *                 type: string
 *                 description: 密码
 *     responses:
 *       201:
 *         description: 注册成功
 *       400:
 *         description: 请求参数错误
 *       500:
 *         description: 服务器内部错误
 */
router.post('/users/register', userController.register);

/**
 * @swagger
 * /users/login:
 *   post:
 *     summary: 用户登录
 *     description: 用户登录验证
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *                 description: 用户名
 *               password:
 *                 type: string
 *                 description: 密码
 *     responses:
 *       200:
 *         description: 登录成功
 *       400:
 *         description: 请求参数错误
 *       401:
 *         description: 用户名或密码错误
 *       500:
 *         description: 服务器内部错误
 */
router.post('/users/login', userController.login);

/**
 * @swagger
 * /users:
 *   get:
 *     summary: 获取用户列表
 *     description: 获取所有用户列表，支持分页和状态筛选
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: 页码
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: 每页数量
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [active, inactive, banned]
 *         description: 用户状态筛选
 *     responses:
 *       200:
 *         description: 成功获取用户列表
 *       500:
 *         description: 服务器内部错误
 */
router.get('/users', userController.getUsers);

/**
 * @swagger
 * /users/{id}:
 *   get:
 *     summary: 获取用户详情
 *     description: 根据ID获取用户详细信息
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: 用户ID
 *     responses:
 *       200:
 *         description: 成功获取用户详情
 *       404:
 *         description: 用户不存在
 *       500:
 *         description: 服务器内部错误
 */
router.get('/users/:id', userController.getUserById);

/**
 * @swagger
 * /users/{id}/status:
 *   put:
 *     summary: 更新用户状态
 *     description: 更新指定用户的状态
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: 用户ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [active, inactive, banned]
 *                 description: 用户状态
 *     responses:
 *       200:
 *         description: 状态更新成功
 *       400:
 *         description: 无效的状态值
 *       404:
 *         description: 用户不存在
 *       500:
 *         description: 服务器内部错误
 */
router.put('/users/:id/status', userController.updateUserStatus);

/**
 * @swagger
 * /users/{id}:
 *   delete:
 *     summary: 删除用户
 *     description: 删除指定用户
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: 用户ID
 *     responses:
 *       200:
 *         description: 用户删除成功
 *       404:
 *         description: 用户不存在
 *       500:
 *         description: 服务器内部错误
 */
router.delete('/users/:id', userController.deleteUser);

module.exports = router; 