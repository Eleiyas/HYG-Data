npc_module = npc_module or {}

function npc_module:set_npc_icon_by_path(img, icon_path, proxy)
  if not is_null(img) and string.is_valid(icon_path) then
    UIUtil.set_image(img, icon_path, proxy)
  end
end

function npc_module:set_npc_icon_by_id(img, npc_id, proxy, is_big)
  local npc_cfg = npc_module:get_npc_cfg(npc_id)
  if npc_cfg then
    if is_big then
      npc_module:set_npc_icon_by_path(img, npc_cfg.iconname, proxy)
    else
      npc_module:set_npc_icon_by_path(img, npc_cfg.iconnamesmall, proxy)
    end
  end
end

function npc_module:set_npc_icon_by_guid(img, npc_guid, proxy, is_big)
  local npc_entity = CsEntityManagerUtil.GetEntityByGuid(npc_guid)
  if is_null(npc_entity) then
    return
  end
  npc_module:set_npc_icon_by_id(img, npc_entity.configId, proxy, is_big)
end

function npc_module:set_npc_name_by_id(txt, npc_id)
  local npc_cfg = npc_module:get_npc_cfg(npc_id)
  if npc_cfg then
    UIUtil.set_text(txt, npc_cfg.name)
  end
end

function npc_module:set_npc_name_by_guid(txt, npc_guid)
  local npc_entity = CsEntityManagerUtil.GetEntityByGuid(npc_guid)
  if is_null(npc_entity) then
    return
  end
  npc_module:set_npc_name_by_id(txt, npc_entity.configId)
end

function npc_module:get_npc_name_by_id(npc_id)
  local npc_cfg = npc_module:get_npc_cfg(npc_id)
  if npc_cfg then
    return npc_cfg.name
  end
  return ""
end

function npc_module:open_npc_chat_page()
  UIManagerInstance:open("UI/Npc/NpcChatPage")
end

function npc_module:open_npc_contact_book_page()
  UIManagerInstance:open("UI/Npc/NpcContactBookPage")
end

return npc_module or {}
