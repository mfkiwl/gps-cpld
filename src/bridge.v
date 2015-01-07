`timescale 1ns / 1ps

module bridge(
		input GPS_I0,
		input GPS_I1,
		input GPS_Q0,
		input GPS_Q1,
		input GPS_CLK_16_368,
		input MCU_CLK_25_000,
		input RESET_N,
		output MCU_SCK,
		output MCU_SS,
		output MCU_MOSI);

wire datardy;

wire gps_i0_sync;
wire gps_i1_sync;
wire gps_q0_sync;
wire gps_q1_sync;

wire GPS_CLK_4_092;
reg  GPS_DIV4_EDGE;
wire GPS_DIV4_EDGE_INV;

reg   gps_i0_sync_reg;
reg   gps_i1_sync_reg;
reg   gps_q0_sync_reg;
reg   gps_q1_sync_reg;

// Instantiate bridge state machine here
bridge_sm bridge_sm_inst (
.GPS_I0(gps_i0_sync_reg),
.GPS_I1(gps_i1_sync_reg),
.GPS_Q0(gps_q0_sync_reg),
.GPS_Q1(gps_q1_sync_reg),
.MCU_CLK_25_000(MCU_CLK_25_000),
.RESET_N(RESET_N),
.DATAREADY(datardy),
.MCU_SCK(MCU_SCK),
.MCU_SS(MCU_SS),
.MCU_MOSI(MCU_MOSI)
);

// A divided clock can
//   only drive the clock input of registers.
always @(posedge GPS_CLK_4_092 or negedge GPS_CLK_4_092 or negedge RESET_N)
      if (!RESET_N) begin
         GPS_DIV4_EDGE <= 1'b0;
      end else begin
         GPS_DIV4_EDGE <= ~GPS_DIV4_EDGE;
      end

// Instantiate a T FF and negate the output to match the clock
// Reset will be tricky...This will also add a 1 clock phase delay.
						
// Instantiate edge detection here
asynch_edge_detect asynch_edge_detect_inst(
		.SYNC_CLK_IN(MCU_CLK_25_000),
		.ASYNC_IN(GPS_DIV4_EDGE),
		.DETECT_OUT(datardy)
);

// Need to match the phase of data due to the can't 
//    use divided clock as an combinational input thing..
always@(posedge MCU_CLK_25_000) begin
   gps_i0_sync_reg <= gps_i0_sync;
   gps_i1_sync_reg <= gps_i1_sync;
   gps_q0_sync_reg <= gps_q1_sync;
   gps_q1_sync_reg <= gps_q1_sync;
end

synchronizer synch_inst_q1 (
	.asynch_input(GPS_Q1),
	.synch_clk(MCU_CLK_25_000),
	.synch_output(gps_q1_sync)
);

synchronizer synch_inst_i0 (
	.asynch_input(GPS_I0),
	.synch_clk(MCU_CLK_25_000),
	.synch_output(gps_i0_sync)
);
	
synchronizer synch_inst_i1 (
	.asynch_input(GPS_I1),
	.synch_clk(MCU_CLK_25_000),
	.synch_output(gps_i1_sync)
);

synchronizer synch_inst_q0 (
	.asynch_input(GPS_Q0),
	.synch_clk(MCU_CLK_25_000),
	.synch_output(gps_q0_sync)
);


// CLK_DIV4: Simple clock Divide by 4  CoolRunner-II
//    Xilinx HDL Language Template, version 14.7
CLK_DIV4 CLK_DIV4_inst (
		.CLKDV(GPS_CLK_4_092),    // Divided clock output
		.CLKIN(GPS_CLK_16_368)     // Clock input
);
// End of CLK_DIV4_inst instantiation


endmodule
