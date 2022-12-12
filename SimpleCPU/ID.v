`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    output wire stall_for_id,
    output wire stallreq,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,
    input wire inst_is_load,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,
    input wire [`EX_TO_RF_WD-1:0] ex_to_rf_bus,
    input wire [`MEM_TO_RF_WD-1:0] mem_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus 
);

    reg[31:0] inst_stall;
    reg inst_stall_en;
    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;                         // ä
    wire [31:0] id_pc;                        // ä0@
    wire ce;

    wire wb_rf_we;                            //ÎWBµ epn
    wire [4:0] wb_rf_waddr;                   
    wire [31:0] wb_rf_wdata;  

    wire ex_rf_we;                           //ÎEXµ epn
    wire [4:0] ex_rf_waddr;                   
    wire [31:0] ex_rf_wdata;

    wire mem_rf_we;                           //ÎMEMµ epn
    wire [4:0] mem_rf_waddr;                   
    wire [31:0] mem_rf_wdata;
    
    wire[31:0] inst_stall1;
    wire inst_stall_en1;
 
    always @ (posedge clk) begin               // 
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
        end
    end
    
    always @ (posedge clk) begin
        inst_stall_en <= 1'b0;
        inst_stall <= 32'b0;
        if(stall[1] == 1'b1)begin
            inst_stall <= inst;
            inst_stall_en <= 1'b1;
        end
    end

    assign inst_stall1 = inst_stall;
    assign inst_stall_en1 = inst_stall_en;
    
    
    assign inst = inst_stall_en1 ? inst_stall1 : inst_sram_rdata;            
    
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;                       
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;
    assign {
        ex_rf_we,
        ex_rf_waddr,
        ex_rf_wdata
    } = ex_to_rf_bus;
    assign {
        mem_rf_we,
        mem_rf_waddr,
        mem_rf_wdata
    } = mem_to_rf_bus;
    
    assign stall_for_id = (inst_is_load == 1'b1 && (rs == ex_rf_waddr || rt == ex_rf_waddr));

    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;

    regfile u_regfile(
    	.clk       (clk           ),
        .raddr1    (rs            ),
        .rdata1    (rdata1        ),
        .raddr2    (rt            ),
        .rdata2    (rdata2        ),
        .wb_we     (wb_rf_we      ),
        .wb_waddr  (wb_rf_waddr   ),
        .wb_wdata  (wb_rf_wdata   ),
        .ex_we     (ex_rf_we      ),
        .ex_waddr  (ex_rf_waddr   ),
        .ex_wdata  (ex_rf_wdata   ),
        .mem_we    (mem_rf_we     ),
        .mem_waddr (mem_rf_waddr  ),
        .mem_wdata (mem_rf_wdata  )
    );

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];
    
    
    
    wire inst_ori, inst_or, inst_xor, inst_xori, inst_nor, inst_lui, inst_and,inst_andi,
         inst_addiu, inst_addu, inst_add, inst_addi, inst_subu, inst_sub,
         inst_jr, inst_jal, inst_j, inst_beq, inst_bne,inst_bgez,inst_bgtz,inst_blez,
         inst_sll, inst_sllv, inst_sltu, inst_slt, inst_slti, inst_sltiu, inst_sra, inst_srav, 
         inst_srlv,inst_srl,
         inst_lw, inst_sw;

    wire op_addu, op_subu, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );

    
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_or      = op_d[6'b00_0000] & func_d[6'b10_0101];
    assign inst_xori    = op_d[6'b00_1110];
    assign inst_xor     = op_d[6'b00_0000] & func_d[6'b10_0110];
    assign inst_nor     = op_d[6'b00_0000] & func_d[6'b10_0111];
    assign inst_and     = op_d[6'b00_0000] & func_d[6'b10_0100];
    assign inst_andi    = op_d[6'b00_1100];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_addi    = op_d[6'b00_1000];
    assign inst_addu    = op_d[6'b00_0000] & func_d[6'b10_0001];
    assign inst_add     = op_d[6'b00_0000] & func_d[6'b10_0000];
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_bne     = op_d[6'b00_0101];
    assign inst_subu    = op_d[6'b00_0000] & func_d[6'b10_0011];
    assign inst_sub     = op_d[6'b00_0000] & func_d[6'b10_0010];
    assign inst_jr      = op_d[6'b00_0000] & func_d[6'b00_1000];
    assign inst_j       = op_d[6'b00_0010];
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_jalr    = op_d[6'b00_0000] & func_d[6'b00_1001];
    assign inst_sll     = op_d[6'b00_0000] & func_d[6'b00_0000];
    assign inst_sllv    = op_d[6'b00_0000] & func_d[6'b00_0100];
    assign inst_lw      = op_d[6'b10_0011];
    assign inst_sw      = op_d[6'b10_1011];
    assign inst_sltu    = op_d[6'b00_0000] & func_d[6'b10_1011];
    assign inst_slt     = op_d[6'b00_0000] & func_d[6'b10_1010];
    assign inst_slti    = op_d[6'b00_1010];
    assign inst_sltiu   = op_d[6'b00_1011];
    assign inst_sra     = op_d[6'b00_0000] & func_d[6'b00_0011];
    assign inst_srav    = op_d[6'b00_0000] & func_d[6'b00_0111];
    assign inst_srl     = op_d[6'b00_0000] & func_d[6'b00_0010];
    assign inst_srlv    = op_d[6'b00_0000] & func_d[6'b00_0110];
    assign inst_bgez    = op_d[6'b00_0001] & rt_d[5'b0_0001];
    assign inst_bgtz    = op_d[6'b00_0111];
    assign inst_blez    = op_d[6'b00_0110];
    assign inst_bltz    = op_d[6'b00_0001] & rt_d[5'b0_0000];
    assign inst_bltzal  = op_d[6'b00_0001] & rt_d[5'b1_0000];
    assign inst_bgezal  = op_d[6'b00_0001] & rt_d[5'b1_0001];
    // rs to reg1
    assign sel_alu_src1[0] = inst_ori | inst_or | inst_xor | inst_nor | inst_xori | inst_and | inst_andi | 
                             inst_addiu | inst_add | inst_addu | inst_addi | inst_subu | inst_sub |
                             inst_lw | inst_sw  | 
                             inst_sltu | inst_slt | inst_slti | inst_sltiu | inst_sllv | inst_srav | inst_srlv;

    // pc to reg1
    assign sel_alu_src1[1] = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;

    // sa_zero_extend to reg1
    assign sel_alu_src1[2] = inst_sll | inst_sra | inst_srl;

    
    // rt to reg2
    assign sel_alu_src2[0] = inst_subu | inst_sub | inst_addu | inst_add | inst_sll | inst_or | inst_xor | inst_nor | inst_and |
                             inst_sltu | inst_slt |inst_sllv | inst_sra | inst_srav | inst_srl | inst_srlv;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] = inst_lui | inst_addiu | inst_addi | inst_lw | inst_sw | inst_slti | inst_sltiu ;

    // 32'b8 to reg2
    assign sel_alu_src2[2] = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;

    // imm_zero_extend to reg2
    assign sel_alu_src2[3] = inst_ori | inst_andi | inst_xori;



    assign op_add = inst_addiu | inst_addu | inst_jal | inst_lw | inst_sw | inst_add | inst_addi | inst_bltzal | inst_bgezal | inst_jalr;
    assign op_subu = inst_subu | inst_sub;
    assign op_slt = inst_slt | inst_slti;
    assign op_sltu = inst_sltu | inst_sltiu; 
    assign op_and = inst_and | inst_andi;
    assign op_nor = inst_nor;
    assign op_or = inst_ori | inst_or;
    assign op_xor = inst_xor | inst_xori;
    assign op_sll = inst_sll | inst_sllv;
    assign op_srl = inst_srl | inst_srlv;
    assign op_sra = inst_sra | inst_srav;
    assign op_lui = inst_lui;

    assign alu_op = {op_add, op_subu, op_slt, op_sltu,
                     op_and, op_nor, op_or, op_xor,
                     op_sll, op_srl, op_sra, op_lui};



    // load and store enable
    assign data_ram_en = inst_lw | inst_sw;

    // write enable
    assign data_ram_wen =  inst_sw ? 4'b1111 : 4'b0000;



    // regfile store enable
    assign rf_we = inst_ori | inst_or | inst_xor | inst_xori | inst_nor | inst_and | inst_andi |inst_lui | 
                   inst_addiu | inst_subu | inst_sub | inst_jal | inst_addu | inst_bltzal | inst_bgezal | inst_jalr |
                   inst_sll | inst_sllv | inst_lw |  inst_sltu | inst_slt | inst_slti | inst_sra | inst_srav |
                   inst_srl | inst_srlv |
                   inst_sltiu | inst_add | inst_addi ;
 


    // store in [rd]
    assign sel_rf_dst[0] = inst_subu | inst_sub | inst_addu  | inst_or | inst_xor | inst_nor | inst_and |
                           inst_sll | inst_sllv |inst_sltu | inst_slt | inst_add | inst_sra | inst_srav | inst_srl | inst_srlv;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_ori | inst_xori | inst_andi | inst_lui | inst_addiu | inst_addi | inst_lw | inst_slti | inst_sltiu;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res = inst_lw ? 1'b1:1'b0; 

    assign id_to_ex_bus = {
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rdata1,         // 63:32
        rdata2          // 31:0
    };


    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt;
    wire rs_ge_z;
    wire rs_gt_z;
    wire rs_le_z;
    wire rs_lt_z;
    wire [31:0] pc_plus_4;
    assign pc_plus_4 = id_pc + 32'h4;

    assign rs_eq_rt = (rdata1 == rdata2);
    assign rs_ne_rt = (rdata1 != rdata2);
    assign rs_bgez = (rdata1[31]== 1'b0);
    assign rs_bgtz = (rdata1[30:0] > 31'b0 && rdata1[31] == 1'b0);
    assign rs_blez = (rs_bgtz == 1'b0);
    assign rs_bltz = (rdata1[31] == 1'b1);

    assign br_e = inst_beq & rs_eq_rt | inst_bne & rs_ne_rt | inst_jr | inst_jal | inst_jalr | inst_j | inst_bgez & rs_bgez | inst_bgtz & rs_bgtz | inst_blez & rs_blez |
                  inst_bltz & rs_bltz | inst_bltzal & rs_bltz | inst_bgezal & rs_bgez;
    assign br_addr = inst_beq ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_jal ? ({pc_plus_4[31:28],instr_index,2'b0}):
                     inst_jr | inst_jalr ? rdata1 : 
                     inst_j ? ({pc_plus_4[31:28],instr_index,2'b0}):
                     inst_bgez ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bne ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bgtz ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_blez ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bltz ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bltzal ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bgezal ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     32'b0;

    assign br_bus = {
        br_e,
        br_addr
    };
    


endmodule
