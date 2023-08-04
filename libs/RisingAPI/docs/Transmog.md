# API: Transmog

# ToDo

* Change / document how `ApplyAll()` behaves if some transmogrifications fail

# Syntax

## `value: Type?`
Optional value of type `Type` or `nil`

# Types

## `SlotId: uint`
```cpp
HEAD                = 1,
SHOULDERS           = 3,
BODY                = 4, // shirt
CHEST               = 5,
WAIST               = 6,
LEGS                = 7,
FEET                = 8,
WRISTS              = 9,
HANDS               = 10,
MAINHAND            = 12,
SHIELDHANDWEAPON    = 13,
OFFHAND             = 14,
RANGED              = 15,
BACK                = 16,
TABARD              = 19,
```

## `ItemId: uint`
Id of the item. Special values if used as transmog visual:
* `0` - no transmog / show normal visual of item
* `1` - hide the item (no visual)

## `SkinId: uint`
Id of a user created transmog skin

## `Price: { copper: uint, shards: uint }`
Price info consisting of copper amount (100 copper = 1 silver; 100 silver = 1 gold) and shards (Shards of Illusion)

## `SlotMap: { [slotId: SlotId]: ItemId }`
Set of transmog visuals represented as a mapping of slots to item visuals

# Notes
* An item visual is considered "temporary unlocked" if it is available for transmogrification but not yet permanently unlocked. There are multiple situations in which an item is temporary unlocked: If the character has a BoE item in its inventory that is not yet bound to the player and whose visual was not unlocked before. If the character has a soulbound item in its inventory that can still be traded with other raid members or refunded at a vendor.

# Functions

## `GetUnlockedVisuals()` (`transmog/visual/list`)
Get a list of all item visuals that are unlocked for transmog. Depending on the parameter `permanent` the resulting list contains only permanently unlocked items (`true`), only temporary unlocked items (`false`) or all unlocked items (`nil`). The result **also contains** items that are currently unavailable for transmog (see event `transmog/visual/unlock`).
#### Parameters
* `permanent`: `boolean?`
#### Response
`ItemId[]`

## `GetUnlockedVisualsForSlot()` (`transmog/visual/list`)
Get a list of all item visuals that are unlocked for transmog and are compatible with the given slot. Depending on the parameter `permanent` the resulting list contains only permanently unlocked items (`true`), only temporary unlocked items (`false`) or all unlocked items (`nil`). The result does **not contain** items that are currently unavailable for transmog (see event `transmog/visual/unlock`).
#### Parameters
* `slotId`: `SlotId`
* `permanent`: `boolean?`
#### Response
`ItemId[]`

## `GetUnlockedVisualsForItem()` (`transmog/visual/list`)
Get a list of all item visuals that are permanently unlocked for transmog and are compatible with the given item in the given slot. The slot can be ommitted to skip checking whether the visuals are compatible with the given slot. Depending on the parameter `permanent` the resulting list contains only permanently unlocked items (`true`), only temporary unlocked items (`false`) or all unlocked items (`nil`). The result does **not contain** items that are currently unavailable for transmog (see event `transmog/visual/unlock`).
#### Parameters
* `itemId`: `ItemId`
* `slotId`: `SlotId?`
* `permanent`: `boolean?`
#### Response
`ItemId[]`

## `GetBalance()` (`transmog/balance`)
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

## `GetPrice()` (`transmog/price`)
Get the price of applying the given transmog visual to the given item. If no item is provided, instead calculates the price of applying the given transmog to a skin.
#### Parameters
* `visualItemId: ItemId`
* `itemId: ItemId?`
* `slotId: SlotId`
#### Response
`Price`
#### Errors
* If transmog visual cannot be applied to the given item

## `GetPriceAll()` (`transmog/price`)
Get the price of applying the given transmog visuals. If `forSkin` is `true` gets the price of applying the visuals to a skin, otherwise gets the price of applying them to the currently equipped items.
**Note:** There are not discounts, so the price of applying multiple transmogs is simply the sum of the prices to apply each transmog individually.
#### Parameters
* `slots: SlotMap`
* `forSkin: boolean`
#### Response
`Price`
#### Errors
* see `GetPrice()`

## `Apply()` (`transmog/apply`)
Applies the given transmog visual to the given skin or the currently equipped item if no skin id is provided.
**Note:** When applying a visual that is not yet permanently unlocked, but a corresponding item exists in the player's inventory, that item will be bound to the player and can no longer be traded or refunded.
#### Parameters
* `visualItemId: ItemId`
* `skinId: SkinId?`
* `slotId: SlotId`
#### Response
`nil`
#### Errors
* If player has insufficient balance
* If the transmog visual is not available (permanently unlocked or in inventory)
* If transmog visual cannot be applied to the given item
* If the skin is not renamed yet

