const SUPABASE_URL = 'https://awhpfdhxcoycxgfhpfoy.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_VyBOeg7kGc_i905NOmd69g_KkSbsOpA';

let supabaseClient = null;

function initSupabase() {
    if (!supabaseClient && typeof supabase !== 'undefined') {
        try {
            supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
            console.log('✅ Supabase 客户端初始化成功');
        } catch (e) {
            console.error('❌ Supabase 客户端初始化失败:', e);
            throw e;
        }
    }
    return supabaseClient;
}

function ensureSupabase() {
    const client = initSupabase();
    if (!client) {
        throw new Error('Supabase 初始化失败，请检查网络连接或配置');
    }
    return client;
}

function getSupabase() {
    if (!supabaseClient) {
        initSupabase();
    }
    return supabaseClient;
}

async function testConnection() {
    const client = getSupabase();
    if (!client) {
        return { success: false, message: '客户端未初始化' };
    }
    try {
        const { data, error } = await client.from('admins').select('id').limit(1);
        if (error) {
            return { success: false, message: error.message };
        }
        return { success: true, message: '连接成功' };
    } catch (e) {
        return { success: false, message: e.message };
    }
}

async function signUp(phone, password, userData = {}) {
    const supabase = getSupabase();
    
    const { data, error } = await supabase
        .from('users')
        .insert([{
            phone: phone,
            password: password,
            ...userData,
            created_at: new Date().toISOString()
        }])
        .select();
    
    if (error) throw error;
    return data[0];
}

async function signIn(phone, password) {
    const supabase = ensureSupabase();
    
    const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('phone', phone)
        .eq('password', password)
        .eq('status', 'active')
        .single();
    
    if (error) {
        console.error('登录错误:', error);
        throw new Error('手机号或密码错误');
    }
    return data;
}

async function agencySignIn(username, password) {
    const supabase = ensureSupabase();
    
    const { data, error } = await supabase
        .from('agencies')
        .select('*')
        .eq('username', username)
        .eq('password', password)
        .eq('status', 'active')
        .single();
    
    if (error) {
        console.error('中介登录错误:', error);
        throw new Error('用户名或密码错误');
    }
    return data;
}

async function adminSignIn(username, password) {
    const supabase = ensureSupabase();
    
    const { data, error } = await supabase
        .from('admins')
        .select('*')
        .eq('username', username)
        .eq('password', password)
        .single();
    
    if (error) {
        console.error('管理员登录错误:', error);
        throw new Error('用户名或密码错误');
    }
    return data;
}

function getCurrentUser() {
    try {
        const userStr = localStorage.getItem('currentUser');
        if (!userStr) return null;
        
        const user = JSON.parse(userStr);
        console.log('getCurrentUser:', user);
        return user;
    } catch (e) {
        console.error('getCurrentUser 错误:', e);
        return null;
    }
}

function setCurrentUser(user) {
    try {
        const userStr = JSON.stringify(user);
        localStorage.setItem('currentUser', userStr);
        console.log('setCurrentUser:', user);
        
        // 验证写入是否成功
        const saved = localStorage.getItem('currentUser');
        if (!saved) {
            console.error('localStorage 写入失败');
            return false;
        }
        return true;
    } catch (e) {
        console.error('setCurrentUser 错误:', e);
        return false;
    }
}

function clearCurrentUser() {
    localStorage.removeItem('currentUser');
}

function isLoggedIn() {
    return getCurrentUser() !== null;
}

function logout() {
    clearCurrentUser();
    window.location.href = 'index.html';
}