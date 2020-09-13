import argparse
import serial
import re

CMD_LOAD = 0x10
CMD_START = 0x20

ERR_SUCCESS = 1
ERR_CHECKSUM = 2

def main():
    arg_parser = argparse.ArgumentParser(description = 'LEG processor programmer')
    arg_parser.add_argument('in_file', metavar = 'file')
    arg_parser.add_argument('-b', '--block-size',
                        dest = 'block_size',
                        type = int,
                        default = None,
                        help = 'maximum block size to send at a time')
    arg_parser.add_argument('-p', '--port',
                        dest = 'port')
    arg_parser.add_argument('-r', '--baudrate',
                        dest = 'baudrate',
                        type = int)

    args = arg_parser.parse_args()

    rows = read_file(args.in_file)
    blocks = split_blocks(rows, args.block_size)

    with serial.Serial(args.port, args.baudrate, timeout=1, write_timeout=1) as s:
        for i, block in enumerate(blocks):
            send_block(s, block)
            print(f'sent {i+1}/{len(blocks)} blocks')

        send_start(s, blocks[0].start_addr)

def read_file(path):
    rows = []
    with open(path, 'r') as file:
        for line in file.readlines():
            m = re.match(r'^([a-zA-Z0-9]{1,8}):([a-zA-Z0-9]{8})$', line)
            if not m:
                raise Exception(f"Line '{line}' has wrong format")
            rows.append(map(lambda x: int(x, 16), [m[1], m[2]]))
    return rows

class Block:
    def __init__(self, addr):
        self.start_addr = addr
        self.current_addr = addr
        self.words = []

    def size(self):
        return self.current_addr - self.start_addr

    def add(self, addr, data):
        while(self.current_addr < addr):
            self.words.append(0)
            self.current_addr += 4
        self.words.append(data)
        self.current_addr += 4

    def checksum(self):
        acc = 0
        for word in self.words:
            acc ^= word
        return acc

def split_blocks(rows, block_size):
    blocks = []
    current_block = None

    for addr, data in rows:
        if current_block is None:
            current_block = Block(addr)
        if (block_size is not None and current_block.size() > block_size) or addr - current_block.current_addr >= 32:
            blocks.append(current_block)
            current_block = Block(addr)
        current_block.add(addr, data)

    if current_block is not None:
        blocks.append(current_block)

    return blocks

def send_block(serial, block):
    checksum = block.checksum()
    attempts = 0
    while True:
        serial.write(bytes([CMD_LOAD]))
        serial.write(int.to_bytes(block.size(), length=4, byteorder='little'))
        serial.write(int.to_bytes(block.start_addr, length=4, byteorder='little'))
        serial.write(int.to_bytes(checksum, length=4, byteorder='little'))
        for word in block.words:
            serial.write(int.to_bytes(word, length=4, byteorder='little'))

        res = int.from_bytes(serial.read(1), byteorder='little')
        print('res:', res)
        if res == ERR_SUCCESS:
            break
        elif res == ERR_CHECKSUM:
            print('Checksum error')
            attempts += 1
            if attempts < 4:
                print('retrying...')
            else:
                print('too many attempts, consider decreasing baudrate or block size')
                break
        else:
            raise Exception(f'Unknown error {res}')

def send_start(serial, addr):
    serial.write(bytes([CMD_START]))
    serial.write(int.to_bytes(addr, length=4, byteorder='little'))

if __name__ == "__main__":
    main()
