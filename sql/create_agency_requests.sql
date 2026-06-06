-- ============================================
-- 创建 agency_requests 表（用于用户通过中介联系私人用户）
-- ============================================

-- 如果表不存在，创建它
CREATE TABLE IF NOT EXISTS agency_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    agency_id UUID REFERENCES agencies(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected, completed
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_agency_requests_from_user_id ON agency_requests(from_user_id);
CREATE INDEX IF NOT EXISTS idx_agency_requests_to_user_id ON agency_requests(to_user_id);
CREATE INDEX IF NOT EXISTS idx_agency_requests_agency_id ON agency_requests(agency_id);
CREATE INDEX IF NOT EXISTS idx_agency_requests_status ON agency_requests(status);

-- 禁用 RLS（允许前端访问）
ALTER TABLE IF EXISTS agency_requests DISABLE ROW LEVEL SECURITY;

-- 授予权限
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE ON TABLE agency_requests TO anon;

-- 验证
SELECT 'agency_requests 表创建完成' AS status;
SELECT COUNT(*) AS total_requests FROM agency_requests;
