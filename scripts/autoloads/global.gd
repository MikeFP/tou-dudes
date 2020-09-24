extends Node

enum TileType {
    BOUNDS,
    GROUND,
    WALL,
    DESTRUCTURE
}

func enum_as_string(enum_type, value):
    return str(enum_type.keys()[value])