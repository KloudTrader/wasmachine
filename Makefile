#----------------------------------------
#-- Establecer nombre del componente
#----------------------------------------
SRC   = src
BUILD = build

NAME = wasmcpu
DEPS = $(SRC)/dividerp1.v $(SRC)/genrom.v $(SRC)/$(NAME).v

NAME2 = vacio1
DEPS2 = $(SRC)/$(NAME2).v

IVERILOG = iverilog -I $(SRC)
VVP      = vvp -N



#-------------------------------------------------------
#-- Objetivo por defecto: hacer simulacion y sintesis
#-------------------------------------------------------
all: $(BUILD) test sint


#
# Auxiliar objectives
#
$(BUILD):
	mkdir -p $(BUILD)


#----------------------------------------------
#-- Objetivo para hacer la simulacion del
#-- banco de pruebas
#----------------------------------------------
test: $(BUILD)/$(NAME)_tb.vcd

#-----------------------------------------------
#-  Objetivo para realizar la sintetis completa
#- y dejar el diseno listo para su grabacion en
#- la FPGA
#-----------------------------------------------
sint: $(NAME).bin


test-stack: $(BUILD) $(BUILD)/stack_tb.vcd

$(BUILD)/stack_tb.vcd: $(BUILD)/stack_tb
	(cd $(BUILD) && $(VVP) stack_tb) || (rm $(BUILD)/stack_tb && exit 1)

$(BUILD)/stack_tb: test/assert.vh test/stack_tb.v $(SRC)/stack.v
	$(IVERILOG) -I test test/stack_tb.v $(SRC)/stack.v -o $(BUILD)/stack_tb

view-stack: test-stack
	gtkwave $(BUILD)/stack_tb.vcd test/stack_tb.gtkw



#-------------------------------
#-- Compilacion y simulacion
#-------------------------------
$(BUILD)/$(NAME)_tb.vcd: $(DEPS) test/$(NAME)_tb.v test/prog.list

	#-- Compilar
	$(IVERILOG) $(DEPS) test/$(NAME)_tb.v -o $(BUILD)/$(NAME)_tb

	#-- Simular
	cp test/prog.list $(BUILD)
	(cd $(BUILD) && $(VVP) $(NAME)_tb)

	#-- Ver visualmente la simulacion con gtkwave
	gtkwave $@ test/$(NAME)_tb.gtkw &

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


test2: $(BUILD)/$(NAME2)_tb.vcd

#-----------------------------------------------
#-  make sint
#-----------------------------------------------
#-  Objetivo para realizar la sintetis completa
#- y dejar el diseno listo para su grabacion en
#- la FPGA
#-----------------------------------------------
sint2: $(NAME2).bin


#-------------------------------
#-- Compilacion y simulacion
#-------------------------------
$(BUILD)/$(NAME2)_tb.vcd: $(DEPS2) test/$(NAME2)_tb.v

	#-- Compilar
	$(IVERILOG) $^ -o $(BUILD)/$(NAME2)_tb

	#-- Simular
	cp test/prog.list $(BUILD)
	(cd $(BUILD) && $(VVP) $(NAME2)_tb)

	#-- Ver visualmente la simulacion con gtkwave
	gtkwave $@ $(NAME2)_tb.gtkw &

#------------------------------
#-- Sintesis completa
#------------------------------
$(NAME2).bin: resources/$(NAME2).pcf $(DEPS2)

	#-- Sintesis
	yosys -p "synth_ice40 -blif $(NAME2).blif" $(DEPS2)

	#-- Place & route
	arachne-pnr -d 1k -p resources/$(NAME2).pcf $(NAME2).blif -o $(NAME2).txt

	#-- Generar binario final, listo para descargar en fgpa
	icepack $(NAME2).txt $(NAME2).bin


#-- Limpiar todo
clean:
	rm -rf *.bin *.txt *.blif $(BUILD) *~

.PHONY: all clean
