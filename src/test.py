import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles


@cocotb.test()
async def test_clock_divider(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut._log.info("reset")
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    # set the compare value
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Are big endian: {}".format(dut.ui_in.bigEndian))

    # reset counters
    dut._log.info("reset counters")
    await ClockCycles(dut.clk, 100)
