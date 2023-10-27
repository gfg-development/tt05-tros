import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles, First
from cocotb.result import TestFailure

async def test_divider(dut, signal, divider, nr_divided_cycles = 160):
    expected = divider * nr_divided_cycles

    await RisingEdge(signal)
    edge_clk      = RisingEdge(dut.clk)
    edge_div_clk  = RisingEdge(signal)

    count_clk     = 0
    count_div_clk = 0
    while True:
        result = await First(edge_clk, edge_div_clk)
        if result == edge_clk:
            count_clk += 1
        elif result == edge_div_clk:
            count_div_clk += 1

        if nr_divided_cycles == count_div_clk:
            if count_clk != expected:
                raise TestFailure("Reached number of divided clock cylces @ wrong number of clock cycles: {} != {}".format(count_clk, expected))

        if count_clk > expected:
            raise TestFailure("Duration longer than expected")


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

    # reset counters
    dut._log.info("reset counters")
    dut.ui_in.value = 2
    await ClockCycles(dut.clk, 10)
    dut.ui_in.value = 0

    await test_divider(dut, dut.tt_um_gfg_development_tros.nand4_div_clk, 4)
    await test_divider(dut, dut.tt_um_gfg_development_tros.nand4_cap_div_clk, 4)
    await test_divider(dut, dut.tt_um_gfg_development_tros.inv_sub_div_clk, 4)

    await ClockCycles(dut.clk, 1000)
