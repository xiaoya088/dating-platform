-- =============================================
-- 长期登录功能 - 数据库端支持
-- =============================================

-- 创建长期登录token表
CREATE TABLE IF NOT EXISTS long_term_login_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    token VARCHAR(128) UNIQUE NOT NULL,
    device_info TEXT,
    ip_address VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '30 days',
    last_used_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_long_term_user_id ON long_term_login_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_long_term_token ON long_term_login_tokens(token);
CREATE INDEX IF NOT EXISTS idx_long_term_expires ON long_term_login_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_long_term_active ON long_term_login_tokens(is_active);

-- 生成长期登录token函数
CREATE OR REPLACE FUNCTION generate_long_term_token(p_user_id UUID)
RETURNS TABLE (token VARCHAR) AS $$
DECLARE
    v_token VARCHAR(128);
BEGIN
    -- 生成随机token（使用更安全的随机数）
    v_token := encode(gen_random_bytes(64), 'hex');
    
    -- 插入token记录
    INSERT INTO long_term_login_tokens (user_id, token, expires_at)
    VALUES (p_user_id, v_token, NOW() + INTERVAL '30 days');
    
    RETURN QUERY SELECT v_token;
END;
$$ LANGUAGE plpgsql;

-- 验证长期登录token函数
CREATE OR REPLACE FUNCTION verify_long_term_token(p_token VARCHAR)
RETURNS TABLE (valid BOOLEAN, user_data JSONB) AS $$
DECLARE
    v_user_id UUID;
    v_expires_at TIMESTAMP;
    v_is_active BOOLEAN;
    v_user_data JSONB;
BEGIN
    -- 检查token是否存在且有效
    SELECT user_id, expires_at, is_active
    INTO v_user_id, v_expires_at, v_is_active
    FROM long_term_login_tokens
    WHERE token = p_token;
    
    IF NOT FOUND OR NOT v_is_active THEN
        RETURN QUERY SELECT FALSE, NULL;
        RETURN;
    END IF;
    
    -- 检查是否过期
    IF v_expires_at < NOW() THEN
        UPDATE long_term_login_tokens SET is_active = false WHERE token = p_token;
        RETURN QUERY SELECT FALSE, NULL;
        RETURN;
    END IF;
    
    -- 获取用户信息
    SELECT to_jsonb(u) INTO v_user_data
    FROM users u
    WHERE u.id = v_user_id AND u.status = 'active';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL;
        RETURN;
    END IF;
    
    -- 更新最后使用时间
    UPDATE long_term_login_tokens 
    SET last_used_at = NOW() 
    WHERE token = p_token;
    
    RETURN QUERY SELECT TRUE, v_user_data;
END;
$$ LANGUAGE plpgsql;

-- 使指定用户的所有token失效（用于安全退出）
CREATE OR REPLACE FUNCTION invalidate_user_tokens(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE long_term_login_tokens 
    SET is_active = false 
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- 清理过期token的定时任务
DO $$
BEGIN
    PERFORM cron.unschedule('clean_expired_long_term_tokens');
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END $$;

SELECT cron.schedule(
    'clean_expired_long_term_tokens',
    '0 0 * * *',
    'DELETE FROM long_term_login_tokens WHERE is_active = false OR expires_at < NOW();'
);

-- =============================================
-- 验证
-- =============================================
SELECT '长期登录功能初始化完成' AS message;
SELECT '表已创建:' AS info, tablename FROM pg_tables WHERE tablename = 'long_term_login_tokens';
