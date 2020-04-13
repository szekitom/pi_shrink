#!/bin/bash

# GPL v3 Licensz érvényes erre a szkriptre. Író: CPT.Pirk 
# Köszönet bambano, Jester01, vadoca és azbest kollégáknak a prohardver.hu fórumából.
#
# Nem vagyok se programozó, se informatikus, kérem ezek szerint kezelni a szkriptet.
# Azért született meg ez a szkript, mert nem találtam nekem megfelelő megoldást az image fájl
# méretének csökkentésére.
#
# A második verziót cigam követe el.

# Bármi baj történik, (0 vagy éppen nem)
trap cleanup 0 1 2 3 6

cleanup()
{
# kitakarít maga után
echo "   A munkakönyvtárak törlése."
umount $LOOPDEVICE'p1'>/dev/null 2>&1
umount $LOOPDEVICE'p2'>/dev/null 2>&1
losetup -d $LOOPDEVICE>/dev/null 2>&1
umount $SDCARD'p1'>/dev/null 2>&1
umount $SDCARD'p2'>/dev/null 2>&1
rm -rf $WORKDIR>/dev/null 2>&1
}

# A script neve  
PROGRAM="$(basename -- $0)"
# Root joggal fut?
if [ "$(id -u)" != "0" ]; then
  echo -e "A '$PROGRAM' futtatásához root jogokra van szükséged.\n"
  exit 1
fi
# Az SD kártya eszközneve
if [ -z "$1" ]; then
  clear
  echo "#############################################################"
  echo "#                                                           #"
  echo "#           Raspbery PI image shrink script 2.2             #"
  echo "#                                                           #"
  echo "#  Ha nem adod meg paraméterként az SD kártya eszköznevét,  #"
  echo "#  akkor alapértelmezés ként a /dev/mmcblk0 lesz használva  #"
  echo "#                                                           #"
  echo -e "#  például: \e[1msudo ./rpi_shrink.sh /dev/mmcblk0\e[0m               #"  
  echo "#                                                           #"
  echo "#############################################################"
  SDCARD="/dev/mmcblk0"
else
  SDCARD=$1
fi
# Ebben a könyvtárban fut a script
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# A munkakönyvtár neve
WORKDIR="$DIR/rpi_shrink"
# A mai dátum
DATE=`date +%Y-%m-%d`
# Az image fájl neve
IMAGEFILE="RaspberryPi_$DATE.img"
# Összefoglaló kiírása
echo ""
echo "   SD kártya: $SDCARD"
echo "   Munkakönyvtár: $WORKDIR"
echo "   Image fájl: $IMAGEFILE"
echo ""
# Elmenti a kurzor pozícióját 
echo -e "\E7    Kezdődhet a folyamat? (\e[1mi\e[0mgen/\e[1mn\e[0mem):"
echo ""
read resp
# Kitörli az i betüt a képernyőről
echo -e "\EM\E[1K "
if [ "$resp" = "n" ] || [ "$resp" = "nem" ]; then
  echo "  A program leállt."
  exit 1
fi

