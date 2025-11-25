ecology_donation_module = ecology_donation_module or {}
ecology_donation_module.all_organism_in_packet = {}
ecology_donation_module.all_organism = {}

function ecology_donation_module:get_all_organism()
  local all_organism_dic = LocalDataUtil.get_dic_table(typeof(CS.BDonationCfg))
  ecology_donation_module.all_organism = dic_to_table(all_organism_dic)
end

function ecology_donation_module:get_all_organism_in_packet()
  local all_organism_in_packet_list = back_bag_module:get_packet_data():GetItemIdsByOrganism()
  ecology_donation_module.all_organism_in_packet = list_to_table(all_organism_in_packet_list)
end

return ecology_donation_module
