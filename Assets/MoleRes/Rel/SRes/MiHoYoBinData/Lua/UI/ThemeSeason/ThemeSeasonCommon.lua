theme_season_module = theme_season_module or {}
theme_season_module.season_state = {
  locked = 0,
  active = 1,
  ended = 2
}
theme_season_module.bp_exchange_type = {free = 0, paid = 1}
theme_season_module.BP_TIER = {
  NONE = 0,
  SINGLE_COMMON = 1,
  SINGLE_LUXURY = 2,
  DOUBLE_COMMON = 3,
  DOUBLE_LUXURY = 4
}
theme_season_module.BP_SLOT = {
  SINGLE_COMMON = 1,
  SINGLE_LUXURY = 2,
  DOUBLE_COMMON = 3,
  DOUBLE_LUXURY = 4
}
theme_season_module.BP_SLOT_STATE = {
  PURCHASABLE = 0,
  PURCHASED = 1,
  GIFTABLE = 2,
  GIFTED = 3,
  UNAVAILABLE = 4
}
theme_season_module.GIFT_BLOCK_REASON = {
  NONE = 0,
  NOT_FRIEND = 1,
  SEASON_NOT_OPEN = 2,
  ALREADY_HAS_BP = 3
}
theme_season_module.GIFT_ITEM_NUM = 1
theme_season_module.LEVEL_STATE = {
  OBTAINED = 0,
  LOCKED = 1,
  CURRENT = 2,
  FINAL = 3
}
theme_season_module.GRADUATE_EXCHANGE_STATE = {
  LOCKED = 0,
  AVAILABLE = 1,
  EXCHANGED = 2,
  LACKED_COIN = 3
}
theme_season_module.HUD_TIP_DURATION_SEC = 3
theme_season_module.DAILY_MISSION_STATE = {
  UNFINISHED = 0,
  CLAIMABLE = 1,
  CLAIMED = 2
}
theme_season_module.CHAPTER_STATE = {
  IN_PROGRESS = 0,
  CLAIMABLE = 1,
  LOCKED = 2,
  CLAIMED = 3
}
theme_season_module.CHAPTER_UNLOCK_REASON = {
  NONE = 0,
  TIME = 1,
  PREV_TASK = 2
}
theme_season_module.CONST_TYPE = {
  FORBID_BUY_BP_MINUTES = "THEME_SEASON_CONST_FORBID_BUY_BP_MINUTES",
  FORBID_GIFT_BP_MINUTES = "THEME_SEASON_CONST_FORBID_GIFT_BP_MINUTES",
  FORBID_TELEPORT_SCENE_MINUTES = "THEME_SEASON_CONST_FORBID_TELEPORT_SCENE_MINUTES",
  BP_GIFT_AUTO_RETURN_HOURS = "THEME_SEASON_CONST_BP_GIFT_AUTO_RETURN_HOURS"
}
theme_season_module.REPORT_PAGE_ID = {
  MAIN = 1,
  PLOT = 2,
  CHAPTER_DETAIL = 3,
  BP_PAY = 4,
  DAILY = 5,
  NPC_IMPRESSION_HALL = 6,
  GRADUATION = 7,
  BP_GIFT_RECEIVE = 8
}
theme_season_module.BP_GIFT_GIVING_PAGE_CLOSE_DELAY = 1.6
theme_season_module.ANIM_TRIGGER = {
  IN = "in",
  OUT = "out",
  GET = "get",
  NEXT = "next",
  FIRST_GET = "first_get"
}
theme_season_module.MAIN_PAGE_ANIM = {
  FIRST_IN = "anim_battlepass_mainpage_firstin",
  IN = "anim_battlepass_mainpage_in",
  OUT = "anim_battlepass_mainpage_out"
}
theme_season_module.ITEM_ENTER_STAGGER_SEC = 0.03
return theme_season_module
