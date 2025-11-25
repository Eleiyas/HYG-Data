codex_module = codex_module or {}
codex_module.codex_page_type = {
  main_page = "UI/Codex/CodexMainPage",
  type_page = "UI/Codex/TypePage/CodexTypePage",
  detail_page = "UI/Codex/DetailPage/ItemDetailPage"
}
codex_module.codex_page_enter_type = {
  codex_sub_type_list = 1,
  item_detail_dialog = 2,
  codex_hud_tip = 3,
  codex_page_switch = 4
}

function codex_module:init_medal_comp(trans)
  if is_null(trans) then
    return
  end
  local cls = {
    trans = trans,
    icon = UIUtil.find_image(trans, "icon"),
    text = UIUtil.find_text(trans, "txt_rank_a"),
    trans_text = UIUtil.find_trans(trans, "txt_rank_a")
  }
  return cls
end

function codex_module:set_medal_comp(cls, level, is_highest, text, proxy)
  if not cls then
    return
  end
  local cfg = codex_module:get_task_rank_cfg_by_medal_level(level, is_highest)
  UIUtil.set_image(cls.icon, cfg.icon, proxy)
  if not_null(text) then
    UIUtil.set_text(cls.text, text)
  else
    UIUtil.set_active(cls.trans_text, false)
  end
end

return codex_module
