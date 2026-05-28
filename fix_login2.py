with open('index.html', 'r') as f:
    content = f.read()

# 简单的字符串替换，移除 localStorage 相关代码
content = content.replace(
    'console.log("localStorage 可用空间:", (5 * 1024 * 1024 - JSON.stringify(localStorage).length) + " bytes");\n                    const userData = JSON.stringify({ ...user, role: \'admin\' });\n                    console.log("用户数据长度:", userData.length);\n                    console.log("用户数据内容:", userData.substring(0, 200));\n                    localStorage.setItem(\'currentUser\', userData);\n                    const saved = localStorage.getItem(\'currentUser\');\n                    console.log(\'保存后验证:\', saved ? \'成功\' : \'失败\');\n                    if (!saved) {\n                        throw new Error(\'用户信息保存失败\');\n                    }\n                    console.log(\'已设置当前用户到 localStorage\');\n                    \n                    showAlert(\'登录成功\', \'success\');\n                    setTimeout(() => {\n                        window.location.href = \'admin.html\';\n                    }, 2000);',
    'const userDataStr = JSON.stringify({ ...user, role: \'admin\' });\n                    const encodedData = btoa(userDataStr);\n                    console.log(\'用户数据已编码，长度:\', encodedData.length);\n                    showAlert(\'登录成功\', \'success\');\n                    setTimeout(() => {\n                        window.location.href = \'admin.html?user=\' + encodedData;\n                    }, 2000);'
)

with open('index.html', 'w') as f:
    f.write(content)

print("修改完成")
