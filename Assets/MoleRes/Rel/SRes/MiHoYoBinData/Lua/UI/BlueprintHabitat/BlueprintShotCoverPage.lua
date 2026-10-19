local M = G.Class("BlueprintShotCoverPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintCameraPage"
  self.config.type = EUIType.Page
  self._blueprint_name = ""
  self._cover_photo_guid = 0
  self._taking_photo = false
  self._btn_shot = nil
  self._btn_close_normal = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_shot) then
    self:bind_callback(self._btn_shot, pack(self, M._on_btn_shot))
  end
  if not_null(self._btn_close_normal) then
    self:bind_callback(self._btn_close_normal, pack(self, M._on_btn_close))
  end
end

function M:on_enable()
  base.on_enable(self)
  self._blueprint_name = self._extra_data and self._extra_data.name or ""
  self._cover_photo_guid = self._extra_data and self._extra_data.cover_guid or 0
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not_null(self._btn_shot) then
    self:bind_input_and_btn(ActionType.Act.F, self._btn_shot)
  end
end

function M:_on_btn_shot()
  if self._taking_photo then
    return
  end
  self._taking_photo = true
  InputManagerIns:lock_input_while(0.3)
  CsCameraManagerUtil.CreatePictureCenter(0, 0, function(guid)
    self._taking_photo = false
    if self._cover_photo_guid and self._cover_photo_guid > 0 and self._cover_photo_guid ~= guid then
      CsCameraManagerUtil.DiscardPhotoTexture(self._cover_photo_guid)
    end
    self:_back_to_save_dialog(guid)
  end)
end

function M:_on_btn_close()
  self:_back_to_save_dialog(self._cover_photo_guid)
end

function M:_back_to_save_dialog(cover_guid)
  self:close_self()
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintSaveDataDialog", {
    name = self._blueprint_name,
    cover_guid = cover_guid
  })
end

function M:handle_back(action)
  action.handled = true
  self:_on_btn_close()
end

return M
