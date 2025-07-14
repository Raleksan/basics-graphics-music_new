
module instruction_ram
#(
    parameter SIZE = 256
)
(
    input logic         clk,

    input  logic        mem_valid,
    output logic        mem_ready,

    input  logic [31:0] mem_addr,
    input  logic [3:0]  mem_wstrb,

    output logic [31:0] mem_rdata,
    input  logic [31:0] mem_wdata
);
    logic [31:0]    memory [0:SIZE - 1];

    initial $readmemh ("program.hex", memory);

    logic           addr_valid;

    always_comb begin : addr_range_check
        // Checking the address for a range with byte align
        addr_valid = (mem_addr >> 2) < SIZE;
    end

    always @(posedge clk) begin: mem_write
		if (mem_valid && addr_valid) begin
            if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
            if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
            if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
		end
	end

    always_ff @(posedge clk) begin: mem_read
        if (mem_valid && addr_valid) begin
            if (~|mem_wstrb)  mem_rdata <= memory[mem_addr >> 2];
        end
    end

    always_ff @(posedge clk) begin: mem_ready_dly
        // Not safe, just for demo. Read/write with out-of-range addr will be ignored 
        mem_ready <= mem_valid; 

        // A safe option that causes the processor to wait indefinitely for a memory read for out-of-range address.
        // mem_ready <= mem_valid && addr_valid;
    end

endmodule
