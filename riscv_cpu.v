module riscv_cpu(
    input clk,
    input rst
);

reg [31:0] pc;

reg [31:0] instr_mem [0:255];

reg [31:0] data_mem [0:255];

wire [31:0] mem_data;
wire [31:0] write_data;

wire [31:0] instruction;

wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;

wire [3:0] alu_control;
wire reg_write;
wire alu_src;
wire mem_read;
wire mem_write;
wire mem_to_reg;
wire branch;
wire [31:0]branch_imm;
wire zero;
wire branch_taken;
wire branch_ne;
wire branch_lt;
wire branch_lt_u;
wire branch_ge;
wire branch_ge_u;
wire jal;
wire [31:0]jal_imm;
wire jalr;
wire lui;
wire auipc;
wire [31:0]next_pc;
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire [31:0] immediate;
wire [31:0] alu_result;
wire [31:0] alu_a;
wire [31:0] alu_b;
wire load_byte_unsigned;
wire load_byte;
wire load_half;
wire load_half_unsigned;
wire [7:0]selected_byte;
wire [15:0]selected_half;
wire store_byte;
wire store_half;
wire halt;
localparam SLL=4'b0111;
localparam SRL=4'b1000;
localparam SRA=4'b1001;
assign selected_byte=data_mem[alu_result[9:2]][alu_result[1:0]*8 +: 8];
assign selected_half=data_mem[alu_result[9:2]][alu_result[1]*16 +: 16];
assign zero=(alu_result==32'd0);
assign branch_taken=branch && (branch_lt_u ? alu_result[0] : (branch_ge_u ? !alu_result[0] :(branch_lt ? alu_result[0] : (branch_ge ? !alu_result[0] : (branch_ne ? !zero : zero))))); // if branch_ne = 0 ,then BEQ otherwise BNE 
assign next_pc=branch_taken ? (pc+branch_imm) : (jal ? (pc+jal_imm) : (jalr ? {alu_result[31:1],1'b0} : (pc+32'd4)));
assign instruction = instr_mem[pc[9:2]];
assign alu_a=lui ? 32'd0 : auipc ? pc : rs1_data;
assign alu_b=(alu_src && (alu_control==SLL || alu_control==SRL || alu_control==SRA))? {27'd0,instruction[24:20]} : alu_src? immediate: rs2_data;
assign mem_data = load_byte ? {{24{selected_byte[7]}}, selected_byte} : load_byte_unsigned ? {24'd0, selected_byte} : load_half ? {{16{selected_half[15]}}, selected_half}: load_half_unsigned ? {16'd0,selected_half} : data_mem[alu_result[9:2]];
assign write_data=(jal || jalr) ? (pc+32'd4) : (mem_to_reg)? mem_data:alu_result;

always @(posedge clk) begin
    if (mem_write) begin

        if (store_byte) begin

            case (alu_result[1:0])

                2'b00:
                    data_mem[alu_result[9:2]][7:0]
                        <= rs2_data[7:0];

                2'b01:
                    data_mem[alu_result[9:2]][15:8]
                        <= rs2_data[7:0];

                2'b10:
                    data_mem[alu_result[9:2]][23:16]
                        <= rs2_data[7:0];

                2'b11:
                    data_mem[alu_result[9:2]][31:24]
                        <= rs2_data[7:0];

            endcase

        end

        else if (store_half) begin

            case (alu_result[1:0])

                2'b00:
                    data_mem[alu_result[9:2]][15:0]
                        <= rs2_data[15:0];

                2'b10:
                    data_mem[alu_result[9:2]][31:16]
                        <= rs2_data[15:0];

            endcase

        end

        else begin
            data_mem[alu_result[9:2]] <= rs2_data;
        end

    end
end

always @(posedge clk or posedge rst) begin
    if(rst)
        pc <= 32'd0;
    else if(!halt)
        pc <= next_pc;
end

decoder decoder_inst(
    .instruction(instruction),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .alu_control(alu_control),
    .branch_ge_u(branch_ge_u),
    .branch_lt_u(branch_lt_u),
    .branch_ge(branch_ge),
    .branch_lt(branch_lt),
    .branch_ne(branch_ne),
    .branch(branch),
    .branch_imm(branch_imm),
    .jal(jal),
    .jal_imm(jal_imm),
    .jalr(jalr),
    .lui(lui),
    .auipc(auipc),
    .alu_src(alu_src),
    .load_byte(load_byte),
    .load_byte_unsigned(load_byte_unsigned),
    .load_half(load_half),
    .load_half_unsigned(load_half_unsigned),
    .store_byte(store_byte),
    .store_half(store_half),
    .halt(halt),
    .immediate(immediate),
    .reg_write(reg_write)
);

register_file reg_file_inst(
    .clk(clk),
    .rst(rst),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_en(reg_write),
    .write_data(write_data),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);

alu alu_inst(
    .a(alu_a),
    .b(alu_b),
    .alu_control(alu_control),
    .result(alu_result)
);

initial begin
    instr_mem[0]  = 32'h123452B7;
    instr_mem[1]  = 32'h00001317;
    instr_mem[2]  = 32'hFF808093;
    instr_mem[3]  = 32'h00209113;
    instr_mem[4]  = 32'h0020D193;
    instr_mem[5]  = 32'h4020D213;
    instr_mem[6]  = 32'h0000A393;
    instr_mem[7]  = 32'h0000B413;
    instr_mem[8]  = 32'h00502493;
    instr_mem[9]  = 32'h00503513;

    instr_mem[10] = 32'h00A00613;
    instr_mem[11] = 32'h00602023;
    instr_mem[12] = 32'h00002683;

    instr_mem[13] = 32'h0AB00713;
    instr_mem[14] = 32'h00E000A3;
    instr_mem[15] = 32'h00104793;
    instr_mem[16] = 32'h00105813;

    instr_mem[17] = 32'h12300713;
    instr_mem[18] = 32'h00E01123;
    instr_mem[19] = 32'h00204913;
    instr_mem[20] = 32'h00205A13;

    instr_mem[21] = 32'h00500113;
    instr_mem[22] = 32'h00500193;

    instr_mem[23] = 32'h00310463;
    instr_mem[24] = 32'h00000013;
    instr_mem[25] = 32'h001002B3;

    instr_mem[26] = 32'h0000000F;
    instr_mem[27] = 32'h00000073;
end

endmodule


