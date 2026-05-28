-- 先删除所有现有表（按依赖关系顺序删除）
DROP TABLE IF EXISTS activity_registrations CASCADE;
DROP TABLE IF EXISTS activities CASCADE;
DROP TABLE IF EXISTS agency_requests CASCADE;
DROP TABLE IF EXISTS blacklist CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS likes CASCADE;
DROP TABLE IF EXISTS user_activity_preferences CASCADE;
DROP TABLE IF EXISTS user_privacy CASCADE;
DROP TABLE IF EXISTS user_interests CASCADE;
DROP TABLE IF EXISTS user_requirements CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS agencies CASCADE;
DROP TABLE IF EXISTS admins CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS system_config CASCADE;
DROP TABLE IF EXISTS interests CASCADE;
DROP TABLE IF EXISTS education_options CASCADE;
DROP TABLE IF EXISTS income_options CASCADE;
DROP TABLE IF EXISTS marital_status_options CASCADE;
DROP TABLE IF EXISTS activity_types CASCADE;

-- 用户表
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255),
    name VARCHAR(50),
    gender VARCHAR(10),
    birthday DATE,
    height INTEGER,
    weight INTEGER,
    education VARCHAR(50),
    occupation VARCHAR(100),
    income VARCHAR(50),
    marital_status VARCHAR(20),
    province VARCHAR(50),
    city VARCHAR(50),
    district VARCHAR(50),
    street VARCHAR(50),
    wechat VARCHAR(50),
    wechat_visible BOOLEAN DEFAULT false,
    avatar_url TEXT,
    photos TEXT[],
    declaration TEXT,
    agency_id UUID,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    -- 性格兴趣字段
    personality TEXT[],
    interests TEXT[],
    activity_types TEXT[],
    accept_pet VARCHAR(20),
    schedule VARCHAR(20),
    -- 婚恋价值观字段
    finance_view VARCHAR(20),
    live_with_parents VARCHAR(20),
    expected_children VARCHAR(20),
    self_description TEXT,
    -- 生活习惯字段
    smoking VARCHAR(20),
    drinking VARCHAR(20),
    -- 资产信息
    property VARCHAR(20),
    car VARCHAR(20),
    -- 隐私设置
    privacy_visibility VARCHAR(20) DEFAULT 'all'
);

-- 用户照片表
CREATE TABLE user_photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    is_avatar BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 用户择偶要求表
CREATE TABLE user_requirements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    scheme_type VARCHAR(20) DEFAULT 'standard',
    -- 年龄要求
    min_age INTEGER,
    max_age INTEGER,
    age_importance VARCHAR(20) DEFAULT 'normal',
    -- 身高要求
    min_height INTEGER,
    max_height INTEGER,
    height_importance VARCHAR(20) DEFAULT 'normal',
    -- 学历要求
    education TEXT[],
    education_importance VARCHAR(20) DEFAULT 'normal',
    -- 收入要求
    min_income VARCHAR(50),
    max_income VARCHAR(50),
    income_importance VARCHAR(20) DEFAULT 'normal',
    -- 婚姻状况要求
    marital_status TEXT[],
    marital_importance VARCHAR(20) DEFAULT 'normal',
    -- 地区要求
    province VARCHAR(50),
    province_importance VARCHAR(20) DEFAULT 'normal',
    -- 体型要求
    body_type VARCHAR(20),
    -- 生活习惯要求
    smoking VARCHAR(20),
    drinking VARCHAR(20),
    -- 性格偏好
    personality TEXT[],
    personality_importance VARCHAR(20) DEFAULT 'normal',
    -- 兴趣重合要求
    min_interest_overlap INTEGER DEFAULT 0,
    -- 活动偏好
    activities TEXT[],
    min_activity_overlap INTEGER DEFAULT 0,
    -- 价值观要求
    values VARCHAR(20),
    -- 房产车辆要求
    house_required VARCHAR(20),
    car_required VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 兴趣爱好选项表
