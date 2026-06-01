-- 检查activity_registrations表结构
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'activity_registrations';

-- 添加取消原因和取消时间字段
ALTER TABLE activity_registrations 
ADD COLUMN IF NOT EXISTS cancel_reason TEXT,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

-- 验证添加后的结构
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'activity_registrations';
