`timescale 1ns/1ps

// Compute the factorial of a number N stored in memory location 200. The result will be stored in memory location 198.

// The steps:
// Initialize register R10 with the memory address 200.
// Load the contents of memory location 200 into register R3.
// Initialize register R2 with the value 1.
// In a loop, multiply R2 and R3, and store the product in R2.
// Decrement R3 by 1; if not zero repeat the loop.
// Store the result (from R3) in memory location 198.

module tb_3 ();

reg clk1 , clk2 ;
integer k ;

mips_32 uut( .clk1(clk1) , .clk2(clk2)) ;

initial begin                    // Two Phase Clock Generation 
    clk1 = 1'b0 ;
    clk2 = 1'b0 ;

    forever begin
        #5 clk1 = 1 ;
        #5 clk1 = 0 ;
        #5 clk2 = 1 ;
        #5 clk2 = 0 ;

    end
end

initial begin                    // Initialization of Register Bank and Memory 
    for (k = 0 ; k<32 ;k=k+1 ) begin
        uut.reg_file[k] = k ; 
    end
    uut.mem[0]  = 32'h280a00c8;  // ADDI   R10, R0, 200
    uut.mem[1]  = 32'h28020001;  // ADDI   R2, R0, 1
    uut.mem[2]  = 32'h0e94a000;  // OR     R20, R20, R20  -- dummy instr.
    uut.mem[3]  = 32'h21430000;  // LW     R3, 0(R10)
    uut.mem[4]  = 32'h0e94a000;  // OR     R20, R20, R20  -- dummy instr.
    uut.mem[5]  = 32'h14431000;  // Loop:  MUL    R2, R2, R3
    uut.mem[6]  = 32'h2c630001;  //        SUBI   R3, R3, 1
    uut.mem[7]  = 32'h0e94a000;  //        OR     R20, R20, R20  -- dummy instr.
    uut.mem[8]  = 32'h3460fffc;  //        BNEQZ  R3, Loop (i.e., -4 offset)
    uut.mem[9]  = 32'h2542fffe;  //        SW     R2, -2(R10)
    uut.mem[10] = 32'hfc000000;  //        HLT
    
    uut.mem[200] = 7 ;
    end

initial begin
    uut.TAKEN_BRANCH = 0 ;
    uut.PC = 0 ;
    uut.HALTED = 0 ;

end

initial begin                    // Display of Required output
    $display("  Time     R2")  ;               
    $monitor("%6t   %4d  " , $time , uut.reg_file[2]) ;
    #1000 
    $display("mem[200] - %3d\nmem[198] - %3d" , uut.mem[200] , uut.mem[198]) ;
    
    #500 $finish ;
end

endmodule 