from rp2 import PIO, StateMachine, asm_pio
from machine import Pin
from ttboard.demoboard import DemoBoard

mytt = DemoBoard.get()
mytt.shuttle.tt_um_gfg_development_tros.enable()

# Set divider to maximum
mytt.input_byte = 0b11000000

# Code from pythoncoder (https://forum.micropython.org/viewtopic.php?t=11463#p62683)
@rp2.asm_pio(set_init=rp2.PIO.IN_LOW, autopush=True, push_thresh=32)
def period():
    wrap_target()
    set(x, 0)
    wait(0, pin, 0)  # Wait for pin to go low
    wait(1, pin, 0)  # Low to high transition
    label('low_high')
    jmp(x_dec, 'next') [1]  # unconditional
    label('next')
    jmp(pin, 'low_high')  # while pin is high
    label('low')  # pin is low
    jmp(x_dec, 'nxt')
    label('nxt')
    jmp(pin, 'done')  # pin has gone high: all done
    jmp('low')
    label('done')
    in_(x, 32)  # Auto push: SM stalls if FIFO full
    wrap()

inv_sub     = Pin(14, Pin.IN, Pin.PULL_UP)
nand4_cap   = Pin(15, Pin.IN, Pin.PULL_UP)
nand4       = Pin(16, Pin.IN, Pin.PULL_UP)

sm_inv_sub = rp2.StateMachine(0, period, in_base=inv_sub, jmp_pin=inv_sub)
sm_inv_sub.active(1)
sm_nand4_cap = rp2.StateMachine(1, period, in_base=nand4_cap, jmp_pin=nand4_cap)
sm_nand4_cap.active(1)
sm_nand4 = rp2.StateMachine(2, period, in_base=nand4, jmp_pin=nand4)
sm_nand4.active(1)

# Clock is 125MHz. 3 cycles per iteration, so unit is 24.0ns
def scale(v):
    return (1 + (v ^ 0xffffffff)) * 24e-9

while True:
    t_inv_sub   = 0
    t_nand4_cap = 0
    t_nand4     = 0

    for _ in range(4096):
        t_inv_sub   += scale(sm_inv_sub.get())
        t_nand4_cap += scale(sm_nand4_cap.get())
        t_nand4     += scale(sm_nand4.get())


    print(4096 * 2**7 / t_inv_sub, 4096 * 2**7 / t_nand4_cap, 4096 * 2**7 / t_nand4)

