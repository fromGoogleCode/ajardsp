mkdir -p build
ajardsp-asm -o=build/boot boot.asm
ajardsp-asm -o=build/vgapattern vgapattern.asm
wb_debug --load-imem:build/boot.imem:0xd0000000:0x100 --load-imem:build/vgapattern.imem:0xd0000100:0x400 --load-dmem:build/vgapattern.dmem:0xd0000500:0x100 --w32:0xc0000004:0x1
