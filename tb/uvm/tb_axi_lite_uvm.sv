`timescale 1ns/1ps
module tb_axi_lite_uvm;
    import uvm_pkg::*;
    import axi_lite_uvm_pkg::*;

    logic aclk = 1'b0;
    logic aresetn = 1'b0;

    axi_lite_if master_if [1:0] (aclk, aresetn);
    axi_lite_if target_if [1:0] (aclk, aresetn);

    logic [1:0] m_awvalid, m_awready;
    logic [1:0][7:0] m_awaddr;
    logic [1:0][2:0] m_awprot;
    logic [1:0] m_wvalid, m_wready;
    logic [1:0][31:0] m_wdata;
    logic [1:0][3:0] m_wstrb;
    logic [1:0] m_bvalid, m_bready;
    logic [1:0][1:0] m_bresp;
    logic [1:0] m_arvalid, m_arready;
    logic [1:0][7:0] m_araddr;
    logic [1:0][2:0] m_arprot;
    logic [1:0] m_rvalid, m_rready;
    logic [1:0][31:0] m_rdata;
    logic [1:0][1:0] m_rresp;

    logic [1:0] s_awvalid, s_awready;
    logic [1:0][7:0] s_awaddr;
    logic [1:0][2:0] s_awprot;
    logic [1:0] s_wvalid, s_wready;
    logic [1:0][31:0] s_wdata;
    logic [1:0][3:0] s_wstrb;
    logic [1:0] s_bvalid, s_bready;
    logic [1:0][1:0] s_bresp;
    logic [1:0] s_arvalid, s_arready;
    logic [1:0][7:0] s_araddr;
    logic [1:0][2:0] s_arprot;
    logic [1:0] s_rvalid, s_rready;
    logic [1:0][31:0] s_rdata;
    logic [1:0][1:0] s_rresp;

    for (genvar g = 0; g < 2; g++) begin : MASTER_BRIDGE
        assign m_awvalid[g] = master_if[g].awvalid;
        assign m_awaddr[g]  = master_if[g].awaddr;
        assign m_awprot[g]  = master_if[g].awprot;
        assign master_if[g].awready = m_awready[g];

        assign m_wvalid[g] = master_if[g].wvalid;
        assign m_wdata[g]  = master_if[g].wdata;
        assign m_wstrb[g]  = master_if[g].wstrb;
        assign master_if[g].wready = m_wready[g];

        assign master_if[g].bvalid = m_bvalid[g];
        assign master_if[g].bresp  = m_bresp[g];
        assign m_bready[g] = master_if[g].bready;

        assign m_arvalid[g] = master_if[g].arvalid;
        assign m_araddr[g]  = master_if[g].araddr;
        assign m_arprot[g]  = master_if[g].arprot;
        assign master_if[g].arready = m_arready[g];

        assign master_if[g].rvalid = m_rvalid[g];
        assign master_if[g].rdata  = m_rdata[g];
        assign master_if[g].rresp  = m_rresp[g];
        assign m_rready[g] = master_if[g].rready;
    end

    for (genvar g = 0; g < 2; g++) begin : TARGET_BRIDGE
        assign target_if[g].awvalid = s_awvalid[g];
        assign target_if[g].awaddr  = s_awaddr[g];
        assign target_if[g].awprot  = s_awprot[g];
        assign s_awready[g] = target_if[g].awready;

        assign target_if[g].wvalid = s_wvalid[g];
        assign target_if[g].wdata  = s_wdata[g];
        assign target_if[g].wstrb  = s_wstrb[g];
        assign s_wready[g] = target_if[g].wready;

        assign s_bvalid[g] = target_if[g].bvalid;
        assign s_bresp[g]  = target_if[g].bresp;
        assign target_if[g].bready = s_bready[g];

        assign target_if[g].arvalid = s_arvalid[g];
        assign target_if[g].araddr  = s_araddr[g];
        assign target_if[g].arprot  = s_arprot[g];
        assign s_arready[g] = target_if[g].arready;

        assign s_rvalid[g] = target_if[g].rvalid;
        assign s_rdata[g]  = target_if[g].rdata;
        assign s_rresp[g]  = target_if[g].rresp;
        assign target_if[g].rready = s_rready[g];
    end

    axi_lite_2x2_interconnect #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(32)
    ) dut (.*);

    for (genvar g = 0; g < 2; g++) begin : UVM_ASSERTIONS
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

    axi_lite_target_model #(.TARGET_INDEX(0)) target0(target_if[0]);
    axi_lite_target_model #(.TARGET_INDEX(1)) target1(target_if[1]);

    always #5 aclk = ~aclk;

    initial begin
        aresetn = 1'b0;
        repeat (5) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual axi_lite_if)::set(null, "uvm_test_top.env.master0", "vif", master_if[0]);
        uvm_config_db#(virtual axi_lite_if)::set(null, "uvm_test_top.env.master1", "vif", master_if[1]);
        uvm_config_db#(int unsigned)::set(null, "uvm_test_top.env.master0", "master_id", 32'd0);
        uvm_config_db#(int unsigned)::set(null, "uvm_test_top.env.master1", "master_id", 32'd1);
        run_test("axi_lite_smoke_test");
    end
endmodule
