`timescale 1ns/1ps
module axi_lite_2x2_smoke_tb;
  logic clk = 0;
  logic rst_n = 0;

  logic [1:0][31:0] s_awaddr, s_wdata, s_araddr;
  logic [1:0][3:0] s_wstrb;
  logic [1:0] s_awvalid, s_awready, s_wvalid, s_wready, s_bready;
  logic [1:0][1:0] s_bresp;
  logic [1:0] s_bvalid;
  logic [1:0] s_arvalid, s_arready, s_rready, s_rvalid;
  logic [1:0][31:0] s_rdata;
  logic [1:0][1:0] s_rresp;

  logic [1:0][31:0] m_awaddr, m_wdata, m_araddr, m_rdata;
  logic [1:0][3:0] m_wstrb;
  logic [1:0] m_awvalid, m_awready, m_wvalid, m_wready, m_bready;
  logic [1:0][1:0] m_bresp, m_rresp;
  logic [1:0] m_bvalid, m_arvalid, m_arready, m_rready, m_rvalid;

  logic [31:0] mem [0:1][0:15];
  logic [31:0] awaddr_q [0:1];
  logic [31:0] wdata_q [0:1];
  logic [3:0] wstrb_q [0:1];
  logic aw_seen [0:1];
  logic w_seen [0:1];
  integer aw_count = 0;
  integer ar_count = 0;
  integer b_count = 0;
  integer r_count = 0;
  integer t, b;

  axi_lite_2x2_interconnect dut (.*);

  always #5 clk = ~clk;

  // Simple independent AXI4-Lite target models. AW and W are accepted
  // independently; BVALID/RVALID remain asserted until the handshake.
  always_comb begin
    m_awready = '0;
    m_wready = '0;
    m_bresp = '0;
    m_bvalid = '0;
    m_arready = '0;
    m_rdata = '0;
    m_rresp = '0;
    m_rvalid = '0;
    for (integer j = 0; j < 2; j = j + 1) begin
      m_awready[j] = !aw_seen[j] && !m_bvalid[j];
      m_wready[j] = !w_seen[j] && !m_bvalid[j];
      m_bresp[j] = 2'b00;
      m_arready[j] = !m_rvalid[j];
    end
  end

  // Separate response registers are modeled in the sequential process.
  logic [1:0] bvalid_q, rvalid_q;
  logic [1:0][31:0] rdata_q;
  always_comb begin
    m_bvalid = bvalid_q;
    m_rvalid = rvalid_q;
    m_rdata = rdata_q;
    m_rresp = '0;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bvalid_q <= '0;
      rvalid_q <= '0;
      rdata_q <= '0;
      for (integer j = 0; j < 2; j = j + 1) begin
        aw_seen[j] <= 1'b0;
        w_seen[j] <= 1'b0;
        awaddr_q[j] <= '0;
        wdata_q[j] <= '0;
        wstrb_q[j] <= '0;
      end
      aw_count <= 0;
      ar_count <= 0;
      b_count <= 0;
      r_count <= 0;
      for (integer x = 0; x < 2; x = x + 1)
        for (integer y = 0; y < 16; y = y + 1)
          mem[x][y] <= '0;
    end else begin
      for (integer j = 0; j < 2; j = j + 1) begin
        if (m_awvalid[j] && m_awready[j]) begin
          aw_seen[j] <= 1'b1;
          awaddr_q[j] <= m_awaddr[j];
          aw_count <= aw_count + 1;
        end
        if (m_wvalid[j] && m_wready[j]) begin
          w_seen[j] <= 1'b1;
          wdata_q[j] <= m_wdata[j];
          wstrb_q[j] <= m_wstrb[j];
        end
        if (!bvalid_q[j] &&
            (aw_seen[j] || (m_awvalid[j] && m_awready[j])) &&
            (w_seen[j] || (m_wvalid[j] && m_wready[j]))) begin
          for (integer lane = 0; lane < 4; lane = lane + 1) begin
            if ((w_seen[j] ? wstrb_q[j][lane] : m_wstrb[j][lane]) === 1'b1)
              mem[j][(aw_seen[j] ? awaddr_q[j][5:2] : m_awaddr[j][5:2])][lane*8 +: 8]
                <= (w_seen[j] ? wdata_q[j][lane*8 +: 8] : m_wdata[j][lane*8 +: 8]);
          end
          aw_seen[j] <= 1'b0;
          w_seen[j] <= 1'b0;
          bvalid_q[j] <= 1'b1;
        end
        if (bvalid_q[j] && m_bready[j]) begin
          bvalid_q[j] <= 1'b0;
          b_count <= b_count + 1;
        end
        if (m_arvalid[j] && m_arready[j]) begin
          rdata_q[j] <= mem[j][m_araddr[j][5:2]];
          rvalid_q[j] <= 1'b1;
          ar_count <= ar_count + 1;
        end
        if (rvalid_q[j] && m_rready[j]) begin
          rvalid_q[j] <= 1'b0;
          r_count <= r_count + 1;
        end
      end
    end
  end

  task automatic axi_write(input integer master, input logic [31:0] addr,
                           input logic [31:0] data);
    begin
      @(negedge clk);
      s_awaddr[master] = addr;
      s_wdata[master] = data;
      s_wstrb[master] = 4'hF;
      s_awvalid[master] = 1'b1;
      s_wvalid[master] = 1'b1;
      fork
        begin
          do @(posedge clk); while (!s_awready[master]);
          @(negedge clk);
          s_awvalid[master] = 1'b0;
        end
        begin
          do @(posedge clk); while (!s_wready[master]);
          @(negedge clk);
          s_wvalid[master] = 1'b0;
        end
      join
      do @(posedge clk); while (!s_bvalid[master]);
      if (s_bresp[master] !== 2'b00)
        $fatal(1, "WRITE response error master=%0d resp=%b", master, s_bresp[master]);
      @(negedge clk);
    end
  endtask

  task automatic axi_read(input integer master, input logic [31:0] addr,
                          input logic [31:0] expected);
    begin
      @(negedge clk);
      s_araddr[master] = addr;
      s_arvalid[master] = 1'b1;
      do @(posedge clk); while (!s_arready[master]);
      @(negedge clk);
      s_arvalid[master] = 1'b0;
      do @(posedge clk); while (!s_rvalid[master]);
      if (s_rresp[master] !== 2'b00)
        $fatal(1, "READ response error master=%0d resp=%b", master, s_rresp[master]);
      if (s_rdata[master] !== expected)
        $fatal(1, "READ DATA MISMATCH master=%0d addr=%08x expected=%08x got=%08x",
               master, addr, expected, s_rdata[master]);
      @(negedge clk);
    end
  endtask

  initial begin
    s_awaddr = '0; s_awvalid = '0; s_wdata = '0; s_wstrb = '0; s_wvalid = '0;
    s_bready = '1; s_araddr = '0; s_arvalid = '0; s_rready = '1;
    repeat (4) @(negedge clk);
    rst_n = 1'b1;
    repeat (2) @(negedge clk);

    $display("[TEST] concurrent writes from both masters to target 0");
    fork
      axi_write(0, 32'h0000_0000, 32'hA5A5_1234);
      axi_write(1, 32'h0000_0004, 32'h5A5A_5678);
    join

    $display("[TEST] concurrent writes to different targets");
    fork
      axi_write(0, 32'h0000_0008, 32'h1122_3344);
      axi_write(1, 32'h0000_1000, 32'hDEAD_BEEF);
    join

    $display("[TEST] readback and response routing");
    fork
      axi_read(0, 32'h0000_0000, 32'hA5A5_1234);
      axi_read(1, 32'h0000_0004, 32'h5A5A_5678);
    join
    axi_read(0, 32'h0000_0008, 32'h1122_3344);
    axi_read(1, 32'h0000_1000, 32'hDEAD_BEEF);

    if (aw_count != 4 || ar_count != 4 || b_count != 4 || r_count != 4)
      $fatal(1, "COUNT MISMATCH aw=%0d ar=%0d b=%0d r=%0d",
             aw_count, ar_count, b_count, r_count);

    $display("PASS: AXI-Lite 2x2 smoke test");
    $display("PROOF: AW=%0d AR=%0d B=%0d R=%0d; all readbacks matched",
             aw_count, ar_count, b_count, r_count);
    $finish;
  end

  initial begin
    #20000;
    $fatal(1, "TIMEOUT: testbench did not complete");
  end
endmodule
