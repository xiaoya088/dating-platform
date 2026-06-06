-- ============================================
-- 匹配信息查询性能优化
-- ============================================

-- 1. 为 match_results 表添加索引
CREATE INDEX IF NOT EXISTS idx_match_results_user_id ON match_results(user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_target_user_id ON match_results(target_user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_user_id_filtered ON match_results(user_id, is_filtered);
CREATE INDEX IF NOT EXISTS idx_match_results_score ON match_results(score DESC);

-- 2. 为 users 表添加索引
CREATE INDEX IF NOT EXISTS idx_users_agency_id ON users(agency_id);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- 3. 刷新缓存
NOTIFY pgrst, 'reload schema';

-- 4. 查看索引是否创建成功
SELECT indexname, tablename FROM pg_indexes WHERE schemaname = 'public' AND tablename IN ('match_results', 'users');
