--[[
    Please see the license.html file included with this distribution for attribution and copyright information.
--]]
local oXPType = ""


function onInit()
	OptionsManager.registerOption2("WEIGHT_ENCUMBRANCE", false, "option_header_game", "option_label_weight_encumbrance", "option_entry_cycler", 
		{ labels = "encumbrance_options_penalties_on|encumbrance_options_penalties_off", 
		  values = "1|0", 
		  baselabel = "encumbrance_options_penalties_on", 
		  baseval = "on", 
		  default = "1" }
	);

	OptionsManager.registerOption2("COIN_WEIGHT", false, "option_header_game", "option_label_coin_weight", "option_entry_cycler", 
		{ labels = "encumbrance_options_coinweight_on|encumbrance_options_coinweight_off", 
		  values = "1|0", 
		  baselabel = "encumbrance_options_coinweight_on", 
		  baseval = "on", 
		  default = "1" }
	);	
	
	OptionsManager.registerOption2("ENCUMBRANCE_COLORS", false, "option_header_game", "option_label_encumbrance_colors", "option_entry_cycler", 
		{ labels = "encumbrance_options_color_on|encumbrance_options_color_off", 
		  values = "1|0", 
		  baselabel = "encumbrance_options_color_off", 
		  baseval = "off", 
		  default = "0" }
	);	
end
