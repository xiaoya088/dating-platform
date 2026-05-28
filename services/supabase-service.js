// Supabase 数据服务
import { supabaseConfig } from '../supabase-config.js';

let supabase = null;
let initAttempted = false;

async function initializeSupabase() {
  if (supabase) return;
  if (initAttempted) return;
  
  initAttempted = true;
  
  // 等待 Supabase SDK 加载
  if (typeof window !== 'undefined') {
    // 如果 SDK 还没加载，等待一下
    if (!window.supabase) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    if (window.supabase) {
      try {
        supabase = window.supabase.createClient(supabaseConfig.url, supabaseConfig.anonKey);
        // 测试连接
        await supabase.from('users').select('*').limit(1);
        console.log('✅ Supabase 初始化成功');
      } catch (error) {
        console.error('❌ Supabase 初始化失败:', error.message);
        supabase = null;
        initAttempted = false; // 允许重试
      }
    }
  }
}

// 用户服务
export const UserService = {
  getAllUsers: async () => {
    initializeSupabase();
    if (!supabase) return JSON.parse(localStorage.getItem('datingUsers') || '[]');
    
    try {
      const { data, error } = await supabase.from('users').select('*');
      return error ? JSON.parse(localStorage.getItem('datingUsers') || '[]') : data;
    } catch {
      return JSON.parse(localStorage.getItem('datingUsers') || '[]');
    }
  },

  getUserById: async (userId) => {
    initializeSupabase();
    if (!supabase) return null;
    
    try {
      const { data, error } = await supabase.from('users').select('*').eq('id', userId).single();
      return error ? null : data;
    } catch {
      return null;
    }
  },

  createUser: async (userData) => {
    initializeSupabase();
    if (!supabase) {
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      if (users.find(u => u.phone === userData.phone)) {
        return { success: false, user: null, message: '该手机号已被注册' };
      }
      users.push(userData);
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return { success: true, user: userData, message: '注册成功' };
    }
    
    try {
      const { data, error } = await supabase.from('users').insert([userData]).select().single();
      if (error) {
        if (error.message.includes('duplicate key') || error.message.includes('unique')) {
          return { success: false, user: null, message: '该手机号已被注册' };
        }
        return { success: false, user: null, message: error.message };
      }
      return { success: true, user: data, message: '注册成功' };
    } catch (e) {
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      if (users.find(u => u.phone === userData.phone)) {
        return { success: false, user: null, message: '该手机号已被注册' };
      }
      users.push(userData);
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return { success: true, user: userData, message: '注册成功（本地存储）' };
    }
  },

  updateUser: async (userId, userData) => {
    initializeSupabase();
    if (!supabase) {
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      const index = users.findIndex(u => u.id === userId);
      if (index !== -1) users[index] = { ...users[index], ...userData };
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return users[index];
    }
    
    try {
      const { data, error } = await supabase.from('users').update(userData).eq('id', userId).select().single();
      return error ? null : data;
    } catch {
      return null;
    }
  },

  deleteUser: async (userId) => {
    initializeSupabase();
    if (!supabase) {
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]').filter(u => u.id !== userId);
      localStorage.setItem('datingUsers', JSON.stringify(users));
      return true;
    }
    
    try {
      const { error } = await supabase.from('users').delete().eq('id', userId);
      return !error;
    } catch {
      return false;
    }
  },

  login: async (phone, password) => {
    initializeSupabase();
    if (!supabase) {
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      return users.find(u => u.phone === phone && u.password === password);
    }
    
    try {
      const { data, error } = await supabase.from('users').select('*').eq('phone', phone).eq('password', password).single();
      return error ? null : data;
    } catch {
      const users = JSON.parse(localStorage.getItem('datingUsers') || '[]');
      return users.find(u => u.phone === phone && u.password === password);
    }
  },

  register: async (userData) => {
    return await UserService.createUser(userData);
  }
};

// 内容审核服务
export const ContentService = {
  getPosts: async (status = 'all') => {
    initializeSupabase();
    if (!supabase) return JSON.parse(localStorage.getItem('datingPosts') || '[]');
    
    try {
      let query = supabase.from('posts').select('*');
      if (status !== 'all') query = query.eq('status', status);
      const { data, error } = await query;
      return error ? JSON.parse(localStorage.getItem('datingPosts') || '[]') : data;
    } catch {
      return JSON.parse(localStorage.getItem('datingPosts') || '[]');
    }
  },

  updatePostStatus: async (postId, status) => {
    initializeSupabase();
    if (!supabase) {
      const posts = JSON.parse(localStorage.getItem('datingPosts') || '[]');
      const index = posts.findIndex(p => p.id === postId);
      if (index !== -1) posts[index].status = status;
      localStorage.setItem('datingPosts', JSON.stringify(posts));
      return posts[index];
    }
    
    try {
      const { data, error } = await supabase.from('posts').update({ status }).eq('id', postId).select().single();
      return error ? null : data;
    } catch {
      return null;
    }
  }
};

