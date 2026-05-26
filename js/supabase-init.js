// Supabase 初始化脚本
// 全局变量，供页面脚本使用
let supabase = null;

async function initSupabaseClient() {
  try {
    // 加载配置
    const response = await fetch('/supabase-config.js');
    const configText = await response.text();
    
    // 解析配置
    const urlMatch = configText.match(/url:\s*["']([^"']+)["']/);
    const keyMatch = configText.match(/anonKey:\s*["']([^"']+)["']/);
    
    if (urlMatch && keyMatch && window.supabase) {
      supabase = window.supabase.createClient(urlMatch[1], keyMatch[1]);
      console.log('Supabase 初始化成功');
      
      // 测试连接
      try {
        await supabase.from('users').select('*').limit(1);
        console.log('Supabase 连接测试成功');
      } catch (error) {
        console.warn('Supabase 连接测试失败，将使用 localStorage 模式:', error.message);
      }
    } else {
      console.warn('Supabase 配置不完整或 SDK 未加载，使用 localStorage 模式');
    }
  } catch (error) {
    console.warn('加载 Supabase 配置失败，使用 localStorage 模式:', error.message);
  }
}

// 页面加载时初始化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initSupabaseClient);
} else {
  initSupabaseClient();
}

// 提供全局访问方法
window.getSupabase = () => supabase;