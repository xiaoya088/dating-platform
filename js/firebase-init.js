// Firebase 初始化脚本
// 请在 HTML 页面中引入此脚本

// 动态加载 Firebase SDK
function loadFirebaseSDK(callback) {
  const script = document.createElement('script');
  script.src = 'https://www.gstatic.com/firebasejs/9.22.1/firebase-app.js';
  script.onload = () => {
    // 加载其他 Firebase 模块
    const modules = [
      'https://www.gstatic.com/firebasejs/9.22.1/firebase-auth.js',
      'https://www.gstatic.com/firebasejs/9.22.1/firebase-firestore.js',
      'https://www.gstatic.com/firebasejs/9.22.1/firebase-storage.js'
    ];
    
    let loaded = 0;
    modules.forEach(src => {
      const moduleScript = document.createElement('script');
      moduleScript.src = src;
      moduleScript.onload = () => {
        loaded++;
        if (loaded === modules.length && callback) {
          callback();
        }
      };
      document.head.appendChild(moduleScript);
    });
  };
  script.onerror = () => {
    console.warn('Firebase SDK 加载失败，将使用 localStorage 模式');
    if (callback) callback();
  };
  document.head.appendChild(script);
}

// 初始化 Firebase App
function initFirebase() {
  if (typeof firebase !== 'undefined') {
    try {
      // 检查是否已初始化
      const apps = firebase.getApps();
      if (apps.length === 0) {
        // 从配置文件获取配置
        fetch('/firebase-config.js')
          .then(response => response.text())
          .then(text => {
            // 解析配置
            const match = text.match(/const firebaseConfig = (\{[\s\S]*?\});/);
            if (match) {
              const config = JSON.parse(match[1]);
              firebase.initializeApp(config);
              console.log('Firebase 初始化成功');
            }
          })
          .catch(() => {
            console.warn('无法加载 Firebase 配置');
          });
      }
    } catch (error) {
      console.warn('Firebase 初始化失败:', error);
    }
  }
}

// 页面加载完成后初始化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    loadFirebaseSDK(initFirebase);
  });
} else {
  loadFirebaseSDK(initFirebase);
}