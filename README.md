# TotalEncumbrance
I was excited to come across Alaxandir's CoreRPG port of Zuger's Coin Weight extension, but it had visual issues in the Pathfinder ruleset. I made a few changes and enabled some extra features that had been left disabled/unfinished in the source mod. After seeing how it worked, it seemed like an obvious next step to extend its functionality to help fill the gaps in the existing functionality around weight, encumbrance, coins, and the like.

# Features
* Calculate coin weight. Two columns, one weighed and one not. 50 coins is 1 weight unit.
* Automate encumbrance penalties based on total weight and current carrying capacity.
* Color-code the numbers in the penalties boxes to indicate their source. Red is for encumbrance and black is for armor.
* Options to enable/disable each extension component.
* Automatically roll arcane spell failure chance when appropriate. Alternately, prompt user to roll via a chat message including the spell failure chance.
* Carrying capacities update live when strength-modifying effects are applied/changed/removed.
* Armor can now have a max dex of zero, although it's a workaround. See the encumbrance_globals.lua section below.
* Speed penalties auto-change based on weight encumbrance and effects.
* Total inventory value is now shown at the top of the treasure box on the Inventory tab.


# Compatibility and Configuration
This extension has been tested with FantasyGrounds Classic 3.3.10 and FantasyGrounds Unity 4.0.0 (2020-07-07). It has limited compatibility in Unity (weight encumbrance penalties don't work fully and should be disabled under options).

Compatibility with [Kelrugem's Advanced Effects extension](https://www.fantasygrounds.com/forums/showthread.php?48977-Advanced-3-5e-and-Pathfinder-effects) (and any mod that contains it) is currently limited until it gets a compatibility update (coming soon).

Any values designed to be user-modifiable are located in [scripts/encumbrance_globals.lua](https://github.com/bmos/FG-PFRPG-TotalEncumbrance/blob/master/scripts/encumbrance_globals.lua) and include:
* Coins per weight unit
* Classes which have arcane failure in different categories of armor
* Encumbrance penalties for medium or heavy encumbrance
* A list of armor that is supposed to have a maximum dex penalty of zero (as FG didn't support this and I wanted half-plate to work right without manual corrections)

# Video Demonstration
[![v1.6.0 demo](https://i.imgur.com/DZnOvIF.jpg)](https://www.youtube.com/watch?v=Tj2rDt4oeL8 "Total Encumbrance - v1.6.0 - Click to Watch!")
