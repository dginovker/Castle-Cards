class_name GameOverScreen
extends CanvasLayer

signal retry_pressed
signal main_menu_pressed

@onready var title_label: Label = %TitleLabel
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	hide()

func show_win() -> void:
	title_label.text = "You Win!"
	retry_button.hide()
	show()

func show_lose() -> void:
	title_label.text = "You Lose!"
	retry_button.show()
	show()

func _on_retry_pressed() -> void:
	retry_pressed.emit()

func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()
