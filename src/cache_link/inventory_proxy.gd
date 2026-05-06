class_name InventoryProxy extends Inventory

var multi_inventory: MultiInventory

func _init() -> void:
    pass

func _ready() -> void:
    widget = InventoryWidgetProxy.new()
    add_child(widget)

func initialize(_multi_inventory: MultiInventory) -> void:
    multi_inventory = _multi_inventory
    capacity = multi_inventory.capacity

    widget.initialize_proxy(multi_inventory)

func update() -> void:
    widget.update()

func set_item(index: int, item_state: ItemState) -> void:
    multi_inventory.set_item(index, item_state)
