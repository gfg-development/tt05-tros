/* A ring oscillator based on tri-state inverters.
 * An enable singal allows to control the state the oscillator.
 * With a sub-threshold voltage the frequency of the oscillator can
 * be tuned. 
 * To ensure, that the signal quality does not suffer to much, there
 * are standard inverters in between the tri-state inverters.
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
 * File     : ros_einv_sub.v
 * Create   : Oct 13, 2023
 * Revise   : Oct 26, 2023
 * Revision : 1.1
 *
 * -----------------------------------------------------------------------------
 */
`default_nettype none

module ros_einv_sub #(parameter STAGES = 3) (
    input  wire       ena,              // will go high when the design is enabled
    input  wire [7:0] voltage_control,  // control the sub-threshold voltage
    output wire       clk               // clock
);
    genvar i;
    genvar j;
    
    (* keep = "true" *) wire [4 * STAGES:0] nets_notouch_;
    (* keep = "true" *) wire sub_voltage_notouch_;

    assign clk = !nets_notouch_[0];

    // generation of the sub-thresold voltage
    /*generate
        // generate four sub-thresold voltage generators
        for (i = 0; i < 4; i++) begin
            (* keep = "true" *) sky130_fd_sc_hd__einvp_1 sub_generator (
                .A(sub_voltage_notouch_),
                .TE(voltage_control[4 + i] & ena),
                .Z(sub_voltage_notouch_)
            );
        end
        
        // generate two up and down pull stages
        for (i = 0; i < 2; i++) begin
            (* keep = "true" *) sky130_fd_sc_hd__einvp_1 down (
                .A(1'b1),
                .TE(voltage_control[i] & ena),
                .Z(sub_voltage_notouch_)
            );

            (* keep = "true" *) sky130_fd_sc_hd__einvp_1 up (
                .A(1'b0),
                .TE(voltage_control[i] & ena),
                .Z(sub_voltage_notouch_)
            );
        end
    endgenerate*/
    (* keep = "true" *) sky130_fd_sc_hd__einvp_1 sub_generator (
        .A(sub_voltage_notouch_),
        .TE(ena),
        .Z(sub_voltage_notouch_)
    );
    
    // first stage of the oscillator, with the enable signal
    (* keep = "true" *) sky130_fd_sc_hd__nand2_1 fstage (
        .A(nets_notouch_[4 * STAGES]), 
        .B(ena), 
        .Y(nets_notouch_[0])
    );

    // other stages of the oscillator
    generate
        for (i = 0; i < STAGES; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
                (* keep = "true" *) sky130_fd_sc_hd__einvp_1 tristage (
                    .A(nets_notouch_[4 * i + j]), 
                    .TE(sub_voltage_notouch_), 
                    .Z(nets_notouch_[4 * i + j + 1])
                );
            end
            (* keep = "true" *) sky130_fd_sc_hd__inv_1 stage (
                .A(nets_notouch_[4 * i + 3]), 
                .Y(nets_notouch_[4 * i + 4])
            );
        end
    endgenerate
endmodule
