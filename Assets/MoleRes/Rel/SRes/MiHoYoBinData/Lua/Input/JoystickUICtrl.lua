local M = G.Class("JoystickUICtrl")

function M:__ctor()
  self._list = nil
  self._row_count = 0
  self._count = 0
  self._initialized = false
end

function M:init_list(list, row_count)
  if list == nil then
    self._initialized = false
    return
  end
  self._list = list
  self._count = #list
  if row_count ~= nil then
    self._row_count = row_count
  else
    self._row_count = 0
  end
  self._initialized = true
end

function M:_check(index)
  if not self._initialized then
    return false
  end
  if index < 1 or index > self._count then
    Logger.Log("不合法的Index")
    return false
  end
  return true
end

function M:up(index)
  if not self:_check(index) then
    return nil
  end
  if self._row_count == 0 then
    return nil
  end
  if index - self._row_count >= 1 then
    return self._list[index - self._row_count]
  else
    return nil
  end
end

function M:down(index)
  if not self:_check(index) then
    return nil
  end
  if self._row_count == 0 then
    return nil
  end
  if index + self._row_count <= self._count then
    return self._list[index + self._row_count]
  else
    return nil
  end
end

function M:left(index)
  if not self:_check(index) then
    return nil
  end
  if 1 <= index - 1 then
    return self._list[index - 1]
  else
    return nil
  end
end

function M:right(index)
  if not self:_check(index) then
    return nil
  end
  if index + 1 <= self._count then
    return self._list[index + 1]
  else
    return nil
  end
end

function M:get_index(item)
  if not self._initialized then
    return 0
  end
  for i = 1, self._count do
    if self._list[i] == item then
      return i
    end
  end
  return 0
end

function M:get_first()
  if self._initialized and self._count >= 1 then
    return self._list[1]
  end
  return nil
end

return M
