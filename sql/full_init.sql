-- 婚恋红娘系统数据库初始化脚本
-- 项目名: xiaoya088

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
    -- 隐私设置
    privacy_visibility VARCHAR(20) DEFAULT 'all'
);

-- 用户择偶要求表
CREATE TABLE user_requirements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    min_age INTEGER,
    max_age INTEGER,
    min_height INTEGER,
    max_height INTEGER,
    education TEXT[],
    min_income VARCHAR(50),
    max_income VARCHAR(50),
    marital_status TEXT[],
    provinces TEXT[],
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

-- ========== 插入默认数据 ==========

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

-- 默认管理员 (用户名: admin, 密码: admin123)
INSERT INTO admins (username, password, name, role) VALUES
('admin', 'admin123', '系统管理员', 'super_admin');

-- 默认中介 (用户名: agency, 密码: agency123)
INSERT INTO agencies (username, password, name, phone, status) VALUES
('agency', 'agency123', '婚恋中介有限公司', '13800138000', 'active');

-- 测试用户
INSERT INTO users (phone, password, name, gender, birthday, height, weight, education, occupation, income, marital_status, province, city, declaration) VALUES
('13812345678', '123456', '张三', '男', '1990-01-15', 175, 65, '本科', '工程师', '10000-15000', '未婚', '广东省', '深圳市', '真诚交友，寻找另一半'),
('13987654321', '654321', '李四', '女', '1992-05-20', 165, 52, '硕士', '设计师', '8000-10000', '未婚', '北京市', '北京市', '希望找到志同道合的伴侣');

-- 用户择偶要求
INSERT INTO user_requirements (user_id, min_age, max_age, min_height, max_height, education, min_income, marital_status, provinces) VALUES
((SELECT id FROM users WHERE phone = '13812345678'), 25, 35, 160, 175, '{"本科","硕士"}', '5000-8000', '{"未婚"}', '{"广东省","北京市"}'),
((SELECT id FROM users WHERE phone = '13987654321'), 28, 38, 170, 185, '{"本科","硕士","博士"}', '8000-10000', '{"未婚"}', '{"北京市","上海市"}');

-- 用户兴趣爱好
INSERT INTO user_interests (user_id, interest_id) VALUES
((SELECT id FROM users WHERE phone = '13812345678'), (SELECT id FROM interests WHERE name = '运动健身')),
((SELECT id FROM users WHERE phone = '13812345678'), (SELECT id FROM interests WHERE name = '旅游')),
((SELECT id FROM users WHERE phone = '13987654321'), (SELECT id FROM interests WHERE name = '音乐')),
((SELECT id FROM users WHERE phone = '13987654321'), (SELECT id FROM interests WHERE name = '阅读'));

-- 用户隐私设置
INSERT INTO user_privacy (user_id, contact_visibility, profile_visibility) VALUES
((SELECT id FROM users WHERE phone = '13812345678'), 'public', 'all'),
((SELECT id FROM users WHERE phone = '13987654321'), 'friends', 'all');

SELECT '数据库初始化完成！' AS result;
