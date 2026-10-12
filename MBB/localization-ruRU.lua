if( GetLocale() == "ruRU" ) then

MBB_TOOLTIP1 = "[Ctrl + ПКМ] - сменить позиции на миникарте.";
MBB_OPTIONS_HEADER = "Опции";
MBB_OPTIONS_OKBUTTON = "Да";
MBB_OPTIONS_CANCELBUTTON = "Отмена";
MBB_OPTIONS_SLIDEROFF = "Откл";
MBB_OPTIONS_SLIDERSEK = "сек";
MBB_OPTIONS_SLIDERLABEL = "Время сворачивания:";
MBB_OPTIONS_EXPANSIONLABEL = "Расширить:";
MBB_OPTIONS_EXPANSIONLEFT = "Влево";
MBB_OPTIONS_EXPANSIONTOP = "Вверх";
MBB_OPTIONS_EXPANSIONRIGHT = "Вправо";
MBB_OPTIONS_EXPANSIONBOTTOM = "Вниз";
MBB_OPTIONS_MAXBUTTONSLABEL = "Макс. кнопки/строка:";
MBB_OPTIONS_MAXBUTTONSINFO = "(0=бесконечность)";
MBB_OPTIONS_ALTEXPANSIONLABEL = "Следующая строка:";
	MBB_OPTIONS_BUTTONSCALE = "Размер кнопок:";
MBB_HELP1 = "Введите \"/mmbb <cmd>\" где <cmd> одна из команд:";
MBB_HELP2 = "  |c00ffffffbuttons|r: Показать список всех фреймов для MBB бара";
MBB_HELP3 = "  |c00ffffffreset position|r: сбросить позицию MBB кнопки у миникарты";
MBB_HELP4 = "  |c00ffffffreset all|r: сбросить все опции";
MBB_NOERRORS = "Ошибок не найдено!";


MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn загружен."
MBB_FIRST_RUN_COUNT = "Собрано кнопок миникарты: %d."
MBB_FIRST_RUN_HELP = "Введите /mbb, чтобы увидеть доступные команды."
MBB_FIRST_RUN_RESCAN = "Используйте /mbb rescan, если некоторые кнопки отсутствуют."

MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
MBB_ABOUT_VERSION = "Версия:";
MBB_ABOUT_BASED_ON = "(на основе 4.0.26)";
MBB_ABOUT_CREDITS_TITLE = "Авторы:";

MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – Статус патча";
MBB_PATCH_ADDON_INTERFACE = "Версия интерфейса аддона:";
MBB_PATCH_WOW_INTERFACE = "Текущая версия интерфейса WoW:";
MBB_PATCH_OK = "Статус: аддон актуален для этого патча WoW.";
MBB_PATCH_OLD = "Статус: этот аддон создан для более старого патча WoW. Проверьте наличие обновлений.";

MBB_HELP_ABOUT = "  |c00ffffffabout|r: Показать информацию об аддоне (версия и авторы)";
MBB_HELP_PATCH = "  |c00ffffffpatch|r: Показать статус совместимости с патчем";
MBB_HELP_RESCAN = "  |c00ffffffrescan|r: Повторно найти отсутствующие кнопки миникарты";
MBB_RESCAN_DONE = "MBB: повторное сканирование завершено. Найдено новых кнопок миникарты: %d.";

