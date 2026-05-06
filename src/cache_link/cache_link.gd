class_name CacheLink extends RefCounted

const item_widget_scene: PackedScene = preload("res://main/ui/menu/game_menu/inventory_widget/item_widget/item_widget.tscn")
const cache_interface_widget_scene: PackedScene = preload("res://cache_link/cache_interface_widget.tscn")

static var initialized: bool = false
static var cache_interface_widget: CacheInterfaceWidget

static func ensure_initialized() -> void:
    if initialized:
        return
    initialized = true

    cache_interface_widget = cache_interface_widget_scene.instantiate()
    cache_interface_widget.name = "CacheInterfaceWidget"
    var hidden_container: VBoxContainer = Ref.game_menu.get_node("HUDContainer/ScreenContainer/HiddenContainer")
    hidden_container.add_child(cache_interface_widget)
    hidden_container.move_child(cache_interface_widget, 1)

static func open_interface(cache_cube: CacheCube) -> void:
    CacheLink.ensure_initialized()
    cache_interface_widget.initialize(cache_cube)

static func close_interface() -> void:
    cache_interface_widget.reset()

static func get_connected_cache_cubes(cache_cube: CacheCube) -> Array[CacheCube]:
    var cache_cubes: Array[CacheCube] = []

    var visited: Dictionary[Vector3, bool] = {}
    var stack: Array[CacheCube] = [cache_cube]
    while not stack.is_empty():
        var current_cache_cube = stack.pop_back()
        if visited.has(current_cache_cube.global_position):
            continue
        visited[current_cache_cube.global_position] = true

        cache_cubes.append(current_cache_cube)

        for direction in [Vector3.LEFT, Vector3.RIGHT, Vector3.DOWN, Vector3.UP, Vector3.FORWARD, Vector3.BACK]:
            var neighbor_pos = current_cache_cube.global_position + direction
            if not visited.has(neighbor_pos):
                var neighbor_cache_cube = Ref.world.get_living_block_at(neighbor_pos)
                if neighbor_cache_cube and neighbor_cache_cube is CacheCube and neighbor_cache_cube.style == cache_cube.style:
                    stack.append(neighbor_cache_cube)

    cache_cubes.sort_custom(_compare_cache_cubes_by_pos)
    return cache_cubes

static func _compare_cache_cubes_by_pos(a: CacheCube, b: CacheCube) -> bool:
    var a_position: Vector3 = a.global_position
    var b_position: Vector3 = b.global_position

    if a_position.x != b_position.x:
        return a_position.x < b_position.x
    if a_position.y != b_position.y:
        return a_position.y < b_position.y
    return a_position.z < b_position.z

static func set_held_item(item_state: ItemState, initial_position: Vector2 = Vector2.ZERO) -> void:
    if item_state == null or item_state.count <= 0:
        if InventorySlot.state == InventorySlot.HOLDING_ITEM:
            InventorySlot.held_item.queue_free()
            InventorySlot.held_item = null
            InventorySlot.state = InventorySlot.IDLE
    else:
        if InventorySlot.state == InventorySlot.IDLE:
            InventorySlot.held_item = item_widget_scene.instantiate()
            InventorySlot.held_item.initialize(item_state)
            Ref.ui.add_child(InventorySlot.held_item)
            InventorySlot.held_item.position = initial_position
            InventorySlot.held_item.follow_mouse = true
        else:
            InventorySlot.held_item.initialize(item_state)
        InventorySlot.state = InventorySlot.HOLDING_ITEM

static func make_item_state(item: Item, count: int, durability: int = -1) -> ItemState:
    if item == null or count <= 0:
        return null

    var item_state: ItemState = ItemState.new()
    item_state.initialize(item)
    item_state.count = count
    if durability != -1:
        item_state.durability = durability
    return item_state
