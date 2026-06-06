const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://awhpfdhxcoycxgfhpfoy.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_VyBOeg7kGc_i905NOmd69g_KkSbsOpA';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function initFamilyOptions() {
    console.log('=== 初始化家庭情况选项数据 ===\n');
    
    try {
        // 首先检查表是否存在
        console.log('1. 检查 family_options 表...');
        let { data, error } = await supabase.from('family_options').select('*').limit(1);
        
        if (error && error.message.includes('does not exist')) {
            console.log('❌ family_options 表不存在，需要创建');
            return;
        }
        
        if (error) {
            console.log('❌ 检查失败:', error.message);
            return;
        }
        
        console.log(`✅ family_options 表存在，当前记录数: ${data.length || 0}`);
        
        // 如果表为空，插入初始数据
        if (!data || data.length === 0) {
            console.log('\n2. 表为空，开始插入初始数据...');
            
            const initialData = [
                // 父母现状
                { field_name: 'family_parents_status', option_value: 'both_alive', option_label: '双亲健在', sort_order: 1 },
                { field_name: 'family_parents_status', option_value: 'single_parent', option_label: '单亲', sort_order: 2 },
                { field_name: 'family_parents_status', option_value: 'both_deceased', option_label: '父母已故', sort_order: 3 },
                
                // 父母工作
                { field_name: 'family_parents_job', option_value: 'farming', option_label: '务农', sort_order: 1 },
                { field_name: 'family_parents_job', option_value: 'employed', option_label: '在职上班', sort_order: 2 },
                { field_name: 'family_parents_job', option_value: 'retired', option_label: '退休', sort_order: 3 },
                { field_name: 'family_parents_job', option_value: 'business', option_label: '个体经商', sort_order: 4 },
                
                // 兄弟姐妹
                { field_name: 'family_siblings', option_value: 'only_child', option_label: '独生', sort_order: 1 },
                { field_name: 'family_siblings', option_value: 'has_brother_older', option_label: '有兄', sort_order: 2 },
                { field_name: 'family_siblings', option_value: 'has_brother_younger', option_label: '有弟', sort_order: 3 },
                { field_name: 'family_siblings', option_value: 'has_sister_older', option_label: '有姐', sort_order: 4 },
                { field_name: 'family_siblings', option_value: 'has_sister_younger', option_label: '有妹', sort_order: 5 },
                
                // 原生家庭定居地
                { field_name: 'family_hometown', option_value: 'same_city', option_label: '和本人同城', sort_order: 1 },
                { field_name: 'family_hometown', option_value: 'different_city', option_label: '异地老家', sort_order: 2 },
                
                // 父母养老保障
                { field_name: 'family_pension', option_value: 'has_pension', option_label: '有退休金社保', sort_order: 1 },
                { field_name: 'family_pension', option_value: 'no_pension', option_label: '无养老保障', sort_order: 2 },
                
                // 家庭经济状况
                { field_name: 'family_economic_status', option_value: 'wealthy', option_label: '富贵人家', sort_order: 1 },
                { field_name: 'family_economic_status', option_value: 'middle_class', option_label: '中产家庭', sort_order: 2 },
                { field_name: 'family_economic_status', option_value: 'comfortable', option_label: '小康之家', sort_order: 3 },
                { field_name: 'family_economic_status', option_value: 'slight_debt', option_label: '略有负债', sort_order: 4 },
                
                // 家庭氛围
                { field_name: 'family_atmosphere', option_value: 'traditional', option_label: '传统保守', sort_order: 1 },
                { field_name: 'family_atmosphere', option_value: 'open', option_label: '开明随和', sort_order: 2 },
                
                // 是否和父母同住
                { field_name: 'family_living_with_parents', option_value: 'living_alone', option_label: '自住独居', sort_order: 1 },
                { field_name: 'family_living_with_parents', option_value: 'living_with_parents', option_label: '和父母同住', sort_order: 2 },
                { field_name: 'family_living_with_parents', option_value: 'living_nearby', option_label: '就近居住', sort_order: 3 },
                
                // 家里对婚恋态度
                { field_name: 'family_marriage_attitude', option_value: 'urgent', option_label: '催婚', sort_order: 1 },
                { field_name: 'family_marriage_attitude', option_value: 'natural', option_label: '顺其自然', sort_order: 2 },
                { field_name: 'family_marriage_attitude', option_value: 'no_interference', option_label: '不干涉', sort_order: 3 },
            ];
            
            const { error: insertError } = await supabase.from('family_options').insert(initialData);
            
            if (insertError) {
                console.log('❌ 插入数据失败:', insertError.message);
                return;
            }
            
            console.log('✅ 成功插入 ' + initialData.length + ' 条记录');
        } else {
            console.log('\n2. 表已有数据，无需初始化');
        }
        
        // 验证数据
        console.log('\n3. 验证数据...');
        const { data: verifyData, error: verifyError } = await supabase
            .from('family_options')
            .select('*')
            .order('field_name, sort_order');
        
        if (verifyError) {
            console.log('❌ 验证失败:', verifyError.message);
            return;
        }
        
        console.log(`✅ 验证成功，共 ${verifyData.length} 条记录`);
        
        // 按字段分组显示
        const grouped = {};
        verifyData.forEach(item => {
            if (!grouped[item.field_name]) {
                grouped[item.field_name] = [];
            }
            grouped[item.field_name].push(item);
        });
        
        console.log('\n4. 各字段数据:');
        Object.keys(grouped).forEach(fieldName => {
            console.log(`   - ${fieldName}: ${grouped[fieldName].length} 条`);
        });
        
    } catch (e) {
        console.log('❌ 发生异常:', e.message);
    }
}

initFamilyOptions();