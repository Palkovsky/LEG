all: rom.s
	../asm/asm.sh --rom rom.s | tee out

bootloader.s: bootloader.c
	clang -target riscv32--none- bootloader.c -S -O3 -o bootloader.s

boot.s: bootloader.s
	../asm/convert-asm.sh bootloader.s > boot.s

rom.s: boot.s prelude.s
	cat prelude.s boot.s > rom.s

clean:
	rm -f bootloader.s boot.s rom.s out
