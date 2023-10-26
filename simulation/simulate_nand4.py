from ring_oscillators import *

hw_configs = [
    #{"cap_gates": 0, "stages": 33}, 
    #{"cap_gates": 4, "stages": 23},
    #{"cap_gates": 8, "stages": 17},
    {"cap_gates": 16, "stages": 11},    
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
            data_t = pool.map_async(wrapper_simulate_nand, args_t)
            data_v = pool.map_async(wrapper_simulate_nand, args_v)
            results_t[corner] = data_t
            results_v[corner] = data_v

        for corner in corners:
            printAndSave(
                list(results_t[corner].get()),
                filename="nand4_{}stages_{}caps_{}_t.csv".format(
                    hw_config["stages"], hw_config["cap_gates"], corner
                ),
            )
            printAndSave(
                list(results_v[corner].get()),
                filename="nand4_{}stages_{}caps_{}_v.csv".format(
                    hw_config["stages"], hw_config["cap_gates"], corner
                ),
            )
