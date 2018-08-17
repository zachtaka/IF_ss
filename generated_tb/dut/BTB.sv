/*
* @info Brach Target Buffer
* @info Top Modules: Predictor.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief A target predictor, addressable with the PC address, for use in dynamic predictors
*
* @note The SRAM Stores in each entry: [OriginatingPC/TargetPC]
*
* @param PC_BITS       : # of PC Address Bits
* @param SEL_BITS      : # of Selector bits used from PC
* @param SIZE          : # of addressable entries (lines) in the array
*/
module BTB #(PC_BITS=32,SIZE=1024) (
    input  logic               clk       ,
    input  logic               rst_n     ,
    //Update Interface
    input  logic               Wr_En     ,
    input  logic [PC_BITS-1:0] Orig_PC   ,
    input  logic [PC_BITS-1:0] Target_PC ,
    //Invalidation Interface
    input  logic               invalidate,
    input  logic [PC_BITS-1:0] pc_invalid,
    //Access Interface
    input  logic [PC_BITS-1:0] PC_in_a   ,
    input  logic [PC_BITS-1:0] PC_in_b   ,
    //Output Ports
    output logic               Hit_a     ,
    output logic [PC_BITS-1:0] next_PC_a ,
    output logic               Hit_b     ,
    output logic [PC_BITS-1:0] next_PC_b
);
    localparam SEL_BITS = $clog2(SIZE);
	// #Internal Signals#
    logic [1:0][ 2*PC_BITS-1:0] data_out;
    logic [1:0][SEL_BITS-1:0]   read_addresses;
    logic [SEL_BITS-1 : 0]      line_selector_a, line_selector_b, line_write_selector, line_inv_selector;
    logic [ 2*PC_BITS-1:0]      retrieved_data_a, retrieved_data_b, new_data;
    logic [      SIZE-1:0]      Validity        ;
    logic                       masked_wr_en    ;

    localparam int BTB_SIZE = SIZE*2*PC_BITS + $bits(Validity); //dummy for debugging
	//create the line selector from the PC_in_a bits k-2
    assign line_selector_a = PC_in_a[SEL_BITS : 1];
    assign line_selector_b = PC_in_b[SEL_BITS : 1];
    //Create the line selector for the write operation
    assign line_write_selector = Orig_PC[SEL_BITS : 1];
	//Create the new Data to be stored ([Orig_PC/Target_PC])
	assign new_data            = { Orig_PC,Target_PC };	
	//Create the Invalidation line selector
	assign line_inv_selector   = pc_invalid[SEL_BITS : 1];

    assign read_addresses[0] = line_selector_a;
    assign read_addresses[1] = line_selector_b;
    SRAM #(.SIZE        (SIZE),
           .DATA_WIDTH  (2*PC_BITS),
           .RD_PORTS    (2),
           .WR_PORTS    (1),
           .RESETABLE   (0))
    SRAM (.clk                 (clk),
          .rst_n               (rst_n),
          .Wr_En               (Wr_En),
          .read_address        (read_addresses),
          .data_out            (data_out),
          .write_address       (line_write_selector),
          .new_data            (new_data));

    //always output the target PC
    assign retrieved_data_a = data_out[0];
    assign retrieved_data_b = data_out[1];
    assign next_PC_a        = retrieved_data_a[0 +: PC_BITS];
    assign next_PC_b        = retrieved_data_b[0 +: PC_BITS];

	always_comb begin : HitOutputA		
		//Calculate Hit_a signal										
		if (retrieved_data_a[PC_BITS +: PC_BITS]==PC_in_a) begin								
			Hit_a = Validity[line_selector_a];
		end else begin
			Hit_a = 0;
		end
	end
    always_comb begin : HitOutputB       
        //Calculate Hit_a signal                                        
        if (retrieved_data_b[PC_BITS +: PC_BITS]==PC_in_b) begin                                
            Hit_b = Validity[line_selector_b];
        end else begin
            Hit_b = 0;
        end
    end

    assign masked_wr_en = invalidate ? Wr_En & (line_inv_selector!=line_write_selector) : Wr_En;
	always_ff @(posedge clk or negedge rst_n) begin : ValidityBits
		if(!rst_n) begin
			 Validity[SIZE-1:0] <= 'd0;
		end else begin
			 if(invalidate) begin
			 	Validity[line_inv_selector] <= 0;
			 end
             if(masked_wr_en) begin
			 	Validity[line_write_selector] <= 1;
			 end
		end
	end

endmodule