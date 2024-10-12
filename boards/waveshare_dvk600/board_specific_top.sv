`include "config.svh"
`include "lab_specific_board_config.svh"

//----------------------------------------------------------------------------

`ifdef FORCE_NO_INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
    `undef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE
`endif

`define IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION

//----------------------------------------------------------------------------

module board_specific_top
# (
    parameter clk_mhz       = 50,
              pixel_mhz     = 25,

              w_key         = 0,
              w_sw          = 0,
              w_led         = 0,
              w_digit       = 0,
              w_gpio        = 5,

              w_h_left      = 54,
              w_h_right     = 54,
              w_h_up        = 32,
              w_h_down      = 32,

              w_red         = 4,
              w_green       = 4,
              w_blue        = 4,

              screen_width  = 640,
              screen_height = 480,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                   CLK,
    input                   RESET,

    output [w_led   - 1:0]  LED,

    inout  [w_h_left   :1]  H_LEFT,
    inout  [w_h_right  :1]  H_RIGHT,
    inout  [w_h_up     :1]  H_UP,
    inout  [w_h_down   :1]  H_DOWN
);

    //------------------------------------------------------------------------

    localparam w_tm_key   = 8,
               w_tm_led   = 8,
               w_tm_digit = 8;

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        localparam w_lab_key   = w_tm_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_tm_led,
                   w_lab_digit = w_tm_digit;

    `else                   // TM1638 module is not connected

        localparam w_lab_key   = w_key,
                   w_lab_sw    = w_sw,
                   w_lab_led   = w_led,
                   w_lab_digit = w_digit;

    `endif

    //------------------------------------------------------------------------

    wire                      clk   =   CLK;
    wire                      rst;

    wire  [w_gpio      - 1:0] gpio;

    wire  [              7:0] abcdefgh;

    wire  [w_x         - 1:0] x;
    wire  [w_y         - 1:0] y;

    wire  [w_red       - 1:0] red;
    wire  [w_green     - 1:0] green;
    wire  [w_blue      - 1:0] blue;

    wire  [             23:0] mic;
    wire  [             15:0] sound;

    wire  [w_tm_key    - 1:0] tm_key;
    wire  [w_tm_led    - 1:0] tm_led;
    wire  [w_tm_digit  - 1:0] tm_digit;

    logic [w_lab_key   - 1:0] lab_key;
    wire  [w_lab_led   - 1:0] lab_led;
    wire  [w_lab_digit - 1:0] lab_digit;

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

        assign rst      = tm_key [w_tm_key - 1];
        assign lab_key  = tm_key [w_tm_key - 1:0];

        assign tm_led   = lab_led;
        assign tm_digit = lab_digit;

        assign LED      = w_led' (~ lab_led);

    `elsif IMITATE_RESET_ON_POWER_UP_FOR_TWO_BUTTON_CONFIGURATION

        imitate_reset_on_power_up i_imitate_reset_on_power_up (clk, rst);

        assign lab_key  = ~ KEY [w_key - 1:0];
        assign LED      = ~ lab_led;

    `else  // TM1638 module is not connected and no reset initation

        assign rst      = ~ RESET;

    `endif

    assign gpio = H_DOWN [1 +: w_gpio];

    //------------------------------------------------------------------------

    wire slow_clk;

    slow_clk_gen # (.fast_clk_mhz (clk_mhz), .slow_clk_hz (1))
    i_slow_clk_gen (.slow_clk (slow_clk), .*);

    //------------------------------------------------------------------------

    lab_top
     # (
        .clk_mhz       ( clk_mhz       ),

        .w_key         ( w_lab_key     ),  // The last key is used for a reset
        .w_sw          ( w_lab_key     ),
        .w_led         ( w_lab_led     ),
        .w_digit       ( w_lab_digit   ),
        .w_gpio        ( w_gpio        ),

        .screen_width  ( screen_width  ),
        .screen_height ( screen_height ),

        .w_red         ( w_red         ),
        .w_green       ( w_green       ),
        .w_blue        ( w_blue        )
    )
    i_lab_top
    (
        .clk           ( clk           ),
        .slow_clk      ( slow_clk      ),
        .rst           ( rst           ),

        .key           ( lab_key       ),
        .sw            ( lab_key       ),

        .led           ( lab_led       ),

        .abcdefgh      ( abcdefgh      ),
        .digit         ( lab_digit     ),

        .x             ( x             ),
        .y             ( y             ),

        .red           ( red           ),
        .green         ( green         ),
        .blue          ( blue          ),

        .uart_rx       (        ),
        .uart_tx       (        ),

        .mic           ( mic           ),
        .sound         ( sound         ),
        .gpio          ( gpio          )
    );

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

    wire [$left (abcdefgh):0] hgfedcba;

    generate
        genvar i;

        for (i = 0; i < $bits (abcdefgh); i ++)
        begin : abc
            assign hgfedcba [i] = abcdefgh [$left (abcdefgh) - i];
        end
    endgenerate

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_TM1638_BOARD_CONTROLLER_MODULE

    tm1638_board_controller
    # (
        .clk_mhz  ( clk_mhz        ),
        .w_digit  ( w_tm_digit     )
    )
    i_tm1638
    (
        .clk      ( clk            ),
        .rst      ( rst            ),
        .hgfedcba ( hgfedcba       ),
        .digit    ( tm_digit       ),
        .ledr     ( tm_led         ),
        .keys     ( tm_key         ),
        .sio_data (        ),
        .sio_clk  (    ),
        .sio_stb  (  )
    );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_GRAPHICS_INTERFACE_MODULE

        wire [9:0] x10; assign x = x10;
        wire [9:0] y10; assign y = y10;

        vga
        # (
            .CLK_MHZ     ( clk_mhz   ),
            .PIXEL_MHZ   ( pixel_mhz )
        )
        i_vga
        (
            .clk         ( clk        ),
            .rst         ( rst        ),
            .hsync       (   ),
            .vsync       (   ),
            .display_on  (  ),
            .hpos        ( x10        ),
            .vpos        ( y10        ),
            .pixel_clk   (            )
        );

    `endif

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_MICROPHONE_INTERFACE_MODULE

            inmp441_mic_i2s_receiver
            # (
                .clk_mhz ( clk_mhz   )
            )
            i_microphone
            (
                .clk     ( clk       ),
                .rst     ( rst       ),
                .lr      (  ),
                .ws      (  ),
                .sck     (  ),
                .sd      (  ),
                .value   ( mic       )
            );

        `endif  // USE_INMP_441_MIC

    `endif  // INSTANTIATE_MICROPHONE_INTERFACE_MODULE

    //------------------------------------------------------------------------

    `ifdef INSTANTIATE_SOUND_OUTPUT_INTERFACE_MODULE

        i2s_audio_out
        # (
            .clk_mhz ( clk_mhz   )
        )
        inst_audio_out
        (
            .clk     ( clk       ),
            .reset   ( rst       ),
            .data_in ( sound     ),
            .mclk    (      ), 
            .bclk    (     ),  
            .lrclk   (     ),  
            .sdata   (  )   
        );                           

    `endif

endmodule
