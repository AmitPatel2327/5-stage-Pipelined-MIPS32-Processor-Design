`timescale 1ns/1ps

//  Load a word stored in memory location 120, add 45 to it, and store the result in memory location 121.

//  Steps:
//  Initialize register R1 with the memory address 120.
//  Load the contents of memory location 120 into register R2.
//  Add 45 to register R2.
//  Store the result in memory location 121.


module tb_2 ();

reg clk1 , clk2 ;
integer k ;

mips_32 uut( .clk1(clk1) , .clk2(clk2)) ;

initial begin                   // Two phase clock generation 
    clk1 = 1'b0 ;
    clk2 = 1'b0 ;

    forever begin
        #5 clk1 = 1 ;
        #5 clk1 = 0 ;
        #5 clk2 = 1 ;
        #5 clk2 = 0 ;

    end
end

initial begin                   // initialization of register bank and memory
    for (k = 0 ; k<32 ;k=k+1 ) begin
        uut.reg_file[k] = k ; 
    end

    // Dummy intruction are added here to get rid of data hazard. 
    uut.mem[0] = 32'h28010078;  // ADDI R1, R0, 120
    uut.mem[1] = 32'h0c631800;  // OR   R3, R3, R3  -- dummy instr.
    uut.mem[2] = 32'h20220000;  // LW   R2, 0(R1)
    uut.mem[3] = 32'h0c631800;  // OR   R3, R3, R3  -- dummy instr.
    uut.mem[4] = 32'h2842002d;  // ADDI R2, R2, 45
    uut.mem[5] = 32'h0c631800;  // OR   R3, R3, R3  -- dummy instr.
    uut.mem[6] = 32'h24220001;  // SW   R2, 1(R1)
    uut.mem[7] = 32'hfc000000;  // HLT

    uut.mem[120] = 85 ;

end

initial begin
    uut.TAKEN_BRANCH = 0 ;
    uut.PC = 0 ;
    uut.HALTED = 0 ;
end

initial begin                   // Display of required output 
    #200 
    $display("R1 - %3d  ||  R2 - %3d  ||  mem[120] - %3d  ||  mem[121] - %3d" , uut.reg_file[1] , uut.reg_file[2] , uut.mem[120] , uut.mem[121]) ;
    #200 $finish ;
end
endmodule