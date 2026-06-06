-- ============================================
-- 最终修复 match_results 外键问题
-- ============================================

-- 1. 清理无效的匹配记录（user_id 或 target_user_id 不存在于 users 表）
DELETE FROM match_results
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.user_id);

DELETE FROM match_results
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.target_user_id);

-- 2. 删除旧的外键约束（如果存在）
ALTER TABLE match_results 
DROP CONSTRAINT IF EXISTS fk_match_results_user_id;

ALTER TABLE match_results 
DROP CONSTRAINT IF EXISTS fk_match_results_target_user_id;

-- 3. 重新创建外键约束（带 CASCADE 删除）
ALTER TABLE match_results
ADD CONSTRAINT fk_match_results_user_id
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE match_results
ADD CONSTRAINT fk_match_results_target_user_id
FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE;

-- 4. 创建触发器：当用户被删除时自动清理匹配记录
CREATE OR REPLACE FUNCTION cleanup_user_matches()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM match_results WHERE user_id = OLD.id OR target_user_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 删除旧触发器（如果存在）
DROP TRIGGER IF EXISTS trigger_cleanup_user_matches ON users;

-- 创建新触发器
CREATE TRIGGER trigger_cleanup_user_matches
    BEFORE DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_user_matches();

-- 5. 创建函数用于验证并清理无效匹配
CREATE OR REPLACE FUNCTION validate_match_results()
RETURNS void AS $$
BEGIN
    DELETE FROM match_results
    WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.user_id)
       OR NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.target_user_id);
END;
$$ LANGUAGE plpgsql;

-- 6. 验证修复结果
SELECT 
    '有效记录' as status,
    COUNT(*) as count
FROM match_results
WHERE EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.user_id)
  AND EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.target_user_id);

-- 7. 刷新 PostgREST schema 缓存
NOTIFY pgrst, 'reload schema';
