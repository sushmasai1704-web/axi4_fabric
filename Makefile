SIM     = sim/axi4_sim
VCD     = sim/axi4.vcd
SRCS    = rtl/axi4_master.sv rtl/axi4_slave.sv tb/axi4_assertions.v tb/tb_axi4.sv

all: $(SIM)

$(SIM): $(SRCS)
	iverilog -g2012 -o $(SIM) $(SRCS)

run: $(SIM)
	vvp $(SIM)

wave: $(VCD)
	dbus-run-session gtkwave $(VCD)

clean:
	rm -f $(SIM) $(VCD)
