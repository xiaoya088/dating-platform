-- =============================================
-- 优化点赞检索速度 - 添加索引
-- =============================================

-- likes 表缺少索引导致查询慢

-- 1. 为 from_user_id 添加索引（用于查询"我喜欢的"）
CREATE INDEX IF NOT EXISTS idx_likes_from_user_id 
ON likes(from_user_id);

-- 2. 为 to_user_id 添加索引（用于查询"喜欢我的"）
CREATE INDEX IF NOT EXISTS idx_likes_to_user_id 
ON likes(to_user_id);

-- 3. 为 (from_user_id, to_user_id) 添加唯一索引（已存在唯一约束，可省略）
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_likes_from_to 
-- ON likes(from_user_id, to_user_id);

-- 4. 为 created_at 添加索引（用于排序）
CREATE INDEX IF NOT EXISTS idx_likes_created_at 
ON likes(created_at DESC);

-- 验证索引创建
SELECT 
    '索引创建完成' AS info,
    indexrelname AS index_name,
    idx_scan AS scan_count
FROM pg_stat_user_indexes 
WHERE relname = 'likes';

-- 查看 likes 表的所有索引
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'likes';