MBB_OPTIONS_DETACH = "Отсоединить от миникарты";
MBB_OPTIONS_DETACH_DESC = "Позволяет свободно перемещать кнопку MBB по экрану.";
MBB_OPTIONS_DETACH_COMBAT = "Нельзя изменить во время боя.";


	-- Version update notification
	MBB_UPDATE_AVAILABLE = "MBB: Доступна новая версия: %s (у вас %s). Обновите аддон через CurseForge.";

	-- MBB Reborn 2.0 - Button Manager
	MBB_MANAGER_BUTTON = "Управление кнопками...";
	MBB_MANAGER_TITLE = "Управление кнопками";
	MBB_MANAGER_DESC = "Управление известными кнопками миникарты. Отмеченные кнопки собираются в MBB.";
	MBB_MANAGER_ENABLED = "В MBB";
	MBB_MANAGER_DISABLED = "На миникарте";
	MBB_MANAGER_MISSING = "Не загружено";
	MBB_MANAGER_RESCAN = "Пересканировать";
	MBB_MANAGER_CLOSE = "Закрыть";
	MBB_MANAGER_COUNT = "Известных кнопок: %d";
	MBB_MANAGER_EMPTY = "Кнопки пока не обнаружены. Используйте пересканирование.";
	MBB_MANAGER_COMBAT = "Управление кнопками недоступно во время боя.";
	MBB_MANAGER_COLUMN_BUTTON = "Кнопка";
	MBB_MANAGER_COLUMN_STATUS = "Состояние";
	MBB_MANAGER_TOOLTIP_INCLUDED = "Отмечено: кнопка собрана внутри MBB.";
	MBB_MANAGER_TOOLTIP_EXCLUDED = "Не отмечено: кнопка остаётся на миникарте.";
	MBB_HELP_MANAGER = "  |c00ffffffmanager|r: открывает управление кнопками миникарты";

	-- MBB Reborn 2.0 - Button ordering
	MBB_MANAGER_ORDER_HELP = "Перетащите строку или используйте стрелки, чтобы изменить порядок кнопок.";
	MBB_MANAGER_MOVE_UP = "Переместить вверх";
	MBB_MANAGER_MOVE_DOWN = "Переместить вниз";
	MBB_MANAGER_RESET_ORDER = "Сбросить порядок";
	MBB_MANAGER_RESET_ORDER_DONE = "MBB: порядок кнопок сброшен.";
	MBB_MANAGER_DRAG_HINT = "Перетащите эту строку, чтобы изменить её позицию.";


-- MBB Reborn 2.0 - Positioning
	MBB_OPTIONS_LOCK_POSITION = "Закрепить позицию";
	MBB_OPTIONS_LOCK_POSITION_DESC = "Не позволяет случайно переместить откреплённую кнопку MBB.";
	MBB_OPTIONS_SNAP_EDGES = "Привязка к краям окна WoW";
	MBB_OPTIONS_SNAP_EDGES_DESC = "Привязывает откреплённую кнопку MBB к ближайшим краям окна WoW. Примечание: аддоны WoW не могут определить физическую границу между несколькими мониторами.";


-- MBB Reborn 2.0 - Profiles
	MBB_PROFILE_BUTTON = "Профили";
	MBB_PROFILE_TITLE = "Профили";
	MBB_PROFILE_DESC = "Профили сохраняют раскладку, масштаб, позицию и порядок кнопок. Исключения остаются отдельными для каждого персонажа.";
	MBB_PROFILE_CURRENT = "Текущий профиль:";
	MBB_PROFILE_ACTIVE = "Активен";
	MBB_PROFILE_DEFAULT_DISPLAY = "По умолчанию";
	MBB_PROFILE_ACTIVATE = "Активировать";
	MBB_PROFILE_NEW = "Новый";
	MBB_PROFILE_DELETE = "Удалить";
	MBB_PROFILE_CLOSE = "Закрыть";
	MBB_PROFILE_HINT = "Новые профили создаются как копия текущего профиля.";
	MBB_PROFILE_NEW_PROMPT = "Введите имя нового профиля:";
	MBB_PROFILE_DELETE_PROMPT = "Удалить профиль '%s'?";
	MBB_PROFILE_APPLIED = "MBB: профиль '%s' активирован.";
	MBB_PROFILE_CREATED = "MBB: профиль '%s' создан.";
	MBB_PROFILE_DELETED = "MBB: профиль '%s' удалён.";
	MBB_PROFILE_EXISTS = "MBB: профиль с именем '%s' уже существует.";
	MBB_PROFILE_INVALID = "MBB: введите имя профиля длиной от 1 до 32 символов.";
	MBB_PROFILE_DELETE_DEFAULT = "MBB: профиль по умолчанию нельзя удалить.";
	MBB_PROFILE_COMBAT = "MBB: профили нельзя менять в бою.";
	MBB_PROFILE_RENAME = "Переименовать";
	MBB_PROFILE_DUPLICATE = "Дублировать";
	MBB_PROFILE_RENAME_PROMPT = "Введите новое имя для профиля «%s»:";
	MBB_PROFILE_DUPLICATE_PROMPT = "Введите имя для копии профиля «%s»:";
	MBB_PROFILE_COPY_SUFFIX = "Копия";
	MBB_PROFILE_RENAMED = "MBB: профиль «%s» переименован в «%s».";
	MBB_PROFILE_DUPLICATED = "MBB: профиль «%s» скопирован как «%s».";
	MBB_PROFILE_RENAME_DEFAULT = "MBB: профиль по умолчанию нельзя переименовать.";
	MBB_HELP_PROFILE = "  |c00ffffffprofiles|r: открывает управление профилями";

end
