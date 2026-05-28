// Firebase 数据服务
import { firebaseConfig } from '../firebase-config.js';

// 初始化 Firebase（如果未初始化）
let firebaseApp = null;
let db = null;
let auth = null;

function initializeFirebase() {
  if (!firebaseApp && typeof firebase !== 'undefined') {
    firebaseApp = firebase.initializeApp(firebaseConfig);
    db = firebase.firestore();
    auth = firebase.auth();
  }
}

// 用户服务
export const UserService = {
  // 获取所有用户
  getAllUsers: async () => {
    initializeFirebase();
    if (!db) return [];
    
    try {
      const snapshot = await db.collection('users').get();
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
      console.error('获取用户列表失败:', error);
      // 回退到 localStorage
      return JSON.parse(localStorage.getItem('datingUsers') || '[]');
    }
  },

  // 获取单个用户
  getUserById: async (userId) => {
    initializeFirebase();
    if (!db) return null;
    
    try {
      const doc = await db.collection('users').doc(userId).get();
      return doc.exists ? { id: doc.id, ...doc.data() } : null;
    } catch (error) {
      console.error('获取用户失败:', error);
      return null;
    }
  },

  // 创建用户
  createUser: async (userData) => {
    initializeFirebase();
    if (!db) {
      // 回退到 localStorage
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      users.push(userData);
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return userData;
    }
    
    try {
      const docRef = await db.collection('users').add(userData);
      return { id: docRef.id, ...userData };
    } catch (error) {
      console.error('创建用户失败:', error);
      throw error;
    }
  },

  // 更新用户
  updateUser: async (userId, userData) => {
    initializeFirebase();
    if (!db) {
      // 回退到 localStorage
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      const index = users.findIndex(u => u.id === userId);
      if (index !== -1) {
        users[index] = { ...users[index], ...userData };
        localStorage.setItem('datingUsers', JSON.stringify(users));
      }
      return users[index];
    }
    
    try {
      await db.collection('users').doc(userId).update(userData);
      return { id: userId, ...userData };
    } catch (error) {
      console.error('更新用户失败:', error);
      throw error;
    }
  },

  // 删除用户
  deleteUser: async (userId) => {
    initializeFirebase();
    if (!db) {
      // 回退到 localStorage
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]').filter(u => u.id !== userId);
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return true;
    }
    
    try {
      await db.collection('users').doc(userId).delete();
      return true;
    } catch (error) {
      console.error('删除用户失败:', error);
      throw error;
    }
  },

  // 登录
  login: async (phone, password) => {
    initializeFirebase();
    if (!auth || !db) {
      // 回退到 localStorage
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      return users.find(u => u.phone === phone && u.password === password);
    }
    
    try {
      // 使用邮箱登录（Firebase 需要邮箱格式）
      const email = `${phone}@dating-app.com`;
      const userCredential = await auth.signInWithEmailAndPassword(email, password);
      
      // 获取用户额外信息
      const userDoc = await db.collection('users').where('phone', '==', phone).get();
      if (!userDoc.empty) {
        return { id: userDoc.docs[0].id, ...userDoc.docs[0].data() };
      }
      return null;
    } catch (error) {
      console.error('登录失败:', error);
      // 回退到 localStorage
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      return users.find(u => u.phone === phone && u.password === password);
    }
  },

  // 注册
  register: async (userData) => {
    initializeFirebase();
    if (!auth || !db) {
      // 回退到 localStorage
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      users.push(userData);
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return userData;
    }
    
    try {
      // 创建 Firebase 认证用户（使用邮箱格式）
      const email = `${userData.phone}@dating-app.com`;
      const userCredential = await auth.createUserWithEmailAndPassword(email, userData.password);
      
      // 存储用户额外信息
      await db.collection('users').doc(userCredential.user.uid).set(userData);
      return { id: userCredential.user.uid, ...userData };
    } catch (error) {
      console.error('注册失败:', error);
      // 回退到 localStorage
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      users.push(userData);
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return userData;
    }
  }
};

// 内容审核服务
export const ContentService = {
  // 获取动态列表
  getPosts: async (status = 'all') => {
    initializeFirebase();
    if (!db) {
      return JSON.parse(localStorage.getItem('datingPosts') || '[]');
    }
    
    try {
      let query = db.collection('posts');
      if (status !== 'all') {
        query = query.where('status', '==', status);
      }
      const snapshot = await query.get();
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
      console.error('获取动态失败:', error);
      return JSON.parse(localStorage.getItem('datingPosts') || '[]');
    }
  },

  // 更新动态状态
  updatePostStatus: async (postId, status) => {
    initializeFirebase();
    if (!db) {
      const posts = JSON.parse(localStorage.getItem('datingPosts') || '[]');
      const index = posts.findIndex(p => p.id === postId);
      if (index !== -1) {
        posts[index].status = status;
        localStorage.setItem('datingPosts', JSON.stringify(posts));
      }
      return posts[index];
    }
    
    try {
      await db.collection('posts').doc(postId).update({ status });
      return { id: postId, status };
    } catch (error) {
      console.error('更新动态状态失败:', error);
      throw error;
    }
  }
};

