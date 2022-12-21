`include "defines.vh"
module hilo_reg(
    input wire clk,

	input wire r_hi_we,
	input wire r_lo_we,
	output wire[31:0] hi_o,
	output wire[31:0] lo_o,
   
    input wire [`EX_TO_HILO-1:0] ex_to_hilo_bus,
    input wire [`MEM_TO_HILO-1:0] mem_to_hilo_bus,
    input wire [`WB_TO_HILO-1:0] wb_to_hilo_bus


);

    reg [31:0] hi;
    reg [31:0] lo;
    
    wire hi_ex_we;
    wire lo_ex_we;
    wire [31:0] hi_ex;
    wire [31:0] lo_ex;

    wire hi_mem_we;
    wire lo_mem_we;
    wire [31:0] hi_mem;
    wire [31:0] lo_mem;

    wire hi_wb_we;
    wire lo_wb_we;
    wire [31:0] hi_wb;
    wire [31:0] lo_wb;
    assign{
        hi_ex_we,
        lo_ex_we,
        hi_ex,
        lo_ex
    } = ex_to_hilo_bus;
    
    assign{
        hi_mem_we,
        lo_mem_we,
        hi_mem,
        lo_mem
    } = mem_to_hilo_bus;
    
    assign{
        hi_wb_we,
        lo_wb_we,
        hi_wb,
        lo_wb
    } = wb_to_hilo_bus;
    
    
    // write
    always @ (posedge clk) begin
        if (hi_wb_we ) begin
            hi <= hi_wb;
        end
        if (lo_wb_we ) begin
            lo <= lo_wb;
        end
    end
    
    assign hi_o =  hi_ex_we ? hi_ex:
                   hi_mem_we ? hi_mem:
                   hi_wb_we ? hi_wb: 
                   hi;
    assign lo_o =  lo_ex_we ? lo_ex:
                   lo_mem_we ? lo_mem:
                   lo_wb_we ? lo_wb:
                   lo;
     
endmodule