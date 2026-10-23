module tb_axi_lite_2x2_interconnect;
    localparam int ADDR_WIDTH = 8;
    localparam int DATA_WIDTH = 32;
    localparam int DEPTH = 32;

    logic aclk = 1'b0;
    logic aresetn = 1'b0;

    logic [1:0] m_awvalid, m_awready;
    logic [1:0][ADDR_WIDTH-1:0] m_awaddr;
    logic [1:0][2:0] m_awprot;
    logic [1:0] m_wvalid, m_wready;
    logic [1:0][DATA_WIDTH-1:0] m_wdata;
    logic [1:0][DATA_WIDTH/8-1:0] m_wstrb;
    logic [1:0] m_bvalid, m_bready;
    logic [1:0][1:0] m_bresp;
    logic [1:0] m_arvalid, m_arready;
    logic [1:0][ADDR_WIDTH-1:0] m_araddr;
    logic [1:0][2:0] m_arprot;
    logic [1:0] m_rvalid, m_rready;
    logic [1:0][DATA_WIDTH-1:0] m_rdata;
    logic [1:0][1:0] m_rresp;

    logic [1:0] s_awvalid, s_awready;
    logic [1:0][ADDR_WIDTH-1:0] s_awaddr;
    logic [1:0][2:0] s_awprot;
    logic [1:0] s_wvalid, s_wready;
    logic [1:0][DATA_WIDTH-1:0] s_wdata;
    logic [1:0][DATA_WIDTH/8-1:0] s_wstrb;
    logic [1:0] s_bvalid, s_bready;
    logic [1:0][1:0] s_bresp;
    logic [1:0] s_arvalid, s_arready;
    logic [1:0][ADDR_WIDTH-1:0] s_araddr;
    logic [1:0][2:0] s_arprot;
    logic [1:0] s_rvalid, s_rready;
    logic [1:0][DATA_WIDTH-1:0] s_rdata;
    logic [1:0][1:0] s_rresp;

    logic [ADDR_WIDTH-1:0] target_awaddr_q [0:1];
    logic [1:0] target_aw_seen;
    logic [1:0] target_bvalid_q;
    logic [1:0][1:0] target_bresp_q;
    logic [1:0] target_rvalid_q;
    logic [1:0][DATA_WIDTH-1:0] target_rdata_q;
    logic [1:0][1:0] target_rresp_q;
    logic [DATA_WIDTH-1:0] mem [0:1][0:DEPTH-1];

    always_comb begin
        s_awready = '0;
        s_wready  = '0;
        s_bvalid  = target_bvalid_q;
        s_bresp   = target_bresp_q;
        s_arready = '0;
        s_rvalid  = target_rvalid_q;
        s_rdata   = target_rdata_q;
        s_rresp   = target_rresp_q;
        for (int k = 0; k < 2; k++) begin
            s_awready[k] = !target_aw_seen[k] && !target_bvalid_q[k];
            s_wready[k]  = target_aw_seen[k] && !target_bvalid_q[k];
            s_arready[k] = !target_rvalid_q[k];
        end
    end

    // Independent one-outstanding AXI-Lite target memory models.
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            target_aw_seen <= '0;
            target_bvalid_q <= '0;
            target_rvalid_q <= '0;
            target_bresp_q <= '0;
            target_rresp_q <= '0;
            target_rdata_q <= '0;
            for (int k = 0; k < 2; k++) begin
                target_awaddr_q[k] <= '0;
                for (int j = 0; j < DEPTH; j++)
                    mem[k][j] <= '0;
            end
        end else begin
            for (int k = 0; k < 2; k++) begin
                if (s_awvalid[k] && s_awready[k]) begin
                    target_awaddr_q[k] <= s_awaddr[k];
                    target_aw_seen[k] <= 1'b1;
                end

                if (s_wvalid[k] && s_wready[k]) begin
                    for (int j = 0; j < DATA_WIDTH/8; j++) begin
                        if (s_wstrb[k][j])
                            mem[k][target_awaddr_q[k][6:2]][8*j +: 8] <= s_wdata[k][8*j +: 8];
                    end
                    target_bresp_q[k] <= 2'b00;
                    target_bvalid_q[k] <= 1'b1;
                end

                if (s_bvalid[k] && s_bready[k]) begin
                    target_bvalid_q[k] <= 1'b0;
                    target_aw_seen[k] <= 1'b0;
                end

                if (s_arvalid[k] && s_arready[k]) begin
                    target_rdata_q[k] <= mem[k][s_araddr[k][6:2]];
                    target_rresp_q[k] <= 2'b00;
                    target_rvalid_q[k] <= 1'b1;
                end

                if (s_rvalid[k] && s_rready[k])
                    target_rvalid_q[k] <= 1'b0;
            end
        end
    end

    axi_lite_2x2_interconnect #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (.*);


    for (genvar g = 0; g < 2; g++) begin : MASTER_ASSERTIONS
        axi_lite_channel_assertions master_checker (
            .aclk(aclk), .aresetn(aresetn),
            .awvalid(m_awvalid[g]), .awready(m_awready[g]), .awaddr(m_awaddr[g]), .awprot(m_awprot[g]),
            .wvalid(m_wvalid[g]), .wready(m_wready[g]), .wdata(m_wdata[g]), .wstrb(m_wstrb[g]),
            .bvalid(m_bvalid[g]), .bready(m_bready[g]), .bresp(m_bresp[g]),
            .arvalid(m_arvalid[g]), .arready(m_arready[g]), .araddr(m_araddr[g]), .arprot(m_arprot[g]),
            .rvalid(m_rvalid[g]), .rready(m_rready[g]), .rdata(m_rdata[g]), .rresp(m_rresp[g])
        );
        axi_lite_channel_assertions target_checker (
            .aclk(aclk), .aresetn(aresetn),
            .awvalid(s_awvalid[g]), .awready(s_awready[g]), .awaddr(s_awaddr[g]), .awprot(s_awprot[g]),
            .wvalid(s_wvalid[g]), .wready(s_wready[g]), .wdata(s_wdata[g]), .wstrb(s_wstrb[g]),
            .bvalid(s_bvalid[g]), .bready(s_bready[g]), .bresp(s_bresp[g]),
            .arvalid(s_arvalid[g]), .arready(s_arready[g]), .araddr(s_araddr[g]), .arprot(s_arprot[g]),
            .rvalid(s_rvalid[g]), .rready(s_rready[g]), .rdata(s_rdata[g]), .rresp(s_rresp[g])
        );
    end

    always #5 aclk <= ~aclk;

    task automatic axi_write(
        input integer master,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [DATA_WIDTH/8-1:0] strb
    );
        bit aw_done;
        bit w_done;
        bit b_done;
        integer cycles;
        begin
            aw_done = 0;
            w_done = 0;
            b_done = 0;
            cycles = 0;
            @(negedge aclk);
            m_awaddr[master] = addr;
            m_awprot[master] = '0;
            m_awvalid[master] = 1'b1;
            m_wdata[master] = data;
            m_wstrb[master] = strb;
            m_wvalid[master] = 1'b1;

            while ((!aw_done || !w_done) && cycles < 200) begin
                @(posedge aclk);
                if (m_awvalid[master] && m_awready[master]) aw_done = 1;
                if (m_wvalid[master] && m_wready[master]) w_done = 1;
                @(negedge aclk);
                if (aw_done) m_awvalid[master] = 1'b0;
                if (w_done) m_wvalid[master] = 1'b0;
                cycles = cycles + 1;
            end
            if (!aw_done || !w_done)
                $fatal(1, "WRITE REQUEST TIMEOUT master=%0d addr=0x%02h", master, addr);

            m_bready[master] = 1'b1;
            cycles = 0;
            while (!b_done && cycles < 200) begin
                @(posedge aclk);
                if (m_bvalid[master] && m_bready[master]) begin
                    b_done = 1;
                    if (m_bresp[master] != 2'b00)
                        $fatal(1, "WRITE RESPONSE ERROR master=%0d addr=0x%02h resp=%0b", master, addr, m_bresp[master]);
                end
                cycles = cycles + 1;
            end
            @(negedge aclk);
            m_bready[master] = 1'b0;
            if (!b_done)
                $fatal(1, "WRITE RESPONSE TIMEOUT master=%0d addr=0x%02h", master, addr);
        end
    endtask

    task automatic axi_read(
        input integer master,
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] expected
    );
        bit ar_done;
        bit r_done;
        integer cycles;
        begin
            ar_done = 0;
            r_done = 0;
            cycles = 0;
            @(negedge aclk);
            m_araddr[master] = addr;
            m_arprot[master] = '0;
            m_arvalid[master] = 1'b1;

            while (!ar_done && cycles < 200) begin
                @(posedge aclk);
                if (m_arvalid[master] && m_arready[master]) ar_done = 1;
                @(negedge aclk);
                if (ar_done) m_arvalid[master] = 1'b0;
                cycles = cycles + 1;
            end
            if (!ar_done)
                $fatal(1, "READ ADDRESS TIMEOUT master=%0d addr=0x%02h", master, addr);

            m_rready[master] = 1'b1;
            cycles = 0;
            while (!r_done && cycles < 200) begin
                @(posedge aclk);
                if (m_rvalid[master] && m_rready[master]) begin
                    r_done = 1;
                    if (m_rresp[master] != 2'b00)
                        $fatal(1, "READ RESPONSE ERROR master=%0d addr=0x%02h resp=%0b", master, addr, m_rresp[master]);
                    if (m_rdata[master] !== expected)
                        $fatal(1, "READ DATA MISMATCH master=%0d addr=0x%02h expected=0x%08h actual=0x%08h", master, addr, expected, m_rdata[master]);
                    $display("READ PASS master=%0d addr=0x%02h data=0x%08h", master, addr, m_rdata[master]);
                end
                cycles = cycles + 1;
            end
            @(negedge aclk);
            m_rready[master] = 1'b0;
            if (!r_done)
                $fatal(1, "READ RESPONSE TIMEOUT master=%0d addr=0x%02h", master, addr);
        end
    endtask

    initial begin
        m_awvalid = '0;
        m_awaddr = '0;
        m_awprot = '0;
        m_wvalid = '0;
        m_wdata = '0;
        m_wstrb = '0;
        m_bready = '0;
        m_arvalid = '0;
        m_araddr = '0;
        m_arprot = '0;
        m_rready = '0;

        if ($test$plusargs("TRACE")) begin
            $dumpfile("results/axi_lite_smoke.vcd");
            $dumpvars(0, tb_axi_lite_2x2_interconnect);
        end

        repeat (4) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1'b1;
        repeat (2) @(posedge aclk);

        $display("TEST 1: master 0 -> target 0 write/read");
        axi_write(0, 8'h10, 32'h11223344, 4'b1111);
        axi_read (0, 8'h10, 32'h11223344);

        $display("TEST 2: master 1 -> target 1 write/read");
        axi_write(1, 8'h90, 32'hA5C35A3C, 4'b1111);
        axi_read (1, 8'h90, 32'hA5C35A3C);

        $display("TEST 3: byte strobes preserve untouched bytes");
        axi_write(0, 8'h10, 32'h0000CCDD, 4'b0011);
        axi_read (0, 8'h10, 32'h1122CCDD);

        $display("TEST 4: masters write different targets concurrently");
        fork
            axi_write(0, 8'h20, 32'h0BADF00D, 4'b1111);
            axi_write(1, 8'hA0, 32'hC001D00D, 4'b1111);
        join
        fork
            axi_read(0, 8'h20, 32'h0BADF00D);
            axi_read(1, 8'hA0, 32'hC001D00D);
        join

        $display("TEST 5: two masters contend for target 0; requests must not be lost");
        fork
            axi_write(0, 8'h30, 32'hCAFE0001, 4'b1111);
            axi_write(1, 8'h34, 32'hCAFE0002, 4'b1111);
        join
        fork
            axi_read(0, 8'h30, 32'hCAFE0001);
            axi_read(1, 8'h34, 32'hCAFE0002);
        join

        $display("TEST 6: simultaneous read requests contend for target 0");
        fork
            axi_read(0, 8'h30, 32'hCAFE0001);
            axi_read(1, 8'h34, 32'hCAFE0002);
        join

        $display("ALL TESTS PASSED: AXI4-Lite 2x2 smoke regression");
        $finish;
    end
endmodule
