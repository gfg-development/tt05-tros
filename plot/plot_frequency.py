import serial
import queue
import threading

import matplotlib.pyplot as plt
import numpy as np
import matplotlib.animation as animation

def recv():
    with serial.Serial("/dev/ttyACM0") as ser:
        while True:
            data = ser.readline().split(b' ')
            if len(data) != 3:
                print("Invalid data")
            else:
                data = [float(d.decode("utf-8").strip()) for d in data]
                q.put(np.array(data) / 1e6)

q = queue.Queue()
t = threading.Thread(target=recv)
t.start()

fig, ax = plt.subplots(3, 1)
data = [[], [], []]
time = []
lines = []
for i in range(3):
    lines.append(ax[i].plot(time, data[i])[0])
    ax[i].set(xlabel='Sample', ylabel='Frequency / MHz')

def update(frame):
    if not q.empty():
        if len(time) == 0:
            time.append(0)
        else:
            time.append(time[-1] + 1)
        nd = q.get()
        for i in range(3):
            data[i].append(nd[i])

    for i in range(3):
        lines[i].set_xdata(time)
        lines[i].set_ydata(data[i])
        if len(time) != 0:
            ax[i].set(xlim=[0, np.max(time)], ylim=[np.min(data[i]), np.max(data[i])])
    return lines

ani = animation.FuncAnimation(fig=fig, func=update, frames=40, interval=30)
plt.show()
