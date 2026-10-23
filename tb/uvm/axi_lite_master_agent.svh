class axi_lite_master_agent extends uvm_agent;
    virtual axi_lite_if vif;
    int unsigned master_id;

    uvm_sequencer #(axi_lite_item) sequencer;
    axi_lite_master_driver driver;
    axi_lite_master_monitor monitor;

    `uvm_component_utils(axi_lite_master_agent)

    function new(string name = "axi_lite_master_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", $sformatf("No virtual interface for %s", get_full_name()))
        if (!uvm_config_db#(int unsigned)::get(this, "", "master_id", master_id))
            `uvm_fatal("NOMASTERID", $sformatf("No master_id for %s", get_full_name()))

        uvm_config_db#(virtual axi_lite_if)::set(this, "driver", "vif", vif);
        uvm_config_db#(virtual axi_lite_if)::set(this, "monitor", "vif", vif);
        uvm_config_db#(int unsigned)::set(this, "monitor", "master_id", master_id);

        sequencer = uvm_sequencer#(axi_lite_item)::type_id::create("sequencer", this);
        driver = axi_lite_master_driver::type_id::create("driver", this);
        monitor = axi_lite_master_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
