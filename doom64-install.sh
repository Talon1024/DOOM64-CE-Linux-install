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

# Link files from this repo into the Doom 64 CE directories
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

# Extract the lost levels from DOOM64.IWAD and patch them
if [[ ! -f DOOM64.CE.Maps.LostLevels.pk3 ]]; then
    waddir=/tmp/wad
    zipdir=/tmp/ce
    mapdir=${zipdir}/maps
    for direc in $waddir $zipdir $mapdir; do
        mkdir -p $direc
    done
    wadex=patcher/wadex/wadex.py
    cemaps=(LOST{01..07})
    ogmaps=(MAP{34..40})
    python3 $wadex $steamapps/Doom\ 64/DOOM64.WAD ${ogmaps[@]} --destination $waddir
    # Apply each patch
    for ((index=0; index < ${#ogmaps[@]}; index++)); do
        cename=${cemaps[$index]}
        ogname=${ogmaps[$index]}
        ogwadname="$ogname.wad"
        cepatchname="$cename.bps"
        cewadname="$cename.wad"
        $flips --apply patcher/$cepatchname $waddir/$ogwadname $mapdir/$cewadname
    done
    # Zip up the package and move it to the Doom 64 CE directory
    cd $zipdir
    zip -r DOOM64.CE.Maps.LostLevels.pk3 .
    mv -t $curdir DOOM64.CE.Maps.LostLevels.pk3
    cd -
    # Remove temporary files
    rm -rf $waddir $zipdir
fi
