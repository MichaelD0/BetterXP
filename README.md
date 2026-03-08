# BetterXP

A lightweight World of Warcraft addon that replaces the default experience bar with a cleaner, more informative one.

## Features

- **XP bar** with percentage, current/max XP, and remaining XP displayed on the bar
- **Rested XP** shown as a separate blue overlay with the rested amount in the text
- **Time tracking** — shows time spent on the current level and estimated time to level (TTL) based on your XP/hour rate
- **Draggable** — click and drag to reposition the bar anywhere on screen
- **Lockable** — lock the bar in place to prevent accidental movement
- **Persistent** — position, lock state, and time tracking are saved across sessions
- **Tooltip** — hover for detailed stats including XP/hour and time to level
- **Auto-hide** — automatically hides at max level

## Installation

1. Download or clone this repository
2. Copy the `BetterXP` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory
3. Restart WoW or type `/reload` in-game

## Slash Commands

| Command | Description |
|---------|-------------|
| `/bxp lock` | Lock the bar in place |
| `/bxp unlock` | Unlock the bar for dragging |
| `/bxp reset` | Reset the bar to its default position |

## Bar Display

The bar shows the following information at a glance:

```
55.2%  —  125.5K / 227.3K  (101.8K remaining)  (+50.0K rested)  TTL: 1h 23m  T: 2h 15m
```

- **Percentage** — current level progress
- **XP values** — current / max with remaining in parentheses
- **Rested** (blue) — rested XP bonus if available
- **TTL** (gold) — estimated time to level up based on your earning rate
- **T** (grey) — total time spent on the current level

## Tooltip

Hover over the bar for detailed information:

- Current XP (exact values)
- Remaining XP and percentage
- Rested XP
- Current level
- Time on level
- XP per hour
- Estimated time to level
