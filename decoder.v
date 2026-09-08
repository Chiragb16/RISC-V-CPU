module decoder(
    input [31:0] instruction,

    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,

    output reg [3:0] alu_control,
    output reg alu_src,
    output reg [31:0] immediate,

    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch_ne,
    output reg branch,
    output reg branch_lt,
    output reg branch_lt_u,
    output reg branch_ge,
    output reg branch_ge_u,
    output reg [31:0] branch_imm,
    output reg jal,
    output reg [31:0]jal_imm,
    output reg jalr,
    output reg lui,
    output reg auipc,
    output reg load_byte, 
    output reg load_byte_unsigned,
    output reg load_half,
    output reg load_half_unsigned,
    output reg store_byte,
    output reg store_half,
    output reg halt
);

localparam ADD    = 4'b0000;
localparam SUB    = 4'b0001;
localparam AND_OP = 4'b0010;
localparam OR_OP  = 4'b0011;
localparam XOR_OP = 4'b0100;
localparam SLT    = 4'b0101;
localparam SLTU   = 4'b0110;
localparam SLL    = 4'b0111;
localparam SRL    = 4'b1000;
localparam SRA    = 4'b1001;

always @(*) begin

    rs1 = instruction[19:15];
    rs2 = 5'd0;
    rd = instruction[11:7];

    alu_control = ADD;
    alu_src = 1'b0;
    immediate = 32'd0;

    reg_write = 1'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_to_reg = 1'b0;
    branch_lt=1'b0;
    branch_lt_u=1'b0;
    branch_ge=1'b0;
    branch_ge_u=1'b0;
    branch_ne=1'b0;
    branch = 1'b0;
    branch_imm = 32'd0;
    jal=1'b0;
    jal_imm=32'd0;
    jalr=1'b0;
    lui=1'b0;
    auipc=1'b0;
    load_byte=1'b0;
    load_byte_unsigned=1'b0;
    load_half=1'b0;
    load_half_unsigned=1'b0;
    store_byte=1'b0;
    store_half=1'b0;
    halt=1'b0;

    case(instruction[6:0])

    
        7'b0110011: begin

            alu_src = 1'b0;
            reg_write = 1'b1;
            rs2 = instruction[24:20];

            case(instruction[14:12])

                3'b000: begin
                    if(instruction[31:25] == 7'b0000000)
                        alu_control = ADD;
                    else if(instruction[31:25] == 7'b0100000)
                        alu_control = SUB;
                end

                3'b111:
                    alu_control = AND_OP;

                3'b110:
                    alu_control = OR_OP;

                3'b100:
                    alu_control = XOR_OP;

                3'b010:
                    alu_control = SLT;

                3'b011:
                    alu_control=SLTU;

                3'b001:
                    alu_control=SLL;
                3'b101:begin
                    if(instruction[31:25] == 7'b0000000)
                        alu_control=SRL;
                    if(instruction[31:25] == 7'b0100000)
                        alu_control=SRA;
                end

                default:
                    alu_control = ADD;

            endcase
        end

        
        7'b0010011: begin

            alu_src = 1'b1;
            reg_write = 1'b1;

            immediate = {{20{instruction[31]}},
                         instruction[31:20]};

            case(instruction[14:12])
                3'b000: alu_control = ADD;
                3'b001: alu_control = SLL;
                3'b010: alu_control = SLT;
                3'b011: alu_control = SLTU;
                3'b101:begin
                    if(instruction[31:25]==7'b0000000)
                        alu_control=SRL;
                    if(instruction[31:25]==7'b0100000)
                        alu_control=SRA;

                end
                default: begin
                    alu_control=ADD;
                    reg_write=1'b0;
                end
            endcase

        end

        
        7'b0000011: begin

            alu_src = 1'b1;
            reg_write = 1'b1;
            mem_read = 1'b1;
            mem_to_reg = 1'b1;

            immediate = {{20{instruction[31]}},
                         instruction[31:20]};

            if(instruction[14:12] == 3'b010)
                alu_control = ADD;

            if(instruction[14:12] == 3'b000)begin
                alu_control = ADD;
                load_byte=1'b1;
            end

            if(instruction[14:12] == 3'b100)begin
                alu_control=ADD;
                load_byte_unsigned=1'b1;
            end

            if(instruction[14:12] == 3'b001)begin
                alu_control=ADD;
                load_half=1'b1;
            end

            if(instruction[14:12] == 3'b101)begin
                alu_control=ADD;
                load_half_unsigned=1'b1;
            end

        end

    
        7'b0100011: begin

            alu_src = 1'b1;
            mem_write = 1'b1;

            rs2 = instruction[24:20];

            immediate = {{20{instruction[31]}},
                         instruction[31:25],
                         instruction[11:7]};

            case(instruction[14:12])
                3'b000: begin
                    store_byte=1'b1;
                end

                3'b001: begin
                    store_half=1'b1;
                end

                3'b010: begin
                    alu_control=ADD;
                end
            endcase
        end

        
        7'b1100011: begin

            rs2 = instruction[24:20];

            branch_imm = {{19{instruction[31]}},
                  instruction[31],
                  instruction[7],
                  instruction[30:25],
                  instruction[11:8],
                  1'b0};

            if (instruction[14:12] == 3'b000) begin
                branch = 1'b1;
                branch_ne = 1'b0;
                alu_src = 1'b0;
                alu_control = SUB;
            end

            else if (instruction[14:12] == 3'b001) begin
                branch = 1'b1;
                branch_ne = 1'b1;
                alu_src = 1'b0;
                alu_control = SUB;
            end

            else if (instruction[14:12] == 3'b100) begin
                branch = 1'b1;
                branch_lt = 1'b1;
                alu_src = 1'b0;
                alu_control = SLT;
            end

            else if (instruction[14:12] == 3'b101) begin
                branch=1'b1;
                branch_ge=1'b1;
                alu_src=1'b0;
                alu_control=SLT;
            end

            else if (instruction[14:12] == 3'b110) begin
                branch=1'b1;
                branch_lt_u=1'b1;
                alu_src=1'b0;
                alu_control=SLTU;
            end

            else if (instruction[14:12] == 3'b111) begin
                branch=1'b1;
                branch_ge_u=1'b1;
                alu_src=1'b0;
                alu_control=SLTU;
            end
        end  

        7'b1101111: begin
            jal=1'b1;
            reg_write=1'b1;
            jal_imm={{11{instruction[31]}},instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0};
        end

        7'b1100111: begin
            if(instruction[14:12] == 3'b000) begin
                jalr=1'b1;
                reg_write=1'b1;
                alu_src=1'b1;
                alu_control=ADD;

                immediate={{20{instruction[31]}},instruction[31:20]};
            end
        end

        7'b0110111: begin
            lui=1'b1;
            alu_src=1'b1;
            reg_write=1'b1;
            alu_control=ADD;
            immediate={instruction[31:12],12'd0};
        end

        7'b0010111: begin
            auipc=1'b1;
            alu_src=1'b1;
            reg_write=1'b1;
            alu_control=ADD;
            immediate={instruction[31:12],12'd0};
        end
        
        7'b0001111: begin
            reg_write=1'b0;
            mem_read=1'b0;
            mem_write=1'b0;
        end

        7'b1110011: begin
            if(instruction[31:20] == 12'd0 || instruction[31:20] == 12'd1) begin
                halt=1'b1;
            end
        end

        default: begin
             reg_write = 1'b0;
         end

    endcase
end

endmodule
