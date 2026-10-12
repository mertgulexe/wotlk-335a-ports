if( GetLocale() == "zhTW" ) then

MBB_TOOLTIP1 = "Ctrl + 右鍵選擇是否附著在小地圖";
MBB_OPTIONS_HEADER = "選項";
MBB_OPTIONS_OKBUTTON = "確定";
MBB_OPTIONS_CANCELBUTTON = "取消";
MBB_OPTIONS_SLIDEROFF = "無";
MBB_OPTIONS_SLIDERSEK = "秒";
MBB_OPTIONS_SLIDERLABEL = "消失時間:";
MBB_OPTIONS_EXPANSIONLABEL = "展開方向:";
MBB_OPTIONS_EXPANSIONLEFT = "左";
MBB_OPTIONS_EXPANSIONTOP = "上";
MBB_OPTIONS_EXPANSIONRIGHT = "右";
MBB_OPTIONS_EXPANSIONBOTTOM = "下";
MBB_OPTIONS_MAXBUTTONSLABEL = "每列最大圖示:";
MBB_OPTIONS_MAXBUTTONSINFO = "(0=無限制)";
MBB_OPTIONS_ALTEXPANSIONLABEL = "下一行方向：";
	MBB_OPTIONS_BUTTONSCALE = "按鈕大小：";
MBB_HELP1 = "語法：\"/mmbb <cmd>\" 其中 <cmd> 包含如下指令:";
MBB_HELP2 = "  |c00ffffffbuttons|r: 列出在 MBB 列的所有小地圖按鈕名稱";
MBB_HELP3 = "  |c00ffffffreset position|r: 重設 MBB 在小地圖的位置";
MBB_HELP4 = "  |c00ffffffreset all|r: 重設所有選項";
MBB_NOERRORS = "沒有發現錯誤!";


MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn 已載入。"
MBB_FIRST_RUN_COUNT = "已收集 %d 個小地圖按鈕。"
MBB_FIRST_RUN_HELP = "輸入 /mbb 查看可用指令。"
MBB_FIRST_RUN_RESCAN = "如果有按鈕遺漏，請使用 /mbb rescan。"

MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
MBB_ABOUT_VERSION = "版本：";
MBB_ABOUT_BASED_ON = "（基於 4.0.26）";
MBB_ABOUT_CREDITS_TITLE = "致謝：";

MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – 更新狀態";
MBB_PATCH_ADDON_INTERFACE = "插件介面版本：";
MBB_PATCH_WOW_INTERFACE = "目前 WoW 介面版本：";
MBB_PATCH_OK = "狀態：插件已支援目前的 WoW 更新版本。";
MBB_PATCH_OLD = "狀態：此插件是為較舊的 WoW 更新版本建立，請檢查是否有更新。";

MBB_HELP_ABOUT = "  |c00ffffffabout|r: 顯示插件資訊（版本與致謝）";
MBB_HELP_PATCH = "  |c00ffffffpatch|r: 顯示更新版本相容狀態";
MBB_HELP_RESCAN = "  |c00ffffffrescan|r: 重新掃描小地圖以尋找遺漏的按鈕";
MBB_RESCAN_DONE = "MBB：重新掃描完成。找到 %d 個新的小地圖按鈕。";

