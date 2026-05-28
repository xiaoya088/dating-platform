with open('index.html', 'r') as f:
    content = f.read()

old_code = """                        localStorage.setItem('currentUser', JSON.stringify({ ...user, role: 'user' }));
                    const saved = localStorage.getItem('currentUser');
                    console.log('保存后验证:', saved ? '成功' : '失败');
                    if (!saved) {
                        throw new Error('用户信息保存失败');
                    }
                        console.log('已设置当前用户到 localStorage');

                        showAlert('登录成功', 'success');
                        setTimeout(() => {
                            window.location.href = user.name ? 'match.html' : 'profile.html';
                        }, 2000);"""

new_code = """                        const userDataStr = JSON.stringify({ ...user, role: 'user' });
                    const encodedData = encodeURIComponent(userDataStr);
                    console.log('用户数据已编码，长度:', encodedData.length);

                        showAlert('登录成功', 'success');
                        setTimeout(() => {
                            alert("即将跳转到首页...");
                            window.location.href = (user.name ? 'match.html' : 'profile.html') + '?user=' + encodedData;
                        }, 2000);"""

content = content.replace(old_code, new_code)

with open('index.html', 'w') as f:
    f.write(content)

print("修复完成")
