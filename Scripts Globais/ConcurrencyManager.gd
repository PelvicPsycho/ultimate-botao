extends Node
## ConcurrencyManager — Autoload singleton that decides the execution backend once at boot.
##
## Modes:
##   THREADED   — Native threads available (Windows, Linux, macOS, Web with COOP/COEP).
##   TIME_SLICED — No threads (Web nothreads, or thread creation failed).
##
## Web note: Godot exports two Web variants:
##   - threads   (variant/thread_support=true)  → OS.has_feature("threads") = true
##   - nothreads (variant/thread_support=false) → OS.has_feature("threads") = false
##
## When threads=true but SharedArrayBuffer is unavailable (missing COOP/COEP headers),
## the Godot loader aborts with an error screen before _ready() is ever reached —
## so we never need to handle that case here.

enum Mode { THREADED, TIME_SLICED }

var mode: Mode = Mode.TIME_SLICED
var worker_count: int = 1
var boot_logged: bool = false

## Reservation: cores to leave free for the engine / OS.
## Desktop native: 2; Web: 1 (browser needs the main thread responsive).
const RESERVE_DESKTOP: int = 2
const RESERVE_WEB: int = 1

## Minimum workers on web. navigator.hardwareConcurrency often underreports
## (Safari/iOS caps at 2, privacy protections, etc.), so we enforce a floor.
## The actual limit is emscripten_pool_size (12) — see export_presets.cfg.
const MIN_WORKERS_WEB: int = 4

## Maximum worker count (configurable at runtime for testing).
## On iOS, memory pressure may require lowering this to 4.
var max_workers: int = 8


func _ready() -> void:
	_detect_and_configure()
	_log_boot_info()


func _detect_and_configure() -> void:
	var is_web: bool = OS.has_feature("web")
	var has_threads: bool = OS.has_feature("threads")
	var cores: int = OS.get_processor_count()

	# ---- 1. Decide mode ----
	if has_threads:
		mode = Mode.THREADED
	else:
		mode = Mode.TIME_SLICED

	# ---- 2. Calculate worker count ----
	var reserve: int = RESERVE_WEB if is_web else RESERVE_DESKTOP
	var raw_count: int = cores - reserve
	worker_count = clampi(raw_count, 1, max_workers)
	
	# Web: enforce a minimum because navigator.hardwareConcurrency is often capped.
	if is_web and worker_count < MIN_WORKERS_WEB:
		worker_count = mini(MIN_WORKERS_WEB, max_workers)

	boot_logged = true


func _log_boot_info() -> void:
	var is_web: bool = OS.has_feature("web")
	var mode_str: String = "THREADED" if mode == Mode.THREADED else "TIME_SLICED"

	print_rich(
		"[b][ConcurrencyManager][/b] OS=", OS.get_name(),
		" | web=", is_web,
		" | threads_feature=", OS.has_feature("threads"),
		" | cores=", OS.get_processor_count(),
		" | mode=", mode_str,
		" | workers=", worker_count
	)

	# Extra web diagnostics (main-thread only, safe here in _ready).
	if is_web:
		var js_bridge = Engine.get_singleton("JavaScriptBridge")
		if js_bridge:
			var cross_origin: bool = js_bridge.eval("crossOriginIsolated", true)
			var hw_concurrency: int = js_bridge.eval("navigator.hardwareConcurrency", true)
			print_rich(
				"[b][ConcurrencyManager][/b] Web: crossOriginIsolated=", cross_origin,
				" | navigator.hardwareConcurrency=", hw_concurrency
			)


## Public helper — use this everywhere instead of raw OS.get_processor_count().
func get_effective_worker_count() -> int:
	return worker_count


## Convenience: "am I running with real threads?"
func is_threaded() -> bool:
	return mode == Mode.THREADED


## Allow runtime override for testing / tuning.
func set_max_workers(count: int) -> void:
	max_workers = clampi(count, 1, 16)
	# Recalculate with new cap.
	_detect_and_configure()
