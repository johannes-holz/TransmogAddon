# API: Transmog

The transmog module is available at `LibStub("RisingAPI").Transmog`.

# Syntax

`value: Type` denotes a parameter or table key with name `value` of type `Type`. A type followed by a question mark like `Type?` is optional and its type is `Type` or `nil`. `Type[]` denotes an array of type `Type`.

# Special Types

## `Slot: string`
```lua
	Head                  = "1",
	Shoulders             = "3",
	Body                  = "4", -- shirt
	Chest                 = "5",
	Waist                 = "6",
	Legs                  = "7",
	Feet                  = "8",
	Wrists                = "9",
	Hands                 = "10",
	MainHandWeapon        = "12",
	OffHandWeapon         = "13",
	OffHand               = "14",
	Ranged                = "15",
	Back                  = "16",
	Tabard                = "19",

	EnchantMainHandWeapon = "20",
	EnchantOffHandWeapon  = "21",
```
Lua constants are available (e.g. `Transmog.Slot.Head`).

## `ItemId: uint`
Id of the item.

## `SpellId: uint`
Id of the enchantment spell (e.g. 59621).

## `VisualId: ItemId | SpellId`
Either an item id or spell id depending on the slot.

## Special values for `ItemId`, `SpellId` and `VisualId`
* `Transmog.NoTransmog` (`0`) - show normal visual of item / enchantment; removes transmog if used in `Apply()`; not included in `GetUnlockedVisuals...()`-methods
* `Transmog.HideItem` (`1`) - hide the item / enchantment visual; only included in `GetUnlockedVisualsFor{Slot,Item}()` if visual can be hidden

## `UnlockedVisuals: { itemIds: ItemId[], spellIds: SpellId[] }`
Contains unlocked visuals.

## `SkinId: uint`
Id of a user created transmog skin

## `Price: { copper: uint, shards: uint }`
Price info consisting of copper amount (100 copper = 1 silver; 100 silver = 1 gold) and shards (Shards of Illusion)

## `SlotMap: { [slot: Slot]: VisualId }`
Set of transmog visuals represented as a mapping of slots to visuals.

# Notes
* All API functions return a [Promise](Promise.md) that wraps the API response.
* An item visual is considered "temporary unlocked" if it is unlocked for transmogrification but not yet permanently unlocked. There are multiple situations in which an item is temporary unlocked:
	* If the character has a BoE item in its inventory that is not yet bound to the player and whose visual was not unlocked before.
	* If the character has a soulbound item in its inventory that can still be traded with other raid members or refunded at a vendor.
* An unlocked item visual is considered "unavailable" if the player does not currently satisfy all requirements needed to use the item visual for transmogrification. Such requirements include: level, profession, profession specialization.
* Rate limiting is in place for the API. If you send too many requests in a short amount of time, your requests will fail with the message `too many requests`. The exact limits vary between different requests and may change.

# API Functions

