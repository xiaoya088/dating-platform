-- 清理 match_results 表中的重复数据
-- 保留每个用户对每个目标用户的最高匹配度记录

-- 1. 查看重复数据数量
SELECT 
    user_id, 
    target_user_id, 
    COUNT(*) as duplicate_count,
    MAX(score) as max_score
FROM match_results
GROUP BY user_id, target_user_id
HAVING COUNT(*) > 1;

-- 2. 使用窗口函数删除重复数据，保留匹配度最高的记录
WITH duplicates_to_delete AS (
    SELECT id
    FROM (
        SELECT 
            id,
            ROW_NUMBER() OVER (PARTITION BY user_id, target_user_id ORDER BY score DESC NULLS LAST) as row_num
        FROM match_results
    ) ranked
    WHERE row_num > 1
)
DELETE FROM match_results
WHERE id IN (SELECT id FROM duplicates_to_delete);

-- 3. 验证清理结果
SELECT COUNT(*) as total_records FROM match_results;
SELECT 
    user_id, 
    target_user_id, 
    COUNT(*) as count
FROM match_results
GROUP BY user_id, target_user_id
HAVING COUNT(*) > 1;
