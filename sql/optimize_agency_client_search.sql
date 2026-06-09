-- =============================================
-- 优化中介后台客户管理检索速度
-- 问题：中介搜索客户时使用 OR 查询，现有索引无法有效利用
-- =============================================

-- 1. 删除可能存在的旧索引（如果有）
DROP INDEX IF EXISTS idx_users_agency_name;
DROP INDEX IF EXISTS idx_users_agency_phone;
DROP INDEX IF EXISTS idx_users_agency_created_at;

-- 2. 创建针对中介客户搜索的复合索引
--    组合：agency_id + name（用于按姓名搜索中介客户）
CREATE INDEX IF NOT EXISTS idx_users_agency_name 
ON users(agency_id, name);

-- 3. 创建针对中介客户手机号搜索的复合索引
--    组合：agency_id + phone（用于按手机号搜索中介客户）
CREATE INDEX IF NOT EXISTS idx_users_agency_phone 
ON users(agency_id, phone);

-- 4. 创建针对中介客户列表加载的复合索引
--    组合：agency_id + created_at DESC（用于按创建时间排序显示）
CREATE INDEX IF NOT EXISTS idx_users_agency_created_at 
ON users(agency_id, created_at DESC);

-- 5. 创建 GIN 索引支持全文搜索（可选，用于更复杂的搜索场景）
--    组合 name 和 phone 字段，支持 faster 全文搜索
DROP INDEX IF EXISTS idx_users_agency_search;
CREATE INDEX IF NOT EXISTS idx_users_agency_search 
ON users USING GIN (to_tsvector('simple', COALESCE(name, '') || ' ' || COALESCE(phone, ''))) 
WHERE agency_id IS NOT NULL;

-- 6. 验证索引创建
SELECT 
    '索引创建完成' AS info,
    indexrelname AS index_name,
    idx_scan AS scan_count,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes 
WHERE relname = 'users';

-- 7. 查看 users 表的所有索引
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'users';

-- 8. 测试查询性能（中介客户搜索）- 需要替换为真实的 agency_id
-- EXPLAIN ANALYZE 
-- SELECT id, name, phone, gender, birthday, status, agency_id, created_at 
-- FROM users 
-- WHERE agency_id = 'your_real_agency_uuid_here' 
--   AND (name ILIKE '%test%' OR phone ILIKE '%test%')
-- ORDER BY created_at DESC 
-- LIMIT 50;

-- 9. 测试列表加载性能 - 需要替换为真实的 agency_id
-- EXPLAIN ANALYZE 
-- SELECT id, name, phone, gender, birthday, status, agency_id, created_at 
-- FROM users 
-- WHERE agency_id = 'your_real_agency_uuid_here'
-- ORDER BY created_at DESC 
-- LIMIT 100;
