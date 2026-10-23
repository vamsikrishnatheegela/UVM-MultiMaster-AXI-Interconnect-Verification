// 2-master / 2-target AXI4-Lite interconnect.
// Supported subset: one outstanding write and one outstanding read per master;
// one active transaction per target for each direction; 32-bit data by default.
// Address bit ADDR_WIDTH-1 selects target 0 (0) or target 1 (1).
// This is AXI4-Lite, not a full AXI4 burst/ID interconnect.
module axi_lite_2x2_interconnect #(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32
) (
    input  logic                           aclk,
    input  logic                           aresetn,

    input  logic [1:0]                     m_awvalid,
    output logic [1:0]                     m_awready,
    input  logic [1:0][ADDR_WIDTH-1:0]     m_awaddr,
    input  logic [1:0][2:0]               m_awprot,

    input  logic [1:0]                     m_wvalid,
    output logic [1:0]                     m_wready,
    input  logic [1:0][DATA_WIDTH-1:0]     m_wdata,
    input  logic [1:0][DATA_WIDTH/8-1:0]    m_wstrb,

    output logic [1:0]                     m_bvalid,
    input  logic [1:0]                     m_bready,
    output logic [1:0][1:0]               m_bresp,

    input  logic [1:0]                     m_arvalid,
    output logic [1:0]                     m_arready,
    input  logic [1:0][ADDR_WIDTH-1:0]     m_araddr,
    input  logic [1:0][2:0]               m_arprot,

    output logic [1:0]                     m_rvalid,
    input  logic [1:0]                     m_rready,
    output logic [1:0][DATA_WIDTH-1:0]     m_rdata,
    output logic [1:0][1:0]               m_rresp,

    output logic [1:0]                     s_awvalid,
    input  logic [1:0]                     s_awready,
    output logic [1:0][ADDR_WIDTH-1:0]     s_awaddr,
    output logic [1:0][2:0]               s_awprot,

    output logic [1:0]                     s_wvalid,
    input  logic [1:0]                     s_wready,
    output logic [1:0][DATA_WIDTH-1:0]     s_wdata,
    output logic [1:0][DATA_WIDTH/8-1:0]    s_wstrb,

    input  logic [1:0]                     s_bvalid,
    output logic [1:0]                     s_bready,
    input  logic [1:0][1:0]               s_bresp,

    output logic [1:0]                     s_arvalid,
    input  logic [1:0]                     s_arready,
    output logic [1:0][ADDR_WIDTH-1:0]     s_araddr,
    output logic [1:0][2:0]               s_arprot,

    input  logic [1:0]                     s_rvalid,
    output logic [1:0]                     s_rready,
    input  logic [1:0][DATA_WIDTH-1:0]     s_rdata,
    input  logic [1:0][1:0]               s_rresp
);

    logic [1:0] wr_active;
    logic [1:0] wr_owner;
    logic [1:0] wr_wdone;
    logic [1:0] rd_active;
    logic [1:0] rd_owner;
    logic [1:0] wr_busy;
    logic [1:0] rd_busy;
    logic [1:0] wr_rr;
    logic [1:0] rd_rr;

    integer wr_grant [0:1];
    integer rd_grant [0:1];
    integer t;
    integer selected;

    always_comb begin
        m_awready = '0;
        m_wready  = '0;
        m_bvalid  = '0;
        m_bresp   = '0;
        m_arready = '0;
        m_rvalid  = '0;
        m_rdata   = '0;
        m_rresp   = '0;

        s_awvalid = '0;
        s_awaddr  = '0;
        s_awprot  = '0;
        s_wvalid  = '0;
        s_wdata   = '0;
        s_wstrb   = '0;
        s_bready  = '0;
        s_arvalid = '0;
        s_araddr  = '0;
        s_arprot  = '0;
        s_rready  = '0;

        // Write address arbitration is independent for each target.
        for (t = 0; t < 2; t = t + 1) begin
            selected = -1;
            wr_grant[t] = -1;
            if (!wr_active[t]) begin
                if (wr_rr[t] == 1'b0) begin
                    if (m_awvalid[0] && !wr_busy[0] &&
                        (m_awaddr[0][ADDR_WIDTH-1] == t))
                        selected = 0;
                    else if (m_awvalid[1] && !wr_busy[1] &&
                             (m_awaddr[1][ADDR_WIDTH-1] == t))
                        selected = 1;
                end else begin
                    if (m_awvalid[1] && !wr_busy[1] &&
                        (m_awaddr[1][ADDR_WIDTH-1] == t))
                        selected = 1;
                    else if (m_awvalid[0] && !wr_busy[0] &&
                             (m_awaddr[0][ADDR_WIDTH-1] == t))
                        selected = 0;
                end
            end

            wr_grant[t] = selected;
            if (selected >= 0) begin
                s_awvalid[t] = m_awvalid[selected];
                s_awaddr[t]  = m_awaddr[selected];
                s_awprot[t]  = m_awprot[selected];
                m_awready[selected] = s_awready[t];
            end
        end

        // W data follows accepted AW ownership; B returns to that owner.
        for (t = 0; t < 2; t = t + 1) begin
            if (wr_active[t]) begin
                if (wr_owner[t] == 1'b0) begin
                    s_wvalid[t] = m_wvalid[0];
                    s_wdata[t]  = m_wdata[0];
                    s_wstrb[t]  = m_wstrb[0];
                    m_wready[0] = s_wready[t];
                    if (wr_wdone[t]) begin
                        m_bvalid[0] = s_bvalid[t];
                        m_bresp[0]  = s_bresp[t];
                        s_bready[t] = m_bready[0];
                    end
                end else begin
                    s_wvalid[t] = m_wvalid[1];
                    s_wdata[t]  = m_wdata[1];
                    s_wstrb[t]  = m_wstrb[1];
                    m_wready[1] = s_wready[t];
                    if (wr_wdone[t]) begin
                        m_bvalid[1] = s_bvalid[t];
                        m_bresp[1]  = s_bresp[t];
                        s_bready[t] = m_bready[1];
                    end
                end
            end
        end

        // Read address arbitration has independent state from write arbitration.
        for (t = 0; t < 2; t = t + 1) begin
            selected = -1;
            rd_grant[t] = -1;
            if (!rd_active[t]) begin
                if (rd_rr[t] == 1'b0) begin
                    if (m_arvalid[0] && !rd_busy[0] &&
                        (m_araddr[0][ADDR_WIDTH-1] == t))
                        selected = 0;
                    else if (m_arvalid[1] && !rd_busy[1] &&
                             (m_araddr[1][ADDR_WIDTH-1] == t))
                        selected = 1;
                end else begin
                    if (m_arvalid[1] && !rd_busy[1] &&
                        (m_araddr[1][ADDR_WIDTH-1] == t))
                        selected = 1;
                    else if (m_arvalid[0] && !rd_busy[0] &&
                             (m_araddr[0][ADDR_WIDTH-1] == t))
                        selected = 0;
                end
            end

            rd_grant[t] = selected;
            if (selected >= 0) begin
                s_arvalid[t] = m_arvalid[selected];
                s_araddr[t]  = m_araddr[selected];
                s_arprot[t]  = m_arprot[selected];
                m_arready[selected] = s_arready[t];
            end
        end

        // R response returns to the master that issued the accepted AR.
        for (t = 0; t < 2; t = t + 1) begin
            if (rd_active[t]) begin
                if (rd_owner[t] == 1'b0) begin
                    m_rvalid[0] = s_rvalid[t];
                    m_rdata[0]  = s_rdata[t];
                    m_rresp[0]  = s_rresp[t];
                    s_rready[t] = m_rready[0];
                end else begin
                    m_rvalid[1] = s_rvalid[t];
                    m_rdata[1]  = s_rdata[t];
                    m_rresp[1]  = s_rresp[t];
                    s_rready[t] = m_rready[1];
                end
            end
        end
    end

    integer i;
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wr_active <= '0;
            wr_owner  <= '0;
            wr_wdone  <= '0;
            rd_active <= '0;
            rd_owner  <= '0;
            wr_busy   <= '0;
            rd_busy   <= '0;
            wr_rr     <= '0;
            rd_rr     <= '0;
        end else begin
            for (i = 0; i < 2; i = i + 1) begin
                if (s_awvalid[i] && s_awready[i]) begin
                    wr_active[i] <= 1'b1;
                    wr_owner[i]  <= (wr_grant[i] == 1) ? 1'b1 : 1'b0;
                    wr_wdone[i]  <= 1'b0;
                    if (wr_grant[i] == 0)
                        wr_busy[0] <= 1'b1;
                    else
                        wr_busy[1] <= 1'b1;
                    if (wr_grant[i] == 0)
                        wr_rr[i] <= 1'b1;
                    else
                        wr_rr[i] <= 1'b0;
                end

                if (wr_active[i] && s_wvalid[i] && s_wready[i])
                    wr_wdone[i] <= 1'b1;

                if (wr_active[i] && wr_wdone[i] &&
                    s_bvalid[i] && s_bready[i]) begin
                    wr_active[i] <= 1'b0;
                    wr_wdone[i]  <= 1'b0;
                    wr_busy[wr_owner[i]] <= 1'b0;
                end

                if (s_arvalid[i] && s_arready[i]) begin
                    rd_active[i] <= 1'b1;
                    rd_owner[i]  <= (rd_grant[i] == 1) ? 1'b1 : 1'b0;
                    if (rd_grant[i] == 0)
                        rd_busy[0] <= 1'b1;
                    else
                        rd_busy[1] <= 1'b1;
                    if (rd_grant[i] == 0)
                        rd_rr[i] <= 1'b1;
                    else
                        rd_rr[i] <= 1'b0;
                end

                if (rd_active[i] && s_rvalid[i] && s_rready[i]) begin
                    rd_active[i] <= 1'b0;
                    rd_busy[rd_owner[i]] <= 1'b0;
                end
            end
        end
    end

endmodule
