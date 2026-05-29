-- 匹配结果预计算表：用于存储预计算的匹配分数，提高显示效率
CREATE TABLE IF NOT EXISTS match_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    a_to_b_score INTEGER,
    b_to_a_score INTEGER,
    reasons JSONB,
    common_interests TEXT[],
    common_activities TEXT[],
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_filtered BOOLEAN DEFAULT FALSE,
    filter_reason TEXT,
    UNIQUE(user_id, target_user_id)
);

CREATE INDEX IF NOT EXISTS idx_match_results_user_id ON match_results(user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_score ON match_results(user_id, score DESC);
CREATE INDEX IF NOT EXISTS idx_match_results_calculated ON match_results(user_id, calculated_at);

-- 定期清理过期匹配结果的函数（保留最近3天的计算结果）
CREATE OR REPLACE FUNCTION cleanup_old_match_results()
RETURNS void AS $$
BEGIN
    DELETE FROM match_results WHERE calculated_at < NOW() - INTERVAL '3 days';
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE match_results IS '预计算匹配结果表，用于缓存匹配分数提高显示效率';