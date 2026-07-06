extends CanvasLayer
## Debug overlay for diagnosing threading / AI issues on web builds.
## Toggle with F3 key. Shows concurrency info + AI state.

const FONT_SIZE: int = 14
const MARGIN: int = 8

var _label: Label
var _visible_flag: bool = false
var _ia_controller_ref: IA_Controller = null
var _collision_ref: CollisionResolution2D = null
var _active_touches = {}  # dicionário índice -> true


func _ready() -> void:
	layer = 128  # render on top of everything

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	_label.position = Vector2(MARGIN, MARGIN)
	_label.size = Vector2(600, 600)
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_label)

	_label.visible = _visible_flag
	_refresh_text()


func _input(event: InputEvent) -> void:
	# --- Tecla F3 (já existente) ---
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_toggle_debug()

	# --- Toque com 3 dedos (novo) ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = true
			if _active_touches.size() == 3:
				_toggle_debug()
		else:
			_active_touches.erase(event.index)


func _toggle_debug():
	_visible_flag = not _visible_flag
	_label.visible = _visible_flag
	if _visible_flag:
		_refresh_text()


func _process(_delta: float) -> void:
	if not _visible_flag:
		return
	# Refresh once per second to avoid string allocation overhead.
	if Engine.get_process_frames() % 60 == 0:
		_refresh_text()


func _refresh_text() -> void:
	var lines: PackedStringArray = PackedStringArray()

	# ---- System info ----
	lines.append("[b]System[/b]")
	lines.append("  OS: %s" % OS.get_name())
	lines.append("  Web: %s" % OS.has_feature("web"))
	lines.append("  Threads feat: %s" % OS.has_feature("threads"))
	lines.append("  Cores: %d" % OS.get_processor_count())

	# ---- Concurrency ----
	lines.append("[b]Concurrency[/b]")
	var cm = get_node_or_null("/root/ConcurrencyMgr")
	if cm and cm.has_method("is_threaded"):
		lines.append("  Mode: %s" % ("THREADED" if cm.is_threaded() else "TIME_SLICED"))
		lines.append("  Workers: %d" % cm.get_effective_worker_count())
	else:
		lines.append("  (ConcurrencyManager not found)")

	# ---- AI State ----
	lines.append("[b]AI[/b]")
	if _ia_controller_ref and is_instance_valid(_ia_controller_ref):
		lines.append("  State: %s" % IA_Controller.AIState.keys()[_ia_controller_ref.ai_state])
		lines.append("  Plays sim'd: %d / %d" % [
			_ia_controller_ref.list_of_plays_simulated.size(),
			_ia_controller_ref.list_of_plays_to_simulate.size()
		])
	else:
		lines.append("  (IA_Controller not linked)")

	# ---- Simulators ----
	lines.append("[b]Sim Controllers[/b]")
	if _collision_ref and is_instance_valid(_collision_ref):
		var sims = _collision_ref.Sim_Controller_list
		lines.append("  Count: %d" % sims.size())
		for i in sims.size():
			var sim = sims[i]
			var ended: String = "Y" if sim.simulation_ended else "N"
			var ts: String = " (TS)" if sim._ts_active else ""
			lines.append("  [%d] ended=%s%s" % [i, ended, ts])
	else:
		lines.append("  (CollisionResolution2D not linked)")

	_label.text = "\n".join(lines)


## Call this from MatchState or wherever the references are available.
func set_references(ia_ctrl: IA_Controller, coll_res: CollisionResolution2D) -> void:
	_ia_controller_ref = ia_ctrl
	_collision_ref = coll_res
