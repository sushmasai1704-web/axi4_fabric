SIM = sim/axi4_sim
VCD = sim/axi4.vcd

all: $(SIM)

$(SIM): rtl/axi4_master.v rtl/axi4_slave.v tb/tb_axi4.v
	iverilog -o $(SIM) rtl/axi4_master.v rtl/axi4_slave.v tb/tb_axi4.v

run: $(SIM)
	vvp $(SIM)

wave: $(VCD)
	gtkwave $(VCD)

clean:
	rm -f $(SIM) $(VCD)
