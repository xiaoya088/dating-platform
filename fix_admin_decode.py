with open('admin.html', 'r') as f:
    content = f.read()

old_code = '''            console.log("从 URL 获取到用户数据");
            try {
                const userDataStr = atob(encodedUser);
                currentUser = JSON.parse(userDataStr);
                console.log("解码后的用户数据:", currentUser);
                localStorage.setItem('currentUser', userDataStr);
                console.log("已保存到 localStorage");
            } catch (e) {
                console.error("解码用户数据失败:", e);
            }'''

new_code = '''            console.log("从 URL 获取到用户数据");
            try {
                const userDataStr = decodeURIComponent(encodedUser);
                currentUser = JSON.parse(userDataStr);
                console.log("解码后的用户数据:", currentUser);
                localStorage.setItem('currentUser', userDataStr);
                console.log("已保存到 localStorage");
            } catch (e) {
                console.error("解码用户数据失败:", e);
            }'''

content = content.replace(old_code, new_code)

with open('admin.html', 'w') as f:
    f.write(content)

print("修改完成")
