`include "params.v"

module EAST_BORDER (
	PCLK, SE,
	EAST_IO_IN, EAST_IO_OUT, WEST_CB_IN, WEST_CB_OUT,
	NORTH_BUS_IN, SOUTH_BUS_IN, WEST_BUS_IN,
	NORTH_BUS_OUT, SOUTH_BUS_OUT, WEST_BUS_OUT,
	CB_SIN, SB_SIN,
	CB_SOUT, SB_SOUT
);

input PCLK;
input [`IO_PER_CB-1:0] EAST_IO_IN;
input [`TRACKS-1:0] NORTH_BUS_IN, SOUTH_BUS_IN, WEST_BUS_IN;
output [`TRACKS-1:0] NORTH_BUS_OUT, SOUTH_BUS_OUT, WEST_BUS_OUT;
input [`BLE_PER_CLB/4-1:0] WEST_CB_IN;
output [`CLB_INPUTS/4-1:0] WEST_CB_OUT;
input SE, CB_SIN, SB_SIN;
output CB_SOUT, SB_SOUT;
output [`IO_PER_CB-1:0] EAST_IO_OUT;



// bus wires to connect SB and CB
wire [`TRACKS-1:0] bus_up, bus_down;

SWITCH_BLOCK sb_inst (
	.CLK (PCLK),
	.IN_N (bus_down),
	.IN_E (0),
	.IN_S (SOUTH_BUS_IN),
	.IN_W (WEST_BUS_IN),
	.OUT_N (bus_up),
	.OUT_E (), // not connected to anything
	.OUT_S (SOUTH_BUS_OUT),
	.OUT_W (WEST_BUS_OUT),
	.SE (SE),
	.SIN (SB_SIN),
	.SOUT (SB_SOUT)
);


CONNECTION_BLOCK cb_inst (
	.CLK (PCLK),
	.LB1_IN (WEST_CB_IN),
	.LB2_IN (EAST_IO_IN),
	.SB1_IN (NORTH_BUS_IN),
	.SB2_IN (bus_up),
	.LB1_OUT (WEST_CB_OUT),
	.LB2_OUT (EAST_IO_OUT),
	.SB1_OUT (NORTH_BUS_OUT),
	.SB2_OUT (bus_down),
	.SE (SE),
	.SIN (CB_SIN),
	.SOUT (CB_SOUT)
);


endmodule

