SRC   = src
BUILD = build

NAME = wasmachine
DEPS = $(SRC)/dividerp1.v $(SRC)/genrom.v $(SRC)/$(NAME).v

IVERILOG = iverilog -I $(SRC) -y $(SRC)
VVP      = vvp -N


all: test $(NAME).bin


#
# General test objectives
#
test       : test/stack test/genrom
test/genrom: $(BUILD)/genrom_tb.vcd
test/stack : $(BUILD)/stack_tb.vcd
test/%     : $(BUILD)/%_tb.vcd

$(BUILD)/%_tb.vcd: $(BUILD)/%_tb
	(cd $(BUILD) && $(VVP) ../$<) || (rm $< && exit 1)

$(BUILD)/%_tb: $(SRC)/%.v test/assert.vh test/%_tb.v
	mkdir -p $(@D)
	$(IVERILOG) -I test test/$(@F).v -o $@

view/%: test/%
	gtkwave $(BUILD)/$(@F)_tb.vcd test/$(@F)_tb.gtkw








# genrom
$(BUILD)/genrom_tb.vcd: $(BUILD)/genrom_tb
	cp test/genrom.hex $(BUILD)
	(cd $(BUILD) && $(VVP) ../$<) || (rm $< && exit 1)


#------------------------------
#-- Sintesis completa
#------------------------------
$(NAME).bin: resources/$(NAME).pcf $(DEPS) test/prog.list

	#-- Sintesis
	yosys -p "synth_ice40 -blif $(NAME).blif" $(DEPS)

	#-- Place & route
	arachne-pnr -d 1k -p resources/$(NAME).pcf $(NAME).blif -o $(NAME).txt

	#-- Generar binario final, listo para descargar en fgpa
	icepack $(NAME).txt $(NAME).bin


#-- Limpiar todo
clean:
	rm -rf *.bin *.txt *.blif $(BUILD) *~

.PHONY: all clean
