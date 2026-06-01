#!/bin/bash

echo "🚀 启动婚恋红娘系统本地服务器..."

# 检查Python是否安装
if command -v python3 &> /dev/null; then
    echo "✅ 使用Python3启动服务器"
    python3 -m http.server 8000
elif command -v python &> /dev/null; then
    echo "✅ 使用Python启动服务器"
    python -m http.server 8000
else
    echo "❌ 未找到Python，请先安装Python"
    echo "或者使用其他HTTP服务器，如："
    echo "  - npx serve"
    echo "  - npx http-server"
    exit 1
fi