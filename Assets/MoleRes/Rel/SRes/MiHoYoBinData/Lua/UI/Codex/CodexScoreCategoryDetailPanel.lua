local M = G.Class("CodexScoreCategoryDetailPanel", G.UIPanel)
local base = G.UIPanel
local round_item_class = "UI/Codex/CodexScoreProgressRoundItem"
local score_item_class = "UI/Codex/CodexScoreCategoryScoreItem"
local CategoryDefs = {
  {
    codex_type = CodexDataType.Creature,
    title = "Codex_Creature",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Organism"
  },
  {
    codex_type = CodexDataType.Plant,
    title = "Codex_Plant",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Plant"
  },
  {
    codex_type = CodexDataType.Cloth,
    title = "Codex_Clothes",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Clothe"
  },
  {
    codex_type = CodexDataType.Food,
    title = "Codex_Food",
    icon = "UISprite/Load/TabIcon/Tab_Icon_Ugc_003_c"
  },
  {
    codex_type = CodexDataType.Furniture,
    title = "Codex_Furniture",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Furniture"
  }
}

function M:init()
  base.init(self)
  self._round_items = {}
  self._score_items = {}
  self._created = false
end

function M:on_create()
  base.on_create(self)
  UIUtil.set_active(self._trans_progress_item, false)
  UIUtil.set_active(self._trans_item, false)
end

function M:refresh(add_score_map)
  self:_ensure_items()
  add_score_map = add_score_map or {}
  for i = 1, #CategoryDefs do
    local def = CategoryDefs[i]
    local info = CsCodexModuleUtil.GetScoreCategoryInfo(def.codex_type)
    local current_score = info.currentScore or 0
    local full_score = info.fullScore or 0
    local add_score = add_score_map[def.codex_type] or 0
    local prev_score = math.max(current_score - add_score, 0)
    local current_norm = 0 < full_score and math.min(current_score / full_score, 1) or 0
    local prev_norm = 0 < full_score and math.min(prev_score / full_score, 1) or 0
    local round_item = self._round_items[i]
    if round_item ~= nil then
      round_item:refresh({
        title = def.title,
        icon = def.icon,
        prev_norm = prev_norm,
        current_norm = current_norm,
        add_score = add_score
      })
    end
    local score_item = self._score_items[i]
    if score_item ~= nil then
      score_item:refresh({
        icon = def.icon,
        title = def.title,
        num = current_score
      })
    end
  end
end

function M:_ensure_items()
  if self._created then
    return
  end
  self._created = true
  self:_create_item_list(self._trans_progress_item, round_item_class, self._round_items)
  self:_create_item_list(self._trans_item, score_item_class, self._score_items)
end

function M:_create_item_list(template, class_path, out_items)
  if is_null(template) then
    return
  end
  local parent = template.parent
  for i = 1, #CategoryDefs do
    local go = UIUtil.load_prefab_set_parent(template, parent)
    if not_null(go) then
      go.name = template.name .. "_" .. tostring(i)
      UIUtil.set_active(go, true)
      local item = self:add_panel(class_path, go)
      if item ~= nil then
        out_items[i] = item
      end
    end
  end
end

return M
