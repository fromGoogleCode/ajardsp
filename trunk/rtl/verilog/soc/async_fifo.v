module async_fifo(rst,

                  wclk,
                  wdata,
                  wen,
                  wfull,

                  rclk,
                  rdata,
                  ren,
                  rempty);

   input rst;

   input wclk, wen;
   output wfull;
   input [35:0] wdata;

   input rclk, ren;
   output rempty;
   output [35:0] rdata;

   parameter AW = 9;

   wire [AW-1:0]  raddr_gray, waddr_gray;
   wire           empty, full, equal;

   reg [1:0]     empty_pipe, full_pipe;
   reg           dir, dirclr, dirset;
   wire          dirclr_;

   assign rempty = empty_pipe[1];
   assign wfull  = full_pipe[1];

   assign equal = raddr_gray == waddr_gray ? 1 : 0;
   assign empty = equal & ~dir;
   assign full  = equal &  dir;

   /* dir = 1 -> going full, dir = 0 -> going empty */

   always @(raddr_gray or waddr_gray)
     begin
        case ({waddr_gray[AW-1:AW-2], raddr_gray[AW-1:AW-2]})
          4'b0001: dirset = 1;
          4'b0111: dirset = 1;
          4'b1110: dirset = 1;
          4'b1000: dirset = 1;
          default: dirset = 0;
        endcase
     end

   always @(raddr_gray or waddr_gray)
     begin
        case ({waddr_gray[AW-1:AW-2], raddr_gray[AW-1:AW-2]})
          4'b0100: dirclr = 1;
          4'b1101: dirclr = 1;
          4'b1011: dirclr = 1;
          4'b0010: dirclr = 1;
          default: dirclr = 0;
        endcase
     end

   assign dirclr_ = dirclr | rst;

   always @(posedge dirclr_ or posedge dirset)
     begin
        if (dirclr_) dir = 0;
        else if (dirset) dir = 1;
     end

   always @(posedge rclk or posedge empty)
     begin
        if (empty)
          begin
             empty_pipe <= 2'b11;
          end
        else
          begin
             empty_pipe[1] <= empty_pipe[0];
             empty_pipe[0] <= empty;
          end
     end

   always @(posedge wclk or posedge full or posedge rst)
     begin
        if (rst)
          begin
             full_pipe <= 2'b00;
          end
        else if (full)
          begin
             full_pipe <= 2'b11;
          end
        else
          begin
             full_pipe[1] <= full_pipe[0];
             full_pipe[0] <= full;
          end
     end

   gray_counter rgray(.rst(rst), .clk(rclk),
                      .inc(ren), .out(raddr_gray));

   gray_counter wgray(.rst(rst), .clk(wclk),
                      .inc(wen), .out(waddr_gray));

   RAMB16_S36_S36 aram(.DOA(/**/),
                       .DOB(rdata[31:0]),
                       .DOPA(/**/),
                       .DOPB(rdata[35:32]),
                       .ADDRA(waddr_gray),
                       .ADDRB(raddr_gray),
                       .CLKA(wclk),
                       .CLKB(rclk),
                       .DIA(wdata[31:0]),
                       .DIB(/**/),
                       .DIPA(wdata[35:32]),
                       .DIPB(/**/),
                       .ENA(1'b1),
                       .ENB(1'b1),
                       .SSRA(rst),
                       .SSRB(rst),
                       .WEA(wen),
                       .WEB(1'b0));

endmodule

module gray_counter(rst,
                    clk,
                    inc,
                    out);

   parameter WIDTH = 9;

   input rst, clk, inc;
   output [WIDTH-1:0] out;

   reg [WIDTH-1:0]    bin_r, gray_r;

   wire [WIDTH-1:0]   sum;

   assign sum = bin_r + inc;
   assign out = gray_r;

   always @(posedge clk or posedge rst)
     begin
        if (rst)
          begin
             bin_r  <= 0;
             gray_r <= 0;
          end
        else
          begin
             bin_r  <= sum;
             gray_r <= (sum >> 1) ^ sum;
          end
     end

endmodule
