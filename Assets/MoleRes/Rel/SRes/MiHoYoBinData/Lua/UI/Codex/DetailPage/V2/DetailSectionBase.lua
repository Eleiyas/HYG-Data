local M = G.Class("DetailSectionBase", G.UIPanel)

function M:should_show(item_data)
  return true
end

function M:refresh(item_data)
end

return M
