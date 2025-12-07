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
from cocotb.runner import get_runner
test_file = os.path.basename(__file__).replace(".py","")




@cocotb.test()
async def test_cpu(dut):
   cocotb.start_soon(Clock(dut.clk_slow, 120, units="ns").start())
   cocotb.start_soon(Clock(dut.clk_fast, 10, units="ns").start())

# for now mmp doesn't read a 16 bit address
   mem = {
    int("0xFFFC", 16): int("0x4C", 16), # jump absolute
    int("0xFFFD", 16): int("0x80", 16), 
    int("0xFFFE", 16): int("0x00", 16), 
    int("0x8000", 16): int("0xF0", 16), 
    int("0x8001", 16): int("0x00", 16), 
    int("0xF000", 16): int("0xE8", 16), # INX
    int("0xF001", 16): int("0xC8", 16) # INY
   }
   dut.rst.value = 1
   await ClockCycles(dut.clk_slow, 1)
   dut.rst.value = 0
   for i in range(1000):
        await FallingEdge(dut.clk_fast)

        addr = dut.addr.value 
        if (addr != 0):
            print("addr: ", addr)
            if not (int(addr) in mem):
                mem_val = 0
                print("invaild address")
                # break
            else: 
                mem_val = mem[int(addr)]
            dut.din.value = mem_val
            dut.din_valid.value = 1
            if (dut.rw):
                mem[int(addr)] = dut.dout.value
            
        await RisingEdge(dut.clk_fast)

   await ClockCycles(dut.clk_fast, 5)
   # I will actually test this later
   # I just wanted to see that palette was correctly loading w/o asserts

      



def cpu_runner():
    """CPU Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v",
               proj_path / "hdl" / "cpu.sv"
               ]
    build_test_args = ["-Wall"]
    #values for parameters defined earlier in the code.

    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "cpu"
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
   cpu_runner()
 