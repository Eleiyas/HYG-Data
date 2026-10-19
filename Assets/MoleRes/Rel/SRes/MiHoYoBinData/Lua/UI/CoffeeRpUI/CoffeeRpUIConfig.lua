local CoffeeRpUIConfig = {}
CoffeeRpUIConfig.SLOT_COUNT = {
  COFFEE = 9,
  PLAYER = 4,
  ORDER_STEP = 4
}
CoffeeRpUIConfig.OPEN_CONTEXT = {
  NORMAL = 0,
  GPT_SELF = 1,
  GPT_TARGET = 2,
  GPT_MULTI = 3,
  INVITE_CONFIRM = 4
}
CoffeeRpUIConfig.UI_STATE = {
  MAIN = "main",
  PLAYERS = "players",
  ORDER = "order",
  TASTE = "taste",
  INVITE = "invite",
  INVITE_TASTE = "invite_taste"
}
CoffeeRpUIConfig.TASTE_VALUE = {
  LOW = -1,
  NORMAL = 0,
  HIGH = 1
}
CoffeeRpUIConfig.ORDER_STATUS = {WAIT_INIT = 1}
CoffeeRpUIConfig.INVITE_TIMEOUT = {CONFIRM = 10, TASTE = 5}
CoffeeRpUIConfig.TOGGLE_CHILD_INDEX = {OFF = 0, ON = 1}
return CoffeeRpUIConfig
