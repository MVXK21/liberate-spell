# Changelog

## 1.0.1

- Fixed: quest slaves (Eleedal-Lei, Dahleena, Hides-His-Foot, Llaals Ores) could still be freed by casting Liberate on another slave and then talking to them. The dialogue now excludes them too.
- Fixed: the spell no longer uses an inventory item. Dropping that item stopped it from expiring, so picking it up again gave a permanent pass. A global variable is used instead, and nothing appears in your inventory.
- Docs: the spell is Target range only, and the time limit is about a minute of unpaused play, not in-game time.

## 1.0.0 (2026-11-25)

First release.

- Adds the Liberate spell (Alteration, target range), sold by Imperial Cult spell merchants.
- Casting it on a slave unlocks a "go free" dialogue choice for about a minute.
- Works with vanilla and Tamriel Rebuilt slaves; skips four quest slaves.
