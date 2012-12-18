#                              -*- Mode: GNUmakefile -*-
#  Filename        : makefile
#  Description     : Makefile for the kernel, which utilises the GPR.
#  Author          : Luke A. Guest
#  Created On      : Thu Jun 14 11:59:53 2012
#  Licence         : See LICENCE in the root directory.

###############################################################################
# These variables should be edited depending on the platform you are building
# for TAMP for.
###############################################################################
BOARD		=	pc
BITS		=	32
BUILD		=	debug
#BUILD		=	release

# The next option is for when there is a bug box and we need to build with
# extra options so we can file a bug.
#BUG		=	bug
BUG		=	clean

###############################################################################
# Everything after here should not be touched.
###############################################################################
PWD		=	$(shell pwd)

GNATMAKE	=	gnatmake
AS		=	as

###############################################################################
# Platform specific.
###############################################################################
ifeq ($(BOARD),pc)
ifeq ($(BITS),32)
ARCH		=	i386
AS_FLAGS	=	--32 -march=$(ARCH)
QEMU		=	qemu
else
ARCH		=	x86_64
AS_FLAGS	=	--64
QEMU		=	qemu-system-x86_64
endif
TOOL_PREFIX	=

AS_OBJS		=	obj/$(ARCH)/startup.o
ADA_OBJS	=	obj/multiboot.o

IMAGE		=	boot.iso
QEMU_FLAGS	=	-s -cdrom $(IMAGE)
QEMUD_FLAGS	=	-S $(QEMU_FLAGS)

OUTDIR		=	out/disk/boot/
else
ifeq ($(BOARD),rpi)
ARCH		=	arm
TOOL_PREFIX	=	arm-none-eabi-

AS_FLAGS	=	-march=armv6zk -mfpu=vfp -mfloat-abi=hard -marm \
			-mcpu=arm1176jzf-s -mtune=arm1176jzf-s
endif
endif

###############################################################################
# Force make not to try to build these objects as gnatmake and the project
# file does this for us.
###############################################################################
.PHONY: $(ADA_OBJS)

OBJS		=	$(AS_OBJS) $(ADA_OBJS)
RTS_DIR		=	$(PWD)/rts/boards/$(BOARD)/$(ARCH)

###############################################################################
# Debug specific flags.
###############################################################################
ifeq ($(BUILD),debug)
AS_FLAGS	+=	-g
else
ifeq ($(BUILD),release)
endif
endif

# The final output filename.
TARGET		=	$(OUTDIR)tamp-$(ARCH).elf

###############################################################################
# Rules.
###############################################################################
all: $(TARGET)

$(TARGET): prepare $(OBJS) src/tamp.adb
	$(TOOL_PREFIX)$(GNATMAKE) -p --RTS=$(RTS_DIR) \
		-XBoard=$(BOARD) -XBuild=$(BUILD) -XBug=$(BUG) \
		-XBits=$(BITS) -Ptamp.gpr

obj/$(ARCH)/startup.o: src/$(BOARD)/startup.s
	$(AS) $(AS_FLAGS) $< -o $@

# This will start qemu, but then stop the emulation, press ctrl+alt+shift+f2
# to get to the console, press c to continue once GDB has been configured. For
# more on QEMU's monitor, see http://en.wikibooks.org/wiki/QEMU/Monitor
#
# To debug using GDB:
# ./gdb-qemu.sh
qemud: $(IMAGE)
	$(QEMU) $(QEMUD_FLAGS)

qemu: $(IMAGE)
	$(QEMU) $(QEMU_FLAGS)

# The PC boot.iso image that qemu uses.
boot.iso: $(TARGET)
	grub-mkrescue -o boot.iso out/disk/

prepare:
	@mkdir -p obj/$(ARCH)

clean:
	@rm -rf obj
	-rm *~ $(TARGET)

.PHONY: clean prepare
