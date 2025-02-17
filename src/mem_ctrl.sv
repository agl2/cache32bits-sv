/************************************
*
*/
//`include "cache_structs_def.sv"
//=================================================
// Import the Packages
//=================================================
import cache_parameters::*;

module mem_ctrl 	
(
	input logic						rst,					// Reset Input
	input logic                  	clk, 				// Clock Input
	
	/// CACHE -> MEMORY
	input memory_request_t			mem_req,			// memory request
	
	/// CACHE <- MEMORY
	output memory_response_t		mem_res
);
		
	typedef enum {idle, mem_op, save_data} mem_ctrl_state_t;
	
	mem_ctrl_state_t state, next_state;
	
	
	logic [ADDR_WIDTH-1:0]addr;
	logic [WORD_WIDTH-1:0] data_in;
	logic wren;
	logic [WORD_WIDTH-1:0] data_out;
	logic [OFFSET_WIDTH:0] offset_count;
	ram ram1
	(
		.address(addr),
		.clock(clk),
		.data(data_in),
		.wren(wren),
		.q(data_out)
	);
	
	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			state <= idle;
		end
		else begin
			state <= next_state;
		end
	end
	
	
	always_ff @ (posedge clk or posedge rst) begin
		if(rst) begin
			offset_count <= 0;
		end
		else begin
			case(state)
				idle: begin
					offset_count <= 'b0;
				end			
				mem_op: begin

				end
				save_data: begin
					mem_res.data[offset_count] <= data_out;	
					offset_count <= offset_count + 1;		
				end
			endcase
		end
	end
	
	always @* begin
		case(state)
			idle: begin
				addr = 'b0;
				data_in = 'b0;
				wren = 'b0;
				mem_res.ack = 'b0;
				if(mem_req.cs == 1) begin
					next_state = mem_op;
				end
				else begin
					next_state = idle;
				end
			end
			mem_op: begin
				if(offset_count < BLOCK_SIZE) begin
					addr = (mem_req.addr + offset_count);
					data_in = mem_req.data[offset_count];
					wren = mem_req.rw;
					next_state = save_data;
				end
				else begin
					addr = 'b0;
					data_in = 'b0;
					wren = 'b0;
					mem_res.ack = 'b1;
					next_state = idle;
				end
			end
			save_data: begin
				next_state = mem_op;
			end
		endcase
	end
endmodule // End of Module ram_sp_sr_sws
