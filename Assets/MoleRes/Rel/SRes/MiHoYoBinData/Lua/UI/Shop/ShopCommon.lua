shop_module = shop_module or {}
shop_module.shop_page_type = {
  none = -1,
  resident = 1,
  everyday = 2
}
shop_module.shop_buy_state = {
  none = -1,
  buy = 1,
  currency_lack_of = 2,
  good_lack_of = 3
}
shop_module.shop_select_bg_path = {
  "UISprite/Load/Quality/Bg_Quality_White_Shop_Select",
  "UISprite/Load/Quality/Bg_Quality_Green_Shop_Select",
  "UISprite/Load/Quality/Bg_Quality_Blue_Shop_Select",
  "UISprite/Load/Quality/Bg_Quality_Purple_Shop_Select"
}
shop_module.glenn_shop_tab = {sell = 1, buy = 2}
return shop_module or {}
