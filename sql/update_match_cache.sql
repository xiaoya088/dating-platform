-- 匹配结果预计算表：用于存储预计算的匹配分数，提高显示效率
CREATE TABLE IF NOT EXISTS match_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    target_user_id UUID NOT NULL,
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

DROP INDEX IF EXISTS idx_match_results_user_id;
DROP INDEX IF EXISTS idx_match_results_score;
DROP INDEX IF EXISTS idx_match_results_calculated;

CREATE INDEX IF NOT EXISTS idx_match_results_user_id ON match_results(user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_score ON match_results(user_id, score DESC);
CREATE INDEX IF NOT EXISTS idx_match_results_calculated ON match_results(user_id, calculated_at);

ALTER TABLE match_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "允许读取自己的匹配结果"
ON match_results FOR SELECT
USING (true);

CREATE POLICY "允许插入匹配结果"
ON match_results FOR INSERT
WITH CHECK (true);

CREATE POLICY "允许更新匹配结果"
ON match_results FOR UPDATE
USING (true);

COMMENT ON TABLE match_results IS '预计算匹配结果表，用于缓存匹配分数提高显示效率';