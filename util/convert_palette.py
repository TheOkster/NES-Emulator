dest = open('data/2C07.mem', 'w')
with open('util/2C07.pal', 'rb') as f:
   for i in range(64):
      color = f.read(3)
      if not color: # Python bytes falsiness is weird so 0x0 will not go through this even though 0 would
         raise Exception("No bits found past index 63!")
      dest.write(color.hex() + "\n")
   dest.close()
