with open('profile.html', 'r') as f:
    content = f.read()

search = """        const currentUser = getCurrentUser();
        if (!currentUser) {
            window.location.href = 'index.html';
        }"""

replace = """        let currentUser = null;

        const urlParams = new URLSearchParams(window.location.search);
        const encodedUser = urlParams.get('user');

        if (encodedUser) {
            console.log("从 URL 获取到用户数据");
            try {
                const userDataStr = decodeURIComponent(encodedUser);
                currentUser = JSON.parse(userDataStr);
                console.log("解码后的用户数据:", currentUser);
                localStorage.setItem('currentUser', userDataStr);
                console.log("已保存到 localStorage");
            } catch (e) {
                console.error("解码用户数据失败:", e);
            }
        } else {
            console.log("从 localStorage 获取用户数据");
            currentUser = getCurrentUser();
        }

        if (!currentUser) {
            console.log('用户未登录，重定向到登录页');
            window.location.href = 'index.html';
        }"""

content = content.replace(search, replace)

with open('profile.html', 'w') as f:
    f.write(content)

print("profile.html 修改完成")
