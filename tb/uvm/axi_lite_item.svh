class axi_lite_item extends uvm_sequence_item;
    rand bit is_write;
    rand bit [7:0] addr;
    rand bit [31:0] wdata;
    rand bit [3:0] wstrb;
    bit [31:0] rdata;
    bit [1:0] resp;
    int unsigned master_id;

    constraint aligned_addr_c { addr[1:0] == 2'b00; }

    `uvm_object_utils(axi_lite_item)

    function new(string name = "axi_lite_item");
        super.new(name);
    endfunction
endclass
