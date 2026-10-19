local M = G.Class("HairDyeingFlowerFilterDialog", G.UIWindow)
local base = G.UIWindow
local filter_item_cls = "UI/CommonUI/SearchFilter/CommonGroupedFilterToggleItem"
local FILTER_ALL_KEY = 0
local FILTER_ALL_LABEL_TEXT_ID = "Common_All"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/HairDyeing/HairDyeingSelectDialog"
  self.config.type = EUIType.Dialog
  self._filter_items = nil
  self._color_systems = nil
  self._draft_set = nil
  self._on_confirm = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_btn_close))
  end
  if not is_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M._on_btn_close))
  end
  if not is_null(self._btn_reset) then
    self:bind_callback(self._btn_reset, pack(self, M._on_btn_reset))
  end
  if not is_null(self._btn_confim) then
    self:bind_callback(self._btn_confim, pack(self, M._on_btn_confirm))
  end
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._on_confirm = data.on_confirm
  self._color_systems = hair_dyeing_module:get_flower_color_systems() or {}
  self._draft_set = {}
  for _, tag in ipairs(data.selected_tags or {}) do
    self._draft_set[tag] = true
  end
  self:_refresh_items()
end

function M:_build_entries()
  local is_all_on = next(self._draft_set) == nil
  local entries = {
    {
      key = FILTER_ALL_KEY,
      label_text_id = FILTER_ALL_LABEL_TEXT_ID,
      count = self:_calc_all_count(),
      use_color_state = false,
      is_on = is_all_on
    }
  }
  for _, sys in ipairs(self._color_systems) do
    table.insert(entries, {
      key = sys.tag,
      label = sys.label,
      count = sys.count,
      color = sys.color,
      use_color_state = true,
      is_on = self._draft_set[sys.tag] == true
    })
  end
  return entries
end

function M:_calc_all_count()
  local total = 0
  for _, sys in ipairs(self._color_systems) do
    total = total + (sys.count or 0)
  end
  return total
end

function M:_refresh_items()
  if is_null(self._trans_item_tog_filter) then
    return
  end
  local entries = self:_build_entries()
  self._filter_items = self._filter_items or {}
  local parent = self._trans_item_tog_filter.parent
  local max_num = math.max(#self._filter_items, #entries)
  for i = 1, max_num do
    local entry = entries[i]
    local item = self._filter_items[i]
    if item == nil and entry then
      local go = i == 1 and self._trans_item_tog_filter.gameObject or UIUtil.load_prefab_set_parent(self._trans_item_tog_filter.gameObject, parent)
      item = self:add_panel(filter_item_cls, go.transform)
      self._filter_items[i] = item
    end
    if item then
      if entry then
        item:refresh({
          key = entry.key,
          label = entry.label,
          label_text_id = entry.label_text_id,
          count = entry.count,
          color = entry.color,
          use_color_state = entry.use_color_state,
          is_on = entry.is_on,
          on_change = function(key, is_on)
            self:_on_item_toggle(key, is_on)
          end
        })
      else
        item:set_active(false)
      end
    end
  end
end

function M:_on_item_toggle(key, is_on)
  if key == FILTER_ALL_KEY then
    self._draft_set = {}
  elseif is_on then
    self._draft_set[key] = true
  else
    self._draft_set[key] = nil
  end
  self:_refresh_items()
end

function M:_on_btn_reset()
  self._draft_set = {}
  self:_refresh_items()
end

function M:_on_btn_confirm()
  if self._on_confirm then
    self._on_confirm(self:_draft_to_tags())
  end
  self:close_self()
end

function M:_draft_to_tags()
  local tags = {}
  for tag in pairs(self._draft_set) do
    table.insert(tags, tag)
  end
  return tags
end

function M:_on_btn_close()
  self:close_self()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

return M
