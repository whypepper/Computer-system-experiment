`include "lib/defines.vh"
module CTRL(
    input wire rst,
    input wire stallreq_for_load,
    input wire stallreq_for_ex,
    output reg [`StallBus-1:0] stall
);  
    always @ (*) begin
        if (rst) begin
            stall = `StallBus'b0;
        end
        else if(stallreq_for_load == `Stop) begin
            stall = 6'b000111;
        end
        else if(stallreq_for_ex == `Stop) begin
            stall = 6'b001111;
        end
        else begin
            stall = `StallBus'b0;
        end
    end

endmodule