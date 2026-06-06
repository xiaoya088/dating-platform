-- ============================================
-- 添加私信回复功能所需字段
-- ============================================

-- 添加回复相关字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'reply_to_id'
    ) THEN
        ALTER TABLE messages ADD COLUMN reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL;
        RAISE NOTICE '已添加 reply_to_id 字段';
    ELSE
        RAISE NOTICE 'reply_to_id 字段已存在';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'reply_to_content'
    ) THEN
        ALTER TABLE messages ADD COLUMN reply_to_content TEXT;
        RAISE NOTICE '已添加 reply_to_content 字段';
    ELSE
        RAISE NOTICE 'reply_to_content 字段已存在';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' AND column_name = 'reply_to_name'
    ) THEN
        ALTER TABLE messages ADD COLUMN reply_to_name TEXT;
        RAISE NOTICE '已添加 reply_to_name 字段';
    ELSE
        RAISE NOTICE 'reply_to_name 字段已存在';
    END IF;
END $$;

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_messages_reply_to_id ON messages(reply_to_id);

-- 验证表结构
SELECT 'messages 表结构:' AS info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'messages'
ORDER BY ordinal_position;
