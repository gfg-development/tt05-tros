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
    dut.ui_in[6:7].value = 0
    # set the compare value
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # reset counters
    dut._log.info("reset counters")
    dut.ui_in[1].value = 1
    await ClockCycles(dut.clk, 10)
    dut.ui_in[1].value = 0
