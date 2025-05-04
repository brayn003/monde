extends Node

const WORLD_BOUND_TOP = Vector2(2000, 0)
const WORLD_BOUND_RIGHT = Vector2(4000, 1000)
const WORLD_BOUND_BOTTOM = Vector2(2000, 2000)
const WORLD_BOUND_LEFT = Vector2(0, 1000)

const PIKI_MAX_HP = 10.0
const PIKI_MAX_ENERGY = 100.0
const PIKI_INITIAL_ENERGY = 20.0
const PIKI_THRUST = Vector2(200, 0)
const PIKI_TORQUE = 200.0
const PIKI_VISION_RANGE = 1000.0
const PIKI_VISION_ANGLE = (TAU) / 1.5  # 180 deg
const PIKI_SIZE = 10.0
const PIKI_CLOCK_SPEED = 2 # in Hz - no of times per sec

const AIKO_MAX_HP = 100.0
const AIKO_MAX_ENERGY = 200.0
const AIKO_THRUST = Vector2(300, 0)
const AIKO_TORQUE = 2000.0
const AIKO_VISION_RANGE = 5000.0
const AIKO_VISION_ANGLE = (TAU) / 4  # 120 deg
const AIKO_SIZE = 40.0
const AIKO_CLOCK_SPEED = 20 # in Hz - no of times per sec

const PLANT_SIZE = 1.0
const PLANT_MAX_HP = 10.0
const PLANT_MAX_ENERGY = 100.0
const PLANT_CLOCK_SPEED = 1.0 # 1 in 1 second

const FRUIT_SIZE = 5.0
const FRUIT_ENERGY = 30.0

const MAX_FRUITS = 2000
const MAX_PIKIS = 200
