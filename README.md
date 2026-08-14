# Delve combat prototype

A first playable Godot 4 implementation of the combat loop in [DESIGN.md](DESIGN.md): speed-based turns, temporary three-card choices, cross-turn chains, block, equipment, and win/lose states.

The player has Head, Chest, Legs, Boots, Left Hand, and Right Hand equipment slots. Equipped items contribute Attack (strike damage), Power (magic damage and healing), Defence (guard block), and Speed (turn-gauge rate); the combat HUD shows every slot and the resulting totals.

Turn gauges fill at 300% of their original rate (a 200% speed increase) while preserving the player's and enemy's relative Speed values. Both gauges run independently: the enemy attacks whenever its gauge fills, including while the player is choosing, and the player's choices remain available until an ability is used.

## Setup and run

Install [Godot 4.3 or newer](https://godotengine.org/download/archive/) and verify `godot` is on your `PATH`.

```bash
godot --editor project.godot
# or launch the game directly
godot --path .
```

## Validation

The test runner uses only Godot itself; no add-ons or package installs are required.

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_runner.gd
```
