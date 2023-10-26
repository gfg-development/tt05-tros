import subprocess
import tempfile
import os
from multiprocessing.pool import Pool

from scipy import signal
import numpy as np
import matplotlib.pyplot as plt

from prettytable import PrettyTable

import ngspice_read


def shifted_range(rangeob, shift):
    size, shift = rangeob.stop, shift * rangeob.step
    return ((i + shift) % size for i in rangeob)


def write_spice_file_nand(
    path,
    corner,
    stages,
    input_gates,
    size,
    temperature,
    single_gate,
    supply_voltage,
    cap_gates,
    sub_stages,
    sub_threshold,
):
    with open(path, "w") as f:
        x_ctr = 0
        f.write("** Ring Oscillator with NAND{}\r\n".format(input_gates))
        for i, o in zip(range(stages), shifted_range(range(stages), 1)):
            f.write("x{} net{} ".format(x_ctr, i))
            x_ctr += 1
            for _ in range(input_gates - 1):
                if single_gate:
                    f.write("VPWR ")
                else:
                    f.write("net{} ".format(i))
            f.write(
                "VGND VNB VPB VPWR net{} sky130_fd_sc_hd__nand{}_{}\r\n".format(
                    o, input_gates, size
                )
            )

            for i in range(cap_gates):
                f.write(
                    "x{} net{} VGND VGND VNB VPB VPWR net{}open sky130_fd_sc_hd__nand2_1\r\n".format(
                        x_ctr, i, i
                    )
                )
                x_ctr += 1

        if cap_gates != 0 and not (input_gates == 2 and size == 1):
            f.write(
                ".include /usr/local/share/sky130_fd_sc_hd/cells/nand2/sky130_fd_sc_hd__nand2_1.spice\r\n"
            )

        f.write(
            """.lib /usr/local/share/sky130_fd_pr/models/sky130.lib.spice {}
.include /usr/local/share/sky130_fd_sc_hd/cells/nand{}/sky130_fd_sc_hd__nand{}_{}.spice
Vgnd VGND 0 0
Vnb VNB 0 0
Vdd VPWR VGND {}
Vpb VPB VGND {}
.temp {}
.tran 0.01n 1u
.save v(net0)
.end
""".format(
                corner,
                input_gates,
                input_gates,
                size,
                supply_voltage,
                supply_voltage,
                temperature,
            )
        )

    return [
        corner,
        stages,
        input_gates,
        size,
        temperature,
        single_gate,
        supply_voltage,
        cap_gates,
        None,
        None,
    ]


def write_spice_file_inv(
    path,
    corner,
    stages,
    input_gates,
    size,
    temperature,
    single_gate,
    supply_voltage,
    cap_gates,
    sub_stages,
    sub_threshold,
):
    with open(path, "w") as f:
        f.write("** Ring Oscillator with INV\r\n")
        for i, o in zip(range(stages), shifted_range(range(stages), 1)):
            f.write(
                "x{} net{} VGND VNB VPB VPWR net{} sky130_fd_sc_hd__inv_{}\r\n".format(
                    i, i, o, size
                )
            )

        f.write(
            """.lib /usr/local/share/sky130_fd_pr/models/sky130.lib.spice {}
.include /usr/local/share/sky130_fd_sc_hd/cells/inv/sky130_fd_sc_hd__inv_{}.spice
Vgnd VGND 0 0
Vnb VNB 0 0
Vdd VPWR VGND {}
Vpb VPB VGND {}
.temp {}
.tran 0.01n 1u
.save v(net0)
.end
""".format(
                corner, size, supply_voltage, supply_voltage, temperature
            )
        )

    return [
        corner,
        stages,
        1,
        size,
        temperature,
        True,
        supply_voltage,
        cap_gates,
        None,
        None,
    ]


def write_spice_file_sub_nand(
    path,
    corner,
    stages,
    input_gates,
    size,
    temperature,
    single_gate,
    supply_voltage,
    cap_gates,
    sub_stages,
    sub_threshold,
):
    with open(path, "w") as f:
        f.write("** Ring Oscillator with tristate NAND\r\n")
        x_ctr = 0
        for _ in range(stages):
            f.write("x{} net{} ".format(x_ctr, x_ctr))

            for _ in range(1, input_gates):
                f.write("vdac ")

            f.write(
                "VGND VNB VPB VPWR net{} sky130_fd_sc_hd__nand{}_{}\r\n".format(
                    x_ctr + 1, input_gates, size
                )
            )
            x_ctr += 1

        f.write(
            "x{} vdac VGND VNB VPB VPWR vdac sky130_fd_sc_hd__inv_{}\r\n".format(
                x_ctr, size
            )
        )

        f.write(
            """.lib /usr/local/share/sky130_fd_pr/models/sky130.lib.spice {}
.include /usr/local/share/sky130_fd_sc_hd/cells/inv/sky130_fd_sc_hd__inv_{}.spice
.include /usr/local/share/sky130_fd_sc_hd/cells/einvp/sky130_fd_sc_hd__einvp_{}.spice
.include /usr/local/share/sky130_fd_sc_hd/cells/nand2/sky130_fd_sc_hd__nand{}_{}.spice
Vgnd VGND 0 0
Vnb VNB 0 0
Vdd VPWR VGND {}
Vpb VPB VGND {}
.temp {}
.tran 0.01n 1u
.save v(net0)
.end
""".format(
                corner,
                size,
                size,
                input_gates,
                size,
                supply_voltage,
                supply_voltage,
                temperature,
            )
        )

    return [
        corner,
        stages,
        input_gates,
        size,
        temperature,
        True,
        supply_voltage,
        cap_gates,
        None,
        sub_threshold,
    ]


