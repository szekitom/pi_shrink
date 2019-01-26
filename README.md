# pi_shrink
A Raspbery Pi SD kártyáiról készít csökkentett méretű lemezképet

A scriptet egy nagy kapacitású háttértár (Pl. a Pi-hez csatlakoztatott merevlemez) könyvtárába kell letölteni. Ebbe a könyvtárba jön létre az a lemezkép, amit egy kártyahiba, vagy egy félresikerült konfiguráció után visszatölthetsz az SD kártyára.

Ha egy visszatöltött rendszert indítasz, ne felejtsd el a raspi-config-ban megnövelni a partíció méretét! (7 Advanced Options » A1 Expand Filesystem)
..............................................................................................................................
Creates a reduced size image of Raspbery Pi's SD cards

The script must be downloaded to a directory of a high-capacity mass storage (eg a hard disk connected to Pi). This directory creates a disk image that can be loaded onto a SD card after a card error or a misconfigured configuration.

If you start a boot system, remember to increase the partition size in raspi-config! (7 Advanced Options »A1 Expand Filesystem)
