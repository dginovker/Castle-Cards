class_name PauseMenu
extends Control

signal resume_pressed
signal restart_pressed
signal main_menu_pressed

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    
    resume_button.pressed.connect(_on_resume_pressed)
    restart_button.pressed.connect(_on_restart_pressed)
    main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_resume_pressed() -> void:
    resume_pressed.emit()

func _on_restart_pressed() -> void:
    restart_pressed.emit()

func _on_main_menu_pressed() -> void:
    main_menu_pressed.emit()

func show_pause() -> void:
    visible = true
    get_tree().paused = true

func hide_pause() -> void:
    visible = false
    get_tree().paused = false
