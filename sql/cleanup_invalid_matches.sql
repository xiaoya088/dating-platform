-- ============================================
-- 清理无效的匹配记录
-- 删除 user_id 或 target_user_id 在 users 表中不存在的记录
-- ============================================

-- 1. 查看有多少无效记录
SELECT 
    '无效 user_id' as issue_type,
    COUNT(*) as count
FROM match_results mr
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = mr.user_id)

UNION ALL

SELECT 
    '无效 target_user_id' as issue_type,
    COUNT(*) as count
FROM match_results mr
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = mr.target_user_id);

-- 2. 删除 user_id 无效的记录
DELETE FROM match_results
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.user_id);

-- 3. 删除 target_user_id 无效的记录
DELETE FROM match_results
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.target_user_id);

-- 4. 验证清理结果
SELECT COUNT(*) as remaining_records FROM match_results;
