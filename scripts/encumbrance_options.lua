--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	OptionsManager.registerOption2('ENCUMBRANCE_UNIT', false, 'option_header_game', 'opt_lab_enc_unit', 'option_entry_cycler', 
		{ labels = 'enc_opt_enc_unit_kg|enc_opt_enc_unit_kg-full', values = 'kg|kg-full', baselabel = 'enc_opt_enc_unit_lb', baseval = 'lb', default = 'lb' })

	OptionsManager.registerOption2('WARN_COST', false, 'option_header_game', 'opt_lab_warn_cost', 'option_entry_cycler', 
		{ labels = 'enc_opt_warn_cost_off|enc_opt_warn_cost_on', values = 'off|on', baselabel = 'enc_opt_warn_cost_subtle', baseval = 'subtle', default = 'subtle' })
end