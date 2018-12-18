module ft232h
(
	input          ft_clk,
	input          rst,
	input          key,
	input          ft_rxf_n,  
	input          ft_txe_n,  
	output         ft_oe_n,
	output reg     ft_rd_n,
	output         ft_wr_n,
	inout[7:0]     ft_data,
	output reg [7:0]  r_data
);
localparam IDLE   = 0;
localparam READ   = 1;
localparam WRITE  = 2;
localparam WAIT   = 3;

reg[3:0]           state;
reg                buf_wr;
reg[7:0]           buf_data;
wire[7:0]          ft_data_out;

reg               ft_oe_n_d0;
assign ft_oe_n = (state == READ) ? 1'b0 : 1'b1;
assign ft_data = (ft_oe_n == 1'b0) ? 8'hzz : ft_data_out;
assign ft_wr_n = (state == WRITE && ft_txe_n == 1'b0 ) ? 1'b0 : 1'b1;
assign buf_rd =  (state == WRITE && ft_txe_n == 1'b0 ) ? 1'b1 : 1'b0;

//

always@(posedge ft_clk ) begin
if (rst == 1'b1) 
      r_data <= 8'd0;
if (buf_wr ) 
      r_data <= buf_data;
end
//
always@(posedge ft_clk or posedge rst)
begin
	if(rst == 1'b1)
		ft_oe_n_d0 <= 1'b0;
	else 
		ft_oe_n_d0 <= ft_oe_n;
end
//
always@(posedge ft_clk or posedge rst)
begin
	if(rst == 1'b1)
		buf_wr <= 1'b0;
	else if(state == READ)
		buf_wr <= ~ft_oe_n_d0 & ~ft_rxf_n;
	else
		buf_wr <= 1'b0;
end

always@(posedge ft_clk or posedge rst)
begin
	if(rst == 1'b1)
		buf_data <= 8'd0;
	else if(state == READ)
		buf_data <= ft_data;
end

always@(posedge ft_clk or posedge rst)
begin
	if(rst == 1'b1)
		ft_rd_n <= 1'b1;
	else if(ft_rxf_n == 1'b1)
		ft_rd_n <= 1'b1;
	else if(state == READ)
		ft_rd_n <= 1'b0;
		
end

reg [11:0]txcounter;
assign ft_data_out = txcounter[7:0];
always@(posedge ft_clk or posedge rst)
begin
	if(rst == 1'b1)
	begin
		state <= IDLE;
	end
	else
		case(state)
			IDLE:
			begin
			   if(ft_rxf_n == 1'b0)
				begin
				   state <= READ;
				end
				else if(ft_txe_n == 1'b0 && key)
				begin
					txcounter <= 12'h0;
					state <= WRITE;
				end
			end
			READ: begin
				if(ft_rxf_n == 1'b1)
				begin
				   state <= IDLE;
				end
			end
			WRITE:
			begin
				if(ft_txe_n == 1'b1 ) 
				begin
					state <= WAIT;
				end
				else begin
				  if (txcounter == 12'hfff ) begin
						state <= IDLE;
					end 
					else begin
				      txcounter <= txcounter + 12'b1;
					end
				end
			end
			WAIT: 
			begin
			   if (ft_txe_n == 1'b0 ) // transmitter buffer free again
				begin
				   state <= WRITE;
			   end		
			end
			default:
				state <= IDLE;
		endcase
end
endmodule
