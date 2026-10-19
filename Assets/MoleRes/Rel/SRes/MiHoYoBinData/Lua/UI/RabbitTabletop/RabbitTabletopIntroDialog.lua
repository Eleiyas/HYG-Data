local M = G.Class("RabbitTabletopIntroDialog", G.UIWindow)
local base = G.UIWindow
local RuleGenre = {
  Title = 1,
  Desc = 2,
  Card = 3
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/RabbitTabletop/RabbitTabletopIntroDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  UIUtil.set_active(self._trans_rule_title, false)
  UIUtil.set_active(self._trans_rule_desc, false)
  UIUtil.set_active(self._trans_card_row, false)
  self._title_items = {}
  self._desc_items = {}
  self._card_rows = {}
end

function M:on_enable()
  base.on_enable(self)
  local extra = self:get_extra_data()
  local game_id = extra and extra.game_id or nil
  self:_refresh_ui(game_id)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_bg, pack(self, M._on_btn_bg_click))
  self:bind_close_btn(self._btn_close)
end

function M:_on_btn_bg_click()
  self:close_self()
end

function M:_refresh_ui(game_id)
  if game_id == nil then
    return
  end
  local rule_order = self:_find_rule_order(game_id)
  if rule_order == nil then
    return
  end
  local rule_count = rule_order.ruleidLength
  if rule_count == 0 then
    return
  end
  local rules = {}
  for i = 0, rule_count - 1 do
    local rule_cfg = ExcelDataUtil.get_value(typeof(BRuleCfg), rule_order:ruleid(i))
    if rule_cfg then
      table.insert(rules, rule_cfg)
    end
  end
  local title_idx = 1
  local desc_idx = 1
  local card_row_idx = 1
  local sibling = 0
  local i = 1
  while i <= #rules do
    local cfg = rules[i]
    local genre = cfg.genre
    if genre == RuleGenre.Title then
      local item = self:_get_or_create_title(title_idx)
      self:_fill_title(item, cfg)
      UIUtil.set_active(item.go, true)
      item.go.transform:SetSiblingIndex(sibling)
      sibling = sibling + 1
      title_idx = title_idx + 1
      i = i + 1
    elseif genre == RuleGenre.Desc then
      local item = self:_get_or_create_desc(desc_idx)
      self:_fill_desc(item, cfg)
      UIUtil.set_active(item.go, true)
      item.go.transform:SetSiblingIndex(sibling)
      sibling = sibling + 1
      desc_idx = desc_idx + 1
      i = i + 1
    elseif genre == RuleGenre.Card then
      local card_rules = {}
      while i <= #rules and rules[i].genre == RuleGenre.Card do
        table.insert(card_rules, rules[i])
        i = i + 1
      end
      local row_count = math.ceil(#card_rules / 2)
      for row_offset = 1, row_count do
        local row = self:_get_or_create_card_row(card_row_idx)
        local left_rule_idx = (row_offset - 1) * 2 + 1
        self:_fill_card(row.left, card_rules[left_rule_idx])
        self:_fill_card(row.right, card_rules[left_rule_idx + 1])
        UIUtil.set_active(row.go, true)
        row.go.transform:SetSiblingIndex(sibling)
        sibling = sibling + 1
        card_row_idx = card_row_idx + 1
      end
    else
      i = i + 1
    end
  end
  for j = title_idx, #self._title_items do
    UIUtil.set_active(self._title_items[j].go, false)
  end
  for j = desc_idx, #self._desc_items do
    UIUtil.set_active(self._desc_items[j].go, false)
  end
  for j = card_row_idx, #self._card_rows do
    UIUtil.set_active(self._card_rows[j].go, false)
  end
end

function M:_find_rule_order(game_id)
  local tbl = ExcelDataUtil.get_table(typeof(BRuleOrderCfg))
  if is_null(tbl) then
    return nil
  end
  for _, v in pairs(tbl) do
    if v.gameid == game_id then
      return v
    end
  end
  return nil
end

function M:_get_or_create_title(idx)
  if self._title_items[idx] then
    return self._title_items[idx]
  end
  local go = GameObject.Instantiate(self._trans_rule_title.gameObject, self._trans_rule_parent)
  local text = UIUtil.find_text(go.transform, "txt_title_dynamic")
  local item = {go = go, text = text}
  self._title_items[idx] = item
  return item
end

function M:_fill_title(item, rule_cfg)
  if not_null(item.text) then
    UIUtil.set_text_by_id(item.text, rule_cfg.text)
  end
end

function M:_get_or_create_desc(idx)
  if self._desc_items[idx] then
    return self._desc_items[idx]
  end
  local go = GameObject.Instantiate(self._trans_rule_desc.gameObject, self._trans_rule_parent)
  local text = UIUtil.find_text(go.transform)
  local item = {go = go, text = text}
  self._desc_items[idx] = item
  return item
end

function M:_fill_desc(item, rule_cfg)
  if not_null(item.text) then
    UIUtil.set_text_by_id(item.text, rule_cfg.text)
  end
end

function M:_get_or_create_card_row(idx)
  if self._card_rows[idx] then
    return self._card_rows[idx]
  end
  local go = GameObject.Instantiate(self._trans_card_row.gameObject, self._trans_rule_parent)
  local left_go = go.transform:Find("item_card_left")
  local right_go = go.transform:Find("item_card_right")
  local row = {
    go = go,
    left = {
      go = left_go,
      fields = UIUtil.get_mono_binder_field(left_go)
    },
    right = {
      go = right_go,
      fields = UIUtil.get_mono_binder_field(right_go)
    }
  }
  self._card_rows[idx] = row
  return row
end

function M:_fill_card(card, rule_cfg)
  UIUtil.set_active(card.go, rule_cfg ~= nil)
  if rule_cfg and card.fields then
    UIUtil.set_text_by_id(card.fields._txt_name, rule_cfg.title)
    UIUtil.set_text_by_id(card.fields._txt_desc, rule_cfg.text)
    if string.is_valid(rule_cfg.icon) then
      UIUtil.set_image(card.fields._img_card, rule_cfg.icon, self:get_load_proxy())
    end
  end
end

return M
