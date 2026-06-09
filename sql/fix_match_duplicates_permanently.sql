-- =============================================
-- 永久修复 match_results 表重复数据问题
-- 1. 删除现有重复数据
-- 2. 添加唯一约束防止未来产生重复
-- =============================================

-- 1. 查看当前重复数据情况
SELECT '=== 当前重复数据统计 ===' AS info;
SELECT 
    user_id, 
    target_user_id, 
    COUNT(*) as duplicate_count,
    MAX(score) as max_score
FROM match_results
GROUP BY user_id, target_user_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2. 删除重复数据（保留匹配度最高的记录）
WITH ranked_matches AS (
    SELECT 
        id,
        user_id,
        target_user_id,
        score,
        ROW_NUMBER() OVER (
            PARTITION BY user_id, target_user_id 
            ORDER BY score DESC NULLS LAST, created_at ASC
        ) as row_num
    FROM match_results
)
DELETE FROM match_results
WHERE id IN (
    SELECT id FROM ranked_matches WHERE row_num > 1
);

-- 3. 验证删除结果
SELECT '=== 删除重复后记录数 ===' AS info, COUNT(*) as total_records FROM match_results;

-- 4. 确认已无重复数据
SELECT '=== 剩余重复数据（应为空） ===' AS info;
SELECT 
    user_id, 
    target_user_id, 
    COUNT(*) as count
FROM match_results
GROUP BY user_id, target_user_id
HAVING COUNT(*) > 1;

-- 5. 添加唯一约束（防止未来产生重复）
-- 先检查是否已存在约束
SELECT '=== 检查现有约束 ===' AS info;
SELECT conname, conrelid::regclass AS table_name
FROM pg_constraint
WHERE conrelid = 'match_results'::regclass;

-- 删除可能存在的旧约束
ALTER TABLE match_results DROP CONSTRAINT IF EXISTS unique_user_target_pair;

-- 添加唯一约束
ALTER TABLE match_results 
ADD CONSTRAINT unique_user_target_pair 
UNIQUE (user_id, target_user_id);

-- 6. 验证约束已添加
SELECT '=== 约束添加成功 ===' AS info;
SELECT conname, conrelid::regclass AS table_name
FROM pg_constraint
WHERE conrelid = 'match_results'::regclass;

-- 7. 查看索引状态
SELECT '=== match_results 表索引 ===' AS info;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'match_results';
