import pandas
import matplotlib.pyplot as plt
import numpy as np
import sys


for simulation in sys.argv[1:]:
    df_t = pandas.read_csv(simulation + "_t.csv")
    df_v = pandas.read_csv(simulation + "_v.csv")

    def analyse(parameter, df):
        m, b = np.polyfit(df[parameter], df["Cycle time / ns"], 1)
        
        def fit(x):
            return m * x + b

        plt.figure()
        plt.title("{} {} dependency".format(simulation, parameter.split('/')[0]))
        plt.plot(df[parameter], df["Cycle time / ns"])
        plt.plot(df[parameter], fit(df[parameter]))
        
        plt.ylabel("Cycle time / ns")
        plt.xlabel(parameter)

        print("\t{}: {} ps /{} + {} ns".format(parameter.split('/')[0], m * 1e3, parameter.split('/')[1], b))

        return (m, b)

    print(simulation)
    (m_t, b_t) = analyse("Temperature / °C", df_t)
    (m_v, b_v) = analyse("Supply Voltage / V", df_v)

    print("\tRatio between temperature and voltage sensitivity: {}".format(m_t / m_v))
    
plt.show()
