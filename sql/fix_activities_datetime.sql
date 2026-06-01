-- 检查activities表的结构
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'activities';

-- 如果deadline或activity_time是VARCHAR类型，修改为TIMESTAMP类型
ALTER TABLE activities ALTER COLUMN deadline TYPE TIMESTAMP USING deadline::TIMESTAMP;
ALTER TABLE activities ALTER COLUMN activity_time TYPE TIMESTAMP USING activity_time::TIMESTAMP;

-- 验证修改后的结构
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'activities';
