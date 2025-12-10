with open('util/Donkey Kong (USA) (Rev 1) (e-Reader) - NesPpuMemory.dmp.dmp', 'rb') as f:
   parsed = f.read()
   nametable = parsed[0x2000:0x27FF+1]  

   with open('data/smb_nametable_sample.mem', "w") as f:
      for b in nametable:
         f.write(f"{b:02X}\n")

   palette_ram = parsed[0x3F00:0x3F1F+1]  

   with open('data/palette_ram.mem', "w") as f:
      for b in palette_ram:
         f.write(f"{b:02X}\n")


   ch_rom = parsed[0x0:0x1FFF+1]  

   with open('data/chr_rom.mem', "w") as f:
         for b in ch_rom:
            f.write(f"{b:02X}\n")