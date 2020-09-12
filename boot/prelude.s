# initialize the stack and jump to main bootloader function

# li sp, 0x1000
lui sp, 0x1

jal main

halt: # infinite loop in case main returns
j halt

# --- END OF PRELUDE ---
