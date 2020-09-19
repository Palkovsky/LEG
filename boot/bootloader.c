typedef unsigned char uint8_t;
typedef unsigned long uint32_t;
typedef volatile uint8_t* u8_addr_t;

#define true 1
#define false 0

#define UART_TX_MMIO ((u8_addr_t) 0xffffffff)
#define UART_RX_MMIO ((u8_addr_t) 0xfffffffe)
#define HEX_DISPLAY_BASE_MMIO ((u8_addr_t) 0xfffffff0)

#define HEX_DISPLAY_1 0
#define HEX_DISPLAY_2 1
#define HEX_DISPLAY_3 2

#define CMD_LOAD 0x10
#define CMD_START 0x20

#define ERR_SUCCESS 1
#define ERR_CHECKSUM 2

static void
cmd_load();

static void
cmd_start();

static inline void
write_byte(u8_addr_t addr, uint8_t b) {
  *addr = b;
}

static inline uint8_t
read_byte(u8_addr_t addr) {
  return *addr;
}

static uint8_t
read_uart() {
  return read_byte(UART_RX_MMIO);
}

static void
write_uart(uint8_t b) {
  write_byte(UART_TX_MMIO, b);
}

static uint32_t
read_word() {
  uint32_t res = 0;
  for(int i = 0; i < 4; i++) {
    res |= read_uart() << i * 8;
  }
  return res;
}

static void
hex_display(uint8_t display, uint8_t b) {
  if (display >= HEX_DISPLAY_1 && display <= HEX_DISPLAY_3) {
    write_byte(HEX_DISPLAY_BASE_MMIO + display, b);
  }
}

static void
hex_panel(uint8_t b1, uint8_t b2, uint8_t b3) {
  hex_display(HEX_DISPLAY_1, b1);
  hex_display(HEX_DISPLAY_2, b2);
  hex_display(HEX_DISPLAY_3, b3);
}

void
main() {
  hex_panel(0xBB, 0xBB, 0xBB);
  while(true) {
    uint8_t command = read_uart();
    switch (command) {
    case CMD_LOAD:
      hex_display(HEX_DISPLAY_2, 0);
      cmd_load();
      break;
    case CMD_START:
      hex_panel(0, 0, 0);
      cmd_start();
      break;
    default:
      ;
    }
  }
}

static void
cmd_load() {
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
  write_uart((checksum_acc == checksum) ?
             ERR_SUCCESS : ERR_CHECKSUM);
}

static void
cmd_start() {
  uint32_t ptr = read_word();
  ((void (*)(void)) ptr)();
}
