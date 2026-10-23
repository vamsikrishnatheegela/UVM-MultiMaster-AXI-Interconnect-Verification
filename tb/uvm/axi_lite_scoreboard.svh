class axi_lite_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(axi_lite_item, axi_lite_scoreboard) analysis_export;

    bit [31:0] model_mem [0:1][0:31];
    int unsigned writes_checked;
    int unsigned reads_checked;
    int unsigned errors_seen;

    bit cov_is_write;
    bit cov_target;
    bit [1:0] cov_resp;
    int unsigned cov_master;

    covergroup txn_cov;
        cp_kind: coverpoint cov_is_write {
            bins read_txn = {1'b0};
            bins write_txn = {1'b1};
        }
        cp_target: coverpoint cov_target {
            bins target0 = {1'b0};
            bins target1 = {1'b1};
        }
        cp_master: coverpoint cov_master {
            bins master0 = {0};
            bins master1 = {1};
        }
        cp_response: coverpoint cov_resp {
            bins okay = {2'b00};
            bins error = {[2'b01:2'b11]};
        }
        kind_by_target: cross cp_kind, cp_target;
        master_by_target: cross cp_master, cp_target;
    endgroup

    `uvm_component_utils(axi_lite_scoreboard)

    function new(string name = "axi_lite_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        writes_checked = 0;
        reads_checked = 0;
        errors_seen = 0;
        txn_cov = new();
        for (int t = 0; t < 2; t++)
            for (int a = 0; a < 32; a++)
                model_mem[t][a] = '0;
    endfunction

    function void write(axi_lite_item tr);
        int unsigned target;
        int unsigned word_index;
        bit [31:0] expected;
        target = tr.addr[7] ? 1 : 0;
        word_index = tr.addr[6:2];
        cov_is_write = tr.is_write;
        cov_target = tr.addr[7];
        cov_resp = tr.resp;
        cov_master = tr.master_id;
        txn_cov.sample();

        if (tr.resp != 2'b00) begin
            errors_seen++;
            `uvm_error("SCOREBOARD_RESP", $sformatf("Master %0d addr=0x%02h response=%0b", tr.master_id, tr.addr, tr.resp))
        end else if (tr.is_write) begin
            for (int b = 0; b < 4; b++) begin
                if (tr.wstrb[b])
                    model_mem[target][word_index][8*b +: 8] = tr.wdata[8*b +: 8];
            end
            writes_checked++;
            `uvm_info("SB_WRITE", $sformatf("M%0d wrote addr=0x%02h data=0x%08h strb=%b", tr.master_id, tr.addr, tr.wdata, tr.wstrb), UVM_MEDIUM)
        end else begin
            expected = model_mem[target][word_index];
            if (tr.rdata !== expected) begin
                errors_seen++;
                `uvm_error("SB_READ_MISMATCH", $sformatf("M%0d addr=0x%02h expected=0x%08h actual=0x%08h", tr.master_id, tr.addr, expected, tr.rdata))
            end else begin
                reads_checked++;
                `uvm_info("SB_READ", $sformatf("M%0d read addr=0x%02h data=0x%08h matches reference model", tr.master_id, tr.addr, tr.rdata), UVM_MEDIUM)
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SB_SUMMARY", $sformatf("Writes checked=%0d Reads checked=%0d Scoreboard errors=%0d", writes_checked, reads_checked, errors_seen), UVM_NONE)
        `uvm_info("COVERAGE", $sformatf("Transaction functional coverage = %0.1f%%", txn_cov.get_coverage()), UVM_NONE)
        if (errors_seen != 0)
            `uvm_error("SB_FAIL", "Scoreboard detected one or more failures")
    endfunction
endclass
