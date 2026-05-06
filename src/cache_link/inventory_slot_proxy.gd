class_name InventorySlotProxy extends InventorySlot

var multi_inventory: MultiInventory

func _init() -> void:
    pass

func _ready() -> void:
    pass

func can_hold(_other_item: Item) -> bool:
    return true
