`include "params.v"

module MASTER (
	input SYSCLK,
	input SYSRST,
	input PUSH_N, PUSH_S, PUSH_E, PUSH_W, PUSH_C,
	input [7:0] DIP,
	input UART_RX,
	output UART_TX,
	output LED_N, LED_S, LED_E, LED_W, LED_C,
	output [7:0] LEDS
);


wire uart_rx_valid;
wire uart_tx_ready;
wire uart_tx_valid;
wire [7:0] uart_rx_data;
wire [7:0] uart_tx_data;

UART UART_inst (
	.SCLK(SYSCLK),
	.RESET(~SYSRST),
	.RX(UART_RX),
	.RX_VALID(uart_rx_valid),
	.RX_DATA(uart_rx_data),
	.TX(UART_TX),
	.TX_READY(uart_tx_ready),
	.TX_VALID(uart_tx_valid),
	.TX_DATA(uart_tx_data)
);


wire shift_head;
wire shift_enable;

DECODER decoder_inst (
	.SCLK(SYSCLK),
	.RESET(~SYSRST),
	.UART_READY(uart_tx_ready),
	.RX_VALID(uart_rx_valid),
	.TX_VALID(uart_tx_valid),
	.RX_DATA(uart_rx_data),
	.TX_DATA(uart_tx_data),
	.SHIFT_HEAD(shift_head),
	.SHIFT_ENABLE(shift_enable)
);


wire user_click_clk;
wire user_reset;
wire user_clk_toggle;

TRANSITION user_click_clk_tran_inst(SYSCLK, ~SYSRST, PUSH_N, user_click_clk);
TRANSITION user_reset_tran_inst(SYSCLK, ~SYSRST, PUSH_C, user_reset);
TRANSITION user_clk_toggle_tran_inst(SYSCLK, ~SYSRST, PUSH_W, user_clk_toggle);

reg slow_clk;
reg [25:0] slow_clk_count;

always @ (posedge SYSCLK) begin
	if (slow_clk_count == 50000000) begin
		slow_clk <= ~slow_clk;
		slow_clk_count <= 0;
	end else begin
		slow_clk_count <= slow_clk_count + 1;
	end
end

reg user_clk_select;

always @ (posedge SYSCLK) begin
	if (~SYSRST)
		user_clk_select <= 0;
	else begin
		if (user_clk_toggle)
			user_clk_select <= ~user_clk_select;
	end
end


parameter NUM_IO = 2 * `IO_PER_CB * (`ROWS + `COLS);

wire [NUM_IO-1:0] overlay_inputs = DIP;
wire [NUM_IO-1:0] overlay_outputs;
assign LEDS = overlay_outputs;

OVERLAY overlay_inst (
	.PCLK			(SYSCLK),
	.PRST			(~SYSRST),
	.UCLK			(user_clk_select ? slow_clk : user_click_clk),
	.URST			(user_reset),
	.SE				(shift_enable),
	.SIN			(shift_head),
	.INPUTS			(overlay_inputs),
	.OUTPUTS		(overlay_outputs)
);


assign { LED_N, LED_W, LED_S, LED_E, LED_C } = { PUSH_N, PUSH_W, PUSH_S, PUSH_E, PUSH_C };


endmodule

