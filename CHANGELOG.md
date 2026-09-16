# v0.4.0
- Added some more ammo types, firearms, and melee weapons.
- All weapons now get added to loadout slots, "primary" for shotguns, rifles etc, secondary for pistols.
- Using weapons now sends the loadout slot through handler so hud can hook into it

# v0.3.0
- Removed UI entirely, now routes through RIG's ui kit, make sure to update rig also.
- Added support for stack splitting and stacking.
- Equipped weapons are now removed from metadata when player is dropped, stays in loadout.
- Hotbar now works like a real hotbar just displays the items you put on it, no longer removes the item from inventory slot.

# v0.2.0

- Hotbar support with allow list
- Changes to use_item to support hotbar use
- New usable items registry to allow for external resources to register items
- Progressbar support on item use / craft