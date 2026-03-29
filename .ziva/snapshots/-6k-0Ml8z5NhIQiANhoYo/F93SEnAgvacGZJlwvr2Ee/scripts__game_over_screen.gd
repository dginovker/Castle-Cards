class_name GameOverScreen
extends CanvasLayer

signal retry_pressed
signal main_menu_pressed

@onready var title_label: Label = %TitleLabel
@onready var reward_badge: PanelContainer = %RewardBadge
@onready var reward_label: Label = %RewardLabel
@onready var retry_button: Button = %RetryButton
@onready var main_menu_button: Button = %MainMenuButton

func _ready() -> void:
    retry_button.pressed.connect(_on_retry_pressed)
    main_menu_button.pressed.connect(_on_main_menu_pressed)
    
    retry_button.mouse_entered.connect(_on_button_mouse_entered.bind(retry_button))
    retry_button.mouse_exited.connect(_on_button_mouse_exited.bind(retry_button))
    main_menu_button.mouse_entered.connect(_on_button_mouse_entered.bind(main_menu_button))
    main_menu_button.mouse_exited.connect(_on_button_mouse_exited.bind(main_menu_button))
    
    reward_badge.pivot_offset = Vector2(100, 40) # Approximate center
    hide()

func _on_button_mouse_entered(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)

func _on_button_mouse_exited(button: Button) -> void:
    var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)

func show_win(reward_amount: int = 0) -> void:
    title_label.text = "You Win!"
    if reward_amount > 0:
        reward_label.text = "+" + str(reward_amount)
        reward_badge.show()
        # Wait a frame to get the correct size for the pivot
        await get_tree().process_frame
        reward_badge.pivot_offset = reward_badge.size / 2.0
        
        # Pop animation
        reward_badge.scale = Vector2.ZERO
        var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.tween_property(reward_badge, "scale", Vector2.ONE, 0.5)
    else:
        reward_badge.hide()
    retry_button.hide()
    show()

func show_lose() -> void:
    title_label.text = "You Lose!"
    reward_badge.hide()
    retry_button.show()
    show()

func _on_retry_pressed() -> void:
    retry_pressed.emit()

func _on_main_menu_pressed() -> void:
    main_menu_pressed.emit()
