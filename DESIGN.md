# Combat Prototype

## Overview

This is a small combat prototype built in Godot.

The goal is to test a simple ability-based combat system where:

* The player and enemy act based on **Speed**.
* Speed determines how quickly each character gets their next turn.
* The player has a **deck of 20 abilities**.
* Each player turn, **3 abilities are drawn**.
* The player chooses **1 of the 3 abilities** to use.
* After choosing, **all 3 abilities are discarded**.
* On the player's next turn, **3 new abilities are drawn**.
* Many abilities can **chain from previously played ability types**.
* The enemy currently acts automatically.

The prototype should stay as simple as possible while testing whether choosing abilities and building chains across turns is fun.

---

## Core Combat Loop

Combat takes place on a single screen between:

* Player
* Enemy

Both have:

* Health
* Speed
* Turn Progress

Turn progress continuously fills based on Speed.

When a character's turn progress reaches its required amount, that character gets a turn.

Example:

```text
PLAYER
HP: 40 / 40
Speed: 10
Turn: ████████░░

ENEMY
HP: 50 / 50
Speed: 7
Turn: █████░░░░░
```

---

## Speed

Speed controls how quickly a character gets turns.

Conceptually:

```text
turn_progress += speed * delta
```

When:

```text
turn_progress >= turn_threshold
```

the character gets a turn.

After acting:

```text
turn_progress = 0
```

A character with higher Speed will therefore act more frequently than a character with lower Speed.

For example:

```text
Player Speed: 10
Enemy Speed: 5
```

The player should get roughly twice as many turns as the enemy.

The exact numbers and turn threshold can be adjusted during testing.

---

## Player Turn

When the player's turn progress reaches the threshold:

1. Combat pauses for player input.
2. Draw 3 abilities from the player's deck.
3. Display all 3 abilities.
4. The player selects 1 ability.
5. The selected ability resolves.
6. The selected ability becomes the player's `last_ability`.
7. All 3 displayed abilities are discarded.
8. The player's turn progress resets.
9. Combat resumes.

The two abilities that were not selected are **not kept**.

Every player turn presents 3 completely new choices.

---

## Ability Deck

The player has a deck containing:

```text
20 abilities
```

At the beginning of combat, the deck is shuffled.

Every player turn:

```text
Draw 3
Choose 1
Discard all 3
```

When there are not enough cards remaining to draw another full set of 3, the discarded cards are shuffled back into the draw pile.

The exact reshuffle behaviour can be adjusted later if necessary.

---

## Ability Structure

Each ability should contain only the information needed for the prototype.

Example structure:

```text
Name
Type
Base Effect
Chain Requirement
Chain Effect
```

Example:

```text
Name: Ignite
Type: Fire

Base Effect:
Deal 4 damage

Chain Requirement:
Previous ability was Blade

Chain Effect:
Deal +4 damage
```

Not every ability needs to have a chain effect.

---

## Ability Types

Abilities belong to a type.

Initial example types:

* Blade
* Fire
* Guard
* Arcane
* Nature

These types exist primarily to allow abilities to chain together.

The exact list of types is not final.

---

## Chaining

The game remembers the **type of the last ability the player actually used**.

Example:

```text
last_ability_type = "Blade"
```

Abilities can check this value when played.

Example ability:

```text
IGNITE

Type: Fire

Deal 4 damage.

CHAIN — Blade:
Deal an additional 4 damage.
```

If the player's previous ability was Blade:

```text
Slash -> Ignite
```

Ignite receives its chain bonus.

After Ignite is used:

```text
last_ability_type = "Fire"
```

This means another ability could then chain from Fire.

Example:

```text
Slash
Blade

↓

Ignite
Fire
Chain: Blade

↓

Explosion
Blast
Chain: Fire
```

Chains therefore happen **across multiple player turns**.

---

## Important Draw Rule

Cards are not held between turns.

Example:

### Turn 1

The player draws:

```text
Slash
Guard
Growth
```

The player chooses:

```text
Slash
```

All three cards disappear.

The player's last ability type becomes:

```text
Blade
```

### Turn 2

The player draws:

```text
Ignite
Shield
Spark
```

Ignite has:

```text
Chain: Blade
```

Because Slash was used last turn, Ignite's chain effect is active.

The player chooses Ignite.

All three cards are discarded.

The player's last ability type becomes:

```text
Fire
```

### Turn 3

The player draws:

```text
Explosion
Thorns
Heavy Slash
```

Explosion has:

```text
Chain: Fire
```

Because Ignite was played on the previous player turn, Explosion's chain effect is active.

---

## Enemy

For the first prototype, the enemy does not need its own deck.

The enemy has:

* Health
* Speed
* Attack Damage
* Turn Progress

