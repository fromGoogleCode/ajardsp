module soc_top(
               CLK_50_MHZ,
               RST,

               SD_A,
               SD_DQ,
               SD_BA,
               SD_CAS,
               SD_CK_N,
               SD_CK_P,
               SD_CKE,
               SD_CS,
               SD_LDM,
               SD_LDQS,
               SD_RAS,
               SD_UDM,
               SD_UDQS,
               SD_WE,
               SD_CK_FB,

               SW,
               BTN_NORTH,
               BTN_EAST,
               BTN_SOUTH,
               LED
               );

   input CLK_50_MHZ;
   input RST;

   input [3:0] SW;
   input       BTN_NORTH;
   input       BTN_EAST;
   input       BTN_SOUTH;
/*   input       BTN_WEST; */
   output reg [7:0] LED;

   output [12:0] SD_A;
   inout [15:0]  SD_DQ;
   output [1:0]  SD_BA;
   output        SD_CAS;
   output        SD_CK_N;
   output        SD_CK_P;
   output        SD_CKE;
   output        SD_CS;
   output        SD_LDM;

   output        SD_LDQS;
   output        SD_RAS;
   output        SD_UDM;
   output        SD_UDQS;
   output        SD_WE;
   input         SD_CK_FB;

   reg           rd, wr;

   wire          clk_fb;
   wire          clk_fb_;

   wire          locked_0, locked_1;
   wire          PRE_CLK_100_MHZ;
   wire          CLK_100_MHZ;
   wire [31:0]   read_data;
   wire          ack;

   wire          ddr_clk, ddr_clk_n, ddr_clk_fb;

   wire          rst;
   wire          clk;

   assign SD_CS = 0;

   assign SD_CK_P = ddr_clk;
   assign SD_CK_N = ddr_clk_n;

   assign  ddr_clk_fb = SD_CK_FB;

   assign rst = RST || !locked_0 || !locked_1;

      DCM_SP dcm_0(.CLK0(clk_fb_),
                .CLK90(),
                .CLK180(),
                .CLK270(),
                .CLK2X(PRE_CLK_100_MHZ),

                .CLK2X180(),
	        .CLKDV(),
                .CLKFX(),
                .CLKFX180(),
                .LOCKED(locked_0),
                .PSDONE(),
                .STATUS(),
	        .CLKFB(clk_fb),
                .CLKIN(CLK_50_MHZ),
                .DSSEN(),
                .PSCLK(),
                .PSEN(),
                .PSINCDEC(),
                .RST(RST));

   BUFG bufg0(.I(clk_fb_), .O(clk_fb));

   DCM_SP dcm_1(.CLK0(ddr_clk),
                .CLK90(clk_n),
                .CLK180(ddr_clk_n),
                .CLK270(clk),
                .CLK2X(),
                .CLK2X180(),
	        .CLKDV(),
                .CLKFX(),
                .CLKFX180(),
                .LOCKED(locked_1),
                .PSDONE(),
                .STATUS(),
	        .CLKFB(ddr_clk_fb),
                .CLKIN(PRE_CLK_100_MHZ),
                .DSSEN(),
                .PSCLK(),
                .PSEN(),
                .PSINCDEC(),
                .RST(RST | !locked_0));


   wire        wb_ack_i_w;
   wire [31:0] wb_dat_o_w;
   wire [31:0] wb_dat_i_w;
   wire [31:0] wb_adr_o_w;
   wire        wb_cyc_o_w;
   wire [3:0]  wb_sel_o_w;
   wire        wb_stb_o_w;
   wire        wb_we_o_w;

   wb_ajardsp wb_ajardsp_0(.clk(clk),
                           .rst(rst),

                           /* Wishbone interface */
                           .wb_clk_i(clk),
                           .wb_rst_i(rst),

                           .wb_ack_i(wb_ack_i_w),
                           .wb_dat_o(wb_dat_o_w),
                           .wb_dat_i(wb_dat_i_w),
                           .wb_adr_o(wb_adr_o_w),

                           .wb_cyc_o(wb_cyc_o_w),
                           .wb_sel_o(wb_sel_o_w),
                           .wb_stb_o(wb_stb_o_w),
                           .wb_we_o(wb_we_o_w)
                           );


   wb_sdram_ctrl wb_sdram_ctrl_0(.wb_clk_i(clk),
                                 .wb_rst_i(rst),

                                 .wb_adr_i(wb_adr_o_w),
                                 .wb_dat_i(wb_dat_o_w),
                                 .wb_dat_o(wb_dat_i_w),

                                 .wb_cyc_i(wb_cyc_o_w),
                                 .wb_stb_i(wb_stb_o_w),
                                 .wb_we_i(wb_we_o_w),
                                 .wb_sel_i(wb_sel_o_w),
                                 .wb_ack_o(wb_ack_i_w),

                                 .clk(clk),
                                 .clk_n(clk_n),

                                 .ddr_clk(ddr_clk),
                                 .ddr_clk_n(ddr_clk_n),

                                 .ddr_cke(SD_CKE),
                                 .ddr_cmd({SD_RAS, SD_CAS, SD_WE}),
                                 .ddr_data(SD_DQ),
                                 .ddr_dm({SD_UDM, SD_LDM}),
                                 .ddr_dqs({SD_UDQS, SD_LDQS}),
                                 .ddr_addr(SD_A),
                                 .ddr_ba(SD_BA)
                                 );

endmodule
