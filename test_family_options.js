const { createClient } = require('@supabase/supabase-js');

// 使用正确的 Supabase 配置
const SUPABASE_URL = 'https://awhpfdhxcoycxgfhpfoy.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_VyBOeg7kGc_i905NOmd69g_KkSbsOpA';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testFamilyOptions() {
    console.log('=== 测试家庭情况选项表 ===\n');
    
    try {
        // 测试连接
        console.log('1. 测试数据库连接...');
        const { data: testData, error: testError } = await supabase.from('admins').select('id').limit(1);
        if (testError) {
            console.log('❌ 数据库连接失败:', testError.message);
            return;
        }
        console.log('✅ 数据库连接成功\n');
        
        // 检查 family_options 表
        console.log('2. 检查 family_options 表...');
        const { data: familyData, error: familyError } = await supabase
            .from('family_options')
            .select('*')
            .order('field_name, sort_order');
        
        if (familyError) {
            console.log('❌ 查询失败:', familyError.message);
            return;
        }
        
        if (!familyData || familyData.length === 0) {
            console.log('❌ family_options 表为空');
            console.log('需要运行 SQL 初始化脚本创建数据');
            return;
        }
        
        console.log(`✅ family_options 表有 ${familyData.length} 条记录\n`);
        
        // 按字段分组显示
        const grouped = {};
        familyData.forEach(item => {
            if (!grouped[item.field_name]) {
                grouped[item.field_name] = [];
            }
            grouped[item.field_name].push(item);
        });
        
        console.log('3. 各字段数据详情:');
        Object.keys(grouped).forEach(fieldName => {
            console.log(`\n   ${fieldName} (${grouped[fieldName].length}条):`);
            grouped[fieldName].forEach(item => {
                console.log(`     - ${item.option_value}: ${item.option_label} (排序: ${item.sort_order})`);
            });
        });
        
        // 测试查询特定字段
        console.log('\n4. 测试按字段查询...');
        const testField = 'family_parents_status';
        const { data: specificData, error: specificError } = await supabase
            .from('family_options')
            .select('*')
            .eq('field_name', testField)
            .order('sort_order');
        
        if (specificError) {
            console.log(`❌ 查询 ${testField} 失败:`, specificError.message);
        } else {
            console.log(`✅ 查询 ${testField} 成功，返回 ${specificData.length} 条记录`);
        }
        
    } catch (e) {
        console.log('❌ 发生异常:', e.message);
    }
}

testFamilyOptions();