with open('match.html', 'r') as f:
    lines = f.readlines()

new_lines = []
i = 0
while i < len(lines):
    line = lines[i]

    if "console.log('match.html 页面加载，开始检查用户登录状态');" in line:
        new_lines.append(line)
        new_lines.append("\n")
        new_lines.append("        let currentUser = null;\n")
        new_lines.append("\n")
        new_lines.append("        const urlParams = new URLSearchParams(window.location.search);\n")
        new_lines.append("        const encodedUser = urlParams.get('user');\n")
        new_lines.append("\n")
        new_lines.append("        if (encodedUser) {\n")
        new_lines.append("            console.log(\"从 URL 获取到用户数据\");\n")
        new_lines.append("            try {\n")
        new_lines.append("                const userDataStr = decodeURIComponent(encodedUser);\n")
        new_lines.append("                currentUser = JSON.parse(userDataStr);\n")
        new_lines.append("                console.log(\"解码后的用户数据:\", currentUser);\n")
        new_lines.append("                localStorage.setItem('currentUser', userDataStr);\n")
        new_lines.append("                console.log(\"已保存到 localStorage\");\n")
        new_lines.append("            } catch (e) {\n")
        new_lines.append("                console.error(\"解码用户数据失败:\", e);\n")
        new_lines.append("            }\n")
        new_lines.append("        } else {\n")
        new_lines.append("            console.log(\"从 localStorage 获取用户数据\");\n")
        new_lines.append("            currentUser = getCurrentUser();\n")
        new_lines.append("        }\n")
        new_lines.append("\n")
        i += 1
        while i < len(lines) and ("const currentUser = getCurrentUser();" in lines[i] or
                                    "console.log('获取到的当前用户:', currentUser);" in lines[i] or
                                    lines[i].strip() == "" or
                                    ("if (!currentUser)" in lines[i] and "window.location.href = 'index.html';" in lines[i+1] if i+1 < len(lines) else False) or
                                    ("console.log('用户未登录，重定向到登录页');" in lines[i] and i+1 < len(lines) and "window.location.href = 'index.html';" in lines[i+1]) or
                                    ("window.location.href = 'index.html';" in lines[i]) or
                                    ("} else {" in lines[i]) or
                                    ("console.log('用户已登录:', currentUser.name, currentUser.role);" in lines[i])):
            if "const currentUser = getCurrentUser();" in lines[i]:
                i += 1
                continue
            if "console.log('获取到的当前用户:', currentUser);" in lines[i]:
                i += 1
                continue
            if lines[i].strip() == "":
                i += 1
                continue
            if "if (!currentUser)" in lines[i]:
                i += 1
                continue
            if "console.log('用户未登录，重定向到登录页');" in lines[i]:
                i += 1
                continue
            if "window.location.href = 'index.html';" in lines[i]:
                i += 1
                continue
            if "} else {" in lines[i]:
                i += 1
                continue
            if "console.log('用户已登录:', currentUser.name, currentUser.role);" in lines[i]:
                i += 1
                continue
            i += 1
        continue

    new_lines.append(line)
    i += 1

with open('match.html', 'w') as f:
    f.writelines(new_lines)

print("match.html 修改完成")
