lua_module_mgr = lua_module_mgr or {}

function lua_module_mgr:load_module()
  self._tbl_module = {
    lua_module_mgr:require("CfgCallLuaFunction/CfgCallLuaFunc"),
    lua_module_mgr:require("UI/Item/ItemInit"),
    lua_module_mgr:require("UI/HandBook/HandBookInit"),
    lua_module_mgr:require("LuaEvent/LuaEventInit"),
    lua_module_mgr:require("BackBag/BackBagInit"),
    lua_module_mgr:require("UI/Warehouse/WarehouseInit"),
    lua_module_mgr:require("UI/Npc/NpcInit"),
    lua_module_mgr:require("UI/Player/PlayerInit"),
    lua_module_mgr:require("Level/LevelInit"),
    lua_module_mgr:require("UI/Quest/TaskInit"),
    lua_module_mgr:require("UI/CommonUI/CommonUI"),
    lua_module_mgr:require("UI/CommonUI/OpenLuaUI"),
    lua_module_mgr:require("UI/OverheadHint/OverheadHintInit"),
    lua_module_mgr:require("UI/Mail/MailInit"),
    lua_module_mgr:require("OnLine/OnLineInit"),
    lua_module_mgr:require("Social/SocialInit"),
    lua_module_mgr:require("Chat/ChatInit"),
    lua_module_mgr:require("UI/Shop/ShopInit"),
    lua_module_mgr:require("UI/Recipe/RecipeInit"),
    lua_module_mgr:require("Phone/PhoneInit"),
    lua_module_mgr:require("UI/LeMiAchieve/LeMiAchieveInit"),
    lua_module_mgr:require("RedPoint/RedPointInit"),
    lua_module_mgr:require("InGameLetter/InGameLetterInit"),
    lua_module_mgr:require("ScoreSystem/ScoreSystemInit"),
    lua_module_mgr:require("UI/Tutorial/Module/TutorialInit"),
    lua_module_mgr:require("UI/TVShopping/TVShopInit"),
    lua_module_mgr:require("Level/Levelmusicalchairs"),
    lua_module_mgr:require("UI/CompanionStar/CompanionStarInit"),
    lua_module_mgr:require("UI/Cooking/CookingInit"),
    lua_module_mgr:require("UI/MiTaiScore/Module/MiTaiScoreInit"),
    lua_module_mgr:require("UI/LucaHeart/LucaHeartInit"),
    lua_module_mgr:require("UI/NpcHouseOrder/Module/NpcHouseOrderInit"),
    lua_module_mgr:require("UI/Collection/CollectionInit"),
    lua_module_mgr:require("UI/DineTogether/DineTogetherInit"),
    lua_module_mgr:require("UI/EcologyDonation/EcologyDonationInit"),
    lua_module_mgr:require("UI/NpcFavour/Module/NpcFavourInit"),
    lua_module_mgr:require("UI/WorldEditor/WorldEditorInit"),
    lua_module_mgr:require("UI/Memo/MemoInit"),
    lua_module_mgr:require("Tracking/TrackingInit"),
    lua_module_mgr:require("UI/PlayerVisit/PlayerVisitInit"),
    lua_module_mgr:require("UI/StarFriend/StarFriendInit"),
    lua_module_mgr:require("UI/Friend/StarFriendSocialInit"),
    lua_module_mgr:require("UI/InstrumentPlay/InstrumentPlayInit"),
    lua_module_mgr:require("UI/Codex/Module/CodexInit"),
    lua_module_mgr:require("UI/HUDInfo/HUDInfoInit"),
    lua_module_mgr:require("UI/Appearance/AppearanceInit"),
    lua_module_mgr:require("UI/GalacticBazaar/GalacticBazaarInit"),
    lua_module_mgr:require("UI/FortuneWheel/FortuneWheelInit"),
    lua_module_mgr:require("UI/PlanetTree/Module/PlanetTreeInit"),
    lua_module_mgr:require("UI/Report/Module/ReportInit")
  }
  for i, _ in ipairs(self._tbl_module) do
    self._tbl_module[i]:init()
  end
end

function lua_module_mgr:reload_module()
  lua_module_mgr:_clear_module()
  if self._tbl_module == nil then
    lua_module_mgr:load_module()
    return
  end
end

function lua_module_mgr:on_level_destroy()
  if self._tbl_module then
    for i = #self._tbl_module, 1, -1 do
      if self._tbl_module[i] and self._tbl_module[i].on_level_destroy then
        self._tbl_module[i]:on_level_destroy()
      end
    end
  end
end

function lua_module_mgr:clear_on_disconnect()
end

function lua_module_mgr:init_on_connect(isReLogin)
  if self._tbl_module then
    for i = #self._tbl_module, 1, -1 do
      if self._tbl_module[i] and self._tbl_module[i].init_on_connect then
        self._tbl_module[i]:init_on_connect(isReLogin)
      end
    end
  end
end

function lua_module_mgr:_clear_module()
  if self._tbl_module then
    for i = #self._tbl_module, 1, -1 do
      if self._tbl_module[i] then
        CS.UnityEngine.Debug.Log(self._tbl_module[i]._cname .. "   clear")
        self._tbl_module[i]:close()
        un_require(lua_module_mgr:get_module_path_by_cname(self._tbl_module[i]._cname), self._tbl_module[i]._cname)
        self._tbl_module[i] = nil
      end
    end
    self._tbl_module_path = nil
    self._tbl_module = nil
  end
end

function lua_module_mgr:require(cpath)
  local mode = require(cpath)
  if self._tbl_module_path == nil then
    self._tbl_module_path = {}
  end
  if self._tbl_module_path[mode._cname] == nil then
    self._tbl_module_path[mode._cname] = {}
  end
  table.insert(self._tbl_module_path[mode._cname], cpath)
  return mode
end

function lua_module_mgr:get_module_path_by_cname(cname)
  if self._tbl_module_path and self._tbl_module_path[cname] then
    return self._tbl_module_path[cname]
  end
  return {}
end

function lua_module_mgr:close_module()
  lua_module_mgr:_clear_module()
  un_require("LuaModule/LuaModuleMgr")
end

return lua_module_mgr
