# Template makefile for stm32 ARM devices

TARGET 		:= program


# Find all resources: c-files, header files, asm-files, linker script
RESOURCES := $(shell find . -name "*.c" -o -name "*.h" -o -name "*.ld" -o -name "*.s")
#RESOURCES := $(shell find .  -name "*.h" -o -name "*.ld")
#RESOURCES += C_SOURCES

# Resource directories
SRCDIR 		:= $(sort $(dir $(filter %.c,$(RESOURCES))))
INCDIR 		:= $(addprefix -I,$(sort $(dir $(filter %.h,$(RESOURCES)))))
ASMDIR 		:= $(sort $(dir $(filter %.s,$(RESOURCES))))
OBJDIR		:= ./obj
DEPDIR 		:= ./deps

$(shell mkdir -p $(DEPDIR) >/dev/null)
$(shell mkdir -p $(OBJDIR) >/dev/null)

# Resources
SRCS 			:= $(notdir $(filter %.c,$(RESOURCES)))
ASMS 			:= $(notdir $(filter %.s,${RESOURCES}))
LDSCRIPT	:= $(filter %.ld,${RESOURCES})
OBJS 			:= $(patsubst %.c,%.o,$(SRCS))
OBJS 			+= $(patsubst %.s,%.o,$(ASMS))
OBJS 			:= $(addprefix $(OBJDIR)/,$(OBJS))

# Path where make should look for c-files and asm-files
vpath %.c $(SRCDIR)
vpath %.s $(ASMDIR)

CC 	:= gcc
LD 	:= ld
AS 	:= gcc -x assembler-with-cpp
SZ 	:= size -x
HEX := objcopy -Oihex
BIN := objcopy -Obinary -S

# Compiler options
CFLAGS 			+= #-Wall -std=gnu11 -O0 -g3 -fdata-sections -ffunction-sections
CPPFLAGS 		+= #$(INCDIR) -DSTM32F407xx -DUSE_HAL_DRIVER -static -specs=nano.specs -specs=nosys.specs -D__weak=__attribute__\(\(weak\)\) -D__packed=__attribute__\(\(__packed__\)\) 
TARGET_ARCH += #-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16

# Assembler options
ASFLAGS			+=# $(CFLAGS) #-Wa,--no-warn 
TARGET_MACH += #-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16

# Linker options
LOADLIBES +=
LDLIBS 		+=
LDFLAGS 	+= #-T$(LDSCRIPT) -mthumb -mcpu=cortex-m4 -Wl,--gc-section -mfloat-abi=hard -mfpu=fpv4-sp-d16 -Wl,-Map=$(OBJDIR)/mapfile.map

# Dependencies options
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td

# Updated built-in compilation macro including dependency generation
COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE.s = $(AS) $(DEPFLAGS) $(ASFLAGS) $(TARGET_MACH) -c

POSTCOMPILE = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d #&& touch $@

# Default goals: elf, hex and bin
all: $(OBJDIR)/$(TARGET).elf 

# program.elf goal
$(OBJDIR)/$(TARGET).elf: $(OBJS) | Makefile 
	@echo Generating: $(notdir $@)...
	$(LINK.o) $(CPPFLAGS) $^ -o $@
	$(SZ) $@
	@echo



# Redefine defaults to generate dependencies
%.o: %.c
%.o: %.c $(DEPDIR)/%.d
	@echo Default compile
	$(COMPILE.c) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)

# Goals for object files based on c-files with dependencies on headers
$(OBJDIR)/%.o: %.c $(DEPDIR)/%.d
	@echo here SRCDIR: $(SRCDIR)...
	@echo here SRCS: $(SRCS)...
	@echo here OBJS: $(OBJS)...
	@echo $(patsubst %,$(DEPDIR)/%.d,$(basename $(SOURCES)))
	@echo Compiling: $(notdir $@)...
	$(COMPILE.c) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)
	$(SZ) $@
	@echo

main.c: main.h
        

# Goals for object files based on asm-files
$(OBJDIR)/%.o: %.s
	@echo Assembling: $(notdir $@)...
	$(COMPILE.s) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)
	$(SZ) $@
	@echo

# Include dependencies for *.o goals
-include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(SOURCES))))

# Guarantee that *.o files will be generated even when %.d files were not yet created
$(DEPDIR)/%.d: ;

# Guarantee that *.d files won't be deleted after finished build process
.PRECIOUS: $(DEPDIR)/%.d

.PHONY: clean
clean:
	@echo Cleaning object  directory...
	@rm -rf $(OBJDIR) $(DEPDIR)

