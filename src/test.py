import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles, First


async def count_edges_cycles(signal, edges):
    edge = RisingEdge(signal)
    for i in range(edges):
        await edge
        signal._log.info("Rising edge %d detected" % i)
    signal._log.info("Finished, returning %d" % edges)
    return edges

async def test_divider(signal, periode_ns, cycles):
    await RisingEdge(signal)
    
    timer = Timer(periode_ns, "ns")
    task = cocotb.start_soon(count_edges_cycles(signal, cycles))
    count = 0
    expect = cycles

    while True:
        result = await First(timer, task.join())
        assert count <= expect, "Task didn't complete in expected time"
        if result is timer:
            signal._log.info("Count %d: Task still running" % count)
            count += 1
        else:
            break

    assert count == expect, "Expected to monitor the task %d times but got %d" % (
        expect,
        count,
    )
    assert result == cycles, "Expected task to return %d but got %s" % (
        cycles,
        repr(result),
    )
    

@cocotb.test()
async def test_clock_divider(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    # reset
    dut._log.info("reset")
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # test the different divider
    for i in range(4):
        # reset counters
        divider = 4 + 4 * i
        dut._log.info("reset counters and set divider for divider: {}".format(divider))
        dut.ui_in.value = 2 + (i << 6)
        await ClockCycles(dut.clk, 10)
        dut.ui_in.value = 0 + (i << 6)

        cycles = 160
        period_ns = 20 * divider
        await test_divider(dut.tt_um_gfg_development_tros.nand4_div_clk, period_ns, cycles)
        await test_divider(dut.tt_um_gfg_development_tros.nand4_cap_div_clk, period_ns, cycles)
        await test_divider(dut.tt_um_gfg_development_tros.inv_sub_div_clk, period_ns, cycles)
