# TotalEncumbrance
I was excited to come across [Alaxandir's CoreRPG port](https://www.fantasygrounds.com/forums/showthread.php?57185-Coin-Weight-for-CoreRPG-(MoreCore-compatible)) of [Zuger's Coin Weight extension](https://svn.fantasygrounds.com/forums/showthread.php?41109-The-weight-of-the-coins), but it had visual issues in the Pathfinder ruleset. I made a few changes and enabled some extra features that had been left disabled/unfinished in the source mod. After seeing how it worked, it seemed like an obvious next step to extend its functionality to help fill the gaps in the existing functionality around weight, encumbrance, coins, and the like. At this point, the coin weight aspect is a tiny piece of this extension.

The spell failure compenent previously included here is now available as [its own extension](https://github.com/bmos/FG-PFRPG-Spell-Failure).

# Features
* Calculate coin weight. Two columns, one weighed and one not. 50 coins is 1 pound. (If using kg, leave this as coins per pound; the conversion will be done automatically)
* Automate encumbrance penalties based on total weight and current carrying capacity. The penalties are now colored to indicate their source. Red is for encumbrance based on weight and black is for armor.
* Update carrying capacities when strength-modifying effects are applied/changed/removed. Currently supported: 'STR: N'(increases strength score and carrying capacity ONLY IN 3.5E), 'CARRY: N'(increases strength score only for calculating carrying capacity), and 'Ant Haul'(triples carrying capacity).
* Include the [Armor Expert trait](https://www.d20pfsrd.com/traits/combat-traits/armor-expert/), [Muscle of the Society trait](https://www.d20pfsrd.com/traits/combat-traits/muscle-of-the-society/), and [Armor Training fighter class feature](https://www.d20pfsrd.com/classes/Core-Classes/Fighter/#Armor_Training_Ex) in carry capacity and armor calculations.
* Auto-change speed based on weight encumbrance and some supported Pathfinder conditions.
* Compute and display total net worth (all items + coins) at the top of the treasure box on the Inventory tab.
* Provide rudimentary support for extraplanar storage by ignoring the weight of carried items that aren't equipped and have the terms "holding", "portable hole", or "efficient quiver" in the location field. "Handy haversack" will be added in the next update as I forgot about that when adding this feature.

# Compatibility and Configuration
This extension has been tested with [FantasyGrounds Classic](https://www.fantasygrounds.com/home/FantasyGroundsClassic.php) 3.3.11 and [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) 4.0.0 (2020-09-03).

In-game controls for enabling/disabling/configuring some extension components are in FantasyGrounds' "Options" menu.
Any values designed to be user-modifiable are located in [scripts/encumbrance_globals.lua](https://github.com/bmos/FG-PFRPG-TotalEncumbrance/blob/master/scripts/encumbrance_globals.lua) and include:
* How many coins weigh one pound
* The encumbrance penalties imposed by medium or heavy encumbrance

# Video Demonstration (click for video)
[<img src="https://i.ytimg.com/vi_webp/y-jzwaN5i6s/hqdefault.webp">](https://youtu.be/y-jzwaN5i6s)