When the enemy's turn progress reaches the threshold:

1. Enemy attacks.
2. Player takes damage.
3. Enemy turn progress resets.
4. Combat continues.

Example:

```text
Enemy HP: 50
Enemy Speed: 7
Enemy Damage: 6
```

For the initial prototype, the enemy can perform the same basic attack every turn.

More complicated enemy behaviour can be added later if the basic combat system works.

---

## Health

Both the player and enemy have Health.

Example:

```text
Player HP: 40 / 40
Enemy HP: 50 / 50
```

Damage reduces Health.

If:

```text
Enemy HP <= 0
```

the player wins.

If:

```text
Player HP <= 0
```

the player loses.

---

## Block

Some abilities can give the player Block.

Example:

```text
Guard

Type: Guard

Gain 6 Block.
```

Block absorbs incoming enemy damage before Health is reduced.

Example:

```text
Player HP: 30
Player Block: 5

Enemy attacks for 8.
```

Result:

```text
Block absorbs 5.
Player takes 3 damage.

Player HP: 27
```

For the prototype, remaining Block should be cleared after the enemy attack.

---

## Example Ability Set

These are examples only and can be changed during testing.

| Ability     | Type   | Base Effect    | Chain                 |
| ----------- | ------ | -------------- | --------------------- |
| Slash       | Blade  | Deal 6 damage  | None                  |
| Heavy Slash | Blade  | Deal 8 damage  | Guard → bonus damage  |
| Ignite      | Fire   | Deal 4 damage  | Blade → bonus damage  |
| Fireball    | Fire   | Deal 7 damage  | Fire → bonus damage   |
| Guard       | Guard  | Gain Block     | None                  |
| Riposte     | Blade  | Deal damage    | Guard → bonus damage  |
| Spark       | Arcane | Deal damage    | Fire → bonus effect   |
| Growth      | Nature | Restore Health | Guard → bonus healing |
| Thorns      | Nature | Gain Block     | Nature → deal damage  |

The final prototype deck should contain:

```text
20 cards
```

Cards may be duplicated if required.

The first goal is testing the system, not creating 20 completely unique mechanics.

---

## Combat UI

The prototype only needs a single combat screen.

Rough layout:

```text
              ENEMY

             43 / 50 HP

        ███████░░░
          TURN BAR


        [ Enemy Visual ]


----------------------------------


              PLAYER

             28 / 40 HP
              4 BLOCK

        █████░░░░░
          TURN BAR


 [ ABILITY ] [ ABILITY ] [ ABILITY ]
```

The three ability buttons only need to be selectable when it is the player's turn.

---

## Ability UI

Each ability should display enough information for the player to understand the choice.

Example:

```text
┌─────────────────┐
│     IGNITE      │
│                 │
│      FIRE       │
│                 │
│ Deal 4 damage   │
│                 │
│ Chain: Blade    │
│ +4 damage       │
└─────────────────┘
```

If a card's chain condition is currently active, the UI should make that obvious.

The exact visual treatment is not important for the first prototype.

---

## Suggested Game State

The combat system can be treated as several simple states.

```text
RUNNING
PLAYER_TURN
RESOLVING
GAME_OVER
```

### RUNNING

Player and enemy turn bars fill.

### PLAYER_TURN

Turn bars stop.

Three abilities are displayed.

Wait for the player to choose one.

### RESOLVING

Resolve the selected ability or enemy attack.

Update Health, Block and chain information.

### GAME_OVER

Either the player or enemy has reached 0 Health.

---

## Minimum Prototype

The first playable version should contain only:

* One combat screen
* One player
* One enemy
* Player Health
* Enemy Health
* Player Speed
* Enemy Speed
* Turn progress bars
* 20-card player deck
* Draw 3 cards each player turn
* Choose 1 card
* Discard all 3 cards
* Draw 3 new cards next turn
* Ability types
* `last_ability_type`
* Chain effects
* Damage
* Block
* Enemy automatic attack
* Win condition
* Lose condition

---

## Not Required Yet

Do **not** build these until the basic combat is working and fun:

* Equipment
* Character classes
* Multiple enemies
* Multiple player characters
* Mana
* Energy
* Card rarity
* Card upgrades
* Status-effect system
* Inventory
* Map
* Progression
* Shops
* Rewards
* Deck building outside combat
* Complex enemy AI
* Complex animations
* Save system
* Meta progression

These systems can be considered later.

---

## Prototype Goal

The prototype needs to answer one main question:

> Is it fun to repeatedly receive three temporary ability choices and try to construct useful chains across multiple turns while the player and enemy act at different speeds?

If that interaction is enjoyable, the game can be expanded from there.

If it is not enjoyable, the combat system should be changed before adding additional game systems.
