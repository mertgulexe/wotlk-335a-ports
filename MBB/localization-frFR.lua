if( GetLocale() == "frFR" ) then
	MBB_TOOLTIP1 = "Ctrl + Clic droit sur un bouton pour le rattacher a la minimap.";
	MBB_OPTIONS_HEADER = "Options";
	MBB_OPTIONS_OKBUTTON = "Ok";
	MBB_OPTIONS_CANCELBUTTON = "Annuler";
	MBB_OPTIONS_SLIDEROFF = "Off";
	MBB_OPTIONS_SLIDERSEK = "sec";
	MBB_OPTIONS_SLIDERLABEL = "Temps de reduc.:";
	MBB_OPTIONS_EXPANSIONLABEL = "Etendre a:";
	MBB_OPTIONS_EXPANSIONLEFT = "Gauche";
	MBB_OPTIONS_EXPANSIONTOP = "Haut";
	MBB_OPTIONS_EXPANSIONRIGHT = "Droite";
	MBB_OPTIONS_EXPANSIONBOTTOM = "Bas";
	MBB_OPTIONS_MAXBUTTONSLABEL = "Max Boutons/Ligne:";
	MBB_OPTIONS_MAXBUTTONSINFO = "(0=infini)";
	MBB_OPTIONS_ALTEXPANSIONLABEL = "Ligne suivante :";
	MBB_OPTIONS_BUTTONSCALE = "Taille des boutons :";
	MBB_HELP1 = "Type \"/mmbb <cmd>\" ou <cmd> est l'un des suivants:";
	MBB_HELP2 = "  |c00ffffffbuttons|r: Affiche la liste de tous les boutons de la barre MBB";
	MBB_HELP3 = "  |c00ffffffreset position|r: Reinitialiser la position du bouton MBB";
	MBB_HELP4 = "  |c00ffffffreset all|r: Reinitialiser toutes les options";
	MBB_NOERRORS = "Aucune erreur trouvée !";

	MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn chargé."
	MBB_FIRST_RUN_COUNT = "%d boutons de minicarte collectés."
	MBB_FIRST_RUN_HELP = "Tapez /mbb pour voir les commandes disponibles."
	MBB_FIRST_RUN_RESCAN = "Utilisez /mbb rescan si des boutons sont manquants."

	MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
	MBB_ABOUT_VERSION = "Version :";
	MBB_ABOUT_BASED_ON = "(basé sur 4.0.26)";
	MBB_ABOUT_CREDITS_TITLE = "Crédits :";

	MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – État du patch";
	MBB_PATCH_ADDON_INTERFACE = "Version d’interface de l’addon :";
	MBB_PATCH_WOW_INTERFACE = "Version actuelle de l’interface WoW :";
	MBB_PATCH_OK = "État : l’addon est à jour pour ce patch de WoW.";
	MBB_PATCH_OLD = "État : cet addon a été conçu pour un ancien patch de WoW. Veuillez vérifier les mises à jour.";

	MBB_HELP_ABOUT = "  |c00ffffffabout|r: Affiche les informations de l’addon (version et crédits)";
	MBB_HELP_PATCH = "  |c00ffffffpatch|r: Affiche l’état de compatibilité avec le patch";
	MBB_HELP_RESCAN = "  |c00ffffffrescan|r: Recherche à nouveau les boutons manquants sur la minicarte";
	MBB_RESCAN_DONE = "MBB : nouvelle analyse terminée. %d nouveau(x) bouton(s) de minicarte trouvé(s).";

	MBB_OPTIONS_DETACH = "Détacher de la minicarte";
	MBB_OPTIONS_DETACH_DESC = "Permet de déplacer librement le bouton MBB à l’écran.";
	MBB_OPTIONS_DETACH_COMBAT = "Ne peut pas être modifié pendant le combat.";


	-- Version update notification
	MBB_UPDATE_AVAILABLE = "MBB : Une nouvelle version est disponible : %s (vous utilisez %s). Veuillez mettre à jour via CurseForge.";

	-- MBB Reborn 2.0 - Button Manager
	MBB_MANAGER_BUTTON = "Gestion des boutons...";
	MBB_MANAGER_TITLE = "Gestion des boutons";
	MBB_MANAGER_DESC = "Gérez les boutons de mini-carte connus. Les boutons cochés sont regroupés dans MBB.";
	MBB_MANAGER_ENABLED = "Dans MBB";
	MBB_MANAGER_DISABLED = "Sur la mini-carte";
	MBB_MANAGER_MISSING = "Non chargé";
	MBB_MANAGER_RESCAN = "Réanalyser";
	MBB_MANAGER_CLOSE = "Fermer";
	MBB_MANAGER_COUNT = "%d boutons connus";
	MBB_MANAGER_EMPTY = "Aucun bouton détecté. Utilisez Réanalyser.";
	MBB_MANAGER_COMBAT = "La gestion des boutons est désactivée en combat.";
	MBB_MANAGER_COLUMN_BUTTON = "Bouton";
	MBB_MANAGER_COLUMN_STATUS = "État";
	MBB_MANAGER_TOOLTIP_INCLUDED = "Coché : ce bouton est regroupé dans MBB.";
	MBB_MANAGER_TOOLTIP_EXCLUDED = "Décoché : ce bouton reste sur la mini-carte.";
	MBB_HELP_MANAGER = "  |c00ffffffmanager|r : ouvre la gestion des boutons de mini-carte";

	-- MBB Reborn 2.0 - Button ordering
	MBB_MANAGER_ORDER_HELP = "Faites glisser une ligne ou utilisez les flèches pour modifier l’ordre des boutons.";
	MBB_MANAGER_MOVE_UP = "Monter";
	MBB_MANAGER_MOVE_DOWN = "Descendre";
	MBB_MANAGER_RESET_ORDER = "Réinitialiser l’ordre";
	MBB_MANAGER_RESET_ORDER_DONE = "MBB : ordre des boutons réinitialisé.";
	MBB_MANAGER_DRAG_HINT = "Faites glisser cette ligne pour modifier sa position.";


