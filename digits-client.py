import sys
import serial

'''
EXAMPLE:
python digits-client.py COM5 9600 0 0 0 0.75 0.8125 0.3125 0 0 0 0 0 0.6875 1 0.5625 0 0 0 0 0.1875 0.9375 1 0.375 0 0 0 0.4375 0.9375 1 1 0.125 0 0 0 0 0.0625 1 1 0.1875 0 0 0 0 0.0625 1 1 0.375 0 0 0 0 0.0625 1 1 0.375 0 0 0 0 0 0.6875 1 0.625 0 0
'''

DATA_DIMEN = 64

def main():
    if len(sys.argv) != DATA_DIMEN + 3:
        print("Usage: %s <port> <baud_rate> [DATA, ... %d]" % (sys.argv[0], DATA_DIMEN))
        sys.exit(1)

    port = sys.argv[1]
    baudrate = int(sys.argv[2])

    bs = []
    digit = [float(x) for x in sys.argv[3:]]
    encoded = "".join(encode_digit(digit))

    print(encoded)
    for i in range(0, len(encoded), 2):
        h = encoded[i:i+2]
        b = int(h, 16)
        bs.append(b)

    with serial.Serial(port, baudrate, timeout=1, write_timeout=1) as s:
        s.write(bytes(bs))
        res = int.from_bytes(s.read(1), "little")
        print("Response: %d" % res)


def encode_digit(digit):
    assert(len(digit) == 64)
    words = []
    for i in range(0, len(digit), 4):
        b = ["%02x" % int(x * 255) for x in digit[i:i+4]]
        b.reverse()
        words.append("".join(b))
    return words

if __name__ == "__main__":
    main()
