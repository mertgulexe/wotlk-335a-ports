if( GetLocale() == "itIT" ) then

	MBB_TOOLTIP1 = "Ctrl + Click Destro su un pulsante per riposizionarlo sulla minimappa.";
	MBB_OPTIONS_HEADER = "Opzioni";
	MBB_OPTIONS_OKBUTTON = "Ok";
	MBB_OPTIONS_CANCELBUTTON = "Cancella";
	MBB_OPTIONS_SLIDEROFF = "Off";
	MBB_OPTIONS_SLIDERSEK = "sec";
	MBB_OPTIONS_SLIDERLABEL = "Durata comparsa:";
	MBB_OPTIONS_EXPANSIONLABEL = "Espandi:";
	MBB_OPTIONS_EXPANSIONLEFT = "Sinistra";
	MBB_OPTIONS_EXPANSIONTOP = "Sopra";
	MBB_OPTIONS_EXPANSIONRIGHT = "Destra";
	MBB_OPTIONS_EXPANSIONBOTTOM = "Sotto";
	MBB_OPTIONS_MAXBUTTONSLABEL = "Num. Max. di Pulsanti/Riga:";
	MBB_OPTIONS_MAXBUTTONSINFO = "(0=infinito)";
	MBB_OPTIONS_ALTEXPANSIONLABEL = "Riga successiva:";
	MBB_OPTIONS_BUTTONSCALE = "Dimensione pulsanti:";
	MBB_HELP1 = "Scrivi \"/mmbb <cmd>\" dove <cmd> è uno dei seguenti:";
	MBB_HELP2 = "  |c00ffffffbuttons|r: Mostra una lista di tutti i frames nella barra di MBB";
	MBB_HELP3 = "  |c00ffffffreset position|r: Reimposta la posizione di MBB sulla minimappa";
	MBB_HELP4 = "  |c00ffffffreset all|r: Reimposta tutte le opzioni";
	MBB_NOERRORS = "Nessun errore trovato!";


	MBB_FIRST_RUN_TITLE = "MinimapButtonBag Reborn caricato."
	MBB_FIRST_RUN_COUNT = "Raccolti %d pulsanti della minimappa."
	MBB_FIRST_RUN_HELP = "Digita /mbb per vedere i comandi disponibili."
	MBB_FIRST_RUN_RESCAN = "Usa /mbb rescan se mancano dei pulsanti."

	MBB_ABOUT_TITLE = "MinimapButtonBag Reborn";
	MBB_ABOUT_VERSION = "Versione:";
	MBB_ABOUT_BASED_ON = "(basato su 4.0.26)";
	MBB_ABOUT_CREDITS_TITLE = "Crediti:";

	MBB_PATCH_STATUS_TITLE = "MinimapButtonBag Reborn – Stato patch";
	MBB_PATCH_ADDON_INTERFACE = "Versione interfaccia addon:";
	MBB_PATCH_WOW_INTERFACE = "Versione attuale interfaccia WoW:";
	MBB_PATCH_OK = "Stato: l’addon è aggiornato per questa patch di WoW.";
	MBB_PATCH_OLD = "Stato: questo addon è stato creato per una patch precedente di WoW. Controlla gli aggiornamenti.";

	MBB_HELP_ABOUT = "  |c00ffffffabout|r: Mostra informazioni sull’addon (versione e crediti)";
	MBB_HELP_PATCH = "  |c00ffffffpatch|r: Mostra lo stato di compatibilità con la patch";
	MBB_HELP_RESCAN = "  |c00ffffffrescan|r: Esegue una nuova scansione della minimappa per i pulsanti mancanti";
	MBB_RESCAN_DONE = "MBB: scansione completata. Trovati %d nuovi pulsanti della minimappa.";

	MBB_OPTIONS_DETACH = "Scollega dalla minimappa";
	MBB_OPTIONS_DETACH_DESC = "Consente di spostare liberamente il pulsante MBB sullo schermo.";
	MBB_OPTIONS_DETACH_COMBAT = "Non può essere modificato durante il combattimento.";


	-- Version update notification
	MBB_UPDATE_AVAILABLE = "MBB: È disponibile una versione più recente: %s (stai usando %s). Aggiorna tramite CurseForge.";

	-- MBB Reborn 2.0 - Button Manager
	MBB_MANAGER_BUTTON = "Gestione pulsanti...";
	MBB_MANAGER_TITLE = "Gestione pulsanti";
	MBB_MANAGER_DESC = "Gestisci i pulsanti minimappa conosciuti. I pulsanti selezionati vengono raccolti in MBB.";
	MBB_MANAGER_ENABLED = "In MBB";
	MBB_MANAGER_DISABLED = "Sulla minimappa";
	MBB_MANAGER_MISSING = "Non caricato";
	MBB_MANAGER_RESCAN = "Riscansiona";
	MBB_MANAGER_CLOSE = "Chiudi";
	MBB_MANAGER_COUNT = "%d pulsanti conosciuti";
	MBB_MANAGER_EMPTY = "Nessun pulsante rilevato. Usa Riscansiona.";
	MBB_MANAGER_COMBAT = "La gestione dei pulsanti è disattivata durante il combattimento.";
	MBB_MANAGER_COLUMN_BUTTON = "Pulsante";
	MBB_MANAGER_COLUMN_STATUS = "Stato";
	MBB_MANAGER_TOOLTIP_INCLUDED = "Selezionato: questo pulsante viene raccolto in MBB.";
	MBB_MANAGER_TOOLTIP_EXCLUDED = "Non selezionato: questo pulsante resta sulla minimappa.";
	MBB_HELP_MANAGER = "  |c00ffffffmanager|r: apre la gestione dei pulsanti minimappa";

	-- MBB Reborn 2.0 - Button ordering
	MBB_MANAGER_ORDER_HELP = "Trascina una riga o usa le frecce per cambiare l’ordine dei pulsanti.";
	MBB_MANAGER_MOVE_UP = "Sposta su";
	MBB_MANAGER_MOVE_DOWN = "Sposta giù";
	MBB_MANAGER_RESET_ORDER = "Reimposta ordine";
	MBB_MANAGER_RESET_ORDER_DONE = "MBB: ordine dei pulsanti reimpostato.";
	MBB_MANAGER_DRAG_HINT = "Trascina questa riga per cambiarne la posizione.";


