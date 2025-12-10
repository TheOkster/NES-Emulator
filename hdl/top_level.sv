`timescale 1ns / 1ps
`default_nettype none 
 
module top_level(
        input wire [15:0] sw, 
        input wire [3:0] btn,
        input wire clk_100mhz,
        output logic [15:0] led, 
        output logic [2:0] rgb0, 
        output logic [2:0] rgb1, 
        output logic [3:0] ss0_an,
        output logic [3:0] ss1_an,
        output logic [6:0] ss0_c,
        output logic [6:0] ss1_c,
        output logic [2:0] pmoda,

        // UART
        input wire              uart_rxd, // UART computer->FPGA
        output logic            uart_txd, // UART FPGA->computer
                // hdmi port
        output logic [2:0]  hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
        output logic [2:0]  hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
        output logic        hdmi_clk_p, hdmi_clk_n //differential hdmi clock
    );
    logic [23:0] pixel_out;
    // Pattern Table Variables for debugging purpose
    // logic patt_table_ind;
    logic [7:0] patt_table_x;
    logic [7:0] patt_table_y;
    logic [23:0] patt_table_pix;
    logic patt_table_out_valid;
    // logic [23:0] frame_buff_raw;
    logic clk_100_passthrough;
    logic clk_pixel;
    logic          clk_5x;
    logic sys_rst;
    assign sys_rst = btn[0];

    cw_hdmi_clk_wiz wizard_hdmi(
        .sysclk(clk_100_passthrough),
        .clk_pixel(clk_pixel),
        .clk_tmds(clk_5x),
        .reset(0)
    );

    logic clk_nes;
    nes_clk_wiz wizard_nes(
        .clk_100mhz(clk_100_passthrough),
        .clk_nes(clk_nes),
        .reset(sys_rst),
        .locked(0)
    );



    logic clk_100mhz_ibuff;
    IBUF clk_ibuf (.I(clk_100mhz), .O(clk_100mhz_ibuff));
    BUFG clk_bufg (.I(clk_100mhz_ibuff), .O(clk_100_passthrough));

    logic [15:0] cpu_addr;
    logic [7:0] cpu_dout;
    logic [7:0] cpu_din;
    logic cpu_din_valid;
    logic cpu_rw;


    logic [1:0] counter_4 = 0;   
    logic [3:0] counter_12 = 0; 

    logic cpu_nes_trig;
    logic ppu_nes_trig;

    always_ff @(posedge clk_nes) begin
        counter_4 <= counter_4 + 1;
        if (counter_12 == 11)
            counter_12 <= 0;
        else
            counter_12 <= counter_12 + 1;
    end

    assign ppu_nes_trig  = (counter_4 == 3); 
    assign cpu_nes_trig = (counter_12 == 11);

    // clock domain
    logic cpu_sync0_trig, cpu_sync1_trig;
    logic ppu_sync0_trig, ppu_sync1_trig;

    always_ff @(posedge clk_100_passthrough) begin
        cpu_sync0_trig <= cpu_nes_trig;
        cpu_sync1_trig <= cpu_sync0_trig;
        ppu_sync0_trig <= ppu_nes_trig;
        ppu_sync1_trig <= ppu_sync0_trig;
    end
    logic ppu_clk_trig, cpu_clk_trig;
