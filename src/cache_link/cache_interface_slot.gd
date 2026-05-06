class_name CacheInterfaceSlot extends TextureRect

@export var normal_texture: Texture
@export var hover_texture: Texture
@export var item_widget_scene: PackedScene

var has_default_icon: bool = false
var has_input_icon: bool = false
var has_output_icon: bool = false
var has_trash_icon: bool = false

var interface_widget: CacheInterfaceWidget
var item_widget: DenseItemWidget
var item_state: ItemState
var index: int = 0
var hovered_over: bool = false



func _ready() -> void :
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    visibility_changed.connect(_on_visibility_changed)
    Ref.game_menu.inventory_closed.connect(_on_inventory_closed)
    Ref.game_menu.inventory_opened.connect(_on_inventory_opened)

func initialize(_item_state: ItemState) -> void:
    item_state = _item_state

    if is_instance_valid(item_widget):
        item_widget.queue_free()

    %ItemPopup.initialize(_item_state)

    if _item_state != null:
        var new_widget: DenseItemWidget = item_widget_scene.instantiate()
        new_widget.initialize(item_state)
        add_child(new_widget)

        item_widget = new_widget
    else:
        item_widget = null

func can_hold(_other_item: Item) -> bool:
    return true

func _on_inventory_opened() -> void :
    set_process_input(true)

func _on_inventory_closed() -> void :
    set_process_input(false)

func _on_visibility_changed() -> void :
    set_process_input(visible and is_visible_in_tree())
    if (not is_visible_in_tree()):
        hovered_over = false
        texture = normal_texture
        %ItemPopup.exit()

func _on_mouse_entered() -> void :
    if Ref.game_menu.state == GameMenu.DEFAULT:
        return

    hovered_over = true
    texture = hover_texture
    if item_state != null:
        %ItemPopup.enter()

    # if Input.is_action_pressed("half_deposit") and Input.is_action_pressed("deposit") and state == HOLDING_ITEM:
    #     deposit(self, true)
    # elif Input.is_action_pressed("deposit") and state == HOLDING_ITEM:
    #     deposit(self)

func _on_mouse_exited() -> void :
    if Ref.game_menu.state == GameMenu.DEFAULT:
        return

    hovered_over = false
    texture = normal_texture
    %ItemPopup.exit()

func _input(event: InputEvent) -> void :
    if not visible or not is_visible_in_tree():
        return

    if not hovered_over or InventorySlot.state == InventorySlot.HOLDING_ITEM or not item_state:
        return

    if event.is_action_pressed("select", false) and Input.is_action_pressed("transfer_stack_secondary"):
        interface_widget.transfer_stack(item_state, true)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("select", false) and Input.is_action_pressed("transfer_stack"):
        interface_widget.transfer_stack(item_state)
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("select", false):
        interface_widget.pick_up(item_state)
        get_viewport().set_input_as_handled()