CREATE TABLE interests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 用户兴趣爱好表
CREATE TABLE user_interests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    interest_id UUID REFERENCES interests(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 活动类型表
CREATE TABLE activity_types (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 线下活动意愿表
CREATE TABLE user_activity_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    willing BOOLEAN DEFAULT false,
    activity_types TEXT[],
    created_at TIMESTAMP DEFAULT NOW()
);

-- 隐私设置表
CREATE TABLE user_privacy (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    contact_visibility VARCHAR(20) DEFAULT 'public',
    profile_visibility VARCHAR(20) DEFAULT 'all',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 中介表
CREATE TABLE agencies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 管理员表
CREATE TABLE admins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT NOW()
);

-- 点赞表
CREATE TABLE likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id)
);

-- 私信表
CREATE TABLE messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    image_url TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 中介联系请求表
CREATE TABLE agency_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    agency_id UUID REFERENCES agencies(id),
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);

-- 黑名单表
CREATE TABLE blacklist (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    blocked_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, blocked_user_id)
);

-- 线下活动表
CREATE TABLE activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    activity_time TIMESTAMP,
    location VARCHAR(200),
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    deadline TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    created_by UUID REFERENCES admins(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 活动报名表
CREATE TABLE activity_registrations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    activity_id UUID REFERENCES activities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    registered_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(activity_id, user_id)
);

-- 公告表
CREATE TABLE announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    is_pinned BOOLEAN DEFAULT false,
    expire_at TIMESTAMP,
    created_by UUID REFERENCES admins(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 系统配置表
CREATE TABLE system_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 学历选项表
CREATE TABLE education_options (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    sort_order INTEGER DEFAULT 0
);

-- 收入区间选项表
CREATE TABLE income_options (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    min_value INTEGER,
    max_value INTEGER,
    sort_order INTEGER DEFAULT 0
);

-- 婚姻状况选项表
CREATE TABLE marital_status_options (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    sort_order INTEGER DEFAULT 0
);

-- 插入默认数据

-- 学历选项
INSERT INTO education_options (name, sort_order) VALUES
('小学', 1),
('初中', 2),
('高中', 3),
('大专', 4),
('本科', 5),
('硕士', 6),
('博士', 7);

-- 收入区间
INSERT INTO income_options (name, min_value, max_value, sort_order) VALUES
('3000以下', 0, 3000, 1),
('3000-5000', 3000, 5000, 2),
('5000-8000', 5000, 8000, 3),
('8000-10000', 8000, 10000, 4),
('10000-15000', 10000, 15000, 5),
('15000-20000', 15000, 20000, 6),
('20000-30000', 20000, 30000, 7),
('30000以上', 30000, 999999, 8);

-- 婚姻状况
INSERT INTO marital_status_options (name, sort_order) VALUES
('未婚', 1),
('离异', 2),
('丧偶', 3);

-- 兴趣爱好
INSERT INTO interests (name, sort_order) VALUES
('运动健身', 1),
('旅游', 2),
('阅读', 3),
('音乐', 4),
('电影', 5),
('美食', 6),
('摄影', 7),
('游戏', 8),
('宠物', 9),
('手工', 10),
('绘画', 11),
('舞蹈', 12),
('瑜伽', 13),
('钓鱼', 14),
('园艺', 15);

-- 活动类型
INSERT INTO activity_types (name, sort_order) VALUES
('运动', 1),
('聚餐', 2),
('旅行', 3),
('读书会', 4),
('KTV', 5),
('户外徒步', 6),
('桌游', 7);

-- 系统配置
INSERT INTO system_config (config_key, config_value, description) VALUES
('daily_like_limit', '10', '每日点赞次数限制'),
('min_password_length', '6', '密码最小长度');

-- 默认管理员
INSERT INTO admins (username, password, name, role) VALUES
('admin', 'admin123', '系统管理员', 'super_admin');