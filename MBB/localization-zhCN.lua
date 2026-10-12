if( GetLocale() == "zhCN" ) then

MBB_TOOLTIP1 = "Ctrl + 右键 选择将一个按钮重新依附到迷你地图。";
MBB_OPTIONS_HEADER = "选项";
MBB_OPTIONS_OKBUTTON = "确定";
MBB_OPTIONS_CANCELBUTTON = "取消";
MBB_OPTIONS_SLIDEROFF = "无";
MBB_OPTIONS_SLIDERSEK = "秒";
MBB_OPTIONS_SLIDERLABEL = "消失时间：";
MBB_OPTIONS_EXPANSIONLABEL = "扩展方向：";
MBB_OPTIONS_EXPANSIONLEFT = "左侧";
MBB_OPTIONS_EXPANSIONTOP = "向上";
MBB_OPTIONS_EXPANSIONRIGHT = "右侧";
MBB_OPTIONS_EXPANSIONBOTTOM = "向下";
MBB_OPTIONS_MAXBUTTONSLABEL = "最大按钮数/每行：";
MBB_OPTIONS_MAXBUTTONSINFO = "(0=无限制)";
MBB_OPTIONS_ALTEXPANSIONLABEL = "下一行方向：";
	MBB_OPTIONS_BUTTONSCALE = "按钮大小：";
MBB_HELP1 = "输入 \"/mmbb <cmd>\" 以下 <cmd> 可以使用：";
MBB_HELP2 = "  |c00ffffffbuttons|r: 在 MBB 条上显示所有按钮";
MBB_HELP3 = "  |c00ffffffreset position|r: 重置 MBB 在迷你地图上的位置";
MBB_HELP4 = "  |c00ffffffreset all|r: 重置所有设置";
MBB_NOERRORS = "没有错误产生！";


MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn 已加载。"
MBB_FIRST_RUN_COUNT = "已收集 %d 个小地图按钮。"
MBB_FIRST_RUN_HELP = "输入 /mbb 查看可用命令。"
MBB_FIRST_RUN_RESCAN = "如果有按钮缺失，请使用 /mbb rescan。"

MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
MBB_ABOUT_VERSION = "版本：";
MBB_ABOUT_BASED_ON = "（基于 4.0.26）";
MBB_ABOUT_CREDITS_TITLE = "鸣谢：";

MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – 补丁状态";
MBB_PATCH_ADDON_INTERFACE = "插件接口版本：";
MBB_PATCH_WOW_INTERFACE = "当前 WoW 接口版本：";
MBB_PATCH_OK = "状态：插件已适配当前 WoW 补丁。";
MBB_PATCH_OLD = "状态：此插件为较旧的 WoW 补丁构建，请检查更新。";

MBB_HELP_ABOUT = "  |c00ffffffabout|r: 显示插件信息（版本和鸣谢）";
MBB_HELP_PATCH = "  |c00ffffffpatch|r: 显示补丁兼容状态";
MBB_HELP_RESCAN = "  |c00ffffffrescan|r: 重新扫描小地图以查找缺失按钮";
MBB_RESCAN_DONE = "MBB：重新扫描完成。发现 %d 个新的小地图按钮。";

