-- =============================================
-- 优化消息检索速度 - 添加索引
-- =============================================

-- messages 表缺少必要索引导致查询慢

-- 1. 为 from_user_id 添加索引（用于查询"我发送的消息"）
CREATE INDEX IF NOT EXISTS idx_messages_from_user_id
ON messages(from_user_id);

-- 2. 为 to_user_id 添加索引（用于查询"我接收的消息"）
CREATE INDEX IF NOT EXISTS idx_messages_to_user_id
ON messages(to_user_id);

-- 3. 为 created_at 添加索引（用于按时间排序）
CREATE INDEX IF NOT EXISTS idx_messages_created_at
ON messages(created_at DESC);

-- 4. 为 is_read 添加索引（用于未读消息统计）
CREATE INDEX IF NOT EXISTS idx_messages_is_read
ON messages(is_read);

-- 5. 复合索引：加速查询某个用户的所有消息
CREATE INDEX IF NOT EXISTS idx_messages_from_to_created
ON messages(from_user_id, to_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_to_from_created
ON messages(to_user_id, from_user_id, created_at DESC);

-- 验证索引创建
SELECT
    '索引创建完成' AS info,
    indexrelname AS index_name,
    idx_scan AS scan_count
FROM pg_stat_user_indexes
WHERE relname = 'messages';

-- 查看 messages 表的所有索引
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'messages';

-- 验证完成
SELECT '✅ 索引创建完成，消息检索性能已优化' AS status;