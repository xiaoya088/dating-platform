// 登录诊断脚本
// 运行方式: node test_login.js

const fetch = require('cross-fetch');

const SUPABASE_URL = 'https://awhpfdhxcoycxgfhpfoy.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3aHBmZGh4Y295Y3hnZmhwb295Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTUxNzQ1MDIsImV4cCI6MjAzMDc1MDUwMn0.9kK9k9Q9K9kK9k9K9kK9kK9k9K9kK9kK9k9K9kK';

async function testSupabaseConnection() {
    console.log('=== 测试 Supabase 连接 ===\n');
    
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/admins?select=*`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        
        console.log(`HTTP 状态码: ${response.status}`);
        console.log(`响应状态: ${response.statusText}`);
        
        if (response.ok) {
            const data = await response.json();
            console.log(`\n✅ 连接成功!`);
            console.log(`管理员数量: ${data.length}`);
            if (data.length > 0) {
                console.log(`管理员用户名: ${data[0].username}`);
            }
            return true;
        } else {
            const error = await response.text();
            console.log(`❌ 连接失败: ${error}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ 网络错误: ${error.message}`);
        return false;
    }
}

async function testAdminLogin() {
    console.log('\n=== 测试管理员登录 ===\n');
    
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/admins?select=*&username=eq.admin&password=eq.admin123`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        
        console.log(`HTTP 状态码: ${response.status}`);
        
        if (response.ok) {
            const data = await response.json();
            if (data.length > 0) {
                console.log(`✅ 管理员登录成功!`);
                console.log(`用户ID: ${data[0].id}`);
                console.log(`用户名: ${data[0].username}`);
                console.log(`姓名: ${data[0].name}`);
                return true;
            } else {
                console.log(`❌ 登录失败: 未找到匹配的管理员`);
                return false;
            }
        } else {
            const error = await response.text();
            console.log(`❌ 登录失败: ${error}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ 网络错误: ${error.message}`);
        return false;
    }
}

async function testUserLogin() {
    console.log('\n=== 测试用户登录 ===\n');
    
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/users?select=*&phone=eq.13812345678&password=eq.123456&status=eq.active`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });
        
        console.log(`HTTP 状态码: ${response.status}`);
        
        if (response.ok) {
            const data = await response.json();
            if (data.length > 0) {
                console.log(`✅ 用户登录成功!`);
                console.log(`用户ID: ${data[0].id}`);
                console.log(`手机号: ${data[0].phone}`);
                console.log(`姓名: ${data[0].name}`);
                return true;
            } else {
                console.log(`❌ 登录失败: 未找到匹配的用户`);
                return false;
            }
        } else {
            const error = await response.text();
            console.log(`❌ 登录失败: ${error}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ 网络错误: ${error.message}`);
        return false;
    }
}

async function main() {
    console.log('🚀 婚恋红娘系统 - 登录诊断工具\n');
    
    const connSuccess = await testSupabaseConnection();
    
    if (connSuccess) {
        await testAdminLogin();
        await testUserLogin();
    }
    
    console.log('\n=== 诊断完成 ===');
}

main().catch(console.error);