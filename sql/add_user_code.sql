-- 添加用户编号字段（简化格式：xy+顺序数字）
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
