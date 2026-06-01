-- =============================================
-- 修复 match_results 表重复数据问题
-- =============================================

-- 1. 查看 match_results 表结构
SELECT 'match_results 表结构:' AS info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'match_results' 
ORDER BY ordinal_position;

-- 2. 查看重复数据
SELECT '重复数据统计:' AS info;
SELECT user_id, target_user_id, COUNT(*) as count
FROM match_results
GROUP BY user_id, target_user_id
HAVING COUNT(*) > 1;

-- 3. 删除重复数据，保留最早的一条
DELETE FROM match_results a
USING match_results b
WHERE a.ctid < b.ctid
AND a.user_id = b.user_id 
AND a.target_user_id = b.target_user_id;

-- 4. 确认删除后的数据
SELECT '删除重复数据后的记录数:' AS info, COUNT(*) as total FROM match_results;

-- 5. 重新计算指定用户的匹配结果（可选）
-- 将下面的 user_id 替换为需要重新计算的用户 ID
-- SELECT recalculate_match_for_user('需要重新计算的用户ID');
