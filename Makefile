SRC   = src
BUILD = build

NAME = wasmachine
DEPS = $(SRC)/dividerp1.v $(SRC)/genrom.v $(SRC)/$(NAME).v

IVERILOG = iverilog -I $(SRC) -y $(SRC) -y vendor/LEB128
VVP      = vvp -N


all: test $(NAME).bin


clean:
	rm -rf *.bin *.txt *.blif $(BUILD) *~

update-dependencies:
	git submodule update --remote


.PHONY: all clean update-dependencies


#
# General test objectives
#
test       : test/stack test/genrom test/cpu
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


# cpu
test/cpu: test/cpu/parametric_operators test/cpu/constants \
					test/cpu/comparison_operators

test/cpu/parametric_operators: test/cpu/drop test/cpu/select
test/cpu/drop   : $(BUILD)/cpu/drop_tb.vcd
test/cpu/select : test/cpu/select1 test/cpu/select2 test/cpu/select3
test/cpu/select1: $(BUILD)/cpu/select1_tb.vcd
test/cpu/select2: $(BUILD)/cpu/select2_tb.vcd
test/cpu/select3: $(BUILD)/cpu/select3_tb.vcd

test/cpu/constants: test/cpu/f32.const test/cpu/f64.const test/cpu/i32.const \
	                  test/cpu/i64.const
test/cpu/f32.const: $(BUILD)/cpu/f32.const_tb.vcd
test/cpu/f64.const: $(BUILD)/cpu/f64.const_tb.vcd
test/cpu/i32.const: $(BUILD)/cpu/i32.const_tb.vcd
test/cpu/i64.const: $(BUILD)/cpu/i64.const_tb.vcd

test/cpu/comparison_operators: test/cpu/i32.eqz test/cpu/i64.eqz
test/cpu/i32.eqz : test/cpu/i32.eqz1 test/cpu/i32.eqz2
test/cpu/i32.eqz1: $(BUILD)/cpu/i32.eqz1_tb.vcd
test/cpu/i32.eqz2: $(BUILD)/cpu/i32.eqz2_tb.vcd
test/cpu/i64.eqz : test/cpu/i64.eqz1 test/cpu/i64.eqz2
test/cpu/i64.eqz1: $(BUILD)/cpu/i64.eqz1_tb.vcd
test/cpu/i64.eqz2: $(BUILD)/cpu/i64.eqz2_tb.vcd

test/cpu/reinterpretations: test/cpu/i32.reinterpret-f32 \
														test/cpu/f32.reinterpret-i32 \
														test/cpu/f64.reinterpret-i64
test/cpu/i32.reinterpret-f32: $(BUILD)/cpu/i32.reinterpret-f32_tb.vcd
test/cpu/f32.reinterpret-i32: $(BUILD)/cpu/f32.reinterpret-i32_tb.vcd
test/cpu/f64.reinterpret-i64: $(BUILD)/cpu/f64.reinterpret-i64_tb.vcd


$(BUILD)/cpu/%_tb.vcd: $(BUILD)/cpu/%_tb $(BUILD)/cpu/%.hex
	(cd $(BUILD)/cpu && $(VVP) ../../$<) || (rm $< && exit 1)

$(BUILD)/cpu/%.hex:
	mkdir -p $(@D)
	cp test/cpu/$(@F) $(BUILD)/cpu

$(BUILD)/cpu/%_tb: $(SRC)/cpu.v test/assert.vh test/cpu/%_tb.v
	mkdir -p $(@D)
	$(IVERILOG) -I test test/cpu/$(@F).v -o $@

view/cpu/%: test/cpu/%
	gtkwave $(BUILD)/cpu/$(@F)_tb.vcd test/cpu/cpu_tb.gtkw


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
