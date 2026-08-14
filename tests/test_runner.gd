extends SceneTree

var failures := 0

func _init() -> void:
	_test_deck_and_draw()
	_test_chain_damage_and_discard()
	_test_block_and_enemy_attack()
	_test_win_and_loss()
	if failures == 0: print("All combat model tests passed.")
	quit(failures)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_deck_and_draw() -> void:
	var model := CombatModel.new(); model.start(123)
	check(model.draw_pile.size() == 20, "Deck must begin with 20 cards")
	model.advance(10.0)
	check(model.state == "PLAYER_TURN", "Player reaches a turn based on speed")
	check(model.choices.size() == 3 and model.draw_pile.size() == 17, "A player turn draws exactly three")

func _test_chain_damage_and_discard() -> void:
	var model := CombatModel.new(); model.start(1)
	model.state = "PLAYER_TURN"; model.last_ability_type = "BLADE"
	model.choices = [model._card("Ignite", "FIRE", 4, 0, 0, "BLADE", 4), model._card("Guard", "GUARD", 0, 6), model._card("Slash", "BLADE", 6)]
	model.play_choice(0)
	check(model.enemy_health == 42, "An active chain adds bonus damage")
	check(model.discard_pile.size() == 3 and model.choices.is_empty(), "All three choices are discarded")
	check(model.last_ability_type == "FIRE", "Selected ability becomes the chain source")

func _test_block_and_enemy_attack() -> void:
	var model := CombatModel.new(); model.start(2); model.player_block = 4; model.enemy_progress = 99.0
	model.advance(1.0)
	check(model.player_health == 38, "Block absorbs damage before health")
	check(model.player_block == 0, "Block clears after an enemy attack")

func _test_win_and_loss() -> void:
	var model := CombatModel.new(); model.start(3); model.enemy_health = 3; model.state = "PLAYER_TURN"; model.choices = [model._card("Slash", "BLADE", 6)]
	model.play_choice(0); check(model.state == "GAME_OVER" and model.enemy_health == 0, "Enemy reaching zero produces game over")
	model.start(4); model.player_health = 2; model.enemy_progress = 99.0; model.advance(1.0)
	check(model.state == "GAME_OVER" and model.player_health == 0, "Player reaching zero produces game over")
