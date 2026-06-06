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

function getSupabaseClient() {
    return getSupabase();
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
        .select('id, phone, name, gender, avatar_url, status, created_at, updated_at')
        .eq('phone', phone)
        .eq('password', password)
        .eq('status', 'active')
        .single();
    
    if (error) {
        throw new Error('手机号或密码错误');
    }
    return data;
}

async function agencySignIn(username, password) {
    const supabase = ensureSupabase();
    
    const { data, error } = await supabase
        .from('agencies')
        .select('id, username, name, phone, status, created_at')
        .eq('username', username)
        .eq('password', password)
        .eq('status', 'active')
        .single();
    
    if (error) {
        throw new Error('用户名或密码错误');
    }
    return data;
}

async function adminSignIn(username, password) {
    const supabase = ensureSupabase();
    
    const { data, error } = await supabase
        .from('admins')
        .select('id, username, name, role, created_at')
        .eq('username', username)
        .eq('password', password)
        .single();
    
    if (error) {
        throw new Error('用户名或密码错误');
    }
    return data;
}

function getCurrentUser() {
    try {
        const userStr = sessionStorage.getItem('currentUser');
        if (!userStr) return null;
        return JSON.parse(userStr);
    } catch (e) {
        return null;
    }
}

function setCurrentUser(user) {
    if (user) {
        sessionStorage.setItem('currentUser', JSON.stringify(user));
    } else {
        sessionStorage.removeItem('currentUser');
    }
}

function clearCurrentUser() {
    sessionStorage.removeItem('currentUser');
}

function isLoggedIn() {
    return getCurrentUser() !== null;
}

function logout() {
    clearCurrentUser();
    window.location.href = 'index.html';
}

let currentPhotoPreview = null;

function openPhotoPreview(url) {
    if (currentPhotoPreview) {
        document.body.removeChild(currentPhotoPreview);
    }
    
    currentPhotoPreview = document.createElement('div');
    currentPhotoPreview.className = 'photo-preview-modal';
    currentPhotoPreview.innerHTML = `
        <button class="close-btn" onclick="closePhotoPreview()">×</button>
        <div class="img-container">
            <img src="${url}" alt="照片预览">
        </div>
        <div class="hint">点击任意处关闭</div>
    `;
    
    currentPhotoPreview.addEventListener('click', function(e) {
        if (e.target === currentPhotoPreview || e.target.classList.contains('img-container') === false) {
            closePhotoPreview();
        }
    });
    
    document.body.appendChild(currentPhotoPreview);
    
    document.addEventListener('keydown', handlePhotoPreviewKeydown);
}

function closePhotoPreview() {
    if (currentPhotoPreview) {
        document.body.removeChild(currentPhotoPreview);
        currentPhotoPreview = null;
    }
    document.removeEventListener('keydown', handlePhotoPreviewKeydown);
}

function handlePhotoPreviewKeydown(e) {
    if (e.key === 'Escape') {
        closePhotoPreview();
    }
}

function createPhotoHtml(photos, size = 'normal') {
    if (!photos) return '<span style="color: #888;">暂无照片</span>';
    if (typeof photos === 'string') {
        try {
            photos = JSON.parse(photos);
        } catch (e) {
            return '<span style="color: #888;">暂无照片</span>';
        }
    }
    if (!Array.isArray(photos) || photos.length === 0) {
        return '<span style="color: #888;">暂无照片</span>';
    }
    
    if (size === 'large') {
        return photos.map((photo, idx) => 
            `<div class="photo-item" style="width: 200px; height: 250px;">
                <img src="${photo}" class="photo-clickable" onclick="openPhotoPreview('${photo}')" alt="照片${idx + 1}">
            </div>`
        ).join('');
    } else {
        return photos.map((photo, idx) => 
            `<img src="${photo}" class="photo-clickable" style="max-width: 120px; max-height: 150px; margin: 5px; border-radius: 8px; object-fit: cover; cursor: pointer;" onclick="openPhotoPreview('${photo}')" alt="照片${idx + 1}">`
        ).join('');
    }
}

function getUserPhotoUrl(user) {
    if (!user) return 'https://via.placeholder.com/100?text=无头像';
    let photos = user.photos;
    if (typeof photos === 'string') {
        try { photos = JSON.parse(photos); } catch (e) { photos = []; }
    }
    if (Array.isArray(photos) && photos.length > 0) return photos[0];
    return 'https://via.placeholder.com/100?text=无头像';
}