class axi_lite_smoke_sequence extends uvm_sequence #(axi_lite_item);
    int unsigned master_id;

    `uvm_object_utils(axi_lite_smoke_sequence)

    function new(string name = "axi_lite_smoke_sequence");
        super.new(name);
        master_id = 0;
    endfunction

    task automatic issue_write(input bit [7:0] addr, input bit [31:0] data, input bit [3:0] strb = 4'hF);
        axi_lite_item tr;
        tr = axi_lite_item::type_id::create("write_item");
        start_item(tr);
        tr.is_write = 1'b1;
        tr.addr = addr;
        tr.wdata = data;
        tr.wstrb = strb;
        tr.master_id = master_id;
        finish_item(tr);
    endtask

    task automatic issue_read(input bit [7:0] addr);
        axi_lite_item tr;
        tr = axi_lite_item::type_id::create("read_item");
        start_item(tr);
        tr.is_write = 1'b0;
        tr.addr = addr;
        tr.wstrb = '0;
        tr.master_id = master_id;
        finish_item(tr);
    endtask

    task body();
        if (master_id == 0) begin
            issue_write(8'h10, 32'h11223344);
            issue_read (8'h10);
            // Same-target contention candidate: master 1 also requests target 0.
            issue_write(8'h20, 32'hCAFE0001);
            issue_read (8'h20);
            issue_write(8'h10, 32'h0000CCDD, 4'b0011);
            issue_read (8'h10);
        end else begin
            issue_write(8'h90, 32'hA5C35A3C);
            issue_read (8'h90);
            issue_write(8'h24, 32'hCAFE0002);
            issue_read (8'h24);
            issue_write(8'hA0, 32'hC001D00D);
            issue_read (8'hA0);
        end
    endtask
endclass
