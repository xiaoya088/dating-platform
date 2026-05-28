with open('index.html', 'r') as f:
    content = f.read()

# 修复普通用户登录
old_user_login = '''                        localStorage.setItem('currentUser', JSON.stringify({ ...user, role: 'user' }));
                    const saved = localStorage.getItem('currentUser');
                    console.log('保存后验证:', saved ? '成功' : '失败');
                    if (!saved) {
                        throw new Error('用户信息保存失败');
                    }
                        console.log('已设置当前用户到 localStorage');

                        showAlert('登录成功', 'success');
                        setTimeout(() => {
                            window.location.href = user.name ? 'match.html' : 'profile.html';
                        }, 2000);'''

new_user_login = '''                        const userDataStr = JSON.stringify({ ...user, role: 'user' });
                    const encodedData = encodeURIComponent(userDataStr);
                    console.log('用户数据已编码，长度:', encodedData.length);

                        showAlert('登录成功', 'success');
                        setTimeout(() => {
                            alert("即将跳转到首页...");
                            window.location.href = (user.name ? 'match.html' : 'profile.html') + '?user=' + encodedData;
                        }, 2000);'''

content = content.replace(old_user_login, new_user_login)

# 修复中介登录
old_agency_login = '''localStorage.setItem('currentUser', JSON.stringify({ ...user, role: 'agency' }));
                    const saved = localStorage.getItem('currentUser');
                    console.log('保存后验证:', saved ? '成功' : '失败');
                    if (!saved) {
                        throw new Error('用户信息保存失败');
                    }'''

new_agency_login = '''localStorage.setItem('currentUser', JSON.stringify({ ...user, role: 'agency' }));
                    const saved = localStorage.getItem('currentUser');
                    console.log('保存后验证:', saved ? '成功' : '失败');
                    if (!saved) {
                        throw new Error('用户信息保存失败');
                    }'''

content = content.replace(old_agency_login, new_agency_login)

with open('index.html', 'w') as f:
    f.write(content)

print("修改完成")
