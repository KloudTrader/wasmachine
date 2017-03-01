#----------------------------------------
#-- Establecer nombre del componente
#----------------------------------------
SRC = src

NAME = wasmcpu
DEPS = $(SRC)/dividerp1.v $(SRC)/genrom.v $(SRC)/$(NAME).v

NAME2 = vacio1
DEPS2 = $(SRC)/$(NAME2).v


#-------------------------------------------------------
#-- Objetivo por defecto: hacer simulacion y sintesis
#-------------------------------------------------------
all: test sint


#----------------------------------------------
#-- Objetivo para hacer la simulacion del
#-- banco de pruebas
#----------------------------------------------
test: $(NAME)_tb.vcd

#-----------------------------------------------
#-  Objetivo para realizar la sintetis completa
#- y dejar el diseno listo para su grabacion en
#- la FPGA
#-----------------------------------------------
sint: $(NAME).bin


#-------------------------------
#-- Compilacion y simulacion
#-------------------------------
$(NAME)_tb.vcd: $(DEPS) test/$(NAME)_tb.v test/prog.list

	#-- Compilar
	iverilog -I $(SRC) $(DEPS) test/$(NAME)_tb.v -o $(NAME)_tb.out

	#-- Simular
	./$(NAME)_tb.out

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


test2: $(NAME2)_tb.vcd

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
$(NAME2)_tb.vcd: $(DEPS2) test/$(NAME2)_tb.v

	#-- Compilar
	iverilog -I $(SRC) $^ -o $(NAME2)_tb.out

	#-- Simular
	./$(NAME2)_tb.out

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
	rm -f *.bin *.txt *.blif *.out *.vcd *~

.PHONY: all clean
