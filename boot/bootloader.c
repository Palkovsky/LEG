/* #include <stdbool> */
// #include <stdint>

typedef unsigned char uint8_t;
typedef unsigned long uint32_t;

#define true 1
#define false 0

#define UART_TX_MMIO ((volatile uint8_t*) 0xffffffff)
#define UART_RX_MMIO ((volatile uint8_t*) 0xfffffffe)

#define CMD_LOAD 0x10
#define CMD_START 0x20

#define ERR_SUCCESS 1
#define ERR_CHECKSUM 2

static void cmd_load();
static void cmd_start();

static uint8_t read_byte() {
  return *UART_RX_MMIO;
}

static void write_byte(uint8_t b) {
  *UART_TX_MMIO = b;
}

static uint32_t read_word() {
  uint32_t res = 0;
  for(int i = 0; i < 4; i++) {
    res |= read_byte() << i * 8;
  }
  return res;
}

void main() {
  while(true) {
    uint8_t command = read_byte();
    switch (command) {
    case CMD_LOAD:
      cmd_load();
      break;
    case CMD_START:
      cmd_start();
      break;
    default:
      ;
      // do nothing
    }
  }
}

static void cmd_load() {
  uint32_t size = read_word();
  uint32_t* ptr = (uint32_t*) read_word();
  uint32_t checksum = read_word();
  uint32_t checksum_acc = 0;
  for(uint32_t i = 0; i < size; i++) {
    uint32_t word = read_word();
    checksum_acc ^= word;
    *ptr = word;
    ptr++;
  }
  if (checksum_acc != checksum) {
    write_byte(ERR_CHECKSUM);
  } else {
    write_byte(ERR_SUCCESS);
  }
}

static void cmd_start() {
  uint32_t ptr = read_word();
  ((void (*)(void)) ptr)();
}
