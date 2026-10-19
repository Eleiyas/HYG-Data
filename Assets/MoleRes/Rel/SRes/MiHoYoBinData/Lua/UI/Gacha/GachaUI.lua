gacha_module = gacha_module or {}

function gacha_module:open_main_page(gacha_id)
  self:set_cur_gacha_id(gacha_id)
  UIManagerInstance:open(GachaConst.page_path.main, {is_request_all_data = true})
end

function gacha_module:open_exchange_page(exchange_index)
  self:set_cur_exchange_index(exchange_index)
  UIManagerInstance:open(GachaConst.page_path.exchange)
end

function gacha_module:open_cloth_pool_show_page(cloth_pool_index)
  self:set_cur_cloth_pool_index(cloth_pool_index)
  UIManagerInstance:open(GachaConst.page_path.cloth_pool_show)
end

function gacha_module:open_process_t1_page(is_cloth)
  local page_path = is_cloth and GachaConst.page_path.process_cloth_t1 or GachaConst.page_path.process_furniture_t1
  UIManagerInstance:open(page_path)
end

function gacha_module:open_rule_history_dialog(tab_index)
  UIManagerInstance:open(GachaConst.page_path.description, {
    tab = tab_index or GachaConst.rule_tab.inventory
  })
end

function gacha_module:open_performance_controller_page(extra_data)
  UIManagerInstance:open(GachaConst.page_path.performance_controller, extra_data)
end

function gacha_module:open_draw_show_t1()
  UIManagerInstance:open(GachaConst.page_path.draw_show_t1)
end

function gacha_module:open_accum_reward_dialog(gacha_id)
  self:set_cur_gacha_id(gacha_id)
  UIManagerInstance:open(GachaConst.page_path.accum_reward, {gacha_id = gacha_id})
end

function gacha_module:open_all_collect_banner(gacha_id)
  UIManagerInstance:open(GachaConst.page_path.all_collect_banner, {gacha_id = gacha_id})
end

function gacha_module:show_draw_transition_cover()
  UIManagerInstance:open(GachaConst.page_path.draw_transition_cover)
end

function gacha_module:show_draw_transition_cover_background()
  local cover = UIManagerInstance:get_window_by_class(GachaConst.page_path.draw_transition_cover)
  if cover ~= nil then
    if cover.is_active then
      cover:show_background()
    else
      cover:set_show_background_flag(true)
    end
  end
end

function gacha_module:hide_draw_transition_cover()
  local cover = UIManagerInstance:is_show(GachaConst.page_path.draw_transition_cover)
  if cover ~= nil then
    cover:close_self()
  end
end

return gacha_module
