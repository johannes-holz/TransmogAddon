MyAddon, myadd = ...


--TODO: useless before variables loaded event?
MyAddonDB = MyAddonDB or {}

-- General Programflow: GUI action (-> Request Serveraction -> Request update of possibly changed data) -> Changes to data -> Trigger update to all GUI elements that use that data
-- Itempreviews not yet included in that workflow. Here Setting slot+category triggers updating the list of displayed items, setting the page and updating the preview models


--TODO: Revert changes button
-- einfach tabelle mit allen currentChanges? 

-- equipSlot and equipSet methoden, die die update methoden jedes gui elements aufrufen, die sich dafür registriert haben?
-- dann darüber die changes history anlegen? vor, zurück button: index an welcher stelle in historytable wir uns befinden. bei changes alles vor index löschen (lua trick dafür?)
-- vor und zurück button verschieben index und ändern set ohne die history zu ändern. bei set wechsel history wipen

-- geänderte slots die geblockt werden nach dem ändern (durch ablegen des items), auch für savekrams ignorieren?

--babelfish for locales file generation?
--libdbicon und libstub als libs für minimap icon
--libcallbackhandler to implement listener pattern for gui?

-- drüber klar werden, wie itemid/displayid gehandelt werden kann.
-- liste der equipable display ids aus itemids generieren -> für angezogene items checken ob zugehörige display id in der liste ist?
-- liste abfragen beim öffnen des addons, falls noch nicht geschehen oder equip sich in der zwischenzeit geändert hat. und bei itemänderung während das addon geöffnet ist
-- frage ob serverseitig handlebar bzgl datenmengen, wo bottleneck?
-- 

-- slotmodels: anderer rahmen, wenn mog vorhanden bzw nicht vorhanden ist

-- garantieren, dass build list die vom server gesendeten items anzeigt, egal ob die items in displayids krams stehen

--isOffhandBlocked function, die für icon und apply function benutzt wird? 
--TODO: get weapon enchants on gear and make icon logic with that -- im moment können enchants nur gewählt werden, wenn enchant auf waffe vorhanden ist, iconborder/blockedtex etc zeigt dies aber nicht an
--TODO: ranged slot blocken, wenn keine mogable waffe drin ist (buchbände etc)
--TODO: item farben: mogit hat relativ gute daten (1-3 farben), zum teil aber auch murks farben dabei. sortieren nach kleinster farb differenz statt avarages zu vergleichen? "Hauptfarbe" zu wissen wäre nützlich, aber ham wa nicht
--TODO: swirly animation textur für changes verbessern(inneren und äußeren rahmen)
--TODO: slotmodels und page stuff in frame packen, den man hiden kann, um alles auf einmal zu hiden etc
	--scrollfunktion dann auf dem? in models mousefunktion aufrufen, da sonst von denen blockiert?

--TODO: dummy weapons getiteminfo securen mit dem tooltip trick?
--TODO: die mainhand/offhand geschichte nochmal genau anschauen. offhand nicht mehr setzbar machen, wenn 2h (titangrib beachten und woanders setzen und bei talentschanged erneut setzen) mogg in mh? sonst komisches verhalten#
--für previews nicht nötig, höchstens für checks if wearable: /run for i = 1, GetNumSkillLines() do print(i, GetSkillLineInfo(i)) end gibt waffenfertigkeiten und rüstungssachverstand, IsSpellKnown(674) gibt beidhändigkeit
--TODO:NO später: favourite items setzen? mini vorschau von gespeicherten sets?
--TODO: modelposition settings abhängig von den rassen? bei diesem kram mit richtiger auflösugn arbeiten!!
--TODO: fenster für ingame-sets devias etc
--animationen abhängig von waffentyp etc? bogenhaltung, armbrust, funstuff wie shy bei undress etc?
--optional skybox model statt hintergrund textur
--animationen bräuchten liste mit name, id, duration, folgeanimation (kiss into normal idle, sit down into sit etc) viel arbeit die timings rauszukriegen, nicht worth

--feature ideas:
--[[
share optionen, import export? clickable set links? nur für addon user sichtbar machen, indem über addonmessage channel gesendet wird und chat link vom empfänger erzeugt wird?






]]

local API = LibStub("RisingAPI", true)

local bar, windowFrame
local model, headSlotFrame, pageTextField, catDDM, setDDM, saveButton, applyButton, costsFrame, itemSlotOptionsFrame, nameFilterTextField
local itemSlotFrames, slotModels = {}, {}
local list = {}
local selectedCategory, selectedSlot = nil, nil
local page = 1
local modelWidth = 428 --300
local modelHeight = 500 --350
local itemSlotWidth = 32 --modelHeight / 8 - 2
local slotModelWidth = modelHeight / 2.91
local itemSlotDistance = 20--(modelHeight-7*itemSlotWidth) / 6
local slotModelDistance = 10
local modelsPerPage = 8
local nakedSlotModels = true
local maxSets = 40
local onlyMogableFilter = false
local nameFilter = true
local toBeRenamed
local gossipFrameWidthBackup = 0
local mogTooltipTextColor = { ["r"] = 0xff / 255, ["g"] = 0x9c / 255, ["b"] = 0xe6 / 255, ["a"] = 1 } -- 255/255, 192/255, 203/255)
local setItemTooltipTextColor = { ["r"] = 1, ["g"] = 1, ["b"] = 0.6, ["a"] = 1 }
local setItemMissingTooltipTextColor = { ["r"] = 0.5, ["g"] = 0.5, ["b"] = 0.5, ["a"] = 1 }
local bonusTooltipTextColor = { ["r"] = 0, ["g"] = 1, ["b"] = 0, ["a"] = 1 }

local BackgroundItemInfoWorker = {}
-- Functionreferences, get defined in the Addonloading process. So after the Variables loaded event, everything should be defined and callable
local FunctionOnItemInfo, GetCoinTextureStringFull
local UpdateItemSlots, BuildList, SetPage, ToApiSet, SetAvailableMogs, PlayApplyAnimations

local listeners = {}
local RegisterListener, UpdateListeneres, HandleItem

-- Functions that interact with the API. Trigger another Request or trigger SetX function on server answer. Convert to and from API set format
local RequestCurrentMogsUpdate, RequestAvailableMogsUpdate, RequestPriceOfApplyingUpdate, RequestApplyCurrentChanges, RequestBalance, RequestSets, RequestSetRename, RequestSetAdd, RequestSetDelete, RequestPriceOfSavingUpdate, RequestSetUpgrade, RequestApplySet
-- Functions setting data and trigger update function of registered GUI elements
local SetCosts, SetCurrentChanges, SetCurrentChangesSlot, SetSlotAndCategory, SetBalance, SetCurrentMogs, SetSets, SetSelectedSet
local SelectSet --set selected set and current changes accordingly

local balance, costs, saveSetCosts = 0, 0, {["copper"] = 0, ["points"] = 0}

MyAddonDB.sets = MyAddonDB.sets or {}
MyAddonDB.currentChanges = MyAddonDB.currentChanges or {}

-- items sind unsinn zum teil (von anderem slot kopiert)
myadd.availableMogs = {
		["HeadSlot"] = {[48902] = true},
		["ShoulderSlot"] = {[24996] = true},
		["BackSlot"] = {[34190] = true},
		["ChestSlot"] = {[30896] = true},
		["ShirtSlot"] = {[42378] = true},
		["TabardSlot"] = {[42378] = true},
		["WristSlot"] = {[31636] = true},
		["HandsSlot"] = {[31636] = true},
		["WaistSlot"] = {[24934] = true},
		["LegsSlot"] = {[30536] = true},
		["FeetSlot"] = {[13527] = true},
		["MainHandSlot"] = {[29329] = true},
		["MainHandEnchantSlot"] = {[3789] = true},
		["SecondaryHandSlot"] = {[29329] = true},
		["SecondaryHandEnchantSlot"] = {[3789] = true},
		["RangedSlot"] = {[29329] = true},
}

myadd.availableMogsUpdateNeeded = {}

local currentMogs = {
	["inventory"] = {},
	["container"] = {}, --TODO: Hopefully not needed, with tmog id provided in itemlinks
}

myadd.warmaneItems = {
	[50701] = true,
	[47664] = true,
	[51820] = true,
	[51884] = true,
	[6117] = true,
	[127] = true,
	[22425] = true,
	[19372] = true,
	[30641] = true,
	[46961] = true,
	[51277] = true,
	[51405] = true,
	[50414] = true,
	[51469] = true,
	[48432] = true,
	[30897] = true,
	[50606] = true,
	[50670] = true,
	[50702] = true,
	[47665] = true,
	[30034] = true,
	[51885] = true,
	[30082] = true,
	[2105] = true,
	[18861] = true,
	[40792] = true,
	[33695] = true,
	[40984] = true,
	[14617] = true,
	[50255] = true,
	[50351] = true,
	[50415] = true,
	[51470] = true,
	[51534] = true,
	[17103] = true,
	[47506] = true,
	[33216] = true,
	[50639] = true,
	[32512] = true,
	[50703] = true,
	[50735] = true,
	[51822] = true,
	[44693] = true,
	[32608] = true,
	[51918] = true,
	[21387] = true,
	[4335] = true,
	[6385] = true,
	[48977] = true,
	[50032] = true,
	[46995] = true,
	[28660] = true,
	[32801] = true,
	[51279] = true,
	[50352] = true,
	[28788] = true,
	[51471] = true,
	[49489] = true,
	[50608] = true,
	[50640] = true,
	[50672] = true,
	[50736] = true,
	[34400] = true,
	[42616] = true,
	[51855] = true,
	[33473] = true,
	[48978] = true,
	[46964] = true,
	[33697] = true,
	[40890] = true,
	[47092] = true,
	[42041] = true,
	[33889] = true,
	[50353] = true,
	[45270] = true,
	[50417] = true,
	[50449] = true,
	[48435] = true,
	[50609] = true,
	[47572] = true,
	[50673] = true,
	[42521] = true,
	[47668] = true,
	[42585] = true,
	[51888] = true,
	[51920] = true,
	[21388] = true,
	[22427] = true,
	[28597] = true,
	[33698] = true,
	[47093] = true,
	[42042] = true,
	[27702] = true,
	[3342] = true,
	[51377] = true,
	[51473] = true,
	[21692] = true,
	[30915] = true,
	[50610] = true,
	[50642] = true,
	[50674] = true,
	[50706] = true,
	[50738] = true,
	[51857] = true,
	[30084] = true,
	[33699] = true,
	[23019] = true,
	[46071] = true,
	[50195] = true,
	[42043] = true,
	[51346] = true,
	[32354] = true,
	[51410] = true,
	[51474] = true,
	[6833] = true,
	[51570] = true,
	[34243] = true,
	[47574] = true,
	[50675] = true,
	[50707] = true,
	[47670] = true,
	[51826] = true,
	[28502] = true,
	[51890] = true,
	[21389] = true,
	[28566] = true,
	[28582] = true,
	[47958] = true,
	[21453] = true,
	[21485] = true,
	[28662] = true,
	[46072] = true,
	[32805] = true,
	[42044] = true,
	[45145] = true,
	[21581] = true,
	[51347] = true,
	[50356] = true,
	[51475] = true,
	[48438] = true,
	[51571] = true,
	[50612] = true,
	[50644] = true,
	[50676] = true,
	[47671] = true,
	[30053] = true,
	[18832] = true,
	[22940] = true,
	[47927] = true,
	[50005] = true,
	[21269] = true,
	[19349] = true,
	[47064] = true,
	[19348] = true,
	[23068] = true,
	[42045] = true,
	[47192] = true,
	[29458] = true,
	[51348] = true,
	[50357] = true,
	[10055] = true,
	[50421] = true,
	[51476] = true,
	[54577] = true,
	[28825] = true,
	[17106] = true,
	[32250] = true,
	[50613] = true,
	[47576] = true,
	[50677] = true,
	[50709] = true,
	[47672] = true,
	[28611] = true,
	[51828] = true,
	[33446] = true,
	[6097] = true,
	[28358] = true,
	[21390] = true,
	[22429] = true,
	[5107] = true,
	[19392] = true,
	[46969] = true,
	[47001] = true,
	[21486] = true,
	[17066] = true,
	[50614] = true,
	[19352] = true,
	[42046] = true,
	[42078] = true,
	[28743] = true,
	[51349] = true,
	[28775] = true,
	[41251] = true,
	[51445] = true,
	[50454] = true,
	[48440] = true,
	[54585] = true,
	[2576] = true,
	[33191] = true,
	[47545] = true,
	[50646] = true,
	[50678] = true,
	[28729] = true,
	[47673] = true,
	[28295] = true,
	[42622] = true,
	[42377] = true,
	[30642] = true,
	[28797] = true,
	[28777] = true,
	[30102] = true,
	[49975] = true,
	[28765] = true,
	[28764] = true,
	[4332] = true,
	[28529] = true,
	[40928] = true,
	[18811] = true,
	[47130] = true,
	[42047] = true,
	[42079] = true,
	[22426] = true,
	[48644] = true,
	[50359] = true,
	[23072] = true,
	[51446] = true,
	[50455] = true,
	[54579] = true,
	[19137] = true,
	[17107] = true,
	[34215] = true,
	[50615] = true,
	[50647] = true,
	[50679] = true,
	[42527] = true,
	[54564] = true,
	[42591] = true,
	[50000] = true,
	[51862] = true,
	[51894] = true,
	[34352] = true,
	[23437] = true,
	[4336] = true,
	[34341] = true,
	[50008] = true,
	[46971] = true,
	[50072] = true,
	[42943] = true,
	[21503] = true,
	[34240] = true,
	[23709] = true,
	[44094] = true,
	[42080] = true,
	[31995] = true,
	[30985] = true,
	[50360] = true,
	[33696] = true,
	[50424] = true,
	[48410] = true,
	[48442] = true,
	[21691] = true,
	[40322] = true,
	[34216] = true,
	[47547] = true,
	[50648] = true,
	[50680] = true,
	[50712] = true,
	[21674] = true,
	[21623] = true,
	[51831] = true,
	[51863] = true,
	[33481] = true,
	[51927] = true,
	[40706] = true,
	[50466] = true,
	[49977] = true,
	[44894] = true,
	[31993] = true,
	[30124] = true,
	[42944] = true,
	[34345] = true,
	[29998] = true,
	[16956] = true,
	[44095] = true,
	[42081] = true,
	[29067] = true,
	[32341] = true,
	[50361] = true,
	[32373] = true,
	[28824] = true,
	[50457] = true,
	[54581] = true,
	[28518] = true,
	[48507] = true,
	[38309] = true,
	[50617] = true,
	[50649] = true,
	[50681] = true,
	[50713] = true,
	[42561] = true,
	[47708] = true,
	[51832] = true,
	[28505] = true,
	[51896] = true,
	[27703] = true,
	[40707] = true,
	[28569] = true,
	[19378] = true,
	[44895] = true,
	[50627] = true,
	[50074] = true,
	[42945] = true,
	[21618] = true,
	[50170] = true,
	[50202] = true,
	[44096] = true,
	[42082] = true,
	[31992] = true,
	[51353] = true,
	[50362] = true,
	[47063] = true,
	[32515] = true,
	[50458] = true,
	[48444] = true,
	[30903] = true,
	[42370] = true,
	[47517] = true,
	[47549] = true,
	[47581] = true,
	[50682] = true,
	[50714] = true,
	[16951] = true,
	[28795] = true,
	[28512] = true,
	[2577] = true,
	[48402] = true,
	[51929] = true,
	[51477] = true,
	[23668] = true,
	[50447] = true,
	[30995] = true,
	[16853] = true,
	[45983] = true,
	[42946] = true,
	[51162] = true,
	[40964] = true,
	[32278] = true,
	[54562] = true,
	[16954] = true,
	[23476] = true,
	[32342] = true,
	[50363] = true,
	[27705] = true,
	[23705] = true,
	[50459] = true,
	[54583] = true,
	[23666] = true,
	[48509] = true,
	[38311] = true,
	[50619] = true,
	[50651] = true,
	[48691] = true,
	[50715] = true,
	[50737] = true,
	[33888] = true,
	[33811] = true,
	[16952] = true,
	[45] = true,
	[44092] = true,
	[22416] = true,
	[35027] = true,
	[30991] = true,
	[44897] = true,
	[21457] = true,
	[30123] = true,
	[42947] = true,
	[28666] = true,
	[28747] = true,
	[32813] = true,
	[44098] = true,
	[35031] = true,
	[42116] = true,
	[51355] = true,
	[50364] = true,
	[30998] = true,
	[21391] = true,
	[48414] = true,
	[54584] = true,
	[30904] = true,
	[42372] = true,
	[47519] = true,
	[50620] = true,
	[50652] = true,
	[50684] = true,
	[50716] = true,
	[31996] = true,
	[50618] = true,
	[33421] = true,
	[51867] = true,
	[16059] = true,
	[16953] = true,
	[29066] = true,
	[49949] = true,
	[47935] = true,
	[27706] = true,
	[16854] = true,
	[16856] = true,
	[42948] = true,
	[40934] = true,
	[32263] = true,
	[50205] = true,
	[44099] = true,
	[35029] = true,
	[42117] = true,
	[51356] = true,
	[51388] = true,
	[30987] = true,
	[31997] = true,
	[50461] = true,
	[51516] = true,
	[30125] = true,
	[51580] = true,
	[38313] = true,
	[50621] = true,
	[50653] = true,
	[50685] = true,
	[42533] = true,
	[34381] = true,
	[50354] = true,
	[10054] = true,
	[27704] = true,
	[51900] = true,
	[45580] = true,
	[22417] = true,
	[40643] = true,
	[15196] = true,
	[50014] = true,
	[46977] = true,
	[38314] = true,
	[21490] = true,
	[35280] = true,
	[50174] = true,
	[22999] = true,
	[44100] = true,
	[20132] = true,
	[42118] = true,
	[51357] = true,
	[28779] = true,
	[50398] = true,
	[51453] = true,
	[50462] = true,
	[51517] = true,
	[52572] = true,
	[51581] = true,
	[47521] = true,
	[50622] = true,
	[50654] = true,
	[50686] = true,
	[33327] = true,
	[42566] = true,
	[36941] = true,
	[23192] = true,
	[24344] = true,
	[51901] = true,
	[51933] = true,
	[49919] = true,
	[49086] = true,
	[31404] = true,
	[42854] = true,
	[16855] = true,
	[40872] = true,
	[42950] = true,
	[51166] = true,
	[50175] = true,
	[32280] = true,
	[44101] = true,
	[45578] = true,
	[42119] = true,
	[51358] = true,
	[51390] = true,
	[19506] = true,
	[19032] = true,
	[50463] = true,
	[54587] = true,
	[50002] = true,
	[48513] = true,
	[45579] = true,
	[50623] = true,
	[50655] = true,
	[50687] = true,
	[48673] = true,
	[23345] = true,
	[42599] = true,
	[45577] = true,
	[49309] = true,
	[49] = true,
	[51934] = true,
	[22418] = true,
	[50975] = true,
	[23473] = true,
	[44901] = true,
	[38310] = true,
	[21475] = true,
	[42951] = true,
	[51167] = true,
	[46084] = true,
	[49185] = true,
	[44102] = true,
	[45574] = true,
	[28748] = true,
	[51359] = true,
	[51391] = true,
	[50400] = true,
	[35279] = true,
	[21667] = true,
	[21683] = true,
	[5976] = true,
	[34192] = true,
	[2587] = true,
	[50624] = true,
	[50656] = true,
	[48642] = true,
	[48674] = true,
	[42369] = true,
	[4344] = true,
	[30027] = true,
	[51871] = true,
	[18806] = true,
	[3427] = true,
	[29068] = true,
	[41249] = true,
	[49985] = true,
	[44902] = true,
	[46980] = true,
	[45037] = true,
	[42952] = true,
	[42984] = true,
	[148] = true,
	[10052] = true,
	[44103] = true,
	[41252] = true,
	[3428] = true,
	[51360] = true,
	[51392] = true,
	[24143] = true,
	[51456] = true,
	[54557] = true,
	[40267] = true,
	[38] = true,
	[34193] = true,
	[47524] = true,
	[45510] = true,
	[50657] = true,
	[48643] = true,
	[48675] = true,
	[18231] = true,
	[4334] = true,
	[41248] = true,
	[51872] = true,
	[42373] = true,
	[3426] = true,
	[22419] = true,
	[41255] = true,
	[42374] = true,
	[6384] = true,
	[21460] = true,
	[3148] = true,
	[28653] = true,
	[42985] = true,
	[50178] = true,
	[49187] = true,
	[41253] = true,
	[28733] = true,
	[28749] = true,
	[51361] = true,
	[51393] = true,
	[50402] = true,
	[51457] = true,
	[48420] = true,
	[54590] = true,
	[10056] = true,
	[42378] = true,
	[49998] = true,
	[50626] = true,
	[48612] = true,
	[33299] = true,
	[50722] = true,
	[6130] = true,
	[16060] = true,
	[42375] = true,
	[53] = true,
	[50661] = true,
	[6096] = true,
	[29069] = true,
	[20901] = true,
	[39757] = true,
	[40812] = true,
	[16857] = true,
	[41250] = true,
	[4333] = true,
	[40940] = true,
	[6795] = true,
	[11840] = true,
	[51266] = true,
	[47206] = true,
	[51330] = true,
	[51362] = true,
	[6136] = true,
	[2575] = true,
	[42376] = true,
	[50467] = true,
	[22196] = true,
	[19143] = true,
	[48517] = true,
	[47526] = true,
	[48581] = true,
	[48613] = true,
	[48645] = true,
	[50723] = true,
	[859] = true,
	[32570] = true,
	[51842] = true,
	[2579] = true,
	[51906] = true,
	[41254] = true,
	[19351] = true,
	[42371] = true,
	[50718] = true,
	[28606] = true,
	[50366] = true,
	[48685] = true,
	[42949] = true,
	[48677] = true,
	[32789] = true,
	[48683] = true,
	[48689] = true,
	[48687] = true,
	[51331] = true,
	[51363] = true,
	[51395] = true,
	[50404] = true,
	[44105] = true,
	[48422] = true,
	[35155] = true,
	[50030] = true,
	[50019] = true,
	[48671] = true,
	[48582] = true,
	[48614] = true,
	[29965] = true,
	[50724] = true,
	[34388] = true,
	[42604] = true,
	[51843] = true,
	[44093] = true,
	[51907] = true,
	[18824] = true,
	[29070] = true,
	[44091] = true,
	[49989] = true,
	[48718] = true,
	[16858] = true,
	[49994] = true,
	[40910] = true,
	[46057] = true,
	[32267] = true,
	[50468] = true,
	[44107] = true,
	[50333] = true,
	[51332] = true,
	[51364] = true,
	[35028] = true,
	[47078] = true,
	[40207] = true,
	[54561] = true,
	[15198] = true,
	[50365] = true,
	[48519] = true,
	[50711] = true,
	[50629] = true,
	[48615] = true,
	[50693] = true,
	[50725] = true,
	[50607] = true,
	[54586] = true,
	[51844] = true,
	[51876] = true,
	[50699] = true,
	[6120] = true,
	[22421] = true,
	[39728] = true,
	[49990] = true,
	[48999] = true,
	[54558] = true,
	[54578] = true,
	[50625] = true,
	[46058] = true,
	[47113] = true,
	[49191] = true,
	[51269] = true,
	[50705] = true,
	[51333] = true,
	[21606] = true,
	[51397] = true,
	[50688] = true,
	[50691] = true,
	[48424] = true,
	[50671] = true,
	[50667] = true,
	[30866] = true,
	[50630] = true,
	[48584] = true,
	[48616] = true,
	[50694] = true,
	[50726] = true,
	[21814] = true,
	[54580] = true,
	[54582] = true,
	[51877] = true,
	[50659] = true,
	[54559] = true,
	[50611] = true,
	[50721] = true,
	[30126] = true,
	[50023] = true,
	[16859] = true,
	[50180] = true,
	[50355] = true,
	[47515] = true,
	[50358] = true,
	[47146] = true,
	[16955] = true,
	[50650] = true,
	[51334] = true,
	[50343] = true,
	[35030] = true,
	[50453] = true,
	[50186] = true,
	[54563] = true,
	[31405] = true,
	[34167] = true,
	[48521] = true,
	[50470] = true,
	[49999] = true,
	[50663] = true,
	[50695] = true,
	[50727] = true,
	[50185] = true,
	[51849] = true,
	[49967] = true,
	[51878] = true,
	[50469] = true,
	[4330] = true,
	[22422] = true,
	[49960] = true,
	[49992] = true,
	[47978] = true,
	[42539] = true,
	[21479] = true,
	[21495] = true,
	[42991] = true,
	[32793] = true,
	[50182] = true,
	[50452] = true,
	[50061] = true,
	[51335] = true,
	[50344] = true,
	[51399] = true,
	[21639] = true,
	[50456] = true,
	[48426] = true,
	[42076] = true,
	[47239] = true,
	[54589] = true,
	[54591] = true,
	[50632] = true,
	[50664] = true,
	[50696] = true,
	[29983] = true,
	[17723] = true,
	[47579] = true,
	[54588] = true,
	[34488] = true,
	[50720] = true,
	[54576] = true,
	[30095] = true,
	[45869] = true,
	[30127] = true,
	[50025] = true,
	[16860] = true,
	[51480] = true,
	[50181] = true,
	[42992] = true,
	[40978] = true,
	[34382] = true,
	[51272] = true,
	[50689] = true,
	[51336] = true,
	[50345] = true,
	[51400] = true,
	[21652] = true,
	[51479] = true,
	[54565] = true,
	[50628] = true,
	[48672] = true,
	[47553] = true,
	[48511] = true,
	[50633] = true,
	[50665] = true,
	[50697] = true,
	[50729] = true,
	[54560] = true,
	[42609] = true,
	[51848] = true,
	[51880] = true,
	[51912] = true,
	[47552] = true,
	[54556] = true,
	[51354] = true,
	[28593] = true,
	[19402] = true,
	[51881] = true,
	[40883] = true,
	[45254] = true,
	[47085] = true,
	[40979] = true,
	[50460] = true,
	[50728] = true,
	[50658] = true,
	[40831] = true,
	[50346] = true,
	[51401] = true,
	[50730] = true,
	[50731] = true,
	[48428] = true,
	[35161] = true,
	[47666] = true,
	[42572] = true,
	[42077] = true,
	[49952] = true,
	[45255] = true,
	[50698] = true,
	[47661] = true,
	[48716] = true,
	[51817] = true,
	[30032] = true,
	[30048] = true,
	[51913] = true,
	[33215] = true,
	[30096] = true,
	[30112] = true,
	[47603] = true,
	[47667] = true,
	[46990] = true,
	[40884] = true,
	[50645] = true,
	[35020] = true,
	[6796] = true,
	[22428] = true,
	[16957] = true,
	[46374] = true,
	[19394] = true,
	[28608] = true,
	[51402] = true,
	[45296] = true,
	[48993] = true,
	[54567] = true,
	[21598] = true,
	[50690] = true,
	[51389] = true,
	[50603] = true,
	[23219] = true,
	[42483] = true,
	[42515] = true,
	[47662] = true,
	[34395] = true,
	[50717] = true,
	[48515] = true,
	[29950] = true,
	[51914] = true,
	[32521] = true,
	[47238] = true,
	[47918] = true,
	[19387] = true,
	[22431] = true,
	[50660] = true,
	[21481] = true,
	[47055] = true,
	[54566] = true,
	[48404] = true,
	[47151] = true,
	[50643] = true,
	[48580] = true,
	[28754] = true,
	[50348] = true,
	[51403] = true,
	[28802] = true,
	[40852] = true,
	[34401] = true,
	[30896] = true,
	[48406] = true,
	[48992] = true,
	[50604] = true,
	[50636] = true,
	[50668] = true,
	[50700] = true,
	[50732] = true,
	[42580] = true,
	[28621] = true,
	[30033] = true,
	[51170] = true,
	[30065] = true,
	[30081] = true,
	[47095] = true,
	[30878] = true,
	[51173] = true,
	[51481] = true,
	[23000] = true,
	[48583] = true,
	[47056] = true,
	[48408] = true,
	[34180] = true,
	[50692] = true,
	[16958] = true,
	[50464] = true,
	[50006] = true,
	[50349] = true,
	[51404] = true,
	[33303] = true,
	[51468] = true,
	[47156] = true,
	[32365] = true,
	[17102] = true,
	[48412] = true,
	[50605] = true,
	[42504] = true,
	[32333] = true,
	[48646] = true,
}
	
