local JUMP_ITEM_CLS = "UI/CommonUI/CommonCoinLackJumpItem"
local ITEM_V2_PANEL_CLS = "UI/Item/ItemV2Panel"
local DEFAULT_TITLE_KEY = "Common_Coin_Lack_Title"
local COIN_LACK_CONFIG = {
  [200008] = {
    jumps = {
      {
        text_key = "Common_Coin_Lack_Jump_SeasonDaily",
        jump = function()
          theme_season_module:open_daily_page()
        end
      },
      {
        text_key = "Common_Coin_Lack_Jump_BP",
        jump = function()
          theme_season_module:open_bp_pay_page()
        end
      }
    }
  },
  [200009] = {
    jumps = {
      {
        text_key = "Common_Coin_Lack_Jump_NPC_Exchange",
        jump = function()
          theme_season_module:open_npc_impression_hall_page()
        end
      }
    }
  }
}
local M = G.Class("CommonCoinLackDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonCoindLackDialog"
  self.config.type = EUIType.Dialog
  self._coin_id = 0
  self._title_key = nil
  self._on_jump = nil
  self._item_v2_panel = nil
  self._jump_items = {}
  self._txt_title = nil
  self._btn_item_v2_basic = nil
  self._list_content = nil
  self._btn_close = nil
  self._btn_close_bg = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_create_item_v2_panel()
end

function M:on_enable()
  base.on_enable(self)
  local ctx = self:get_extra_data() or {}
  self._coin_id = ctx.coin_id or 0
  self._title_key = ctx.title_key
  self._on_jump = ctx.on_jump
  self:_refresh_title()
  self:_refresh_coin()
  self:_refresh_jump_list()
end

function M:on_destroy()
  self._jump_items = {}
  self._on_jump = nil
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not_null(self._btn_close) then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
end

function M:_add_ui_listener()
  if not_null(self._btn_close) then
    self:bind_close_btn(self._btn_close)
  end
  if not_null(self._btn_close_bg) then
    self:bind_close_btn(self._btn_close_bg)
  end
end

function M:_create_item_v2_panel()
  if is_null(self._btn_item_v2_basic) then
    return
  end
  self._item_v2_panel = self:add_panel(ITEM_V2_PANEL_CLS, self._btn_item_v2_basic)
end

function M:_refresh_title()
  if is_null(self._txt_title) then
    return
  end
  local cfg = COIN_LACK_CONFIG[self._coin_id]
  local title_key = self._title_key or cfg and cfg.title_key or DEFAULT_TITLE_KEY
  UIUtil.set_text_by_id(self._txt_title, title_key)
end

function M:_refresh_coin()
  if self._item_v2_panel == nil then
    return
  end
  self._item_v2_panel:set_item_data(self._coin_id, nil)
  self._item_v2_panel:bind_item_info_btn(self._coin_id)
end

function M:_refresh_jump_list()
  local cfg = COIN_LACK_CONFIG[self._coin_id]
  local jumps = cfg and cfg.jumps or {}
  for index = 1, #jumps do
    local item = self._jump_items[index]
    if item == nil then
      item = self:_create_jump_item()
      self._jump_items[index] = item
    end
    if item ~= nil then
      item:set_active(true)
      item:set_data(self:_wrap_jump_data(jumps[index]))
    end
  end
  for i = #jumps + 1, #self._jump_items do
    local item = self._jump_items[i]
    if item ~= nil then
      item:set_active(false)
    end
  end
end

function M:_create_jump_item()
  if is_null(self._list_content) then
    return nil
  end
  local obj = self._list_content:AddItem(0)
  if is_null(obj) then
    return nil
  end
  return self:add_panel(JUMP_ITEM_CLS, obj)
end

function M:_wrap_jump_data(entry)
  local raw_jump = entry.jump
  local wrapped_jump
  if type(raw_jump) == "function" then
    function wrapped_jump()
      raw_jump()
      
      local on_jump = self._on_jump
      self:close_self()
      if type(on_jump) == "function" then
        on_jump()
      end
    end
  end
  return {
    text_key = entry.text_key,
    jump = wrapped_jump
  }
end

return M
