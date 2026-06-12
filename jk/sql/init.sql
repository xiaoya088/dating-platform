-- =============================================
-- JK健康管理系统数据库初始化脚本
-- 表名前缀：jk_
-- 与红娘系统共用同一数据库，但使用完全独立的表
-- =============================================

-- 1. 管理员表
CREATE TABLE IF NOT EXISTS jk_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL, -- 用户名（用于登录）
    password VARCHAR(255) NOT NULL,
    name VARCHAR(100), -- 显示名称
    role VARCHAR(20) DEFAULT 'admin', -- admin, doctor
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 用户表
CREATE TABLE IF NOT EXISTS jk_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE NOT NULL,
    real_name VARCHAR(100),
    avatar_url TEXT,
    role VARCHAR(20) DEFAULT 'user', -- user, doctor, admin
    status VARCHAR(20) DEFAULT 'active', -- active, inactive, banned
    referral_code VARCHAR(50) UNIQUE, -- 推荐码/二维码标识
    show_qr_code BOOLEAN DEFAULT TRUE, -- 是否展示二维码（管理员控制）
    points DECIMAL(10,2) DEFAULT 0, -- 用户积分
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 用户健康信息表
CREATE TABLE IF NOT EXISTS jk_user_health_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    gender VARCHAR(10),
    birthday DATE,
    height DECIMAL(5,2), -- 身高(cm)
    weight DECIMAL(5,2), -- 体重(kg)
    blood_type VARCHAR(10), -- 血型
    allergies TEXT, -- 过敏史
    medical_history TEXT, -- 病史
    current_medications TEXT, -- 当前用药
    emergency_contact_name VARCHAR(100), -- 紧急联系人
    emergency_contact_phone VARCHAR(20), -- 紧急联系电话
    referrer_id UUID REFERENCES jk_users(id), -- 推荐人ID
    referral_code_used VARCHAR(50), -- 使用的推荐码
    referral_valid_until TIMESTAMP WITH TIME ZONE, -- 推荐码有效期（注册后保留一个月）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 每日健康记录
CREATE TABLE IF NOT EXISTS jk_daily_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    sleep_hours DECIMAL(4,1), -- 睡眠时长(小时)
    water_intake DECIMAL(4,1), -- 饮水量(升)
    exercise_minutes INT, -- 运动时长(分钟)
    meal_count INT, -- 用餐次数
    mood INT DEFAULT 3, -- 心情指数 1-5
    product_effect TEXT, -- 使用产品后的效果描述
    is_public BOOLEAN DEFAULT FALSE, -- 是否公开
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, record_date)
);