local modelPositions = {
	["Human"] = {0.1, 0, 0.05},
	["NightElf"] = {-0.2, 0, 0.15},
	["Gnome"] = {1, 0, 0.3},
	["Troll"] = {-0.4, 0, 0.05},
	["Tauren"] = {-0.4, 0, 0.05},
	["BloodElf"] = {-0.4, 0, 0.1},
	["Draenei"] = {-0.3, 0, 0.15},
	["Scourge"] = {-0.2, 0, 0.1},
	["Dwarf"] = {0.2, 0, 0.1},
	["Orc"] = {0, 0, 0.05},
}
--TODO: abhängig von rassen, geschlecht, offhand, 1h, 2h, misc
local slotModelPositions = {
	["Human"] = {
		["HeadSlot"] = {1.8, 0, -0.74, 0},
		["ShoulderSlot"] = {1.65, 0, -0.6, 0},
		["ChestSlot"] = {1.55, 0, -0.3, 0},
		["ShirtSlot"] = {1.55, 0, -0.3, 0},
		["TabardSlot"] = {1.55, 0, -0.3, 0},
		["WristSlot"] = {1.75, 0, -0.1, 0},
		["HandsSlot"] = {1.75, 0, -0.1, 0},
		["WaistSlot"] = {1.75, 0, -0.1, 0},
		["LegsSlot"] = {1.15, 0, 0.28, 0},	
		["FeetSlot"] = {1.5, 0, 0.5, 0},
		["BackSlot"] = {1, 0, -0.05, math.pi},
		["MainHandSlot"] = {0.6, 0, 0, math.pi * 0.2},
		["SecondaryHandSlot"] = {0.6, 0, 0, -math.pi * 0.2},
		["MainHandEnchantSlot"] = {0.6, 0, 0, math.pi * 0.2},
		["SecondaryHandEnchantSlot"] = {0.6, 0, 0, -math.pi * 0.2},
		["RangedSlot"] = {0.6, 0, 0, math.pi * 0.2},},
	["NightElf"] = {
		["HeadSlot"] = {3, 0, -0.82, 0},
		["ShoulderSlot"] = {2.45, 0, -0.6, 0},
		["ChestSlot"] = {2.65, 0, -0.3, 0},
		["ShirtSlot"] = {2.65, 0, -0.3, 0},
		["TabardSlot"] = {2.65, 0, -0.3, 0},
		["WristSlot"] = {2.75, 0, -0.13, 0},
		["HandsSlot"] = {2.75, 0, -0.13, 0},
		["WaistSlot"] = {2.75, 0, -0.13, 0},
		["LegsSlot"] = {1.79, 0, 0.32, 0},	
		["FeetSlot"] = {2.6, 0, 0.62, 0},
		["BackSlot"] = {1.7, 0, -0.05, math.pi},
		["MainHandSlot"] = {1.5, 0, 0, math.pi * 0.2},
		["SecondaryHandSlot"] = {1.5, 0, 0, -math.pi * 0.2},
		["MainHandEnchantSlot"] = {1.5, 0, 0, math.pi * 0.2},
		["SecondaryHandEnchantSlot"] = {1.5, 0, 0, -math.pi * 0.2},
		["RangedSlot"] = {1.5, 0, 0, math.pi * 0.2},},
	["Gnome"] = {
		["HeadSlot"] = {0.9, 0, -0.18, 0},
		["ShoulderSlot"] = {0.82, 0, 0, 0},
		["ChestSlot"] = {1.14, 0, 0.17, 0},
		["ShirtSlot"] = {1.14, 0, 0.17, 0},
		["TabardSlot"] = {1.14, 0, 0.17, 0},
		["WristSlot"] = {1.14, 0, 0.14, 0},
		["HandsSlot"] = {1, 0, 0.14, 0},
		["WaistSlot"] = {1.2, 0, 0.21, 0},
		["LegsSlot"] = {1, 0, 0.28, 0},	
		["FeetSlot"] = {1.1, 0, 0.34, 0},
		["BackSlot"] = {0.8, 0, 0.2, math.pi},
		["MainHandSlot"] = {0, 0, 0.1, math.pi * 0.3},
		["SecondaryHandSlot"] = {0, 0, 0.1, -math.pi * 0.3}, 
		["MainHandEnchantSlot"] = {0, 0, 0.1, math.pi * 0.3},
		["SecondaryHandEnchantSlot"] = {0, 0, 0.1, -math.pi * 0.3},
		["RangedSlot"] = {0, 0, 0.1, math.pi * 0.3},},
	--[[head 1.04, 0, -0.18
shoulder 0.82, 0, 0
chest 1.14, 0, 0.14
shirt
tabard
wrist
hands
wrists
legs 1.2, 0, 0.28
feet 1.16, 0, 0.4
mh 0, 0, 0.1
oh same?
	["axe"] = {0.2, 0, 0, math.pi * 0.4},
	["sword"] = {0.2, 0, 0, math.pi * 0.4},
	["mace"] = {0.2, 0, 0, math.pi * 0.4},
	["dagger"] = {1.1, 0, 0, math.pi * 0.3},
	["fistweapon"] = {0.9, 0, 0, math.pi * 0.3},
	["polearm"] = {0.2, 0, 0, math.pi * 0.2},
	["staff"] = {0.2, 0, 0, math.pi * 0.4},
	["fishingpole"] = {0.2, 0, 0, math.pi * 0.4},
	["bow"] = {0.2, 0, 0, math.pi * 0.4},
	["crossbow"] = {0.2, 0, 0, math.pi * 0.4},
	["gun"] = {0.2, 0, 0, math.pi * 0.4},
	["thrown"] = {0.2, 0, 0, math.pi * 0.4},
	["wand"] = {0.2, 0, 0, math.pi * 0.4},
	["offhand"] = {0.2, 0, 0, -math.pi * 0.4},
	["shield"] = {0.2, 0, 0, -math.pi * 0.4},]]--
}

local invSlots = {
	INVTYPE_HEAD = "HeadSlot",
	INVTYPE_SHOULDER = "ShoulderSlot",
	INVTYPE_BODY = "ShirtSlot",
	INVTYPE_CLOAK = "BackSlot",
	INVTYPE_CHEST = "ChestSlot",
	INVTYPE_ROBE = "ChestSlot",
	INVTYPE_WAIST = "WaistSlot",
	INVTYPE_LEGS = "LegsSlot",
	INVTYPE_FEET = "FeetSlot",
	INVTYPE_WRIST = "WristSlot",
	INVTYPE_2HWEAPON = "MainHandSlot",
	INVTYPE_WEAPON = "MainHandSlot",
	INVTYPE_WEAPONMAINHAND = "MainHandSlot",
	INVTYPE_WEAPONOFFHAND = "SecondaryHandSlot",
	INVTYPE_SHIELD = "SecondaryHandSlot",
	INVTYPE_HOLDABLE = "SecondaryHandSlot",
	INVTYPE_RANGED = "RangedSlot",
	INVTYPE_RANGEDRIGHT = "RangedSlot",
	INVTYPE_THROWN = "RangedSlot",
	INVTYPE_HAND = "HandsSlot",
	INVTYPE_TABARD = "TabardSlot",
}

local itemSlots = {
	"HeadSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"MainHandSlot",
	"SecondaryHandSlot",
	"MainHandEnchantSlot", --TODO: erlaubt?
	"SecondaryHandEnchantSlot",
	"RangedSlot",
}

local allInventorySlots = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
	"RangedSlot",
	"AmmoSlot"
}

for k, v in pairs(itemSlots) do
	if v ~= "MainHandEnchantSlot" and v ~= "SecondaryHandEnchantSlot" then
		myadd.availableMogsUpdateNeeded[v] = true
	end
end

local idToSlot = {
	[1] = "HeadSlot",
	[3] = "ShoulderSlot",
	[15] = "BackSlot",
	[5] = "ChestSlot",
	[4] = "ShirtSlot",
	[19] = "TabardSlot",
	[9] = "WristSlot",
	[10] = "HandsSlot",
	[6] = "WaistSlot",
	[7] = "LegsSlot",
	[8] = "FeetSlot",
	[16] = "MainHandSlot",
	[17] = "SecondaryHandSlot",
	--[1???] = "MainHandEnchantSlot", --TODO: erlaubt?
	--[1???] = "SecondaryHandEnchantSlot",
	[18] = "RangedSlot",
}

--These IDs are referring to the inventoryType in the itemdata , not to be confused with itemSlotIDs
slotToIDs = {
	["HeadSlot"] = {1},
	["ShoulderSlot"] = {3},
	["BackSlot"] = {16},
	["ChestSlot"] = {5, 20}, --chest, robe
	["ShirtSlot"] = {4},
	["TabardSlot"] = {19},
	["WristSlot"] = {9},
	["HandsSlot"] = {10},
	["WaistSlot"] = {6},
	["LegsSlot"] = {7},
	["FeetSlot"] = {8},
	["MainHandSlot"] = {13, 21, 17}, --1h, mh, 2h
	["SecondaryHandSlot"] = {13, 22, 17, 14, 23}, --1h, oh, 2h, shields, holdable/tomes --contains twohand for warris?
	["RangedSlot"] = {15, 25, 26}, --bow, thrown, ranged right(gun, wands, crossbow)
};

-- {class, subclass}
catToClassSubclass = {
	["Rüstung Stoff"] = {4, 1},
	["Rüstung Leder"] = {4, 2},
	["Rüstung Schwere Rüstung"] = {4, 3},
	["Rüstung Platte"] = {4, 4},
	["Rüstung Verschiedenes"] = {4, 0},
	["Waffe Dolche"] = {2, 15},
	["Waffe Faustwaffen"] = {2, 13},
	["Waffe Einhandäxte"] = {2, 0},
	["Waffe Einhandstreitkolben"] = {2, 4},
	["Waffe Einhandschwerter"] = {2, 7},
	["Waffe Stangenwaffen"] = {2, 6},
	["Waffe Stäbe"] = {2, 10},
	["Waffe Zweihandäxte"] = {2, 1},
	["Waffe Zweihandstreitkolben"] = {2, 5},
	["Waffe Zweihandschwerter"] = {2, 8},
	["Waffe Angelruten"] = {2, 20},
	["Waffe Verschiedenes"] = {2, 14},
	["Rüstung Schilde"] = {4, 6},
	["Verschiedenes Plunder"] = {15, 0},
	["Waffe Bogen"] = {2, 2},
	["Waffe Armbrüste"] = {2, 18},
	["Waffe Schusswaffen"] = {2, 3},
	["Waffe Wurfwaffen"] = {2, 16},
	["Waffe Zauberstäbe"] = {2, 19},
	["Rüstung Buchbände"] = {4, 7},
	["Rüstung Götzen"] = {4, 8},
	["Rüstung Totems"] = {4, 9},
	["Rüstung Siegel"] = {4, 10},
	
}

