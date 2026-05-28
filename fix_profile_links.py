import os

def fix_links(filename):
    with open(filename, 'r') as f:
        content = f.read()

    # 找到导航栏中的 profile.html 链接并修改
    old_link = '<li><a href="profile.html">个人资料</a></li>'
    new_link = '<li><a href="profile.html" id="profileLink">个人资料</a></li>'
    
    content = content.replace(old_link, new_link)

    # 在 chat.html 中修改返回链接
    old_chat_link = '<a href="profile.html" class="back-link">← 返回个人中心</a>'
    new_chat_link = '<a href="profile.html" id="profileLink" class="back-link">← 返回个人中心</a>'
    
    content = content.replace(old_chat_link, new_chat_link)

    # 在脚本末尾添加动态设置链接的代码
    # 找到 </script> 标签，在它之前添加代码
    
    # 读取文件找到最后一个 </script> 标签的位置
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    for i, line in enumerate(lines):
        new_lines.append(line)
        # 如果找到最后一个 </script> 标签之前，添加动态设置链接的代码
        if '</script>' in line and i == len(lines) - 2:  # 假设倒数第二行是 </script>
            new_lines.append('\n        // 动态设置个人资料链接\n')
            new_lines.append('        const profileLink = document.getElementById("profileLink");\n')
            new_lines.append('        if (profileLink && currentUser) {\n')
            new_lines.append('            const userDataStr = JSON.stringify(currentUser);\n')
            new_lines.append('            const encodedData = encodeURIComponent(userDataStr);\n')
            new_lines.append('            profileLink.href = "profile.html?user=" + encodedData;\n')
            new_lines.append('        }\n')
    
    with open(filename, 'w') as f:
        f.writelines(new_lines)

    print(f"{filename} 修改完成")

# 修复所有需要修改的页面
fix_links('match.html')
fix_links('activities.html')
fix_links('messages.html')
fix_links('chat.html')

print("所有链接已修复")
