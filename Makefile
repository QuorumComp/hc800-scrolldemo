LIBSTD = libs/stdlib/std.lib
LOWLEVEL = libs/lowlevel/lowlevel.lib
LIBS = $(LIBSTD) $(LOWLEVEL)
SRCS = core.asm demo.asm
ASMFLAGS = -g -el -z0 -ilibs
TARGET = demo

CLEAN = $(addsuffix .clean,$(dir $(LIBS)))

ASM = motorrc8
LIB = xlib
LINK = xlink

DEPDIR := .d
DEPFLAGS = -d$(DEPDIR)/$*.Td

ifeq ($(MAKE_HOST),Windows32)
$(shell mkdir $(DEPDIR) >NUL 2>&1)
POSTCOMPILE = @move /Y $(DEPDIR)\$*.Td $(DEPDIR)\$*.d >NUL && type NUL >>$@
REMOVEALL = del /S /Q $(TARGET) $(notdir $(SRCS:asm=obj)) $(DEPDIR) >NUL
else
$(shell mkdir -p $(DEPDIR) >/dev/null)
POSTCOMPILE = @mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@
REMOVEALL = rm -rf $(TARGET) $(notdir $(SRCS:asm=obj)) $(DEPDIR)
endif

ASSEMBLE = $(ASM) $(DEPFLAGS) $(ASMFLAGS)

$(TARGET) : $(notdir $(SRCS:asm=obj)) $(LIBS)
	$(LINK) -sEntry -m$@.sym -o$@ -thc8s $+

%.obj : %.asm
%.obj : %.asm $(DEPDIR)/%.d
	$(ASSEMBLE) -o$@ $<
	$(POSTCOMPILE)

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

clean : $(CLEAN)
	$(REMOVEALL)

%.clean:
	@$(MAKE) -C $* clean

# Make subdirs

SUBDIRS = $(dir $(LIBS))

subdirs: $(SUBDIRS)

.PHONY: subdirs $(SUBDIRS)

$(LIBS): subdirs

$(SUBDIRS):
	@$(MAKE) -C $(@D)

# Include dependency info

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(notdir $(SRCS)))))
