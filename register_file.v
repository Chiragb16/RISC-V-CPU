module register_file(
input clk,
input rst,
input [4:0]rs1,
input [4:0]rs2,
input [4:0]rd,
input write_en,
input [31:0]write_data,
output [31:0]rs1_data,
output [31:0]rs2_data
);
reg [31:0]regs[0:31];

assign rs1_data=(rs1==5'd0)? 32'd0 : regs[rs1];
assign rs2_data=(rs2==5'd0)? 32'd0 : regs[rs2];
integer i;

always @(posedge clk or posedge rst)begin
    if(rst)begin
        for(i=0;i<32;i++)begin
            regs[i]<=32'd0;
        end
    end
    else if(write_en && rd!=0)begin
        regs[rd]<=write_data;
    end
end
end
endmodule


