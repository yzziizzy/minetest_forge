# minetest_forge

Huge electric arc furnaces for minetest, with non-renewable finite-liquids-like molten ores and metals.


![ ](http://i.imgur.com/aP6cAvJ.jpg)


Crafts
======

First make refractory clay:
![ ](http://i.imgur.com/EaeVof3.jpg)

Refractory clay can also be made from slag:
![ ](http://i.imgur.com/jmiuzXB.jpg)

Then craft refractory brick blocks
![ ](http://i.imgur.com/r34faDx.jpg)
![ ](http://i.imgur.com/k4YTehm.jpg)


Build a crucible where the bottom can be accessed. I used mesecon sticky pistons for gates.
Place the electrode in the top, give it a lot of juice, and punch to turn it on. But before that fill the crucible with ore.

Electrode:
![ ](http://i.imgur.com/34udvpD.jpg)

The electrode uses all surplus power, much like a battery box. The more power you give it the faster it melts ores.

Molten ore will flow out of holes created in the bottom of the crucible and eventually cool. Be careful, molten ore will destroy most materials. Use the refractory bricks.

Molten ore cools more slowly on refractory materials. It cools very quickly when exposed to water. 

Ores
======
Input materials and what you might get out of them. Yields vary; some things result in mostly slag.

* desert cobble: copper, steel
* stone cobble: steel, copper
* gravel: steel, gold
* dirt: steel, gold
* desert sand: glass
* sand: glass
* sandstone: glass

Metal blocks can be remelted without loss. Reprocessing slag over and over may yield small returns.

Molten metals of different densities will float or sink relative to each other eventually.



forge_steam.png texture is LGPL (from mintest_game/tnt)
Everything else WTFPL / Unlicense