## `ApplyAll()` (`transmog/apply`)
Applies the given transmog visuals to the given skin or the currently equipped items if no skin id is provided.
**Note:** When applying a visual that is not yet permanently unlocked, but a corresponding item exists in the player's inventory, that item will be bound to the player and can no longer be traded or refunded.
#### Parameters
* `slots: SlotMap`
* `skinId: SkinId?`
#### Response
`nil`
#### Errors
* see `Apply()`

## `Check()` (`transmog/check`)
Checks whether the given transmog visual can be applied to the given skin or the currently equipped item if no skin id is provided. This method performs the same checks as `Apply()` does, but without actually applying the transmog.
#### Parameters
* `visualItemId: ItemId`
* `skinId: SkinId?`
* `slotId: SlotId`
#### Response
`{ valid: boolean, message: string? }`
#### Errors
* If the skin is not renamed yet

## `CheckAll()` (`transmog/check`)
Checks whether the given transmog visuals can be applied to the given skin or the currently equipped items if no skin id is provided. This method performs the same checks as `ApplyAll()` does, but without actually applying the transmogs.
#### Parameters
* `slots: SlotMap`
* `skinId: SkinId?`
#### Response
`{ valid: boolean, messages: { [slot: SlotId]: string } }`
#### Errors
* see `Check()`

## `GetSkins()` (`transmog/skin/list`)
Get a list of all skins.
#### Parameters
#### Response
```
{
	id: SkinId,
	name: string,
	slots: { [slot: SlotId (as string)]: ItemId },
}[]
```

## `GetSkinPrice()` (`transmog/skin/price`)
Get the price of the next skin.
#### Parameters
#### Response
`Price`

## `BuySkin()` (`transmog/skin/buy`)
Buy the next skin.
#### Parameters
#### Response
`nil`
#### Errors
* If player has insufficient balance

## `RenameSkin()` (`transmog/skin/rename`)
Rename the given skin.
#### Parameters
* `skinId: SkinId`
* `newName: string` - new name of the skin
#### Response
`nil`

## `GetActiveSkin()` (`transmog/skin/list`)
Get the id of the active skin or `nil` if no skin is currently active.
#### Parameters
#### Response
```
SkinId?
```

## `ActivateSkin()` (`transmog/skin/activate`)
Activates the given skin
#### Parameters
* `skinId: SkinId?` - id of the skin or `nil` to deactivate
#### Response
`nil`

## `ResetSkin()` (`transmog/skin/reset`)
Resets the name and transmogged slots of the given skin
#### Parameters
* `skinId: SkinId` - id of the skin
#### Response
`nil`

## `GetTransferVisualsToSkinPrice()` (`transmog/skin/transfer/price`)
Get the price of transferring the transmogs of the currently equipped items to the given skin.
#### Parameters
* `skinId: SkinId` - id of the skin
#### Response
`Price`

## `TransferVisualsToSkin()` (`transmog/skin/transfer/apply`)
Transfers the transmogs of the currently equipped items to the given skin.
#### Parameters
* `skinId: SkinId` - id of the skin
#### Response
`nil`

## `GetConfig()` (`transmog/config/show`)
Get the current transmog config
#### Parameters
#### Response
`{ visibility: "visible" | "hidden-in-pvp" | "hidden", }`

## `UpdateConfig()` (`transmog/config/update`)
Update the transmog config
#### Parameters
* `{ visibility: "visible" | "hidden-in-pvp" | "hidden", }`
#### Response
`nil`

# Events
Use `RisingAPI:registerEvent(event, handler)` to subscribe to an event. When the event occurs, the `handler` is called with a table as single parameter whose contents are specified below.

## `transmog/balance/changed`
Indicates a change to the player's balance
#### Parameter
same structure as the response of `GetBalance()`

## `transmog/visual/unlocked`
Indicates a new permanently unlocked visual. Also includes whether the item is currently available for transmog. Failed requirements why an item may not be available include: level, profession, profession specialization, faction, race. If a player can never satisfy the requirements of an item (e.g. wrong class), no event is triggered.
#### Parameter
`itemId: uint`
`available: boolean` whether the item is currently available for transmog

## `transmog/skin/changed`
Indicates a change to a player's skin
#### Parameter
same structure as a single skin in the response of `GetSkins()`

## `transmog/skin/activated`
Indicates the player's active skin has changed
#### Parameter
`skinId: uint?` Id of the newly activated skin or `nil` for skin disabled

## `transmog/config/changed`
Indicates a change to a player's transmog config
#### Parameter
same structure as the response of `GetConfig()`
