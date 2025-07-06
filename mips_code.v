`timescale 1ns/1ps

// Company: IIT(ISM) Dhanbad
// Engineer: Amit Patel
// 
// Create Date: 05.07.2025 10:18:32
// Design Name: 5 stage pipelined architecture of mips32 
// Module Name: mips_32
// Project Name: MIPS 32-bit Processor
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
module mips_32 (clk1 , clk2);  // TWO PHASE CLOCK

input clk1 , clk2 ;
reg [31:0] PC , IF_ID_NPC , IF_ID_IR ;
reg [31:0] ID_EX_NPC , ID_EX_A , ID_EX_B , ID_EX_IMM , ID_EX_IR ;
reg [31:0] EX_MEM_ALUout , EX_MEM_COND , EX_MEM_B , EX_MEM_IR ;
reg [31:0] MEM_WB_ALUout , MEM_WB_LMD , MEM_WB_IR ;
reg [2:0] ID_EX_type , EX_MEM_type , MEM_WB_type ;

reg [31:0] reg_file [31:0] ;  // 32x32 REGISTER BANK
reg [31:0] mem [1023:0] ;     // 1024x32 MEMORY

parameter ADD = 6'b000000 , SUB = 6'b000001 , AND = 6'b000010 , OR = 6'b000011 , SLT = 6'b000100 , MUL = 6'b000101 ,
          HLT = 6'b111111 , LW = 6'b001000 , SW = 6'b001001 , ADDI = 6'b001010 , SUBI = 6'b001011 , SLTI = 6'b001100 ,
          BNEQZ = 6'b001101 , BEQZ = 6'b001110 ;

parameter RR_ALU = 3'b000 , RM_ALU = 3'b001 , LOAD = 3'b010 , STORE = 3'b011 , BRANCH = 3'b100 , HALT = 3'b101 ; 

reg HALTED ; // set after HLT instruction is completed (i.e. in WB stage) 
reg TAKEN_BRANCH ; // required to disable instructions after branch

always @(posedge clk1 ) begin             // 1st stage - Instruction Fetch (IF)
    if(HALTED == 0) 
    begin
        if(((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_COND == 1)) || 
        ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_COND == 0))) 
        begin
            IF_ID_IR     <= #2 mem[EX_MEM_ALUout] ;
            TAKEN_BRANCH <= #2 1'b1 ;
            IF_ID_NPC    <= #2 EX_MEM_ALUout + 1 ;
            PC           <= #2 EX_MEM_ALUout + 1 ;
        end
        else 
        begin
            IF_ID_IR     <= #2 mem[PC] ;
            IF_ID_NPC    <= #2 PC + 1 ;
            PC           <= #2 PC + 1 ;       
        end

    end
end

always @(posedge clk2 ) begin             // 2nd stage - Instruction Decode & Register Read (ID)
    if(HALTED == 0) 
    begin
        if (IF_ID_IR[25:21] == 5'b00000) begin
            ID_EX_A <= #2 32'b0 ; 
        end
        else ID_EX_A <= #2 reg_file[IF_ID_IR[25:21]] ;   // rs

        if (IF_ID_IR[20:16] == 5'b00000) begin
            ID_EX_B <= #2 32'b0 ; 
        end
        else ID_EX_B <= #2 reg_file[IF_ID_IR[20:16]] ;  // rt

        ID_EX_NPC <= #2 IF_ID_NPC ;
        ID_EX_IR  <= #2 IF_ID_IR ;
        ID_EX_IMM <= #2 {{16{IF_ID_IR[15]}} , {IF_ID_IR[15:0]}} ;

        case (IF_ID_IR[31:26])
           ADD , SUB , AND , OR , MUL , SLT : ID_EX_type <= #2 RR_ALU ;
           ADDI , SUBI , SLTI               : ID_EX_type <= #2 RM_ALU ;
           LW                               : ID_EX_type <= #2 LOAD ;
           SW                               : ID_EX_type <= #2 STORE ;
           BNEQZ , BEQZ                     : ID_EX_type <= #2 BRANCH ;
           HLT                              : ID_EX_type <= #2 HALT ;
           default                          : ID_EX_type <= #2 HALT ;
        endcase
 
    end
end

always @(posedge clk1 ) begin             // 3rd stage - Execution/ALU (EX) 
    if(HALTED == 0)
    begin
        EX_MEM_type  <= ID_EX_type ;
        EX_MEM_IR    <= ID_EX_IR ;
        TAKEN_BRANCH <= 1'b0 ;  

        case (ID_EX_type)
           RR_ALU : begin
                    case (ID_EX_IR[31:26])
                       ADD : EX_MEM_ALUout  <= #2 ID_EX_A + ID_EX_B ;
                       SUB : EX_MEM_ALUout  <= #2 ID_EX_A - ID_EX_B ;
                       AND : EX_MEM_ALUout  <= #2 ID_EX_A & ID_EX_B ;
                       OR  : EX_MEM_ALUout  <= #2 ID_EX_A | ID_EX_B ;
                       SLT : EX_MEM_ALUout  <= #2 ID_EX_A < ID_EX_B ;
                       MUL : EX_MEM_ALUout  <= #2 ID_EX_A * ID_EX_B ;
                         
                        default: EX_MEM_ALUout <= #2 32'hxxxxxxxx ;
                    endcase
           end

           RM_ALU : begin
                    case (ID_EX_IR[31:26])
                       ADDI : EX_MEM_ALUout <= #2 ID_EX_A + ID_EX_IMM ;
                       SUBI : EX_MEM_ALUout <= #2 ID_EX_A - ID_EX_IMM ;
                       SLTI : EX_MEM_ALUout <= #2 ID_EX_A < ID_EX_IMM ;
                       
                       default: EX_MEM_ALUout <= #2 32'hxxxxxxxx ;
                    endcase
           end

           LOAD , STORE : begin
                       EX_MEM_ALUout <= #2 ID_EX_A + ID_EX_IMM ;
                       EX_MEM_B      <= #2 ID_EX_B ; 
           end  

           BRANCH : begin
                       EX_MEM_ALUout <= #2 ID_EX_NPC + ID_EX_IMM ;
                       EX_MEM_COND   <= #2 (ID_EX_A == 0) ;
           end  
        
        endcase
    end
end

always @(posedge clk2 ) begin             // 4th stage - Memory Access (MEM)
    if(HALTED == 0) begin
        MEM_WB_type <= #2 EX_MEM_type ;
        MEM_WB_IR   <= #2 EX_MEM_IR ;

        case (EX_MEM_type)
          RR_ALU , RM_ALU : MEM_WB_ALUout <= #2 EX_MEM_ALUout ;
          LOAD            : MEM_WB_LMD    <= #2 mem[EX_MEM_ALUout] ;
          STORE           : if(TAKEN_BRANCH == 0) 
                                mem[EX_MEM_ALUout] <= #2 EX_MEM_B ; 
        
        endcase
    end
end

always @(posedge clk1 ) begin             // %th stage - Writeback (WB)
    if(TAKEN_BRANCH == 0) begin
        case (MEM_WB_type)
           RR_ALU : reg_file[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUout ;
           RM_ALU : reg_file[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUout ;
           LOAD   : reg_file[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD ;
           HALT   : HALTED                     <= #2 1'b1 ;
            
        endcase
    end
end
endmodule