MBB_OPTIONS_DETACH = "從小地圖分離";
MBB_OPTIONS_DETACH_DESC = "允許在畫面上自由移動 MBB 按鈕。";
MBB_OPTIONS_DETACH_COMBAT = "戰鬥中無法變更。";


	-- Version update notification
	MBB_UPDATE_AVAILABLE = "MBB：有新版本可用：%s（目前使用 %s）。請透過 CurseForge 更新。";

	-- MBB Reborn 2.0 - Button Manager
	MBB_MANAGER_BUTTON = "按鈕管理...";
	MBB_MANAGER_TITLE = "按鈕管理";
	MBB_MANAGER_DESC = "管理已知的小地圖按鈕。勾選的按鈕會收納到 MBB 中。";
	MBB_MANAGER_ENABLED = "在 MBB 中";
	MBB_MANAGER_DISABLED = "在小地圖上";
	MBB_MANAGER_MISSING = "未載入";
	MBB_MANAGER_RESCAN = "重新掃描";
	MBB_MANAGER_CLOSE = "關閉";
	MBB_MANAGER_COUNT = "已知按鈕：%d";
	MBB_MANAGER_EMPTY = "尚未偵測到按鈕。請使用「重新掃描」。";
	MBB_MANAGER_COMBAT = "戰鬥中無法管理按鈕。";
	MBB_MANAGER_COLUMN_BUTTON = "按鈕";
	MBB_MANAGER_COLUMN_STATUS = "狀態";
	MBB_MANAGER_TOOLTIP_INCLUDED = "已勾選：此按鈕會收納到 MBB 中。";
	MBB_MANAGER_TOOLTIP_EXCLUDED = "未勾選：此按鈕會保留在小地圖上。";
	MBB_HELP_MANAGER = "  |c00ffffffmanager|r：開啟小地圖按鈕管理器";

	-- MBB Reborn 2.0 - Button ordering
	MBB_MANAGER_ORDER_HELP = "拖曳一列或使用箭頭來調整按鈕順序。";
	MBB_MANAGER_MOVE_UP = "上移";
	MBB_MANAGER_MOVE_DOWN = "下移";
	MBB_MANAGER_RESET_ORDER = "重設順序";
	MBB_MANAGER_RESET_ORDER_DONE = "MBB：按鈕順序已重設。";
	MBB_MANAGER_DRAG_HINT = "拖曳此列可變更其位置。";


-- MBB Reborn 2.0 - Positioning
	MBB_OPTIONS_LOCK_POSITION = "鎖定位置";
	MBB_OPTIONS_LOCK_POSITION_DESC = "防止意外移動已從小地圖分離的 MBB 按鈕。";
	MBB_OPTIONS_SNAP_EDGES = "吸附至 WoW 視窗邊緣";
	MBB_OPTIONS_SNAP_EDGES_DESC = "將分離的 MBB 按鈕吸附至附近的 WoW 視窗邊緣。注意：WoW 插件無法偵測多個螢幕之間的實體邊界。";


-- MBB Reborn 2.0 - Profiles
	MBB_PROFILE_BUTTON = "設定檔";
	MBB_PROFILE_TITLE = "設定檔";
	MBB_PROFILE_DESC = "設定檔會儲存版面、縮放、位置與按鈕順序。排除清單仍依角色分別儲存。";
	MBB_PROFILE_CURRENT = "目前設定檔：";
	MBB_PROFILE_ACTIVE = "使用中";
	MBB_PROFILE_DEFAULT_DISPLAY = "預設";
	MBB_PROFILE_ACTIVATE = "啟用";
	MBB_PROFILE_NEW = "新增";
	MBB_PROFILE_DELETE = "刪除";
	MBB_PROFILE_CLOSE = "關閉";
	MBB_PROFILE_HINT = "新設定檔會以目前設定檔的副本建立。";
	MBB_PROFILE_NEW_PROMPT = "請輸入新設定檔名稱：";
	MBB_PROFILE_DELETE_PROMPT = "刪除設定檔 '%s'？";
	MBB_PROFILE_APPLIED = "MBB：已啟用設定檔 '%s'。";
	MBB_PROFILE_CREATED = "MBB：已建立設定檔 '%s'。";
	MBB_PROFILE_DELETED = "MBB：已刪除設定檔 '%s'。";
	MBB_PROFILE_EXISTS = "MBB：名為 '%s' 的設定檔已存在。";
	MBB_PROFILE_INVALID = "MBB：請輸入 1 到 32 個字元的設定檔名稱。";
	MBB_PROFILE_DELETE_DEFAULT = "MBB：預設設定檔無法刪除。";
	MBB_PROFILE_COMBAT = "MBB：戰鬥中無法切換設定檔。";
	MBB_PROFILE_RENAME = "重新命名";
	MBB_PROFILE_DUPLICATE = "複製";
	MBB_PROFILE_RENAME_PROMPT = "請輸入設定檔「%s」的新名稱：";
	MBB_PROFILE_DUPLICATE_PROMPT = "請輸入設定檔「%s」副本的名稱：";
	MBB_PROFILE_COPY_SUFFIX = "副本";
	MBB_PROFILE_RENAMED = "MBB：設定檔「%s」已重新命名為「%s」。";
	MBB_PROFILE_DUPLICATED = "MBB：設定檔「%s」已複製為「%s」。";
	MBB_PROFILE_RENAME_DEFAULT = "MBB：預設設定檔無法重新命名。";
	MBB_HELP_PROFILE = "  |c00ffffffprofiles|r：開啟設定檔管理器";

end
