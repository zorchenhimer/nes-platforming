import math

speed = 3
offset = int("0", 16)
frames = 30
rate = 0.10

for i in range(frames):
    speed -= rate
    if speed <= 0:
        speed = 0
    print(hex(int(speed)) + " " + hex(int(speed*100) & 0x00FF))
    #offset -= math.floor(speed)
    #print(hex(offset))
