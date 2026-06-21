-- 数据库优化SQL（安全版本）
-- 只执行肯定存在的表和字段

-- 1. 添加用户编号字段（如果不存在）
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

-- 2. 添加 users 表索引（安全）
CREATE INDEX IF NOT EXISTS idx_users_gender ON users(gender);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_marital_status ON users(marital_status);

-- 3. 添加 agencies 表索引（如果表存在）
CREATE INDEX IF NOT EXISTS idx_agencies_username ON agencies(username);
CREATE INDEX IF NOT EXISTS idx_agencies_status ON agencies(status);

-- 4. 添加 admins 表索引（如果表存在）
CREATE INDEX IF NOT EXISTS idx_admins_username ON admins(username);

-- 5. 添加 likes 表索引（如果表存在）
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_target_user_id ON likes(target_user_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

-- 6. 添加 messages 表索引（如果表存在）
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- 7. 添加 user_requirements 表索引（如果表存在）
CREATE INDEX IF NOT EXISTS idx_user_requirements_user_id ON user_requirements(user_id);

-- 8. 只为 match_results 表添加索引（忽略错误）
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_match_results_user_id ON match_results(user_id);
EXCEPTION WHEN undefined_table OR undefined_column THEN
    RAISE NOTICE 'match_results table or columns not found, skipping';
END $$;

DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_match_results_target_user_id ON match_results(target_user_id);
EXCEPTION WHEN undefined_table OR undefined_column THEN
    RAISE NOTICE 'match_results table or columns not found, skipping';
END $$;

DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_match_results_score ON match_results(score DESC);
EXCEPTION WHEN undefined_table OR undefined_column THEN
    RAISE NOTICE 'match_results table or columns not found, skipping';
END $$;

-- 9. 更新统计信息
ANALYZE users;