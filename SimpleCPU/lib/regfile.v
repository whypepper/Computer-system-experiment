`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    
   
    input wire [`EX_TO_RF_WD-1:0] ex_to_rf_bus,
    input wire [`MEM_TO_RF_WD-1:0] mem_to_rf_bus,
    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus

);

    wire ex_we;
    wire [4:0] ex_waddr;
    wire [31:0] ex_wdata;

    wire mem_we;
    wire [4:0] mem_waddr;
    wire [31:0] mem_wdata;
    
    wire wb_we;
    wire [4:0] wb_waddr;
    wire [31:0] wb_wdata;

    
    assign {
        ex_we,
        ex_waddr,
        ex_wdata
    } = ex_to_rf_bus;
    assign {
        mem_we,
        mem_waddr,
        mem_wdata
    } = mem_to_rf_bus;
    assign {
        wb_we,
        wb_waddr,
        wb_wdata
    } = wb_to_rf_bus;

    reg [31:0] reg_array [31:0];
    // write
    always @ (posedge clk) begin
        if (wb_we && wb_waddr!=5'b0) begin
            reg_array[wb_waddr] <= wb_wdata;
        end
    end

    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : 
                    ((raddr1 == ex_waddr) && ex_we)? ex_wdata:
                    ((raddr1 == mem_waddr) && mem_we)? mem_wdata:
                    ((raddr1 == wb_waddr) && wb_we)? wb_wdata:
                    reg_array[raddr1];

    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : 
                    ((raddr2 == ex_waddr) && ex_we)? ex_wdata:
                    ((raddr2 == mem_waddr) && mem_we)? mem_wdata:
                    ((raddr2 == wb_waddr) && wb_we)? wb_wdata:
                    reg_array[raddr2];
endmodule