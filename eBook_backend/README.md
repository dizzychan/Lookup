# eBook Backend

这是一个基于 Node.js 和 MySQL 的后端服务。

## 安装依赖

```bash
npm install
```

## 配置

1. 复制 `.env.example` 文件为 `.env`
2. 修改 `.env` 文件中的数据库配置

## 运行

开发模式：
```bash
npm run dev
```

生产模式：
```bash
npm start
```

## API 测试

测试接口：
```
GET /api/hello
```

响应示例：
```json
{
  "message": "Hello from eBook backend!"
}
``` 