-- =============================================
-- 取消数据更新触发器，改为每晚定时计算
-- =============================================

-- 1. 删除所有数据变更触发器
DROP TRIGGER IF EXISTS users_after_update_trigger ON users;
DROP TRIGGER IF EXISTS user_requirements_after_update_trigger ON user_requirements;
DROP TRIGGER IF EXISTS users_after_insert_trigger ON users;
DROP TRIGGER IF EXISTS user_requirements_after_insert_trigger ON user_requirements;

-- 2. 删除触发器函数（可选，保留函数供定时任务调用）
-- DROP FUNCTION IF EXISTS trigger_recalculate_user_matches();

-- 3. 取消旧的定时任务（每30分钟执行）
DO $$
BEGIN
    PERFORM cron.unschedule('calculate_all_matches');
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END $$;

-- 4. 设置新的定时任务：每晚11点10分执行
-- cron表达式：'10 23 * * *' 表示每天23:10执行
SELECT cron.schedule(
    'calculate_all_matches_nightly',
    '10 23 * * *',
    'SELECT calculate_all_matches();'
);

-- 5. 验证触发器已删除
SELECT 
    '触发器状态检查' AS info,
    COUNT(*) AS remaining_triggers
FROM information_schema.triggers 
WHERE event_object_table IN ('users', 'user_requirements')
AND trigger_name LIKE '%after%';

-- 6. 验证定时任务已设置
SELECT 
    '定时任务检查' AS info,
    jobid,
    schedule,
    command
FROM cron.job 
WHERE jobname = 'calculate_all_matches_nightly';

-- 7. 显示完成信息
SELECT '✅ 触发器已删除，定时任务已设置为每晚11点10分执行' AS status;