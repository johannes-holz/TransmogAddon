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
    SELECT_ITEM_TYPE = "Gegenstandsarten", -- "Gegenstandsart auswählen",
    OVERVIEW = "Übersicht",

    HIDE = "Verstecken",
    UNMOG = "Entmogrifizieren",
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

    APPLY_TO_ITEMS = "Übernehmen", -- don't think we can fit "to skin/items" on the button in german
    APPLY_TO_SKIN = "Übernehmen",

    BUY_SKIN_SLOT = "Weiteren Skinplatz kaufen",
    EMPTY_SKIN_SLOT = "[Freier Skinplatz]",

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

    CURRENCY_TOOLTIP_TEXT1 = "Splitter der Illusion werden für besondere Transmogrifizierungen benötigt.",
    CURRENCY_TOOLTIP_TEXT2 = "Insgesamt habt ihr aktuell:",
    CURRENCY_TOOLTIP_TEXT3 = "Diese Woche wurden bereits verdient:",
    CURRENCY_TOOLTIP_TEXT4 = "Aktuell kann die Transmoginformation nicht abgefragt werden.",
    CURRENCY_TOOLTIP_TEXT5 = "Gesamt:",
    CURRENCY_TOOLTIP_TEXT6 = "Schlachtzüge:",
    CURRENCY_TOOLTIP_TEXT7 = "Dungeonbrowser:",
    CURRENCY_TOOLTIP_TEXT8 = "Arena:",
    CURRENCY_TOOLTIP_TEXT9 = "Schlachtfelder:",

    TRANSMOG_NAME = "Transmogrifikation",
    APPEARANCE_NOT_COLLECTED_TEXT_A = "Ihr habt dieses Aussehen noch nicht gesammelt.", -- "You haven't collected this appearance"
    APPEARANCE_NOT_COLLECTED_TEXT_B = "Ihr habt dieses Aussehen gesammelt, aber nicht von diesem Gegenstand.", --"You've collected this appearance, but not from this item"
    APPEARANCE_NOT_COLLECTED_TEXT_NO = "Gesammelte Aussehen konnten nicht abgefragt werden.",

    APPEARANCE_TOOLTIP_TEXT1A = "Gegenstände mit diesem Aussehen:",
    APPEARANCE_TOOLTIP_TEXT1B = "Verfügbare Gegenstände mit diesem Aussehen:",
    APPEARANCE_TOOLTIP_TEXT2 = "Drücke Tab oder Rechtsklick, um einen anderen Gegenstand auszuwählen.",
    APPEARANCE_TOOLTIP_TEXT3 = "Es gibt weitere Gegenstände mit diesem Aussehen, die nicht der aktuellen Auswahl entsrprechen.",
    APPEARANCE_TOOLTIP_TEXT4 = "* Durch die Transmogrifikation wird der Gegenstand an euch gebunden und kann nicht mehr gehandelt oder zurückgegeben werden.",

    ITEM_TOOLTIP_TRANSMOGRIFIED_TO = "Transmogrifiziert zu:",
    ITEM_TOOLTIP_ACTIVE_SKIN = "Aktiver Skin:",
    ITEM_TOOLTIP_FETCHING_NAME = "Frage Iteminformation ab für ",

    TRANSMOG_TOOLTIP_PENDING_CHANGE = "Wird geändert zu:",
    TRANSMOG_TOOLTIP_CURRENT_MOG = "Aktuelle Transmogrifikation:",
    TRANSMOG_TOOLTIP_REMOVE_MOG = "Transmogrifikation entfernen",
    TRANSMOG_TOOLTIP_CURRENT_SKIN = "Aktuell ausgewählt:",
    TRANSMOG_TOOLTIP_REMOVE_SKIN = "Leerer Slot",

    CAN_NOT_PREVIEW = "Waffenkombination kann in Vorschau nicht angezeigt werden", -- "Cannot preview current melee weapons together."
    OH_WILL_BE_HIDDEN = "OH wird von aktueller MH versteckt werden", -- "Off hand will be hidden by current main hand appearance."
    OH_APPEARANCE_WONT_BE_SHOWN = "Transmog auf Nebenhand wird nicht angezeigt", -- "This off hand appearance will not be shown while in this slot."
    MH_APPEARANCE_WONT_BE_SHOWN = "Transmog auf Waffenhand wird nicht angezeigt",
    MH_OH_APPEARANCE_WONT_BE_SHOWN = "Transmog auf beiden Händen wird nicht angezeigt",

    MINIMAP_TOOLTIP_TEXT1 = "Linksklick: Sammlung öffnen", -- "Left-click: Open Wardrobe"
    MINIMAP_TOOLTIP_TEXT2 = "Umschalt + Linksklick: Transmogfenster öffnen", -- "Shift + Left-click: Open Transmog Interface"
    MINIMAP_TOOLTIP_TEXT3 = "Rechtsklick: Transmog Sichtbarkeit umschalten", -- "Right-click: Toggle through visibility options"

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

    --"Die Transmogrifizierung aller ausgerüsteten Gegenstände wird von den Gegenständen entfernt und auf den Skin übertragen. Bereits gezahlte Kosten werden verrechnet. Existiert bereits eine Transmogrifikation auf einem Ausrüstungsplatz des Skins, so wird diese nicht überschrieben. Fortfahren?"
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

    UNLOCKED_BAR_TOOLTIP_TEXT1 = "Anzahl gesammelter Aussehen, die den gewählten Filtern entsprechen.", -- "Unlocked Appearances for current selection. The upper bound includes items that might not be collectable for this character."
    SEARCHBOX_TOOLTIP_TEXT1 = "Filtert Auswahl nach Gegenstandsname oder ID.", -- "Filter items by name or item ID.\nSearch by name only works for cached items."

    SELECT_SKIN = "Skin auswählen",

    APPLY_ERROR1 = "Transmogkosten oder Splitterguthaben konnten nicht abgefragt werden.",
    APPLY_ERROR2 = "Ihr habt nicht genug Geld oder Splitter der Illusion.",

    NO_SLOT_SELECTED_TEXT = "Gegenstandsplatz auswählen, um verfügbare Transmogrifikationen anzuzeigen.",

    CAN_NOT_DRESS_OFFHAND = "Euer Charakter kann diesen Gegenstand nicht in der Nebenhand anprobieren.",
    
    SHADOW_FORM_TOOLTIP_TITLE = "Simuliere Schattengestalt",
    SHADOW_FORM_TOOLTIP_TEXT = "Emissionstexturen und Gegenstände mit Lichtquellen werden anders aussehen als in der richtigen Schattengestalt.",

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
    SELECT_ITEM_TYPE = "Item types", -- "Select item type",
    OVERVIEW = "Overview",

    HIDE = "Hide",
    UNMOG = "Unmog",
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

    APPLY_TO_ITEMS = "Apply to items", -- or just apply?
    APPLY_TO_SKIN = "Apply to skin",

    BUY_SKIN_SLOT = "Buy another skin slot",
    EMPTY_SKIN_SLOT = "[Free skin slot]",

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

    CURRENCY_TOOLTIP_TEXT1 = "Shards of Illusion are used for special transmogrifications.",
    CURRENCY_TOOLTIP_TEXT2 = "You currently have a total of:",
    CURRENCY_TOOLTIP_TEXT3 = "Already earned this week:",
    CURRENCY_TOOLTIP_TEXT4 = "Could not retrieve transmog information from server.",
    CURRENCY_TOOLTIP_TEXT5 = "Overall:",
    CURRENCY_TOOLTIP_TEXT6 = "Raids:",
    CURRENCY_TOOLTIP_TEXT7 = "Dungeonbrowser:",
    CURRENCY_TOOLTIP_TEXT8 = "Arena:",
    CURRENCY_TOOLTIP_TEXT9 = "Battlegrounds:",

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
    TRANSMOG_TOOLTIP_CURRENT_SKIN = "Aktuell ausgewählt:",
    TRANSMOG_TOOLTIP_REMOVE_SKIN = "Empty slot",

    CAN_NOT_PREVIEW = "Cannot preview current melee weapons together.",
    OH_WILL_BE_HIDDEN = "Off hand will be hidden by current main hand appearance.",
    OH_APPEARANCE_WONT_BE_SHOWN = "Off hand appearance will not be shown while in this slot.",
    MH_APPEARANCE_WONT_BE_SHOWN = "Main hand appearance will not be shown while in this slot.",
    MH_OH_APPEARANCE_WONT_BE_SHOWN = "Main and off hand appearance incompatible with slo.t",

    MINIMAP_TOOLTIP_TEXT1 = "Left click: Open wardrobe", -- "Left-click: Open Wardrobe"
    MINIMAP_TOOLTIP_TEXT2 = "Shift + left click: Open transmogrification", -- "Shift + Left-click: Open Transmog Interface"
    MINIMAP_TOOLTIP_TEXT3 = "Right click: Change transmog visibility", -- "Right-click: Toggle through visibility options"

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

    --"Die Transmogrifizierung aller ausgerüsteten Gegenstände wird von den Gegenständen entfernt und auf den Skin übertragen. Bereits gezahlte Kosten werden verrechnet. Existiert bereits eine Transmogrifikation auf einem Ausrüstungsplatz des Skins, so wird diese nicht überschrieben. Fortfahren?"
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
}


local locale, default = GetLocale(), "enEU"
L = L[locale] or L[default]

for k, v in pairs(L) do
    core[k] = v
end