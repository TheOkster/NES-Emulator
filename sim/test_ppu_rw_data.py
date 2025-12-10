import cocotb
import os
import random
import sys
import numpy as np
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from PIL import Image

test_file = os.path.basename(__file__).replace(".py","")


# def reverse_bits(n,size):
#     reversed_n = 0
#     for i in range(size):
#         reversed_n = (reversed_n << 1) | (n & 1)
#         n >>= 1
#     return reversed_n

async def ppu_clk_triggerer(dut):
    while True:
        dut.ppu_clk_trig.value = 1
        await RisingEdge(dut.clk)

        dut.ppu_clk_trig.value = 0
        for _ in range(18):   
            await RisingEdge(dut.clk)

@cocotb.test()
async def test_ppu_write(dut):
   cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
   cocotb.start_soon(ppu_clk_triggerer(dut))
   dut.rst.value = 1
   await ClockCycles(dut.clk, 1)
   dut.rst.value = 0
   await RisingEdge(dut.ppu_clk_trig)
   await RisingEdge(dut.ppu_clk_trig)
   # pixels = np.zeros((240, 256, 3), dtype=np.uint8)
   await ClockCycles(dut.clk, 19*242*341)
   for _ in range(1*1):
      dut.cpu_dout.value = 0x10
      dut.cpu_rw.value = 1
      dut.cpu_addr.value = 0x2006
      await ClockCycles(dut.clk, 19)
   for _ in range(1*1):
      dut.cpu_dout.value = 0x00
      await ClockCycles(dut.clk, 19)
   # vram addr should be 0x1000
   print(dut.dot.value)
   for _ in range(1*1):
      dut.cpu_dout.value = 0xF5
      dut.cpu_rw.value = 1
      dut.cpu_addr.value = 0x2007 # writing to pattern table, not needed in most games
      await ClockCycles(dut.clk, 19)
      dut.cpu_rw.value = 0
   for _ in range(1*1):
      dut.cpu_dout.value = 0x10
      dut.cpu_rw.value = 1
      dut.cpu_addr.value = 0x2006
      await ClockCycles(dut.clk, 19)
   for _ in range(1*1):
      dut.cpu_dout.value = 0x00
      await ClockCycles(dut.clk, 19)
   for _ in range(1*1):
      # dut.cpu_dout.value = 0xF5
      dut.cpu_rw.value = 0
      dut.cpu_addr.value = 0x2007 # reading from pattern table, not needed in most games
      await ClockCycles(dut.clk, 19)
      dut.cpu_rw.value = 1
   assert dut.cpu_din.value != 0xF5, f"This should be buffered..."
   for _ in range(1*1):
      # dut.cpu_dout.value = 0xF5
      dut.cpu_rw.value = 0
      dut.cpu_addr.value = 0x2007 # writing to pattern table, not needed in most games
      await ClockCycles(dut.clk, 19)
      dut.cpu_rw.value = 1
   assert dut.cpu_din.value == 0xF5, f"Expected dut.cpu_din to be 0xF5 but instead it is {dut.cpu_din.value}"
   # assert dut.vram_addr.value == 0x69, f"Expected dut.vram to be 0x69 but instead it is {dut.vram_addr}"
  
   # for _ in range(1*1):
   #    dut.cpu_dout.value = 0xA
   #    dut.cpu_rw.value = 1
   #    dut.cpu_addr.value = 0x2001
   #    await ClockCycles(dut.clk, 19)
   #    dut.cpu_rw.value = 0
   # for _ in range(1*340):
   #    await ClockCycles(dut.clk, 19)
   # for _ in range(21*341):
   #    await ClockCycles(dut.clk, 1)
   #    await ClockCycles(dut.clk, 18)

   # for _ in range(1*341):
   #    await ClockCycles(dut.clk, 1)
   #    await ClockCycles(dut.clk, 18)

            




def ppu_runner():
    """PPU Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v",
               proj_path / "hdl" / "palette_ram.sv", proj_path/ "hdl" /"ppu.sv", proj_path/ "hdl" / "name_table.sv"
               ]
    build_test_args = ["-Wall"]
    #values for parameters defined earlier in the code.

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "ppu"
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module=test_file,
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
   ppu_runner()
 