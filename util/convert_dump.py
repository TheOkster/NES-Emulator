with open('util/smb - NesPpuMemory.dmp.dmp', 'rb') as f:
   parsed = f.read()
   nametable = parsed[0x2000:0x27FF+1]  

   with open('data/smb_nametable_sample.mem', "w") as f:
      for b in nametable:
         f.write(f"{b:02X}\n")

   palette_ram = parsed[0x3F00:0x3F1F+1]  

   with open('data/palette_ram.mem', "w") as f:
      for b in palette_ram:
         f.write(f"{b:02X}\n")