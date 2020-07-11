#!/bin/python3
import sys
import random
import serial

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: %s <port> <baudrate>" % sys.argv[0], flush=True)
        sys.exit(1)

    port, baudrate = sys.argv[1:3]
    baudrate = int(baudrate)
    print((port, baudrate), flush=True)

    errors = 0
    total  = 0
    with serial.Serial(port, baudrate, timeout=1, write_timeout=1) as serial:
        while True:
            total += 1

            wr = bytes(chr(random.randint(0, 127)), "ascii")
            serial.write(wr)

            as_int = lambda x: int.from_bytes(x, byteorder='little')
            rd, wr = (as_int(serial.read(1)), as_int(wr))

            if rd != wr:
                errors += 1
                print("ERROR(Got '%d', expectd '%d')" % (rd, wr), flush=True)
            else:
                print("OK(Errors: %d/%d)" % (errors, total), flush=True)

