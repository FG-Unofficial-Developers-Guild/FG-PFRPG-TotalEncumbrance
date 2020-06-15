--[[
    Please see the license.html file included with this distribution for attribution and copyright information.
--]]
function onInit()
	registerOptions()
end

function registerOptions()
	OptionsManager.registerOption2('WEIGHT_ENCUMBRANCE', false, 'option_header_game', 'opt_lab_weight_enc', 'option_entry_cycler', 
		{ labels = 'enc_opt_pen_on|enc_opt_pen_off', values = 'on|off', baselabel = 'enc_opt_pen_on', baseval = 'on', default = 'on' })

	OptionsManager.registerOption2('COIN_WEIGHT', false, 'option_header_game', 'opt_lab_coin_weight', 'option_entry_cycler', 
		{ labels = 'enc_opt_coin_on|enc_opt_coin_off', values = 'on|off', baselabel = 'enc_opt_coin_on', baseval = 'on', default = 'on' })

	OptionsManager.registerOption2('ENCUMBRANCE_COLORS', false, 'option_header_game', 'opt_lab_enc_color', 'option_entry_cycler', 
		{ labels = 'enc_opt_color_on|enc_opt_color_off', values = 'on|off', baselabel = 'enc_opt_color_off', baseval = 'off', default = 'off' })
end