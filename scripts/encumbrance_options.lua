--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

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
		{ labels = 'enc_opt_fail_prompt|enc_opt_fail_off', values = 'prompt|off', baselabel = 'enc_opt_fail_on', baseval = 'auto', default = 'auto' })

	OptionsManager.registerOption2('CALCULATE_INVENTORY_VALUE', false, 'option_header_game', 'opt_lab_inv_value', 'option_entry_cycler', 
		{ labels = 'enc_opt_inv_value_off', values = 'off', baselabel = 'enc_opt_inv_value_on', baseval = 'on', default = 'on' })

	OptionsManager.registerOption2('ENCUMBRANCE_UNIT', false, 'option_header_game', 'opt_lab_enc_unit', 'option_entry_cycler', 
		{ labels = 'enc_opt_enc_unit_kg|enc_opt_enc_unit_kg-full', values = 'kg|kg-full', baselabel = 'enc_opt_enc_unit_lb', baseval = 'lb', default = 'lb' })

	OptionsManager.registerOption2('WARN_COST', false, 'option_header_game', 'opt_lab_warn_cost', 'option_entry_cycler', 
		{ labels = 'enc_opt_warn_cost_off', values = 'off', baselabel = 'enc_opt_warn_cost_on', baseval = 'on', default = 'on' })

--	OptionsManager.registerOption2('CARRY_CAPACITY_FROM_EFFECTS', false, 'option_header_game', 'opt_lab_carry_effects', 'option_entry_cycler', 
--		{ labels = 'enc_opt_carry_effects_off', values = 'off', baselabel = 'enc_opt_carry_effects_on', baseval = 'on', default = 'on' })

--	OptionsManager.registerOption2('SPEED_INCREMENT', false, 'option_header_game', 'opt_lab_speed_inc', 'option_entry_cycler', 
--		{ labels = 'enc_opt_speed_inc_1', values = '1', baselabel = 'enc_opt_speed_inc_5', baseval = '5', default = '5' })
end