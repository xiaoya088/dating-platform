-- =============================================
-- 清空匹配表并重新计算所有用户匹配度
-- =============================================

-- 1. 清空 match_results 表（保留表结构）
TRUNCATE TABLE match_results;

-- 2. 重新计算所有用户的匹配度
SELECT calculate_all_matches();

-- 3. 验证结果
SELECT 
    '重新计算完成' AS status,
    COUNT(*) AS total_matches
FROM match_results;

-- 4. 显示统计信息
SELECT 
    user_id,
    COUNT(*) AS match_count,
    AVG(score) AS avg_score,
    MAX(score) AS max_score
FROM match_results
GROUP BY user_id
ORDER BY match_count DESC
LIMIT 10;