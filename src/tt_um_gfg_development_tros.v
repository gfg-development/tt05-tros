`default_nettype none

module tt_um_gfg_development_tros #(parameter COUNTER_LENGTH = 20) (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    /*
     * Configure and rename the IOs
     */
    wire reset                  = !rst_n;
    wire gate                   = ui_in[0];
    wire ctr_reset              = ui_in[1];
    wire latch_counter          = ui_in[2];
    wire [1:0] counter_select   = ui_in[4:3];
    wire sync_select            = ui_in[5];
    wire [1:0] div_select       = ui_in[7:6];

    // use bidirectionals as outputs
    assign uio_oe       = 8'b11111111;
    assign uio_out      = 8'b11111111;

    assign uo_out[3:1]  = 3'b111;

    assign uo_out[0]    = data_stream;
    assign uo_out[4]    = inv_sub_div_clk;
    assign uo_out[5]    = nand4_cap_div_clk;
    assign uo_out[6]    = nand2_sub_div_clk;
    assign uo_out[7]    = nand4_div_clk;


    /*
     * Implement the NAND4 ring oscillator
     */
    wire nand4_clk;
    wire nand4_div_clk;
    wire [COUNTER_LENGTH-1:0] nand4_cycle_count;

    ros_nand4 ros_nand4(
        .ena(ena), 
        .clk(nand4_clk)
    );

    fmeasurment #(.LENGTH(COUNTER_LENGTH)) fmeasurment_nand4_ros(
        .clk(nand4_clk), 
        .gate(gate),
        .div_select(div_select),
        .reset(ctr_reset),
        .sync_select(sync_select),
        .cycle_count(nand4_cycle_count),
        .divided_clk(nand4_div_clk)
    );


    /*
     * Implement the NAND4 ring oscillator with additional capacity
     */
    wire nand4_cap_clk;
    wire nand4_cap_div_clk;
    wire [COUNTER_LENGTH-1:0] nand4_cap_cycle_count;

    ros_nand4_cap ros_nand4_cap(.ena(ena), .clk(nand4_cap_clk));

    fmeasurment #(.LENGTH(COUNTER_LENGTH)) fmeasurment_nand4_cap_ros(
        .clk(nand4_clk), 
        .gate(gate),
        .div_select(div_select),
        .reset(ctr_reset),
        .sync_select(sync_select),
        .cycle_count(nand4_cap_cycle_count),
        .divided_clk(nand4_cap_div_clk)
    );


    /*
     * Implement the NAND2 ring oscillator with sub threshold at second input
     */
    wire nand2_sub_clk;
    wire nand2_sub_div_clk;
    wire [COUNTER_LENGTH-1:0] nand2_sub_cycle_count;

    ros_nand2_sub ros_nand2_sub(.ena(ena), .clk(nand2_sub_clk));

    fmeasurment #(.LENGTH(COUNTER_LENGTH)) fmeasurment_nand2_sub_ros(
        .clk(nand4_clk), 
        .gate(gate),
        .div_select(div_select),
        .reset(ctr_reset),
        .sync_select(sync_select),
        .cycle_count(nand2_sub_cycle_count),
        .divided_clk(nand2_sub_div_clk)
    );


    /*
     * Implement a tristate inverter ring oscillator with sub threashold
     */
    wire inv_sub_clk;
    wire inv_sub_div_clk;
    wire [COUNTER_LENGTH-1:0] inv_sub_cycle_count;

    ros_einv_sub ros_einv_sub(.ena(ena), .clk(inv_sub_clk));

    fmeasurment #(.LENGTH(COUNTER_LENGTH)) fmeasurment_einv_sub_ros(
        .clk(inv_sub_clk), 
        .gate(gate),
        .div_select(div_select),
        .reset(ctr_reset),
        .sync_select(sync_select),
        .cycle_count(inv_sub_cycle_count),
        .divided_clk(inv_sub_div_clk)
    );


    /*
     * Implement the readout of the counter values
     */
    wire data_stream;
    reg [COUNTER_LENGTH+3:0] shift_register;

    assign data_stream = shift_register[COUNTER_LENGTH+3] ^ clk;

    always @(posedge clk) begin
        if (ena) begin
            if (latch_counter == 1) begin
                case (counter_select)
                    2'b00: shift_register <= {4'b1010, nand4_cycle_count}; 
                    2'b01: shift_register <= {4'b1010, nand4_cap_cycle_count};
                    2'b10: shift_register <= {4'b1010, nand2_sub_cycle_count};
                    2'b11: shift_register <= {4'b1010, inv_sub_cycle_count};
                endcase
            end else begin
                shift_register <= {shift_register[COUNTER_LENGTH+2:0], 1'b0};
            end 
        end
    end
endmodule
