`default_nettype none

module fmeasurment #(parameter LENGTH = 20) (
    input  wire         clk,         // clock
    input  wire         gate,        // gate for counting
    input  wire [1:0]   div_select,  // select which divider is used  
    input  wire         reset,       // reset counter to zero
    input  wire         sync_select, // select if the gate is synchronized with two FFs
    output wire [LENGTH - 1:0] 
                        cycle_count, // number of counted cycles
    output wire         divided_clk  // the divided clock, speed is selected with div_select
);
    reg [LENGTH - 1:0]  counts;
    reg                 selected_divided_clk;

    assign cycle_count = counts;
    assign divided_clk = !selected_divided_clk;

    always @(counts or div_select) begin
        case (div_select)
            2'b00: selected_divided_clk = counts[1];
            2'b01: selected_divided_clk = counts[3];
            2'b10: selected_divided_clk = counts[5];
            2'b11: selected_divided_clk = counts[7];
        endcase
    end

    reg [1 : 0] gate_syncs;
    wire gate_final;
    
    assign gate_final = sync_select ? gate_syncs[1] : gate;

    always @(posedge clk) begin
        gate_syncs <= {gate_syncs[0], gate};
        if (reset == 1) begin
            counts <= 0;
        end else begin
            counts <= counts + {{LENGTH - 1{1'b0}}, gate_final};
        end
    end
endmodule
