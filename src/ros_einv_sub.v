`default_nettype none

module ros_einv_sub #(parameter STAGES = 3) (
    input  wire       ena,      // will go high when the design is enabled
    output wire       clk       // clock
);
    (* keep = "true" *) wire [4 * STAGES:0] nets;
    (* keep = "true" *) wire sub_voltage;

    assign clk = !nets[0];

    (* keep = "true" *) sky130_fd_sc_hd__inv_1 sub_generator (.A(sub_voltage), .Y(sub_voltage));

    (* keep = "true" *) sky130_fd_sc_hd__nand2_1 fstage (.A(nets[4 * STAGES]), .B(ena), .Y(nets[0]));
    genvar i;
    genvar j;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
                (* keep = "true" *) sky130_fd_sc_hd__einvp_1 tristage (.A(nets[4 * i + j]), .TE(sub_voltage), .Z(nets[4 * i + j + 1]));
            end
            (* keep = "true" *) sky130_fd_sc_hd__inv_1 stage (.A(nets[4 * i + 3]), .Y(nets[4 * i + 4]));
        end
    endgenerate
endmodule
