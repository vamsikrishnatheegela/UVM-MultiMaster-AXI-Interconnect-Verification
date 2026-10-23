class axi_lite_env extends uvm_env;
    axi_lite_master_agent master0;
    axi_lite_master_agent master1;
    axi_lite_scoreboard scoreboard;

    `uvm_component_utils(axi_lite_env)

    function new(string name = "axi_lite_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        master0 = axi_lite_master_agent::type_id::create("master0", this);
        master1 = axi_lite_master_agent::type_id::create("master1", this);
        scoreboard = axi_lite_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        master0.monitor.ap.connect(scoreboard.analysis_export);
        master1.monitor.ap.connect(scoreboard.analysis_export);
    endfunction
endclass
