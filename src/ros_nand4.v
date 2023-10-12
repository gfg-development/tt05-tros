`default_nettype none

module ros_nand4 #( parameter STAGES = 13) (
    input  wire       ena,      // will go high when the design is enabled
    output wire       clk       // clock
);
    wire [STAGES - 1:0] nets;

    assign clk = nets[0];

    (* keep = "true" *) sky130_fd_sc_hd__nand4_1 fstage (.A(nets[STAGES - 1]), .B(ena), .C(nets[STAGES - 1]), .D(nets[STAGES - 1]), .Y(nets[0]));
    genvar i;
    generate
		for (i = 1; i < STAGES; i = i + 1) begin
			(* keep = "true" *) sky130_fd_sc_hd__nand4_1 stage (.A(nets[i - 1]), .B(nets[i - 1]), .C(nets[i - 1]), .D(nets[i - 1]), .Y(nets[i]));
		end
  	endgenerate
endmodule
