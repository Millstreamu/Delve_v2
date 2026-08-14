class_name CombatModel
extends RefCounted

signal state_changed
signal combat_finished(result: String)

const TURN_THRESHOLD := 100.0
const DRAW_SIZE := 3

var player_max_health := 40
var player_health := 40
var player_block := 0
var player_speed := 10.0
var player_progress := 0.0
var enemy_max_health := 50
var enemy_health := 50
var enemy_speed := 7.0
var enemy_progress := 0.0
var enemy_damage := 6
var state := "RUNNING"
var last_ability_type := ""
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var choices: Array[Dictionary] = []
var battle_log := "The duel begins."
var rng := RandomNumberGenerator.new()

func start(seed_value: int = 0) -> void:
	rng.seed = seed_value if seed_value != 0 else Time.get_unix_time_from_system()
	player_health = player_max_health
	player_block = 0
	player_progress = 0.0
	enemy_health = enemy_max_health
	enemy_progress = 0.0
	state = "RUNNING"
	last_ability_type = ""
	discard_pile.clear()
	choices.clear()
	draw_pile = _make_deck()
	_shuffle(draw_pile)
	battle_log = "The duel begins. Build a chain before the enemy strikes."
	state_changed.emit()

func advance(delta: float) -> void:
	if state != "RUNNING":
		return
	player_progress += player_speed * delta
	enemy_progress += enemy_speed * delta
	if player_progress >= TURN_THRESHOLD:
		player_progress = TURN_THRESHOLD
		_begin_player_turn()
	elif enemy_progress >= TURN_THRESHOLD:
		_enemy_turn()
	state_changed.emit()

func play_choice(index: int) -> void:
	if state != "PLAYER_TURN" or index < 0 or index >= choices.size():
		return
	state = "RESOLVING"
	var ability := choices[index]
	var chained: bool = ability.chain_type != "" and ability.chain_type == last_ability_type
	var damage: int = ability.damage + (ability.chain_damage if chained else 0)
	var block: int = ability.block + (ability.chain_block if chained else 0)
	var healing: int = ability.heal + (ability.chain_heal if chained else 0)
	enemy_health = maxi(0, enemy_health - damage)
	player_block += block
	player_health = mini(player_max_health, player_health + healing)
	last_ability_type = ability.type
	battle_log = "%s: %s%s" % [ability.name, _effect_summary(damage, block, healing), " — CHAIN!" if chained else ""]
	discard_pile.append_array(choices)
	choices.clear()
	player_progress = 0.0
	if enemy_health <= 0:
		_finish("VICTORY")
	else:
		state = "RUNNING"
	state_changed.emit()

func chain_is_active(ability: Dictionary) -> bool:
	return ability.chain_type != "" and ability.chain_type == last_ability_type

func _begin_player_turn() -> void:
	state = "PLAYER_TURN"
	choices.clear()
	if draw_pile.size() < DRAW_SIZE:
		draw_pile.append_array(discard_pile)
		discard_pile.clear()
		_shuffle(draw_pile)
	for ignored in DRAW_SIZE:
		choices.append(draw_pile.pop_back())
	battle_log = "Your turn. Choose one ability; all three will be discarded."

func _enemy_turn() -> void:
	state = "RESOLVING"
	var absorbed: int = mini(player_block, enemy_damage)
	var health_damage: int = enemy_damage - absorbed
	player_health = maxi(0, player_health - health_damage)
	player_block = 0
	enemy_progress = 0.0
	battle_log = "Enemy attacks for %d. Block absorbs %d; you take %d." % [enemy_damage, absorbed, health_damage]
	if player_health <= 0:
		_finish("DEFEAT")
	else:
		state = "RUNNING"

func _finish(result: String) -> void:
	state = "GAME_OVER"
	battle_log = "%s — %s" % [result, "The enemy falls." if result == "VICTORY" else "Your expedition ends here."]
	combat_finished.emit(result)

func _shuffle(cards: Array[Dictionary]) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporary := cards[i]
		cards[i] = cards[j]
		cards[j] = temporary

func _effect_summary(damage: int, block: int, healing: int) -> String:
	var parts: Array[String] = []
	if damage > 0: parts.append("%d damage" % damage)
	if block > 0: parts.append("%d block" % block)
	if healing > 0: parts.append("%d healing" % healing)
	return ", ".join(parts)

func _card(name: String, type: String, damage := 0, block := 0, heal := 0, chain_type := "", chain_damage := 0, chain_block := 0, chain_heal := 0) -> Dictionary:
	return {"name": name, "type": type, "damage": damage, "block": block, "heal": heal, "chain_type": chain_type, "chain_damage": chain_damage, "chain_block": chain_block, "chain_heal": chain_heal}

func _make_deck() -> Array[Dictionary]:
	return [
		_card("Slash", "BLADE", 6), _card("Slash", "BLADE", 6),
		_card("Heavy Slash", "BLADE", 8, 0, 0, "GUARD", 4), _card("Heavy Slash", "BLADE", 8, 0, 0, "GUARD", 4),
		_card("Ignite", "FIRE", 4, 0, 0, "BLADE", 4), _card("Ignite", "FIRE", 4, 0, 0, "BLADE", 4),
		_card("Fireball", "FIRE", 7, 0, 0, "FIRE", 3), _card("Fireball", "FIRE", 7, 0, 0, "FIRE", 3),
		_card("Guard", "GUARD", 0, 6), _card("Guard", "GUARD", 0, 6), _card("Guard", "GUARD", 0, 6),
		_card("Riposte", "BLADE", 5, 0, 0, "GUARD", 5), _card("Riposte", "BLADE", 5, 0, 0, "GUARD", 5),
		_card("Spark", "ARCANE", 5, 0, 0, "FIRE", 3), _card("Spark", "ARCANE", 5, 0, 0, "FIRE", 3),
		_card("Growth", "NATURE", 0, 0, 5, "GUARD", 0, 0, 4), _card("Growth", "NATURE", 0, 0, 5, "GUARD", 0, 0, 4),
		_card("Thorns", "NATURE", 0, 5, 0, "NATURE", 4), _card("Thorns", "NATURE", 0, 5, 0, "NATURE", 4),
		_card("Starfall", "ARCANE", 6, 0, 0, "ARCANE", 4)
	]
