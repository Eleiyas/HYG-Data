ecology_donation_module = ecology_donation_module or {}
ecology_donation_module._cname = "ecology_donation_module"
lua_module_mgr:require("UI/EcologyDonation/EcologyDonationMain")
lua_module_mgr:require("UI/EcologyDonation/EcologyDonationData")

function ecology_donation_module:init()
end

function ecology_donation_module:close()
end

function ecology_donation_module:clear_on_disconnect()
end

return ecology_donation_module
