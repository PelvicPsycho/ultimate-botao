extends Control

var volumeMaster: float
var volumeBGM: float
var volumeSFX: float
@onready var MasterBus = AudioServer.get_bus_index("Master")
@onready var BGMBus = AudioServer.get_bus_index("BGM")
@onready var MasterContr = SoundMaster
@export var soundQuaseGol: AudioStream
@export var MasterSoundSlider: HSlider
@export var BGMSlider: HSlider
@export var SFXSlider: HSlider
@export var Checkbox: CheckBox


func _ready() -> void:
	await get_tree().process_frame
	# Atualiza a posição visual dos Sliders (assumindo que vão de 0 a 100)
	MasterSoundSlider.value = SoundMaster.volume_master
	BGMSlider.value = SoundMaster.volume_BGM
	SFXSlider.value = SoundMaster.volume_SFX
	
	# Atualiza o CheckBox de Mute
	Checkbox.button_pressed = AudioServer.is_bus_mute(MasterBus)


func _on_master_sound_slider_value_changed(value: float) -> void:
	var vol = value / 100
	
	AudioServer.set_bus_volume_linear(MasterBus,vol)
	volumeMaster = vol

func _on_bgm_slider_value_changed(value: float) -> void:
	var vol = value / 100
	AudioServer.set_bus_volume_linear(BGMBus, vol)
	volumeBGM = vol

func _on_sfx_slider_value_changed(value: float) -> void:
	var vol = value / 100
	MasterContr.set_sfx_volume(vol)
	volumeSFX = vol
func _on_sfx_slider_drag_ended(value_changed: bool) -> void:
	MasterContr.play_button(soundQuaseGol)


func _on_check_box_toggled(toggled_on: bool) -> void:
	# Muta o MasterBus se estiver marcado, desmuta se for desmarcado
	AudioServer.set_bus_mute(MasterBus, toggled_on)
