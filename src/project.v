/*
 * "XzT" VGA demo (1x1 tile edition, 6 scenes). No CPU, no GPU, no RAM!
 * Racing the beam, straight to VGA 640x480@60Hz.
 *
 * Remix of "Drop" by Renaldas Zioma, Erik Hemming and Matthias Kampa
 *   https://github.com/rejunity/tt08-vga-drop
 * Code is based on the VGA examples by Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_XzT07_VGAPLAY(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  // TinyVGA PMOD https://github.com/mole99/tiny-vga
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused_ok = &{ena, ui_in, uio_in};

  wire [9:0] x;
  wire [9:0] y;
  wire video_active;
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
  );

  // ---------------------------------------------------------------
  // Tiempo: 6 escenas de 128 cuadros (~2 s cada una)
  // ---------------------------------------------------------------
  reg [6:0] frame;   // cuadro dentro de la escena
  reg [2:0] part;    // escena 0..5
  always @(posedge clk) begin
    if (~rst_n) begin
      frame <= 0;
      part  <= 0;
    end else if (x == 0 && y == 0) begin
      frame <= frame + 1;
      if (frame == 7'd127)
        part <= (part == 3'd5) ? 3'd0 : part + 1;
    end
  end

  wire [7:0] t    = {part[0], frame};
  wire       beat = frame[4:2] == 3'd0;   // destello cada 32 cuadros

  // ---------------------------------------------------------------
  // Coordenadas centradas en (320,240)
  // ---------------------------------------------------------------
  wire [9:0] p_x = x - 10'd320;
  wire [9:0] p_y = y - 10'd240;
  wire [8:0] ax  = p_x[9] ? ~p_x[8:0] : p_x[8:0];   // |x| (aprox. en complemento a 1)
  wire [8:0] ay  = p_y[9] ? ~p_y[8:0] : p_y[8:0];   // |y|
  wire [8:0] cheb = (ax > ay) ? ax : ay;            // cuadrados
  wire [8:0] manh = ax + ay;                        // rombos

  // r ~ (x/8)^2 + (y/8)^2 de forma incremental: (q+1)^2 = q^2 + 2q + 1
  // Bloques de 8x8 pixeles: menos bits, menos area (look retro).
  wire [6:0] qx = p_x[9:3];
  wire [6:0] qy = p_y[9:3];
  reg [10:0] sx;   // (x/8)^2, max 40^2
  reg [9:0]  sy;   // (y/8)^2, max 30^2
  always @(posedge clk) begin
    if (x == 10'd799)
      sx <= 11'd1600;                                  // 40^2 al inicio de linea
    else if (x[2:0] == 3'd7)
      sx <= sx + {{3{qx[6]}}, qx, 1'b1};

    if (x == 10'd799) begin
      if (y == 10'd524)
        sy <= 10'd900;                                 // 30^2 al inicio de cuadro
      else if (y[2:0] == 3'd7)
        sy <= sy + {{2{qy[6]}}, qy, 1'b1};
    end
  end
  wire [10:0] r = sx + {1'b0, sy};

  // ---------------------------------------------------------------
  // Titulo "XzT" (celdas de 128x128 en x = 128..511, y = 176..303)
  // ---------------------------------------------------------------
  wire [9:0] ty = y - 10'd176;
  wire [6:0] lx = x[6:0];
  wire [6:0] ly = ty[6:0];
  wire [7:0] s  = lx + ly;                 // diagonal  /
  wire [7:0] d  = lx - ly + 8'd12;         // diagonal  \  (|lx-ly| < 12  <=>  d < 24)
  wire in_x = (lx >= 16 && lx < 112 && ly >= 16 && ly < 112);
  wire g_x  = in_x && (d < 8'd24 || (s > 8'd116 && s < 8'd140));
  wire g_z  = (lx >= 32 && lx < 96 && ly >= 48 && ly < 112) &&
              (ly < 60 || ly >= 100 || (s > 8'd133 && s < 8'd155));
  wire g_t  = (ly >= 16 && ly < 112) && ((lx >= 16 && lx < 112 && ly < 32) || (lx >= 52 && lx < 76));
  wire title = (ty[9:7] == 3'd0) &&
               ((x[9:7] == 3'd1 && g_x) || (x[9:7] == 3'd2 && g_z) || (x[9:7] == 3'd3 && g_t));

  wire [5:0] title_rgb = (ly < 7'd48) ? 6'b11_11_11 :   // blanco
                         (ly < 7'd80) ? 6'b01_11_11 :   // cian claro
                                        6'b11_01_11;    // rosa

  // ---------------------------------------------------------------
  // Efectos
  // 0: XzT + cuadrados   1: XOR        2: ondas
  // 3: rombos            4: barras     5: XzT + ondas con destello
  // ---------------------------------------------------------------
  wire [7:0] squares = cheb[7:0] - {t[6:0], 1'b0};
  wire [7:0] xortex  = (x[7:0] + t) ^ y[7:0];
  wire [7:0] ripple  = r[7:0] - {t[5:0], 2'b00};
  wire [7:0] diamond = manh[7:0] + {t[6:0], 1'b0};

  // barras de cobre: onda triangular sobre y + t
  wire [7:0] bar     = y[7:0] + {t[6:0], 1'b0};
  wire [1:0] bl      = bar[5] ? ~bar[4:3] : bar[4:3];
  wire [5:0] copper  = bar[7] ? (bar[6] ? {bl, bl, 2'b00} : {bl, 2'b00, bl})
                              : (bar[6] ? {2'b00, bl, bl} : {bl, bl[1], 1'b0, 2'b00});

  wire [5:0] fx0 = squares[5] ? 6'b00_00_10 : 6'b00_00_01;
  wire [5:0] fx1 = {xortex[7:6], xortex[6:5] & {2{xortex[4]}}, xortex[5:4]};
  wire [5:0] fx2 = ripple[7] ? {2'b00, ripple[6:5], 2'b11} : {4'b0000, ripple[6:5]};
  wire [5:0] fx3 = diamond[6] ? {diamond[5:4], 4'b0011} : {2'b00, diamond[5:4], 2'b00};

  reg [5:0] scene;
  always @(*) begin
    case (part)
      3'd0:    scene = fx0;
      3'd1:    scene = fx1;
      3'd2:    scene = fx2;
      3'd3:    scene = fx3;
      3'd4:    scene = copper;
      default: scene = beat ? ~fx2 : fx2;
    endcase
  end

  wire show_title = (part == 3'd0) | (part == 3'd5 & frame[6:5] != 2'd0);

  assign {R, G, B} =
    (~video_active)      ? 6'b00_00_00 :
    (show_title & title) ? (beat ? ~title_rgb : title_rgb) :
                           scene;

endmodule