-- 5. 医生建议表
CREATE TABLE IF NOT EXISTS jk_doctor_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id UUID NOT NULL REFERENCES jk_daily_records(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    advice TEXT NOT NULL, -- 医生建议/注意事项
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 记录评价表
CREATE TABLE IF NOT EXISTS jk_record_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id UUID NOT NULL REFERENCES jk_daily_records(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 记录点赞表
CREATE TABLE IF NOT EXISTS jk_record_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id UUID NOT NULL REFERENCES jk_daily_records(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(record_id, user_id)
);

-- 8. 咨询表
CREATE TABLE IF NOT EXISTS jk_consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, replied, resolved
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. 咨询回复表
CREATE TABLE IF NOT EXISTS jk_consultation_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_id UUID NOT NULL REFERENCES jk_consultations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_doctor BOOLEAN DEFAULT FALSE, -- 是否医生回复
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. 产品表
CREATE TABLE IF NOT EXISTS jk_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    original_price DECIMAL(10,2), -- 原价（用于显示折扣）
    image_url TEXT,
    stock INT DEFAULT 0, -- 库存
    category VARCHAR(50), -- 产品分类
    is_active BOOLEAN DEFAULT TRUE, -- 是否上架
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. 订单表
CREATE TABLE IF NOT EXISTS jk_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    order_no VARCHAR(50) UNIQUE NOT NULL, -- 订单号
    status VARCHAR(20) DEFAULT 'pending', -- pending, paid, shipped, completed, cancelled
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    shipping_address TEXT,
    shipping_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. 订单项表
CREATE TABLE IF NOT EXISTS jk_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES jk_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES jk_products(id),
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0
);

-- 13. 管理员交流表（医生主动发起）
CREATE TABLE IF NOT EXISTS jk_admin_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    title VARCHAR(200),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. 消费记录表（管理员录入）
CREATE TABLE IF NOT EXISTS jk_consumption_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL DEFAULT 0, -- 消费金额
    description VARCHAR(500), -- 消费描述
    record_type VARCHAR(20) DEFAULT 'order', -- order:订单消费, manual:手动录入
    created_by UUID REFERENCES jk_users(id), -- 录入人（管理员）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 15. 推荐积分记录表
CREATE TABLE IF NOT EXISTS jk_referral_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE, -- 推荐人ID
    referred_user_id UUID NOT NULL REFERENCES jk_users(id) ON DELETE CASCADE, -- 被推荐人ID
    consumption_id UUID REFERENCES jk_consumption_records(id), -- 关联消费记录
    points_earned DECIMAL(10,2) NOT NULL DEFAULT 0, -- 获得的积分
    percentage DECIMAL(5,2) NOT NULL DEFAULT 0, -- 使用的比例
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 16. 推荐配置表
CREATE TABLE IF NOT EXISTS jk_referral_config (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    value VARCHAR(500) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 17. 系统配置表
CREATE TABLE IF NOT EXISTS jk_system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value VARCHAR(500) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 索引
-- =============================================

-- 管理员表索引
CREATE INDEX IF NOT EXISTS idx_jk_admins_username ON jk_admins(username);

-- 用户表索引
CREATE INDEX IF NOT EXISTS idx_jk_users_username ON jk_users(username);
CREATE INDEX IF NOT EXISTS idx_jk_users_phone ON jk_users(phone);
CREATE INDEX IF NOT EXISTS idx_jk_users_email ON jk_users(email);
CREATE INDEX IF NOT EXISTS idx_jk_users_role ON jk_users(role);

-- 健康信息表索引
CREATE INDEX IF NOT EXISTS idx_jk_user_health_info_user_id ON jk_user_health_info(user_id);

-- 每日记录索引
CREATE INDEX IF NOT EXISTS idx_jk_daily_records_user_id ON jk_daily_records(user_id);
CREATE INDEX IF NOT EXISTS idx_jk_daily_records_date ON jk_daily_records(record_date);
CREATE INDEX IF NOT EXISTS idx_jk_daily_records_public ON jk_daily_records(is_public);

-- 医生建议索引
CREATE INDEX IF NOT EXISTS idx_jk_doctor_comments_record_id ON jk_doctor_comments(record_id);
CREATE INDEX IF NOT EXISTS idx_jk_doctor_comments_doctor_id ON jk_doctor_comments(doctor_id);

-- 记录评价索引
CREATE INDEX IF NOT EXISTS idx_jk_record_comments_record_id ON jk_record_comments(record_id);
CREATE INDEX IF NOT EXISTS idx_jk_record_comments_user_id ON jk_record_comments(user_id);

-- 记录点赞索引
CREATE INDEX IF NOT EXISTS idx_jk_record_likes_record_id ON jk_record_likes(record_id);
CREATE INDEX IF NOT EXISTS idx_jk_record_likes_user_id ON jk_record_likes(user_id);

-- 咨询表索引
CREATE INDEX IF NOT EXISTS idx_jk_consultations_user_id ON jk_consultations(user_id);
CREATE INDEX IF NOT EXISTS idx_jk_consultations_status ON jk_consultations(status);

-- 咨询回复索引
CREATE INDEX IF NOT EXISTS idx_jk_consultation_replies_consultation_id ON jk_consultation_replies(consultation_id);
CREATE INDEX IF NOT EXISTS idx_jk_consultation_replies_user_id ON jk_consultation_replies(user_id);

-- 产品表索引
CREATE INDEX IF NOT EXISTS idx_jk_products_name ON jk_products(name);
CREATE INDEX IF NOT EXISTS idx_jk_products_category ON jk_products(category);
CREATE INDEX IF NOT EXISTS idx_jk_products_active ON jk_products(is_active);

-- 订单表索引
CREATE INDEX IF NOT EXISTS idx_jk_orders_user_id ON jk_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_jk_orders_order_no ON jk_orders(order_no);
CREATE INDEX IF NOT EXISTS idx_jk_orders_status ON jk_orders(status);

-- 订单项索引
CREATE INDEX IF NOT EXISTS idx_jk_order_items_order_id ON jk_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_jk_order_items_product_id ON jk_order_items(product_id);

-- 管理员交流索引
CREATE INDEX IF NOT EXISTS idx_jk_admin_messages_admin_id ON jk_admin_messages(admin_id);
CREATE INDEX IF NOT EXISTS idx_jk_admin_messages_user_id ON jk_admin_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_jk_admin_messages_read ON jk_admin_messages(is_read);

-- 用户表新增索引
CREATE INDEX IF NOT EXISTS idx_jk_users_referral_code ON jk_users(referral_code);
CREATE INDEX IF NOT EXISTS idx_jk_users_show_qr_code ON jk_users(show_qr_code);

-- 用户健康信息表新增索引
CREATE INDEX IF NOT EXISTS idx_jk_user_health_info_referrer_id ON jk_user_health_info(referrer_id);
CREATE INDEX IF NOT EXISTS idx_jk_user_health_info_referral_code ON jk_user_health_info(referral_code_used);

-- 消费记录表索引
CREATE INDEX IF NOT EXISTS idx_jk_consumption_records_user_id ON jk_consumption_records(user_id);
CREATE INDEX IF NOT EXISTS idx_jk_consumption_records_created_by ON jk_consumption_records(created_by);

-- 推荐积分记录表索引
CREATE INDEX IF NOT EXISTS idx_jk_referral_points_referrer_id ON jk_referral_points(referrer_id);
CREATE INDEX IF NOT EXISTS idx_jk_referral_points_referred_user_id ON jk_referral_points(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_jk_referral_points_consumption_id ON jk_referral_points(consumption_id);

-- 系统配置表索引
CREATE INDEX IF NOT EXISTS idx_jk_system_config_key ON jk_system_config(config_key);

-- =============================================
-- 触发器函数
-- =============================================

-- 更新时间戳的函数
CREATE OR REPLACE FUNCTION jk_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为需要更新时间的表创建触发器
DROP TRIGGER IF EXISTS update_jk_users_timestamp ON jk_users;
CREATE TRIGGER update_jk_users_timestamp
    BEFORE UPDATE ON jk_users
    FOR EACH ROW EXECUTE FUNCTION jk_update_timestamp();

DROP TRIGGER IF EXISTS update_jk_user_health_info_timestamp ON jk_user_health_info;
CREATE TRIGGER update_jk_user_health_info_timestamp
    BEFORE UPDATE ON jk_user_health_info
    FOR EACH ROW EXECUTE FUNCTION jk_update_timestamp();

DROP TRIGGER IF EXISTS update_jk_daily_records_timestamp ON jk_daily_records;
CREATE TRIGGER update_jk_daily_records_timestamp
    BEFORE UPDATE ON jk_daily_records
    FOR EACH ROW EXECUTE FUNCTION jk_update_timestamp();

DROP TRIGGER IF EXISTS update_jk_consultations_timestamp ON jk_consultations;
CREATE TRIGGER update_jk_consultations_timestamp
    BEFORE UPDATE ON jk_consultations
    FOR EACH ROW EXECUTE FUNCTION jk_update_timestamp();

DROP TRIGGER IF EXISTS update_jk_orders_timestamp ON jk_orders;
CREATE TRIGGER update_jk_orders_timestamp
    BEFORE UPDATE ON jk_orders
    FOR EACH ROW EXECUTE FUNCTION jk_update_timestamp();

DROP TRIGGER IF EXISTS update_jk_products_timestamp ON jk_products;
CREATE TRIGGER update_jk_products_timestamp
    BEFORE UPDATE ON jk_products
    FOR EACH ROW EXECUTE FUNCTION jk_update_timestamp();

-- =============================================
-- RLS (Row Level Security) 策略设置
-- =============================================

-- 禁用所有jk_表的RLS（方便开发，生产环境建议配置具体策略）
ALTER TABLE jk_admins DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_user_health_info DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_daily_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_doctor_comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_record_comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_record_likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_consultations DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_consultation_replies DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_products DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_order_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_admin_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_consumption_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_referral_points DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_referral_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE jk_system_config DISABLE ROW LEVEL SECURITY;

-- =============================================
-- 权限设置
-- =============================================

-- 授予必要的权限
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- 管理员表权限（允许匿名用户查询用于登录验证）
GRANT SELECT ON TABLE jk_admins TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE jk_admins TO authenticated;

-- 用户表权限（允许匿名用户查询和插入用于登录和注册）
GRANT SELECT ON TABLE jk_users TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE jk_users TO anon, authenticated;

-- 健康信息表权限
GRANT SELECT, INSERT, UPDATE ON TABLE jk_user_health_info TO authenticated;

-- 每日记录表权限
GRANT SELECT, INSERT, UPDATE ON TABLE jk_daily_records TO authenticated;

-- 医生建议表权限
GRANT SELECT, INSERT ON TABLE jk_doctor_comments TO authenticated;

-- 记录评价表权限
GRANT SELECT, INSERT ON TABLE jk_record_comments TO authenticated;

-- 记录点赞表权限
GRANT SELECT, INSERT, DELETE ON TABLE jk_record_likes TO authenticated;

-- 咨询表权限
GRANT SELECT, INSERT, UPDATE ON TABLE jk_consultations TO authenticated;

-- 咨询回复表权限
GRANT SELECT, INSERT ON TABLE jk_consultation_replies TO authenticated;

-- 产品表权限
GRANT SELECT ON TABLE jk_products TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE jk_products TO authenticated;

-- 订单表权限
GRANT SELECT, INSERT, UPDATE ON TABLE jk_orders TO authenticated;

-- 订单项表权限
GRANT SELECT, INSERT ON TABLE jk_order_items TO authenticated;

-- 管理员交流表权限
GRANT SELECT, INSERT ON TABLE jk_admin_messages TO authenticated;

-- 消费记录表权限
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE jk_consumption_records TO authenticated;

-- 推荐积分记录表权限
GRANT SELECT, INSERT ON TABLE jk_referral_points TO authenticated;

-- 推荐配置表权限
GRANT SELECT ON TABLE jk_referral_config TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE jk_referral_config TO authenticated;

-- 系统配置表权限
GRANT SELECT ON TABLE jk_system_config TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE jk_system_config TO authenticated;

-- =============================================
-- 验证创建成功
-- =============================================

SELECT '=== JK健康管理系统表创建成功 ===' AS info;
SELECT tablename FROM pg_tables WHERE tablename LIKE 'jk_%' ORDER BY tablename;

-- =============================================
-- 初始数据
-- =============================================

-- 插入默认管理员账号
INSERT INTO jk_admins (username, password, name, role) VALUES
('admin', 'admin123', '系统管理员', 'admin'),
('doctor', 'doctor123', '王医生', 'doctor')
ON CONFLICT (username) DO UPDATE SET 
    password = EXCLUDED.password,
    name = EXCLUDED.name,
    role = EXCLUDED.role;

-- 插入推荐配置默认数据
INSERT INTO jk_referral_config (name, value, description) VALUES
('referral_rate', '0.05', '推荐积分比例（消费金额的5%）'),
('referral_valid_days', '30', '推荐关系有效期（30天）')
ON CONFLICT (name) DO NOTHING;

-- 插入系统配置默认数据
INSERT INTO jk_system_config (config_key, config_value, description) VALUES
('community_enabled', 'true', '是否启用健康社区功能')
ON CONFLICT (config_key) DO NOTHING;

-- 插入示例产品
INSERT INTO jk_products (id, name, description, price, original_price, image_url, stock, category, is_active) VALUES
(gen_random_uuid(), '健康监测手环', '实时监测心率、血压、血氧，支持睡眠监测', 299.00, 399.00, 'https://via.placeholder.com/300x300?text=手环', 100, '智能设备', true),
(gen_random_uuid(), '蛋白质营养粉', '补充人体所需蛋白质，增强免疫力', 168.00, 198.00, 'https://via.placeholder.com/300x300?text=营养粉', 200, '营养品', true),
(gen_random_uuid(), '维生素C咀嚼片', '每日一片，增强抵抗力', 68.00, 88.00, 'https://via.placeholder.com/300x300?text=维C', 500, '保健品', true)
ON CONFLICT DO NOTHING;