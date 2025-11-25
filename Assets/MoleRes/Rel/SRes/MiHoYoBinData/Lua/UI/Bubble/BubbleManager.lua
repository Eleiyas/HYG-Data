local M = G.Class("BubbleManager")

function M:__ctor()
  self._bubble_elements = {}
  local weak_k = {__mode = "k"}
  setmetatable(self._bubble_elements, weak_k)
  self._showhide = true
end

function M:show_bubble(args)
  local data = {
    trans = args.trans,
    onFinish = function()
      args.onFinish()
      self._bubble_elements[args.trans] = nil
    end,
    onReact = args.onReact,
    text1 = args.text1,
    text2 = args.text2,
    duration = args.duration,
    getPosFunc = args.getPosFunc,
    bubble_type = args.bubbleType
  }
  local bubble_page
  if self._bubble_elements[args.trans] then
    self._bubble_elements[args.trans].page:set_extra_data(data)
    self._bubble_elements[args.trans].page:refresh()
    bubble_page = self._bubble_elements[args.trans].page
  else
    local guid, page = UIManagerInstance:open("UI/Bubble/BubblePage", data)
    self._bubble_elements[args.trans] = {
      guid = guid,
      page = page,
      on_finish = args.onFinish
    }
    bubble_page = page
  end
  bubble_page:set_alpha(self._showhide)
end

function M:close_bubble(guid)
end

function M:set_bubbles_showhide(showhide)
  self._showhide = showhide
  for _, element in pairs(self._bubble_elements) do
    element.page:set_alpha(self._showhide)
  end
end

function M:destroy()
  for _, element in pairs(self._bubble_elements) do
    element.on_finish()
  end
  self._bubble_elements = {}
end

return M
