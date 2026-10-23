module axi_lite_target_model #(
    parameter int TARGET_INDEX = 0,
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32,
    parameter int DEPTH = 32
) (axi_lite_if target_if);

    logic aw_seen;
    logic [ADDR_WIDTH-1:0] awaddr_q;
    logic bvalid_q;
    logic [1:0] bresp_q;
    logic rvalid_q;
    logic [DATA_WIDTH-1:0] rdata_q;
    logic [1:0] rresp_q;
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always_comb begin
        target_if.awready = !aw_seen && !bvalid_q;
        target_if.wready  = aw_seen && !bvalid_q;
        target_if.bvalid  = bvalid_q;
        target_if.bresp   = bresp_q;
        target_if.arready = !rvalid_q;
        target_if.rvalid  = rvalid_q;
        target_if.rdata   = rdata_q;
        target_if.rresp   = rresp_q;
    end

    always_ff @(posedge target_if.aclk or negedge target_if.aresetn) begin
        if (!target_if.aresetn) begin
            aw_seen <= 1'b0;
            awaddr_q <= '0;
            bvalid_q <= 1'b0;
            bresp_q <= 2'b00;
            rvalid_q <= 1'b0;
            rdata_q <= '0;
            rresp_q <= 2'b00;
            for (int i = 0; i < DEPTH; i++)
                mem[i] <= '0;
        end else begin
            if (target_if.awvalid && target_if.awready) begin
                awaddr_q <= target_if.awaddr;
                aw_seen <= 1'b1;
            end

            if (target_if.wvalid && target_if.wready) begin
                for (int b = 0; b < DATA_WIDTH/8; b++) begin
                    if (target_if.wstrb[b])
                        mem[awaddr_q[6:2]][8*b +: 8] <= target_if.wdata[8*b +: 8];
                end
                bresp_q <= 2'b00;
                bvalid_q <= 1'b1;
            end

            if (target_if.bvalid && target_if.bready) begin
                bvalid_q <= 1'b0;
                aw_seen <= 1'b0;
            end

            if (target_if.arvalid && target_if.arready) begin
                rdata_q <= mem[target_if.araddr[6:2]];
                rresp_q <= 2'b00;
                rvalid_q <= 1'b1;
            end

            if (target_if.rvalid && target_if.rready)
                rvalid_q <= 1'b0;
        end
    end

endmodule
