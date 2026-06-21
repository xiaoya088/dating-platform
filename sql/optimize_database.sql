-- 数据库优化SQL
-- 1. 添加用户编号字段
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_code VARCHAR(10);

-- 为现有用户生成编号（格式：xy + 6位序号）
DO $$
DECLARE
    rec RECORD;
    seq INT := 1;
BEGIN
    FOR rec IN SELECT id FROM users WHERE user_code IS NULL ORDER BY created_at LOOP
        UPDATE users SET user_code = 'xy' || LPAD(seq::TEXT, 6, '0') WHERE id = rec.id;
        seq := seq + 1;
    END LOOP;
END $$;

-- 设置编号为唯一
ALTER TABLE users ALTER COLUMN user_code SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_user_code ON users(user_code);

-- 为未来新用户创建触发器自动生成编号
CREATE OR REPLACE FUNCTION generate_user_code()
RETURNS TRIGGER AS $$
DECLARE
    max_seq INT;
BEGIN
    SELECT COALESCE(MAX(CAST(SUBSTRING(user_code FROM 3) AS INTEGER)), 0) + 1
    INTO max_seq
    FROM users;
    
    NEW.user_code := 'xy' || LPAD(max_seq::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_users_user_code ON users;
CREATE TRIGGER tr_users_user_code
BEFORE INSERT ON users
FOR EACH ROW
WHEN (NEW.user_code IS NULL)
EXECUTE FUNCTION generate_user_code();

-- 2. 添加索引以优化查询性能

-- users表索引
CREATE INDEX IF NOT EXISTS idx_users_gender ON users(gender);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_agency_id ON users(agency_id);
CREATE INDEX IF NOT EXISTS idx_users_marital_status ON users(marital_status);

-- match_results表索引（匹配查询优化）
CREATE INDEX IF NOT EXISTS idx_match_results_user_id ON match_results(user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_target_user_id ON match_results(target_user_id);
CREATE INDEX IF NOT EXISTS idx_match_results_score ON match_results(score DESC);
CREATE INDEX IF NOT EXISTS idx_match_results_user_score ON match_results(user_id, score DESC);
CREATE INDEX IF NOT EXISTS idx_match_results_filtered ON match_results(user_id, is_filtered, score DESC);

-- likes表索引
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_target_user_id ON likes(target_user_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

-- messages表索引
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- user_requirements表索引
CREATE INDEX IF NOT EXISTS idx_user_requirements_user_id ON user_requirements(user_id);

-- 3. 优化表结构 - 将photos字段分离到独立表（如果需要）
-- 注意：如果已经使用user_photos表，可以删除users表的photos字段
-- ALTER TABLE users DROP COLUMN IF EXISTS photos;

-- 4. 添加部分索引以减少索引大小
CREATE INDEX IF NOT EXISTS idx_users_active ON users(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_match_results_valid ON match_results(score) WHERE is_filtered = false;

-- 5. 添加复合索引以优化常见查询
CREATE INDEX IF NOT EXISTS idx_users_gender_status ON users(gender, status) WHERE status = 'active';

-- 6. 定期清理过期数据（可选）
-- 创建函数清理30天前的消息
CREATE OR REPLACE FUNCTION cleanup_old_messages()
RETURNS void AS $$
BEGIN
    DELETE FROM messages WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- 7. 添加统计信息更新
ANALYZE users;
ANALYZE match_results;
ANALYZE likes;
ANALYZE messages;
ANALYZE user_requirements;