if( GetLocale() == "koKR" ) then

MBB_TOOLTIP1 = "Ctrl + 우클릭시 미니맵에서 분리하거나 묶을수 있습니다.";
MBB_OPTIONS_HEADER = "옵션";
MBB_OPTIONS_OKBUTTON = "확인";
MBB_OPTIONS_CANCELBUTTON = "취소";
MBB_OPTIONS_SLIDEROFF = "끔";
MBB_OPTIONS_SLIDERSEK = "초";
MBB_OPTIONS_SLIDERLABEL = "버튼 사라짐 시간:";
MBB_OPTIONS_EXPANSIONLABEL = "확장 방향:";
MBB_OPTIONS_EXPANSIONLEFT = "좌측";
MBB_OPTIONS_EXPANSIONTOP = "상단";
MBB_OPTIONS_EXPANSIONRIGHT = "우측";
MBB_OPTIONS_EXPANSIONBOTTOM = "하단";
MBB_OPTIONS_MAXBUTTONSLABEL = "최대 버튼/줄:";
MBB_OPTIONS_MAXBUTTONSINFO = "(0=무한)";
MBB_OPTIONS_ALTEXPANSIONLABEL = "다음 줄 방향:";
	MBB_OPTIONS_BUTTONSCALE = "버튼 크기:";
MBB_HELP1 = "\"/mmbb <cmd>\" 입력을 합니다. <cmd>명령어는 다음과 같습니다:";
MBB_HELP2 = "  |c00ffffffbuttons|r: 모든 MBB 버튼바 프레임 리스트로 보여줍니다.";
MBB_HELP3 = "  |c00ffffffreset position|r: MBB 미니맵 위치를 초기화 합니다.";
MBB_HELP4 = "  |c00ffffffreset all|r: 모두 기본설정으로 되돌립니다.";
MBB_NOERRORS = "오류를 찾을수 없습니다!";


MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn을 불러왔습니다."
MBB_FIRST_RUN_COUNT = "미니맵 버튼 %d개를 수집했습니다."
MBB_FIRST_RUN_HELP = "사용 가능한 명령어를 보려면 /mbb를 입력하세요."
MBB_FIRST_RUN_RESCAN = "버튼이 누락된 경우 /mbb rescan을 사용하세요."

MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
MBB_ABOUT_VERSION = "버전:";
MBB_ABOUT_BASED_ON = "(4.0.26 기반)";
MBB_ABOUT_CREDITS_TITLE = "제작진:";

MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – 패치 상태";
MBB_PATCH_ADDON_INTERFACE = "애드온 인터페이스 버전:";
MBB_PATCH_WOW_INTERFACE = "현재 WoW 인터페이스 버전:";
MBB_PATCH_OK = "상태: 이 WoW 패치에 맞는 최신 애드온입니다.";
MBB_PATCH_OLD = "상태: 이 애드온은 이전 WoW 패치용입니다. 업데이트를 확인하세요.";

MBB_HELP_ABOUT = "  |c00ffffffabout|r: 애드온 정보(버전 및 제작진)를 표시합니다";
MBB_HELP_PATCH = "  |c00ffffffpatch|r: 패치 호환성 상태를 표시합니다";
MBB_HELP_RESCAN = "  |c00ffffffrescan|r: 누락된 미니맵 버튼을 다시 검색합니다";
MBB_RESCAN_DONE = "MBB: 재검색 완료. 새로운 미니맵 버튼 %d개를 찾았습니다.";

MBB_OPTIONS_DETACH = "미니맵에서 분리";
MBB_OPTIONS_DETACH_DESC = "MBB 버튼을 화면에서 자유롭게 이동할 수 있습니다.";
MBB_OPTIONS_DETACH_COMBAT = "전투 중에는 변경할 수 없습니다.";


	-- Version update notification
	MBB_UPDATE_AVAILABLE = "MBB: 새 버전을 사용할 수 있습니다: %s (현재 사용 중: %s). CurseForge에서 업데이트하세요.";

	-- MBB Reborn 2.0 - Button Manager
	MBB_MANAGER_BUTTON = "버튼 관리...";
	MBB_MANAGER_TITLE = "버튼 관리";
	MBB_MANAGER_DESC = "알려진 미니맵 버튼을 관리합니다. 체크된 버튼은 MBB에 모입니다.";
	MBB_MANAGER_ENABLED = "MBB 안";
	MBB_MANAGER_DISABLED = "미니맵";
	MBB_MANAGER_MISSING = "로드되지 않음";
	MBB_MANAGER_RESCAN = "다시 검색";
	MBB_MANAGER_CLOSE = "닫기";
	MBB_MANAGER_COUNT = "알려진 버튼 %d개";
	MBB_MANAGER_EMPTY = "아직 감지된 버튼이 없습니다. 다시 검색을 사용하세요.";
	MBB_MANAGER_COMBAT = "전투 중에는 버튼 관리를 사용할 수 없습니다.";
	MBB_MANAGER_COLUMN_BUTTON = "버튼";
	MBB_MANAGER_COLUMN_STATUS = "상태";
	MBB_MANAGER_TOOLTIP_INCLUDED = "체크됨: 이 버튼은 MBB 안에 모입니다.";
	MBB_MANAGER_TOOLTIP_EXCLUDED = "체크 해제됨: 이 버튼은 미니맵에 남습니다.";
	MBB_HELP_MANAGER = "  |c00ffffffmanager|r: 미니맵 버튼 관리 창을 엽니다";

	-- MBB Reborn 2.0 - Button ordering
	MBB_MANAGER_ORDER_HELP = "행을 드래그하거나 화살표를 사용하여 버튼 순서를 변경하세요.";
	MBB_MANAGER_MOVE_UP = "위로 이동";
	MBB_MANAGER_MOVE_DOWN = "아래로 이동";
	MBB_MANAGER_RESET_ORDER = "순서 초기화";
	MBB_MANAGER_RESET_ORDER_DONE = "MBB: 버튼 순서를 초기화했습니다.";
	MBB_MANAGER_DRAG_HINT = "이 행을 드래그하여 위치를 변경하세요.";


