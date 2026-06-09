-- =============================================
-- 优化中介后台客户匹配列表查询速度
-- =============================================

-- 1. 删除可能存在的旧索引
DROP INDEX IF EXISTS idx_match_results_user_filtered;
DROP INDEX IF EXISTS idx_match_results_target_filtered;
DROP INDEX IF EXISTS idx_match_results_user_score;
DROP INDEX IF EXISTS idx_match_results_agency_user;

-- 2. 创建复合索引：user_id + is_filtered（用于查询用户的匹配数量）
--    这是最关键的索引，用于 loadAgencyMatches() 中的匹配数量统计
CREATE INDEX IF NOT EXISTS idx_match_results_user_filtered 
ON match_results(user_id, is_filtered);

-- 3. 创建复合索引：user_id + is_filtered + score DESC（用于查询用户的匹配结果列表）
--    用于 loadMatchResults() 函数，按匹配度排序
CREATE INDEX IF NOT EXISTS idx_match_results_user_score 
ON match_results(user_id, is_filtered, score DESC);

-- 4. 创建索引：target_user_id（用于查询目标用户信息）
CREATE INDEX IF NOT EXISTS idx_match_results_target_filtered 
ON match_results(target_user_id, is_filtered);

-- 5. 创建复合索引：agency_id + user_id（用于中介查询其用户的匹配）
--    需要先在 users 表有 agency_id 索引
CREATE INDEX IF NOT EXISTS idx_users_agency_for_match 
ON users(agency_id, id);

-- 6. 验证索引创建
SELECT '=== match_results 表索引 ===' AS info;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'match_results';

SELECT '=== users 表相关索引 ===' AS info;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'users' AND indexname LIKE '%agency%';

-- 7. 查看索引使用情况统计
SELECT '=== 索引使用统计 ===' AS info;
SELECT 
    indexrelname AS index_name,
    idx_scan AS scan_count,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes 
WHERE relname = 'match_results';

-- 8. 创建聚合查询函数（可选，用于更高效的匹配数量统计）
--    这个函数可以一次性返回所有用户的匹配数量，替代分批查询
CREATE OR REPLACE FUNCTION get_match_counts_for_users(user_ids UUID[])
RETURNS TABLE(user_id UUID, match_count BIGINT)
LANGUAGE SQL
STABLE
AS $$
    SELECT 
        user_id,
        COUNT(*) as match_count
    FROM match_results
    WHERE user_id = ANY(user_ids)
      AND is_filtered = false
    GROUP BY user_id;
$$;

-- 9. 测试聚合函数
-- SELECT * FROM get_match_counts_for_users(ARRAY['your_user_uuid_here'::uuid]);

-- 10. 性能测试（需要替换为真实的 agency_id）
-- EXPLAIN ANALYZE 
-- SELECT user_id, COUNT(*) 
-- FROM match_results 
-- WHERE user_id IN ('uuid1', 'uuid2', 'uuid3')
--   AND is_filtered = false
-- GROUP BY user_id;