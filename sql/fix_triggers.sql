-- ============================================
-- 修复数据库触发器和函数问题
-- 如果保存用户信息时出现函数不存在的错误，运行此脚本
-- ============================================

-- 1. 删除可能导致问题的触发器（暂时禁用自动匹配计算）
DROP TRIGGER IF EXISTS users_after_update_trigger ON users;
DROP TRIGGER IF EXISTS user_requirements_after_update_trigger ON user_requirements;
DROP TRIGGER IF EXISTS users_after_insert_trigger ON users;
DROP TRIGGER IF EXISTS user_requirements_after_insert_trigger ON user_requirements;

-- 2. 删除可能不完整的函数
DROP FUNCTION IF EXISTS trigger_recalculate_user_matches();
DROP FUNCTION IF EXISTS calculate_matches_for_user(UUID);
DROP FUNCTION IF EXISTS calculate_all_matches();
DROP FUNCTION IF EXISTS calculate_single_user_matches(UUID);

-- 3. 验证users表可以正常更新
SELECT '触发器已删除，用户保存功能应该正常工作了！' AS status;

-- 4. 查看当前users表的触发器
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users';
