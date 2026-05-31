-- =============================================
-- 婚恋匹配系统 - 数据库端匹配计算
-- =============================================

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================
-- 1. 创建匹配计算存储过程
-- =============================================

-- 计算年龄函数
CREATE OR REPLACE FUNCTION calculate_age(birth_date DATE) 
RETURNS INTEGER AS $$
BEGIN
    IF birth_date IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 计算区间匹配分数
CREATE OR REPLACE FUNCTION calculate_interval_score(value INTEGER, min_val INTEGER, max_val INTEGER)
RETURNS INTEGER AS $$
BEGIN
    IF value IS NULL OR (min_val IS NULL AND max_val IS NULL) THEN
        RETURN 100;
    END IF;
    
    IF min_val IS NOT NULL AND value < min_val THEN
        RETURN 0;
    END IF;
    
    IF max_val IS NOT NULL AND value > max_val THEN
        RETURN 0;
    END IF;
    
    RETURN 100;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 计算分类匹配分数
CREATE OR REPLACE FUNCTION calculate_category_score(value TEXT, category_list TEXT[])
RETURNS INTEGER AS $$
BEGIN
    IF value IS NULL OR category_list IS NULL OR array_length(category_list, 1) = 0 THEN
        RETURN 100;
    END IF;
    
    IF value = ANY(category_list) THEN
        RETURN 100;
    END IF;
    
    RETURN 0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 获取重要性权重
CREATE OR REPLACE FUNCTION get_importance_weight(importance TEXT)
RETURNS NUMERIC AS $$
BEGIN
    CASE importance
        WHEN 'must' THEN RETURN 2.0;
        WHEN 'important' THEN RETURN 1.5;
        WHEN 'general' THEN RETURN 1.0;
        ELSE RETURN 1.0;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 计算单个用户与目标用户的匹配分数（返回单条记录）
CREATE OR REPLACE FUNCTION calculate_single_match_score(p_user_id UUID, p_target_id UUID)
RETURNS TABLE (score INTEGER, filtered BOOLEAN, reasons TEXT[]) AS $$
DECLARE
    v_my_gender TEXT;
    v_my_birthday DATE;
    v_my_height INTEGER;
    v_my_education TEXT;
    v_my_marital_status TEXT;
    v_my_current_address TEXT;
    v_my_income TEXT;
    v_my_smoking TEXT;
    v_my_drinking TEXT;
    
    v_target_gender TEXT;
    v_target_birthday DATE;
    v_target_height INTEGER;
    v_target_education TEXT;
    v_target_marital_status TEXT;
    v_target_current_address TEXT;
    v_target_income TEXT;
    v_target_smoking TEXT;
    v_target_drinking TEXT;
    
    v_req_min_age INTEGER;
    v_req_max_age INTEGER;
    v_req_min_height INTEGER;
    v_req_max_height INTEGER;
    v_req_min_income INTEGER;
    v_req_education TEXT;
    v_req_marital_status TEXT;
    v_req_province TEXT;
    v_req_smoking TEXT;
    v_req_drinking TEXT;
    v_req_smoking_importance TEXT;
    v_req_drinking_importance TEXT;
    v_req_age_importance TEXT;
    v_req_height_importance TEXT;
    v_req_education_importance TEXT;
    v_req_marital_importance TEXT;
    v_req_province_importance TEXT;
    
    v_target_req_min_age INTEGER;
    v_target_req_max_age INTEGER;
    v_target_req_min_height INTEGER;
    v_target_req_max_height INTEGER;
    v_target_req_min_income INTEGER;
    v_target_req_education TEXT;
    v_target_req_marital_status TEXT;
    v_target_req_province TEXT;
    v_target_req_smoking TEXT;
    v_target_req_drinking TEXT;
    v_target_req_smoking_importance TEXT;
    v_target_req_drinking_importance TEXT;
    v_target_req_age_importance TEXT;
    v_target_req_height_importance TEXT;
    v_target_req_education_importance TEXT;
    v_target_req_marital_importance TEXT;
    v_target_req_province_importance TEXT;
    
    v_my_age INTEGER;
    v_target_age INTEGER;
    v_total_score NUMERIC := 0;
    v_total_weight NUMERIC := 0;
    v_result_score INTEGER;
    v_result_filtered BOOLEAN := FALSE;
    v_result_reasons TEXT[] := '{}'::TEXT[];
