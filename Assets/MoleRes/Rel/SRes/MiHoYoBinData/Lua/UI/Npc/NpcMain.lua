npc_module = npc_module or {}

function npc_module:add_event()
  npc_module:remove_event()
  self._events = {
    [EventID.LuaShowKnockBubble] = function(guid)
      local window = UIManagerInstance:get_window_by_class("UI/OverheadHint/KnockBubbleHintScene")
      if window then
        window:add_knock_hint(guid)
      else
        if self._knock_bubble_guids == nil then
          self._knock_bubble_guids = {}
        end
        if table.contains(self._knock_bubble_guids, guid) == false then
          table.insert(self._knock_bubble_guids, guid)
        end
      end
    end,
    [EventID.LuaRemoveKnockBubble] = function(guid)
      local window = UIManagerInstance:get_window_by_class("UI/OverheadHint/KnockBubbleHintScene")
      if window then
        window:remove_knock_hint(guid)
      else
        if self._knock_bubble_guids == nil then
          self._knock_bubble_guids = {}
          return
        end
        for i = #self._knock_bubble_guids, 1, -1 do
          if self._knock_bubble_guids[i] == guid then
            table.remove(self._knock_bubble_guids, i)
          end
        end
      end
    end
  }
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function npc_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function npc_module:get_all_npc_entity()
  return list_to_table(CsEntityManagerUtil.avatarManager:GetNPCEntities())
end

function npc_module:is_npc(entity)
  if entity and entity.IsValid then
    return EntityUtil.is_npc(entity.Guid)
  end
  return false
end

function npc_module:is_npc_following()
  local npc_id = CsNPCManagerUtil.GetInvitedNpcId()
  return npc_id ~= 0
end

function npc_module:get_following_npc_id()
  return CsNPCManagerUtil.GetInvitedNpcId()
end

return npc_module