// 举报服务
export const ReportService = {
  // 获取举报列表
  getReports: async () => {
    initializeFirebase();
    if (!db) {
      return JSON.parse(localStorage.getItem('datingReports') || '[]');
    }
    
    try {
      const snapshot = await db.collection('reports').get();
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
      console.error('获取举报失败:', error);
      return JSON.parse(localStorage.getItem('datingReports') || '[]');
    }
  },

  // 创建举报
  createReport: async (reportData) => {
    initializeFirebase();
    if (!db) {
      const reports = JSON.parse(localStorage.getItem('datingReports') || '[]');
      reports.push(reportData);
      localStorage.setItem('datingReports', JSON.stringify(reports));
      return reportData;
    }
    
    try {
      const docRef = await db.collection('reports').add(reportData);
      return { id: docRef.id, ...reportData };
    } catch (error) {
      console.error('创建举报失败:', error);
      throw error;
    }
  },

  // 处理举报
  handleReport: async (reportId, status) => {
    initializeFirebase();
    if (!db) {
      const reports = JSON.parse(localStorage.getItem('datingReports') || '[]');
      const index = reports.findIndex(r => r.id === reportId);
      if (index !== -1) {
        reports[index].status = status;
        localStorage.setItem('datingReports', JSON.stringify(reports));
      }
      return reports[index];
    }
    
    try {
      await db.collection('reports').doc(reportId).update({ status });
      return { id: reportId, status };
    } catch (error) {
      console.error('处理举报失败:', error);
      throw error;
    }
  }
};

// 活动服务
export const ActivityService = {
  // 获取活动类型
  getActivities: async () => {
    initializeFirebase();
    if (!db) {
      return JSON.parse(localStorage.getItem('activities') || '[]');
    }
    
    try {
      const snapshot = await db.collection('activities').get();
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
      console.error('获取活动类型失败:', error);
      return JSON.parse(localStorage.getItem('activities') || '[]');
    }
  },

  // 创建活动类型
  createActivity: async (activityData) => {
    initializeFirebase();
    if (!db) {
      const activities = JSON.parse(localStorage.getItem('activities') || '[]');
      activities.push(activityData);
      localStorage.setItem('activities', JSON.stringify(activities));
      return activityData;
    }
    
    try {
      const docRef = await db.collection('activities').add(activityData);
      return { id: docRef.id, ...activityData };
    } catch (error) {
      console.error('创建活动类型失败:', error);
      throw error;
    }
  },

  // 删除活动类型
  deleteActivity: async (activityId) => {
    initializeFirebase();
    if (!db) {
      const activities = JSON.parse(localStorage.getItem('activities') || '[]').filter(a => a.id !== activityId);
      localStorage.setItem('activities', JSON.stringify(activities));
      return true;
    }
    
    try {
      await db.collection('activities').doc(activityId).delete();
      return true;
    } catch (error) {
      console.error('删除活动类型失败:', error);
      throw error;
    }
  }
};

// 敏感词服务
export const SensitiveWordService = {
  // 获取敏感词列表
  getWords: async () => {
    initializeFirebase();
    if (!db) {
      return JSON.parse(localStorage.getItem('sensitiveWords') || '[]');
    }
    
    try {
      const snapshot = await db.collection('sensitiveWords').get();
      return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
      console.error('获取敏感词失败:', error);
      return JSON.parse(localStorage.getItem('sensitiveWords') || '[]');
    }
  },

  // 添加敏感词
  addWord: async (word) => {
    initializeFirebase();
    if (!db) {
      const words = JSON.parse(localStorage.getItem('sensitiveWords') || '[]');
      words.push({ word, createdAt: new Date().toISOString() });
      localStorage.setItem('sensitiveWords', JSON.stringify(words));
      return word;
    }
    
    try {
      await db.collection('sensitiveWords').add({ word, createdAt: new Date() });
      return word;
    } catch (error) {
      console.error('添加敏感词失败:', error);
      throw error;
    }
  },

  // 删除敏感词
  deleteWord: async (wordId) => {
    initializeFirebase();
    if (!db) {
      const words = JSON.parse(localStorage.getItem('sensitiveWords') || '[]').filter((_, index) => index !== parseInt(wordId));
      localStorage.setItem('sensitiveWords', JSON.stringify(words));
      return true;
    }
    
    try {
      await db.collection('sensitiveWords').doc(wordId).delete();
      return true;
    } catch (error) {
      console.error('删除敏感词失败:', error);
      throw error;
    }
  }
};