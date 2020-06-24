# TotalEncumbrance
I was excited to come across Alaxandir's CoreRPG port of Zuger's Coin Weight extension, but it had visual issues in the Pathfinder ruleset. I made a few changes and enabled some extra features that had been left disabled/unfinished in the source mod. After seeing how it worked, it seemed like an obvious next step to extend its functionality to create an 'all-in-one' extension to try and get as close to 100% rule parity as possible. Currently, this mod has the following features:

* Calculate coin weight. Two columns, one weighed and one not. 50 coins is 1 weight unit.
* Automate encumbrance penalties based on total weight and current carrying capacity.
* Color-code the numbers in the penalties boxes to indicate their source. Red is for encumbrance and black is for armor.
* Options to enable/disable each extension component.
* Automatically roll arcane spell failure chance when appropriate. Alternately, prompt user to roll via a chat message including the spell failure chance.
* Carrying capacities update live when strength-modifying effects are applied/changed/removed.
* Armor can now have a max dex of zero, although it's a workaround. See the encumbrance_globals.lua section below.
* Speed penalties auto-change based on weight encumbrance.

Any values designed to be user-modifiable are located in scripts/encumbrance_globals.lua and include:
* Coins per weight unit
* Classes which have arcane failure in different categories of armor
* Encumbrance penalties for medium or heavy encumbrance
* A list of armor that is supposed to have a maximum dex penalty of zero (as FG didn't support this and I wanted half-plate to work right without manual corrections)

https://svn.fantasygrounds.com/forums/showthread.php?58641-Coin-Weight-for-Pathfinder
