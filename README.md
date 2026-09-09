# PeaversGuildCount

[![AddonSentry](https://addonsentry.io/api/public/repos/peavers-warcraft/PeaversGuildCount/badge.svg)](https://addonsentry.io/dashboard/peavers-warcraft/PeaversGuildCount)

A World of Warcraft addon that shows how many players from each guild are in your party or raid, as a sorted list of bars.

## Features

<!-- peavers:features -->
- One bar per guild, its value the number of players from that guild
- Bars sorted by headcount or guild name
- Each guild keeps the same colour every time you see it
- Your own guild highlighted
- Unguilded players counted together, and hideable
- Hover a bar to list the players it is counting
- Customizable bar colors, textures, spacing, height, and width
- Movable and lockable frame, placeable in Edit Mode
- Combat-only mode option
<!-- /peavers:features -->

## Usage

<!-- peavers:usage -->
The addon displays automatically when you join a group. The longest bar is the guild with the most players present; every other bar is drawn relative to it. Hover a bar to see who it is counting.

### Slash Commands

- `/pgc` - Toggle the display
- `/pgc config` - Open configuration panel
- `/pgc test` - Preview the display with an example raid
<!-- /peavers:usage -->

## Configuration

<!-- peavers:configuration -->
Access settings through `/pgc config`:

- **Sorting**: Order by headcount or guild name
- **Hide Unguilded**: Leave out the bar counting players in no guild
- **Highlight My Guild**: Draw your own guild in the accent colour
- **Display Mode**: Always, party only, or raid only
- **Appearance**: Customize bar colors, textures, size, and spacing
- **Frame Lock**: Lock position when satisfied with placement
- **Combat Mode**: Show only during combat
<!-- /peavers:configuration -->


## Installation

### Recommended: PeaversUpdater

Download and install [PeaversUpdater](https://github.com/peavers-warcraft/PeaversUpdater/releases/latest), the desktop updater for the whole Peavers collection. It installs PeaversGuildCount together with its required dependencies and delivers updates before they reach CurseForge.

### Alternative: CurseForge

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/peaversguildcount)
2. Ensure [PeaversCommons](https://www.curseforge.com/wow/addons/peaverscommons) is also installed
3. Ensure [PeaversConfig](https://www.curseforge.com/wow/addons/peaversconfig) is also installed
4. Enable the addon on the character selection screen

---

*Part of the [Peavers](https://peavers.io) addon collection · [Report an issue](https://github.com/peavers-warcraft/PeaversGuildCount/issues) · [Support development on Patreon](https://www.patreon.com/Peavers)*