-- MBB Reborn 2.0 - Positioning
	MBB_OPTIONS_LOCK_POSITION = "Verrouiller la position";
	MBB_OPTIONS_LOCK_POSITION_DESC = "Empêche de déplacer accidentellement le bouton MBB détaché.";
	MBB_OPTIONS_SNAP_EDGES = "Aligner sur les bords de la fenêtre WoW";
	MBB_OPTIONS_SNAP_EDGES_DESC = "Aligne le bouton MBB détaché sur les bords proches de la fenêtre WoW. Remarque : les addons WoW ne peuvent pas détecter la limite physique entre plusieurs écrans.";


-- MBB Reborn 2.0 - Profiles
	MBB_PROFILE_BUTTON = "Profils";
	MBB_PROFILE_TITLE = "Profils";
	MBB_PROFILE_DESC = "Les profils enregistrent la disposition, l’échelle, la position et l’ordre des boutons. Les exclusions restent propres à chaque personnage.";
	MBB_PROFILE_CURRENT = "Profil actuel :";
	MBB_PROFILE_ACTIVE = "Actif";
	MBB_PROFILE_DEFAULT_DISPLAY = "Par défaut";
	MBB_PROFILE_ACTIVATE = "Activer";
	MBB_PROFILE_NEW = "Nouveau";
	MBB_PROFILE_DELETE = "Supprimer";
	MBB_PROFILE_CLOSE = "Fermer";
	MBB_PROFILE_HINT = "Les nouveaux profils commencent comme une copie du profil actuel.";
	MBB_PROFILE_NEW_PROMPT = "Entrez un nom pour le nouveau profil :";
	MBB_PROFILE_DELETE_PROMPT = "Supprimer le profil '%s' ?";
	MBB_PROFILE_APPLIED = "MBB : profil '%s' activé.";
	MBB_PROFILE_CREATED = "MBB : profil '%s' créé.";
	MBB_PROFILE_DELETED = "MBB : profil '%s' supprimé.";
	MBB_PROFILE_EXISTS = "MBB : un profil nommé '%s' existe déjà.";
	MBB_PROFILE_INVALID = "MBB : saisissez un nom de profil de 1 à 32 caractères.";
	MBB_PROFILE_DELETE_DEFAULT = "MBB : le profil par défaut ne peut pas être supprimé.";
	MBB_PROFILE_COMBAT = "MBB : les profils ne peuvent pas être changés en combat.";
	MBB_PROFILE_RENAME = "Renommer";
	MBB_PROFILE_DUPLICATE = "Dupliquer";
	MBB_PROFILE_RENAME_PROMPT = "Entrez un nouveau nom pour le profil « %s » :";
	MBB_PROFILE_DUPLICATE_PROMPT = "Entrez un nom pour la copie du profil « %s » :";
	MBB_PROFILE_COPY_SUFFIX = "Copie";
	MBB_PROFILE_RENAMED = "MBB : profil « %s » renommé en « %s ».";
	MBB_PROFILE_DUPLICATED = "MBB : profil « %s » dupliqué sous « %s ».";
	MBB_PROFILE_RENAME_DEFAULT = "MBB : le profil par défaut ne peut pas être renommé.";
	MBB_HELP_PROFILE = "  |c00ffffffprofiles|r : ouvre la gestion des profils";

end
