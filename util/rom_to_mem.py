import sys


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: {0} <NES ROM to convert>".format(sys.argv[0]))

    else:
        rom_fname = sys.argv[1]
        if not rom_fname.endswith(".nes"):
            print("ROM should end with extension .nes")
            print("Usage: {0} <NES ROM to convert>".format(sys.argv[0]))
            exit(1)
        with open(sys.argv[1], "rb") as rom:
            signature = rom.read(4)
            if signature != b'NES\x1a':
                print("Error: invalid rom file")
                exit(1)
            print("Valid rom file!")

            prg_rom_size = int.from_bytes(rom.read(1)) * 16384
            chr_rom_size = int.from_bytes(rom.read(1)) * 8192

            # iNES flags, will save them but won't deal with them 
            flags = [rom.read(1) for _ in range(5)]
            with open("flags.mem", "w") as f:
                f.write("\n".join([flag.hex() for flag in flags]))
            
            rom.read(5)

            prg_rom = [rom.read(1) for _ in range(prg_rom_size)]
            with open("prg_rom.mem", "w") as f:
                f.write("\n".join([byte.hex() for byte in prg_rom]))

            chr_rom = [rom.read(1) for _ in range(chr_rom_size)]
            with open("chr_rom.mem", "w") as f:
                f.write("\n".join([byte.hex() for byte in chr_rom]))

