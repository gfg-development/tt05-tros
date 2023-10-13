`default_nettype none

module ros_nand4_cap #(parameter STAGES = 23, NR_CAPS = 4) (
    input  wire       ena,      // will go high when the design is enabled
    output wire       clk       // clock
);
    (* keep = "true" *) wire [STAGES - 1:0] nets;
    (* keep = "true" *) wire [STAGES * NR_CAPS - 1:0] open_nets;

    assign clk = !nets[0];

    (* keep = "true" *) sky130_fd_sc_hd__nand4_1 fstage (.A(nets[STAGES - 1]), .B(ena), .C(nets[STAGES - 1]), .D(nets[STAGES - 1]), .Y(nets[0]));
    genvar i;
    genvar j;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin
            (* keep = "true" *) sky130_fd_sc_hd__nand4_1 stage (.A(nets[i - 1]), .B(nets[i - 1]), .C(nets[i - 1]), .D(nets[i - 1]), .Y(nets[i]));
        end
    endgenerate

    generate
        for (i = 0; i < STAGES; i = i + 1) begin
            for (j = 0; j < NR_CAPS; j = j + 1) begin
                (* keep = "true" *) sky130_fd_sc_hd__nand2_1 cap (.A(nets[i]), .B(1'b0), .Y(open_nets[NR_CAPS * i + j]));
            end
        end
    endgenerate
endmodule
