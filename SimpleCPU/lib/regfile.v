`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    
    input wire wb_we,
    input wire [4:0] wb_waddr,
    input wire [31:0] wb_wdata,

    input wire ex_we,
    input wire [4:0] ex_waddr,
    input wire [31:0] ex_wdata,

    input wire mem_we,
    input wire [4:0] mem_waddr,
    input wire [31:0] mem_wdata
);
    reg [31:0] reg_array [31:0];
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end

    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : 
                    ((raddr1 == ex_waddr) && ex_we))? ex_wdata:
                    ((raddr1 == mem_waddr) && mem_we))? mem_wdata:
                    ((raddr1 == wb_waddr) && wb_we))? wb_wdata:
                    reg_array[raddr1];

    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : 
                    ((raddr2 == ex_waddr) && ex_we))? ex_wdata:
                    ((raddr2 == mem_waddr) && mem_we))? mem_wdata:
                    ((raddr2 == wb_waddr) && wb_we))? wb_wdata:
                    reg_array[raddr2];
endmodule