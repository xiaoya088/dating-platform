with open('admin.html', 'r') as f:
    content = f.read()

old_code = '''    <script>
        console.log("=== admin.html 页面加载 ===");
        console.log("localStorage 当前长度:", JSON.stringify(localStorage).length);
        console.log("localStorage 当前内容:", localStorage);
        console.log("开始检查用户");
        const currentUser = getCurrentUser();
        console.log("获取到的 currentUser:", currentUser);
        console.log("localStorage 中的原始数据:", localStorage.getItem("currentUser"));
        
        if (!currentUser || currentUser.role !== 'admin') {
            window.location.href = 'index.html';
        }'''

new_code = '''    <script>
        console.log("=== admin.html 页面加载 ===");
        console.log("URL:", window.location.href);
        
        let currentUser = null;
        
        const urlParams = new URLSearchParams(window.location.search);
        const encodedUser = urlParams.get('user');
        
        if (encodedUser) {
            console.log("从 URL 获取到用户数据");
            try {
                const userDataStr = atob(encodedUser);
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
            console.log("localStorage 中的数据:", localStorage.getItem("currentUser"));
        }
        
        console.log("最终的 currentUser:", currentUser);
        
        if (!currentUser || currentUser.role !== 'admin') {
            console.log("用户未登录或权限不足，重定向到登录页");
            window.location.href = 'index.html';
        }'''

content = content.replace(old_code, new_code)

with open('admin.html', 'w') as f:
    f.write(content)

print("修改完成")
