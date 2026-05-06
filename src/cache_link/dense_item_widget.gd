class_name DenseItemWidget extends Control

const order_abbr = ["", "K", "M", "B", "T"]

@export var progress_color: GradientTexture1D
@export var under_color: GradientTexture1D

var item: ItemState

func _ready() -> void :
    set_process(false)
    %DurabilityBar.set_instance_shader_parameter("offset", Vector2(randf(), randf()))
    %Label.set_instance_shader_parameter("offset", Vector2(randf(), randf()))
    %Icon.set_instance_shader_parameter("offset", Vector2(randf(), randf()))

func initialize(new_item: ItemState) -> void :
    item = new_item

    if item == null:
        visible = false
        return

    var r_item: Item = ItemMap.map(item.id)

    %Icon.texture = r_item.icon
    set_count(item.count)

    %DurabilityBar.visible = r_item.max_durability > 0 and item.durability != r_item.max_durability
    if %DurabilityBar.visible:
        set_durability(item.durability / float(r_item.max_durability))

func set_count(count: int) -> void:
    var magnitude = 0
    var mantissa: float = float(count)
    while mantissa >= 1000:
        mantissa /= 1000
        magnitude += 1
    
    
    var mantissa_str: String
    if magnitude == 0:
        mantissa_str = str(roundi(mantissa))
    elif mantissa < 10:
        mantissa_str = "%.02f" % (roundf(mantissa * 100) / 100)
    elif mantissa < 100:
        mantissa_str = "%.01f" % (roundf(mantissa * 10) / 10)
    else:
        mantissa_str = str(roundi(mantissa))
    mantissa_str = mantissa_str.replace(".", " . ")

    %Label.text = mantissa_str + order_abbr[magnitude]

func set_durability(progress: float) -> void :
    %DurabilityBar.tint_progress = progress_color.gradient.sample(progress)
    %DurabilityBar.tint_under = under_color.gradient.sample(progress)
    %DurabilityBar.value = progress
