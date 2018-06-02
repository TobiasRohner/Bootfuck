

.PHONY: all
all: .assembly disassembly.txt


.PHONY: clean
clean:
	rm -f brainfuck_bootloader.img disassembly.txt .assembly brainfuck_bootloader.lst gdb_init_file



.assembly: brainfuck_bootloader.asm
	nasm -f bin -o brainfuck_bootloader.img -l brainfuck_bootloader.lst $<
	touch .assembly


.PHONY: brainfuck_bootloader.img
brainfuck_bootloader.img: .assembly


.PHONY: brainfuck_bootloader.lst
brainfuck_bootloader.lst: .assembly


disassembly.txt: brainfuck_bootloader.img
	objdump -D -b binary -m i8086 -M intel --adjust-vma=0x7c00 $< > $@


gdb_init_file: write_gdb_initfile.py brainfuck_bootloader.lst
	python3 $^ gdb_init_file


.PHONY: run
run: brainfuck_bootloader.img
	qemu-system-i386 $<


.PHONY: debug
debug: brainfuck_bootloader.img gdb_init_file
	qemu-system-i386 -fda $< -boot a -s -S & gnome-terminal -- gdb -x gdb_init_file