-- MBB Reborn 2.0 - Positioning
	MBB_OPTIONS_LOCK_POSITION = "Blocca posizione";
	MBB_OPTIONS_LOCK_POSITION_DESC = "Impedisce di spostare accidentalmente il pulsante MBB sganciato.";
	MBB_OPTIONS_SNAP_EDGES = "Aggancia ai bordi della finestra WoW";
	MBB_OPTIONS_SNAP_EDGES_DESC = "Aggancia il pulsante MBB sganciato ai bordi vicini della finestra WoW. Nota: gli addon di WoW non possono rilevare il confine fisico tra più monitor.";


-- MBB Reborn 2.0 - Profiles
	MBB_PROFILE_BUTTON = "Profili";
	MBB_PROFILE_TITLE = "Profili";
	MBB_PROFILE_DESC = "I profili salvano layout, scala, posizione e ordine dei pulsanti. Le esclusioni restano specifiche del personaggio.";
	MBB_PROFILE_CURRENT = "Profilo attuale:";
	MBB_PROFILE_ACTIVE = "Attivo";
	MBB_PROFILE_DEFAULT_DISPLAY = "Predefinito";
	MBB_PROFILE_ACTIVATE = "Attiva";
	MBB_PROFILE_NEW = "Nuovo";
	MBB_PROFILE_DELETE = "Elimina";
	MBB_PROFILE_CLOSE = "Chiudi";
	MBB_PROFILE_HINT = "I nuovi profili iniziano come copia del profilo attuale.";
	MBB_PROFILE_NEW_PROMPT = "Inserisci un nome per il nuovo profilo:";
	MBB_PROFILE_DELETE_PROMPT = "Eliminare il profilo '%s'?";
	MBB_PROFILE_APPLIED = "MBB: profilo '%s' attivato.";
	MBB_PROFILE_CREATED = "MBB: profilo '%s' creato.";
	MBB_PROFILE_DELETED = "MBB: profilo '%s' eliminato.";
	MBB_PROFILE_EXISTS = "MBB: esiste già un profilo chiamato '%s'.";
	MBB_PROFILE_INVALID = "MBB: inserisci un nome profilo da 1 a 32 caratteri.";
	MBB_PROFILE_DELETE_DEFAULT = "MBB: il profilo predefinito non può essere eliminato.";
	MBB_PROFILE_COMBAT = "MBB: i profili non possono essere cambiati durante il combattimento.";
	MBB_PROFILE_RENAME = "Rinomina";
	MBB_PROFILE_DUPLICATE = "Duplica";
	MBB_PROFILE_RENAME_PROMPT = "Inserisci un nuovo nome per il profilo '%s':";
	MBB_PROFILE_DUPLICATE_PROMPT = "Inserisci un nome per la copia del profilo '%s':";
	MBB_PROFILE_COPY_SUFFIX = "Copia";
	MBB_PROFILE_RENAMED = "MBB: Profilo '%s' rinominato in '%s'.";
	MBB_PROFILE_DUPLICATED = "MBB: Profilo '%s' duplicato come '%s'.";
	MBB_PROFILE_RENAME_DEFAULT = "MBB: Il profilo predefinito non può essere rinominato.";
	MBB_HELP_PROFILE = "  |c00ffffffprofiles|r: apre la gestione dei profili";

end