def write_spice_file_einv(
    path,
    corner,
    stages,
    input_gates,
    size,
    temperature,
    single_gate,
    supply_voltage,
    cap_gates,
    sub_stages,
    sub_threshold,
):
    with open(path, "w") as f:
        f.write("** Ring Oscillator with tristate INV\r\n")
        x_ctr = 0
        for _ in range(stages):
            for _ in range(sub_stages):
                f.write(
                    "x{} net{} vdac VGND VNB VPB VPWR net{} sky130_fd_sc_hd__einvp_{}\r\n".format(
                        x_ctr, x_ctr, x_ctr + 1, size
                    )
                )
                x_ctr += 1

            f.write(
                "x{} net{} VGND VNB VPB VPWR net{} sky130_fd_sc_hd__inv_{}\r\n".format(
                    x_ctr, x_ctr, x_ctr + 1, size
                )
            )
            x_ctr += 1

        f.write(
            "x{} net{} VPWR VGND VNB VPB VPWR net0 sky130_fd_sc_hd__nand2_{}\r\n".format(
                x_ctr, x_ctr, size
            )
        )
        x_ctr += 1

        f.write(
            "x{} vdac VGND VNB VPB VPWR vdac sky130_fd_sc_hd__inv_{}\r\n".format(
                x_ctr, size
            )
        )

        f.write(
            """.lib /usr/local/share/sky130_fd_pr/models/sky130.lib.spice {}
.include /usr/local/share/sky130_fd_sc_hd/cells/inv/sky130_fd_sc_hd__inv_{}.spice
.include /usr/local/share/sky130_fd_sc_hd/cells/einvp/sky130_fd_sc_hd__einvp_{}.spice
.include /usr/local/share/sky130_fd_sc_hd/cells/nand2/sky130_fd_sc_hd__nand2_{}.spice
Vgnd VGND 0 0
Vnb VNB 0 0
Vdd VPWR VGND {}
Vpb VPB VGND {}
.temp {}
.tran 0.01n 1u
.save v(net0)
.end
""".format(
                corner, size, size, size, supply_voltage, supply_voltage, temperature
            )
        )

    return [
        corner,
        stages,
        1,
        size,
        temperature,
        True,
        supply_voltage,
        cap_gates,
        sub_stages,
        sub_threshold,
    ]


def simulate_ro(
    write_spice_file,
    corner="tt",
    stages=13,
    input_gates=4,
    size=1,
    temperature=23,
    single_gate=False,
    supply_voltage=1.8,
    cap_gates=0,
    sub_stages=1,
    sub_threshold=None,
):
    with tempfile.TemporaryDirectory() as tempdir:
        params = write_spice_file(
            os.path.join(tempdir, "ring.spice"),
            corner,
            stages,
            input_gates,
            size,
            temperature,
            single_gate,
            supply_voltage,
            cap_gates,
            sub_stages,
            sub_threshold,
        )

        subprocess.run(
            [
                "ngspice",
                "-b",
                "-r",
                os.path.join(tempdir, "ring.raw"),
                "-o",
                os.path.join(tempdir, "ring.out"),
                os.path.join(tempdir, "ring.spice"),
            ]
        )

        try:
            data = ngspice_read.ngspice_read(os.path.join(tempdir, "ring.raw"))
            p = data.get_plots()[0]
            scale = p.get_scalevector().get_data()[100:]
            data = p.get_datavectors()[0].get_data()[100:]
            zdata = np.zeros(1024 * 1024)
            zdata[0 : len(data)] = data

            f, Pxx_den = signal.periodogram(zdata, 1.0 / (scale[1] - scale[0]))
            Pxx_den[f < 5e6] = 0
            freq = f[np.argmax(Pxx_den[1:]) + 1]

            return params + [freq]
        except Exception as e:
            print(e)


def wrapper_simulate_nand(args):
    return simulate_ro(write_spice_file_nand, **args)


def wrapper_simulate_inv(args):
    return simulate_ro(write_spice_file_inv, **args)


def wrapper_simulate_einv(args):
    return simulate_ro(write_spice_file_einv, **args)


def wrapper_simulate_sub_nand(args):
    return simulate_ro(write_spice_file_sub_nand, **args)


def printAndSave(data, filename="data.csv"):
    tab = PrettyTable(
        [
            "Corner",
            "Stages",
            "# input gates",
            "Size",
            "Temperature / °C",
            "Single gate",
            "Supply Voltage / V",
            "Cap gates",
            "Sub stages",
            "Sub threshold",
            "Cycle time / ns",
            "Frequency / MHz",
        ]
    )
    for d in data:
        if d is not None:
            tab.add_row(d[0:-1] + [1e9 / d[-1]] + [d[-1] / 1e6])

    print(tab)

    with open(filename, "w", newline="") as f_output:
        f_output.write(tab.get_csv_string())
