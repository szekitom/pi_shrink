# pi_shrink
A Raspbery Pi SD kártyáiról készít csökkentett méretű lemezképet

A scriptet egy nagy kapacitású háttértár (Pl. a Pi-hez csatlakoztatott merevlemez) könyvtárába kell letölteni. Ebbe a könyvtárba jön létre az a lemezkép, amit egy kártyahiba, vagy egy félresikerült konfiguráció után visszatölthetsz az SD kártyára.
Ha egy visszatöltött rendszert indítasz, ne felejtsd el a raspi-config-ban megnövelni a partíció méretét! (7 Advanced Options » A1 Expan Filesystem)
