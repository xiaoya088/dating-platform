-- =============================================
-- 优化用户管理检索速度 - 添加索引
-- =============================================

-- users 表缺少必要索引导致查询慢

-- 1. 为 created_at 添加索引（用于排序）
CREATE INDEX IF NOT EXISTS idx_users_created_at 
ON users(created_at DESC);

-- 2. 为 status 添加索引（用于统计活跃用户）
CREATE INDEX IF NOT EXISTS idx_users_status 
ON users(status);

-- 3. 为 gender 添加索引（用于性别统计和筛选）
CREATE INDEX IF NOT EXISTS idx_users_gender 
ON users(gender);

-- 4. 为 agency_id 添加索引（用于中介筛选）
CREATE INDEX IF NOT EXISTS idx_users_agency_id 
ON users(agency_id);

-- 5. 为 phone 添加索引（用于手机号搜索）
CREATE INDEX IF NOT EXISTS idx_users_phone 
ON users(phone);

-- 6. 为 name 添加索引（用于姓名搜索）
CREATE INDEX IF NOT EXISTS idx_users_name 
ON users(name);

-- 验证索引创建
SELECT 
    '索引创建完成' AS info,
    indexrelname AS index_name,
    idx_scan AS scan_count
FROM pg_stat_user_indexes 
WHERE relname = 'users';

-- 查看 users 表的所有索引
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'users';

-- 查看查询计划（测试排序性能）
EXPLAIN ANALYZE 
SELECT id, name, phone, gender, birthday, status, agency_id, created_at 
FROM users 
ORDER BY created_at DESC 
LIMIT 100;