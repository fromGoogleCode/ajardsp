module top(
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

   wire [15:0]   address;


   reg           BTN_NORTH_p0;
   reg           BTN_EAST_p0;
   reg           BTN_SOUTH_p0;

   reg           BTN_NORTH_p1;
   reg           BTN_EAST_p1;
   reg           BTN_SOUTH_p1;


   always @(posedge clk)
     begin
        if (rst)
          begin
             LED <= 0;
          end
        else
          begin
             BTN_NORTH_p0 <= BTN_NORTH;
             BTN_EAST_p0  <= BTN_EAST;
             BTN_SOUTH_p0 <= BTN_SOUTH;
             BTN_NORTH_p1 <= BTN_NORTH_p0;
             BTN_EAST_p1  <= BTN_EAST_p0;
             BTN_SOUTH_p1 <= BTN_SOUTH_p0;

             if (rd && ack)
               begin
                  LED <= read_data[7:0];
               end
          end
     end

   assign SD_CS = 0;

   assign SD_LDM = 0;
   assign SD_UDM = 0;

   assign SD_CK_P = ddr_clk;
   assign SD_CK_N = ddr_clk_n;

   assign  ddr_clk_fb = SD_CK_FB;

   assign address = BTN_NORTH_p1 ? 16'habcd : 16'h1234;

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
	        .CLKFB(clk_fb_),
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



   always @(posedge clk)
     begin
        if (rst)
          begin
             rd <= 0;
             wr <= 0;
          end
        else
          begin
             if (ack)
               rd <= 0;
             else if (BTN_EAST_p1)
               rd <= 1;

             if (ack)
               wr <= 0;
             else if (BTN_SOUTH_p1)
               wr <= 1;
          end
     end

   wb_sdram_ctrl wb_sdram_ctrl_0(.wb_clk_i(clk),
                                 .wb_rst_i(rst),

                                 .wb_adr_i({16'h0123, address}),
                                 .wb_dat_i({SW, SW, SW, SW, SW, SW, SW, SW}),
                                 .wb_dat_o(read_data),

                                 .wb_stb_i(rd | wr),
                                 .wb_we_i(wr),
                                 .wb_sel_i(2'b11),
                                 .wb_ack_o(ack),

                                 .clk(clk),
                                 .clk_n(clk_n),

                                 .ddr_clk(ddr_clk),
                                 .ddr_clk_n(ddr_clk_n),

                                 .ddr_cke(SD_CKE),
                                 .ddr_cmd({SD_RAS, SD_CAS, SD_WE}),
                                 .ddr_data(SD_DQ),
                                 .ddr_dqs({SD_UDQS, SD_LDQS}),
                                 .ddr_addr(SD_A),
                                 .ddr_ba(SD_BA)
                                 );

endmodule
