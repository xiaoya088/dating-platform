-- ============================================
-- 修复 match_results 与 users 表的关系问题
-- ============================================

-- 1. 先删除可能存在的无效外键约束
DO $$
BEGIN
    -- 删除旧的外键约束（如果存在）
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_match_results_user_id' 
        AND table_name = 'match_results'
    ) THEN
        ALTER TABLE match_results DROP CONSTRAINT fk_match_results_user_id;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_match_results_target_user_id' 
        AND table_name = 'match_results'
    ) THEN
        ALTER TABLE match_results DROP CONSTRAINT fk_match_results_target_user_id;
    END IF;
END $$;

-- 2. 确保 users 表有主键
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'users' 
        AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE users ADD PRIMARY KEY (id);
    END IF;
END $$;

-- 3. 重新创建外键约束
ALTER TABLE match_results
ADD CONSTRAINT fk_match_results_user_id
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE match_results
ADD CONSTRAINT fk_match_results_target_user_id
FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE;

-- 4. 创建索引（如果不存在）
CREATE INDEX IF NOT EXISTS idx_match_results_user_id ON match_results(user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_target_user_id ON match_results(target_user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_score ON match_results(score DESC);

-- 5. 清理无效的匹配记录
DELETE FROM match_results
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.user_id);

DELETE FROM match_results
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = match_results.target_user_id);

-- 6. 刷新 PostgREST schema 缓存
NOTIFY pgrst, 'reload schema';
