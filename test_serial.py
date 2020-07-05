#!/bin/python3
import sys
import serial

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: %s <port> <baudrate>" % sys.argv[0], flush=True)
        sys.exit(1)

    port, baudrate = sys.argv[1:3]
    baudrate = int(baudrate)

    print((port, baudrate), flush=True)
    with serial.Serial(port, baudrate, timeout=None) as serial:
        cnt = 0
        while True:
            serial.write(bytes(chr(65+cnt), "utf-8"))
            print(serial.read(1), flush=True)
            cnt = (cnt+1)%26
