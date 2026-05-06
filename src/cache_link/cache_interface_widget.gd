class_name CacheInterfaceWidget extends Control

@export var inferface_slot_scene: PackedScene
@export var normal_slot_label_color: Color
@export var warning_slot_label_color: Color
@export var full_slot_label_color: Color

var num_columns: int
var num_displayed_rows: int

var clicked_cache_cube: CacheCube
var opened_cache_cubes: Array[CacheCube]
var single_inventory: Inventory
var multi_inventory: MultiInventory
var inventory_proxy: InventoryProxy
var slot_states: Array[ItemState] = []

func _ready() -> void:
    num_columns = %SlotGrid.columns
    num_displayed_rows = roundi(%ScrollBar.page)
    for i in range(num_displayed_rows * num_columns):
        var new_slot: CacheInterfaceSlot = inferface_slot_scene.instantiate()
        new_slot.interface_widget = self
        %SlotGrid.add_child(new_slot)

    %ScrollBar.max_value = 0

    inventory_proxy = InventoryProxy.new()
    add_child(inventory_proxy)

func initialize(_clicked_cache_cube: CacheCube) -> void:
    clicked_cache_cube = _clicked_cache_cube
    opened_cache_cubes = CacheLink.get_connected_cache_cubes(_clicked_cache_cube)
    single_inventory = _clicked_cache_cube.get_node("%Inventory")

    var connected_inventories: Array[Inventory] = []
    for cc in opened_cache_cubes:
        connected_inventories.append(cc.get_node("%Inventory"))
    multi_inventory = MultiInventory.new(connected_inventories)

    inventory_proxy.initialize(multi_inventory)
    InventorySlot.cache_cube_inventory = inventory_proxy

    for cc in opened_cache_cubes:
        cc.open = true

    update()
    visible = true
    
    multi_inventory.refresh.connect(update)
    %SearchBar.text_changed.connect(_on_text_changed)
    %ScrollBar.value_changed.connect(_on_scroll_bar_value_changed)
    %SearchBar.focus_entered.connect(_on_search_bar_focus_entered)
    %SearchBar.focus_exited.connect(_on_search_bar_focus_exited)
    Ref.game_menu.inventory_closed.connect(reset)
    %ShowIndividualButton.connect("pressed", show_individual_cache_cube)

    set_process_input(true)

func show_individual_cache_cube() -> void:
    clicked_cache_cube.open = true
    InventorySlot.cache_cube_inventory = single_inventory
    Ref.game_menu.get_node("%CacheCubeContainer").visible = true

    reset()

func reset() -> void:
    # Skip if already reset
    if multi_inventory == null:
        return

    multi_inventory.refresh.disconnect(update)
    %SearchBar.text_changed.disconnect(_on_text_changed)
    %ScrollBar.value_changed.disconnect(_on_scroll_bar_value_changed)
    %SearchBar.focus_entered.disconnect(_on_search_bar_focus_entered)
    %SearchBar.focus_exited.disconnect(_on_search_bar_focus_exited)
    Ref.game_menu.inventory_closed.disconnect(reset)
    %ShowIndividualButton.disconnect("pressed", show_individual_cache_cube)

    for cc in opened_cache_cubes:
        cc.open = false

    opened_cache_cubes = []
    single_inventory = null
    multi_inventory = null
    slot_states = []
    %SearchBar.text = ""
    if %SearchBar.has_focus():
        %SearchBar.release_focus()

    update_displayed_items()
    visible = false
    
    set_process_input(false)
    Ref.game_menu.set_process_input(true)

func update() -> void:
    var search_text = %SearchBar.text
    slot_states = get_aggregated_items() \
        .filter(func(item): return _matches_search(item, search_text))

    %ScrollBar.max_value = (slot_states.size() + num_columns - 1) / num_columns
    %ScrollBar.page = num_displayed_rows

    update_displayed_items()
    _set_slot_label()

    inventory_proxy.update()

