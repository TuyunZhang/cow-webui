

# 阶段 1: 构建前端
FROM node:18 as frontend-build
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build


# 设置环境变量
ENV SECRET_KEY=your_secret_key_here
ENV CORS_ORIGINS=http://localhost
ENV DOCKER_ENV=true
ENV BACKEND_PORT=5002

# 阶段 2: 构建后端和最终镜像
FROM python:3.9-alpine

# 安装 Nginx 和其他必要的包
RUN apk add --no-cache nginx

# 创建并激活虚拟环境
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
# ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PATH="/app/backend:${PATH}"

# 安装构建依赖和必要的系统包
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    python3-dev \
    linux-headers \
    nginx \
    gettext

# 设置后端工作目录
WORKDIR /app/backend

# 复制后端文件并安装依赖
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 删除构建依赖
RUN apk del .build-deps

COPY backend/ .

# 创建日志目录并设置权限
RUN mkdir -p /app/backend/logs && chmod 777 /app/backend/logs

# 复制前端构建结果
COPY --from=frontend-build /frontend/dist /usr/share/nginx/html

# 复制 Nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 设置正确的所有权和权限
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# 复制启动脚本
RUN chmod +x start.sh


# 暴露端口
EXPOSE 80

# 运行应用
CMD ["sh", "/app/backend/start.sh"]