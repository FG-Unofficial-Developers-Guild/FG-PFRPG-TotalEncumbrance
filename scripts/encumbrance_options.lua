--[[
    Please see the license.html file included with this distribution for attribution and copyright information.
--]]
function onInit()
	registerOptions()
end

function registerOptions()
	OptionsManager.registerOption2('WEIGHT_ENCUMBRANCE', false, 'option_header_game', 'opt_lab_weight_enc', 'option_entry_cycler', 
		{ labels = 'enc_opt_pen_off', values = 'off', baselabel = 'enc_opt_pen_on', baseval = 'on', default = 'on' })

	OptionsManager.registerOption2('COIN_WEIGHT', false, 'option_header_game', 'opt_lab_coin_weight', 'option_entry_cycler', 
		{ labels = 'enc_opt_coin_off', values = 'off', baselabel = 'enc_opt_coin_on', baseval = 'on', default = 'on' })

	OptionsManager.registerOption2('ENCUMBRANCE_COLORS', false, 'option_header_game', 'opt_lab_enc_color', 'option_entry_cycler', 
		{ labels = 'enc_opt_color_off', values = 'off', baselabel = 'enc_opt_color_on', baseval = 'on', default = 'on' })

	OptionsManager.registerOption2('AUTO_SPELL_FAILURE', false, 'option_header_game', 'opt_lab_spell_fail', 'option_entry_cycler', 
		{ labels = 'enc_opt_fail_off|enc_opt_fail_prompt', values = 'off|prompt', baselabel = 'enc_opt_fail_on', baseval = 'auto', default = 'auto' })

	OptionsManager.registerOption2('CARRY_CAPACITY_FROME_FFECTS', false, 'option_header_game', 'opt_lab_carry_effects', 'option_entry_cycler', 
		{ labels = 'enc_opt_carry_effects_off', values = 'off', baselabel = 'enc_opt_carry_effects_on', baseval = 'on', default = 'on' })
end