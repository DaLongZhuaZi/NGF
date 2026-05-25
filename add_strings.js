const fs = require('fs');
const path = require('path');

const newStrings = {
  tab_framework: { base: '框架', zh_CN: '框架', en_US: 'Framework' },
  tab_features: { base: '功能', zh_CN: '功能', en_US: 'Features' },
  tab_showcase: { base: '展示', zh_CN: '展示', en_US: 'Showcase' },
  tab_device: { base: '设备', zh_CN: '设备', en_US: 'Device' },
  tab_settings: { base: '设置', zh_CN: '设置', en_US: 'Settings' },

  system_resource_preview_status_default: { base: '点击任一图标可复制 sys.symbol 资源引用', zh_CN: '点击任一图标可复制 sys.symbol 资源引用', en_US: 'Click any icon to copy sys.symbol reference' },
  system_resource_preview_title: { base: '系统 Symbol 图标库', zh_CN: '系统 Symbol 图标库', en_US: 'System Symbol Library' },
  system_resource_preview_subtitle: { base: 'HarmonyOS sys.symbol 资源预览', zh_CN: 'HarmonyOS sys.symbol 资源预览', en_US: 'HarmonyOS sys.symbol Resource Preview' },
  system_resource_preview_copy_btn: { base: '复制引用', zh_CN: '复制引用', en_US: 'Copy Reference' },
  system_resource_preview_metric_total: { base: '总数', zh_CN: '总数', en_US: 'Total' },
  system_resource_preview_metric_groups: { base: '分组', zh_CN: '分组', en_US: 'Groups' },
  system_resource_preview_metric_current: { base: '当前', zh_CN: '当前', en_US: 'Current' },
  system_resource_preview_search_placeholder: { base: '搜索 sys.symbol 名称', zh_CN: '搜索 sys.symbol 名称', en_US: 'Search sys.symbol name' },
  system_resource_preview_search_btn: { base: '搜索', zh_CN: '搜索', en_US: 'Search' },
  system_resource_preview_filter_all: { base: '全部', zh_CN: '全部', en_US: 'All' },
  system_resource_preview_search_results_desc: { base: '搜索结果 %1$d 个，已显示 %2$d 个', zh_CN: '搜索结果 %1$d 个，已显示 %2$d 个', en_US: '%1$d results found, %2$d displayed' },
  system_resource_preview_group_unselected: { base: '未选择分组', zh_CN: '未选择分组', en_US: 'No Group Selected' },
  system_resource_preview_group_select_prompt: { base: '请选择一个 Symbol 分组', zh_CN: '请选择一个 Symbol 分组', en_US: 'Please select a Symbol group' },
  system_resource_preview_group_summary: { base: '%1$s · %2$d 个 Symbol', zh_CN: '%1$s · %2$d 个 Symbol', en_US: '%1$s · %2$d Symbols' },
  system_resource_preview_group_title: { base: '资源分组', zh_CN: '资源分组', en_US: 'Resource Groups' },
  system_resource_preview_search_results: { base: '搜索结果', zh_CN: '搜索结果', en_US: 'Search Results' },
  system_resource_preview_no_match: { base: '未找到匹配的系统 Symbol', zh_CN: '未找到匹配的系统 Symbol', en_US: 'No matching system Symbol found' },
  system_resource_preview_search_status: { base: '搜索 %1$s：%2$d 个结果', zh_CN: '搜索 %1$s：%2$d 个结果', en_US: 'Search %1$s: %2$d results' },
  system_resource_preview_copy_success: { base: '已复制 %1$s', zh_CN: '已复制 %1$s', en_US: 'Copied %1$s' },
  system_resource_preview_copy_fail_msg: { base: '复制失败：%1$s', zh_CN: '复制失败：%1$s', en_US: 'Copy failed: %1$s' },
  system_resource_preview_copy_fail: { base: '复制失败', zh_CN: '复制失败', en_US: 'Copy failed' },

  device_awareness_preferred_anchor: { base: '推荐停靠', zh_CN: '推荐停靠', en_US: 'Preferred Anchor' },
  device_awareness_left_side: { base: '左侧', zh_CN: '左侧', en_US: 'Left' },
  device_awareness_right_side: { base: '右侧', zh_CN: '右侧', en_US: 'Right' },
  device_awareness_holding_side: { base: '握持侧', zh_CN: '握持侧', en_US: 'Holding Side' },
  device_awareness_data_source: { base: '数据来源', zh_CN: '数据来源', en_US: 'Data Source' },
  device_awareness_confidence: { base: '置信度', zh_CN: '置信度', en_US: 'Confidence' },
  device_awareness_precise_supported: { base: '精确握姿支持', zh_CN: '精确握姿支持', en_US: 'Precise Posture Supported' },
  device_awareness_operating_hand_supported: { base: '操作手增强', zh_CN: '操作手增强', en_US: 'Operating Hand Enhancement' },
  device_awareness_available_or_try: { base: '可用或可尝试', zh_CN: '可用或可尝试', en_US: 'Available or Tryable' },
  device_awareness_device_not_support: { base: '当前设备不支持', zh_CN: '当前设备不支持', en_US: 'Not Supported on Current Device' },
  device_awareness_holding_updated_at: { base: '握持刷新时间', zh_CN: '握持刷新时间', en_US: 'Holding Updated At' },

  device_awareness_device_info_title: { base: '设备信息', zh_CN: '设备信息', en_US: 'Device Info' },
  device_awareness_device_type: { base: '设备类型', zh_CN: '设备类型', en_US: 'Device Type' },
  device_awareness_screen_orientation: { base: '屏幕方向', zh_CN: '屏幕方向', en_US: 'Screen Orientation' },
  device_awareness_breakpoint: { base: '断点', zh_CN: '断点', en_US: 'Breakpoint' },
  device_awareness_viewport_width: { base: '视口宽度', zh_CN: '视口宽度', en_US: 'Viewport Width' },
  device_awareness_viewport_height: { base: '视口高度', zh_CN: '视口高度', en_US: 'Viewport Height' },
  device_awareness_is_tablet: { base: '平板类设备', zh_CN: '平板类设备', en_US: 'Is Tablet' },
  device_awareness_is_foldable: { base: '折叠屏', zh_CN: '折叠屏', en_US: 'Is Foldable' },
  device_awareness_fold_status: { base: '折叠状态', zh_CN: '折叠状态', en_US: 'Fold Status' },
  device_awareness_is_landscape: { base: '横屏', zh_CN: '横屏', en_US: 'Is Landscape' },
  device_awareness_update_reason: { base: '刷新来源', zh_CN: '刷新来源', en_US: 'Update Reason' },
  device_awareness_updated_at: { base: '刷新时间', zh_CN: '刷新时间', en_US: 'Updated At' },

  device_awareness_holding_left: { base: '左手握持', zh_CN: '左手握持', en_US: 'Left Hand Holding' },
  device_awareness_holding_right: { base: '右手握持', zh_CN: '右手握持', en_US: 'Right Hand Holding' },
  device_awareness_holding_both: { base: '双手握持', zh_CN: '双手握持', en_US: 'Both Hands Holding' },
  device_awareness_holding_none: { base: '未握持', zh_CN: '未握持', en_US: 'Not Holding' },
  device_awareness_unknown: { base: '未知', zh_CN: '未知', en_US: 'Unknown' },
  device_awareness_source_holding_hand: { base: '智感握姿', zh_CN: '智感握姿', en_US: 'Holding Hand' },
  device_awareness_source_operating_hand: { base: '操作手', zh_CN: '操作手', en_US: 'Operating Hand' },
  device_awareness_source_combined: { base: '握姿+操作手联合', zh_CN: '握姿+操作手联合', en_US: 'Combined' },
  device_awareness_source_fallback: { base: '默认回退', zh_CN: '默认回退', en_US: 'Default Fallback' },
  device_awareness_confidence_exact: { base: '精确', zh_CN: '精确', en_US: 'Exact' },
  device_awareness_confidence_inferred: { base: '推断', zh_CN: '推断', en_US: 'Inferred' },
  device_awareness_confidence_fallback: { base: '回退', zh_CN: '回退', en_US: 'Fallback' },
  device_awareness_device_phone: { base: '手机', zh_CN: '手机', en_US: 'Phone' },
  device_awareness_device_tablet: { base: '平板', zh_CN: '平板', en_US: 'Tablet' },
  device_awareness_device_2in1: { base: '2in1设备', zh_CN: '2in1设备', en_US: '2-in-1 Device' },
  device_awareness_orientation_portrait: { base: '竖屏', zh_CN: '竖屏', en_US: 'Portrait' },
  device_awareness_orientation_landscape: { base: '横屏', zh_CN: '横屏', en_US: 'Landscape' },

  device_awareness_reason_initialize: { base: '初始化', zh_CN: '初始化', en_US: 'Initialize' },
  device_awareness_reason_window_bind: { base: '窗口绑定', zh_CN: '窗口绑定', en_US: 'Window Bind' },
  device_awareness_reason_display_change: { base: '屏幕变化', zh_CN: '屏幕变化', en_US: 'Display Change' },
  device_awareness_reason_window_size_change: { base: '窗口尺寸变化', zh_CN: '窗口尺寸变化', en_US: 'Window Size Change' },
  device_awareness_reason_fold_status_change: { base: '折叠状态变化', zh_CN: '折叠状态变化', en_US: 'Fold Status Change' },
  device_awareness_reason_config_update: { base: '系统配置变化', zh_CN: '系统配置变化', en_US: 'Config Update' },
  device_awareness_reason_ability_foreground: { base: '应用回到前台', zh_CN: '应用回到前台', en_US: 'Ability Foreground' },
  device_awareness_reason_page_appear: { base: '页面出现', zh_CN: '页面出现', en_US: 'Page Appear' },
  device_awareness_reason_window_clear: { base: '窗口释放', zh_CN: '窗口释放', en_US: 'Window Clear' },
  device_awareness_not_updated_yet: { base: '尚未刷新', zh_CN: '尚未刷新', en_US: 'Not Updated Yet' },
  device_awareness_fold_expanded: { base: '展开', zh_CN: '展开', en_US: 'Expanded' },
  device_awareness_fold_folded: { base: '折叠', zh_CN: '折叠', en_US: 'Folded' },
  device_awareness_fold_half_folded: { base: '半折叠/悬停', zh_CN: '半折叠/悬停', en_US: 'Half Folded' },
  device_awareness_realtime_holding: { base: '实时握持：%1$s / %2$s', zh_CN: '实时握持：%1$s / %2$s', en_US: 'Realtime Holding: %1$s / %2$s' },
  device_awareness_realtime_device: { base: '实时设备：%1$s · %2$s x %3$s · %4$s', zh_CN: '实时设备：%1$s · %2$s x %3$s · %4$s', en_US: 'Realtime Device: %1$s · %2$s x %3$s · %4$s' },
  device_awareness_unknown_format: { base: '未知(%1$s)', zh_CN: '未知(%1$s)', en_US: 'Unknown(%1$s)' }
};

const dirs = ['base', 'zh_CN', 'en_US'];

dirs.forEach(lang => {
  const filePath = path.join(__dirname, 'entry/src/main/resources', lang, 'element', 'string.json');
  if (fs.existsSync(filePath)) {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    
    // add missing strings
    Object.keys(newStrings).forEach(key => {
      const existing = data.string.find(item => item.name === key);
      if (!existing) {
        data.string.push({
          name: key,
          value: newStrings[key][lang]
        });
      }
    });

    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    console.log(`Updated ${filePath}`);
  } else {
    console.log(`File not found: ${filePath}`);
  }
});
