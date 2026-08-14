extends SceneTree

var failures := 0

func _init() -> void:
	_test_deck_and_draw()
	_test_turn_gauges_are_200_percent_faster()
	_test_chain_damage_and_discard()
	_test_block_and_enemy_attack()
	_test_enemy_keeps_acting_during_player_turn()
	_test_player_becomes_ready_while_enemy_keeps_acting()
	_test_win_and_loss()
	_test_ability_buttons_remain_clickable()
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

func _test_turn_gauges_are_200_percent_faster() -> void:
	var model := CombatModel.new(); model.start(456)
	model.advance(1.0)
	check(model.player_progress == 30.0, "Player turn gauge fills at 300% of its original rate")
	check(model.enemy_progress == 21.0, "Enemy turn gauge fills at 300% of its original rate")

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

func _test_enemy_keeps_acting_during_player_turn() -> void:
	var model := CombatModel.new(); model.start(22)
	model.advance(10.0)
	check(model.state == "PLAYER_TURN" and model.choices.size() == 3, "Player gets ability choices when their gauge fills")
	var choices_before := model.choices.duplicate(true)
	var health_before := model.player_health
	model.advance(5.0)
	check(model.player_health < health_before, "Enemy attacks even while the player is choosing an ability")
	check(model.state == "PLAYER_TURN" and model.choices == choices_before, "Enemy attacks do not dismiss the player's ready turn")
	check(model.player_progress == CombatModel.TURN_THRESHOLD, "A ready player's gauge remains full until an ability is used")

func _test_player_becomes_ready_while_enemy_keeps_acting() -> void:
	var model := CombatModel.new(); model.start(23)
	model.player_speed = 7.0; model.enemy_speed = 10.0
	model.advance(10.0)
	check(model.player_health < model.player_max_health, "Enemy acts whenever its gauge fills")
	check(model.state == "PLAYER_TURN" and model.choices.size() == 3, "Player still receives a turn whenever their gauge fills")

func _test_win_and_loss() -> void:
	var model := CombatModel.new(); model.start(3); model.enemy_health = 3; model.state = "PLAYER_TURN"; model.choices = [model._card("Slash", "BLADE", 6)]
	model.play_choice(0); check(model.state == "GAME_OVER" and model.enemy_health == 0, "Enemy reaching zero produces game over")
	model.start(4); model.player_health = 2; model.enemy_progress = 99.0; model.advance(1.0)
	check(model.state == "GAME_OVER" and model.player_health == 0, "Player reaching zero produces game over")

func _test_ability_buttons_remain_clickable() -> void:
	var screen = preload("res://src/combat_screen.gd").new()
	screen._build_ui()
	screen.model.state = "PLAYER_TURN"
	screen.model.choices.append(screen.model._card("Slash", "BLADE", 6))
	screen._refresh()
	var button := screen.cards.get_child(0) as Button
	screen._refresh()
	check(screen.cards.get_child(0) == button, "Refreshing the HUD must not replace an ability button before it can be clicked")
	button.pressed.emit()
	check(screen.model.enemy_health == 44 and screen.model.state == "RUNNING", "Clicking an ability button plays that choice")
	screen.free()
