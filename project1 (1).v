`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2022 11:24:52 AM
// Design Name: 
// Module Name: led_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module count60_tb(

    );
    reg rst;
    reg rst2;
    reg clk;
    reg en;
    wire [3:0] count;
    wire [3:0] count2;
    reg [5:0] count3;
    wire co;
    initial begin
        rst = 0;
        clk = 0;
        en = 0;
        #100
        rst = 1;
        rst2=1;
        #40
        rst = 0;
        en = 1;
        #250
        rst2=0;
        
    end
    
    always #10 clk = ~clk;
    count_60 count10(rst,rst2,clk,en,count,count2,co);
   always @ (posedge clk) begin
   count3 <= count2 * 4'd10+count;
   end   
     
endmodule
