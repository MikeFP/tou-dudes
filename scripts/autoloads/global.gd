extends Node

enum TileType {
    BOUNDS,
    GROUND,
    WALL,
    DESTRUCTURE
}

func enum_as_string(enum_type, value):
    return str(enum_type.keys()[value])

func random_choice(array: Array, weights: Array):
    assert(array.size() == weights.size())
    
    var sum:float = 0.0
    for val in weights:
        sum += val
        
    var normalizedWeights = []
    
    for val in weights:
        normalizedWeights.append(val / sum)
    
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var rnd = rng.randf()
    
    var i = 0
    var summer:float = 0.0
    
    for val in normalizedWeights:
        summer += val
        if summer >= rnd:
            return array[i]
        i += 1
