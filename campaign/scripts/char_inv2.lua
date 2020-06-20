-- 
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	onEncumbranceChanged()
	DB.addHandler(DB.getPath(getDatabaseNode(), 'abilities.strength.score'), 'onUpdate', onStrengthChanged)
	DB.addHandler(DB.getPath(getDatabaseNode(), 'size'), 'onUpdate', onSizeChanged)
	DB.addHandler(DB.getPath(getDatabaseNode(), 'encumbrance.stradj'), 'onUpdate', onEncumbranceChanged)
	DB.addHandler(DB.getPath(getDatabaseNode(), 'encumbrance.carrymult'), 'onUpdate', onEncumbranceChanged)
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), 'abilities.strength.score'), 'onUpdate', onStrengthChanged)
	DB.removeHandler(DB.getPath(getDatabaseNode(), 'size'), 'onUpdate', onSizeChanged)
	DB.removeHandler(DB.getPath(getDatabaseNode(), 'encumbrance.stradj'), 'onUpdate', onEncumbranceChanged)
	DB.removeHandler(DB.getPath(getDatabaseNode(), 'encumbrance.carrymult'), 'onUpdate', onEncumbranceChanged)
end

function onStrengthChanged()
	onEncumbranceChanged()
end

function onSizeChanged()
	onEncumbranceChanged()
end

function onEncumbranceChanged()
	CarryWeightEffects.onEncumbranceChanged()
end