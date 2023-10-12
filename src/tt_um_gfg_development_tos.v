`default_nettype none

module tt_um_gfg_development_tos (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire reset = ! rst_n;

    // use bidirectionals as outputs
    assign uio_oe       = 8'b11111111;

    assign uo_out[6:0]  = 8'b1111111;
    assign uio_out      = 8'b11111111;

    assign uo_out[6]    = nan2_sub_clk;
    assign uo_out[7]    = nand4_clk;

    wire nand4_clk;
    ros_nand4 ros_nand4(.ena(ena), .clk(nand4_clk));

    wire nand2_sub_clk;
    ros_nand2_sub ros_nand2_sub(.ena(ena), .clk(nand2_sub_clk));

    always @(posedge clk) begin
        if (reset) begin
            
        end else begin
            
        end
    end
endmodule
