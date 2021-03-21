!!# NOW DEPRECATED!!

# PFRPG Total Encumbrance
This extension enhances functionality related to carrying capacity, coin weight, inventory value, and weight/armor encumbrance.
The spell failure compenent previously included here is now available as [its own extension](https://github.com/bmos/FG-PFRPG-Spell-Failure).

# Features
* Calculate coin weight with a default of 1lb/50coins.
* Automate encumbrance penalties based on total weight and current carrying capacity. The penalties are now colored to indicate their source. Red is for encumbrance based on weight and black is for armor.
* Update carrying capacities when strength-modifying effects are applied/changed/removed. Currently supported: 'STR: N'(increases strength score and carrying capacity ONLY IN 3.5E), 'CARRY: N'(increases strength score only for calculating carrying capacity), and 'Ant Haul'(triples carrying capacity).
* Include the [Armor Expert trait](https://www.d20pfsrd.com/traits/combat-traits/armor-expert/), [Muscle of the Society trait](https://www.d20pfsrd.com/traits/combat-traits/muscle-of-the-society/), and [Armor Training fighter class feature](https://www.d20pfsrd.com/classes/Core-Classes/Fighter/#Armor_Training_Ex) in carry capacity and armor calculations.
* Auto-change speed based on weight encumbrance and some supported Pathfinder conditions.
* Compute and display total net worth (value of all items + coins) at the top of the treasure box on the Inventory tab.
* Provide support for extraplanar containers by ignoring the weight of carried (but not equipped) items in supported contaners ('of holding', 'portable hole', 'handy haversack', 'efficient quiver'.

# Compatibility and Instructions
This extension has been tested with [FantasyGrounds Classic](https://www.fantasygrounds.com/home/FantasyGroundsClassic.php) 3.3.12 and [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.0.3 (2020-11-25).

In-game controls for enabling/disabling/configuring some extension components are in FantasyGrounds' "Options" menu.
Any values designed to be user-modifiable are located in [scripts/encumbrance_globals.lua](https://github.com/bmos/FG-PFRPG-TotalEncumbrance/blob/master/scripts/encumbrance_globals.lua) and include:
* Weight per coin of each denomination.
* Supported extraplanar containers.
* The encumbrance penalties imposed by medium or heavy encumbrance.

# Video Demonstration (click for video)
[<img src="https://i.ytimg.com/vi_webp/u4PDWxNbzTo/hqdefault.webp">](https://www.youtube.com/watch?v=u4PDWxNbzTo)