BEGIN
    -- 获取当前用户数据
    SELECT u.gender, u.birthday, u.height, u.education, u.marital_status, 
           u.current_address, u.income::TEXT, u.smoking, u.drinking
    INTO v_my_gender, v_my_birthday, v_my_height, v_my_education, v_my_marital_status,
         v_my_current_address, v_my_income, v_my_smoking, v_my_drinking
    FROM users u
    WHERE u.id = p_user_id AND u.status = 'active';
    
    -- 获取目标用户数据
    SELECT u.gender, u.birthday, u.height, u.education, u.marital_status,
           u.current_address, u.income::TEXT, u.smoking, u.drinking
    INTO v_target_gender, v_target_birthday, v_target_height, v_target_education, v_target_marital_status,
         v_target_current_address, v_target_income, v_target_smoking, v_target_drinking
    FROM users u
    WHERE u.id = p_target_id AND u.status = 'active';
    
    -- 检查用户是否存在
    IF v_my_gender IS NULL AND v_my_birthday IS NULL THEN
        RETURN QUERY SELECT 0, TRUE, ARRAY['无法获取当前用户数据'];
        RETURN;
    END IF;
    
    IF v_target_gender IS NULL AND v_target_birthday IS NULL THEN
        RETURN QUERY SELECT 0, TRUE, ARRAY['无法获取目标用户数据'];
        RETURN;
    END IF;
    
    -- 异性恋匹配：只匹配异性
    IF v_my_gender IS NOT NULL AND v_target_gender IS NOT NULL 
       AND v_my_gender = v_target_gender THEN
        RETURN QUERY SELECT 0, TRUE, ARRAY['性别相同，仅匹配异性'];
        RETURN;
    END IF;
    
    -- 获取当前用户的择偶要求
    SELECT COALESCE(r.min_age, 0), COALESCE(r.max_age, 100),
           COALESCE(r.min_height, 0), COALESCE(r.max_height, 250),
           COALESCE(r.min_income, 0), r.education, r.marital_status,
           r.province, r.smoking, r.drinking,
           r.smoking_importance, r.drinking_importance,
           r.age_importance, r.height_importance, r.education_importance,
           r.marital_importance, r.province_importance
    INTO v_req_min_age, v_req_max_age, v_req_min_height, v_req_max_height,
         v_req_min_income, v_req_education, v_req_marital_status,
         v_req_province, v_req_smoking, v_req_drinking,
         v_req_smoking_importance, v_req_drinking_importance,
         v_req_age_importance, v_req_height_importance, v_req_education_importance,
         v_req_marital_importance, v_req_province_importance
    FROM user_requirements r
    WHERE r.user_id = p_user_id AND r.scheme_type = 'standard';
    
    -- 获取目标用户的择偶要求
    SELECT COALESCE(r.min_age, 0), COALESCE(r.max_age, 100),
           COALESCE(r.min_height, 0), COALESCE(r.max_height, 250),
           COALESCE(r.min_income, 0), r.education, r.marital_status,
           r.province, r.smoking, r.drinking,
           r.smoking_importance, r.drinking_importance,
           r.age_importance, r.height_importance, r.education_importance,
           r.marital_importance, r.province_importance
    INTO v_target_req_min_age, v_target_req_max_age, v_target_req_min_height, v_target_req_max_height,
         v_target_req_min_income, v_target_req_education, v_target_req_marital_status,
         v_target_req_province, v_target_req_smoking, v_target_req_drinking,
         v_target_req_smoking_importance, v_target_req_drinking_importance,
         v_target_req_age_importance, v_target_req_height_importance, v_target_req_education_importance,
         v_target_req_marital_importance, v_target_req_province_importance
    FROM user_requirements r
    WHERE r.user_id = p_target_id AND r.scheme_type = 'standard';
    
    -- 硬筛选：吸烟习惯（当前用户的要求）
    IF v_req_smoking_importance = 'must' AND v_req_smoking IS NOT NULL THEN
        IF v_target_smoking IS NULL OR v_target_smoking != v_req_smoking THEN
            RETURN QUERY SELECT 0, TRUE, ARRAY['吸烟习惯不符合要求'];
            RETURN;
        END IF;
    END IF;
    
    -- 硬筛选：饮酒习惯（当前用户的要求）
    IF v_req_drinking_importance = 'must' AND v_req_drinking IS NOT NULL THEN
        IF v_target_drinking IS NULL OR v_target_drinking != v_req_drinking THEN
            RETURN QUERY SELECT 0, TRUE, ARRAY['饮酒习惯不符合要求'];
            RETURN;
        END IF;
    END IF;
    
    -- 计算年龄
    v_my_age := calculate_age(v_my_birthday);
    v_target_age := calculate_age(v_target_birthday);
    
    -- 年龄匹配（目标用户的要求）
    IF v_target_req_min_age > 0 OR v_target_req_max_age < 100 THEN
        v_total_score := v_total_score + calculate_interval_score(v_my_age, v_target_req_min_age, v_target_req_max_age) 
                         * get_importance_weight(v_target_req_age_importance);
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_age_importance);
    END IF;
    
    -- 身高匹配（目标用户的要求）
    IF v_target_req_min_height > 0 OR v_target_req_max_height < 250 THEN
        v_total_score := v_total_score + calculate_interval_score(v_my_height, v_target_req_min_height, v_target_req_max_height) 
                         * get_importance_weight(v_target_req_height_importance);
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_height_importance);
    END IF;
    
    -- 学历匹配（目标用户的要求）
    IF v_target_req_education IS NOT NULL THEN
        v_total_score := v_total_score + calculate_category_score(v_my_education, string_to_array(v_target_req_education, ',')) 
                         * get_importance_weight(v_target_req_education_importance);
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_education_importance);
    END IF;
    
    -- 婚姻状况匹配（目标用户的要求）
    IF v_target_req_marital_status IS NOT NULL THEN
        v_total_score := v_total_score + calculate_category_score(v_my_marital_status, string_to_array(v_target_req_marital_status, ',')) 
                         * get_importance_weight(v_target_req_marital_importance);
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_marital_importance);
    END IF;
    
    -- 地区匹配（目标用户的要求）
    IF v_target_req_province IS NOT NULL THEN
        IF v_my_current_address IS NOT NULL AND v_my_current_address LIKE '%' || v_target_req_province || '%' THEN
            v_total_score := v_total_score + 100 * get_importance_weight(v_target_req_province_importance);
        END IF;
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_province_importance);
    END IF;
    
    -- 收入匹配（目标用户的要求）
    -- 注意：用户收入是文本格式，择偶要求是数字，直接比较改为简单匹配或跳过
    IF v_target_req_min_income > 0 AND v_my_income IS NOT NULL THEN
        -- 简单检查：只要用户填写了收入信息就给分
        -- 实际应用中可根据收入范围精确匹配
        v_total_score := v_total_score + 50;
        v_total_weight := v_total_weight + 1;
    END IF;
    
    -- 计算最终分数
    IF v_total_weight > 0 THEN
        v_result_score := ROUND(v_total_score / v_total_weight)::INTEGER;
    ELSE
        v_result_score := 50;
    END IF;
    
    RETURN QUERY SELECT v_result_score, v_result_filtered, v_result_reasons;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 2. 为单个用户计算所有匹配
