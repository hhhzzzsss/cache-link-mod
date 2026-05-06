class_name MultiInventory extends RefCounted

signal refresh()

var capacity: int

var inventories: Array[Inventory]
var slot_mapping: Array[Vector2i]
var inventory_index_mapping: Array[int]

func _init(_inventories: Array[Inventory]) -> void:
    inventories = _inventories

    capacity = 0
    for inventory in _inventories:
        inventory_index_mapping.append(capacity)
        capacity += inventory.capacity

    slot_mapping = []
    for i in range(_inventories.size()):
        for j in range(_inventories[i].capacity):
            slot_mapping.append(Vector2i(i, j))

    for inventory in inventories:
        inventory.refresh.connect(func (_index): refresh.emit())

func get_max_extractable(item: Item) -> int:
    var total: int = 0
    for inventory in inventories:
        for item_state in inventory.items:
            if item_state != null and item_state.id == item.id:
                total += item_state.count
    return total

func extract(item: Item, max_amount: int, durability: int) -> ItemState:
    var remaining: int = max_amount
    for i in range(inventories.size() - 1, -1, -1):
        var source_inventory = inventories[i]
        for j in range(source_inventory.capacity - 1, -1, -1):
            var item_state: ItemState = source_inventory.items[j]
            if item_state != null and item_state.id == item.id and item_state.durability == durability:
                var to_extract: int = min(remaining, item_state.count)
                item_state.count -= to_extract
                remaining -= to_extract
                if item_state.count <= 0:
                    source_inventory.set_item(j, null)
                else:
                    source_inventory.set_item(j, item_state)

                if remaining <= 0:
                    return CacheLink.make_item_state(item, max_amount, durability)
    
    return CacheLink.make_item_state(item, max_amount - remaining, durability)

func get_items() -> Array[ItemState]:
    var result: Array[ItemState] = []
    for inventory in inventories:
        for item in inventory.items:
            result.append(item)
    return result

func set_item(index: int, item_state: ItemState) -> void:
    var i = slot_mapping[index].x
    var j = slot_mapping[index].y
    var inventory = inventories[i]
    inventory.set_item(j, item_state)

func get_used_slots() -> int:
    var count: int = 0
    for inventory in inventories:
        for item in inventory.items:
            if item != null:
                count += 1
    return count

func get_total_slots() -> int:
    var count: int = 0
    for inventory in inventories:
        count += inventory.capacity
    return count
