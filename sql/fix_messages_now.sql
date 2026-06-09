-- =======================
-- 立即执行此脚本！
-- 解决中介发送私信失败的问题
-- =======================

-- 1. 删除约束 from_user_id_fkey（这是导致问题的原因）
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_from_user_id_fkey;

-- 2. 完成！现在中介可以发送私信了

-- 3. 验证修改结果
SELECT 'messages_from_user_id_fkey 已删除' AS result;
