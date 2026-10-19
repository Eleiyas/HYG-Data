PageEnableWatcher = PageEnableWatcher or {}
local W = PageEnableWatcher

local function now()
  return CS.UnityEngine.Time.realtimeSinceStartup
end

W._seq = W._seq or 0
W._name = W._name or ""
W._open_name = W._open_name or ""
W._open_seq = W._open_seq or 0
W._t_req = W._t_req or -1
W._t_enable = W._t_enable or -1
W._t_shown = W._t_shown or -1
W._reqs = W._reqs or {}
if W._listener then
  lua_event_module:remove_listener(lua_event_module.event_type.on_page_enable, W._listener)
end

function W._listener(page_name, hash_id)
  local nm = page_name or ""
  W._seq = W._seq + 1
  W._name = nm
  if string.find(nm, "MaskInfo", 1, true) == nil then
    W._t_enable = now()
    W._t_req = W._reqs[nm] or -1
    W._reqs[nm] = nil
    W._t_shown = -1
    W._open_name = nm
    W._open_seq = W._seq
  end
end

lua_event_module:add_listener(lua_event_module.event_type.on_page_enable, W._listener)

function W.ensure_hooks()
  if not W._hooked_open and G and G.UIManager and G.UIManager.open then
    W._hooked_open = true
    local raw_open = G.UIManager.open
    
    function G.UIManager:open(class_name, ...)
      pcall(function()
        if class_name and string.find(tostring(class_name), "MaskInfo", 1, true) == nil then
          W._reqs[tostring(class_name)] = now()
        end
      end)
      return raw_open(self, class_name, ...)
    end
  end
  if not W._hooked_anim and G and G.UIPanel and G.UIPanel.enter_anim_call_back then
    W._hooked_anim = true
    local raw_anim = G.UIPanel.enter_anim_call_back
    
    function G.UIPanel:enter_anim_call_back(...)
      local r = raw_anim(self, ...)
      pcall(function()
        if self and self.full_class_name == W._open_name and W._t_shown < 0 then
          W._t_shown = now()
        end
      end)
      return r
    end
  end
end

W.ensure_hooks()

function gm_get_last_page_enable()
  return string.format("%s|%d", W._name, W._seq)
end

function gm_now()
  return now()
end

function gm_get_last_page_open()
  W.ensure_hooks()
  return string.format("%s|%d|%.4f|%.4f|%.4f|%.4f", W._open_name, W._open_seq, W._t_req, W._t_enable, W._t_shown, now())
end

return PageEnableWatcher
