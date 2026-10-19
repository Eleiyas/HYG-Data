coffee_rp_module = coffee_rp_module or {}
coffee_rp_module.NA_LUO_NPC_ID = 14
coffee_rp_module.NA_LUO_LETTER_CONFIG_ID = 28
coffee_rp_module.NA_LUO_LETTER_PAGE_PATH = "UI/InGameLetter/InGameLetterPaperPage"

function coffee_rp_module:_init_data()
  self._na_luo_letter_content = nil
  self._has_na_luo_letter = false
end

function coffee_rp_module:has_na_luo_letter()
  return self._has_na_luo_letter == true
end

function coffee_rp_module:get_na_luo_letter_content()
  return self._na_luo_letter_content or ""
end

function coffee_rp_module:clear_na_luo_letter()
  self._na_luo_letter_content = nil
  self._has_na_luo_letter = false
end

return coffee_rp_module