func update_displayed_items() -> void:
    for row in range(num_displayed_rows):
        for column in range(num_columns):
            var child_index: int = row * num_columns + column
            var slot_index: int = int(%ScrollBar.value) * num_columns + child_index
            var slot: CacheInterfaceSlot = %SlotGrid.get_child(child_index)
            if slot_index < slot_states.size():
                var item_state: ItemState = slot_states[slot_index]
                slot.initialize(item_state)
            else:
                slot.initialize(null)

func get_aggregated_items() -> Array[ItemState]:
    var unique_item_map: Dictionary[String, ItemState] = {}
    for inventory in multi_inventory.inventories:
        for item_state in inventory.items:
            if item_state != null:
                var key: String = _get_item_key(item_state)
                if not unique_item_map.has(key):
                    unique_item_map[key] = item_state.duplicate()
                else:
                    unique_item_map[key].count += item_state.count
    
    var unique_items: Array[ItemState] = unique_item_map.values()
    unique_items.sort_custom(_compare_items_alphabetical)
    return unique_items

func _get_item_key(item_state: ItemState) -> String:
    return str(item_state.id) + ":" + str(item_state.durability) + ":" + str(item_state.position)

func _compare_items_alphabetical(a: ItemState, b: ItemState) -> bool:
    var a_item: Item = ItemMap.map(a.id)
    var b_item: Item = ItemMap.map(b.id)
    
    if a_item != b_item:
        return a_item.display_name < b_item.display_name
    return a.durability > b.durability

func _matches_search(item_state: ItemState, search_text: String) -> bool:
    if search_text == "":
        return true

    var item: Item = ItemMap.map(item_state.id)
    return item.display_name.to_lower().find(search_text.to_lower()) != -1

func _set_slot_label() -> void:
    var used = multi_inventory.get_used_slots()
    var total = multi_inventory.get_total_slots()
    %SlotLabel.text = str(used) + "/" + str(total) + " slots used"
    if used == total:
        %SlotLabel.modulate = full_slot_label_color
    elif used > total * 0.8:
        %SlotLabel.modulate = warning_slot_label_color
    else:
        %SlotLabel.modulate = normal_slot_label_color


func _on_text_changed(_new_text: String) -> void:
    %ScrollBar.value = 0
    update()

func _on_scroll_bar_value_changed(_value: float) -> void:
    update_displayed_items()

func _on_search_bar_focus_entered() -> void:
    Ref.game_menu.set_process_input(false)

func _on_search_bar_focus_exited() -> void:
    Ref.game_menu.set_process_input(true)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("back") and not Ref.game_menu.is_processing_input():
        Ref.game_menu.set_process_input(true)
        Ref.game_menu._input(event)
        return

    if %SearchBar.has_focus() and event is InputEventMouseButton and event.pressed and not %SearchBar.get_global_rect().has_point(event.position):
        %SearchBar.release_focus()
        
    if not is_visible_in_tree():
        return

    if event is InputEventMouseButton and event.pressed and %SlotGrid.get_global_rect().has_point(event.position):
        if InventorySlot.state == InventorySlot.IDLE:
            pass
        elif event.is_action_pressed("select") and (Input.is_action_pressed("transfer_stack") or Input.is_action_pressed("transfer_stack_secondary")):
            pass
        elif event.is_action_pressed("select", false):
            drop()
        elif Input.is_action_pressed("half_deposit") and event.is_action_pressed("deposit"):
            deposit_half()
        elif event.is_action_pressed("deposit"):
            deposit()
        elif event.is_action_pressed("collect"):
            collect()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            %ScrollBar.value -= 1
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            %ScrollBar.value += 1


func collect() -> void:
    var held_item_state: ItemState = InventorySlot.held_item.item
    var held_item_type: Item = ItemMap.map(held_item_state.id)
    var max_amount: int = held_item_type.stack_size - held_item_state.count
    var extracted: ItemState = multi_inventory.extract(held_item_type, max_amount, held_item_state.durability)
    if extracted != null:
        held_item_state.count += extracted.count
        CacheLink.set_held_item(held_item_state)
        play_drain_sound()

func pick_up(reference_item_state: ItemState) -> void:
    print(_get_item_key(reference_item_state))
    var item: Item = ItemMap.map(reference_item_state.id)
    var extracted = multi_inventory.extract(item, item.stack_size, reference_item_state.durability)
    if extracted != null:
        CacheLink.set_held_item(extracted, global_position)
    play_exit_sound()

