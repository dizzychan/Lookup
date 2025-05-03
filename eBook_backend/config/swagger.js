const swaggerJsdoc = require('swagger-jsdoc');

const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'eBook API 文档',
            version: '1.0.0',
            description: 'eBook 后端服务 API 文档',
        },
        servers: [
            {
                url: 'http://localhost:3000/api',
                description: '开发服务器',
            },
        ],
    },
    apis: ['./routes/*.js'], // 指定包含 API 文档注释的文件路径
};

const specs = swaggerJsdoc(options);

module.exports = specs; 