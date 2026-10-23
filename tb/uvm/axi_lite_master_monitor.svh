class axi_lite_master_monitor extends uvm_monitor;
    virtual axi_lite_if vif;
    uvm_analysis_port #(axi_lite_item) ap;
    int unsigned master_id;

    bit aw_seen;
    bit w_seen;
    bit ar_seen;
    bit [7:0] awaddr_q;
    bit [31:0] wdata_q;
    bit [3:0] wstrb_q;
    bit [7:0] araddr_q;

    `uvm_component_utils(axi_lite_master_monitor)

    function new(string name = "axi_lite_master_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", $sformatf("No AXI-Lite virtual interface for %s", get_full_name()))
        if (!uvm_config_db#(int unsigned)::get(this, "", "master_id", master_id))
            `uvm_fatal("NOMASTERID", $sformatf("No master_id for %s", get_full_name()))
    endfunction

    task run_phase(uvm_phase phase);
        axi_lite_item tr;
        aw_seen = 0;
        w_seen  = 0;
        ar_seen = 0;

        forever begin
            @(posedge vif.aclk);
            if (!vif.aresetn) begin
                aw_seen = 0;
                w_seen  = 0;
                ar_seen = 0;
            end else begin
                if (vif.awvalid && vif.awready) begin
                    awaddr_q = vif.awaddr;
                    aw_seen = 1;
                end
                if (vif.wvalid && vif.wready) begin
                    wdata_q = vif.wdata;
                    wstrb_q = vif.wstrb;
                    w_seen = 1;
                end
                if (vif.bvalid && vif.bready) begin
                    if (!aw_seen || !w_seen)
                        `uvm_error("MON_WRITE_STATE", "B response without prior AW and W handshakes")
                    tr = axi_lite_item::type_id::create("observed_write", this);
                    tr.is_write = 1;
                    tr.addr = awaddr_q;
                    tr.wdata = wdata_q;
                    tr.wstrb = wstrb_q;
                    tr.resp = vif.bresp;
                    tr.master_id = master_id;
                    ap.write(tr);
                    aw_seen = 0;
                    w_seen = 0;
                end

                if (vif.arvalid && vif.arready) begin
                    araddr_q = vif.araddr;
                    ar_seen = 1;
                end
                if (vif.rvalid && vif.rready) begin
                    if (!ar_seen)
                        `uvm_error("MON_READ_STATE", "R response without prior AR handshake")
                    tr = axi_lite_item::type_id::create("observed_read", this);
                    tr.is_write = 0;
                    tr.addr = araddr_q;
                    tr.rdata = vif.rdata;
                    tr.resp = vif.rresp;
                    tr.master_id = master_id;
                    ap.write(tr);
                    ar_seen = 0;
                end
            end
        end
    endtask
endclass
