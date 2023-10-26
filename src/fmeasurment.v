/* This is a simple component, that measures the frequency of
 * the clock relative to a reference signal (e.g. 1PPS). 
 * For debugging purporse a down divided clock is outputted. 
 * Furthermore it can be selected between a 2FF synchronized 
 * reference signal or an unsynchronized one.
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
 * File     : fmeasurement.v
 * Create   : Oct 13, 2023
 * Revise   : Oct 26, 2023
 * Revision : 1.1
 *
 * -----------------------------------------------------------------------------
 */

`default_nettype none

module fmeasurment #(parameter LENGTH = 20) (
    input  wire         clk,            // clock
    input  wire         latch_counter,  // latch the internal counter
    input  wire [1:0]   div_select,     // select which divider is used  
    input  wire         reset,          // reset counter to zero
    input  wire         sync_select,    // select if the gate is synchronized with two FFs
    output wire [LENGTH - 1:0] 
                        cycle_count,    // number of counted cycles
    output wire         divided_clk     // the divided clock, speed is selected with div_select
);
    reg [LENGTH - 1:0]  counts;
    
    // select divided clock
    reg                 selected_divided_clk;
    
    always @(counts or div_select) begin
        case (div_select)
            2'b00: selected_divided_clk = counts[1];
            2'b01: selected_divided_clk = counts[3];
            2'b10: selected_divided_clk = counts[5];
            2'b11: selected_divided_clk = counts[7];
        endcase
    end

    assign divided_clk = !selected_divided_clk;


    // select between 2FF synchronized latch signal and asynchron latch signal
    reg [2:0]   latch_counter_syncs;
    wire        latch_counter_final;

    assign latch_counter_final = sync_select ? latch_counter_syncs[2] : latch_counter;


    // counter and latch logic
    reg [LENGTH - 1:0] latched_cycle_count;
    reg [2:0]           reset_syncs;
    always @(posedge clk) begin
        latch_counter_syncs     <= {latch_counter_syncs[1:0], latch_counter};
        reset_syncs             <= {reset_syncs[1:0], reset};
        if (reset_syncs[2]) begin
            counts              <= 0;
        end else begin
            counts              <= counts + 1;
        end

        if (latch_counter_final) begin
            latched_cycle_count <= counts;
        end
    end

    assign cycle_count = latched_cycle_count;
endmodule
