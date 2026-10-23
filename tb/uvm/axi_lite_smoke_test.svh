class axi_lite_smoke_test extends uvm_test;
    axi_lite_env env;

    `uvm_component_utils(axi_lite_smoke_test)

    function new(string name = "axi_lite_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_lite_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        axi_lite_smoke_sequence seq0;
        axi_lite_smoke_sequence seq1;

        phase.raise_objection(this);
        seq0 = axi_lite_smoke_sequence::type_id::create("master0_sequence");
        seq1 = axi_lite_smoke_sequence::type_id::create("master1_sequence");
        seq0.master_id = 0;
        seq1.master_id = 1;

        `uvm_info("TEST", "Starting concurrent directed sequences on both AXI masters", UVM_LOW)
        fork
            seq0.start(env.master0.sequencer);
            seq1.start(env.master1.sequencer);
        join
        `uvm_info("TEST", "Both master sequences completed", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
