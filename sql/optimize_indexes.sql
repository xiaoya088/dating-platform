-- 优化 match_results 表查询性能

-- 删除可能存在的旧索引
DROP INDEX IF EXISTS idx_match_results_user_id;
DROP INDEX IF EXISTS idx_match_results_target_user_id;
DROP INDEX IF EXISTS idx_match_results_score;
DROP INDEX IF EXISTS idx_match_results_calculated;

-- 创建优化后的复合索引：专门针对用户ID+未过滤+分数排序的查询
CREATE INDEX idx_match_results_user_active_score ON match_results(user_id, is_filtered, score DESC);

-- 创建 target_user_id 索引用于批量查询
CREATE INDEX idx_match_results_target ON match_results(target_user_id);

-- 优化 users 表的查询（如果还没有这些索引）
DROP INDEX IF EXISTS idx_users_status;
DROP INDEX IF EXISTS idx_users_gender;

CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_gender ON users(gender);

-- 确认索引创建成功
SELECT '索引优化完成' AS status;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'match_results';
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'users';