func deposit(amount: int = 1) -> void:
    var success: bool = false
    var held_item_state: ItemState = InventorySlot.held_item.item
    var held_item_type: Item = ItemMap.map(held_item_state.id)
    var held_item_remainder: int = held_item_state.count - amount

    for destination_inventory in multi_inventory.inventories:
        for i in range(destination_inventory.capacity):
            var destination_item_state: ItemState = destination_inventory.items[i]

            if destination_item_state == null or destination_item_state.count == held_item_type.stack_size:
                continue

            if destination_item_state.id == InventorySlot.held_item.item.id:
                var total_count: int = amount + destination_item_state.count
                destination_item_state.count = min(total_count, held_item_type.stack_size)
                destination_inventory.set_item(i, destination_item_state)
                
                amount = total_count - destination_item_state.count
                held_item_state.count = held_item_remainder + amount
                if amount <= 0:
                    CacheLink.set_held_item(held_item_state)
                    play_enter_sound()
                    return
                
                success = true

    for destination_inventory in multi_inventory.inventories:
        for i in range(destination_inventory.capacity):
            var destination_item_state: ItemState = destination_inventory.items[i]

            if destination_item_state == null:
                var new_item_state: ItemState = held_item_state.duplicate()
                new_item_state.count = amount
                destination_inventory.set_item(i, new_item_state)

                held_item_state.count = held_item_remainder
                CacheLink.set_held_item(held_item_state)
                play_enter_sound()
                return

    if success:
        InventorySlot.held_item.initialize(held_item_state)
        play_enter_sound()

func deposit_half() -> void:
    var amount: int = InventorySlot.held_item.item.count / 2
    if amount > 0:
        deposit(amount)
    else:
        deposit()

func drop() -> void:
    deposit(InventorySlot.held_item.item.count)

func transfer_stack(reference_item_state: ItemState, secondary: bool = false) -> void:
    var item: Item = ItemMap.map(reference_item_state.id)
    var max_amount: int = min(multi_inventory.get_max_extractable(item), item.stack_size)
    var remaining_amount: int = max_amount
    
    var destination_inventory: Inventory = null
    var spill_over_inventory: Inventory = null

    if secondary:
        destination_inventory = Ref.player_hotbar
        spill_over_inventory = Ref.player_inventory
    else:
        destination_inventory = Ref.player_inventory
        spill_over_inventory = Ref.player_hotbar

    var success: bool = false
    for current_destination_inventory in [destination_inventory, spill_over_inventory]:
        for i in range(current_destination_inventory.capacity):
            var other_slot: InventorySlot = current_destination_inventory.widget.get_child(i)
            var slot_state: ItemState = other_slot.item

            if not other_slot.can_hold(item):
                continue

            if slot_state != null and slot_state.id == item.id and not slot_state.count == item.stack_size:
                var total_count: int = remaining_amount + slot_state.count
                slot_state.count = min(total_count, item.stack_size)
                current_destination_inventory.set_item(i, slot_state)

                remaining_amount = total_count - slot_state.count
                if remaining_amount <= 0:
                    multi_inventory.extract(item, max_amount, reference_item_state.durability)
                    play_transfer_sound()
                    return
                
                success = true

        for i in range(current_destination_inventory.capacity):
            var other_slot: InventorySlot = current_destination_inventory.widget.get_child(i)
            var slot_state: ItemState = other_slot.item

            if not other_slot.can_hold(item):
                continue

            if slot_state == null:
                var extracted_item_state: ItemState = multi_inventory.extract(item, max_amount, reference_item_state.durability)
                current_destination_inventory.set_item(i, extracted_item_state)
                play_transfer_sound()
                return

        if success:
            multi_inventory.extract(item, max_amount - remaining_amount, reference_item_state.durability)
            play_transfer_sound()


func play_enter_sound() -> void:
    %DropSound.play()

func play_exit_sound() -> void:
    %PickUpSound.play()

func play_transfer_sound() -> void:
    %TransferSound.play()

func play_drain_sound() -> void:
   %DrainSound.play()
