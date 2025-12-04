//
module top_i2s_rx_module #(
	parameter	FRAME_RES	= 32,
			DATA_RES	= 24
)(	input	logic			bck_i, lrck_i, dat_i,
	output	logic	[DATA_RES-1:0]	left_o, right_o
);
	
	localparam LOG2_FRAME_RES = $clog2(FRAME_RES);

	logic				wsd, wsn, wsp;
	logic [DATA_RES-1:0]		data;
	logic [FRAME_RES-1:0]		en_data;
	logic [LOG2_FRAME_RES-1:0]	cnt;

	i2s_cntr_module #(
		.CNT_RES	( LOG2_FRAME_RES	)
	) cntr (
		.rst_i		( wsp			),
		.clk_i		(~bck_i			),
		.en_i		(~en_data[FRAME_RES-1]	),
		.cnt_o		( cnt			)
	);
	
	i2s_decoder_module #(
		.INPUT_WIDTH	( LOG2_FRAME_RES	),
		.OUTPUT_WIDTH	( FRAME_RES		)
	) decoder (
		.d_i		( cnt			),
		.d_o		( en_data		)
	);
	
	genvar i;
	generate
		for(i = 0; i < DATA_RES-1; i++) begin: forgen
			i2s_full_sync_dff_module dreg (
				.d_i	( dat_i			),
				.rst_i	( wsp			),
				.en_i	( en_data[DATA_RES-1-i]	),
				.clk_i	( bck_i			),
				.q_o	( data[i]		)
			);
		end: forgen
	endgenerate

	assign wsp = wsd ^ wsn;

	always_ff @(posedge bck_i) begin
		wsd <= lrck_i;
		wsn <= wsd;
		if(en_data[0])
			data[DATA_RES-1] <= dat_i;
		if(wsp & ~wsd)
			right_o	<= data;
		if(wsp & wsd)
			left_o	<= data;
	end

endmodule: top_i2s_rx_module

// center module
module i2s_cntr_module 
	#(parameter CNT_RES = 5)
	(input	logic			rst_i, clk_i, en_i,
	 output	logic	[CNT_RES-1:0]	cnt_o);
	
	always_ff @(posedge clk_i) begin
		if(rst_i)
			cnt_o <= 0;
		else if(en_i)
			cnt_o <= cnt_o + 1'b1;
	end
	
endmodule: i2s_cntr_module

// decoder
module i2s_decoder_module #(
	parameter	INPUT_WIDTH	= 5,
			OUTPUT_WIDTH	= 32
)(	
	input	[INPUT_WIDTH-1:0]	d_i,
	output	[OUTPUT_WIDTH-1:0]	d_o
);
	
	assign d_o = 1'b1 << d_i;
	
endmodule: i2s_decoder_module

// full_sync
module i2s_full_sync_dff_module
(
	input	logic d_i, rst_i, en_i, clk_i,
	output	logic q_o		
);
	
	always_ff @(posedge clk_i) begin
		if(rst_i)
			q_o <= 0;
		else if(en_i)
			q_o <= d_i;
	end
	
endmodule: i2s_full_sync_dff_module
