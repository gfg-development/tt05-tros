/* A simple ring oscillator based on NAND4 gates.  
 * An enable singal allows to control the state the oscillator.
 * The NAND4 is used to have more gate capacity and therefore a lower 
 * frequency. 
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
 * File     : ros_nand4.v
 * Create   : Oct 13, 2023
 * Revise   : Oct 26, 2023
 * Revision : 1.1
 *
 * -----------------------------------------------------------------------------
 */
`default_nettype none

module ros_nand4 #(parameter STAGES = 33) (
    input  wire       ena,      // will go high when the design is enabled
    output wire       clk       // clock
);
    (* keep = "true" *) wire [STAGES - 1:0] nets_notouch_;

    // use an inverter to buffer the signal
    assign clk = !nets_notouch_[0];

    // first stage of the oscillator, with the enable signal
    (* keep = "true" *) sky130_fd_sc_hd__nand4_1 fstage (
        .A(ena), 
        .B(nets_notouch_[STAGES - 1]), 
        .C(nets_notouch_[STAGES - 1]),
        .D(nets_notouch_[STAGES - 1]), 
        .Y(nets_notouch_[0])
    );

    // other stages of the oscillator
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin
            (* keep = "true" *) sky130_fd_sc_hd__nand4_1 stage (
                .A(nets_notouch_[i - 1]), 
                .B(nets_notouch_[i - 1]), 
                .C(nets_notouch_[i - 1]), 
                .D(nets_notouch_[i - 1]), 
                .Y(nets_notouch_[i])
            );
        end
    endgenerate
endmodule
