local M = G.Class("FoodMarketAvatarBtnDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GeLianFoodMarket/FoodMarketAvatarBtnDialog"
  self.config.type = EUIType.Dialog
  self._uid = nil
  self._show_chat = false
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_bg)
  self:bind_callback(self._btn_visit, pack(self, M._on_btn_visit))
  self:bind_callback(self._btn_chat, pack(self, M._on_btn_chat))
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._uid = data.uid
  self._show_chat = data.show_chat == true
  self:_align_to_avatar(data.align_target, data.offset)
  UIUtil.set_active(self._btn_visit, true)
  UIUtil.set_active(self._btn_chat, self._show_chat)
end

function M:_align_to_avatar(align_target, offset)
  if is_null(align_target) then
    return
  end
  local pos = CsUIUtil.CalculateCanvasLocalPosition(align_target, UIManagerInstance.canvas_rect, 0, 0.5)
  local pos_x, pos_y = pos.x, pos.y
  if not_null(offset) then
    pos_x = pos_x + offset.x
    pos_y = pos_y + offset.y
  end
  self._trans_content.anchoredPosition = Vector2(pos_x, pos_y)
end

function M:_on_btn_chat()
  local uid = self._uid
  if uid == nil then
    return
  end
  self:close_self()
  social_module:open_star_friend_social_page(uid, social_module.open_view_type.friend, social_module.open_sub_view_type.chat)
end

function M:_on_btn_visit()
  local uid = self._uid
  if uid == nil then
    return
  end
  self:close_self()
  social_module:request_visit_player_mainland(social_module.social_transport_entry_source.gelian_food_market_message, uid)
  UIUtil.show_tips_by_text_id("Visit_quest")
end

return M
