--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Initialization
function onInit()
	if User.isHost() then
		Comm.registerSlashHandler("ccweight", computeCoinsWeight);
		-- computeCoinsWeight();
	end
end

-- This function recompute the total weight field
function recomputeTotalWeight( nodeWin )
	local rActor = ActorManager.getActor("pc", nodeWin );
	local nodePC = DB.findNode(rActor['sCreatureNode']);

	local treasure = DB.getValue( nodePC.getPath() .. '.encumbrance.treasure' );
	local eqload = DB.getValue( nodePC.getPath() .. '.encumbrance.load' );

	DB.setValue( nodePC.getPath() .. '.encumbrance.total', 'number', treasure+eqload );
end

-- This function is manualy called with the command /ccweight (DM only)
function computeCoinsWeight(command, parameters)
	if User.isHost() then
		for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
			local sClass, sRecord = DB.getValue(v, "link");
			Debug.chat( sRecord );
			if sClass == "charsheet" and sRecord then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					computePCCoinsWeigh( nodePC );
				end
			end
		end
	end
end

-- This function is called when a coin field is called
function onCoinsValueChanged( nodeWin )
	local rActor = ActorManager.getActor("pc", nodeWin );
	local nodePC = DB.findNode(rActor['sCreatureNode']);
	CoinsWeight.computePCCoinsWeigh( nodePC );
end

-- This function really compute the weight of the coins
function computePCCoinsWeigh( nodePC )
	local weight = 0;
	for _,coin in pairs(DB.getChildren(nodePC, "coins")) do
		weight = weight + DB.getValue(coin, "amount", "")	;
	end

	-- We have now computed the coins weight for this PC
	-- CHANGE WEIGHT HERE, Change the 1 to the fractional weight you desire, for example 10 is 10 coins = 1 weight
	weight = math.floor( weight / 50 );
	DB.setValue( nodePC.getPath() .. '.encumbrance.treasure', 'number', weight );
end