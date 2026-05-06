class_name InventoryWidgetProxy extends InventoryWidget

var multi_inventory: MultiInventory

func _init() -> void:
    pass

func _ready() -> void:
    pass

func initialize_proxy(_multi_inventory: MultiInventory) -> void:
    multi_inventory = _multi_inventory

    for child in get_children():
        remove_child(child)
        child.queue_free()

    for i in range(multi_inventory.capacity):
        add_child(InventorySlotProxy.new())

func update() -> void:
    var items: Array[ItemState] = multi_inventory.get_items()
    for i in range(multi_inventory.capacity):
        get_child(i).item = items[i]
