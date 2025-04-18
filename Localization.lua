local folder, core = ...

local L = {}

L.deDE = {
    CURRENCY_NAME = "Splitter der Illusion",

    HIDDEN = "Versteckt",
    COSTS = "Kosten",
    COLLECTED = "Gesammelt",
    AVAILABLE = "Verfügbar",
    APPEARANCES = "Aussehen",
    TRANSMOGRIFY = "Transmogrifizieren",
    PAGE = "Seite",
    OPTIONS = "Optionen",
    FILTERS = "Filter",
    ENCHANT_PREVIEW = "Verzauberungsvorschau",
    UNLOCKED_FILTER = "Gesammelt",
    INVENTORY = "Inventar",
    SKIN = "Skin",
    SKINS = "Skins",
    SKIN_SLOT = "Skinplatz",
    LOADING1 = "lädt ...",
    LOADING2 = "Gegenstand wird geladen ...",
    UNDRESS = "Ausziehen",
    TRY_ON = "Anprobieren",
    PRINT = "Drucken",
    SHARE = "Teilen",
    SELECT_ITEM_TYPE = "Gegenstandsarten",
    OVERVIEW = "Übersicht",

    COLLECTED_ITEMS = "Gesammelte Gegenstände",
    COLLECTED_VISUALS = "Gesammelte Aussehen",

    HIDE = "Verstecken",
    UNMOG = "Transmogrifikation entfernen",
    CLEAR_PENDING = "Änderung verwerfen",
    HIDE_ALL = "Alles verstecken",
    UNMOG_ALL = "Alle Transmogrifikationen entfernen",
    RESET_ALL = "Alle Änderungen verwerfen",

    SELECT = "Auswählen",
    ACTIVATE = "Aktivieren",
    RESET = "Zurücksetzen",
    TRANSFER = "Transmogrifikationen transferieren",

    EQUIP = "Anziehen",
    RENAME = "Umbenennen",
    OVERWRITE = "Überschreiben",
    CREATE = "Erstellen",

    APPLY_TO_ITEMS = "Übernehmen",
    APPLY_TO_SKIN = "Übernehmen",

    BUY_SKIN_SLOT = "Weiteren Skinplatz kaufen",
    EMPTY_SKIN_SLOT = "[Freier Skinplatz]",

    TOGGLE_URL = "DB wechseln",

    OUTFIT = "Outfit",
    NEW_OUTFIT = "Neues Outfit erstellen",
    NO_OUTFIT = "Kein Outfit",
    CREATE_OUTFIT_TEXT1 = "Namen für neues Outfit eingeben:",
    RENAME_OUTFIT_TEXT1 = "Neuen Namen für Outfit ",
    RENAME_OUTFIT_TEXT2 = " eingeben:",
    DELETE_OUTFIT_TEXT1 = "Seid ihr sicher, dass ihr Outfit ",
    DELETE_OUTFIT_TEXT2 = " löschen wollt?",
    OVERWRITE_OUTFIT_TEXT1 = "Seid ihr sicher, dass ihr Outfit ",
    OVERWRITE_OUTFIT_TEXT2 = " überschreiben wollt?",
    
    SHOW_IN_WARDROBE = "In Sammlung zeigen",

    CURRENCY_TOOLTIP_TEXT1 = "Splitter der Illusion werden für besondere Transmogrifizierungen benötigt.",
    CURRENCY_TOOLTIP_TEXT2 = "Insgesamt habt ihr aktuell:",
    CURRENCY_TOOLTIP_TEXT3 = "Diese Woche wurden bereits verdient:",
    CURRENCY_TOOLTIP_TEXT4 = "Aktuell kann die Transmoginformation nicht abgefragt werden.",
    CURRENCY_TOOLTIP_TEXT5 = "Gesamt:",
    CURRENCY_TOOLTIP_TEXT6 = "Schlachtzüge:",
    CURRENCY_TOOLTIP_TEXT7 = "Dungeonbrowser:",
    CURRENCY_TOOLTIP_TEXT8 = "Arena:",
    CURRENCY_TOOLTIP_TEXT9 = "Schlachtfelder:",

    EQUIP_PREVIEW = "Mit Ausrüstung",

    TRANSMOG_NAME = "Transmogrifikation",
    APPEARANCE_NOT_COLLECTED_TEXT_A = "Ihr habt dieses Aussehen noch nicht gesammelt.",
    APPEARANCE_NOT_COLLECTED_TEXT_B = "Ihr habt dieses Aussehen gesammelt, aber nicht von diesem Gegenstand.",
    APPEARANCE_NOT_COLLECTED_TEXT_NO = "Gesammelte Aussehen konnten nicht abgefragt werden.",

    APPEARANCE_TOOLTIP_TEXT1A = "Gegenstände mit diesem Aussehen:",
    APPEARANCE_TOOLTIP_TEXT1B = "Verfügbare Gegenstände mit diesem Aussehen:",
    APPEARANCE_TOOLTIP_TEXT2 = "Drücke Tab oder Rechtsklick, um einen anderen Gegenstand auszuwählen.",
    APPEARANCE_TOOLTIP_TEXT3 = "Es gibt weitere Gegenstände mit diesem Aussehen, die nicht der aktuellen Auswahl entsprechen.",
    APPEARANCE_TOOLTIP_TEXT4 = "* Durch die Transmogrifikation wird der Gegenstand an euch gebunden und kann nicht mehr gehandelt oder zurückgegeben werden.",

    ITEM_TOOLTIP_TRANSMOGRIFIED_TO = "Transmogrifiziert zu:",
    ITEM_TOOLTIP_ACTIVE_SKIN = "Aktiver Skin:",
    ITEM_TOOLTIP_FETCHING_NAME = "Frage Iteminformation ab für ",

    TRANSMOG_TOOLTIP_PENDING_CHANGE = "Wird geändert zu:",
    TRANSMOG_TOOLTIP_CURRENT_MOG = "Aktuelle Transmogrifikation:",
    TRANSMOG_TOOLTIP_REMOVE_MOG = "Transmogrifikation entfernen",
    TRANSMOG_TOOLTIP_REMOVE_SKIN = "Leerer Slot",

    CAN_NOT_PREVIEW = "Waffenkombination kann in Vorschau nicht angezeigt werden",
    OH_WILL_BE_HIDDEN = "OH wird von aktueller MH versteckt werden",
    OH_APPEARANCE_WONT_BE_SHOWN = "Transmog auf Nebenhand wird nicht angezeigt",
    MH_APPEARANCE_WONT_BE_SHOWN = "Transmog auf Waffenhand wird nicht angezeigt",
    MH_OH_APPEARANCE_WONT_BE_SHOWN = "Transmog auf beiden Händen wird nicht angezeigt",

    -- MINIMAP_TOOLTIP_TEXT1 = "Linksklick: Sammlung öffnen", -- "Left-click: Open Wardrobe"
    -- MINIMAP_TOOLTIP_TEXT2 = "Umschalt + Linksklick: Transmogfenster öffnen", -- "Shift + Left-click: Open Transmog Interface"
    -- MINIMAP_TOOLTIP_TEXT3 = "Rechtsklick: Transmog Sichtbarkeit umschalten", -- "Right-click: Toggle through visibility options"
    OPEN_WARDROBE = "Sammlung öffnen",
    OPEN_TRANSMOG = "Transmogfenster öffnen",
    OPEN_OPTIONS = "Optionen öffnen",
    TOGGLE_VISIBILITY = "Transmogsichtbarkeit umschalten",

    TRANSMOG_WINDOW = "Transmogfenster",

    TRANSMOG_STATUS = "Transmog Sichtbarkeit: ",
    TRANSMOG_STATUS_UNKNOWN = "Transmog Sichtbarkeit konnte nicht abgefragt werden.",

    SHOW_ITEMS_UNDER_SKIN_TOOLTIP_TEXT = "Aktivieren, um anzuzeigen, wie der Skin in Verbindung mit der aktuellen Ausrüstung aussehen wird.",

    BUY_SKIN_TEXT = "Seid Ihr sicher, dass Ihr einen weiteren Skinplatz kaufen möchtet?",
    NO_SKIN_COSTS_ERROR = "Skin Preis konnte nicht abgefragt werden",

    RENAME_SKIN_TEXT1 = "Neuen Namen für Skin",
    RENAME_SKIN_TEXT2 = "eingeben:",

    CREATE_SKIN_TEXT1 = "Name für neuen Skin in Skinplatz ",
    CREATE_SKIN_TEXT2 = " eingeben:",

    RESET_SKIN_TEXT1 = "Seid ihr euch sicher, dass ihr Skin",
    RESET_SKIN_TEXT2 = "zurücksetzen wollt?\nDadurch werden alle Transmogrifikationen auf dem Skin unwiderruflich gelöscht.",

    VISUALS_TO_SKIN_TEXT1 = "Diese Aktion entfernt folgende Transmogrifikationen von eurer Ausrüstung und überträgt sie auf den Skin",
    VISUALS_TO_SKIN_TEXT2 = "Die bereits gezahlten Kosten sind im Preis verrechnet. Fortfahren?",

    APPLY_TO_INVENTORY_TEXT1 = "Auf eure ausgerüsteten Gegenstände",
    APPLY_TO_INVENTORY_TEXT2 = "werden folgende Transmogrifikationen angewandt. Fortfahren?",
    APPLY_TO_SKIN_TEXT1 = "Auf den Skin",

    SKIN_NEEDS_ACTIVATION = "Skin muss benannt werden, bevor er benutzt werden kann.",

    SKIN_NAME_TOO_SHORT = "Skinnamen müssen mindestens ein Zeichen lang sein.",
    SKIN_NAME_INVALID_CHARACTERS = "Skinname enthält ungültige Zeichen.",

    OUTFIT_NAME_TOO_SHORT = "Outfitnamen müssen mindestens ein Zeichen lang sein.",
    OUTFIT_NAME_INVALID_CHARACTERS = "Outfitname enthält ungültige Zeichen.",
    OUTFIT_NAME_ALREADY_IN_USE = "Es gibt bereits ein Outfit mit diesem Namen.",

    UNLOCKED_BAR_TOOLTIP_TEXT1 = "Anzahl gesammelter Aussehen, die den gewählten Filtern entsprechen.",
    SEARCHBOX_TOOLTIP_TEXT1 = "Filtert Auswahl nach Gegenstandsname oder ID.",

    SELECT_SKIN = "Skin auswählen",

    APPLY_ERROR1 = "Transmogkosten oder Splitterguthaben konnten nicht abgefragt werden.",
    APPLY_ERROR2 = "Ihr habt nicht genug Geld oder Splitter der Illusion.",

    NO_SLOT_SELECTED_TEXT = "Gegenstandsplatz auswählen, um verfügbare Transmogrifikationen anzuzeigen.",

    CAN_NOT_DRESS_OFFHAND = "Euer Charakter kann diesen Gegenstand nicht in der Nebenhand anprobieren.",
    
    SHADOW_FORM_TOOLTIP_TITLE = "Simuliere Schattengestalt",
    SHADOW_FORM_TOOLTIP_TEXT = "Emissionstexturen und Gegenstände mit Lichtquellen werden anders aussehen als in der richtigen Schattengestalt.",

    ENCHANT_PREVIEW_BUTTON_TOOLTIP_TEXT = "Zeige ausgerüstete oder gewählte Waffenverzauberung an den Modellen.",

    ENCHANT_UNLOCK_BUTTON_TOOLTIP1 = "Schaltet Verzauberungen aus eurem Inventar zur Transmogrifikation frei.",
    ENCHANT_UNLOCK_BUTTON_TOOLTIP2 = "Ihr habt keine Schriftrollen zum Freischalten von Transmogrifikationen.",

    ENCHANT_UNLOCK_POPUP_TEXT = "Seid ihr sicher, dass ihr folgende Verzauberungen zur Transmogrifikation freischalten wollt? Die Gegenstände werden dabei zerstört.\n",

    NO_UNLOCKS_HINT_TEXT1 = "Ihr habt keine verfügbaren Transmogrifikationen für den gewählten Slot und Gegenstandsart.",
    NO_UNLOCKS_HINT_TEXT2 = "\n\nIhr könnt Schriftrollen oder Gegenstände in eurem Inventar benutzen, um die entsprechende Verzauberung zur Transmogrifikation freizuschalten.\nNutzt dazu den Button in der rechten unteren Ecke oder das Dialogmenü des NPCs.",

    APPLY_TOOLTIP_NO_PENDING = "Keine ausstehenden Transmogrifikationen.",
    APPLY_TOOLTIP_INVALID_SLOTS = "Manche der ausstehenden Transmogrifikationen sind unzulässig:\n",

    BACK_TO_GOSSIP_MENU_TEXT = "Zurück zum Dialogfenster",

    LEFT_CLICK = "Linksklick:",
    SHIFT_LEFT_CLICK = "Umschalt + Linksklick:",
    CONTROL_LEFT_CLICK = "Steuerung + Linksklick:",
    ALT_LEFT_CLICK = "Alt + Linksklick:",
    RIGHT_CLICK = "Rechtsklick:",

    CONFIG_NAMES = {
        [1] = "An",
        [2] = "Im PvP aus",
        [3] = "Aus",
    },
    
    SLOT_NAMES = {
        HeadSlot = "Kopf",
        ShoulderSlot = "Schultern",
        BackSlot = "Rücken",
        ChestSlot = "Brust",
        ShirtSlot = "Hemd",
        TabardSlot = "Wappenrock",
        WristSlot = "Handgelenke",
        HandsSlot = "Hände",
        WaistSlot = "Taille",
        LegsSlot = "Beine",
        FeetSlot = "Füße",
        MainHandSlot = "Waffenhand",
        ShieldHandWeaponSlot = "Schildhandwaffe",
        OffHandSlot = "Nebenhand",
        SecondaryHandSlot = "Schildhand",
        MainHandEnchantSlot = "Waffenhandverzauberung",
        SecondaryHandEnchantSlot = "Schildhandverzauberung",
        RangedSlot = "Distanz",
    },

    CLEAR_FILTERS = "Filter zurücksetzen",
    FILTER_FOR_CHARACTER = "Für Charakter filtern",

    ALLIANCE = "Allianz", -- Localized name lookup for Faction and Race seems to be unavailable before 8.0.1
    HORDE = "Horde",

    HUMAN = "Mensch",
    ORC = "Orc",
    DWARF = "Zwerg",
    NIGHTELF = "Nachtelf",
    UNDEAD = "Untote",
    TAUREN = "Tauren",
    GNOME = "Gnom",
    TROLL = "Troll",
    BLOODELF = "Blutelf",
    DRAENEI = "Draenei",
}