MBB_OPTIONS_DETACH = "从小地图分离";
MBB_OPTIONS_DETACH_DESC = "允许在屏幕上自由移动 MBB 按钮。";
MBB_OPTIONS_DETACH_COMBAT = "战斗中无法更改。";


	-- Version update notification
	MBB_UPDATE_AVAILABLE = "MBB：有新版本可用：%s（当前使用 %s）。请通过 CurseForge 更新。";

	-- MBB Reborn 2.0 - Button Manager
	MBB_MANAGER_BUTTON = "按钮管理...";
	MBB_MANAGER_TITLE = "按钮管理";
	MBB_MANAGER_DESC = "管理已知的小地图按钮。勾选的按钮会收纳到 MBB 中。";
	MBB_MANAGER_ENABLED = "在 MBB 中";
	MBB_MANAGER_DISABLED = "在小地图上";
	MBB_MANAGER_MISSING = "未加载";
	MBB_MANAGER_RESCAN = "重新扫描";
	MBB_MANAGER_CLOSE = "关闭";
	MBB_MANAGER_COUNT = "已知按钮：%d";
	MBB_MANAGER_EMPTY = "尚未检测到按钮。请使用“重新扫描”。";
	MBB_MANAGER_COMBAT = "战斗中无法管理按钮。";
	MBB_MANAGER_COLUMN_BUTTON = "按钮";
	MBB_MANAGER_COLUMN_STATUS = "状态";
	MBB_MANAGER_TOOLTIP_INCLUDED = "已勾选：此按钮会收纳到 MBB 中。";
	MBB_MANAGER_TOOLTIP_EXCLUDED = "未勾选：此按钮会保留在小地图上。";
	MBB_HELP_MANAGER = "  |c00ffffffmanager|r：打开小地图按钮管理器";

	-- MBB Reborn 2.0 - Button ordering
	MBB_MANAGER_ORDER_HELP = "拖动一行或使用箭头来调整按钮顺序。";
	MBB_MANAGER_MOVE_UP = "上移";
	MBB_MANAGER_MOVE_DOWN = "下移";
	MBB_MANAGER_RESET_ORDER = "重置顺序";
	MBB_MANAGER_RESET_ORDER_DONE = "MBB：按钮顺序已重置。";
	MBB_MANAGER_DRAG_HINT = "拖动此行可更改其位置。";


-- MBB Reborn 2.0 - Positioning
	MBB_OPTIONS_LOCK_POSITION = "锁定位置";
	MBB_OPTIONS_LOCK_POSITION_DESC = "防止意外移动已从小地图分离的 MBB 按钮。";
	MBB_OPTIONS_SNAP_EDGES = "吸附到 WoW 窗口边缘";
	MBB_OPTIONS_SNAP_EDGES_DESC = "将分离的 MBB 按钮吸附到附近的 WoW 窗口边缘。注意：WoW 插件无法检测多个显示器之间的物理边界。";


-- MBB Reborn 2.0 - Profiles
	MBB_PROFILE_BUTTON = "配置方案";
	MBB_PROFILE_TITLE = "配置档";
	MBB_PROFILE_DESC = "配置档会保存布局、缩放、位置和按钮顺序。排除列表仍按角色分别保存。";
	MBB_PROFILE_CURRENT = "当前配置档：";
	MBB_PROFILE_ACTIVE = "已启用";
	MBB_PROFILE_DEFAULT_DISPLAY = "默认";
	MBB_PROFILE_ACTIVATE = "启用";
	MBB_PROFILE_NEW = "新建";
	MBB_PROFILE_DELETE = "删除";
	MBB_PROFILE_CLOSE = "关闭";
	MBB_PROFILE_HINT = "新配置档会以当前配置档的副本创建。";
	MBB_PROFILE_NEW_PROMPT = "请输入新配置档名称：";
	MBB_PROFILE_DELETE_PROMPT = "删除配置档 '%s'？";
	MBB_PROFILE_APPLIED = "MBB：已启用配置档 '%s'。";
	MBB_PROFILE_CREATED = "MBB：已创建配置档 '%s'。";
	MBB_PROFILE_DELETED = "MBB：已删除配置档 '%s'。";
	MBB_PROFILE_EXISTS = "MBB：名为 '%s' 的配置档已存在。";
	MBB_PROFILE_INVALID = "MBB：请输入 1 到 32 个字符的配置档名称。";
	MBB_PROFILE_DELETE_DEFAULT = "MBB：默认配置档不能删除。";
	MBB_PROFILE_COMBAT = "MBB：战斗中无法切换配置档。";
	MBB_PROFILE_RENAME = "重命名";
	MBB_PROFILE_DUPLICATE = "复制";
	MBB_PROFILE_RENAME_PROMPT = "请输入配置方案“%s”的新名称：";
	MBB_PROFILE_DUPLICATE_PROMPT = "请输入配置方案“%s”副本的名称：";
	MBB_PROFILE_COPY_SUFFIX = "副本";
	MBB_PROFILE_RENAMED = "MBB：配置方案“%s”已重命名为“%s”。";
	MBB_PROFILE_DUPLICATED = "MBB：配置方案“%s”已复制为“%s”。";
	MBB_PROFILE_RENAME_DEFAULT = "MBB：默认配置方案不能重命名。";
	MBB_HELP_PROFILE = "  |c00ffffffprofiles|r：打开配置档管理器";

end
