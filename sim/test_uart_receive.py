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

# utility function to reverse bits:
def reverse_bits(n,size):
    reversed_n = 0
    for i in range(size):
        reversed_n = (reversed_n << 1) | (n & 1)
        n >>= 1
    return reversed_n

# test spi message:
# SPI_RESP_MSG = 0x0A55
# #flip them:
# SPI_RESP_MSG = reverse_bits(SPI_RESP_MSG,16)

# SPI_CON_MSG = 0xB00B&0xFFFF

BAUD_PERIOD = 10

UART_BYTE = 0x6f
UART_BYTE2 = 0xab

# this module below is a simple "fake" spi module written in Python that we can...
# test our design against.
# async def test_spi_device(dut):
#   count = 0
#   count_max = 16 #change for different sizes
#   recv_msg = 0
#   while True:
#     await FallingEdge(dut.cs) #listen for falling CS
#     dut.cipo.value = (SPI_RESP_MSG>>count)&0x1 #feed in lowest bit
#     dut._log.info(f"SPI peripheral Device Sending: {dut.cipo.value}")
#     count+=1
#     count%=16
#     while dut.cs.value.integer ==0:
#       await RisingEdge(dut.dclk)
#       bit = dut.copi.value.integer #grab value:
#       dut._log.info(f"SPI peripheral Device Receiving: {bit}")
#       recv_msg = recv_msg << 1 | bit
#       dut._log.info(f"SPI peripheral Device Message So Far: {hex(recv_msg)}")
#       await FallingEdge(dut.dclk)
#       dut.cipo.value = (SPI_RESP_MSG>>count)&0x1 #feed in lowest bit
#       dut._log.info(f"SPI peripheral Device Sending: {dut.cipo.value}")
#       count+=1
#       count%=16
#     assert recv_msg == SPI_CON_MSG

async def test_uart_transmitter(dut):
    dut.din.value = 1
    message = [(UART_BYTE >> i) & 1 for i in range(8)]
    message2 = [(UART_BYTE2 >> i) & 1 for i in range(8)]
    await ClockCycles(dut.clk, 20)
    dut.din.value = 0
    await ClockCycles(dut.clk, BAUD_PERIOD)
    for bit in message:
        dut.din.value = bit
        await ClockCycles(dut.clk, BAUD_PERIOD)
    dut.din.value = 1
    await ClockCycles(dut.clk, 10)
    dut.din.value = 0
    await ClockCycles(dut.clk, BAUD_PERIOD)
    for bit in message2:
        dut.din.value = bit
        await ClockCycles(dut.clk, BAUD_PERIOD)
    dut.din.value = 1



@cocotb.test()
async def test_a(dut):
    """cocotb test for the UART transmitting module"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    cocotb.start_soon(test_uart_transmitter(dut))
    dut._log.info("Holding reset...")
    dut.rst.value = 1
    await ClockCycles(dut.clk, 3) #wait three clock cycles
    assert dut.dout_valid.value.integer==0, "dout is not invalid on reset!"
    await  FallingEdge(dut.clk)
    dut.rst.value = 0 #un reset device
    await ClockCycles(dut.clk, 3) #wait a few clock cycles
    await  FallingEdge(dut.clk)
    dut._log.info("Awaiting Completion")
    await RisingEdge(dut.dout_valid)
    await ReadOnly()
    assert dut.dout.value == UART_BYTE, f"expected message {hex(UART_BYTE)}, received {hex(dut.dout.value)} instead."
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    assert dut.dout_valid.value == 0, "dout is not invalid after one cycle!"
    await FallingEdge(dut.clk)
    dut._log.info("Awaiting Completion 2")
    await RisingEdge(dut.dout_valid)
    await ReadOnly()
    assert dut.dout.value == UART_BYTE2, f"expected message {hex(UART_BYTE2)}, received {hex(dut.dout.value)} instead."
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    assert dut.dout_valid.value == 0, "dout is not invalid after one cycle!"
    # dut.trigger.value = 1
    # await ClockCycles(dut.clk, 1,rising=False)
    # dut.din.value = 0xAA # once trigger in is off, don't expect din to stay the same!!
    # dut.trigger.value = 0
    # await ClockCycles(dut.clk, 10)
    # await with_timeout(FallingEdge(dut.busy),5000,'ns')
    await ClockCycles(dut.clk, 300)

def uart_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_receive.sv"]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 100000000, 'BAUD_RATE': 100000000/BAUD_PERIOD} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "uart_receive"
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=True,
        build_args=build_test_args,
        parameters=parameters,
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
    uart_runner()