-- MBB Reborn 2.0 - Positioning
	MBB_OPTIONS_LOCK_POSITION = "위치 잠금";
	MBB_OPTIONS_LOCK_POSITION_DESC = "분리된 MBB 버튼이 실수로 이동하지 않도록 합니다.";
	MBB_OPTIONS_SNAP_EDGES = "WoW 창 가장자리에 맞추기";
	MBB_OPTIONS_SNAP_EDGES_DESC = "분리된 MBB 버튼을 가까운 WoW 창 가장자리에 맞춥니다. 참고: WoW 애드온은 여러 모니터 사이의 물리적 경계를 감지할 수 없습니다.";


-- MBB Reborn 2.0 - Profiles
	MBB_PROFILE_BUTTON = "프로필";
	MBB_PROFILE_TITLE = "프로필";
	MBB_PROFILE_DESC = "프로필은 배치, 크기, 위치 및 버튼 순서를 저장합니다. 제외 버튼 목록은 캐릭터별로 유지됩니다.";
	MBB_PROFILE_CURRENT = "현재 프로필:";
	MBB_PROFILE_ACTIVE = "활성";
	MBB_PROFILE_DEFAULT_DISPLAY = "기본";
	MBB_PROFILE_ACTIVATE = "활성화";
	MBB_PROFILE_NEW = "새로 만들기";
	MBB_PROFILE_DELETE = "삭제";
	MBB_PROFILE_CLOSE = "닫기";
	MBB_PROFILE_HINT = "새 프로필은 현재 프로필의 복사본으로 시작합니다.";
	MBB_PROFILE_NEW_PROMPT = "새 프로필 이름을 입력하세요:";
	MBB_PROFILE_DELETE_PROMPT = "프로필 '%s'을(를) 삭제할까요?";
	MBB_PROFILE_APPLIED = "MBB: 프로필 '%s'이(가) 활성화되었습니다.";
	MBB_PROFILE_CREATED = "MBB: 프로필 '%s'이(가) 생성되었습니다.";
	MBB_PROFILE_DELETED = "MBB: 프로필 '%s'이(가) 삭제되었습니다.";
	MBB_PROFILE_EXISTS = "MBB: '%s' 이름의 프로필이 이미 있습니다.";
	MBB_PROFILE_INVALID = "MBB: 1~32자의 프로필 이름을 입력하세요.";
	MBB_PROFILE_DELETE_DEFAULT = "MBB: 기본 프로필은 삭제할 수 없습니다.";
	MBB_PROFILE_COMBAT = "MBB: 전투 중에는 프로필을 변경할 수 없습니다.";
	MBB_PROFILE_RENAME = "이름 변경";
	MBB_PROFILE_DUPLICATE = "복제";
	MBB_PROFILE_RENAME_PROMPT = "프로필 '%s'의 새 이름을 입력하세요:";
	MBB_PROFILE_DUPLICATE_PROMPT = "프로필 '%s' 복사본의 이름을 입력하세요:";
	MBB_PROFILE_COPY_SUFFIX = "복사본";
	MBB_PROFILE_RENAMED = "MBB: 프로필 '%s'의 이름을 '%s'(으)로 변경했습니다.";
	MBB_PROFILE_DUPLICATED = "MBB: 프로필 '%s'을(를) '%s'(으)로 복제했습니다.";
	MBB_PROFILE_RENAME_DEFAULT = "MBB: 기본 프로필의 이름은 변경할 수 없습니다.";
	MBB_HELP_PROFILE = "  |c00ffffffprofiles|r: 프로필 관리 창을 엽니다";

end