assign cpu_clk_trig = cpu_sync0_trig & ~cpu_sync1_trig; // TODO: the way the cpu clock works i can't do this actually so make
// this an actual clock
assign ppu_clk_trig = ppu_sync0_trig & ~ppu_sync1_trig; // now that i'm thinking about it, this isn't good for duty cycle reasons


    cpu my_cpu(
        .clk_slow(cpu_clk_trig),
        .clk_fast(clk_100_passthrough),
        .rst(sys_rst),

        .dout(cpu_dout),
        .addr(cpu_addr),
        .din(cpu_din),
        .din_valid(cpu_din_valid),
        .rw(cpu_rw),

        .irq(),
        .nmi(nmi),

        .audio_out()
    );

    logic [7:0] ppu_cpu_din;
    logic ppu_cpu_din_valid;
    logic nmi;
    ppu my_ppu(
        .clk(clk_100_passthrough),
        .rst(sys_rst),
        .cpu_dout(cpu_dout),
        .cpu_addr(cpu_addr),
        .cpu_din(ppu_cpu_din),
        .cpu_din_valid(ppu_cpu_din_valid),
        .pixel(pixel_out),
        .cpu_rw(cpu_rw),
        .is_cart_vertical(1),
        .ppu_clk_trig(ppu_clk_trig),
        .patt_table_x(patt_table_x),
        .patt_table_y(patt_table_y),
        .patt_table_pix(patt_table_pix),
        .patt_table_out_valid(patt_table_out_valid)
    );

    logic [7:0] cart_cpu_din;
    logic cart_cpu_din_valid;

    cartridge my_cartridge (
        .clk(clk_100_passthrough),
        .rst(sys_rst),
        .cpu_dout(cpu_dout),
        .cpu_addr(cpu_addr),
        .cpu_din(cart_cpu_din),
        .cpu_din_valid(cart_cpu_din_valid),
        .cpu_rw(cpu_rw),
        .ppu_dout(0), //TODO: change
        .ppu_addr(0), //TODO: change
        .ppu_din(0), //TODO: change
        .ppu_din_valid(0), //TODO: change
        .ppu_rw(0) //TODO: change
    );
    logic [7:0] cpu_mem_cpu_din;
    logic cpu_mem_cpu_din_valid;

    cpu_mem cpu_mem_man(
        .clk(clk_100_passthrough),
        .rst(sys_rst),
        .cpu_dout(cpu_dout),
        .cpu_addr(cpu_addr),
        .cpu_din(cpu_mem_cpu_din),
        .cpu_din_valid(cpu_mem_cpu_din_valid),
        .cpu_rw(cpu_rw)
    );

    logic uart_rx_buf0, uart_rx_buf1;
    always_ff @(posedge clk_100_passthrough) begin
        uart_rx_buf0 <= uart_rxd;
        uart_rx_buf1 <= uart_rx_buf0;
    end

    logic [7:0] controller_cpu_din;
    logic controller_cpu_din_valid;
    nes_controllers controllers (
        .sys_clk(clk_100_passthrough),
        .nes_clk(clk_nes),
        .rst(sys_rst),
        .uart_rx(uart_rx_buf1),
        .cpu_dout(cpu_dout),
        .cpu_addr(cpu_addr),
        .cpu_din(controller_cpu_din),
        .cpu_din_valid(controller_cpu_din_valid),
        .cpu_rw(cpu_rw)
    );
    
    assign cpu_din_valid = cart_cpu_din_valid || ppu_cpu_din_valid || cpu_mem_cpu_din_valid;
    assign cpu_din = cpu_mem_cpu_din_valid ? cpu_mem_cpu_din :
        cart_cpu_din_valid ? cart_cpu_din : 
        ppu_cpu_din_valid ? ppu_cpu_din : 
        0;

    logic [16:0] write_addr;
    assign write_addr = 256*patt_table_y+patt_table_x;


    logic           h_sync_hdmi;
    logic           v_sync_hdmi;
    logic [10:0]    h_count_hdmi;
    logic [9:0]     v_count_hdmi;
    logic           active_draw_hdmi;
    logic           new_frame_hdmi;
    logic [5:0]     frame_count_hdmi;
    logic sys_rst_pixel;
    
    assign sys_rst_pixel = 0; // for now
    // rgb output values
    // logic [7:0]     red,green,blue;
    video_sig_gen vsg(
        .pixel_clk(clk_pixel),
        .rst(sys_rst_pixel),
        .h_count(h_count_hdmi),
        .v_count(v_count_hdmi),
        .v_sync(v_sync_hdmi),
        .h_sync(h_sync_hdmi),
        .new_frame(new_frame_hdmi),
        .active_draw(active_draw_hdmi),
        .frame_count(frame_count_hdmi)
    );
    localparam FB_DEPTH = 256 * 240;
    localparam FB_SIZE = $clog2(FB_DEPTH);
    logic frame_buff_we = btn[1] ? patt_table_out_valid : 1;
    logic [23:0] frame_buff_in = btn[1] ? patt_table_pix : pixel_out;
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(24), //each entry in this memory is 24 bits for now, may be better to just store palette ram index tho and then convert here
        .RAM_DEPTH(FB_DEPTH))
    frame_buffer (
        .addra(write_addr), //pixels are stored using this math
        .clka(clk_100_passthrough), // set to ppu clk?
        .wea(frame_buff_we),
        .dina(frame_buff_in),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(), // update
        .douta(), //never read from this side
        .addrb(addrb),//transformed lookup pixel
        .dinb(16'b0),
        .clkb(clk_pixel),
        .web(1'b0),
        .enb(1'b1),
        .rstb(), // update
        .regceb(1'b1),
        .doutb(frame_buff_raw)
    );
    // 
    logic [23:0] frame_buff_raw; //data out of frame buffer (8-8-8)
    logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer
    logic good_addrb; //used to indicate within valid frame for scaling
    logic good_addrb_bufs [1:0]; //used to indicate within valid frame for scaling
 
    // if(btn[1])
    always_ff @(posedge clk_pixel)begin
        //default: delete:
        // addrb <= h_count_hdmi + 320*v_count_hdmi;
        // good_addrb <= (h_count_hdmi<320)&&(v_count_hdmi<180);
        //use structure below to do scaling
        addrb <= (h_count_hdmi / 3) + 256*(v_count_hdmi / 3); // yes, i'm aware division
        good_addrb <= (h_count_hdmi<256*3)&&(v_count_hdmi<240*3);
        good_addrb_bufs[0] <= good_addrb;
        good_addrb_bufs[1] <= good_addrb_bufs[0];
    end

    logic [7:0] fb_red, fb_green, fb_blue;
    logic [10:0]    h_count_hdmi_buffs[2:0];
    logic [9:0]     v_count_hdmi_buffs[2:0];


    logic           h_sync_hdmi_buffs [11:0];
    logic           v_sync_hdmi_buffs [11:0];  
    logic active_draw_buffs [2:0];
    logic new_frame_hdmi_buffs [2:0];

    always_ff @(posedge clk_pixel)begin

        h_count_hdmi_buffs[0] <= h_count_hdmi;
        v_count_hdmi_buffs[0] <= v_count_hdmi;

        h_sync_hdmi_buffs[0] <= h_sync_hdmi;
        v_sync_hdmi_buffs[0] <= v_sync_hdmi;
        active_draw_buffs[0] <= active_draw_hdmi;
        
        new_frame_hdmi_buffs[0] <=  new_frame_hdmi;

        for (int i=1; i<3; i = i+1) begin
            h_count_hdmi_buffs[i] <= h_count_hdmi_buffs[i-1];
            v_count_hdmi_buffs[i] <= v_count_hdmi_buffs[i-1];
        end
        for (int i=1; i<3; i = i+1) begin
            h_sync_hdmi_buffs[i] <= h_sync_hdmi_buffs[i-1];
            v_sync_hdmi_buffs[i] <= v_sync_hdmi_buffs[i-1];
            active_draw_buffs[i] <= active_draw_buffs[i-1];
        end 
        for (int i=1; i<3; i = i+1) begin
            new_frame_hdmi_buffs[i] <= new_frame_hdmi_buffs[i-1];
        end 
    end

    always_ff @(posedge clk_pixel)begin
        fb_red <= (good_addrb_bufs[1])?{frame_buff_raw[23:16]}:8'b0;
        fb_green <= (good_addrb_bufs[1])?{frame_buff_raw[15:8]}:8'b0;
        fb_blue <= (good_addrb_bufs[1])?{frame_buff_raw[7:0]}:8'b0;
    end

    // HDMI Output

    logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
    logic       tmds_signal [2:0]; //output of each TMDS serializer!

    tmds_encoder tmds_red(
        .clk(clk_pixel),
        .rst(sys_rst_pixel),
        .video_data(fb_red),
        .control(2'b0),
        .video_enable(active_draw_buffs[2]),
        .tmds(tmds_10b[2])
    );
    tmds_encoder tmds_green(
        .clk(clk_pixel),
        .rst(sys_rst_pixel),
        .video_data(fb_green),
        .control(2'b0),
        .video_enable(active_draw_buffs[2]),
        .tmds(tmds_10b[1])
    );
    tmds_encoder tmds_blue(
        .clk(clk_pixel),
        .rst(sys_rst_pixel),
        .video_data(fb_blue),
        .control({v_sync_hdmi_buffs[2],h_sync_hdmi_buffs[2]}),
        .video_enable(active_draw_buffs[2]),
        .tmds(tmds_10b[0])
    );


    //three tmds_serializers (blue, green, red):
    //MISSING: two more serializers for the green and blue tmds signals.
    tmds_serializer red_ser(
        .clk_pixel(clk_pixel),
        .clk_5x(clk_5x),
        .rst(sys_rst_pixel),
        .tmds_in(tmds_10b[2]),
        .tmds_out(tmds_signal[2])
    );
    tmds_serializer green_ser(
        .clk_pixel(clk_pixel),
        .clk_5x(clk_5x),
        .rst(sys_rst_pixel),
        .tmds_in(tmds_10b[1]),
        .tmds_out(tmds_signal[1])
    );
    tmds_serializer blue_ser(
        .clk_pixel(clk_pixel),
        .clk_5x(clk_5x),
        .rst(sys_rst_pixel),
        .tmds_in(tmds_10b[0]),
        .tmds_out(tmds_signal[0])
    );

    //output buffers generating differential signals:
    //three for the r,g,b signals and one that is at the pixel clock rate
    //the HDMI receivers use recover logic coupled with the control signals asserted
    //during blanking and sync periods to synchronize their faster bit clocks off
    //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
    //the slower 74.25 MHz clock)
    OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));

endmodule // top_level
`default_nettype wire