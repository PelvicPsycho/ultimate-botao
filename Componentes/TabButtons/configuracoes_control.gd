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

@onready var TimerTypeLabel = $OptionsContainer/Control/VLabelsContainer/HBoxContainer/HBoxContainer/Label
@onready var timerTypes  = ["Timer", "Chess clock", "Shots count"]
var timerIndex = 0



func _ready() -> void:
	await get_tree().process_frame
	# Atualiza a posição visual dos Sliders (assumindo que vão de 0 a 100)
	MasterSoundSlider.value = SoundMaster.volume_master
	BGMSlider.value = SoundMaster.volume_BGM
	SFXSlider.value = SoundMaster.volume_SFX
	
	# Atualiza o CheckBox de Mute
	Checkbox.button_pressed = AudioServer.is_bus_mute(MasterBus)
	
	TimerTypeLabel.text  = timerTypes[timerIndex]


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


func _on_timer_back_pressed():
	timerIndex -= 1
	if timerIndex < 0:
		timerIndex = timerTypes.size() - 1
	TimerTypeLabel.text = timerTypes[timerIndex]
	GameState.TimerType = timerIndex
	print(GameState.TimerType)

func _on_timer_forward_pressed():
	timerIndex += 1
	if timerIndex > timerTypes.size() - 1:
		timerIndex = 0
	TimerTypeLabel.text = timerTypes[timerIndex]
	GameState.TimerType = timerIndex
	print(GameState.TimerType)
