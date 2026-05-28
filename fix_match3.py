with open('match.html', 'r') as f:
    content = f.read()

# 找到并替换用户验证代码
search = """    <script>
        console.log('match.html 页面加载，开始检查用户登录状态');
        const currentUser = getCurrentUser();
        console.log('获取到的当前用户:', currentUser);
        
        if (!currentUser) {
            console.log('用户未登录，重定向到登录页');
            window.location.href = 'index.html';
        } else {
            console.log('用户已登录:', currentUser.name, currentUser.role);
        }

        let allMatches = [];"""

replace = """    <script>
        console.log('match.html 页面加载，开始检查用户登录状态');

        let currentUser = null;

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
        } else {
            console.log('用户已登录:', currentUser.name, currentUser.role);
        }

        let allMatches = [];"""

content = content.replace(search, replace)

with open('match.html', 'w') as f:
    f.write(content)

print("match.html 修改完成")
