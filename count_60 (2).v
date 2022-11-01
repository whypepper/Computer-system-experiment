module count_60(
    input wire rst,
    input wire rst2,
    input wire clk,
    input wire en,
    output  [3:0] count1,
    output  [3:0] count2,
    output  co
    
);
    
    wire co10,co6;
    
    count_10 u_count_10(
    	.rst   (rst   ),
        .clk   (clk   ),
        .en    (en    ),
        .count (count1 ),
        .co    (co10    )
    );
    
    count_6 u_count_6(
    	.rst   (rst2   ),
        .clk   (co10   ),
        .en    (en    ),
        .count (count2 ),
        .co    (co   )
    );
    
    //assign count3 <= count2 * 4'd10+count1;
    
    
    //assign co=co6;
    
endmodule