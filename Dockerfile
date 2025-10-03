# 基础镜像：Node 16（与作业要求一致）
FROM node:16-alpine

# 工作目录
WORKDIR /app

# 先拷贝依赖描述，安装依赖（利用缓存）
COPY package*.json ./
# 优先使用锁文件；没有锁文件则安装依赖（生产依赖也可：npm ci --only=production）
RUN npm ci || npm install --production

# 再拷贝业务代码
COPY . .

# 生产环境
ENV NODE_ENV=production

# 暴露端口（你的示例应用通常监听 $PORT，默认可用 8080）
EXPOSE 8080

# 启动命令：优先用 package.json 里的 "start"
# 若你的项目没有 "start"，请在 package.json 里加上:  "start": "node app.js"
CMD ["npm","start"]
