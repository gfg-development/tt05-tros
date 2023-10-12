`default_nettype none

module ros_nand2_sub #( parameter STAGES = 33) (
    input  wire       ena,      // will go high when the design is enabled
    output wire       clk       // clock
);
    (* keep = "true" *) wire [STAGES - 1:0] nets;
    (* keep = "true" *) wire sub_voltage;

    assign clk = !nets[0];

    (* keep = "true" *) sky130_fd_sc_hd__inv_1 sub_generator (.A(sub_voltage), .Y(sub_voltage));

    (* keep = "true" *) sky130_fd_sc_hd__nand2_1 fstage (.A(nets[STAGES - 1]), .B(ena), .Y(nets[0]));
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin
            (* keep = "true" *) sky130_fd_sc_hd__nand2_1 stage (.A(nets[i - 1]), .B(sub_voltage), .Y(nets[i]));
        end
    endgenerate
endmodule
