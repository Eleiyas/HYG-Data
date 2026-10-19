local M = G.Class("CoolDownManager")

function M:__ctor()
  self._cd_elements = {}
  local weak_k = {__mode = "k"}
  setmetatable(self._cd_elements, weak_k)
  self._delay_remove_elements = {}
end

function M:update(deltaTime)
  table.clear(self._delay_remove_elements)
  for holder, element in pairs(self._cd_elements) do
    element.time = element.time - deltaTime
    if element.time <= 0 then
      if element.action then
        element.action()
      end
      table.insert(self._delay_remove_elements, holder)
    end
  end
  for _, holder in ipairs(self._delay_remove_elements) do
    self._cd_elements[holder] = nil
  end
end

function M:register(holder, time, action)
  if self._cd_elements[holder] ~= nil then
    Logger.LogError("This holder is already been registered !! " .. tostring(holder))
    return
  end
  self._cd_elements[holder] = {time = time, action = action}
end

function M:unregister(holder)
  self._cd_elements[holder] = nil
end

function M:get_cd(holder)
  return self._cd_elements[holder] and self._cd_elements[holder].time
end

function M:destroy()
  for i = #self._cd_elements, 1, -1 do
    self._cd_elements[i] = nil
  end
end

return M
