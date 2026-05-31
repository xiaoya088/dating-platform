-- =============================================
-- 禁用 RLS 以确保中介能正常工作
-- =============================================

-- 禁用 users 表的 RLS
ALTER TABLE IF EXISTS users DISABLE ROW LEVEL SECURITY;

-- 禁用 agencies 表的 RLS
ALTER TABLE IF EXISTS agencies DISABLE ROW LEVEL SECURITY;

-- 禁用 agency_requests 表的 RLS
ALTER TABLE IF EXISTS agency_requests DISABLE ROW LEVEL SECURITY;

-- 禁用 admins 表的 RLS
ALTER TABLE IF EXISTS admins DISABLE ROW LEVEL SECURITY;

-- 禁用 messages 表的 RLS
ALTER TABLE IF EXISTS messages DISABLE ROW LEVEL SECURITY;

-- 禁用 dating_events 表的 RLS
ALTER TABLE IF EXISTS dating_events DISABLE ROW LEVEL SECURITY;

-- 禁用 registrations 表的 RLS
ALTER TABLE IF EXISTS registrations DISABLE ROW LEVEL SECURITY;

-- 禁用 notifications 表的 RLS
ALTER TABLE IF EXISTS notifications DISABLE ROW LEVEL SECURITY;

-- 禁用 feedback 表的 RLS
ALTER TABLE IF EXISTS feedback DISABLE ROW LEVEL SECURITY;

-- 禁用 system_logs 表的 RLS
ALTER TABLE IF EXISTS system_logs DISABLE ROW LEVEL SECURITY;

SELECT '✅ RLS 已禁用（仅对存在的表）' AS message;