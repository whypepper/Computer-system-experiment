`include "lib/defines.vh"
module MEM(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [31:0] data_sram_rdata,
    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,
    output wire [`MEM_TO_RF_WD-1:0] mem_to_rf_bus,
    output wire [`MEM_TO_HILO-1:0] mem_to_hilo_bus
);

    reg [`EX_TO_MEM_WD-1:0] ex_to_mem_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        // else if (flush) begin
        //     ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        // end
        else if (stall[3]==`Stop && stall[4]==`NoStop) begin
            ex_to_mem_bus_r <= `EX_TO_MEM_WD'b0;
        end
        else if (stall[3]==`NoStop) begin
            ex_to_mem_bus_r <= ex_to_mem_bus;
        end
    end

    wire [31:0] mem_pc;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [31:0] ex_result;
    wire [31:0] mem_result;
    wire [31:0] mem_result;
    wire w_hi_we;
    wire w_lo_we;
    wire [31:0] lo_i;
    wire [31:0] hi_i;
    wire [5:0] inst;
    wire [5:0] opcode;
    wire [3:0] data_ram_sel;
    assign {
        mem_pc,         // 75:44
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        ex_result,       // 31:0
        w_hi_we,
        w_lo_we,
        hi_i,
        lo_i,
        inst,
        data_ram_sel
    } =  ex_to_mem_bus_r;
    
    assign opcode = inst;

    wire [63:0] op_d, func_d;
    
    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );
    
    assign inst_lw      = op_d[6'b10_0011];
    assign inst_lb      = op_d[6'b10_0000];
    assign inst_lbu      = op_d[6'b10_0100];
    assign inst_lh      = op_d[6'b10_0001];
    assign inst_lhu      = op_d[6'b10_0101];
    assign inst_sb      = op_d[6'b10_1000];
    assign inst_sh      = op_d[6'b10_1001];    
    assign inst_sw      = op_d[6'b10_1011];
    wire [7:0]  b_data;
    wire [15:0] h_data;
    wire [31:0] w_data;

    assign b_data = data_ram_sel[3] ? data_sram_rdata[31:24] : 
                data_ram_sel[2] ? data_sram_rdata[23:16] :
                data_ram_sel[1] ? data_sram_rdata[15: 8] : 
                data_ram_sel[0] ? data_sram_rdata[ 7: 0] : 8'b0;
   assign h_data = data_ram_sel[2] ? data_sram_rdata[31:16] :
                data_ram_sel[0] ? data_sram_rdata[15: 0] : 16'b0;
   assign w_data = data_sram_rdata;

   assign mem_result = inst_lb     ? {{24{b_data[7]}},b_data} :
                    inst_lbu    ? {{24{1'b0}},b_data} :
                    inst_lh     ? {{16{h_data[15]}},h_data} :
                    inst_lhu    ? {{16{1'b0}},h_data} :
                    inst_lw     ? w_data : 32'b0; 

    assign rf_wdata = sel_rf_res ? mem_result : ex_result;

    assign mem_to_wb_bus = {
        mem_pc,     // 69:38
        rf_we,      // 37
        rf_waddr,   // 36:32
        rf_wdata,   // 31:0
        w_hi_we,
        w_lo_we,
        hi_i,
        lo_i
    };

    assign mem_to_rf_bus = {
        rf_we,
        rf_waddr,
        rf_wdata
    };

    assign mem_to_hilo_bus=
    {
        w_hi_we,
        w_lo_we,
        hi_i,
        lo_i
    };

endmodule