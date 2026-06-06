-- 简单修复：重新创建外键约束
-- 先删除旧约束（忽略不存在的错误）
ALTER TABLE match_results 
DROP CONSTRAINT IF EXISTS fk_match_results_user_id;

ALTER TABLE match_results 
DROP CONSTRAINT IF EXISTS fk_match_results_target_user_id;

-- 重新创建外键约束
ALTER TABLE match_results
ADD CONSTRAINT fk_match_results_user_id
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE match_results
ADD CONSTRAINT fk_match_results_target_user_id
FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE;

-- 刷新缓存
NOTIFY pgrst, 'reload schema';
