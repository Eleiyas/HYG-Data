local M = G.Class("MessageBoardPicPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MessageBoard/MessageBoardPicPage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self._promo_photo = nil
  self._loading_file_key = ""
end

function M:on_enable()
  base.on_enable(self)
  UIUtil.set_text(self._text_note, CsPlayerVisitModuleUtil.DisplayHostNote or "")
  self:_refresh_photo()
end

function M:on_disable()
  base.on_disable(self)
  self:_release_photo()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_more, pack(self, M._on_report_click))
end

function M:_refresh_photo()
  self:_release_photo()
  local file_key = CsPlayerVisitModuleUtil.DisplayPromoImageFileKey or ""
  UIUtil.set_active(self._img_photo, false)
  if not string.is_valid(file_key) then
    return
  end
  self._loading_file_key = file_key
  CsPlayerVisitModuleUtil.MessageBoardPreparePromoPhotoByFileKey(file_key, function(success, photo)
    if is_null(self.game_obj) or self._loading_file_key ~= file_key then
      if photo ~= nil then
        CsPlayerVisitModuleUtil.ReleaseMsgBoardPromoPhoto(photo)
      end
      return
    end
    if not success or photo == nil or is_null(photo.photoSprite) then
      if photo ~= nil then
        CsPlayerVisitModuleUtil.ReleaseMsgBoardPromoPhoto(photo)
      end
      return
    end
    if self._promo_photo ~= nil then
      CsPlayerVisitModuleUtil.ReleaseMsgBoardPromoPhoto(self._promo_photo)
    end
    self._promo_photo = photo
    UIUtil.set_image(self._img_photo, photo.photoSprite, self:get_load_proxy())
    UIUtil.set_active(self._img_photo, true)
  end)
end

function M:_release_photo()
  self._loading_file_key = ""
  if self._promo_photo ~= nil then
    CsPlayerVisitModuleUtil.ReleaseMsgBoardPromoPhoto(self._promo_photo)
    self._promo_photo = nil
  end
end

function M:_on_report_click()
  local menus = {
    {
      desc = UIUtil.get_text_by_id("Menu_Tip_Off"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_report)
    }
  }
  UIManagerInstance:open("UI/Social/CommonMenuDialog", {
    show_position = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 1),
    state = 1,
    menus = menus
  })
end

function M:_on_menu_report()
  local file_key = CsPlayerVisitModuleUtil.DisplayPromoImageFileKey or ""
  if not string.is_valid(file_key) then
    return
  end
  local note = CsPlayerVisitModuleUtil.DisplayHostNote or ""
  local has_note = string.is_valid(note)
  report_module:open_report_page({
    target = report_module.report_target.station_promo,
    target_uid = player_module:get_scene_owner_uid(),
    content_version = CsPlayerVisitModuleUtil.PromoContentVersion,
    file_key = file_key,
    target_message = has_note and note or "",
    content_version_2 = has_note and CsPlayerVisitModuleUtil.HostNoteVersion or 0
  })
end

return M