# Létezik a munka könyvtár? Ha igen, akkor töröljük.
[ -d $WORKDIR ] && rm -rf $WORKDIR
# A munkakönyvtár létrehozása
# Az elmentett pozícióba írja ki a szöveget.
echo -e "\E8   A munkakönyvtárak létrehozása.    "
mkdir $WORKDIR
# Belép a munkakönyvtárba
cd $WORKDIR
# Átmeneti tároló mappák létrehozása
mkdir SRC_PART1 SRC_PART2 DST_PART1 DST_PART2
# Beállítja a forráspartíciót
mount $SDCARD'p1' SRC_PART1
mount $SDCARD'p2' SRC_PART2
# A forrás partíciók adatainak beolvasása
SRC_PART1_MAX=`df -h $WORKDIR/SRC_PART1 | tail -1 | awk '{print $2}'`
SRC_PART1_USED=`df -h $WORKDIR/SRC_PART1 | tail -1 | awk '{print $3}'`
SRC_PART1_TYPE=`parted $SDCARD -ms p \ | grep "^1" | cut -f 5 -d:`
SRC_PART2_MAX=`df -h $WORKDIR/SRC_PART2 | tail -1 | awk '{print $2}'`
SRC_PART2_USED=`df -h $WORKDIR/SRC_PART2 | tail -1 | awk '{print $3}'`
SRC_PART2_TYPE=`parted $SDCARD -ms p \ | grep "^2" | cut -f 5 -d:`
# Az image fájl méretének kiszámítása (p1 max + p2 min + 1GB)
DEST_PART1_MINIMUM_KBYTE=`df $WORKDIR/SRC_PART1 | tail -1 | awk '{print $2}'`
DEST_PART2_MINIMUM_KBYTE=`df $WORKDIR/SRC_PART2 | tail -1 | awk '{print $3}'`
DEST_IMAGE_SIZE_KBYTE=$((DEST_PART1_MINIMUM_KBYTE + DEST_PART2_MINIMUM_KBYTE + 1048576))
# Átváltjuk MB-ra, és a +1-el felfelé konvertáljuk
DEST_IMAGE_SIZE_MBYTE=$((DEST_IMAGE_SIZE_KBYTE /1024 + 1))
# kilép a munkakönyvtárból, és a script mellé készül az image fájl
cd ..
# Az image fájl létrehozása elött törli a régit, és loop eszközként csatolása
[ -f $IMAGEFILE ] && rm -f $IMAGEFILE
dd if=/dev/zero of=$IMAGEFILE bs=1 count=0 seek=${DEST_IMAGE_SIZE_KBYTE%%.*}'K'>/dev/null 2>&1
#megnézzük hol ér véget az első partíció, hogy azt követően indulhasson a második
SRC_PART1_END=`fdisk -l $SDCARD | grep $SDCARD'p1' | awk '{print $4}'`
#partíciók létrehozása az image fájlban, boot flag, Fat32 LBA típus az első partíciónak
# Az első partíció létrehozása az image fájlon 
(echo n; echo p; echo 1; echo; echo $SRC_PART1_END; echo w) | fdisk -c $IMAGEFILE>/dev/null 2>&1
# A második partíció megkapja a maradék helyet
(echo n; echo p; echo 2; echo; echo; echo w) | fdisk -c $IMAGEFILE>/dev/null 2>&1
# Beállítja az 1. partíció fájlrendszerét és a bootable flag-et
(echo a; echo 1; echo t; echo 1; echo c; echo w) | fdisk -c $IMAGEFILE>/dev/null 2>&1
# Az SD kártya UUID-jának klónozása
PARTID=$(blkid -o value -s PARTUUID /dev/mmcblk0p1)
PARTID=${PARTID%-*}
(echo x; echo i; echo 0x$PARTID; echo r; echo p; echo w) | fdisk -c $IMAGEFILE>/dev/null 2>&1
# loop eszköz rögzítése a kimenetről
LOOPDEVICE=`losetup -f --show $IMAGEFILE`
# A partíciók fájlrendszerének kialakítása
# Újraolvassa a loop eszköz partíciókiosztását.
partx -u $LOOPDEVICE
# Az első artíció cimkéje
PARTLABEL1=$(ls -l /dev/disk/by-label | grep mmcblk0p1 | awk '{print $9}')
mkfs.vfat -F 32 -I -n $PARTLABEL1 $LOOPDEVICE'p1'>/dev/null 2>&1
# A 2. partíció cimkéje
PARTLABEL2=$(ls -l /dev/disk/by-label | grep mmcblk0p2 | awk '{print $9}')
mkfs.ext4 -L $PARTLABEL2 $LOOPDEVICE'p2'>/dev/null 2>&1
#csatoljuk a loop eszközt a másoláshoz
mount $LOOPDEVICE'p1' $WORKDIR/DST_PART1
mount $LOOPDEVICE'p2' $WORKDIR/DST_PART2
# Indul a szinkronizáció
echo "   A '$PARTLABEL1' partíció másolása"
rsync -ah --info=progress2 $WORKDIR/SRC_PART1/ $WORKDIR/DST_PART1/ | tr '\r' '\n' | sed --unbuffered 's/ (.*)//' | tr '\n' '\r' ; echo
echo "   A '$PARTLABEL2' partíció másolása"
rsync -ah --info=progress2 --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} $WORKDIR/SRC_PART2/ $WORKDIR/DST_PART2/ | tr '\r' '\n' | sed --unbuffered 's/ (.*)//' | tr '\n' '\r' ; echo
# Ne a root legyen a tulajdonos, és mások is hozzáférjenek az image fájlhoz
chown pi:pi $IMAGEFILE
chmod 755 $IMAGEFILE
exit 0

