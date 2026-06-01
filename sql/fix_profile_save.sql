-- =============================================
-- 修复用户资料保存失败问题
-- 问题原因：触发器在更新用户资料时重新计算匹配，
-- 但DELETE语句可能没有正确执行导致重复数据
-- =============================================

-- 1. 首先禁用触发器（临时）
DROP TRIGGER IF EXISTS users_after_update_trigger ON users;
DROP TRIGGER IF EXISTS user_requirements_after_update_trigger ON user_requirements;

-- 2. 删除 match_results 表中的重复数据
DELETE FROM match_results a
USING match_results b
WHERE a.ctid < b.ctid
AND a.user_id = b.user_id 
AND a.target_user_id = b.target_user_id;

-- 3. 重新创建触发器，添加错误处理
CREATE OR REPLACE FUNCTION trigger_recalculate_user_matches()
RETURNS TRIGGER AS $$
BEGIN
    -- 使用 BEGIN...EXCEPTION 捕获错误
    BEGIN
        PERFORM calculate_matches_for_user(NEW.id);
    EXCEPTION
        WHEN OTHERS THEN
            -- 如果匹配计算失败，记录日志但不影响主事务
            RAISE NOTICE '匹配计算失败 for user %: %', NEW.id, SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. 重新创建触发器
CREATE TRIGGER users_after_update_trigger
AFTER UPDATE ON users
FOR EACH ROW
WHEN (OLD.status = 'active' AND NEW.status = 'active')
EXECUTE FUNCTION trigger_recalculate_user_matches();

CREATE TRIGGER user_requirements_after_update_trigger
AFTER INSERT OR UPDATE ON user_requirements
FOR EACH ROW
EXECUTE FUNCTION trigger_recalculate_user_matches();

-- 5. 验证修复
SELECT '触发器状态:' AS info;
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE trigger_name IN ('users_after_update_trigger', 'user_requirements_after_update_trigger');

SELECT 'match_results 表记录数:' AS info, COUNT(*) as total FROM match_results;
