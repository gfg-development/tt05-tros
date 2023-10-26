from ring_oscillators import *

hw_configs = [
    {"stages": 13, "input_gates": 2},
    {"stages": 13, "input_gates": 4},
]

corners = ["tt", "ff", "ss"]

for hw_config in hw_configs:
    args_t = [hw_config | {"temperature": v} for v in np.linspace(0, 100, 11)]
    args_v = [hw_config | {"supply_voltage": v} for v in np.linspace(1.75, 1.85, 11)]

    results_t = {}
    results_v = {}
    with Pool(7) as pool:
        for corner in corners:
            args_v = [v | {"corner": corner} for v in args_v]
            args_t = [v | {"corner": corner} for v in args_t]
            data_t = pool.map_async(wrapper_simulate_einv, args_t)
            data_v = pool.map_async(wrapper_simulate_einv, args_v)
            results_t[corner] = data_t
            results_v[corner] = data_v

        for corner in corners:
            printAndSave(
                list(results_t[corner].get()),
                filename="sub_nand{}_{}stages_{}_t.csv".format(
                    hw_config["input_gates"], hw_config["stages"], corner
                ),
            )
            printAndSave(
                list(results_v[corner].get()),
                filename="sub_nand{}_{}stages_{}_v.csv".format(
                    hw_config["input_gates"], hw_config["stages"], corner
                ),
            )
