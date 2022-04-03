#!/usr/bin/env bash
# Install DOOM 64 CE - Linux
# © 2021 Kevin "Talon1024" Caccamo. MIT License.

steamapps=$HOME/.steam/steam/steamapps/common
flips=./patcher/flips/flips-linux
curdir=$PWD

# Make Flips executable
if [[ -f $flips && ! -x $flips ]]; then
    chmod +x $flips || exit 1
fi

dir=$(dirname $(realpath -e $0))
for dfile in $(find $dir/patcher -type f); do
    odfile=${dfile:$((${#dir}+1))}
    ln -s $dfile $odfile
done

# Ensure DOOM64.IWAD is set up
if [[ ! -f DOOM64.IWAD ]]; then
    if [[ ! -f $steamapps/Doom\ 64/DOOM64.WAD ]]; then
        echo "Doom 64 is not installed! Please buy it from Steam and install it: https://store.steampowered.com/app/1148590/DOOM_64/"
        exit 1
    else
        $flips --apply patcher/DOOM64.bps $steamapps/Doom\ 64/DOOM64.WAD DOOM64.IWAD
    fi
fi

if [[ ! -f DOOM64.CE.Maps.LostLevels.pk3 ]]; then
    # Extract the lost levels from DOOM64.IWAD and patch them
    waddir=/tmp/wad
    zipdir=/tmp/ce
    mapdir=${zipdir}/maps
    for direc in $waddir $zipdir $mapdir; do
        mkdir -p $direc
    done
    wadex=patcher/wadex/wadex.py
    python3 $wadex --destination $waddir $steamapps/Doom\ 64/DOOM64.WAD
    for mapnum in {34..40}; do
        lostnum=$((mapnum - 33)) # The first of the "Lost Levels" should be LOST01
        printf -v lostname "LOST%02d" $lostnum
        printf -v mapname "MAP%02d" $mapnum
        mapwadname="$mapname.wad"
        lostpchname="$lostname.bps"
        lostwadname="$lostname.WAD"
        $flips --apply patcher/$lostpchname $waddir/$mapwadname $mapdir/$lostwadname
        mkdir -p $waddir/$lostname
        python3 $wadex --destination $waddir/$lostname $waddir/$mapwadname
    done
    cd $zipdir
    zip -r DOOM64.CE.Maps.LostLevels.pk3 .
    mv -t $curdir DOOM64.CE.Maps.LostLevels.pk3
    cd -
    rm -rf $waddir $zipdir
fi
