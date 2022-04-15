# Name of the target
TARGET=executable

# Put all the output in a separate directory
BUILD_DIR=build
BUILD_TARGET=$(BUILD_DIR)/$(TARGET)
BUILD_IMAGE=$(BUILD_DIR)/flash.bin

# Gather all assembly source files ending in .s
# TODO: If you have multiple files that should not be compiled together, use the line below instead:
SOURCES=aufgabe3.s
# SOURCES=$(wildcard *.s)
OBJECTS=$(patsubst %.s,$(BUILD_DIR)/%.o,$(SOURCES))

# The toolchain to use for building
ASSEMBLER=arm-none-eabi-as
LINKER=arm-none-eabi-ld
OBJCOPY=arm-none-eabi-objcopy

# Emulation toolchain, settings and debugger
EMULATOR=qemu-system-arm
SERIAL=/dev/null
GDB=gdb-multiarch

# Some make related stuff to ignore those names when searching fpor targets
.PHONY: all clean init image run

# Applications builds and starts GDB
all: build run

# Only build the image
build: init image

# Create build directory
init:
	mkdir -p $(BUILD_DIR)

# Create the image
# 1. First, link the object files together and create an ELF executable
# 2. Create a binary output file because we do not have an OS which can parse and execute ELF files
# 3. Create an image file for QEMU (this is our memory)
# 4. Flash our program onto this memory
image: $(OBJECTS)
	$(LINKER) -Ttext=0x0 -o $(BUILD_TARGET).elf $(OBJECTS)
	$(OBJCOPY) -O binary $(BUILD_TARGET).elf $(BUILD_TARGET).bin
	dd if=/dev/zero of=$(BUILD_IMAGE) bs=4096 count=4096
	dd if=$(BUILD_TARGET).bin of=$(BUILD_IMAGE) bs=4096 conv=notrunc

# Target rule for all object files
# Compile all the source files into object files with additional debugging information
$(OBJECTS): $(SOURCES)
	$(ASSEMBLER) -o $@ $< -ggdb

# Launch QEMU (useful if you want to attach from VS Code or something...)
qemu:
	$(EMULATOR) -M connex -drive file=$(BUILD_IMAGE),if=pflash,format=raw -nographic -serial $(SERIAL) -S -gdb tcp:localhost:1234

# Runs QEMU and executes GDB
# 1. Start emulator as a background process
# 2. Connect with GDB
# 3. Cleanup after debugging finished
run:
	$(EMULATOR) -M connex -drive file=$(BUILD_IMAGE),if=pflash,format=raw -nographic -serial $(SERIAL) -S -gdb tcp:localhost:1234 &
	$(GDB) $(BUILD_TARGET).elf -ex "target remote localhost:1234"
	killall $(EMULATOR)

# Remove all artifacts for a fresh build
clean:
	rm -rf $(BUILD_DIR)