L.enEU = {
    CURRENCY_NAME = "Shards of Illusion",

    HIDDEN = "Hidden",
    COSTS = "Costs",
    COLLECTED = "Collected",
    AVAILABLE = "Available",
    APPEARANCES = "Appearances",
    TRANSMOGRIFY = "Transmogrify",
    PAGE = "Page",
    OPTIONS = "Options",
    FILTERS = "Filters",
    ENCHANT_PREVIEW = "Enchant preview",
    UNLOCKED_FILTER = "Collected",
    INVENTORY = "Inventory",
    SKIN = "Skin",
    SKINS = "Skins",
    SKIN_SLOT = "Skin slot",
    LOADING1 = "loading ...",
    LOADING2 = "Loading item info ...",
    UNDRESS = "Undress",
    TRY_ON = "Try on",
    PRINT = "Print",
    SHARE = "Share",
    SELECT_ITEM_TYPE = "Item types",
    OVERVIEW = "Overview",

    COLLECTED_ITEMS = "Collected items",
    COLLECTED_VISUALS = "Collected visuals",

    HIDE = "Hide",
    UNMOG = "Remove transmogrification",
    CLEAR_PENDING = "Clear pending change",
    HIDE_ALL = "Hide all",
    UNMOG_ALL = "Remove all transmogrifications",
    RESET_ALL = "Clear all changes",    

    SELECT = "Select",
    ACTIVATE = "Activate",
    RESET = "Reset",
    TRANSFER = "Transfer transmogrifications",

    EQUIP = "Equip",
    RENAME = "Rename",
    OVERWRITE = "Overwrite",
    CREATE = "Create",

    APPLY_TO_ITEMS = "Apply to items",
    APPLY_TO_SKIN = "Apply to skin",

    BUY_SKIN_SLOT = "Buy another skin slot",
    EMPTY_SKIN_SLOT = "[Free skin slot]",
    
    TOGGLE_URL = "Change DB",

    OUTFIT = "Outfit",
    NEW_OUTFIT = "Create new outfit",
    NO_OUTFIT = "No outfit",
    CREATE_OUTFIT_TEXT1 = "Enter name for new outfit:",
    RENAME_OUTFIT_TEXT1 = "Enter new name for outfit ",
    RENAME_OUTFIT_TEXT2 = ":",
    DELETE_OUTFIT_TEXT1 = "Are u sure you want to delete outfit ",
    DELETE_OUTFIT_TEXT2 = "?",
    OVERWRITE_OUTFIT_TEXT1 = "Are u sure you want to overwrite outfit ",
    OVERWRITE_OUTFIT_TEXT2 = "?",

    SHOW_IN_WARDROBE = "Open in wardrobe",    

    CURRENCY_TOOLTIP_TEXT1 = "Shards of Illusion are used for special transmogrifications.",
    CURRENCY_TOOLTIP_TEXT2 = "You currently have a total of:",
    CURRENCY_TOOLTIP_TEXT3 = "Already earned this week:",
    CURRENCY_TOOLTIP_TEXT4 = "Could not retrieve transmog information from server.",
    CURRENCY_TOOLTIP_TEXT5 = "Overall:",
    CURRENCY_TOOLTIP_TEXT6 = "Raids:",
    CURRENCY_TOOLTIP_TEXT7 = "Dungeonbrowser:",
    CURRENCY_TOOLTIP_TEXT8 = "Arena:",
    CURRENCY_TOOLTIP_TEXT9 = "Battlegrounds:",

    EQUIP_PREVIEW = "Equip preview",

    TRANSMOG_NAME = "Transmogrification",
    APPEARANCE_NOT_COLLECTED_TEXT_A = "You haven't collected this appearance.",
    APPEARANCE_NOT_COLLECTED_TEXT_B = "You've collected this appearance, but not from this item.",
    APPEARANCE_NOT_COLLECTED_TEXT_NO = "Could not retrieve collected appearances from server.",

    APPEARANCE_TOOLTIP_TEXT1A = "Items with this appearance:",
    APPEARANCE_TOOLTIP_TEXT1B = "Available items with this appearance:",
    APPEARANCE_TOOLTIP_TEXT2 = "Press tab or right klick to cycle through items.",
    APPEARANCE_TOOLTIP_TEXT3 = "There are other items with this appearance that don't fit current filters.",
    APPEARANCE_TOOLTIP_TEXT3 = "* Using this item for transmogrification will bind it to you and make it non-tradable and non-refundable.",

    ITEM_TOOLTIP_TRANSMOGRIFIED_TO = "Transmogrified to:",
    ITEM_TOOLTIP_ACTIVE_SKIN = "Active skin:",
    ITEM_TOOLTIP_FETCHING_NAME = "Loading item info ",

    TRANSMOG_TOOLTIP_PENDING_CHANGE = "Pending change:",
    TRANSMOG_TOOLTIP_CURRENT_MOG = "Currently transmogrified to:",
    TRANSMOG_TOOLTIP_REMOVE_MOG = "Remove transmogrification",
    TRANSMOG_TOOLTIP_REMOVE_SKIN = "Empty slot",

    CAN_NOT_PREVIEW = "Cannot preview current melee weapons together.",
    OH_WILL_BE_HIDDEN = "Off hand will be hidden by current main hand appearance.",
    OH_APPEARANCE_WONT_BE_SHOWN = "Off hand appearance will not be shown while in this slot.",
    MH_APPEARANCE_WONT_BE_SHOWN = "Main hand appearance will not be shown while in this slot.",
    MH_OH_APPEARANCE_WONT_BE_SHOWN = "Main and off hand appearance incompatible with slo.t",

    -- MINIMAP_TOOLTIP_TEXT1 = "Left click: Open wardrobe",
    -- MINIMAP_TOOLTIP_TEXT2 = "Shift + left click: Open transmog window",
    -- MINIMAP_TOOLTIP_TEXT3 = "Right click: Change transmog visibility",
    OPEN_WARDROBE = "Open Wardrobe",
    OPEN_TRANSMOG = "Open Transmog Window",
    OPEN_OPTIONS = "Open Options",
    TOGGLE_VISIBILITY = "Change Transmog Visibility",

    TRANSMOG_WINDOW = "Transmog window",

    TRANSMOG_STATUS = "Transmog status: ",
    TRANSMOG_STATUS_UNKNOWN = "Could not retrieve transmog configuration from server.",

    SHOW_ITEMS_UNDER_SKIN_TOOLTIP_TEXT = "Show how the skin will look on top of your current equipment.",

    BUY_SKIN_TEXT = "Do you want to buy another skin slot?",
    NO_SKIN_COSTS_ERROR = "Could not retrieve price for skin slot from server.",

    RENAME_SKIN_TEXT1 = "Enter new name for skin ",
    RENAME_SKIN_TEXT2 = ":",

    CREATE_SKIN_TEXT1 = "Enter name for new skin in slot ",
    CREATE_SKIN_TEXT2 = ":",

    RESET_SKIN_TEXT1 = "Are you sure you want to reset skin ",
    RESET_SKIN_TEXT2 = "?\nAll transmogrifications on the skin will be lost.",

    VISUALS_TO_SKIN_TEXT1 = "This action removes the following transmogrifications from your gear and transfers them to skin",
    VISUALS_TO_SKIN_TEXT2 = "The costs already paid are taken into account. Continue?",

    APPLY_TO_INVENTORY_TEXT1 = "Your items",
    APPLY_TO_INVENTORY_TEXT2 = "will receive the following transmogrifications. Continue?",
    APPLY_TO_SKIN_TEXT1 = "The skin",

    SKIN_NEEDS_ACTIVATION = "Skins need to be named, before they are usable.",

    SKIN_NAME_TOO_SHORT = "Skin name must be atleast one character long.",
    SKIN_NAME_INVALID_CHARACTERS = "Skin name contains illegal characters.",

    OUTFIT_NAME_TOO_SHORT = "Outfit name must be atleast one character long.",
    OUTFIT_NAME_INVALID_CHARACTERS = "Outfit name contains illegal characters.",
    OUTFIT_NAME_ALREADY_IN_USE = "There already exists an outfit with this name.",

    UNLOCKED_BAR_TOOLTIP_TEXT1 = "Amount of collected appearances for current selection.",
    SEARCHBOX_TOOLTIP_TEXT1 = "Filter by item name or ID.",

    SELECT_SKIN = "Select a Skin",

    APPLY_ERROR1 = "Could not retrieve transmogrification costs or balance from server.",
    APPLY_ERROR2 = "You do not have enough gold or Shards of Illusion.",

    NO_SLOT_SELECTED_TEXT = "Select an item slot to display available transmogrifications.",

    CAN_NOT_DRESS_OFFHAND = "Your character cannot try on this item in the shield hand.",

    SHADOW_FORM_TOOLTIP_TITLE = "Shadow form simulation",
    SHADOW_FORM_TOOLTIP_TEXT = "Does not give correct results for emissive textures or items with light sources.",
    
    ENCHANT_PREVIEW_BUTTON_TOOLTIP_TEXT = "Preview equipped or selected weapon enchant on mannequins.",

    ENCHANT_UNLOCK_BUTTON_TOOLTIP1 = "Unlock enchants for transmogrification.",
    ENCHANT_UNLOCK_BUTTON_TOOLTIP2 = "You don't have any scrolls to unlock for transmogrification.",

    ENCHANT_UNLOCK_POPUP_TEXT = "Are you sure you want to unlock the following enchants for transmogrification? The scrolls will be destroyed in the process.\n",
    
    NO_UNLOCKS_HINT_TEXT1 = "You have no available transmogrifications for the selected slot and item type.",
    NO_UNLOCKS_HINT_TEXT2 = "\n\nTo unlock weapon enchantments for transmogrifications, you can sacrifice the corresponding scrolls or consumables from your inventory. To do this, press the button in the lower right corner or use the NPC's dialogue menu.",
    
    APPLY_TOOLTIP_NO_PENDING = "No pending transmogrifications.",
    APPLY_TOOLTIP_INVALID_SLOTS = "There are slots with invalid pending transmogrifications:\n",

    BACK_TO_GOSSIP_MENU_TEXT = "Back to gossip menu",

    LEFT_CLICK = "Left Click:",
    SHIFT_LEFT_CLICK = "Shift + Left Click:",
    CONTROL_LEFT_CLICK = "Control + Left Click:",
    ALT_LEFT_CLICK = "Alt + Left Click:",
    RIGHT_CLICK = "Right Click:",

    CONFIG_NAMES = {
        [1] = "Enabled",
        [2] = "In PvP disabled",
        [3] = "Disabled",
    },
    
    SLOT_NAMES = {
        HeadSlot = "Head",
        ShoulderSlot = "Shoulders",
        BackSlot = "Back",
        ChestSlot = "Chest",
        ShirtSlot = "Shirt",
        TabardSlot = "Tabard",
        WristSlot = "Wrists",
        HandsSlot = "Hands",
        WaistSlot = "Waist",
        LegsSlot = "Legs",
        FeetSlot = "Feet",
        MainHandSlot = "Main hand",
        ShieldHandWeaponSlot = "Shield hand weapon",
        OffHandSlot = "Off hand",
        SecondaryHandSlot = "Shield hand",
        MainHandEnchantSlot = "Main hand enchant",
        SecondaryHandEnchantSlot = "Shield hand enchant",
        RangedSlot = "Ranged",
    },
    
    CLEAR_FILTERS = "Reset filters",
    FILTER_FOR_CHARACTER = "Filter for character",

    ALLIANCE = "Alliance",
    HORDE = "Horde",
    
    HUMAN = "Human",
    ORC = "Orc",
    DWARF = "Dwarf",
    NIGHTELF = "Night Elf",
    UNDEAD = "Undead",
    TAUREN = "Tauren",
    GNOME = "Gnome",
    TROLL = "Troll",
    BLOODELF = "Blood Elf",
    DRAENEI = "Draenei",
}


local locale, default = GetLocale(), "enEU"
L = L[locale] or L[default]

for k, v in pairs(L) do
    core[k] = v
end