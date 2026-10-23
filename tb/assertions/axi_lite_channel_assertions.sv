// AXI4-Lite channel protocol checker.
// Connect one instance to each master-facing interface and each target-facing
// interface. VALID and payload must remain stable while READY is low.
module axi_lite_channel_assertions (
    input logic aclk,
    input logic aresetn,
    input logic awvalid,
    input logic awready,
    input logic [7:0] awaddr,
    input logic [2:0] awprot,
    input logic wvalid,
    input logic wready,
    input logic [31:0] wdata,
    input logic [3:0] wstrb,
    input logic bvalid,
    input logic bready,
    input logic [1:0] bresp,
    input logic arvalid,
    input logic arready,
    input logic [7:0] araddr,
    input logic [2:0] arprot,
    input logic rvalid,
    input logic rready,
    input logic [31:0] rdata,
    input logic [1:0] rresp
);
    property p_aw_stable_when_stalled;
        @(posedge aclk) disable iff (!aresetn)
            awvalid && !awready |=> awvalid && $stable({awaddr, awprot});
    endproperty
    assert property (p_aw_stable_when_stalled)
        else $error("AXI-Lite AW payload changed while stalled");

    property p_w_stable_when_stalled;
        @(posedge aclk) disable iff (!aresetn)
            wvalid && !wready |=> wvalid && $stable({wdata, wstrb});
    endproperty
    assert property (p_w_stable_when_stalled)
        else $error("AXI-Lite W payload changed while stalled");

    property p_b_stable_when_stalled;
        @(posedge aclk) disable iff (!aresetn)
            bvalid && !bready |=> bvalid && $stable(bresp);
    endproperty
    assert property (p_b_stable_when_stalled)
        else $error("AXI-Lite B response changed while stalled");

    property p_ar_stable_when_stalled;
        @(posedge aclk) disable iff (!aresetn)
            arvalid && !arready |=> arvalid && $stable({araddr, arprot});
    endproperty
    assert property (p_ar_stable_when_stalled)
        else $error("AXI-Lite AR payload changed while stalled");

    property p_r_stable_when_stalled;
        @(posedge aclk) disable iff (!aresetn)
            rvalid && !rready |=> rvalid && $stable({rdata, rresp});
    endproperty
    assert property (p_r_stable_when_stalled)
        else $error("AXI-Lite R response changed while stalled");
endmodule
