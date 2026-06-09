-- =============================================
-- 修复 agency_requests 表重复数据问题
-- =============================================

-- 1. 查看当前重复数据情况
SELECT '=== 当前重复数据统计 ===' AS info;
SELECT 
    from_user_id, 
    to_user_id, 
    COUNT(*) as duplicate_count,
    MAX(created_at) as latest_request,
    MIN(created_at) as earliest_request
FROM agency_requests
GROUP BY from_user_id, to_user_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2. 删除重复数据（保留最新的一条）
WITH ranked_requests AS (
    SELECT 
        id,
        from_user_id,
        to_user_id,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY from_user_id, to_user_id 
            ORDER BY created_at DESC, updated_at DESC
        ) as row_num
    FROM agency_requests
)
DELETE FROM agency_requests
WHERE id IN (
    SELECT id FROM ranked_requests WHERE row_num > 1
);

-- 3. 验证删除结果
SELECT '=== 删除重复后记录数 ===' AS info, COUNT(*) as total_records FROM agency_requests;

-- 4. 确认已无重复数据
SELECT '=== 剩余重复数据（应为空） ===' AS info;
SELECT 
    from_user_id, 
    to_user_id, 
    COUNT(*) as count
FROM agency_requests
GROUP BY from_user_id, to_user_id
HAVING COUNT(*) > 1;

-- 5. 删除可能存在的旧约束
ALTER TABLE agency_requests DROP CONSTRAINT IF EXISTS unique_agency_request_pair;

-- 6. 添加唯一约束（防止未来产生重复）
ALTER TABLE agency_requests 
ADD CONSTRAINT unique_agency_request_pair 
UNIQUE (from_user_id, to_user_id);

-- 7. 验证约束已添加
SELECT '=== 约束添加成功 ===' AS info;
SELECT conname, conrelid::regclass AS table_name
FROM pg_constraint
WHERE conrelid = 'agency_requests'::regclass;

-- 8. 查看索引状态
SELECT '=== agency_requests 表索引 ===' AS info;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'agency_requests';
