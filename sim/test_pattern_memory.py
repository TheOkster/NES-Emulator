import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from vicoco.vivado_runner import get_runner
test_file = os.path.basename(__file__).replace(".py","")


# def reverse_bits(n,size):
#     reversed_n = 0
#     for i in range(size):
#         reversed_n = (reversed_n << 1) | (n & 1)
#         n >>= 1
#     return reversed_n
# this test doesn't work anymore bc of design changes
# would need to  change to make sense with new format

# However, since i have visual tests I probably won't tbh


# @cocotb.test()
# async def test_ppu_timing(dut):
#    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
#    dut.rst.value = 1
#    await ClockCycles(dut.clk, 1)
#    dut.rst.value = 0
#    for _ in range(2):
#       for patt_table in range(2):
#          for tile_row in range(16):
#             for tile_col in range(16):
#                await RisingEdge(dut.patt_table_out_valid)
#                for rel_row in range(8):
#                   for rel_col in range(8):
#                      # if rel_col:
#                      #    await FallingEdge(dut.ppu_clk_trig)
#                      await ClockCycles(dut.clk, 1)
#                      # assert dut.patt_table_pix.value == (0x1251a8 if rel_row == rel_col else 0), f"Invalid value at {rel_row}, {rel_col} in tile {tile_row}, {tile_col}"
#                      # assert dut.patt_table_ind.value == patt_table, f"Pattern table value is not {patt_table}"
#                      assert dut.tile_row.value == tile_row
#                      assert dut.tile_col.value == tile_col
#                      assert dut.rel_row.value == rel_row
#                      assert dut.rel_col.value == rel_col, f"rel_col is {dut.rel_col.value} not {i} as expected"
#                   if rel_row != 7:
#                      await RisingEdge(dut.patt_table_out_valid)
         # await ClockCycles(dut.clk, 50000)
   # I will actually test this later
   # I just wanted to see that palette was correctly loading w/o asserts

      



def ppu_runner():
    """PPU Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM","vivado")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v",
               proj_path / "hdl" / "ppu.sv",
                              proj_path / "hdl" / "palette_ram.sv",
                              proj_path / "hdl" / "name_table.sv"

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
 