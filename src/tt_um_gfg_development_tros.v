/* The top-level of a number of ring oscillators, which 
 * have different temperature dependencies. Furhtermore 
 * it includes counters to measure the frequencies and 
 * debug capabilities. 
 * The data is read out via a serial interfaces, which is
 * clocked from the RP2040 and uses a manchester coding.
 *
 * -----------------------------------------------------------------------------
 *
 * Copyright (C) 2023 Gerrit Grutzeck (g.grutzeck@gfg-development.de)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * -----------------------------------------------------------------------------
 *
 * Author   : Gerrit Grutzeck g.grutzeck@gfg-development.de
 * File     : tt_um_gfg_development_tros.v
 * Create   : Oct 13, 2023
 * Revise   : Oct 26, 2023
 * Revision : 1.1
 *
 * -----------------------------------------------------------------------------
 */
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
    wire latch_counter          = ui_in[0];
    wire ctr_reset              = ui_in[1];
    wire send_counter           = ui_in[2];
    wire [1:0] counter_select   = ui_in[4:3];
    wire sync_select            = ui_in[5];
    wire [1:0] div_select       = ui_in[7:6];
    wire [7:0] voltage_control  = uio_in;

    // use bidirectionals as input
    assign uio_oe       = 8'b00000000;
    assign uio_out      = 8'b11111111;

    assign uo_out[3:0]  = 4'b1111;

    assign uo_out[4]    = data_stream;
    assign uo_out[5]    = inv_sub_div_clk;
    assign uo_out[6]    = nand4_cap_div_clk;
    assign uo_out[7]    = nand4_div_clk;


    /*
     * Implement the NAND4 ring oscillator
     */
    wire nand4_clk;
    wire nand4_div_clk;
    wire [COUNTER_LENGTH-1:0] nand4_cycle_count;

    ros_nand4 #(.STAGES(67)) ros_nand4(
        .ena(ena), 
        .clk(nand4_clk)
    );

    fmeasurment #(.LENGTH(COUNTER_LENGTH)) fmeasurment_nand4_ros(
        .clk(nand4_clk), 
        .latch_counter(latch_counter),
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

    ros_nand4_cap #(.STAGES(35), .NR_CAPS(8)) ros_nand4_cap(
        .ena(ena), 
        .clk(nand4_cap_clk)
    );

    fmeasurment #(.LENGTH(COUNTER_LENGTH)) fmeasurment_nand4_cap_ros(
        .clk(nand4_cap_clk), 
        .latch_counter(latch_counter),
        .div_select(div_select),
        .reset(ctr_reset),
        .sync_select(sync_select),
        .cycle_count(nand4_cap_cycle_count),
        .divided_clk(nand4_cap_div_clk)
    );


    /*
     * Implement a tristate inverter ring oscillator with sub threashold
     */
    wire inv_sub_clk;
    wire inv_sub_div_clk;
    wire [COUNTER_LENGTH-1:0] inv_sub_cycle_count;

    ros_einv_sub #(.STAGES(6)) ros_einv_sub(
        .ena(ena), 
        .voltage_control(voltage_control),
        .clk(inv_sub_clk)
    );

    fmeasurment #(.LENGTH(COUNTER_LENGTH)) fmeasurment_einv_sub_ros(
        .clk(inv_sub_clk), 
        .latch_counter(latch_counter),
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
    reg [2:0] send_counter_syncs;
    reg [2:0] ena_syncs;

    assign data_stream = shift_register[COUNTER_LENGTH+3] ^ clk;

    always @(posedge clk) begin
        send_counter_syncs                  <= {send_counter_syncs[1:0], send_counter};
        ena_syncs                           <= {ena_syncs[1:0], ena};
        if (ena_syncs[2]) begin
            if (send_counter_syncs[2] == 1) begin
                case (counter_select)
                    2'b00: shift_register   <= {4'b1010, nand4_cycle_count}; 
                    2'b01: shift_register   <= {4'b1010, nand4_cap_cycle_count};
                    2'b10: shift_register   <= {4'b1010, inv_sub_cycle_count};
                    2'b11: shift_register   <= 0;
                endcase
            end else begin
                shift_register <= {shift_register[COUNTER_LENGTH+2:0], 1'b0};
            end
        end
    end
endmodule
