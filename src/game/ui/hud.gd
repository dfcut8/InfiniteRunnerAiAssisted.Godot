class_name RunnerHUD
extends Control
@onready var score_label: Label = %Score
@onready var relic_label: Label = %Relics
@onready var dash_label: Label = %DashLabel
@onready var dash_charge: ProgressBar = %DashCharge

func update_state(player: RunnerPlayer, score: int, relics: int) -> void:
	score_label.text = "SCORE %06d" % score
	relic_label.text = "RELICS %03d" % relics
	dash_label.text = "DASH READY" if player.cooldown <= 0.00001 and player.dash_left == 0.0 else "DASH"
	var charge := 1.0 - player.cooldown / player.settings.cooldown_seconds
	if player.dash_left > 0.0:
		charge = player.dash_left / player.settings.dash_seconds
	dash_charge.value = floorf(70.0 * charge)
	%Instructions.visible = player.elapsed < 6.0 and not player.dead
	%DeathPanel.visible = player.dead