slotCategories = {
	["HeadSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["ShoulderSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["BackSlot"] = {"Rüstung Stoff"},
	["ChestSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["ShirtSlot"] = {"Rüstung Verschiedenes"},
	["TabardSlot"] = {"Rüstung Verschiedenes"},
	["WristSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["HandsSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["WaistSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["LegsSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["FeetSlot"] = {"Rüstung Stoff", "Rüstung Leder", "Rüstung Schwere Rüstung", "Rüstung Platte", "Rüstung Verschiedenes"},
	["MainHandSlot"] = {"Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
		"Waffe Stangenwaffen", "Waffe Stäbe", "Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Angelruten", "Waffe Verschiedenes"},
	["SecondaryHandSlot"] = {"Rüstung Schilde", "Rüstung Verschiedenes", "Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter",
		"Waffe Zweihandäxte", "Waffe Zweihandstreitkolben", "Waffe Zweihandschwerter", "Waffe Verschiedenes", "Verschiedenes Plunder"},
	["RangedSlot"] = {"Waffe Bogen", "Waffe Armbrüste",	"Waffe Schusswaffen", "Waffe Wurfwaffen", "Waffe Zauberstäbe"},
	["MainHandEnchantSlot"] = {},
	["SecondaryHandEnchantSlot"] = {},
};


function table.pack(...)
  return { n = select("#", ...), ... }
end

local function amHelperTable(printResult, tab)
	for k, v in pairs(tab) do
		printResult = printResult .. tostring(k) .. ": "
		if type(v) == "table" then
			printResult = printResult .. "{"
			printResult = amHelperTable(printResult, v)
			printResult = printResult .. "} "
		else
			printResult = printResult .. tostring(v) .. ", "
		end
    end
	
	return printResult
end

--TODO: handle args? pack and unpack?
local function am(...)
	local args = table.pack(...)
	local printResult = ""
	for i=1,args.n do
		if type(args[i]) == "table" then
			printResult = printResult .. "{"
			printResult = amHelperTable(printResult, args[i])
			printResult = printResult .. "} "
		else
			printResult = printResult .. tostring(args[i]) .. " "
		end
    end
    DEFAULT_CHAT_FRAME:AddMessage(printResult)
end

function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function DeepCompare(t1,t2,ignore_mt)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
	local v2 = t2[k1]
	if v2 == nil or not DeepCompare(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
	local v1 = t1[k2]
	if v1 == nil or not DeepCompare(v1,v2) then return false end
	end
	return true
end

local function contains(tab, element)
  for _, value in pairs(tab) do
    if value == element then
      return true
    end
  end
  return false
end

function length(tab)
  local count = 0
  for _ in pairs(tab) do count = count + 1 end
  return count
end


local waitTable = {}
local waitFrame = nil
local updateInterval, timeSinceLastUpdate = 0.5, 0 --optional
local maxParallelTasks = 100

function MyWaitFunction(delay, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
		return false
	end
	if(waitFrame == nil) then
		waitFrame = CreateFrame("Frame",nil, UIParent)
		waitFrame:SetScript("OnUpdate", function(self, elapse)
			local count = #waitTable
			if count == 0 then
				waitFrame:Hide()
				return
			end
			if count > maxParallelTasks then --Only x at a time, REMOVE IF TASKS ARE SUPPOSED TO BE EXECUTED IN PARALLEL!!
				count = maxParallelTasks
			end
			--[[
			timeSinceLastUpdate = timeSinceLastUpdate + elapse
			if false then
			if timeSinceLastUpdate < updateInterval then
			timeSinceLastUpdate = timeSinceLastUpdate + elapse
			return false
			else
			timeSinceLastUpdate = 0
			elapse = updateInterval
			end
			end
			]]--
			local i = 1

			while(i<=count) do
				local waitRecord = tremove(waitTable,i)
				local d = tremove(waitRecord,1)
				local f = tremove(waitRecord,1)
				local p = tremove(waitRecord,1)
				if(d>elapse) then
					tinsert(waitTable,i,{d-elapse,f,p})
					i = i + 1;
				else
					count = count - 1
					f(unpack(p))
				end
			end
		end)
	end
	tinsert(waitTable, 1, {delay,func,{...}})
	if not waitFrame:IsShown() then
		waitFrame:Show()
	end
	return true
end

ToApiSet = function(set)
	local apiSet = {}
	for slot, id in pairs(set) do
		if slot ~= "MainHandEnchantSlot" and slot ~= "SecondaryHandEnchantSlot" then
			assert(contains(itemSlots, slot))
			assert(type(id) == "number" or (type(id) == "boolean" and not id))
			
			local slotID, _ = GetInventorySlotInfo(slot)
			local itemID = id
			if type(itemID) ~= "number" then
				itemID = 0
			end
			apiSet[slotID] = itemID
		end
	end
	return apiSet
end

RegisterListener = function(field, frame)
	if not listeners[field] then listeners[field] = {} end
	listeners[field][frame] = true
end

UpdateListeners = function(field)
	--assert(listeners[field]) --TODO oder einfach nichts tun, wenn keine listener?
	if not listeners[field] then return end
	
	for k, v in pairs(listeners[field]) do
		k.update(field)
	end
end

SetCosts = function(copper)
	assert(type(copper) == "number")
	
	costs = copper
	UpdateListeners("costs") --moneyframe, applybutton, 
end

SetSaveSetCosts = function(copper, points)
	assert(type(copper) == "number")
	assert(type(points) == "number")
	
	saveSetCosts.copper = copper
	saveSetCosts.points = points
	UpdateListeners("saveSetCosts")
end
	
	
	
SetBalance = function(points)
	assert(type(points) == "number")
	
	balance = points
	UpdateListeners("balance") --balanceFrame
end

SetSlotAndCategory = function(slot, cat)
	assert((slot == nil and cat == nil) or contains(itemSlots, slot))
	assert((slot == nil and cat == nil) or contains(slotCategories[slot], cat))
	
	if slot == selectedSlot and cat == selectedCategory then return end
	
	selectedSlot = slot
	selectedCategory = cat
	
	BuildList()
	SetPage(1)
	
	UIDropDownMenu_SetText(catDDM, selectedCategory or "Category") -- Selection of ddms can only be set, when opened, so we set the visible text here and the selection gets sat on the dynamic creation on opening ddm
	CloseDropDownMenus()
	
	UpdateListeners("selectedSlot") --itemFrames, 
	--UpdateListeners("selectedCategory") --
end


SetCurrentChanges = function(set)
	assert(type(set) == "table")
	for slot, id in pairs(set) do
		assert(contains(itemSlots, slot))
		assert(type(id) == "number" or (type(id) == "boolean" and not id))
	end
	
	--do changehistory stuff here	
	
	MyAddonDB.currentChanges = deepCopy(set)
	
	UpdateListeners("currentChanges") --itemslotframes, model, savebutton, applybutton?, savetosetbutton?, slotmodels (wenn border zur aktuellen auswahl eingebaut wird)

	RequestPriceOfApplyingUpdate()
	--API.GetPriceOfSaving(setId, set)
	RequestPriceOfSavingUpdate(MyAddonDB.selectedSet, MyAddonDB.currentChanges)
end

SetCurrentChangesSlot = function(slot, id)
	assert(contains(itemSlots, slot))
	assert(type(id) == "number" or (type(id) == "boolean" and not id) or id == nil)	
	if not MyAddonDB.currentChanges then MyAddonDB.currentChanges = {} end
	
	if MyAddonDB.currentChanges[slot] == id then return end
	
	--do changehistory stuff here	
	
	MyAddonDB.currentChanges[slot] = id
	
	UpdateListeners("currentChanges")
	
	RequestPriceOfApplyingUpdate()
	--API.GetPriceOfSaving(setId, set) TODO
	RequestPriceOfSavingUpdate(MyAddonDB.selectedSet, MyAddonDB.currentChanges)
end

SetAvailableMogs = function(slot, items)
	--am("Updated available mogs for:", slot)
	--myadd.availableMogsUpdateNeeded[slot] = false --taken out to update everything each time the tmog interface opens, since one mightve unlocked smth in the meantime
	myadd.availableMogs[slot] = {}
	for k, v in pairs(items) do
		myadd.availableMogs[slot][v] = true
	end
	if windowFrame:IsShown() then
		--UpdateItemSlots() -- needed to show correct border --TODO: listener stuff für available mogs einführen
		if slot == selectedSlot then
			local itemID = GetInventoryItemID("player", GetInventorySlotInfo(slot))
			FunctionOnItemInfo(itemID, function()				
				local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
				local itemFullType = itemType.." "..itemSubType
				if selectedCategory ~= itemFullType then
					SetSlotAndCategory(selectedSlot, itemFullType)
				end
			end)
		end
	end
	
	UpdateListeners("availableMogs") --TODO itemslots, 
end

SetCurrentMogs = function(mogs)
	assert(mogs["inventory"] and type(mogs["inventory"]) == "table" and mogs["container"] and type(mogs["container"]) == "table")
	--if not MyAddonDB.currentMogs then MyAddonDB.currentMogs = {} end
	
	--if MyAddonDB.currentChanges[slot] == id then return end --"deep value compare of tables function" ? nah
	
	wipe(currentMogs["inventory"])
	wipe(currentMogs["container"])
	
	for slotID, itemID in pairs(mogs["inventory"]) do
		local id = itemID
		if id == 0 then id = false end --stick to false for hidden in own data?!
		currentMogs["inventory"][idToSlot[slotID]] = id
	end
	
	for containerID, containerContents in pairs(mogs["container"]) do
		currentMogs["container"][containerID] = {}
		for containerSlotID, itemID in pairs(containerContents) do
			currentMogs["container"][containerID][containerSlotID] = itemID
		end
	end
	--TODO: dies uptodate halten für alle möglichen itembewegungen? simples taschenaddon finden um abzugucken?
		--> einfach auf den events update triggern. vielleicht methode schreiben, die zeitpunkt setzt wann sie update requestet und bei neuem aufruf davor den zeitpunkt verschiebt, um multiple requests auf einmal zu vermeiden
	
	UpdateListeners("currentMogs") --itemframes, model? überlegen wie hier currentmogs und currentchanges zusammenkommen
														-- zeigen wir generell unmogable zeug  in currentset an oder wird das abgesehen von nem roten rahmen komplett rausgeschmissen aus der anzeige?
														-- zu klären ob ungeeignete items eines sets neben der roten umrandung auch als icon und am model angezeigt werden oder dort ignoriert werden, der rest kann einfach schonmal eingebaut werden?
	
	if windowFrame:IsShown() then
		RequestPriceOfApplyingUpdate() --TODO nötig hier oder sollte es manuell aufgerufen werden?
	end
	--wann wird currentmogs abgefragt? bei login! aber optimalerweise nicht bei jedem equigment oder item change, sondern das muss ich selber tracken!?
	-- -> sehr schwierig fehlerfrei zu machen? wie kann man da sicherheit haben? wenigstens beim frame öffnen nochmal abfragen? -> das erstmal auf jedenfall
	-- vielleicht für jede mog auch den itemlink des gemoggten items speichern?
	-- wenn lokales tracking funktionieren sollte, dann mogs nur erneut abfragen nach einer antwort von requestapplytransmog und applyset?
	--API.GetPriceOfSaving(setId, set) TODO
	--RequestPriceOfSavingUpdate(MyAddonDB.selectedSet, MyAddonDB.currentChanges)
end

SetSelectedSet = function(id)
	--assert existierende setid or nil?
	if id == nil then
		MyAddonDB.selectedSet = nil
		--SetCurrentChanges({})
	else
		MyAddonDB.selectedSet = id
		--SetCurrentChanges(mySets[id]["transmogs"])
	end
			
	UpdateListeners("selectedSet") -- savebutton, applybutton, upgradeserverset button, maybe setddm	
	RequestPriceOfSavingUpdate(MyAddonDB.selectedSet, MyAddonDB.currentChanges)
end

SelectSet = function(id)
	if not MyAddonDB.sets[id] then
		SetSelectedSet(nil)
		SetCurrentChanges(currentMogs["inventory"])		
		SetSlotAndCategory(nil, nil)
	else
		if id ~= MyAddonDB.selectedSet then
			SetSlotAndCategory(nil, nil)
		end	
		SetSelectedSet(id)
		SetCurrentChanges(MyAddonDB.sets[id]["transmogs"])
	end
end

--[==[

--]==]
SetSets = function(setData)
	--am(setData)
	local sets = {}
	for _, set in pairs(setData) do
		--assert blabla
		local id = set["id"]
		sets[id] = deepCopy(set)
		sets[id]["id"] = nil
		--am(sets[id])
		for slotID, itemID in pairs(set["transmogs"]) do
			if itemID == 0 then itemID = false end
			sets[id]["transmogs"][idToSlot[slotID]] = itemID
			sets[id]["transmogs"][slotID] = nil
		end
	end
	
	MyAddonDB.sets = sets
	
	SelectSet(MyAddonDB.selectedSet)
end

local requestCounterS = 0
RequestSets = function(id)
	API.GetSets():next(function(setData)
		SetSets(setData)
		if id then
			SelectSet(id)
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterSR
RequestSetRename = function(id, newName)	
	API.RenameSet(id, newName):next(function(answer)
		if answer.success == true then
			--rename methode aufrufen oder alle sets erneut abfragen?
			RequestSets()
		else
			--grund für rename fehlschlag? sendet der server ne error message?
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterSD
RequestSetDelete = function(id)		
	API.RemoveSet(id):next(function(answer)
		if answer.success == true then
			--rename methode aufrufen oder alle sets erneut abfragen?
			RequestSets()
		else
			--grund für rename fehlschlag? sendet der server ne error message?
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterSS
RequestSetSave = function(id, set)		
	API.SaveSet(id, ToApiSet(set)):next(function(answer)
		if answer.success == true then
			--rename methode aufrufen oder alle sets erneut abfragen?
			RequestSets(id)		--Kinda hacky to make RequestSetAdd choose the newly added set, when it exists
			RequestBalance()
		else
			--grund für rename fehlschlag? sendet der server ne error message?
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterSU
RequestSetUpgrade = function(id, set)		
	API.UpgradeSet(id, ToApiSet(set)):next(function(answer)
		if answer.success == true then
			--rename methode aufrufen oder alle sets erneut abfragen?
			RequestSets()		--Kinda hacky to make RequestSetAdd choose the newly added set, when it exists
			RequestBalance()
		else
			--grund für rename fehlschlag? sendet der server ne error message?
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterSA
RequestSetAdd = function(name, set)		
	API.AddSet(name):next(function(id)
		-- add set methode aufrufen oder alle sets erneut abfragen (Validate methode?)
		RequestSetSave(id, set)
	end):catch(function(err)
		print("An error occured:", err)
	end)
end


local requestCounterPOS = 0
RequestPriceOfSavingUpdate = function(id, set)
	if not id or not set then 
		SetSaveSetCosts(0, 0) --TODO: hier richtig aufgehoben oder lieber zB in SetSelectedSet
		return
	end
	requestCounterPOS = requestCounterPOS + 1
	local requestID = requestCounterPOS
	API.GetPriceOfSaving(id, ToApiSet(set)):next(function(price)
		if requestID == requestCounterPOS then
			--print("Saving/Upgrading set would cost: " .. GetCoinTextureString(price.copper) .. " + " .. price.points .. " moggies")
			SetSaveSetCosts(price.copper, price.points)
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterAS = 0
RequestApplySet = function(id)
	API.ApplySet(id):next(function(answer)
		PlaySound(6555)
		PlayApplyAnimations()
		RequestCurrentMogsUpdate()
	end):catch(function(err)
		print("An error occured:", err)
	end)
end	

local requestCounterAM = {}
RequestAvailableMogsUpdate = function(slot)
	local slotID = GetInventorySlotInfo(slot)
	requestCounterAM[slotID] = (requestCounterAM[slotID] or 0) + 1
	local requestID = requestCounterAM[slotID]
	API.GetAvailableTransmogs(slotID):next(function(items)
		if requestID == requestCounterAM[slotID] then
			SetAvailableMogs(slot, items)
		else
			--am("This answer to RequestAvailableMogsUpdate("..slot..") is outdated, a newer Update was already requested.")
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end


local requestCounterCM = 0
RequestCurrentMogsUpdate = function()
	requestCounterCM = requestCounterCM + 1
	local requestID = requestCounterCM
	API.GetCurrentTransmogs():next(function(mogs)
		if requestID == requestCounterCM then
			SetCurrentMogs(mogs)
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterACC = 0
RequestApplyCurrentChanges = function()
	requestCounterACC = requestCounterACC + 1
	local requestID = requestCounterACC
	API.ApplyTransmogs(ToApiSet(MyAddonDB.currentChanges)):next(function(answer)
		if requestID == requestCounterACC then
			--TODO: what to do here? was wäre eine sinvollere antwort? liste mit slots und true oder fehlergründen?
			--falls success: coolen sound, itemframe extra animation? model animation?
			--PlaySound(888)
			PlaySound(6555)
			PlayApplyAnimations()
			RequestCurrentMogsUpdate()
			RequestPriceOfApplyingUpdate() --TODO falls nicht in setcurrentmogs drinnen
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end	

local requestCounterB = 0
RequestBalance = function()
	requestCounterB = requestCounterB + 1
	local requestID = requestCounterB
	API.GetBalance():next(function(bal)
		if requestID == requestCounterB then
			print("You balance is: " .. bal.points .. " moggies.")
			--balance = bal["points"] --TODO: listener + setter etc
			--balanceFrame.update()
			SetBalance(bal.points)
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end

local requestCounterPOA = 0
RequestPriceOfApplyingUpdate = function()
	requestCounterPOA = requestCounterPOA + 1
	local requestID = requestCounterPOA
	API.GetPriceOfApplying(ToApiSet(MyAddonDB.currentChanges)):next(function(price)
		if requestID == requestCounterPOA then
			--print("Current changes would cost: " .. GetCoinTextureString(price.copper))
			SetCosts(price.copper)
		end
	end):catch(function(err)
		print("An error occured:", err)
	end)
end


local function canReceiveTransmog(mogTarget, mogSource, slot)
	local canMog = false
	--local targetSubtype = select(7,GetItemInfo(mogTarget))
	--local sourceSubtype = select(7,GetItemInfo(mogSource))
	--if targetSubtype == sourceSubtype then canMog = true end
	if myadd.availableMogs[slot] and myadd.availableMogs[slot][mogSource]
			or mogSource == false or mogSource == nil then
		canMog = true
	end

	return canMog
end

local infosReceivedBeforeThrottle = 0
local timeOfLastItemReceived

local itemInfoWaitFrame
local MyIIWaitFunction = function(delay, tooltip, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
		return false
	end
	if (itemInfoWaitFrame == nil) then
		itemInfoWaitFrame = CreateFrame("Frame",nil, UIParent)
		itemInfoWaitFrame.waitTable = {}
		itemInfoWaitFrame.maxParallelTasks = 1
		itemInfoWaitFrame:SetScript("OnUpdate", function(self, elapse)
			local allTablesEmpty = true
			for tooltip, waitTable2 in pairs(itemInfoWaitFrame.waitTable) do
				local count = length(waitTable2)
				if count > 0 then
					allTablesEmpty = false
				end
				--am(count)
				if count > itemInfoWaitFrame.maxParallelTasks then
					count = itemInfoWaitFrame.maxParallelTasks
				end
				local i = 1

				while(i<=count) do
					local waitRecord = tremove(waitTable2,i)
					local d = tremove(waitRecord,1)
					local f = tremove(waitRecord,1)
					local p = tremove(waitRecord,1)
					if(d>elapse) then
						tinsert(waitTable2,i,{d-elapse,f,p})
						i = i + 1;
					else
						count = count - 1
						
				--am(tooltip:GetName(), length(waitTable2))
						f(unpack(p))
					end
				end
			end
			if allTablesEmpty then
				itemInfoWaitFrame:Hide()
				am("MyIIWaitFunction is done.")
				am("Received "..infosReceivedBeforeThrottle.." items.")
				infosReceivedBeforeThrottle = 0
				timeOfLastItemReceived = nil
			end
		end)
	end
	if not itemInfoWaitFrame.waitTable[tooltip] then itemInfoWaitFrame.waitTable[tooltip] = {} end
	tinsert(itemInfoWaitFrame.waitTable[tooltip], 1, {delay,func,{...}})
	if not itemInfoWaitFrame:IsShown() then
		itemInfoWaitFrame:Show()
	end
	return true
end

local function ClearAllOutstandingOIIF()
	if itemInfoWaitFrame then
		itemInfoWaitFrame.waitTable = {}
	end
end
	
	
local function OnItemInfoHelper(itemID, startTime, tooltip, tooltipSet, func, ...)
	if not startTime then
		startTime = GetTime()
	end
	
	if GetItemInfo(itemID) then
		timeOfLastItemReceived = GetTime()
		infosReceivedBeforeThrottle = infosReceivedBeforeThrottle + 1		
		am("Received", itemID, "after", string.format("%.2f", GetTime() - startTime), "seconds from tooltip:", tooltip:GetName())
		func(...)
	else		
		if timeOfLastItemReceived and GetTime() - timeOfLastItemReceived > 5 and infosReceivedBeforeThrottle > 0 then
			am("Throttle after "..infosReceivedBeforeThrottle.."items.")
			infosReceivedBeforeThrottle = 0
		end
		
		if GetTime() - startTime > 20 then
			--am("FunctionOnItemInfo: Could not retrieve item info for "..itemID..".", GetItemInfo(itemID))			
			--return
		end
		
		if not tooltipSet then
			tooltip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
		end
		
		MyIIWaitFunction(0, tooltip, OnItemInfoHelper, itemID, startTime, tooltip, true, func, ...)
	end
end



local tooltips = {} --{ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3} --GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3
local tooltipAmount = 20
for i=1,tooltipAmount do
	tooltips[i] = CreateFrame("GameTooltip", "ItemInfoGatherer"..i)
end



local foiiCount = 0
FunctionOnItemInfo = function(itemID, func, ...)
	if((type(itemID)~="number" and type(itemID)~="string") or type(func)~="function") then
		return false;
	end
	
	if GetItemInfo(itemID) then
		--am(itemID.." do the thing " .. (maxTries-retriesLeft))
		func(...)
	else
		--ShoppingTooltip3:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
		--MyWaitFunction(0.2*(maxTries-retriesLeft+1), OnItemInfoHelper, itemID, func, maxTries, retriesLeft-1, ...)
		foiiCount = (foiiCount + 1) % length(tooltips)
		--am(tooltips[foiiCount+1]:GetName())
		MyIIWaitFunction(0, tooltips[foiiCount+1] , OnItemInfoHelper, itemID, nil, tooltips[foiiCount+1], false, func, ...)
	end
end

local SetTooltip = function(frame, text)
	if not frame or not text then return end
	frame:HookScript("OnEnter", function(self)		
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(text)
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end


local function canBeEnchanted(itemSlot)
	local itemID = MyAddonDB.currentChanges[itemSlot]
	--local itemID = GetInventoryItemID("player", GetInventorySlotInfo(itemSlot))
	if not itemID then return false end
	local itemSubType = select(7, GetItemInfo(itemID))
	--am(itemSubType)
	return contains({"Dolche", "Faustwaffen", "Einhandäxte", "Einhandstreitkolben", "Einhandschwerter",
		"Stangenwaffen", "Stäbe", "Zweihandäxte", "Zweihandstreitkolben", "Zweihandschwerter"}, itemSubType)	
end


	
UpdateItemSlots = function()
	for k, v in pairs(itemSlotFrames) do
		v.update()		
	end
end

local function ShowMeleeWeapons(mod, mainHand, offHand) --Displays Weapons mainHand and offHand on model mod as well as possible (i.e. can't display dualwielding weapons, if the player can't dualwield)
	if not (mainHand or offHand) or not mod then return end
	
	local mhSubType, mhInvType, ohSubType, ohInvType
	if mainHand then
		mhSubType, _, mhInvType = select(7,GetItemInfo(mainHand))
		if not mhSubType then
			FunctionOnItemInfo(mainHand, ShowMeleeWeapons, mod, mainHand, offHand)
			return
		end
	end
	if offHand then
		ohSubType, _, ohInvType = select(7,GetItemInfo(offHand))
		if not ohSubType then
			FunctionOnItemInfo(offHand, ShowMeleeWeapons, mod, mainHand, offHand)
			return
		end
	end
	
	local titanGrip
	if select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1 then
		titanGrip = true
	end		
	--if offHand == nil or
	--	((contains({"Dolche", "Faustwaffen", "Einhandäxte", "Einhandstreitkolben", "Einhandschwerter"}, mhSubtype) or (contains({"Zweihandäxte", "Zweihandstreitkolben", "Zweihandschwerter"}, mhSubType) and titanGrip))
	--		and contains({"Schilde", "Rüstung Verschiedenes"})
	--am(mhSubType, mhInvType)
	if mainHand then
		mod:TryOn(20083)
		mod:TryOn(mainHand)
		if offHand then
			if ((mhInvType ~= "INVTYPE_2HWEAPON" and (ohInvType == "INVTYPE_SHIELD" or ohInvType == "INVTYPE_HOLDABLE"))
						or (IsSpellKnown(674) and mhInvType ~= "INVTYPE_2HWEAPON" and ohInvType ~= "INVTYPE_2HWEAPON")
						or (titanGrip and not contains({"Waffe Stangenwaffen", "Waffe Stäbe", "Waffe Angelruten"}, mhSubType) and not contains({"Waffe Stangenwaffen", "Waffe Stäbe", "Waffe Angelruten"}, ohSubType)))
						and not (mhSubType == "Verschiedenes" and mhInvType ~= "INVTYPE_WEAPON") then --Function that checks if oh can be worn with mh?
				mod:TryOn(offHand)
			else
				--am("MyAdddon: Cannot preview "..select(1, GetItemInfo(offHand)).." in offhand with "..select(1, GetItemInfo(mainHand)).." in mainhand.")
			end
		end
	else
		if (ohInvType == "INVTYPE_SHIELD" or ohInvType == "INVTYPE_HOLDABLE" or ohInvType == "INVTYPE_WEAPONOFFHAND") then
			mod:TryOn(offHand)
		elseif IsSpellKnown(674) and (ohInvType == "INVTYPE_WEAPON" or (titanGrip and (contains({"Zweihandschwerter", "Zweihandstreitkolben", "Zweihandäxte"}, ohSubType)))) then
			mod:TryOn(20083)
			mod:TryOn(45630)
			mod:TryOn(offHand)
		else
			--am("MyAdddon: Cannot preview "..select(1, GetItemInfo(offHand)).." in offhand.")
		end
	end
end

--[==[
local function UpdateModel(showRanged)
	if not model:IsShown() then am("UpdateModel: Model is not shown.") end
	local itemsToShow = {}
	for k, v in pairs(itemSlots) do
		local id, link
		if v == "MainHandEnchantSlot" then
			link = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
			if link then
				_, id = link:match("item:(%d+):(%d+)")
			end
		elseif v == "SecondaryHandEnchantSlot" then
			link = GetInventoryItemLink("player", GetInventorySlotInfo("SecondaryHandSlot"))
			if link then
				_, id = link:match("item:(%d+):(%d+)")
			end
		else
			id = GetInventoryItemID("player", GetInventorySlotInfo(v))
		end
		id = tonumber(id)
		
		if id and not (id == 0) then
			if MyAddonDB.currentChanges[v] == nil then
				itemsToShow[v] = id
			elseif MyAddonDB.currentChanges[v] then
				itemsToShow[v] = MyAddonDB.currentChanges[v]
			end
		end		
	end
	
	model:Undress()
	
	for k, v in pairs(itemsToShow) do
		if not contains({"MainHandSlot", "MainHandEnchantSlot", "SecondaryHandEnchantSlot", "SecondaryHandSlot", "RangedSlot"}, k) then
			model:TryOn(v)
		end
	end
	
	local mh = itemsToShow["MainHandSlot"]
	if mh and itemsToShow["MainHandEnchantSlot"] then mh = "item:"..mh..":"..itemsToShow["MainHandEnchantSlot"] end
	local oh = itemsToShow["SecondaryHandSlot"]
	if oh and itemsToShow["SecondaryHandEnchantSlot"] then oh = "item:"..oh..":"..itemsToShow["SecondaryHandEnchantSlot"] end
	
	if selectedSlot == "RangedSlot" then
		if itemsToShow["RangedSlot"] then
			model:TryOn(itemsToShow["RangedSlot"])
		end		
	else
		ShowMeleeWeapons(model, mh, oh)
	end
end
--]==]


local function TryOn(mod, itemID, slot, retriesLeft) --TODO: anders handlen when enchant slot ausgewählt ist? 
	--am(retriesLeft)
	slot = slot or nil
	local maxTries = 3
	retriesLeft = retriesLeft or maxTries
	--itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent
	if not itemID then return end
	if not (slot == "MainHandEnchantSlot" or slot == "SecondaryHandEnchantSlot") and GetItemInfo(itemID) == nil then
		if retriesLeft < 1 then 
			am("Could not retrieve item info for "..itemID..".")
			return
		end
		GameTooltip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
		MyWaitFunction(0.1*(maxTries-retriesLeft+1), TryOn, mod, itemID, slot, retriesLeft-1)
	else
		local itemSubtype, _, itemSlot = select(7,GetItemInfo(itemID))
		
		if slot == "MainHandEnchantSlot" or slot == "SecondaryHandEnchantSlot" or invSlots[itemSlot] then
			local titanGrip = false
			if select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1 then
				titanGrip = true
			end		
			--Capture Unequipable stuff and end here
			if slot == "SecondaryHandSlot" and itemSlot == "INVTYPE_2HWEAPON" and not (titanGrip and (itemSubtype == "Zweihandschwerter" or itemSubtype == "Zweihandstreitkolben" or itemSubtype == "Zweihandäxte")) then return end			
			
			--Save in currentChanges	
			if not MyAddonDB.currentChanges then MyAddonDB.currentChanges = {} end
			
			--TODO: Decide if equipping 2h removes offhand from set (if not: probably problems with only offhand getting shown if not specifically handled)
			--titangrib sets would get automatically edited just by equipping on a non titangrib char! have to find other solution (hiding+blocking offhand and handling in "apply" function?)
			--if itemSlot == "INVTYPE_2HWEAPON" and not (titanGrip and (itemSubtype == "Zweihandschwerter" or itemSubtype == "Zweihandstreitkolben" or itemSubtype == "Zweihandäxte")) then
				--MyAddonDB.currentChanges["SecondaryHandSlot"] = nil
				--MyAddonDB.currentChanges["SecondaryHandEnchantSlot"] = nil
			--end
			
			if slot then
				--MyAddonDB.currentChanges[slot] = itemID
				SetCurrentChangesSlot(slot, itemID)
			else
				--MyAddonDB.currentChanges[invSlots[itemSlot]] = itemID --TODO: besser nicht  mehr erlauben?
				SetCurrentChangesSlot(invSlots[itemSlot], itemID)
			end
			
			local showRanged
			if slot == "RangedSlot" or invSlots[itemSlot] == "RangedSlot" then
				showRanged = true
			end
			--UpdateModel(showRanged)
			--UpdateItemSlots() --TODO: wird so viel öfter aufgerufen als nötig, aber ohne werden slots nicht geupdatet bis zur nächsten aktion, falls die items nicht gecached waren
		else
			am("Can't equip spezified item.")
		end
	end
end


--TODO: mit addon load on demand und modulen arbeiten. so wird alles beim addon load geladen
myadd.AddEnchant = function(visualID, enchantID, spellID)
	if not (visualID and enchantID) then return false end
	--am(visualID..", "..enchantID)
	myadd.enchants = myadd.enchants or {}
	if myadd.enchants[visualID] then
		table.insert(myadd.enchants[visualID]["enchantIDs"], enchantID)
	else 
		myadd.enchants[visualID] = {["enchantIDs"] = {enchantID}}
	end
	myadd.enchantInfo = myadd.enchantInfo or {}
	myadd.enchantInfo["visualID"] = myadd.enchantInfo["visualID"] or {}
	myadd.enchantInfo["spellID"] = myadd.enchantInfo["spellID"] or {}
	
	myadd.enchantInfo["visualID"][enchantID] = visualID
	myadd.enchantInfo["spellID"][enchantID] = spellID
end

myadd.AddColor = function(color, itemID)
	--am(itemID.." is "..color)
	--FunctionOnItemInfo(itemID, function()
		myadd.colors = myadd.colors or {}
		myadd.colors[color] = myadd.colors[color] or {}
		myadd.colors[color][itemID] = true
	--end)
	FunctionOnItemInfo(itemID, function()
		if GetItemInfo(itemID) then
			am("Do Stuff with "..itemID)
		else
			am("Don't have item info despite foii executing!")
		end
	end)
end

myadd.AddItem = function(displayID,itemID,class,subClass,inventoryType,quality,requiredLevel,allowableRace,allowableClass,allowableFaction)
	myadd.displayIDs = myadd.displayIDs or {}
	if myadd.displayIDs[displayID] and contains(myadd.displayIDs[displayID]["itemIDs"], itemID) then return end
	if myadd.displayIDs[displayID] then
		table.insert(myadd.displayIDs[displayID]["itemIDs"], itemID)
	else 
		myadd.displayIDs[displayID] = {["itemIDs"] = {itemID}}
	end
	myadd.itemInfo = myadd.itemInfo or {} --TODO: den krma nicht tausendmal aufrufen? oder wird das eh rauscompiliert
	myadd.itemInfo["displayID"] = myadd.itemInfo["displayID"] or {}
	myadd.itemInfo["class"] = myadd.itemInfo["class"] or {}
	myadd.itemInfo["subClass"] = myadd.itemInfo["subClass"] or {}
	myadd.itemInfo["inventoryType"] = myadd.itemInfo["inventoryType"] or {}
	--myadd.itemInfo["quality"] = myadd.itemInfo["quality"] or {}
	--myadd.itemInfo["requiredLevel"] = myadd.itemInfo["requiredLevel"] or {}
	--myadd.itemInfo["allowableRace"] = myadd.itemInfo["allowableRace"] or {}
	--myadd.itemInfo["allowableClass"] = myadd.itemInfo["allowableClass"] or {}
	--myadd.itemInfo["allowableFaction"] = myadd.itemInfo["allowableFaction"] or {}
		
	myadd.itemInfo["displayID"][itemID] = displayID
	myadd.itemInfo["class"][itemID] = class
	myadd.itemInfo["subClass"][itemID] = subClass
	myadd.itemInfo["inventoryType"][itemID] = inventoryType
	--myadd.itemInfo["quality"][itemID] = quality
	--myadd.itemInfo["requiredLevel"][itemID] = requiredLevel
	--myadd.itemInfo["allowableRace"][itemID] = allowableRace
	--myadd.itemInfo["allowableClass"][itemID] = allowableClass
	--myadd.itemInfo["allowableFaction"][itemID] = allowableFaction
end

local function CheckListStatusOnItemInfo(displayID, itemID, remainingTries)
	local remainingTries = remainingTries or 20
	if remainingTries == 0 then return end
	
	for k, v in pairs(myadd.displayIDs[displayID]["itemIDs"]) do
		if not GetItemInfo(v) then
			--am(displayID, ": missing info for ", v)
			FunctionOnItemInfo(v, CheckListStatusOnItemInfo, displayID, itemID, remainingTries - 1)
			return
		end
	end
	local names = ""
	
	--am(displayID, "found all infos POG")
	
	local nameFilterString = string.lower(nameFilterTextField:GetText())
	local eligibleDisplayID = false
	for k, v in pairs(myadd.displayIDs[displayID]["itemIDs"]) do	
		local name = GetItemInfo(v)
		names = names .. name .. ", "
		if name then
			name = string.lower(name)
			if not nameFilter or not nameFilterString or nameFilterString == "" or string.find(name, nameFilterString) then
				eligibleDisplayID = true
			end
		end
	end
	--am(names, eligibleDisplayID)
	
	--am(length(list))
	if not eligibleDisplayID then		
		for k, v in pairs(list) do
			if v == itemID then
				tremove(list, k)
				--am("removed ", { GetItemInfo(itemID) })
				if k < page * modelsPerPage + 1 then
					SetPage(page)
				end
			end
		end
	end
	
	--am(length(list))
	--UpdateSlotModels()
	--FunctionOnItemInfo(am("Missing itemInfo for one of ", myadd.displayIDs[displayID]["itemIDs"]) end
end

BuildList = function()
	ClearAllOutstandingOIIF()
	wipe(list)
	collectgarbage()
	
	local nameFilterString = string.lower(nameFilterTextField:GetText())
	--am(selectedSlot, selectedCategory, onlyMogableFilter)
	
	if not (selectedSlot and selectedCategory) then return end
	
	if selectedSlot == "MainHandEnchantSlot" or selectedSlot == "SecondaryHandEnchantSlot" then
		local weaponID = 49778 --TODO: dummy wert abhängig von klasse/waffenfertigkeiten, muss auch noch in weapon show fix gemacht werden
		if selectedSlot == "MainHandEnchantSlot" then
			local mainHand = GetInventoryItemID("player", GetInventorySlotInfo("MainHandSlot"))
			if MyAddonDB.currentChanges["MainHandSlot"] then
				weaponID = MyAddonDB.currentChanges["MainHandSlot"]
			elseif mainHand then
				weaponID = mainHand
			end
		elseif selectedSlot == "SecondaryHandEnchantSlot" then
			local offHand = GetInventoryItemID("player", GetInventorySlotInfo("SecondaryHandSlot"))
			if MyAddonDB.currentChanges["SecondaryHandSlot"] then
				weaponID = MyAddonDB.currentChanges["SecondaryHandSlot"]
			elseif offHand then
				weaponID = offHand
			end
		end
		
		for k, v in pairs(myadd.enchants) do
			table.insert(list, "item:"..weaponID..":"..v["enchantIDs"][1])
		end
		return
	end
	
	local done = false
	for k, v in pairs(myadd.displayIDs) do
		done = false
		if contains(slotToIDs[selectedSlot], myadd.itemInfo["inventoryType"][v["itemIDs"][1]]) --Only show items with the right inventorytype, class and subclass
				and catToClassSubclass[selectedCategory][1] == myadd.itemInfo["class"][v["itemIDs"][1]]
				and catToClassSubclass[selectedCategory][2] == myadd.itemInfo["subClass"][v["itemIDs"][1]] then			
			for k2, v2 in pairs(v["itemIDs"]) do
				local name = GetItemInfo(v2)
				if name then name = string.lower(name) end
				if not done and (not onlyMogableFilter or --[==[myadd.warmaneItems[v2]--]==](myadd.availableMogs[selectedSlot] and myadd.availableMogs[selectedSlot][v2])) --TODO: Do in Filter
							and (not name or not nameFilter or nameFilterString == nil or nameFilterString == "" or (name ~= nil and string.find(name, nameFilterString))) then
					table.insert(list, v2)
					done = true
					CheckListStatusOnItemInfo(k, v2)
				end
			end
		end
	end
	--wipe(list)
	--BuildListHelper()
	table.sort(list, function(a, b)
		return b < a --to sort by itemlvl i.e., wed need to find lowest lvl per display id first?
	end)
	
	--for k, v in pairs(list) do
	--	am(v)
	--end
	--am(length(myadd.availableMogs[selectedSlot]))
	
	--am(length(list))
	--am(list)
	local count = 0
	for k, v in pairs(list) do
		--am(v)
		local disp = myadd.itemInfo["displayID"][v]
		count = count + length(myadd.displayIDs[disp]["itemIDs"])
	end
	am(count)
	--[[for k, v in pairs(myadd.enchants) do
		local str = "EnchantVisual "..k..": "
		for a, b in pairs(v["enchantIDs"]) do
			str = str..b..", "
		end
		am(str)
	end]]
end

local function UndressSlot(itemSlot)
	--if not MyAddonDB.currentChanges then MyAddonDB.currentChanges = {} end
	--MyAddonDB.currentChanges[itemSlot] = false
	SetCurrentChangesSlot(itemSlot, false)
	--UpdateItemSlots()
	
	--EquipSet(mod, MyAddonDB.currentChanges)
end

local function SavePosition()
	local point, _, relativePoint, xOfs, yOfs = windowFrame:GetPoint()
	if not MyAddonDB.Position then 
		MyAddonDB.Position = {}
	end
	MyAddonDB.Position.point = point
	MyAddonDB.Position.relativePoint = relativePoint
	MyAddonDB.Position.xOfs = xOfs
	MyAddonDB.Position.yOfs = yOfs	
end

local function LoadPosition()
	if MyAddonDB.Position then
		windowFrame:SetPoint(MyAddonDB.Position.point,UIParent,MyAddonDB.Position.relativePoint,MyAddonDB.Position.xOfs,MyAddonDB.Position.yOfs)
	else
		windowFrame:SetPoint("CENTER", UIParent, "CENTER")
	end
end

local function CreateModelFrame()
	model = CreateFrame("DressUpModel", "MyAddonCharacterModel", bar)
	model:SetSize(bar:GetWidth()-22, bar:GetHeight()-22)
	model:SetPoint("TOPLEFT", bar ,"TOPLEFT", 12, -12)
	model:SetPoint("BOTTOMRIGHT", bar ,"BOTTOMRIGHT", -10, 10)
	model:EnableMouse()
	model:EnableMouseWheel()
	
	
	local _, race = UnitRace("player")
	model.standardPos = modelPositions[race] or {0, 0, 0}
	model.posBackup = {0, 0, 0} --Pos must be set to 0, 0, 0 on hide, otherwise camera gets translated on next show. 
	model.texRatio, model.texCutoff = 3/4, 0	
	
	model.seqtime = 0
	model.seq = -1
	
	model.ChangeSequence = function(number)
		assert(type(number) == "number")
		am("Set Model Animation to "..number..".")
		model.seq = number
		model.seqtime = 0
	end
	
	local multi = 1000
	local onUpdateNormal = function(self, elapsed)
		if model.seq < 0 or model.seq > 506 then return end
		model.seqtime = model.seqtime + elapsed*multi
		model:SetSequenceTime(model.seq, model.seqtime)
	end
	
	local onUpdateTurning = function(self, elapsed)
		onUpdateNormal(self, elapsed)
		local curX, curY = GetCursorPosition()
		local dif = curX - model.x
		model:SetFacing(model.facing+dif/100) --TODO: scale with screen resolution for consistent behaviour?
	end
	
	local turning, dragging = false, false
	model:SetScript("OnMouseDown", function(self, button)
		CloseDropDownMenus()
		if button == "LeftButton" then
			if dragging then return end
			turning = true
			model.x, model.y = GetCursorPosition()
			model.facing = model:GetFacing()
			self:SetScript("OnUpdate", onUpdateTurning)
		elseif button == "RightButton" then
			if turning then return end
			dragging = true
		end
	end)
	
	model:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			turning = false
		elseif button == "RightButton" then
			dragging = false
		end
		if not turning and not dragging then self:SetScript("OnUpdate", onUpdateNormal) end		
	end)
	
	model:SetScript("OnShow", function(self)
		model:SetPosition(model.posBackup[1], model.posBackup[2], model.posBackup[3])
		self:SetScript("OnUpdate", onUpdateNormal)
		model.update()
		
		--troll stuff
		local weekday, month, day, year = CalendarGetDate()
		if month == 4 and day == 1 and math.random() > 0.5 then model:SetModel("CREATURE/Tauren_MountedCanoe/Tauren_MountedCanoe.m2") end
		if math.random() > 0.999 then model.seq = 126 end
	end)
	model:SetScript("OnHide", function(self)
		turning, dragging = false, false
		model.posBackup[1], model.posBackup[2], model.posBackup[3] = model:GetPosition() 
		model:SetPosition(model.standardPos[1], model.standardPos[2], model.standardPos[3])
		--[[model.texRatio, model.texCutoff = 3/4, 0
		model.BGTopLeft:SetHeight(model:GetHeight()*model.texRatio)		
		model.BGTopLeft:SetTexCoord(model.texCutoff,1,0,1) --(0,0,middleCutOff,1,1,0,1,1)
		model.BGBottomLeft:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomLeft:SetTexCoord(model.texCutoff,1,0,0.5-model.texCutoff*2)
		model.BGTopRight:SetHeight(model:GetHeight()*model.texRatio)
		model.BGTopRight:SetTexCoord(0,0.95-model.texCutoff,0,1)
		model.BGBottomRight:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomRight:SetTexCoord(0,0.95-model.texCutoff,0,0.5-model.texCutoff*2)]] --Only needed if full reset is desired on hide
		--self:SetScript("OnUpdate", nil) --Happens automatically
	end)
	--TODO: -maybe on enter self.controllFrame:Show() etc
	
	--TODO: Bei langeweile am Fakezoom weiterarbeiten
	model:SetScript("OnMouseWheel", function(self, delta)
		--TODO: Scroll auf bestimmte Körperstellen ermöglichen?
		--camera is in (2, 0, 0?) depends on race and gets translated depending on modelposition at the point of init/show
		--model:SetModelScale(1.5)
		--model:SetPosition(0, 0, -0.5)
		local scale = model:GetModelScale()
		local x, y, z = model:GetPosition()
		--am(x)
		if delta < 0 and x > 0.1 then
			--if x > 0.65 then z = z + x / 20 end
			x = x - 0.05
			model.texRatio = model.texRatio - 0.014
			model.texCutoff = model.texCutoff-0.01
		elseif delta > 0 and x < 1 then
			x = x + 0.05
			--if x > 0.65 then z = z - x / 20 end
			model.texRatio = model.texRatio + 0.014
			model.texCutoff = model.texCutoff+0.01
		end
		--Hängt von der Kameraposition und der Hintergrundtexture ab und braucht daher auch pro rasse/geschlecht abgestimmte parameter
		--Nach oben hin auch weniger punktflucht als zur seite? bei himmel gut, bei wänden und co weniger
		--local middleCutOff = model.texCutoff * model.texRatio        --   Strahlensatz: 1 / model.texRatio = 	model.texCutoff / middleCutOff
		model:SetPosition(x, y, z)
		model.BGTopLeft:SetHeight(model:GetHeight()*model.texRatio)		
		model.BGTopLeft:SetTexCoord(model.texCutoff,1,0,1) --(0,0,middleCutOff,1,1,0,1,1)
		model.BGBottomLeft:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomLeft:SetTexCoord(model.texCutoff,1,0,0.5-model.texCutoff*2)
		model.BGTopRight:SetHeight(model:GetHeight()*model.texRatio)
		model.BGTopRight:SetTexCoord(0,0.95-model.texCutoff,0,1)
		model.BGBottomRight:SetHeight(model:GetHeight()*(1-model.texRatio))
		model.BGBottomRight:SetTexCoord(0,0.95-model.texCutoff,0,0.5-model.texCutoff*2)
	end)
	
	
	model:SetUnit("player")
	model:SetPosition(0.1, 0, 0)
	
	local custom = false
	local _, race = UnitRace("player")
	--if race == "Gnome" then race = "Dwarf" end
	--elseif race == "Troll" then race = "Orc" end
	local path = "Interface\\DressUpFrame\\"
	if race == "Gnome" or race == "Troll" or race == "Orc" then
		--race = "Nightborne"--"Nightborne"--"TROLL"--"Worgen"--"HighmountainTauren"
		path = "Interface\\AddOns\\_myaddon\\images\\"
		--model.texRatio = 4/5 --spillt textur über
		--model:SetPosition(0.1, 0, -0.1)
	end
	
	model.BGTopLeft = model:CreateTexture(nil, "BACKGROUND")
	model.BGTopLeft:SetWidth(model:GetWidth()*4/5)
	model.BGTopLeft:SetHeight(model:GetHeight()*model.texRatio)
	model.BGTopLeft:SetPoint("TOPLEFT", model, "TOPLEFT", 0, 0)
	model.BGTopLeft:SetTexture(path.."DressUpBackground-"..race.."1")
	
	model.BGTopRight = model:CreateTexture(nil, "BACKGROUND")
	model.BGTopRight:SetWidth(model:GetWidth()*1/5)
	model.BGTopRight:SetHeight(model:GetHeight()*model.texRatio)
	model.BGTopRight:SetPoint("TOPRIGHT", model, "TOPRIGHT", 0, 0)
	model.BGTopRight:SetTexture(path.."DressUpBackground-"..race.."2")	
	model.BGTopRight:SetTexCoord(0,0.95,0,1)
	
	model.BGBottomLeft = model:CreateTexture(nil, "BACKGROUND")
	model.BGBottomLeft:SetWidth(model:GetWidth()*4/5)
	model.BGBottomLeft:SetHeight(model:GetHeight()*(1-model.texRatio))
	model.BGBottomLeft:SetPoint("BOTTOMLEFT", model, "BOTTOMLEFT", 0, 0)
	model.BGBottomLeft:SetTexture(path.."DressUpBackground-"..race.."3")
	model.BGBottomLeft:SetTexCoord(0,1,0,0.5)
	
	model.BGBottomRight = model:CreateTexture(nil, "BACKGROUND")
	model.BGBottomRight:SetWidth(model:GetWidth()*1/5)
	model.BGBottomRight:SetHeight(model:GetHeight()*(1-model.texRatio))
	model.BGBottomRight:SetPoint("BOTTOMRIGHT", model, "BOTTOMRIGHT", 0, 0)
	model.BGBottomRight:SetTexture(path.."DressUpBackground-"..race.."4")
	model.BGBottomRight:SetTexCoord(0,0.95,0,0.5)
	
	model.update = function(trigger)
		if not model:IsShown() then am("UpdateModel: Model is not shown."); return end
		
		if trigger and trigger == "selectedSlot" and model.lastUpdateSlot and --only update for slotChanges, when its needed to show different weapons
			((model.lastUpdateSlot ~= "RangedSlot" and selectedSlot ~= "RangedSlot") or
			 (model.lastUpdateSlot == "RangedSlot" and selectedSlot == "RangedSlot")) then
			return
		end		
		model.lastUpdateSlot = selectedSlot
		
	
		local itemsToShow = {}
		for k, v in pairs(itemSlots) do
			local id, link
			if v == "MainHandEnchantSlot" then
				link = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
				if link then
					_, id = link:match("item:(%d+):(%d+)")
				end
			elseif v == "SecondaryHandEnchantSlot" then
				link = GetInventoryItemLink("player", GetInventorySlotInfo("SecondaryHandSlot"))
				if link then
					_, id = link:match("item:(%d+):(%d+)")
				end
			else
				id = GetInventoryItemID("player", GetInventorySlotInfo(v))
			end
			id = tonumber(id)
			
			if id and not (id == 0) then
				if MyAddonDB.currentChanges[v] == nil then
					itemsToShow[v] = id
				elseif MyAddonDB.currentChanges[v] then
					itemsToShow[v] = MyAddonDB.currentChanges[v]
				end
			end		
		end
		
		model:Undress()
		
		for k, v in pairs(itemsToShow) do
			if not contains({"MainHandSlot", "MainHandEnchantSlot", "SecondaryHandEnchantSlot", "SecondaryHandSlot", "RangedSlot"}, k) then
				model:TryOn(v)
			end
		end
		
		local mh = itemsToShow["MainHandSlot"]
		if mh and itemsToShow["MainHandEnchantSlot"] then mh = "item:"..mh..":"..itemsToShow["MainHandEnchantSlot"] end
		local oh = itemsToShow["SecondaryHandSlot"]
		if oh and itemsToShow["SecondaryHandEnchantSlot"] then oh = "item:"..oh..":"..itemsToShow["SecondaryHandEnchantSlot"] end
		
		if selectedSlot == "RangedSlot" then
			if itemsToShow["RangedSlot"] then
				model:TryOn(itemsToShow["RangedSlot"])
			end		
		else
			ShowMeleeWeapons(model, mh, oh)
		end
	end
	
	RegisterListener("currentChanges", model)
	RegisterListener("selectedSlot", model)
	RegisterListener("inventory", model)
	
	model:Show()
end




local function CreateMeAButton(parent, width, height, text,
			upTex, upLeft, upUp, upRight, upDown,
			downTex, downLeft, downUp, downRight, downDown,
			highlightTex, highLeft, highUp, highRight, highDown,
			disabledTex, disLeft, disUp, disRight, disDown)
			
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(width, height)
	if text then b:SetText(text) end
	b:SetNormalFontObject("GameFontNormal")
	b:SetHighlightFontObject("GameFontHighlight")
	b:SetDisabledFontObject("GameFontDisable")
	
	local ntex = b:CreateTexture()
	ntex:SetTexture(upTex or "Interface/Buttons/UI-Panel-Button-Up")
	ntex:SetTexCoord(upLeft, upRight, upUp, upDown)
	ntex:SetAllPoints()	
	b:SetNormalTexture(ntex)	
	
	local ptex = b:CreateTexture()
	ptex:SetTexture(downTex or "Interface/Buttons/UI-Panel-Button-Down")
	ptex:SetTexCoord(downLeft, downRight, downUp, downDown)
	ptex:SetAllPoints()
	b:SetPushedTexture(ptex)

	local htex = b:CreateTexture()
	htex:SetTexture(highlightTex or "Interface/Buttons/UI-Panel-Button-Highlight")
	htex:SetTexCoord(highLeft, highRight, highUp, highDown)
	htex:SetAllPoints()
	b:SetHighlightTexture(htex)
	
	local dtex = b:CreateTexture()
	dtex:SetTexture(disabledTex or "Interface/Buttons/UI-Panel-Button-Disabled")
	dtex:SetTexCoord(disLeft, disRight, disUp, disDown)
	dtex:SetAllPoints()
	b:SetDisabledTexture(dtex)
	return b
end

local function CreateMeATextButton(parent, width, height, text)
	local b = CreateMeAButton(parent, width, height, text,
		"Interface/Buttons/UI-Panel-Button-Up", 0, 0, 0.625, 0.6875,
		"Interface/Buttons/UI-Panel-Button-Down", 0, 0, 0.625, 0.6875,
		"Interface/Buttons/UI-Panel-Button-Highlight", 0, 0, 0.625, 0.6875,
		"Interface/Buttons/UI-Panel-Button-Disabled", 0, 0, 0.625, 0.6875)
	return b
end

local function CreateMeACustomTexButton(parent, width, height, tex, left, up, right, down)
	local b = CreateMeAButton(parent, width, height, nil,
		"Interface/Buttons/UI-EmptySlot", 9/64, 9/64, 54/64,54/64,
		"Interface/Buttons/UI-EmptySlot-White", 9/64, 9/64, 54/64,54/64,
		"Interface/Buttons/ButtonHilight-Square", 0, 0, 1, 1,
		"Interface/Buttons/UI-EmptySlot-Disabled", 9/64, 9/64, 54/64,54/64)
		--[[		"Interface/Buttons/UI-SILVER-BUTTON-UP", 9/64, 9/64, 54/64,54/64,
		"Interface/Buttons/UI-SILVER-BUTTON-Down", 0, 0, 0.625, 0.6875,
		"Interface/Buttons/ButtonHilight-Square", 0, 0, 1, 1,
		"Interface/Buttons/UI-SILVER-BUTTON-Disabled", 0, 0, 0.625, 0.6875)]]
	
	b:GetHighlightTexture():SetAlpha(0.8)
	
	if not tex then return b end
	
	--b.btex = b:CreateTexture(nil, "BACKGROUND")
	--b.btex:SetTexture("Interface/Buttons/UI-EmptySlot")
	--b.btex:SetTexCoord(9/64,  54/64, 9/64,  54/64)
	--b.btex:SetAllPoints()
	--b.btex:Hide()
	--local scale = -0.09
	--b.btex:SetPoint("TOPLEFT", b ,"TOPLEFT", -width*scale, height*scale)
	--b.btex:SetPoint("BOTTOMRIGHT", b ,"BOTTOMRIGHT", width*scale, -height*scale)
	
	
	b.ctex = b:CreateTexture(nil, "OVERLAY")
	b.ctex:SetTexture(tex)
	b.ctex:SetTexCoord(left, right, up, down)
	local scale = -0.14
	b.ctex:SetPoint("TOPLEFT", b ,"TOPLEFT", -width*scale, height*scale)
	b.ctex:SetPoint("BOTTOMRIGHT", b ,"BOTTOMRIGHT", width*scale, -height*scale)
	--am(b.ctex:GetPoint(1))
	--ctex:SetAllPoints()	
	--b.ctex:SetBlendMode("BLEND")
	
	return b
end


local function UpdateSlotModels()
	local _, race = UnitRace("player")
	if not slotModelPositions[race] then race = "Human" end
	local pos = slotModelPositions[race][selectedSlot] or {0, 0, 0, 0}
	for i=1,modelsPerPage do
		if not list[modelsPerPage*(page-1)+i] then
			slotModels[i]:Hide()
		else
			slotModels[i]:Show()
			slotModels[i]:SetPosition(pos[1], pos[2], pos[3])
			slotModels[i]:SetFacing(pos[4])
			if selectedCategory == "Waffe Bogen" then slotModels[i]:SetFacing(-pos[4]) end
			--if nakedSlotModels then
			--slotModels[i]:TryOn(2530) -- Slotrule reset
			slotModels[i].item = list[modelsPerPage*(page-1)+i]
			slotModels[i]:Undress()
			if selectedSlot == "MainHandSlot" or selectedSlot == "MainHandEnchantSlot" then
				ShowMeleeWeapons(slotModels[i], list[modelsPerPage*(page-1)+i], nil)
			elseif selectedSlot == "SecondaryHandSlot" or selectedSlot == "SecondaryHandEnchantSlot" then
				ShowMeleeWeapons(slotModels[i], nil, list[modelsPerPage*(page-1)+i])
				--	slotModels[i]:TryOn(2530) -- Slotrule reset
				--	if select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1 then slotModels[i]:TryOn(20083) end -- titangrip
				--	slotModels[i]:TryOn(2942) -- 1h into mainhand
			else
				slotModels[i]:TryOn(list[modelsPerPage*(page-1)+i])
			end
			--else 
				--EquipSet(slotModels[i], MyAddonDB.currentChanges)
			--end
			slotModels[i].item = list[modelsPerPage*(page-1)+i]				-- start loop from behind since mywaitfunction works as a stack if limited to x parallel functions
			--FunctionOnItemInfo(list[modelsPerPage*(page-1)+i], function() -- Fixes non cached items showing in wrong hand, but also fails if one scrolls too fast and overloads the tooltip itemfino trick with too many parallel requests
				--if selectedSlot == "SecondaryHandSlot" or selectedSlot == "SecondaryHandEnchantSlot" then -- make weapon show in offhand
				--	slotModels[i]:TryOn(2530) -- Slotrule reset
				--	if select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1 then slotModels[i]:TryOn(20083) end -- titangrip
				--	slotModels[i]:TryOn(2942) -- 1h into mainhand
				--end
				--slotModels[i]:TryOn(list[modelsPerPage*(page-1)+i])
			--end)
		end
	end
end


SetPage = function(num)
	if not list then
		page = 1
		pageTextField:SetNumber(page)
		return
	end
	--local pageOld = page
	
	if num > math.ceil(table.getn(list) / 8) then
		page = math.ceil(table.getn(list) / 8)
	else
		page = num
	end
	
	if page < 1 then
		page = 1
	end
	
	pageTextField:SetNumber(page)	
	--if not pageOld == page then
	UpdateSlotModels()
	--end--TODO: geschieht jetzt oft doppelt?
end

local function CreateSlotModelFrame(parent, name, width, height)
	local m = CreateFrame("DressUpModel", name, parent)
	m:SetSize(width, height)
		
	m:EnableMouse()
	m:EnableMouseWheel()
	
	m.backTex = m:CreateTexture(nil, "OVERLAY", nil,-7)
	m.backTex:SetTexture("Interface\\AddOns\\_myaddon\\images\\Transmogrify")
	local scale = 0.06
	m.backTex:SetPoint("TOPLEFT", m ,"TOPLEFT", -width*scale, height*scale)
	m.backTex:SetPoint("BOTTOMRIGHT", m ,"BOTTOMRIGHT", height*scale, -width*scale)
	local left, top, right, bottom = 5/512, 131/512, 95/512,247/512
	m.backTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	
	m.highTex = m:CreateTexture(nil, "HIGHLIGHT", nil,-7)
	m.highTex:SetTexture("Interface\\AddOns\\_myaddon\\images\\Transmogrify")
	local scale = 0.025
	m.highTex:SetPoint("TOPLEFT", m ,"TOPLEFT", -width*scale-3, height*scale)
	m.highTex:SetPoint("BOTTOMRIGHT", m ,"BOTTOMRIGHT", width*scale-3, -height*scale)
	local left, top, right, bottom = 104/512, 225/512, 190/512,336/512
	m.highTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	m.highTex:SetBlendMode("ADD")
	m.highTex:SetAlpha(0.2)
	
	
	m:SetUnit("player")
		
	m.seqtime = 0
	m.seq = 15
	
	--m.ChangeSequence = function(number)
	--	am("Set Model Animation to "..number..".")
	--	m.seq = number
	--	m.seqtime = 0
	--end
	
	local multi = 1000
	m.onUpdateNormal = function(self, elapsed)
		if m.seq < 0 or m.seq > 506 then return end
		m.seqtime = m.seqtime + elapsed*multi
		m:SetSequenceTime(m.seq, m.seqtime)
	end
	m.ShowTooltip = function(self)
		local iid = list[8*(page-1)+tonumber(m:GetName())]
		
		if selectedSlot == "MainHandEnchantSlot" or selectedSlot == "SecondaryHandEnchantSlot" then
			local enchantID, spellID, mogEnchantName
			_, enchantID = iid:match("item:(%d+):(%d+)")
			enchantID = tonumber(enchantID)				
			visualID = myadd.enchantInfo["visualID"][enchantID]
			
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
			GameTooltip:ClearLines()
			for k, v in pairs(myadd.enchants[visualID]["enchantIDs"]) do
				spellID = myadd.enchantInfo["spellID"][v]
				mogEnchantName = GetSpellInfo(spellID)		
				GameTooltip:AddLine(mogEnchantName, 1, 1, 1)
			end
			GameTooltip:Show()
			return
		end
		
		local dispID = myadd.itemInfo["displayID"][iid]
		local itemNames = {}
		local itemNameColors = {}
		for k, v in pairs(myadd.displayIDs[dispID]["itemIDs"]) do
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
			GameTooltip:SetHyperlink("item:"..v)
			local mytext =_G["GameTooltipTextLeft"..1]
			--am( mytext:GetText())
			tinsert(itemNames, mytext:GetText())--.." - "..v)
			tinsert(itemNameColors, { mytext:GetTextColor() })
		end
		--am(itemNames)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
		GameTooltip:ClearLines()
		for i=1,length(itemNames) do
			GameTooltip:AddLine(itemNames[i], itemNameColors[i][1], itemNameColors[i][2], itemNameColors[i][3])
		end
		GameTooltip:Show()
	end
	
	m:SetScript("OnUpdate", m.onUpdateNormal)
	m:SetScript("OnMouseDown", function()
		local iid = list[8*(page-1)+tonumber(m:GetName())] --TODO: weniger scuffed lösung finden?

		if iid then
			am("")
			if selectedSlot == "MainHandEnchantSlot" or selectedSlot == "SecondaryHandEnchantSlot" then
				local itemID, enchantID = iid:match("item:(%d+):(%d+)")
				iid = tonumber(enchantID)
				am("Enchant: "..iid)
			else
				if IsControlKeyDown() then
					local dispID = myadd.itemInfo["displayID"][iid]
					
					--am("DisplayID: "..dispID)
					--am(myadd.displayIDs[dispID])
					--am(myadd.displayIDs[dispID]["itemIDs"])
					for k, v in pairs(myadd.displayIDs[dispID]["itemIDs"]) do
						FunctionOnItemInfo(v, function()
							am(v .. " - "..select(1, GetItemInfo(v)))--..", displayID: "..myadd.itemInfo["displayID"][v])
						end)
					end
				else
					FunctionOnItemInfo(v, function()
						am(iid .. " - "..select(1, GetItemInfo(iid)))--..", displayID: "..myadd.itemInfo["displayID"][iid])
					end)
				end
			end
			TryOn(model, iid, selectedSlot)
		end
	end)
	m:SetScript("OnEnter", m.ShowTooltip)
	m:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	m:SetScript("OnMouseWheel", function(self, delta)
		if delta < 1 then
			SetPage(page+1)
		else
			SetPage(page-1)
		end
		if m:IsShown() then
			m.ShowTooltip(self)
		end
		--[[local x, y, z = m:GetPosition()
		local a = m:GetFacing()
		if IsShiftKeyDown() then		
			m:SetPosition(x, y, z+0.03*delta)
		elseif IsControlKeyDown() then
			m:SetFacing(a+0.03*delta)
		else
			m:SetPosition(x+0.1*delta, y, z)
		end		
		x, y, z = m:GetPosition()
		a = m:GetFacing()
		am(x, y, z, a)]]
	end)
	m:SetScript("OnHide", function(self, delta)
		m:SetPosition(0, 0, 0)
	end)
	m:SetScript("OnShow", function(self, delta)
		if not m.item then return end
		local _, race = UnitRace("player")
		if not slotModelPositions[race] then race = "Human" end
		local pos = slotModelPositions[race][selectedSlot] or {0, 0, 0, 0}
		m:Undress()
		m:TryOn(m.item)
		m:SetPosition(pos[1], pos[2], pos[3])
		m:SetFacing(pos[4])
	end)
	m:Hide()
	return m
end

PlayApplyAnimations = function()	
	for k, v in pairs(itemSlotFrames) do
		v.PlayApply()	
	end
end

local function IconTextureHelper(tex, itemID)
	tex:SetTexture(select(10, GetItemInfo(itemID)))
	tex:Show()
end

local function CreateItemSlot(parent, width, itemSlot, isEnchantSlot)
	local f = CreateFrame("Frame", itemSlot.."Frame", parent)
	f.itemSlot = itemSlot
	if itemSlot == "MainHandEnchantSlot" or itemSlot == "SecondaryHandEnchantSlot" then f.isEnchantSlot = true end
	f:SetSize(width, width)
	f:EnableMouse()
	
	local tex
	if f.isEnchantSlot then
		
		tex = "Interface\\Icons\\INV_Scroll_05" --select(10, GetItemInfo(43987)) --TODO: ACHTUNG FUNKTIONIERT NICHT OHNE VORHER DIE ITEMINFO ZU SECUREN!!! Secure getiteminfo schreiben?
		f:SetSize(width*0.6, width*0.6)
	else
		f.slotID, tex, _ = GetInventorySlotInfo(itemSlot)
	end
	f.ntex = f:CreateTexture(nil,"BACKGROUND",nil,-8)
	f.ntex:SetTexture(tex)
	f.ntex:SetAllPoints(f)
	
	f.itex = f:CreateTexture(nil,"BORDER",nil,-7)
	f.itex:SetTexture(tex)
	f.itex:SetAllPoints(f)
	f.itex:Hide()
	
	f.htex = f:CreateTexture(nil,"OVERLAY",nil,-8) --"HIGHLIGHT" has automatic show on hover, but don't want that on blocked slots
	f.htex:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	f.htex:SetAlpha(0.8)
	f.htex:SetBlendMode("ADD")
	f.htex:SetAllPoints(f)
	f.htex:Hide()
	
	f.mogTex = f:CreateTexture(nil, "BORDER", nil,-7)
	f.mogTex:SetTexture("Interface\\AddOns\\_myaddon\\images\\Transmogrify")	
	local scale = 0.25
	f.mogTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.mogTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	f.mogTex:SetTexCoord(0.2128,0.7890,0.2128,0.8867,0.3105,0.7890,0.3105,0.8867)
	
	f.mogTexSelected = f:CreateTexture(nil, "ARTWORK", nil,-7)
	f.mogTexSelected:SetTexture("Interface\\AddOns\\_myaddon\\images\\Transmogrify")
	scale = 0.36
	f.mogTexSelected:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale-1)
	f.mogTexSelected:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	local left, top, right, bottom = 107/512, 339/512, 166/512,397/512
	f.mogTexSelected:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	f.mogTexSelected:Hide()
	
	f.moggedTex = f:CreateTexture(nil, "ARTWORK", nil,-7)
	f.moggedTex:SetTexture("Interface\\AddOns\\_myaddon\\images\\Transmogrify")
	scale = 0.12
	f.moggedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.moggedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	local left, top, right, bottom = 239/512, 1/512, 282/512,43/512
	f.moggedTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	f.moggedTex:Hide()
	
	f.hiddenTex = f:CreateTexture(nil, "ARTWORK", nil,-7)
	f.hiddenTex:SetTexture("Interface\\AddOns\\_myaddon\\images\\Transmogrify")
	scale = -0.09
	f.hiddenTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.hiddenTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	local left, top, right, bottom = 419/512, 90/512, 443/512,116/512
	f.hiddenTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	f.hiddenTex:SetAlpha(0.8)
	f.hiddenTex:Hide()
	
	f.blockedTex = f:CreateTexture(nil, "ARTWORK", nil,-7)
	f.blockedTex:SetTexture("Interface\\AddOns\\_myaddon\\images\\Transmogrify")
	scale = 0.0
	f.blockedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.blockedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale)
	local left, top, right, bottom = 483/512, 85/512, 511/512,117/512
	f.blockedTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	f.blockedTex:Hide()
	
	f.changedTex = f:CreateTexture(nil, "OVERLAY", nil)
	f.changedTex:SetTexture("Interface\\AddOns\\_myaddon\\images\\PurpleIconAlertAnts")
	scale = 0.14
	f.changedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
	f.changedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale-3)
	left, top, right, bottom = 1/256, 1/256, 239/5/256, 239/5/256
	f.changedTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	f.changedTex:SetAlpha(0.8)
	f.changedTex:Hide()
	
	
	local timeSinceLastFrame, frameLength = 0, 1/12
	local row, column = 0, 0
	--local multi = 1
	--local applying = false
	f.applying = false
	local applyingMulti = 0
	local applyingCount = 0
	
	
	f.animation = function(self, elapsed)
		timeSinceLastFrame = timeSinceLastFrame + elapsed
		if timeSinceLastFrame > frameLength then
			column = column + 1
			if column == 5 then
				column = 0
				row = row + 1
			end
			if row == 5 then
				column = 1
				row = 0
			end
			left, top, right, bottom = (239/5*row+1)/256, (239/5*column+1)/256, 239/5*(row+1)/256, 239/5*(column+1)/256
			f.changedTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
			timeSinceLastFrame = timeSinceLastFrame - frameLength
			
			
			if f.applying then
				if applyingCount < 12 then
					if applyingCount < 3 then
						applyingMulti = applyingMulti + 0.15				
					else
						applyingMulti = applyingMulti - 0.1
					end
					f.changedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*applyingMulti, width*applyingMulti)
					f.changedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*applyingMulti, -width*applyingMulti)
					applyingCount = applyingCount + 1
				else
					if currentMogs["inventory"][f.itemSlot] ~= MyAddonDB.currentChanges[f.itemSlot] 
							and (f.isEnchantSlot or canReceiveTransmog(GetInventoryItemID("player", f.slotID), MyAddonDB.currentChanges[f.itemSlot], f.itemSlot)) then
						f.changedTex:Show()
						f:SetScript("OnUpdate", f.animation)
					else
						f.changedTex:Hide()
						f:SetScript("OnUpdate", nil)
					end
					f.changedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale, width*scale)
					f.changedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale, -width*scale-3)		
					f.applying = false
					applyingMulti = 0
					applyingCount = 0
				end
			end
		end
			
		--local multi = 1 + 2 * math.sin(GetTime()*3)
		--f.changedTex:SetPoint("TOPLEFT", f ,"TOPLEFT", -width*scale*multi, width*scale*multi)
		--f.changedTex:SetPoint("BOTTOMRIGHT", f ,"BOTTOMRIGHT", width*scale*multi, -width*scale-3*multi)
	end
	
	
	f.PlayApply = function()
		if currentMogs["inventory"][f.itemSlot] ~= MyAddonDB.currentChanges[f.itemSlot] 
					and (f.isEnchantSlot or canReceiveTransmog(GetInventoryItemID("player", f.slotID), MyAddonDB.currentChanges[f.itemSlot], f.itemSlot)) then
			f.applying = true
			applyingMulti = 0
			applyingCount = 0
			f.changedTex:Show()
			f:SetScript("OnUpdate", f.animation)
		end
	end
	
	--f.changedTex:Show()
	--f:SetTexture(ntex)
	--f:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
	--enchantscroll texture: "Interface\\Icons\\INV_Scroll_05"
	--107,388, 166,397
	--updateView funktionen von model view konzept viel besser? iteminfo problem?
	f.update = function() -- Show and hide the right textures
		--Blockedtex
		if not ((GetInventoryItemID("player", f.slotID) and not f.isEnchantSlot) or 
						(f.itemSlot == "MainHandEnchantSlot" and canBeEnchanted("MainHandSlot")) or
						(f.itemSlot == "SecondaryHandEnchantSlot" and canBeEnchanted("SecondaryHandSlot"))) then
			f.blockedTex:Show()
			f.moggedTex:Hide()
			f.itex:Hide()
			f.hiddenTex:Hide()
			f.itex:SetVertexColor(1, 1, 1)
			f.mogTex:SetVertexColor(1, 1, 1)
			f.moggedTex:SetVertexColor(1, 1, 1)
			f.changedTex:Hide()
			f.mogTexSelected:Hide()
			--[==[
			if f.itemSlot == selectedSlot then --TODO: move to equipmentchanged event
				selectedSlot = nil
				selectedCategory = nil
				BuildList()
				UpdateSlotModels()
			end
			--]==]
			f:SetScript("OnUpdate", nil)
			return
		else
			f.blockedTex:Hide()
		end
		-- Bordertex
		if not (MyAddonDB.currentChanges[f.itemSlot] == nil) then 
			f.moggedTex:Show() 
			if f.isEnchantSlot or canReceiveTransmog(GetInventoryItemID("player", f.slotID), MyAddonDB.currentChanges[f.itemSlot], f.itemSlot) then
				left, top, right, bottom = 239/512, 1/512, 283/512, 43/512
			else
				left, top, right, bottom = 284/512, 1/512, 330/512, 43/512
			end	
			f.moggedTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
		else
			f.moggedTex:Hide()
		end
		--Hiddentex
		if MyAddonDB.currentChanges[f.itemSlot] == false then 
			f.hiddenTex:Show()
			local hColor = 0.5
			f.itex:SetVertexColor(hColor, hColor, hColor)
			f.mogTex:SetVertexColor(hColor, hColor, hColor)
			f.moggedTex:SetVertexColor(hColor, hColor, hColor)
		else
			f.hiddenTex:Hide()
			f.itex:SetVertexColor(1, 1, 1)
			f.mogTex:SetVertexColor(1, 1, 1)
			f.moggedTex:SetVertexColor(1, 1, 1)
		end
		-- Itemtex
		if GetInventoryItemID("player", f.slotID) and not f.isEnchantSlot then  
			if MyAddonDB.currentChanges[f.itemSlot] and not (MyAddonDB.currentChanges[f.itemSlot] == false ) then
				local itemID = MyAddonDB.currentChanges[f.itemSlot]
				FunctionOnItemInfo(itemID, IconTextureHelper, f.itex, itemID)
			else
				local tex = select(10, GetItemInfo(GetInventoryItemID("player", f.slotID)))
				f.itex:SetTexture(tex)
				f.itex:Show()
			end			
		else
			f.itex:Hide()
		end
		--Changedswirlytex
		--if MyAddonDB.selectedSet and MyAddonDB.sets[MyAddonDB.selectedSet] and not (MyAddonDB.currentChanges[f.itemSlot] == MyAddonDB.sets[MyAddonDB.selectedSet][f.itemSlot]) then
		if not f.applying then
			if currentMogs["inventory"][f.itemSlot] ~= MyAddonDB.currentChanges[f.itemSlot] 
					and (f.isEnchantSlot or canReceiveTransmog(GetInventoryItemID("player", f.slotID), MyAddonDB.currentChanges[f.itemSlot], f.itemSlot)) then
				f.changedTex:Show()
				f:SetScript("OnUpdate", f.animation)
			else
				f.changedTex:Hide()
				f:SetScript("OnUpdate", nil)
			end
		end
		--SelectedTex
		if selectedSlot == f.itemSlot then 
			f.mogTexSelected:Show()
		else
			f.mogTexSelected:Hide()
		end
		--[[
		if GetInventoryItemID("player", f.slotID) and not f.isEnchantSlot then  -- show mogitem tex > show equipitem tex --TODO: wenn keine enchant on waffe auch ausblenden bzw eine ausgegraute version des bilds benutzen?
			--tex = select(10, GetItemInfo(MyAddonDB.currentChanges[f.itemSlot])) --TODO:items in currentset nicht immer save, nur nach full tryon/equipset aufrufen!?
			if MyAddonDB.currentChanges[f.itemSlot] then
				tex = select(10, GetItemInfo(MyAddonDB.currentChanges[f.itemSlot]))
			else
				tex = select(10, GetItemInfo(GetInventoryItemID("player", f.slotID)))
			end
			f.itex:SetTexture(tex)
			f.blockedTex:Hide()
			f.itex:Show()
		elseif f.itemSlot == "MainHandEnchantSlot" and canBeEnchanted("MainHandSlot")
				or f.itemSlot == "SecondaryHandEnchantSlot" and canBeEnchanted("SecondaryHandSlot") then --todo:logik und funktionsweise überlegen hier auch logikfunktion schreiben? canReceiveEnchant(slot) -> if slot = mhench and canreceiveenchat mh then
			f.blockedTex:Hide()		
		else
			f.itex:Hide()
			f.blockedTex:Show()
			--f.changedTex:Hide()
			--f:SetScript("OnUpdate", nil)
			--return
		end	
		if MyAddonDB.currentChanges[f.itemSlot] then
			f.moggedTex:Show()
			if f.isEnchantSlot or canReceiveTransmog(GetInventoryItemID("player", f.slotID), MyAddonDB.currentChanges[f.itemSlot], f.itemSlot) then
				left, top, right, bottom = 239/512, 1/512, 283/512, 43/512
			else
				left, top, right, bottom = 284/512, 1/512, 330/512, 43/512
			end	
			f.moggedTex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
			f.hiddenTex:Hide()
		else
			f.moggedTex:Hide()
			f.hiddenTex:Show()
		end
		if MyAddonDB.selectedSet and MyAddonDB.sets[MyAddonDB.selectedSet] and not (MyAddonDB.currentChanges[f.itemSlot] == MyAddonDB.sets[MyAddonDB.selectedSet][f.itemSlot]) then
			f.changedTex:Show()
			f:SetScript("OnUpdate", f.animation)
		else
			f.changedTex:Hide()
			f:SetScript("OnUpdate", nil)
		end
		if selectedSlot == f.itemSlot then
			f.mogTexSelected:Show()
		else
			f.mogTexSelected:Hide()
		end]]
	end
	
	RegisterListener("currentChanges", f)
	RegisterListener("availableMogs", f)
	RegisterListener("selectedSlot", f)
	RegisterListener("currentMogs", f)
	RegisterListener("inventory", f)
	
	f:SetScript("OnMouseDown", function()		
		if f.blockedTex:IsShown() then return end
		
		local itemID = GetInventoryItemID("player", f.slotID)
		
		if (IsShiftKeyDown()) then
			UndressSlot(f.itemSlot)
			--UpdateModel()
			--UpdateItemSlots() --reicht f.update? enchantslots?
			return
		elseif (IsControlKeyDown()) then
			--if not MyAddonDB.currentChanges then MyAddonDB.currentChanges = {} end
			--MyAddonDB.currentChanges[f.itemSlot] = nil
			SetCurrentChangesSlot(f.itemSlot, nil)
			--UpdateModel()
			--UpdateItemSlots() 
			return
		end
		
		if f.blockedTex:IsShown() then return end
		
		local cat
		--Set Category and BuildList etc
		if f.isEnchantSlot then
			cat = "Verzauberungen"
		else
			local itemID = GetInventoryItemID("player", f.slotID)
			local _, class = UnitClass("player")
			if not itemID or (f.itemSlot == "RangedSlot" and (class == "PALADIN" or class == "DRUID" or class == "SHAMAN" or class == "DEATHKNIGHT")) then return end --make unclickable, if no mogable item equipped
			local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
			local itemFullType = itemType.." "..itemSubType
			--am(GetAuctionItemSubClasses(4)) TODO: get localizied strings like this, better way?
			cat = itemFullType
		end
		
		SetSlotAndCategory(f.itemSlot, cat)
		
		--UIDropDownMenu_SetText(catDDM, selectedCategory)
		--UpdateModel()
		--UpdateItemSlots() --self.update? TODO macht hier listener konzept auf alle möglichen felder noch sinn??? bei selected slot and selected category i.e.??
		--BuildList()
		--SetPage(1)
		--CloseDropDownMenus()
	end)
	f:SetScript("OnEnter", function(self)
		itemSlotOptionsFrame.SetOwner(self)
		if not f.blockedTex:IsShown() then
		--if f.isEnchantSlot or GetInventoryItemID("player", f.slotID) then
			f.htex:Show()
			
			itemSlotOptionsFrame.SetOwner(self)
			itemSlotOptionsFrame:Show()
			if f.isEnchantSlot then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
				GameTooltip:ClearLines()
				local itemLink, itemID, enchantID, spellID, origEnchantName, mogEnchantName
				if f.itemSlot == "MainHandEnchantSlot" then
					itemLink = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"))
				else				
					itemLink = GetInventoryItemLink("player", GetInventorySlotInfo("SecondaryHandSlot"))
				end
				if itemLink then
					itemID, enchantID = itemLink:match("item:(%d+):(%d+)")
				end
				if itemLink and enchantID then
					spellID = myadd.enchantInfo["spellID"][tonumber(enchantID)]					
				end
				if spellID then
					origEnchantName = GetSpellInfo(spellID)
					GameTooltip:AddLine(origEnchantName, 1, 1, 1)
				end
				
				enchantID = MyAddonDB.currentChanges[f.itemSlot]
				if enchantID then
					spellID = myadd.enchantInfo["spellID"][enchantID]
					mogEnchantName = GetSpellInfo(spellID)
					GameTooltip:AddLine("transmogrify to:", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)					
					GameTooltip:AddLine(mogEnchantName, 1, 1, 1)
				end

				if origEnchantName or mogEnchantName then GameTooltip:Show() end
				return
			end
			local equipID = GetInventoryItemID("player", f.slotID)
			local mogID = currentMogs["inventory"][f.itemSlot]
			local changeID = MyAddonDB.currentChanges[f.itemSlot]
			local itemNames = {}
			local itemNameColors = {}
			local itemIcons = {}
			for k, v in pairs({equipID, mogID, changeID}) do
				if v then 
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
					GameTooltip:SetHyperlink("item:"..v)
					local mytext =_G["GameTooltipTextLeft" .. 1]
					local tex = select(10, GetItemInfo(v))
					itemNames[v] = mytext:GetText()--"["..mytext:GetText().."]")
					itemNameColors[v] = { mytext:GetTextColor() }
					itemIcons[v] = tex
				end
			end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")		
			GameTooltip:ClearLines()
			
			if equipID then
				GameTooltip:AddLine(--[["|T"..itemIcons[i]..":0|t "..]]itemNames[equipID], itemNameColors[equipID][1], itemNameColors[equipID][2], itemNameColors[equipID][3])
			end
			if mogID then
				GameTooltip:AddLine("Transmogrified to:", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				GameTooltip:AddLine(--[["|T"..itemIcons[i]..":0|t "..]]itemNames[mogID], itemNameColors[mogID][1], itemNameColors[mogID][2], itemNameColors[mogID][3])
			elseif mogID == false then
				GameTooltip:AddLine("Transmogrified to:", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				GameTooltip:AddLine("Hidden", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				--GameTooltip:AddTexture(itemIcons[i]) --doesn't work on first line, why?
			end			
			if changeID and changeID ~= mogID then
				GameTooltip:AddLine("Pending change:", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				GameTooltip:AddLine(--[["|T"..itemIcons[i]..":0|t "..]]itemNames[changeID], itemNameColors[changeID][1], itemNameColors[changeID][2], itemNameColors[changeID][3])
			elseif changeID == false and changeID ~= mogID then
				GameTooltip:AddLine("Pending change:", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				GameTooltip:AddLine("Hidden", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				--GameTooltip:AddTexture(itemIcons[i]) --doesn't work on first line, why?
			elseif changeID == nil and changeID ~= mogID then
				GameTooltip:AddLine("Pending change:", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				GameTooltip:AddLine("Remove transmogrification", mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
				--GameTooltip:AddTexture(itemIcons[i]) --doesn't work on first line, why?
			end
				
			GameTooltip:Show()
		end
	end)
	f:SetScript("OnLeave", function()
		f.htex:Hide()
		GameTooltip:Hide()
		itemSlotOptionsFrame.QueueHide()
	end)
	f:SetScript("OnShow", function()
		f.update()
	end)
	return f
end

local function CreateItemSlotFrames()
	for _, v in pairs(itemSlots) do
		if v ~= "MainHandEnchantSlot" and v ~= "SecondaryHandEnchantSlot" then
			itemSlotFrames[v] = CreateItemSlot(model, itemSlotWidth, v)
		end
	end
end

local function CreateItemSlotOptionsFrame(parent)
	if itemSlotOptionsFrame then return itemSlotOptionsFrame end
	
	
	itemSlotOptionsFrame = CreateFrame("Frame", nil, parent)
	itemSlotOptionsFrame:SetSize(itemSlotWidth/2, itemSlotWidth)
	itemSlotOptionsFrame:Hide()
	
	
	local left, top, right, bottom = 417/512, 90/512, 443/512,116/512
	itemSlotOptionsFrame.undressButton = CreateMeACustomTexButton(itemSlotOptionsFrame, itemSlotWidth/2, itemSlotWidth/2, "Interface\\AddOns\\_myaddon\\images\\Transmogrify", left, top, right, bottom) --CreateMeATextButton(bar, 70, 24, "Undress")
	--itemSlotOptionsFrame.undressButton:SetFrameStrata("FULLSCREEN")
	itemSlotOptionsFrame.undressButton:SetPoint("BOTTOMRIGHT", itemSlotOptionsFrame, "RIGHT")
	SetTooltip(itemSlotOptionsFrame.undressButton, "Hide")
	
	itemSlotOptionsFrame.undressButton:SetScript("OnClick", function()
		UndressSlot(itemSlotOptionsFrame.owner.itemSlot)
		--UpdateModel()
		--UpdateItemSlots()
	end)	

	local left, top, right, bottom = 451/512, 90/512, 481/512,118/512
	itemSlotOptionsFrame.removeMogButton = CreateMeACustomTexButton(itemSlotOptionsFrame, itemSlotWidth/2, itemSlotWidth/2, "Interface\\AddOns\\_myaddon\\images\\Transmogrify", left, top, right, bottom) --CreateMeATextButton(bar, 70, 24, "Undress")
	itemSlotOptionsFrame.removeMogButton:SetFrameStrata("FULLSCREEN")
	itemSlotOptionsFrame.removeMogButton:SetPoint("TOPRIGHT", itemSlotOptionsFrame, "RIGHT")
	SetTooltip(itemSlotOptionsFrame.removeMogButton, "Unmog")
	
	itemSlotOptionsFrame.removeMogButton:SetScript("OnClick", function()
		--MyAddonDB.currentChanges[itemSlotOptionsFrame.owner.itemSlot] = nil
		SetCurrentChangesSlot(itemSlotOptionsFrame.owner.itemSlot, nil)
		--UpdateModel()
		--UpdateItemSlots()
	end)
	
	itemSlotOptionsFrame.SetOwner = function(frame)
		itemSlotOptionsFrame.hideMe = false
		itemSlotOptionsFrame:Hide()
		itemSlotOptionsFrame.owner = frame
	end
	
	itemSlotOptionsFrame.QueueHide = function()
		itemSlotOptionsFrame.hideMe = true
		MyWaitFunction(0.1, itemSlotOptionsFrame.HideNow)
	end
	
	itemSlotOptionsFrame.HideNow = function()
		if itemSlotOptionsFrame.hideMe == true then
			itemSlotOptionsFrame:Hide()
		end
	end
	
	itemSlotOptionsFrame:SetScript("OnShow", function(self)
		if not self.owner then self:Hide(); return end
		self:SetPoint("RIGHT", self.owner, "LEFT")
	end)
	
	itemSlotOptionsFrame:SetScript("OnHide", function(self)
		--itemSlotOptionsFrame.hideMe = true
	end)
	
	local kids = { itemSlotOptionsFrame:GetChildren() }

	for _, child in ipairs(kids) do
		child:HookScript("OnEnter", function(self)
			itemSlotOptionsFrame.hideMe = false
		end)
		child:HookScript("OnLeave", function(self)
			itemSlotOptionsFrame.QueueHide()
		end)
	end
	
	
	itemSlotOptionsFrame:SetScript("OnLeave", function(self)
		self:Hide()
	end)
	
	--parent:HookScript("OnEnter", itemSlotOptionsFrame.SetOwner)
	--windowFrame:HookScript("OnEnter", itemSlotOptionsFrame.SetOwner)
	
end

local function printItemInfo(itemID)
	am(GetItemInfo(itemID))
end

local GetFreeSetID = function() --TODO: temporary while having to create own ids
	local id = 1
	local usedIDs = {}
	MyAddonDB.sets = MyAddonDB.sets or {}
	for k, _ in pairs(MyAddonDB.sets) do
		table.insert(usedIDs, k)
	end
	
	while true do
		if contains(usedIDs, id) then
			id = id + 1
		else
			return id
		end
	end
end

local CheckForInvalidSetname = function(name)
	local denyMessage
	if string.len(name)<1 then
		denyMessage = "Setname is too short. Setnames must be at least one character long."
	elseif string.find(name, "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz _.,'1234567890]") then
		denyMessage = "Setname contains invalid Symbols."
	end
	
	return denyMessage
end

TryAddSet = function(name)
	local denyMessage = CheckForInvalidSetname(name)
	if denyMessage then
		am(denyMessage)
		return
	end
	--[[local id = GetFreeSetID()
	
	MyAddonDB.sets = MyAddonDB.sets or {}
	MyAddonDB.sets[id] = {["name"] = name, ["isSpecial"] = false, ["transmogs"] = {}}
	SetSelectedSet(id)
	
	am(MyAddonDB.sets)
	am(MyAddonDB.selectedSet)]]
	RequestSetAdd(name, MyAddonDB.currentChanges)
end

local TryRenameSet = function(id, newName) --just changes name, so no updates to anything needed except updating the DDM Text? (TODO: change ddm to listener model?)
	--assert existing setID
	local denyMessage = CheckForInvalidSetname(newName)
	if denyMessage then
		am(denyMessage)
		return
	end
	
	--MyAddonDB.sets[id]["name"] = newName
	
	--if MyAddonDB.selectedSet and id == MyAddonDB.selectedSet then
	--	UpdateListeners("selectedSet")
	--end
	
	RequestSetRename(id, newName)
end



StaticPopupDialogs["NewSetPopup"] = {
	text = "Enter Outfit Name:",
	button1 = SAVE,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		TryAddSet(self.editBox:GetText())
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
		self.editBox:SetMaxLetters(32)
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		TryAddSet(self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
}

StaticPopupDialogs["RenameSetPopup"] = {
	text = "Enter new Outfit Name for %s:",
	button1 = SAVE,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		TryRenameSet(toBeRenamed, self.editBox:GetText())
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
		self.editBox:SetMaxLetters(32)
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self, data)
		TryRenameSet(toBeRenamed, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	exclusive = 1,
	hideOnEscape = 1
}

local GetSetIDsOrderedByName = function()
	local ids = {}
	for id, _ in pairs(MyAddonDB.sets) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		local nameA = string.lower(MyAddonDB.sets[a]["name"])
		local nameB = string.lower(MyAddonDB.sets[b]["name"])
		
		if MyAddonDB.sets[a]["isSpecial"] ~= MyAddonDB.sets[b]["isSpecial"] then
			return not MyAddonDB.sets[b]["isSpecial"]
		end
		
		if nameA == nameB then -- Make ordering of double names deterministic by ordering by id
			return a < b
		else
			return nameA < nameB
		end
	end)
	
	return ids
end

local GetStyledSetName = function(id)
	local name = MyAddonDB.sets[id]["name"]
	local isSpecial = MyAddonDB.sets[id]["isSpecial"]
	
	if isSpecial then
		name = ICON_LIST[1].."0|t".." |cffddbb00"..name.."|r"
		--name = ICON_LIST[1].."0|t"..name
	end
	
	return name
end

CreateSetDDM = function(parent)
	local setDDMNew = CreateFrame("Frame", "SetDDMNew", parent, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(setDDMNew, 160) -- Use in place of dropDown:SetWidth

	setDDMNew.SelectSet = function(self, arg1, arg2, checked) -- arg1: id, arg2: name
		SetSelectedSet(arg1)
		SetCurrentChanges(MyAddonDB.sets[arg1]["transmogs"])
		SetSlotAndCategory(nil, nil)
	end
	setDDMNew.DeleteSet = function(self, arg1, arg2, checked) --arg1: levelOneKey -> id
		--[[MyAddonDB.sets[arg1] = nil --TODO: delete method? muss aber eh auf requestApi krams umgestellt werden
		if MyAddonDB.selectedSet == arg1 then
			local orderedIDs = GetSetIDsOrderedByName()
			SetSelectedSet(orderedIDs[1]) --TODO: lieber eine select set funktion, die immer currentchanges mitsetzt?
			if orderedIDs[1] then
				SetCurrentChanges(MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"])
			else
				SetCurrentChanges({})
			end
			SetSlotAndCategory(nil, nil)
		end--]]
		RequestSetDelete(arg1)
		CloseDropDownMenus()
	end
	
	setDDMNew.firstInit = true	
	--local orderedIDs
	
	setDDMNew.Initialize = function(self, level)		
		if MyAddonDB.selectedSet then 
			UIDropDownMenu_SetSelectedName(setDDMNew, GetStyledSetName(MyAddonDB.selectedSet)) --We can't set selection until menu opens again, so we do it here
		end
		--TODO: wenn doppelnamen erlaubt, umstellen auf: Ermittle setposition in orderedIDS und benutze UIDropDownMenu_SetSelectedID: text nochmal extra setzen weil random texte von anderen DDMs auftauchen...
		--UIDropDownMenu_SetSelectedID(setDDM,2)
		--UIDropDownMenu_SetText(setDDM, orderedKeys[2])
		--am(UIDROPDOWNMENU_OPEN_MENU:GetName(), UIDROPDOWNMENU_OPEN_MENU, UIDROPDOWNMENU_INIT_MENU )
		local orderedIDs = GetSetIDsOrderedByName()
		
		local info
		if level == 1 then
			--Sets
			for _, id in pairs(orderedIDs) do
				info = UIDropDownMenu_CreateInfo()
				info.text = GetStyledSetName(id)--MyAddonDB.sets[id]["name"]
				info.func = setDDMNew.SelectSet
				info.arg1 = id
				info.arg2 = MyAddonDB.sets[id]["name"]
				--if MyAddonDB.sets[id]["isSpecial"] then
				--	info.colorCode = "|cff00ff00"
				--end
				--info.icon = "Interface\\AddOns\\_myaddon\\images\\sm2"
				info.padding = 20
				info.hasArrow = true
				info.value = { ["levelOneKey"] = id} --sonst auch über menulist https://wow.gamepedia.com/Using_UIDropDownMenu
				--info.minWidth = 200 ace lib function
				UIDropDownMenu_AddButton(info, level)
			end
			--Create new Set Button
			----------------------------------------------------------------------------	
			info = UIDropDownMenu_CreateInfo()
			info.text = "|TInterface\\Icons\\Spell_ChargePositive:14:14:0:0|t New Outfit|r"
			--info.icon = "Interface\\Icons\\Spell_ChargePositive"
			info.arg1 = info.text
			info.notCheckable = true
			--info.leftPadding = 100 --ace only
			info.padding = 120
			info.func = function(self, arg1, arg2, checked)
				StaticPopup_Show("NewSetPopup")
			end
			info.value = info.text
			info.colorCode = "|cff00ff00"
			info.justifyH = "CENTER"--akzeptiert kein RIGHT?
			UIDropDownMenu_AddButton(info, level)
			
		elseif level == 2 then
			local levelOneKey = UIDROPDOWNMENU_MENU_VALUE["levelOneKey"]			
			info = UIDropDownMenu_CreateInfo()			
			----------------------------------------------------------------------------			
			info.text = "Rename"
			info.arg1 = info.text
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = "Rename"}
			info.notCheckable = true
			info.padding = 20
			info.func = function(self, arg1, arg2, checked)
				toBeRenamed = levelOneKey
				StaticPopup_Show("RenameSetPopup", GetStyledSetName(toBeRenamed))--MyAddonDB.sets[toBeRenamed]["name"])
				CloseDropDownMenus()
			end
			info.value = info.text
			UIDropDownMenu_AddButton(info, level)	
			----------------------------------------------------------------------------			
			info = UIDropDownMenu_CreateInfo()				
			info.text = "Delete"
			info.arg1 = levelOneKey
			info.value = { ["levelOneKey"] = levelOneKey, ["levelTwoKey"] = "Delete"}
			info.notCheckable = true
			info.padding = 20
			info.func = setDDMNew.DeleteSet--function(self, arg1, arg2, checked)
			--end
			info.value = info.text
			UIDropDownMenu_AddButton(info, level)
			----------------------------------------------------------------------------					
			--TODO: Sets mit anderen sharen / import, export funktionalität irgendwo
		end
		if setDDMNew.firstInit then
			if MyAddonDB.selectedSet then
				UIDropDownMenu_SetSelectedName(setDDMNew,GetStyledSetName(MyAddonDB.selectedSet))
				UIDropDownMenu_SetText(setDDMNew,GetStyledSetName(MyAddonDB.selectedSet))
			else
				UIDropDownMenu_SetText(setDDMNew, "Sets")
			end
			setDDMNew.firstInit = false
		end
	end
	setDDMNew.update = function()		
		if MyAddonDB.selectedSet then
			UIDropDownMenu_SetText(setDDMNew, GetStyledSetName(MyAddonDB.selectedSet))
		else
			UIDropDownMenu_SetText(setDDMNew, "Sets")
		end
	end
	setDDMNew.update()	
	RegisterListener("selectedSet", setDDMNew)
	
	UIDropDownMenu_JustifyText(setDDMNew, "LEFT") 
	UIDropDownMenu_Initialize(setDDMNew, setDDMNew.Initialize)
	
	return setDDMNew
end









local function InitializeFrame()
	--am("(\\(\\         Made              (\\_/)")
	--am("( -.-)          by           =(´o.o`)=")
	--am("o_(\")(\")      Qhizzle    (\")_(\")")
	
	
	local showButton = CreateMeATextButton(UIParent, 70, 24, "Show")
	showButton:SetFrameStrata("FULLSCREEN")
	showButton:SetPoint("TOP", UIParent)
	local textoTmp = CreateFrame("EditBox", nil, bar)
	textoTmp:SetFrameStrata("FULLSCREEN")
	--idTexField:Raise()
	textoTmp:SetPoint("RIGHT", showButton, "LEFT", 0, 0)
	textoTmp:SetSize(70, 24)
	textoTmp:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=12, edgeSize=12, 
      insets={left=4, right=4, top=4, bottom=4}
	})
	textoTmp:SetFontObject("ChatFontNormal")
	textoTmp:SetAutoFocus(false)
	--textoTmp:SetNumeric(true)
	textoTmp:SetMaxLetters(5)
	textoTmp:SetScript("OnEscapePressed",function(self)
		self:ClearFocus()
	end)
	textoTmp:SetScript("OnEnterPressed",function(self)
		local id = tonumber(self:GetText())
		if type(id) == "number" then
			model.ChangeSequence(id)
		end
		--[[if(UnitGUID("target")) then
			model:ClearModel()
			local a=strsub(UnitGUID("target"),9,12)
			local b = tonumber(a,16)
			--am("NPC ID(\""..UnitName("target").."\") = 0x"..a.." = "..b)
			am("Target NPC ID:", tonumber((UnitGUID("target")):sub(-12, -9), 16))
			--am(UnitGUID("target"))
			model:SetCreature(b)
		end]]
		self:SetText("")
		--self:ClearFocus()
	end)
	textoTmp:Show()
	
	
	
	
	showButton:SetScript("OnClick", function()
			windowFrame:Show()
			--model:Hide()
			--model:Show()
			--model:SetModel("CREATURE/FireDancer/FireDancer.m2")
			--model:SetModelScale(2)
			--UpdateModel()
			
			--SetPortraitTexture(windowFrame.charTexture, "player")
		end)	
	showButton:Show()
	
		local setModelButton = CreateMeATextButton(UIParent, 70, 24, "Set Model")
	setModelButton:SetFrameStrata("FULLSCREEN")
	setModelButton:SetPoint("LEFT", showButton, "RIGHT", 0, 0)
	setModelButton:SetScript("OnClick", function()
			--model:SetModel( "Models/Character/OrcFemale.m2" )

			if not UnitIsVisible("target") or not UnitIsPlayer("target") then return end			
			model:ClearModel()
			model:SetUnit("target")
			--model:SetCustomRace(3, 0)
			model:SetModelScale(1)
			local bla, race = UnitRace("target")
			local x, y, z = modelPositions[race]
			model:SetPosition(x, y, z)
			model:SetFacing(0)
			model:Undress()
			--UpdateModel()
			model.update()
			--UpdateItemSlots()
			model:Show()
		end)	
	setModelButton:Show()
	
	
	local f = CreateFrame("Frame", "MyAddonFrame", UIParent)
	f:SetSize(1200, 800) --TODO: make independent of /run print(UIParent:GetScale()) ?
	f:SetPoint("CENTER",UIParent)
	f:Show()
	local scale = 0.25
	function CharacterMicroButton_SetPushed()
		MicroButtonPortrait:SetTexCoord(0.2666, 0.8666, 0, 0.8333);
		MicroButtonPortrait:SetAlpha(0.5);
		CharacterMicroButton:SetButtonState("PUSHED", true);
	end
	function CharacterMicroButton_SetNormal()
		MicroButtonPortrait:SetTexCoord(0.2, 0.8, 0.0666, 0.9);
		MicroButtonPortrait:SetAlpha(1.0);
		CharacterMicroButton:SetButtonState("NORMAL");
	end

	--local func = CharacterFrameCloseButton:GetScript("OnClick")
	f:SetScript("OnShow", function()
		PlaySound("igCharacterInfoOpen")
		--CharacterFrame:Hide()
		--ToggleAchievementFrame()
		--ToggleAchievementFrame()
		--CharacterMicroButton_SetPushed()
		model:Hide() --needed?
		model:Show()
		--UpdateModel()
		UpdateSlotModels()
		--UpdateItemSlots()
		for k, v in pairs(myadd.availableMogsUpdateNeeded) do
			if v and GetInventoryItemID("player", GetInventorySlotInfo(k)) then
				RequestAvailableMogsUpdate(k)
			end
		end		
		RequestBalance()
		RequestPriceOfApplyingUpdate()
		RequestCurrentMogsUpdate()
		RequestSets()
		
		SetPortraitTexture(windowFrame.charTexture, "target")
	end)
	f:SetScript("OnHide", function()		
		GossipFrameGreetingPanel:Show()
		GossipFrameCloseButton:Show()
		GossipFrame:SetAlpha(1)
		CloseGossip()
		PlaySound("igCharacterInfoClose")
	end)
	
	f.BGTopLeft = f:CreateTexture(nil, "BACKGROUND")
	f.BGTopLeft:SetTexture("Interface\\AddOns\\_myaddon\\images\\UI-AUCTIONFRAME-BID-TOPLEFT")
	f.BGTopLeft:SetWidth(f:GetWidth()/3)
	f.BGTopLeft:SetHeight(f:GetHeight()/2)
	f.BGTopLeft:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)	
		f.BGTop = f:CreateTexture(nil, "BACKGROUND")
	f.BGTop:SetTexture("Interface\\AddOns\\_myaddon\\images\\UI-AuctionFrame-Bid-Top")
	f.BGTop:SetWidth(f:GetWidth()/3)
	f.BGTop:SetHeight(f:GetHeight()/2)
	f.BGTop:SetPoint("TOP", f, "TOP", 0, 0)	
		f.BGTopRight = f:CreateTexture(nil, "BACKGROUND")
	f.BGTopRight:SetTexture("Interface\\AddOns\\_myaddon\\images\\UI-AuctionFrame-Bid-TopRight")
	f.BGTopRight:SetWidth(f:GetWidth()/3)
	f.BGTopRight:SetHeight(f:GetHeight()/2)
	f.BGTopRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
		f.BGBottomLeft = f:CreateTexture(nil, "BACKGROUND")
	f.BGBottomLeft:SetTexture("Interface\\AddOns\\_myaddon\\images\\UI-AUCTIONFRAME-BID-BOTLEFT")
	f.BGBottomLeft:SetWidth(f:GetWidth()/3)
	f.BGBottomLeft:SetHeight(f:GetHeight()/2)
	f.BGBottomLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		f.BGBottom = f:CreateTexture(nil, "BACKGROUND")
	f.BGBottom:SetTexture("Interface\\AddOns\\_myaddon\\images\\UI-AuctionFrame-Bid-Bot")
	f.BGBottom:SetWidth(f:GetWidth()/3)
	f.BGBottom:SetHeight(f:GetHeight()/2)
	f.BGBottom:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
		f.BGBottomRight = f:CreateTexture(nil, "BACKGROUND")
	f.BGBottomRight:SetTexture("Interface\\AddOns\\_myaddon\\images\\UI-AUCTIONFRAME-BID-BOTRIGHT")
	f.BGBottomRight:SetWidth(f:GetWidth()/3)
	f.BGBottomRight:SetHeight(f:GetHeight()/2)
	f.BGBottomRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
	
	bar = CreateFrame("Frame", nil, f)
	--bar:SetFrameStrata("MEDIUM")
	f:EnableMouse(true)
	f:EnableMouseWheel(true)
	f:SetMovable(true)
	bar:SetWidth(modelWidth)
	bar:SetHeight(modelHeight)
	bar:SetPoint("LEFT",f,"LEFT", 30, 12)
	f:SetClampedToScreen(false) 
	bar:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=32, edgeSize=32, 
      insets={left=11, right=12, top=12, bottom=11}
	})
	f:SetFrameStrata("DIALOG")
	f:SetScript("OnMouseDown",function(self,button)
		CloseDropDownMenus()
		if button == "LeftButton" then
			self:StartMoving()
		end
	end)
	f:SetScript("OnMouseUp",function(self,button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
			SavePosition()
		end
	end)
	
	windowFrame = f
	tinsert(UISpecialFrames, windowFrame:GetName())
	LoadPosition()
	windowFrame:Show()	
	
	CreateModelFrame()
	
	local exitButton = CreateMeAButton(windowFrame, 48, 48, nil,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Up", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Down", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled", 0, 0, 1, 1)
	--exitButton:SetFrameStrata("FULLSCREEN")																
	exitButton:SetPoint("TOPRIGHT", windowFrame, "TOPRIGHT", 3, -13)
	exitButton:SetScript("OnClick", function() 
			windowFrame:Hide()
		end)
	
	windowFrame.charTexture = windowFrame:CreateTexture(nil, "BACKGROUND")
	windowFrame.charTexture:SetPoint("TOPLEFT", windowFrame, "TOPLEFT", 14, -12)
	windowFrame.charTexture:SetPoint("BOTTOMRIGHT", windowFrame, "TOPLEFT", 14+88, -12-88)
	SetPortraitTexture(windowFrame.charTexture, "player")
	
	--local testButton = CreateFrame("Button","testButton",bar,"UIPanelButtonTemplate2");
	--testButton:SetWidth(80)
	--testButton:SetText("I'm a button :)")
	
	local idTextField = CreateFrame("EditBox", nil, bar)
	idTextField:SetFrameStrata("FULLSCREEN")
	--idTexField:Raise()
	idTextField:SetPoint("LEFT", setModelButton, "RIGHT", 0, 0)
	idTextField:SetSize(70, 24)
	idTextField:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=12, edgeSize=12, 
      insets={left=4, right=4, top=4, bottom=4}
	})
	idTextField:SetFontObject("ChatFontNormal")
	idTextField:SetAutoFocus(false)	
	idTextField:SetJustifyH("CENTER")
	--idTextField:SetNumeric(true)
	--idTextField:SetMaxLetters(5)
	idTextField:SetScript("OnEscapePressed",function(self)
		self:ClearFocus()
	end)
	idTextField:SetScript("OnEnterPressed",function(self)
		local num = tonumber(self:GetText())
		if num then
			TryOn(model, num)
			--UpdateItemSlots()	
			self:SetText("")
		else
			--TODO: regex to recognize if its a wowhead string
			for k, v in pairs(itemSlots) do
				--MyAddonDB.currentChanges[v] = false
				SetCurrentChangesSlot(v, false)
			end
			local bla, itemString = strsplit("=", self:GetText())
			local items = { strsplit(":", itemString) }			
			self:SetText("")
			self:ClearFocus()
			if length(items) < 1 then return end
			am("WoWhead/MogIt import:")
			am(items)
			model:Undress()
			for k, v in pairs(items) do
				if strfind(v, ".") then
					local idk = { strsplit(".", v) }
					v = idk[1]
				end
				v = tonumber(v)
				TryOn(model, v) --TODO: make v int and parse the 0.0.0.0.0.0 out
			end
			--UpdateItemSlots()
		end
		--self:ClearFocus()
	end)
	idTextField:Show()
	
	local left, top, right, bottom = 417/512, 90/512, 443/512,116/512
	local undressButton = CreateMeACustomTexButton(model, 24, 24, "Interface\\AddOns\\_myaddon\\images\\Transmogrify", left, top, right, bottom) --CreateMeATextButton(bar, 70, 24, "Undress")
	--undressButton.ctex:SetAlpha(0.8)
	undressButton:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -16, -16)
	SetTooltip(undressButton, "Hide all")
	
	undressButton:SetScript("OnClick", function()
			for k, v in pairs(itemSlots) do
				UndressSlot(v)
			end
			--UpdateModel()
			--UpdateItemSlots()
		end)	
	undressButton:Show()

	local left, top, right, bottom = 451/512, 90/512, 481/512,118/512
	local removeAllMogButton = CreateMeACustomTexButton(model, 24, 24, "Interface\\AddOns\\_myaddon\\images\\Transmogrify", left, top, right, bottom) --CreateMeATextButton(bar, 70, 24, "Undress")
	removeAllMogButton:SetPoint("RIGHT", undressButton, "LEFT", -2, 0)
	SetTooltip(removeAllMogButton, "Unmog all")
	
	removeAllMogButton:SetScript("OnClick", function()
			--MyAddonDB.currentChanges = {}
			SetCurrentChanges({})
			--UpdateModel()
			--UpdateItemSlots()
		end)	
	removeAllMogButton:Show()
	

	
	local pageTextFieldHolder = CreateFrame("Frame", nil, bar)
	pageTextFieldHolder:SetPoint("LEFT", bar, "BOTTOMRIGHT", 296, 30)
	pageTextFieldHolder:SetSize(30, 24)
	pageTextFieldHolder:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=12, edgeSize=12, 
      insets={left=4, right=4, top=4, bottom=4}
	})
	--pageTextFieldHolder:Hide()
	
	pageTextField = CreateFrame("EditBox", nil, bar)	
	pageTextField:SetPoint("TOPLEFT", pageTextFieldHolder ,"TOPLEFT", 0, 0)
	pageTextField:SetPoint("BOTTOMRIGHT", pageTextFieldHolder ,"BOTTOMRIGHT", 0, 0)
	pageTextField:SetFontObject("ChatFontNormal")
	pageTextField:SetAutoFocus(false)
	pageTextField:SetNumeric(true)
	pageTextField:SetMaxLetters(2)
	pageTextField:SetJustifyH("CENTER")
	pageTextField:SetScript("OnEscapePressed",function(self)
		self:ClearFocus()
	end)
	--pageTextField:EnableMouse()
	--pageTextField:SetScript("OnMouseDown",function(self)
	--	self:HighlightText(0, 2)
	--	am("HI")
	--end)
	pageTextField:SetScript("OnEnterPressed",function(self)
		local num = self:GetNumber()
		SetPage(num)
		--self:SetText("")
		self:ClearFocus()
		
		--Getiteminfo and itemslot
		--if it is a wearable item, save it to current set variable in the right slot
		--save to set?
		--
	end)
	pageTextField:Show()
	
	local pageDownButton = CreateMeAButton(windowFrame, 28, 28, nil,
		"Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled", 0, 0, 1, 1)
	pageDownButton:SetPoint("LEFT", pageTextField, "RIGHT", 4, 0)
	pageDownButton:SetScript("OnClick", function()
		if page > 1 then 
			SetPage(page-1)
		end
	end)
	pageDownButton:Show()
		
	local pageUpButton = CreateMeAButton(windowFrame, 28, 28, nil,
		"Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-Common-MouseHilight", 0, 0, 1, 1,
		"Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled", 0, 0, 1, 1)
	pageUpButton:SetPoint("LEFT", pageDownButton, "RIGHT", 2, 0)
	pageUpButton:SetScript("OnClick", function()
		--local stepSize = 100
		--for i=stepSize*(chestCountTemp-1)+1,stepSize*(chestCountTemp-1)+stepSize do
			--AddChest(100*(chestCountTemp-1)+1)
		--end
		--chestCountTemp = chestCountTemp+1--TODO: Maximum finden
		SetPage(page+1)
	end)
	pageUpButton:Show()
	
	
	--TODO: wahrscheinlich sinnvoller nested drop down zu nutzen!
	--TODO: mainhand, offhand, einhändig geschichte lösen
	catDDM = CreateFrame("Frame", "CAT_DDM", bar, "UIDropDownMenuTemplate")
	
	catDDM.onClick = function(self, arg1, arg2, checked)
		--print(UIDropDownMenu_GetText(self), UIDROPDOWNMENU_MENU_VALUE, arg1, arg2)
		UIDropDownMenu_SetSelectedName(catDDM, arg1) --scheint nichts zu tun?
		--UIDropDownMenu_SetText(catDDM, arg1)
		SetSlotAndCategory(selectedSlot, arg1)
	end
	
	--TODO: über mehrere initialize functions die richtigen slots per "type" in 2. menu setzen? oder geschachteltes dropdown?
	--TODO: ddm size etc fixen
	catDDM.initialize = function(self, level)
		if not selectedSlot then return end --TODO: handlen?
		if contains(slotCategories[selectedSlot], selectedCategory) then
			UIDropDownMenu_SetSelectedName(catDDM, selectedCategory)
		end
		
		local info = UIDropDownMenu_CreateInfo()
		local cats = slotCategories[selectedSlot]
		if selectedSlot == "SecondaryHandSlot" then 
			if not IsSpellKnown(674) then
				cats = {"Rüstung Schilde", "Rüstung Verschiedenes", "Verschiedenes Plunder"}
			elseif not (select(2, UnitClass("player")) == "WARRIOR" and select(5, GetTalentInfo(2, 27)) == 1) then
				cats = {"Rüstung Schilde", "Rüstung Verschiedenes", "Verschiedenes Plunder", "Waffe Dolche", "Waffe Faustwaffen", "Waffe Einhandäxte", "Waffe Einhandstreitkolben", "Waffe Einhandschwerter", "Waffe Verschiedenes"}
			end
		end
		
		
		for k, v in pairs(cats) do
			info.text = v
			info.arg1 = info.text
			info.checked = false
			info.func = catDDM.onClick
			UIDropDownMenu_AddButton(info, level)
		end
	end
	
	--UIDropDownMenu_SetButtonWidth(catDDM,60)
	UIDropDownMenu_SetText(catDDM, "Category")
	UIDropDownMenu_Initialize(catDDM, catDDM.initialize)
	UIDropDownMenu_SetWidth(catDDM,160)
	--UIDropDownMenu_JustifyText(catDDM,"LEFT");
	
	catDDM:SetPoint("LEFT", pageUpButton, "RIGHT", 115, -2)
	catDDM:Show()
		
	
	CreateItemSlotFrames()
	CreateItemSlotOptionsFrame(itemSlotFrames["HeadSlot"])
	
	local leftSlotHolder = CreateFrame("Frame", "leftSlotHolder", bar)
	leftSlotHolder:SetSize(itemSlotWidth+10, modelHeight)
	leftSlotHolder:SetPoint("LEFT", bar, "LEFT", 0, 0)
	local rightSlotHolder = CreateFrame("Frame", "rightSlotHolder", bar)
	rightSlotHolder:SetSize(itemSlotWidth+10, modelHeight)
	rightSlotHolder:SetPoint("RIGHT", bar, "RIGHT", 0, 0)

	itemSlotFrames["HeadSlot"]:SetPoint("TOPLEFT", model, "TOPLEFT", 10, -60)
	itemSlotFrames["ShoulderSlot"]:SetPoint("TOP", itemSlotFrames["HeadSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["BackSlot"]:SetPoint("TOP", itemSlotFrames["ShoulderSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["ChestSlot"]:SetPoint("TOP", itemSlotFrames["BackSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["ShirtSlot"]:SetPoint("TOP", itemSlotFrames["ChestSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["TabardSlot"]:SetPoint("TOP", itemSlotFrames["ShirtSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["WristSlot"]:SetPoint("TOP", itemSlotFrames["TabardSlot"], "BOTTOM", 0, -itemSlotDistance)
		
	itemSlotFrames["HandsSlot"]:SetPoint("TOPRIGHT", model, "TOPRIGHT", -10, -60)
	itemSlotFrames["WaistSlot"]:SetPoint("TOP", itemSlotFrames["HandsSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["LegsSlot"]:SetPoint("TOP", itemSlotFrames["WaistSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["FeetSlot"]:SetPoint("TOP", itemSlotFrames["LegsSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["MainHandSlot"]:SetPoint("TOP", itemSlotFrames["FeetSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["SecondaryHandSlot"]:SetPoint("TOP", itemSlotFrames["MainHandSlot"], "BOTTOM", 0, -itemSlotDistance)
	itemSlotFrames["RangedSlot"]:SetPoint("TOP", itemSlotFrames["SecondaryHandSlot"], "BOTTOM", 0, -itemSlotDistance)
	
--	itemSlotFrames["MainHandEnchantSlot"]:SetPoint("RIGHT", itemSlotFrames["MainHandSlot"], "BOTTOMLEFT", -12, 0)
--	itemSlotFrames["SecondaryHandEnchantSlot"]:SetPoint("RIGHT", itemSlotFrames["SecondaryHandSlot"], "BOTTOMLEFT", -12, 0)
	
	local slotModelFrameHolder = CreateFrame("Frame", "slotModelHolder", bar)
	slotModelFrameHolder:SetSize(modelHeight*2, modelHeight)
	slotModelFrameHolder:SetPoint("LEFT", rightSlotHolder, "RIGHT", 0, 0)
	--[[slotModelFrameHolder:EnableMouseWheel()
	slotModelFrameHolder:SetScript("OnMouseWheel", function(self, delta)
		if delta < 1 then
			SetPage(page+1)
		else
			SetPage(page-1)
		end
	end)]]
	
	--TODO in methode packen
	slotModels[1] = CreateSlotModelFrame(windowFrame, "1", slotModelWidth, slotModelWidth)
	slotModels[1]:SetPoint("LEFT", bar, "RIGHT", 5, (slotModelWidth+slotModelDistance)/2)
	
	slotModels[2]= CreateSlotModelFrame(windowFrame, "2", slotModelWidth, slotModelWidth)
	slotModels[2]:SetPoint("LEFT", slotModels[1], "RIGHT", slotModelDistance, 0)
	
	slotModels[3] = CreateSlotModelFrame(windowFrame, "3", slotModelWidth, slotModelWidth)
	slotModels[3]:SetPoint("LEFT", slotModels[2], "RIGHT", slotModelDistance, 0)
	
	slotModels[4] = CreateSlotModelFrame(windowFrame, "4", slotModelWidth, slotModelWidth)
	slotModels[4]:SetPoint("LEFT", slotModels[3], "RIGHT", slotModelDistance, 0)
	--slotModels[4]:SetAlpha(0.3)
	
	slotModels[5] = CreateSlotModelFrame(windowFrame, "5", slotModelWidth, slotModelWidth)
	slotModels[5]:SetPoint("TOP", slotModels[1], "BOTTOM", 0, -slotModelDistance*1.4)
	
	slotModels[6] = CreateSlotModelFrame(windowFrame, "6", slotModelWidth, slotModelWidth)
	slotModels[6]:SetPoint("LEFT", slotModels[5], "RIGHT", slotModelDistance, 0)
	--slotModels[6]:SetAlpha(0.3)
	
	slotModels[7] = CreateSlotModelFrame(windowFrame, "7", slotModelWidth, slotModelWidth)
	slotModels[7]:SetPoint("LEFT", slotModels[6], "RIGHT", slotModelDistance, 0)
	
	slotModels[8] = CreateSlotModelFrame(windowFrame, "8", slotModelWidth, slotModelWidth)
	slotModels[8]:SetPoint("LEFT", slotModels[7], "RIGHT", slotModelDistance, 0)
	
	setDDM = CreateSetDDM(bar)
	setDDM:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", -12, -8)
	setDDM:Show()
	
	
	saveButton = CreateMeATextButton(bar, 90, 24, "Save")
	saveButton:SetPoint("LEFT", setDDM, "RIGHT", -10, 3)
	saveButton:Show()
	saveButton:SetScript("OnClick", function()
		--MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"] = deepCopy(MyAddonDB.currentChanges)	
		RequestSetSave(MyAddonDB.selectedSet, MyAddonDB.currentChanges)
		--am(MyAddonDB.sets)
		--UpdateListeners("selectedSet")
	end)
	saveButton.update = function()		
		saveButton:Disable()
		--SetTooltip(saveButton, "disabled :(") --TODO: default buttons dont show tooltips while disable, build own buttons?
		if not MyAddonDB.selectedSet or not MyAddonDB.sets[MyAddonDB.selectedSet] or MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] then
			return
		end
		
		for _, slot in pairs(itemSlots) do
			if MyAddonDB.selectedSet and MyAddonDB.sets[MyAddonDB.selectedSet] and MyAddonDB.currentChanges and not (MyAddonDB.currentChanges[slot] == MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"][slot]) then
				saveButton:Enable()
				--SetTooltip(saveButton, "enabled poggies")
				return
			end
		end
	end
	saveButton.update()
	RegisterListener("currentChanges", saveButton)
	RegisterListener("selectedSet", saveButton)
	
	
	local mogCheckButton = CreateFrame("CheckButton", "mogCheckButton_GlobalName", windowFrame, "ChatConfigCheckButtonTemplate")
	mogCheckButton:SetPoint("RIGHT", pageTextField, "LEFT", -260, 0)
	mogCheckButton_GlobalNameText:SetText("Only show mogable"); --TODO: build own text object instead, which we know how to set color with etc
	--mogCheckButton:GetNormalFontObject():SetTextColor(1, 1, 0)
	--mogCheckButton.tooltip = "Only show the items you can currently use as Transmogsource."
	SetTooltip(mogCheckButton, "Only show the items you can currently use as Transmogsource.")
	mogCheckButton:SetScript("OnClick", function()
		onlyMogableFilter = mogCheckButton:GetChecked()
		BuildList()
		--UpdateSlotModels()
		SetPage(1)
	end)
	
	applyButton = CreateMeATextButton(bar, 92, 24, "Apply")
	applyButton:SetPoint("TOPRIGHT", model, "BOTTOMRIGHT", -70, -18)
	applyButton:Show()
	applyButton.applySetText = "Apply Set"
	applyButton.applyText = "Apply"
	
	applyButton:SetScript("OnClick", function()
		--am(ToApiSet(MyAddonDB.currentChanges))
		--SetCurrentChanges(MyAddonDB.currentChanges)
		--SetCurrentChangesSlot("LegsSlot", 9999)
		--RequestPriceOfApplyingUpdate(MyAddonDB.currentChanges)
		if MyAddonDB.sets[MyAddonDB.selectedSet] and MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] == true and DeepCompare(MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"], MyAddonDB.currentChanges) then
			--RequestApplyCurrentChanges()
			RequestApplySet(MyAddonDB.selectedSet)
		else
			RequestApplyCurrentChanges()
		end
		--model:SetLight(true)--, false, 0, -0.707, -0.707, 0.7, 1.0, 1.0, 1.0, 0.8, 1.0, 1.0, 0.8)
		--am(model:GetLight())
		--model:SetLight(1, 0, -1, 1, 0, 1, 0.3, 0.3, 0.3, 1, 0.8, 0.8, 0.64) -- reduced ambient light looks pretty good
		--[==[for setName, setTable in pairs(MyAddonDB.sets) do
			for slot, itemID in pairs(setTable) do
				if type(itemID) == "string" then
					MyAddonDB.sets[setName][slot] = tonumber(itemID)
				end
			end
		end--]==]
		--model:SetModel("character\\human\\female\\humanfemale.m2") 
	end)
	applyButton.update = function()		
		local costs = costs
		local enable = false
		
		if MyAddonDB.sets[MyAddonDB.selectedSet] and MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] == true and DeepCompare(MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"], MyAddonDB.currentChanges) then
			applyButton:SetText(applyButton.applySetText)
			costs = 0
		else
			applyButton:SetText(applyButton.applyText)
		end
		
		--am("curchanges:")
		--am(MyAddonDB.currentChanges)
		--am("curmogs:")
		--am(currentMogs)
		--TODO: handle rangedSlot better?
		for k, slot in pairs(itemSlots) do
			if slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot"
				and MyAddonDB.currentChanges[slot] ~= currentMogs["inventory"][slot] then
				--am(MyAddonDB.currentChanges[slot])
				--am(currentMogs["inventory"][slot])
				enable = true --applyButton:Enable()
			end
		end	
		for k, slot in pairs(itemSlots) do
			if slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot"
				and MyAddonDB.currentChanges[slot] and not canReceiveTransmog(GetInventoryItemID("player", GetInventorySlotInfo(slot)), MyAddonDB.currentChanges[slot], slot) then
				enable = false
			end
		end
		if GetMoney() < costs then
			enable = false
		end
		
		if enable then
			applyButton:Enable()
		else
			applyButton:Disable()
		end
	end
	
		
	applyButton.update()
	RegisterListener("costs", applyButton)
	RegisterListener("currentChanges", applyButton)
	RegisterListener("currentMogs", applyButton)
	RegisterListener("selectedSet", applyButton)
	RegisterListener("money", applyButton)
	
	costsFrame = windowFrame:CreateFontString()
	costsFrame:SetFontObject("GameFontWhite")
	costsFrame:SetPoint("RIGHT", applyButton, "LEFT", -22, 0)
	costsFrame:SetSize(160, 20)
	costsFrame:SetJustifyH("RIGHT")
	costsFrame.update = function()
		local costs = costs
		local enable = false
		
		if MyAddonDB.selectedSet and MyAddonDB.sets[MyAddonDB.selectedSet] and MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] == true and DeepCompare(MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"], MyAddonDB.currentChanges) then
			costs = 0
		end
		
		--am("curchanges:")
		--am(MyAddonDB.currentChanges)
		--am("curmogs:")
		--am(currentMogs)
		--TODO: handle rangedSlot better?
		for k, slot in pairs(itemSlots) do
			if slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot"
				and MyAddonDB.currentChanges[slot] ~= currentMogs["inventory"][slot] then
				--am(MyAddonDB.currentChanges[slot])
				--am(currentMogs["inventory"][slot])
				enable = true --applyButton:Enable()
			end
		end	
		for k, slot in pairs(itemSlots) do
			if slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot"
				and MyAddonDB.currentChanges[slot] and not canReceiveTransmog(GetInventoryItemID("player", GetInventorySlotInfo(slot)), MyAddonDB.currentChanges[slot], slot) then
				enable = false
			end
		end
		
		if enable then
			costsFrame:SetText(GetCoinTextureString(costs))
		else
			costsFrame:SetText("")
		end
	end
	costsFrame.update()
	RegisterListener("costs", costsFrame)
	
	local setCostsBackground = CreateFrame("Frame", nil, windowFrame)
	setCostsBackground:SetPoint("LEFT", saveButton, "RIGHT", -10, -1)
	setCostsBackground:SetSize(220, 36)
	--setCostsBackground:SetPoint("LEFT", applyButton, "RIGHT", 80, 0)
	--setCostsBackground:SetSize(220, 36)
	setCostsBackground:Show()
	
	setCostsBackground.tex = setCostsBackground:CreateTexture(nil,"BACKGROUND",nil)	
	setCostsBackground.tex:SetTexture("Interface\\Addons\\_myaddon\\images\\MONEYFRAME")
	setCostsBackground.tex:SetTexture("Interface\\Addons\\_myaddon\\images\\MONEYFRAME_NOBORDER")
	setCostsBackground.tex:SetAllPoints(setCostsBackground)	
	local left, top, right, bottom = 40/256, 4/32, 215/256,28/32
	setCostsBackground.tex:SetTexCoord(left, top, left, bottom, right, top, right, bottom)
	setCostsBackground.tex:Show()
	
	local setCostsFrame = setCostsBackground:CreateFontString()
	setCostsFrame:SetFontObject("GameFontWhite")
	setCostsFrame:SetPoint("RIGHT", setCostsBackground, "RIGHT", -20, 0)
	setCostsFrame:SetSize(220, 20)
	setCostsFrame:SetJustifyH("RIGHT")
	--setCostsFrame:SetJustifyV("CENTER")
	setCostsFrame.update = function()
		--local changesContainUnmogables = false
		--for k, slot in pairs(itemSlots) do
		--	if slot ~= "MainHandEnchantSlot" and slot~= "SecondaryHandEnchantSlot"
		--		and MyAddonDB.currentChanges[slot] and not canReceiveTransmog(GetInventoryItemID("player", GetInventorySlotInfo(slot)), MyAddonDB.currentChanges[slot], slot) then
		--		changesContainUnmogables = true
		--	end
		--end
		--if not changesContainUnmogables then
		--setCostsFrame:SetText("5".." |T".."Interface\\Icons\\INV_Misc_Coin_07"..":".. 14 .."|t")
		local canUpgrade, changesToSet = false, false
		
		if MyAddonDB.selectedSet and MyAddonDB.sets[MyAddonDB.selectedSet] and MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] == false then
			canUpgrade = true
		end
		for _, slot in pairs(itemSlots) do
			if MyAddonDB.selectedSet and MyAddonDB.sets[MyAddonDB.selectedSet] and MyAddonDB.currentChanges and MyAddonDB.currentChanges[slot] ~= MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"][slot] then
				changesToSet = true
			end
		end
		
		if canUpgrade or changesToSet then			
			local copper = saveSetCosts.copper
			local points = saveSetCosts.points
			
			if copper == nil then copper = "?" end
			if points == nil then points = "?" end
			
			setCostsFrame:SetText(points.." |T".."Interface\\Icons\\INV_Misc_Coin_07"..":".. 14 .."|t, "..GetCoinTextureString(copper))
		else
			setCostsFrame:SetText("")
		end
	end
	setCostsFrame.update()
	RegisterListener("saveSetCosts", setCostsFrame)
	
	local saveSpecialSetButton = CreateMeATextButton(bar, 92, 24, "Upgrade Set")
	saveSpecialSetButton.upgradeText = "Upgrade Set"
	saveSpecialSetButton.saveText = "Save Set"
	saveSpecialSetButton:SetPoint("LEFT", setCostsFrame, "RIGHT", 10, 0)
	saveSpecialSetButton:Show()
	saveSpecialSetButton:SetScript("OnClick", function()
		--RequestApplyCurrentChanges()
		if not MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] then
			--MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] = true --request upgrade
			RequestSetUpgrade(MyAddonDB.selectedSet, MyAddonDB.currentChanges)
		else
			--MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"] = deepCopy(MyAddonDB.currentChanges)	--request save
			RequestSetSave(MyAddonDB.selectedSet, MyAddonDB.currentChanges)
		end
		--SetBalance(balance-5)
		--UpdateListeners("selectedSet")
	end)
	saveSpecialSetButton.update = function()
		saveSpecialSetButton:Disable()
		saveSpecialSetButton:SetText(saveSpecialSetButton.upgradeText)
		
		if not MyAddonDB.selectedSet or not MyAddonDB.sets[MyAddonDB.selectedSet] then
			return
		end
		
		if balance < saveSetCosts.points or GetMoney() < saveSetCosts.copper then
			return
		end
		
		if MyAddonDB.sets[MyAddonDB.selectedSet]["isSpecial"] == false then
			saveSpecialSetButton:Enable()
			return
		end
		
		saveSpecialSetButton:SetText(saveSpecialSetButton.saveText)
		for _, slot in pairs(itemSlots) do
			if MyAddonDB.selectedSet and MyAddonDB.sets[MyAddonDB.selectedSet] and MyAddonDB.currentChanges and MyAddonDB.currentChanges[slot] ~= MyAddonDB.sets[MyAddonDB.selectedSet]["transmogs"][slot] then
				saveSpecialSetButton:Enable()
				return
			end
		end
	end		
	saveSpecialSetButton.update()
	RegisterListener("balance", saveSpecialSetButton)
	RegisterListener("saveSetCosts", saveSpecialSetButton)
	RegisterListener("currentChanges", saveSpecialSetButton)
	RegisterListener("selectedSet", saveSpecialSetButton)
	RegisterListener("money", saveSpecialSetButton)
	
	balanceFrame = windowFrame:CreateFontString()
	balanceFrame:SetFontObject("GameFontWhite")
	balanceFrame:SetPoint("LEFT", applyButton, "RIGHT", 640, 0)
	balanceFrame:SetSize(160, 40)
	balanceFrame:SetJustifyH("RIGHT")
	balanceFrame.update = function()
		local balString = balance
		if balString == nil then balString = "?" end
		balanceFrame:SetText(balString.." |T".."Interface\\Icons\\INV_Misc_Coin_07"..":".. 14 .."|t\n"..GetCoinTextureStringFull(GetMoney())) --balanceFrame:GetStringHeight()*1.3
	end
	balanceFrame.update()
	RegisterListener("balance", balanceFrame)
	RegisterListener("money", balanceFrame)
	
	local titleFrame = windowFrame:CreateFontString()
	titleFrame:SetFontObject("GameFontNormalLarge")
	--titleFrame:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
	titleFrame:SetText("Transmogrify")
	titleFrame:SetPoint("TOP", f, "TOP", 0, -30)
	
	
	nameFilterTextField = CreateFrame("EditBox", nil, windowFrame)
	--nameFilterTextField:SetFrameStrata("FULLSCREEN")
	nameFilterTextField:SetPoint("LEFT", saveButton, "RIGHT", 430, -2)
	nameFilterTextField:SetSize(160, 24)
	nameFilterTextField:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=12, edgeSize=12, 
      insets={left=4, right=4, top=4, bottom=4}
	})
	nameFilterTextField:SetFontObject("ChatFontNormal")
	nameFilterTextField:SetAutoFocus(false)	
	nameFilterTextField:SetJustifyH("CENTER")
	--idTextField:SetNumeric(true)
	--idTextField:SetMaxLetters(5)
	nameFilterTextField:SetScript("OnEscapePressed",function(self)
		self:ClearFocus()
	end)
	nameFilterTextField:SetScript("OnTextChanged",function(self)
		BuildList() --TODO: filter vernünftig implementieren und SetFilter methode triggert list updates
		SetPage(1)
	end)
	nameFilterTextField:SetScript("OnEnterPressed",function(self)
		self:ClearFocus()
	end)
	SetTooltip(nameFilterTextField, "Filter items by name. Only shows already cached items!")
	nameFilterTextField:Show()
	
	
	
	--local font = mogCheckButton:CreateFontString("MA_ButtonFont")--mogCheckButton_GlobalName:GetNormalFontObject()--mogCheckButton:CreateFontString("MA_ButtonFont");
	--font:CopyFontObject(GameFontNormal);
	--font:SetTextColor(1, 1, 0, 1);
	--mogCheckButton:SetNormalFontObject("NumberFontNormalYellow")
	--mogCheckButton_GlobalNameFont:SetTextColor(1, 1, 0, 1);
	
	--UpdateModel()
	--UpdateItemSlots() --TODO: war wohl mal nötig hier, inzwischen aber nicht mehr?
	SetPage(1)
	--local butto = CreateFrame("Button", "globalbutto", UIParent, "UIPanelButtonTemplate2")
	--butto:SetPoint("TOP", showButton, "BOTTOM")
	
end

myadd.Show = function()
	windowFrame:Show()
end

local initLDB = function()
	local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
	
	if not LDBIcon then print("ERROR couldnt find LibDBIcon-1.0!") end
	if LDB then
		local LDBObj = LDB:NewDataObject("MyAddon", {
			type = "launcher",
			label = "MyAddon",
			OnClick = function(_, msg)
				if msg == "LeftButton" then
					myadd.Show()
				elseif msg == "RightButton" then
					--
				end
			end,
			icon = "Interface\\Icons\\Inv_chest_cloth_02",
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddLine("MyAddon")
				tooltip:AddLine("Leftclick to open Transmoginterface.")
			end,
		})

		MyAddonDB["minimapIcon"] = MyAddonDB["minimapIcon"] or
		{
			["minimapPos"] = 260,
			["hide"] = false
		}
		
		if LDBIcon then
			LDBIcon:Register("MyAddon", LDBObj, MyAddonDB.minimapIcon)
		end
	end
end

----parse server messages
--[=====[ 
local function parseCanMog(message)
	--wipe(myadd.availableMogs)
	if not message then return false end
	local slotInfos = { strsplit(";", message) }
	for k, v in pairs(slotInfos) do
		local slotNumber, itemIDsString = strsplit(":", v)
		--am(slotNumber)
		local itemIDs = { strsplit(", ", itemIDsString) }
		--am(idToSlot[slotNumber])
		--am(itemIDs)
		for k2, v2 in pairs(itemIDs) do
			if tonumber(v2) then
				if not myadd.availableMogs[idToSlot[slotNumber]] then myadd.availableMogs[idToSlot[slotNumber]] = {} end
				myadd.availableMogs[idToSlot[slotNumber]][tonumber(v2)] = true
			end
		end
	end
	if selectedSlot and selectedCategory then
		--BuildList()
		--SetPage(1)
	end
	for k, v in pairs(myadd.availableMogs) do
		--am(k, ": ", v)
	end
	UpdateItemSlots()
end
--]=====]
-------slash commands


--[==[ --old and not maintained
SLASH_MYADDON1 = "/test1"
SLASH_MYADDON2 = "/addontest1"
SlashCmdList["MYADDON"] = function(msg)
	windowFrame:Show()
	model:Hide()
	model:Show()
	MyAddonDB.currentChanges = {}
	model:Undress()
	local bla, itemString = strsplit("=", msg)
	local items = { strsplit(":", itemString) }
	for k, v in pairs(items) do
		TryOn(model, v) --TODO: make v int and parse the 0.0.0.0.0.0 out
	end
	UpdateItemSlots()
end 
--]==]

------------------------------------------------------
-- / LOAD THE SHIT / -- and event listener frame
------------------------------------------------------  

local a = CreateFrame("Frame")
a:RegisterEvent("PLAYER_LOGIN")
a:RegisterEvent("CHAT_MSG_ADDON")
a:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
a:RegisterEvent("GOSSIP_SHOW")
a:RegisterEvent("GOSSIP_CLOSED")
a:RegisterEvent("PLAYER_MONEY")

a:SetScript("OnEvent", function(self, event, ...)
	self:UnregisterEvent("PLAYER_LOGIN")
	--self:SetScript("OnEvent", nil)    
	if event == "PLAYER_LOGIN" then
		
		SetDBRef(MyAddonDB)
		InitializeFrame()
		initLDB()
		RequestCurrentMogsUpdate()
		--BackgroundItemInfoWorker.Start()
	--[=====[
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, message, channel, sender = ...
		--am(prefix, message, channel, sender)
		if not sender == UnitName("player") and channel == "WHISPER" then return end -- TODO: "" for server? limit interval how often requests can be send? guarantee correct handling of received mogs (no guarantee moggables:0 comes in first?)
		if prefix == "requestMoggables" then
			local moggies = {}
			local slot
			for k, v in pairs(myadd.warmaneItems) do
				slot = invSlots[select(9,GetItemInfo(k))]
				if slot then
					if GetInventoryItemID("player", GetInventorySlotInfo(slot)) and select(7, GetItemInfo(GetInventoryItemID("player", GetInventorySlotInfo(slot)))) == select(7, GetItemInfo(k)) then
						if not moggies[slot] then moggies[slot] = {} end
						moggies[slot][k] = true
					end
				end				
			end
			--am(moggies)
			local count = 0
			for k, v in pairs(moggies) do
				local msg,_ = GetInventorySlotInfo(k)
				msg = msg..":"
				for id, bool in pairs(v) do
					if string.len(msg) < 230 then
						msg = msg..id..","
					else
						--am(count, string.len(msg))
						SendAddonMessage("moggables:"..count, msg, "WHISPER", UnitName("player"))
						count = count + 1
						msg,_ = GetInventorySlotInfo(k)
						msg = msg..":"
						msg = msg..id..","
					end
				end
				--am(count, string.len(msg))
				SendAddonMessage("moggables:"..count, msg, "WHISPER", UnitName("player"))
				count = count + 1
			end
			--SendAddonMessage("moggables:0", "7:9999", "WHISPER", UnitName("player"))
		elseif string.find(prefix, "moggables") then
			local id = tonumber(string.match(prefix, "moggables:(%d+)"))
			if id == 0 then
				for k, v in pairs(myadd.availableMogs) do
					--myadd.availableMogs[k] = {}
					wipe(myadd.availableMogs)
				end
			end
			parseCanMog(message)
		end
	--]=====]
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		local itemSlotID, itemEquipped = ...
		local itemSlot = idToSlot[itemSlotID]
		if not contains(itemSlots, itemSlot) then return end
		if not windowFrame:IsShown() then
			if not itemEquipped then
				myadd.availableMogs[itemSlot] = {}
			else
				myadd.availableMogsUpdateNeeded[itemSlot] = true
			end
		else
			if not itemEquipped then
				if itemSlot == selectedSlot then
					SetSlotAndCategory(nil, nil)
					--TODO currentmogs hier setzen?
				end
			else
				RequestAvailableMogsUpdate(itemSlot)
				RequestCurrentMogsUpdate()
			end
			UpdateListeners("inventory")
		end
	elseif event == "GOSSIP_SHOW" then --TODO: Alternatively could hook gossipframe stuff and check the button names or smth to see if its the tmog npc
		if not UnitGUID("target") then return end
		local npcIDHex = strsub(UnitGUID("target"),9,12)
		local npcIDDec = tonumber(npcIDHex,16)
		--am(npcIDDec)
		--am("NPC ID(\""..UnitName("target").."\") = 0x"..a.." = "..b)
		--if npcIDDec == 58938 and not GameMenuFrame:IsShown() then
		if GossipFrameNpcNameText:GetText() == "Warpweaver" and not GameMenuFrame:IsShown() then
			--gossipFrameWidthBackup = GossipFrame:GetWidth() --too thick, hide on characterwindow openinstead?
			--GossipFrame:SetWidth(1000)--windowFrame:GetWidth())
			--GossipFrame:SetWidth(windowFrame:GetWidth())
			GossipFrameGreetingPanel:Hide() --here or onshow
			GossipFrameCloseButton:Hide()
			GossipFrame:SetAlpha(0)
			--CharacterFrame:Hide()
			windowFrame:Show()
			
		end
	elseif event == "GOSSIP_CLOSED" then
		--GossipFrame:SetWidth(gossipFrameWidthBackup)
		windowFrame:Hide()
	elseif event == "PLAYER_MONEY" then
		UpdateListeners("money")
	end
end)

--Hooks

CharacterFrame:HookScript("OnShow", function()
	if windowFrame:IsShown() then
		MyWaitFunction(0.01, CloseGossip)
	end
end)

--[[
--local gossipFrameWidthBackup
GossipFrame:HookScript("OnShow", function()
	if GossipFrameNpcNameText:GetText() == "Warpweaver" and not GameMenuFrame:IsShown() then
		--gossipFrameWidthBackup = GossipFrame:GetWidth() --too thick, hide on characterwindow openinstead?
		--am(GossipFrame:GetWidth())
		--GossipFrame:SetWidth(100)--windowFrame:GetWidth())
		--GossipFrame:SetWidth(windowFrame:GetWidth())
		GossipFrameGreetingPanel:Hide() --here or onshow
		GossipFrameCloseButton:Hide()
		GossipFrame:SetAlpha(0)
		--CharacterFrame:Hide()
		windowFrame:Show()
	end
end)

GossipFrame:HookScript("OnHide", function()
	windowFrame:Hide()
	GossipFrame:SetAlpha(1)
	GossipFrameNpcNameText:SetText("Not Warpi")
end)]]

--TODO: make an option to replace default dressup_frame with new wardrobe todo tm
--[[local DressUpItemLink_Orig = DressUpItemLink
	DressUpItemLink = function(link)
	windowFrame:Show()
	model:TryOn(link)
end]]

----------------------------------- Itemtooltip hook
local function TooltipAddMogLine(tooltip, mogID)
	if not tooltip:IsShown() then return end --not necessary?
	
	local textLeft1, textLeft2 
	--for k, v in pairs({tooltip:GetRegions()}) do
	--	if v and v:GetName() and string.find(v:GetName(), "(TextLeft1)$") then
	--		titleTextRegion = v
	--	end
	--end	
	local regions = { tooltip:GetRegions() }
	textLeft1 = regions[10]
	textLeft2 = regions[12]
	--am(tooltip:GetName(), mogID, tooltip:GetWidth(), textLeft1:GetWidth())
	
	local textString = "Transmogrified to:\n"
	if mogID == false then	
		textString = textString .. "Hidden"
	else
		local mogName = GetItemInfo(mogID)
		if mogName then			
			textString = textString..mogName
		else
			textString = textString..mogID
			FunctionOnItemInfo(mogID, TooltipAddMogLine, tooltip, mogID)
		end
	end
	
	--for k, v in pairs({tooltip:GetRegions()}) do
	--	am(k, v:GetName())
	--end
	--am(textLeft1:GetName())
	
	if not tooltip.mogText then
		tooltip.mogText = tooltip:CreateFontString()
		tooltip.mogText:SetFontObject(textLeft2:GetFontObject())
		tooltip.mogText:SetTextColor(mogTooltipTextColor.r, mogTooltipTextColor.g, mogTooltipTextColor.b, mogTooltipTextColor.a)
		tooltip.mogText:SetPoint("BOTTOMLEFT", textLeft2, "TOPLEFT", 0, 1)
	end
	
	tooltip.mogText:SetText(textString)	
	tooltip.mogText:SetWidth(math.max(tooltip:GetWidth()-6, 200)) -- ItemRefTooltip has wrong width on first open, depending on what function gets hooked. One could find the widest tooltipline instead, but this gives good enough functionality imo
	textLeft1:SetJustifyV("TOP")	
	textLeft1:SetHeight(textLeft1:GetStringHeight() + tooltip.mogText:GetHeight())
	tooltip:Show() -- Fixes possibly issues with lines not fitting into the tooltip frame
	--tooltip.mogText:Show()
end

local FindSetItemBaseName = function(itemName)
	local baseItemName
	if string.find(itemName, ".* des %a+ Gladiators") then
		baseItemName = string.sub(itemName, 1, select(1, string.find(itemName, string.match(itemName, ".* des (%a+) Gladiators"))) - 1) .. "Gladiators"
	elseif string.find(itemName, "%a+ Gladiator's .*") then
		baseItemName = string.sub(itemName, select(2, string.find(itemName, string.match(itemName, "(%a+) Gladiator's .*"))) + 2)
		
	elseif string.find(itemName, "%a+ %a+ des Ymirjarfürsten") then
		baseItemName = string.sub(itemName, select(2, string.find(itemName, string.match(itemName, "(%a+) %a+ des Ymirjarfürsten"))) + 2)
	end
	
	return baseItemName
end

HandleItem = function(tooltip, lnk)
	--[[
	local name, link = tooltip:GetItem()
	local texture = select(10, GetItemInfo(link))
	--Add the name and path of the item's texture
	tooltip:AddLine(texture)
	--Show the texture graphic on the previous line
	tooltip:AddTexture(texture)
	--Repaint tooltip with newly added lines
	tooltip:Show()
	
	die tmog in die itemlinks zu packen, wäre deutlich cleaner? ermöglicht tmogs überall korrekt anzuzeigen, in itemrefs im chat, whereever
	
	--local regions = { tooltip:GetRegions() }
	--for k, v in pairs(regions) do
	--	am(v:GetName())
	--end
	--am(regions)
	--am(ownerName)
	
	--if GameTooltipTextLeft1:GetHeight() > 15 then
	--	GameTooltipTextLeft1:SetHeight(GameTooltipTextLeft1:GetHeight() / 2)
	--end
	--if not tooltipFirstLineHeight then
	--	tooltipFirstLineHeight = GameTooltipTextLeft1:GetHeight()
	--end
	
	]]
	
	if not tooltip:GetOwner() then return end
	
	local ownerName = tooltip:GetOwner():GetName()	
	
	--for k, v in pairs({_G["GameTooltipTextLeft1"]}) do
	--	am(k, v)
	--end
	-- usage: local bla = _G["GameTooltipTextLeft1"]
	
	for k, v in pairs({tooltip:GetRegions()}) do
		--am(v:GetName())
		--local myText = _G["GameTooltipTextLeft" .. 1]
		--if v:GetName() then
		--	am(v:GetTextColor())
		--end
		--am(v:GetTextColor())
	end
	
	local currentItems, setItemBaseNames = {}, {}
	local setName, setLine, setCount, setMax, isSetItemLine
	for i=1,40 do		
		local line = _G["GameTooltipTextLeft" .. i]
		--
		--am(string.format('%q', '(%d/%d)'))
		--local str = "Schlachtrüstung des Schreckenspanzers (8/8)"
		--am(string.sub(str, string.find(str, "%(%d/%d%)")))
		if line then
			--am(line:GetName(), line:GetText(), line:GetTextColor())
			if isSetItemLine then
				if line:GetText() == " " then
					isSetItemLine = false
				else
					local setItemName = string.gsub(line:GetText(), '^%s*(.-)%s*$', '%1')
					
					local r, g, b, a = line:GetTextColor()
					
					if r < 0.75 then
						for slot, currentItem in pairs(currentItems) do
							if (currentItem == setItemName or (setItemBaseNames[slot] and setItemBaseNames[slot] == setItemName)) then	
								line:SetTextColor(setItemTooltipTextColor.r, setItemTooltipTextColor.g, setItemTooltipTextColor.b, setItemTooltipTextColor.a)
								line:SetText("  "..currentItem)
								setCount = setCount + 1
							end
						end
					end	
					
					if r > 0.75 and not contains(currentItems, setItemName) then
						line:SetTextColor(setItemMissingTooltipTextColor.r, setItemMissingTooltipTextColor.g, setItemMissingTooltipTextColor.b, setItemMissingTooltipTextColor.a)
						local setItemBaseName = FindSetItemBaseName(setItemName)
						if setItemBaseName then
							line:SetText("  "..setItemBaseName)
						end
						setCount = setCount - 1
					end
				end
			end
			if line:GetText() and string.find(line:GetText(), "%(%d/%d%)") then
				setLine = line
				setName = string.match(line:GetText(), "(.+) %(%d/%d%)")
				setMax = tonumber(string.match(line:GetText(), ".*%(%d/(%d)%)"))
				setCount = tonumber(string.match(line:GetText(), ".*%((%d)/%d%)"))
				for k, v in pairs(allInventorySlots) do
					if GetInventoryItemID("player", GetInventorySlotInfo(v)) then
						currentItems[v] = GetItemInfo(GetInventoryItemID("player", GetInventorySlotInfo(v)))
						
						setItemBaseNames[v] = FindSetItemBaseName(currentItems[v])
					end
				end
				isSetItemLine = true
			end
			if line:GetText() and string.find(line:GetText(), "%(%d%) Set:.*") then
				local required = tonumber(string.match(line:GetText(), "%((%d)%) Set:.*"))
				if setCount >= required then
					line:SetTextColor(bonusTooltipTextColor.r, bonusTooltipTextColor.g, bonusTooltipTextColor.b, bonusTooltipTextColor.a)
					line:SetText(string.sub(line:GetText(), 5))
				end
			end
			--TODO: False Positive Setboni ausgrauen. benötigt info darüber, wie viele parts jeweilige boni benötigen und variable die tracked um den wievielten setbonus es sich handelt, um tabelle nutzen zu können die sagt Ymirjarfürsten = {2,4}
					--oder den ganzen kram mehr id basiert machen?
					--nachfragen wie man an die setdaten kommt, die auf https://db.rising-gods.de/?itemsets dargestellt werden?
					--aus https://wow.tools/dbc/?dbc=itemset&build=3.3.5.12340&locale=deDE#page=1&search=ymir könnte man die bonus thresholds extrahieren
		end
	end
	if setLine then
		setLine:SetText(setName.." ("..setCount.."/"..setMax..")")
	end
	--am(GameTooltipTextLeft1:GetFontObject())
	
	if string.find(ownerName, "Character(%a+)Slot") then -- Default UI Inventory
		local invSlot = string.match(ownerName, "Character(.+)")
		--am(invSlot)
		local mogID = currentMogs["inventory"][invSlot]
		if mogID ~= nil then
			TooltipAddMogLine(tooltip, mogID)
		end
		return
	end
	
	if string.find(ownerName, "ContainerFrame%d+Item%d+") then -- Default UI all Bags but the Bank
		local container, slot = string.match(ownerName, "ContainerFrame(%d+)Item(%d+)")		
		container = container - 1
		slot = GetContainerNumSlots(container) + 1 - slot
		--am("Poggers", container, slot)
		if not currentMogs["container"][container] then return end
		local mogID = currentMogs["container"][container][slot]
		if mogID ~= nil then
			TooltipAddMogLine(tooltip, mogID)
		end
		return
	end
	
	if string.find(ownerName, "BankFrameItem%d+") then -- Default UI Bank
		local slot = tonumber(string.match(ownerName, "BankFrameItem(%d+)"))
		local container = -1
		--am("Poggers", container, slot)
		if not currentMogs["container"][container] then return end
		local mogID = currentMogs["container"][container][slot]
		if mogID ~= nil then
			TooltipAddMogLine(tooltip, mogID)
		end
		return
	end
end

GameTooltip:HookScript("OnTooltipSetItem", HandleItem)

GameTooltip:HookScript("OnHide", function()
	GameTooltipTextLeft1:SetHeight(GameTooltipTextLeft1:GetStringHeight())	
	GameTooltipTextLeft1:SetJustifyV("MIDDLE")
	if GameTooltip.mogText then
		GameTooltip.mogText:SetText("")
	end
end)


GameTooltip:HookScript("OnShow", function()		
	GameTooltipTextLeft1:SetHeight(GameTooltipTextLeft1:GetStringHeight())	
	GameTooltipTextLeft1:SetJustifyV("MIDDLE")
	if GameTooltip.mogText then
		GameTooltip.mogText:SetText("")
	end
end)

ItemRefTooltip:HookScript("OnHide", function()		
	ItemRefTooltipTextLeft1:SetHeight(ItemRefTooltipTextLeft1:GetStringHeight())	
	ItemRefTooltipTextLeft1:SetJustifyV("MIDDLE")
	if ItemRefTooltip.mogText then
		ItemRefTooltip.mogText:SetText("")
	end
end)

hooksecurefunc("SetItemRef", function(link, ...)
	if link and type(link) == "string" then
		local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
		  linkLevel, specializationID, reforgeId, unknown1, unknown2 = strsplit(":", link)
		  
		--am("OnTooltipSetItem", itemId)
		if uniqueId then
			local tmogID = bit.rshift(uniqueId, 16)
		
			TooltipAddMogLine(ItemRefTooltip, itemId)
		end
	end
end)

hooksecurefunc("ChatFrame_OnHyperlinkShow", function(self, link, text, button)
	am(link)
end)


	
local SetHyperlinkOrig = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link, ...)
    if link and string.sub(link, 1, 11) == "transmogset" then
        return
    end
	
    return SetHyperlinkOrig(self, link, ...)
end

local HandleModifiedItemClickOrig = HandleModifiedItemClick
function HandleModifiedItemClick(link, ...)
    if (link and string.find(link, "|Htransmogset|h")) then
        return
    end
	
    return HandleModifiedItemClickOrig(link, ...)
 end
 
--[[
local SendTmogLink = function()
	local link = "|Hplayer:Kaso|h[Kaso]|h"
	
	SendChatMessage(link)
	SendChatMessage("uwu")
	print(link)
end

SendTmogLink()
	]]
--[[
ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip, ...)
	local name, link = tooltip:GetItem()
	if not link then return end
	local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
	  linkLevel, specializationID, reforgeId, unknown1, unknown2 = strsplit(":", link)
	  
	--am("OnTooltipSetItem", itemId)
	local tmogID = bit.rshift(uniqueId, 16)
	
	--TooltipAddMogLine(ItemRefTooltip, itemId)
	
--	if tooltip.notFirstTime then
--		TooltipAddMogLine(ItemRefTooltip, itemId)
--	else
--		tooltip.notFirstTime = true
--		ItemRefTooltip:Hide()
--		MyWaitFunction(0.3, ItemRefTooltip.SetHyperlink, ItemRefTooltip, link, ...)
--	end
end)]]

--Here no problems with first tooltip?!?!?
--[[
local SetHyperlink = ItemRefTooltip.SetHyperlink
ItemRefTooltip.SetHyperlink = function(self, link)	
	local _, itemId, enchantId, jewelId1, jewelId2, jewelId3, jewelId4, suffixId, uniqueId,
	  linkLevel, specializationID, reforgeId, unknown1, unknown2 = strsplit(":", link)
	  
	am(itemId)
	
	SetHyperlink(self, link)
	TooltipAddMogLine(ItemRefTooltip, itemId)
end]]

--hooksecurefunc("SetItemRef", am("SetItemRef"))
--hooksecurefunc("ChatFrame_OnHyperlinkShow", function(...)
--    print("ToggleBackpack called.")
--end)

--hooksecurefunc("ItemRefTooltip_SetHyperlink", function(...)
--	am(...)
--end)
--Initiate Apistub mogables, only for testing

--windowFrame:HookScript("OnShow", function()
	for itemID, v in pairs(myadd.warmaneItems) do
		FunctionOnItemInfo(itemID, function()
			local itemSubtype, _, itemSlot = select(7,GetItemInfo(itemID))
			if itemSlot and invSlots[itemSlot] then
				--am(GetInventorySlotInfo(invSlots[itemSlot]), itemID)
				API.AddTestMoggables(GetInventorySlotInfo(invSlots[itemSlot]), itemID)
			end
		end)
	end
--end)
--[=====[

--]=====]



BackgroundItemInfoWorker.FindNextItemBatch = function(size)
	local batch = {}
	for itemID, _ in pairs(myadd.itemInfo["displayID"]) do
		if not GetItemInfo(itemID) then
			table.insert(batch, itemID)
		end
		if length(batch) >= size then
			break
		end
	end
	
	return batch
end

BackgroundItemInfoWorker.Start = function()
	if not BackgroundItemInfoWorker.batch or length(BackgroundItemInfoWorker.batch) == 0 then
		BackgroundItemInfoWorker.batch = BackgroundItemInfoWorker.FindNextItemBatch(1000)
	end
	
	if length(BackgroundItemInfoWorker.batch) == 0 then return end
	
	local itemID = table.remove(BackgroundItemInfoWorker.batch)
	MyWaitFunction(0.12, FunctionOnItemInfo, itemID, BackgroundItemInfoWorker.Start)
end


GetCoinTextureStringFull = function(money, texHeight)
	texHeight = texHeight or 14
	local texFormat = ":texHeight:texHeight:2:0"
	
	local gold, silver, copper
	
	copper = money % 100
	silver = math.floor((money / 100) % 100)
	gold = math.floor((money / 10000))
	
	return gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon" .. texFormat .. "|t " ..
		silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon" .. texFormat .. "|t " ..
		copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon" .. texFormat .. "|t "
end