// 举报服务
export const ReportService = {
  getReports: async () => {
    initializeSupabase();
    if (!supabase) return JSON.parse(localStorage.getItem('datingReports') || '[]');
    
    try {
      const { data, error } = await supabase.from('reports').select('*');
      return error ? JSON.parse(localStorage.getItem('datingReports') || '[]') : data;
    } catch {
      return JSON.parse(localStorage.getItem('datingReports') || '[]');
    }
  },

  createReport: async (reportData) => {
    initializeSupabase();
    if (!supabase) {
      const reports = JSON.parse(localStorage.getItem('datingReports') || '[]');
      reports.push(reportData);
      localStorage.setItem('datingReports', JSON.stringify(reports));
      return reportData;
    }
    
    try {
      const { data, error } = await supabase.from('reports').insert([reportData]).select().single();
      return error ? reportData : data;
    } catch {
      const reports = JSON.parse(localStorage.getItem('datingReports') || '[]');
      reports.push(reportData);
      localStorage.setItem('datingReports', JSON.stringify(reports));
      return reportData;
    }
  },

  handleReport: async (reportId, status) => {
    initializeSupabase();
    if (!supabase) {
      const reports = JSON.parse(localStorage.getItem('datingReports') || '[]');
      const index = reports.findIndex(r => r.id === reportId);
      if (index !== -1) reports[index].status = status;
      localStorage.setItem('datingReports', JSON.stringify(reports));
      return reports[index];
    }
    
    try {
      const { data, error } = await supabase.from('reports').update({ status }).eq('id', reportId).select().single();
      return error ? null : data;
    } catch {
      return null;
    }
  }
};

// 活动服务
export const ActivityService = {
  getActivities: async () => {
    initializeSupabase();
    if (!supabase) return JSON.parse(localStorage.getItem('activities') || '[]');
    
    try {
      const { data, error } = await supabase.from('activities').select('*');
      return error ? JSON.parse(localStorage.getItem('activities') || '[]') : data;
    } catch {
      return JSON.parse(localStorage.getItem('activities') || '[]');
    }
  },

  createActivity: async (activityData) => {
    initializeSupabase();
    if (!supabase) {
      const activities = JSON.parse(localStorage.getItem('activities') || '[]');
      activities.push(activityData);
      localStorage.setItem('activities', JSON.stringify(activities));
      return activityData;
    }
    
    try {
      const { data, error } = await supabase.from('activities').insert([activityData]).select().single();
      return error ? activityData : data;
    } catch {
      const activities = JSON.parse(localStorage.getItem('activities') || '[]');
      activities.push(activityData);
      localStorage.setItem('activities', JSON.stringify(activities));
      return activityData;
    }
  },

  deleteActivity: async (activityId) => {
    initializeSupabase();
    if (!supabase) {
      const activities = JSON.parse(localStorage.getItem('activities') || '[]').filter(a => a.id !== activityId);
      localStorage.setItem('activities', JSON.stringify(activities));
      return true;
    }
    
    try {
      const { error } = await supabase.from('activities').delete().eq('id', activityId);
      return !error;
    } catch {
      return false;
    }
  }
};

// 敏感词服务
export const SensitiveWordService = {
  getWords: async () => {
    initializeSupabase();
    if (!supabase) return JSON.parse(localStorage.getItem('sensitiveWords') || '[]');
    
    try {
      const { data, error } = await supabase.from('sensitivewords').select('*');
      return error ? JSON.parse(localStorage.getItem('sensitiveWords') || '[]') : data;
    } catch {
      return JSON.parse(localStorage.getItem('sensitiveWords') || '[]');
    }
  },

  addWord: async (word) => {
    initializeSupabase();
    if (!supabase) {
      const words = JSON.parse(localStorage.getItem('sensitiveWords') || '[]');
      words.push({ word, createdAt: new Date().toISOString() });
      localStorage.setItem('sensitiveWords', JSON.stringify(words));
      return word;
    }
    
    try {
      const { error } = await supabase.from('sensitivewords').insert([{ word, createdAt: new Date().toISOString() }]);
      return error ? null : word;
    } catch {
      const words = JSON.parse(localStorage.getItem('sensitiveWords') || '[]');
      words.push({ word, createdAt: new Date().toISOString() });
      localStorage.setItem('sensitiveWords', JSON.stringify(words));
      return word;
    }
  },

  deleteWord: async (wordId) => {
    initializeSupabase();
    if (!supabase) {
      const words = JSON.parse(localStorage.getItem('sensitiveWords') || '[]').filter((_, index) => index !== parseInt(wordId));
      localStorage.setItem('sensitiveWords', JSON.stringify(words));
      return true;
    }
    
    try {
      const { error } = await supabase.from('sensitivewords').delete().eq('id', wordId);
      return !error;
    } catch {
      return false;
    }
  }
};

// 初始化脚本
export function initSupabase() {
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
  script.onload = initializeSupabase;
  script.onerror = () => console.warn('Supabase SDK 加载失败，使用 localStorage 模式');
  document.head.appendChild(script);
}