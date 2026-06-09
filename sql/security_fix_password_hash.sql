-- =============================================
-- 安全修复：密码明文存储问题
-- 使用 bcrypt 哈希存储密码
-- =============================================

-- 1. 检查并安装 pgcrypto 扩展（用于加密功能）
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. 创建密码哈希函数
CREATE OR REPLACE FUNCTION hash_password(p_password TEXT) 
RETURNS TEXT AS $$
BEGIN
    -- 如果密码已经是 bcrypt 哈希（以 $2b$ 或 $2a$ 开头），则不重复哈希
    IF p_password ~ '^\$2[ab]\$[0-9]{2}\$[./A-Za-z0-9]{53}$' THEN
        RETURN p_password;
    END IF;
    
    -- 使用 bcrypt 哈希，成本因子为 12
    RETURN crypt(p_password, gen_salt('bf', 12));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 3. 创建密码验证函数
CREATE OR REPLACE FUNCTION verify_password(p_password TEXT, p_hash TEXT) 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN crypt(p_password, p_hash) = p_hash;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 4. 创建触发器函数：插入前自动哈希密码
CREATE OR REPLACE FUNCTION trigger_hash_password_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.password IS NOT NULL AND NEW.password != '' THEN
        NEW.password = hash_password(NEW.password);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. 创建触发器函数：更新前自动哈希密码
CREATE OR REPLACE FUNCTION trigger_hash_password_update()
RETURNS TRIGGER AS $$
BEGIN
    -- 只有当密码被修改时才重新哈希
    IF NEW.password IS NOT NULL AND NEW.password != '' AND NEW.password != OLD.password THEN
        NEW.password = hash_password(NEW.password);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. 删除可能存在的旧触发器
DROP TRIGGER IF EXISTS users_hash_password_insert_trigger ON users;
DROP TRIGGER IF EXISTS users_hash_password_update_trigger ON users;
DROP TRIGGER IF EXISTS agencies_hash_password_insert_trigger ON agencies;
DROP TRIGGER IF EXISTS agencies_hash_password_update_trigger ON agencies;

-- 7. 创建触发器
-- 对 users 表
CREATE TRIGGER users_hash_password_insert_trigger
BEFORE INSERT ON users
FOR EACH ROW EXECUTE FUNCTION trigger_hash_password_insert();

CREATE TRIGGER users_hash_password_update_trigger
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION trigger_hash_password_update();

-- 对 agencies 表
CREATE TRIGGER agencies_hash_password_insert_trigger
BEFORE INSERT ON agencies
FOR EACH ROW EXECUTE FUNCTION trigger_hash_password_insert();

CREATE TRIGGER agencies_hash_password_update_trigger
BEFORE UPDATE ON agencies
FOR EACH ROW EXECUTE FUNCTION trigger_hash_password_update();

-- 8. 验证函数创建
SELECT '=== 密码安全函数创建成功 ===' AS info;
SELECT proname, prorettype::regtype 
FROM pg_proc 
WHERE proname IN ('hash_password', 'verify_password', 'trigger_hash_password_insert', 'trigger_hash_password_update');

-- 9. 验证触发器创建
SELECT '=== 触发器创建成功 ===' AS info;
SELECT tgname, pg_class.relname AS table_name
FROM pg_trigger
JOIN pg_class ON pg_trigger.tgrelid = pg_class.oid
WHERE tgname LIKE '%hash_password%';
