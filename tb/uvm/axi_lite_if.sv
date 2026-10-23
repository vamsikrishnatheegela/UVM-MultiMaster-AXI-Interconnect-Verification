interface axi_lite_if(input logic aclk, input logic aresetn);
    logic [7:0]  awaddr = '0;
    logic [2:0]  awprot = '0;
    logic        awvalid = 1'b0;
    logic        awready;

    logic [31:0] wdata = '0;
    logic [3:0]  wstrb = '0;
    logic        wvalid = 1'b0;
    logic        wready;

    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready = 1'b0;

    logic [7:0]  araddr = '0;
    logic [2:0]  arprot = '0;
    logic        arvalid = 1'b0;
    logic        arready;

    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready = 1'b0;
endinterface
