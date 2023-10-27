import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles, First
from cocotb.result import TestFailure

async def test_divider(signal, duration_ns, cycles):
    await RisingEdge(signal)
    timer = Timer(duration_ns, 'ns')
    edge_div_clk  = RisingEdge(signal)
    signal._log.info("Go into loop {} ns".format(duration_ns))
    count_div_clk = 0
    while True:
        result = await First(timer, edge_div_clk)
        if result is timer:
            if cycles != count_div_clk:
                assert count_div_clk == cycles, "Wrong number of clock cylces:"
            else:
                break
        elif result == edge_div_clk:
            count_div_clk += 1

        if count_div_clk > cycles:
            assert count_div_clk == cycles, "Wrong number of clock cylces:"


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

    cycles = 160
    divider = 4
    duration_ns = cycles * divider * 20
    await test_divider(dut.tt_um_gfg_development_tros.nand4_div_clk, duration_ns, cycles)
    await test_divider(dut.tt_um_gfg_development_tros.nand4_cap_div_clk, duration_ns, cycles)
    await test_divider(dut.tt_um_gfg_development_tros.inv_sub_div_clk, duration_ns, cycles)

    await ClockCycles(dut.clk, 1000)
