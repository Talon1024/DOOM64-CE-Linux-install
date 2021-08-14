#!/usr/bin/env python3
# Dump all of the lumps in a Doom WAD file
# © 2021 Kevin "Talon1024" Caccamo. MIT License.

import struct
import argparse
import os
import io
from collections import namedtuple


def get_file_type(stream):
    orig_pos = stream.tell()
    stream.seek(0)
    first_bytes = stream.read(8)
    ftype = ""
    if first_bytes == b"\x89PNG\r\n\x1A\n":
        ftype = ".png"
    elif first_bytes.startswith(b"PWAD") or first_bytes.startswith(b"IWAD"):
        ftype = ".wad"
    stream.seek(orig_pos)
    return ftype


WADDirEntry = namedtuple("WADDirEntry", "offset size name")


class WADLump:
    def __init__(self, name, data):
        self.name = name
        self.data = data
    
    @property
    def length(self):
        if self.data is None:
            return 0
        else:
            return len(self.data)


class WADFile:

    IWAD_HEADER = b"IWAD"
    PWAD_HEADER = b"PWAD"

    def __init__(self, stream):
        header = stream.read(4)
        if header != self.IWAD_HEADER and header != self.PWAD_HEADER:
            print("Not a Doom WAD file!")
            return
        self.lumps = []
        # Read the lumps
        lump_count = struct.unpack("<i", stream.read(4))[0]
        directory_offset = struct.unpack("<i", stream.read(4))[0]
        data_pos = stream.tell()
        lump_entries = []
        stream.seek(directory_offset)
        for lump_index in range(lump_count):
            dir_datum = stream.read(16)
            lump_entries.append(
                WADDirEntry(*struct.unpack("<2i8s", dir_datum)))
        for entry in lump_entries:
            stream.seek(entry.offset)
            entry_name = entry.name.rstrip(b"\0").decode()
            self.lumps.append(
                WADLump(entry_name, stream.read(entry.size)))

    def dump_to_directory(self, directory):
        for lump in self.lumps:
            with io.BytesIO(lump.data) as lumpdata:
                lumpftype = get_file_type(lumpdata)
            lumpath = os.path.join(directory, lump.name) + lumpftype
            with open(lumpath, "wb") as lumpfile:
                lumpfile.write(lump.data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Dump all of the lumps in a Doom WAD file.")
    parser.add_argument("wad", help="The WAD file to dump")
    parser.add_argument(
        "--destination",
        help="Where to dump the lumps. Uses the current working directory by "
             "default."
    )
    args = parser.parse_args()
    wadfname = getattr(args, "wad")
    destdir = getattr(args, "destination", os.getcwd())

    with open(wadfname, "rb") as wadfile:
        wad = WADFile(wadfile)
        wad.dump_to_directory(destdir)
