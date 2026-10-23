class axi_lite_master_driver extends uvm_driver #(axi_lite_item);
    virtual axi_lite_if vif;

    `uvm_component_utils(axi_lite_master_driver)

    function new(string name = "axi_lite_master_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", $sformatf("No AXI-Lite virtual interface for %s", get_full_name()))
    endfunction

    task run_phase(uvm_phase phase);
        axi_lite_item req;
        wait (vif.aresetn === 1'b1);
        @(negedge vif.aclk);
        vif.awvalid = 1'b0;
        vif.wvalid  = 1'b0;
        vif.bready  = 1'b0;
        vif.arvalid = 1'b0;
        vif.rready  = 1'b0;

        forever begin
            seq_item_port.get_next_item(req);
            if (req.is_write)
                drive_write(req);
            else
                drive_read(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_write(axi_lite_item tr);
        bit aw_done;
        bit w_done;
        bit b_done;
        int cycles;
        aw_done = 0;
        w_done = 0;
        b_done = 0;
        cycles = 0;

        @(negedge vif.aclk);
        vif.awaddr  = tr.addr;
        vif.awprot  = 3'b000;
        vif.awvalid = 1'b1;
        vif.wdata   = tr.wdata;
        vif.wstrb   = tr.wstrb;
        vif.wvalid  = 1'b1;

        while ((!aw_done || !w_done) && cycles < 256) begin
            @(posedge vif.aclk);
            if (vif.awvalid && vif.awready) aw_done = 1;
            if (vif.wvalid && vif.wready) w_done = 1;
            cycles++;
            @(negedge vif.aclk);
            if (aw_done) vif.awvalid = 1'b0;
            if (w_done) vif.wvalid = 1'b0;
        end
        if (!aw_done || !w_done)
            `uvm_fatal("AW_W_TIMEOUT", $sformatf("Write request timeout addr=0x%02h", tr.addr))

        // Keep BREADY low briefly so response stability assertions are exercised.
        repeat (2) @(negedge vif.aclk);
        vif.bready = 1'b1;
        cycles = 0;
        while (!b_done && cycles < 256) begin
            @(posedge vif.aclk);
            if (vif.bvalid && vif.bready) begin
                tr.resp = vif.bresp;
                b_done = 1;
            end
            cycles++;
        end
        @(negedge vif.aclk);
        vif.bready = 1'b0;
        if (!b_done)
            `uvm_fatal("B_TIMEOUT", $sformatf("Write response timeout addr=0x%02h", tr.addr))
        if (tr.resp != 2'b00)
            `uvm_error("BRESP", $sformatf("Write response=%0b addr=0x%02h", tr.resp, tr.addr))
    endtask

    task drive_read(axi_lite_item tr);
        bit ar_done;
        bit r_done;
        int cycles;
        ar_done = 0;
        r_done = 0;
        cycles = 0;

        @(negedge vif.aclk);
        vif.araddr  = tr.addr;
        vif.arprot  = 3'b000;
        vif.arvalid = 1'b1;

        while (!ar_done && cycles < 256) begin
            @(posedge vif.aclk);
            if (vif.arvalid && vif.arready) ar_done = 1;
            cycles++;
            @(negedge vif.aclk);
            if (ar_done) vif.arvalid = 1'b0;
        end
        if (!ar_done)
            `uvm_fatal("AR_TIMEOUT", $sformatf("Read address timeout addr=0x%02h", tr.addr))

        // Keep RREADY low briefly so response stability assertions are exercised.
        repeat (2) @(negedge vif.aclk);
        vif.rready = 1'b1;
        cycles = 0;
        while (!r_done && cycles < 256) begin
            @(posedge vif.aclk);
            if (vif.rvalid && vif.rready) begin
                tr.rdata = vif.rdata;
                tr.resp  = vif.rresp;
                r_done = 1;
            end
            cycles++;
        end
        @(negedge vif.aclk);
        vif.rready = 1'b0;
        if (!r_done)
            `uvm_fatal("R_TIMEOUT", $sformatf("Read response timeout addr=0x%02h", tr.addr))
        if (tr.resp != 2'b00)
            `uvm_error("RRESP", $sformatf("Read response=%0b addr=0x%02h", tr.resp, tr.addr))
    endtask
endclass