-- =============================================

CREATE OR REPLACE FUNCTION calculate_matches_for_user(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_target_id UUID;
    v_score INTEGER;
    v_filtered BOOLEAN;
    v_reasons TEXT[];
BEGIN
    -- 删除旧的匹配结果
    DELETE FROM match_results WHERE user_id = p_user_id;

    -- 遍历所有其他活跃用户
    FOR v_target_id IN SELECT id FROM users WHERE id != p_user_id AND status = 'active' LOOP
        -- 检查是否在黑名单中
        IF EXISTS (SELECT 1 FROM blacklist WHERE user_id = p_user_id AND blocked_user_id = v_target_id) THEN
            CONTINUE;
        END IF;

        -- 计算匹配分数
        SELECT score, filtered, reasons INTO v_score, v_filtered, v_reasons
        FROM calculate_single_match_score(p_user_id, v_target_id);

        -- 保存匹配结果
        INSERT INTO match_results (user_id, target_user_id, score, is_filtered, filter_reason, calculated_at)
        VALUES (p_user_id, v_target_id, v_score, v_filtered, array_to_string(v_reasons, ', '), NOW());
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. 为所有用户计算匹配（批量计算）
-- =============================================

CREATE OR REPLACE FUNCTION calculate_all_matches()
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    FOR v_user_id IN SELECT id FROM users WHERE status = 'active' LOOP
        PERFORM calculate_matches_for_user(v_user_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. 设置定时任务（每30分钟执行一次）
-- =============================================

-- 先删除已存在的同名任务（忽略不存在的错误）
DO $$
BEGIN
    PERFORM cron.unschedule('calculate_all_matches');
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- 忽略任务不存在的错误
END $$;

-- 创建定时任务
SELECT cron.schedule(
    'calculate_all_matches',
    '*/30 * * * *',
    'SELECT calculate_all_matches();'
);

-- =============================================
-- 5. 添加数据变更触发器（可选）
-- =============================================

-- 用户数据更新时触发重新计算
CREATE OR REPLACE FUNCTION trigger_recalculate_user_matches()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM calculate_matches_for_user(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 删除已存在的触发器
DROP TRIGGER IF EXISTS users_after_update_trigger ON users;
DROP TRIGGER IF EXISTS user_requirements_after_update_trigger ON user_requirements;

-- 创建触发器
CREATE TRIGGER users_after_update_trigger
AFTER UPDATE ON users
FOR EACH ROW
WHEN (OLD.status = 'active' AND NEW.status = 'active')
EXECUTE FUNCTION trigger_recalculate_user_matches();

CREATE TRIGGER user_requirements_after_update_trigger
AFTER INSERT OR UPDATE ON user_requirements
FOR EACH ROW
EXECUTE FUNCTION trigger_recalculate_user_matches();

-- =============================================
-- 执行初始计算
-- =============================================
SELECT calculate_all_matches();

-- =============================================
-- 验证定时任务是否创建成功
-- =============================================
SELECT * FROM cron.job WHERE jobname = 'calculate_all_matches';
