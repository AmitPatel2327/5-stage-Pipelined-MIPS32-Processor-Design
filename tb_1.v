`timescale 1ns/1ps

//  Adding three numbers 10, 20 and 30 stored in processor registers.

//  Steps:
//  Initialize register R1 with 10.
//  Initialize register R2 with 20.
//  Initialize register R3 with 30.
//  Add the three numbers and store the sum in R4.

module tb_1 ();
reg clk1 , clk2 ;
integer k ;

mips_32 uut( .clk1(clk1) , .clk2(clk2)) ;

initial begin                   // Two Phase Clock Generation
    clk1 = 1'b0 ;
    clk2 = 1'b0 ;
    forever begin
        #5 clk1 = 1'b1 ;
        #5 clk1 = 1'b0 ;
        #5 clk2 = 1'b1 ;
        #5 clk2 = 1'b0 ;
    end
end 

initial begin                   // initialization of register bank and memory
    for ( k = 0 ; k < 32 ; k=k+1 ) begin
        uut.reg_file[k] = k ;
    end
    
    // Dummy Intruction are added to get rid of data hazard.
    uut.mem[0] = 32'h2801000a;  // ADDI  R1, R0, 10
    uut.mem[1] = 32'h28020014;  // ADDI  R2, R0, 20
    uut.mem[2] = 32'h28030019;  // ADDI  R3, R0, 25
    uut.mem[3] = 32'h0ce77800;  // OR    R7, R7, R7   -- dummy instr.
    uut.mem[4] = 32'h0ce77800;  // OR    R7, R7, R7   -- dummy instr.
    uut.mem[5] = 32'h00222000;  // ADD   R4, R1, R2
    uut.mem[6] = 32'h0ce77800;  // OR    R7, R7, R7   -- dummy instr.
    uut.mem[7] = 32'h00832800;  // ADD   R5, R4, R3
    uut.mem[8] = 32'hfc000000;  // HLT
end

initial begin
    uut.HALTED = 0 ;
    uut.TAKEN_BRANCH = 0 ;
    uut.PC = 0 ;
end

initial begin                  // display of required Output 
    #300
    for (k = 0 ; k<6 ; k=k+1 ) begin
        $display("R%1d - %2d" , k , uut.reg_file[k]) ;
    end
     #200 $finish ;
end

endmodule