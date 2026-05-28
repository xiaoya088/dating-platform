with open('index.html', 'r') as f:
    content = f.read()

old_code = '''                    setTimeout(() => {
                        window.location.href = 'admin.html?user=' + encodedData;
                    }, 2000);'''

new_code = '''                    setTimeout(() => {
                        alert("即将跳转到管理后台...");
                        console.log("即将跳转到管理后台，URL:", "admin.html?user=" + encodedData.substring(0, 50) + "...");
                        window.location.href = "admin.html?user=" + encodedData;
                    }, 3000);'''

content = content.replace(old_code, new_code)

with open('index.html', 'w') as f:
    f.write(content)

print("修改完成")
