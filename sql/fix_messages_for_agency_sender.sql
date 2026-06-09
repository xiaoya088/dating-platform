-- =============================================
-- 修复中介发送消息失败的问题
-- 问题原因：messages 表的 from_user_id 有外键约束引用 users(id)
-- 但中介用户存储在 agencies 表中，不在 users 表中
-- =============================================

-- 1. 查看当前 messages 表结构
SELECT '=== 当前 messages 表结构 ===' AS info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'messages';

-- 2. 查看外键约束
SELECT '=== 当前外键约束 ===' AS info;
SELECT 
    tc.constraint_name, 
    kcu.table_name AS foreign_table_name,
    kcu.column_name AS foreign_column_name,
    ccu.table_name AS referenced_table_name,
    ccu.column_name AS referenced_column_name
FROM 
    information_schema.table_constraints tc
JOIN 
    information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN 
    information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE 
    tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'messages';

-- 3. 删除现有的外键约束（如果存在）
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_from_user_id_fkey;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_to_user_id_fkey;

-- 4. 添加 sender_type 字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'sender_type') THEN
        ALTER TABLE messages ADD COLUMN sender_type VARCHAR(20) DEFAULT 'user';
        RAISE NOTICE 'Added sender_type column';
    END IF;
END $$;

-- 5. 添加索引
DROP INDEX IF EXISTS idx_messages_from_user_sender;
DROP INDEX IF EXISTS idx_messages_to_user;
DROP INDEX IF EXISTS idx_messages_sender_type;

CREATE INDEX idx_messages_from_user_sender ON messages(from_user_id, sender_type);
CREATE INDEX idx_messages_to_user ON messages(to_user_id);
CREATE INDEX idx_messages_sender_type ON messages(sender_type);

-- 6. 验证修改结果
SELECT '=== 修改后的 messages 表结构 ===' AS info;
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'messages';

SELECT '=== 当前索引 ===' AS info;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'messages';

-- 7. 测试插入一条中介消息（可选）
-- INSERT INTO messages (from_user_id, to_user_id, content, sender_type, created_at)
-- VALUES ('agency_uuid_here', 'user_uuid_here', '测试消息', 'agency', NOW());