## `GetUnlockedVisuals()`
Get a list of all item visuals that are unlocked for transmog. The result **also contains** items that are currently unavailable for transmog.
#### Parameters
* `permanent`: `boolean?` - if `true` the resulting list contains only permanently unlocked items, if `false` only temporary unlocked items, if `nil` all unlocked items. See [Notes](#notes)
#### Response
`UnlockedVisuals`

## `GetUnlockedVisualsForSlot()`
Get a list of all item visuals that are unlocked for transmog and are compatible with the given slot. The result does **not contain** items that are currently unavailable for transmog (see event `transmog/visual/unlock`).
#### Parameters
* `slot`: `Slot`
* `permanent`: `boolean?` - see `GetUnlockedVisuals()`
#### Response
`UnlockedVisuals`

## `GetUnlockedVisualsForItem()`
Get a list of all item visuals that are permanently unlocked for transmog and are compatible with the given item in the given slot. The result does **not contain** items that are currently unavailable for transmog (see event `transmog/visual/unlock`).
#### Parameters
* `itemId`: `ItemId`
* `slot`: `Slot?` - pass a slot id to filter visuals by whether they are compatible with the given slot
* `permanent`: `boolean?` - see `GetUnlockedVisuals()`
#### Response
`UnlockedVisuals`

## `UnlockVisual()`
Unlock the enchantment spell that corresponds to the given enchantment scroll item.
#### Parameters
* `itemId`: `ItemId` - enchantment scroll item
#### Response
`nil`
#### Errors
* if the item is not a valid enchantment scroll for transmog
* if the enchantment spell is currently not available to the player
* if player does not have the item in the inventory

## `GetBalance()`
Get the current balance of the player, the maximum amount of shards the player can currently own and information on the weekly limits.
#### Parameters
#### Response
```
{
	shards: uint,
	shardsLimit: uint,
	weekly: {
		total: uint,
		totalLimit: uint,
		raid: uint,
		raidLimit: uint,
		lfg: uint,
		lfgLimit: uint,
		arena: uint,
		arenaLimit: uint,
		bg: uint,
		bgLimit: uint,
	}
}
```

## `GetPrice()`
Get the price of applying the given transmog visual to the given item. If no item is provided, instead calculates the price of applying the given transmog to a skin.
**Note:** This function does **not** verify whether the visual is compatible with the given item or slot. Use `Check()` for that purpose.
#### Parameters
* `visualId: VisualId`
* `itemId: ItemId?`
* `slot: Slot`
#### Response
`Price`

## `GetPriceAll()`
Get the price of applying the given transmog visuals. If `forSkin` is `true` gets the price of applying the visuals to a skin, otherwise gets the price of applying them to the currently equipped items.
**Note:** There are no discounts, so the price of applying multiple transmogs is simply the sum of the prices to apply each transmog individually.
#### Parameters
* `slots: SlotMap`
* `forSkin: boolean`
#### Response
`Price`
#### Errors
* see `GetPrice()`

## `Apply()`
Applies the given transmog visual to the given skin or the currently equipped item if no skin id is provided.
**Note:** When applying a visual that is not yet permanently unlocked, but a corresponding item exists in the player's inventory, that item will be bound to the player and can no longer be traded or refunded.
#### Parameters
* `visualId: VisualId`
* `skinId: SkinId?`
* `slot: Slot`
#### Response
`nil`
#### Errors
* If player has insufficient balance
* If the transmog visual is not available (permanently unlocked or in inventory)
* If transmog visual cannot be applied to the given item
* If the skin is not renamed yet

## `ApplyAll()`
Applies the given transmog visuals to the given skin or the currently equipped items if no skin id is provided.
**Note:** When applying a visual that is not yet permanently unlocked, but a corresponding item exists in the player's inventory, that item will be bound to the player and can no longer be traded or refunded.
**Warning:** This is only a client-side wrapper around multiple calls to `Apply()`. If one of those calls fails this call will fail with a map of error messages `{ [slot: SlotId]: string }`. In this case, some transmogs may have been applied while others have not. You can prevent such partial results, by first verifying that all requested transmogs are allowed using `CheckAll()` and that the character has sufficient balance using `GetPriceAll()`.
#### Parameters
* `slots: SlotMap`
* `skinId: SkinId?`
#### Response
`nil`
#### Errors
* see `Apply()`

## `Check()`
Checks whether the given transmog visual can be applied to the given skin or the currently equipped item if no skin id is provided. This method performs the same checks as `Apply()` does, but without actually applying the transmog.
#### Parameters
* `visualId: VisualId`
* `skinId: SkinId?`
* `slot: Slot`
#### Response
`{ valid: boolean, message: string? }`
#### Errors
* If the skin is not renamed yet

## `CheckAll()`
Checks whether the given transmog visuals can be applied to the given skin or the currently equipped items if no skin id is provided. This method performs the same checks as `ApplyAll()` does, but without actually applying the transmogs.
#### Parameters
* `slots: SlotMap`
* `skinId: SkinId?`
#### Response
`{ valid: boolean, messages: { [slot: Slot]: string } }`
#### Errors
* see `Check()`

## `GetSkins()`
Get a list of all skins.
#### Parameters
#### Response
```
{
	id: SkinId,
	name: string,
	slots: SlotMap,
}[]
```

## `GetSkinPrice()`
Get the price of the next skin.
#### Parameters
#### Response
`Price`

## `BuySkin()`
Buy the next skin.
#### Parameters
#### Response
`nil`
#### Errors
* If player has insufficient balance

## `RenameSkin()`
Rename the given skin.
#### Parameters
* `skinId: SkinId`
* `newName: string` - new name of the skin
#### Response
`nil`

## `GetActiveSkin()`
Get the id of the active skin or `nil` if no skin is currently active.
#### Parameters
#### Response
```
SkinId?
```

## `ActivateSkin()`
Activates the given skin
#### Parameters
* `skinId: SkinId?` - id of the skin or `nil` to deactivate
#### Response
`nil`

## `ResetSkin()`
Resets the name and transmogged slots of the given skin
#### Parameters
* `skinId: SkinId` - id of the skin
#### Response
`nil`

## `GetTransferVisualsToSkinPrice()`
Get the price of transferring the transmogs of the currently equipped items to the given skin.
#### Parameters
* `skinId: SkinId` - id of the skin
#### Response
`Price`

## `TransferVisualsToSkin()`
Transfers the transmogs of the currently equipped items to the given skin.
#### Parameters
* `skinId: SkinId` - id of the skin
#### Response
`nil`

## `GetConfig()`
Get the current transmog config
#### Parameters
#### Response
`{ visibility: "visible" | "hidden-in-pvp" | "hidden", }`

## `UpdateConfig()`
Update the transmog config
#### Parameters
* `config: { visibility: "visible" | "hidden-in-pvp" | "hidden", }`
#### Response
`nil`

# API Events
Use `RisingAPI:registerEvent(eventName, handler)` to subscribe to an event. When the event occurs, the `handler` is called with a table as single parameter whose contents are specified below.

## `transmog/balance/changed`
Indicates a change to the player's balance
#### Parameters
same structure as the response of `GetBalance()`

## `transmog/visual/unlocked`
Indicates a new permanently unlocked visual.
#### Parameters
`itemId: ItemId`
`available: boolean` whether the item is currently available for transmog

## `transmog/skin/changed`
Indicates a change to a player's skin
#### Parameters
same structure as a single skin in the response of `GetSkins()`

## `transmog/skin/activated`
Indicates the player's active skin has changed
#### Parameters
`skinId: SkinId?` Id of the newly activated skin or `nil` for skin disabled

## `transmog/config/changed`
Indicates a change to a player's transmog config
#### Parameters
same structure as the response of `GetConfig()`

# Utility Functions

## `GetVisualFromItemLink()`
Get visual item id and visual enchant id from an item link. Due to limitations of the WoW client, the visual enchant id cannot always be determined. In this case, `nil` is returned for the enchantment.
#### Parameters
* `link: string` - item link, valid formats: `|c<color>|Hitem:<data>|h[<item name>]|h|r` or `item:<data>`
#### Result
`ItemId, SpellId?`

## `EncodeOutfitLink()`
Encode the given outfit as a chat link.
#### Parameters
* `slots: SlotMap` - outfit
* `text: string` - link text
#### Result
`string`

## `DecodeOutfitLink()`
Decode the given chat link to an outfit. Returns `nil` for malformed chat links.
#### Parameters
* `link: string` - outfit link, valid formats: `|cffff80ff|Hplayer::outfit:<data>|h[<text>]|h|r` or `player::outfit:<data>`
#### Result
`SlotMap?`
