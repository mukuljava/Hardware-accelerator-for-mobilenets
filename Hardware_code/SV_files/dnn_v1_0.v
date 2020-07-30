
`timescale 1 ns / 1 ps

	module dnn_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
		//BRAM I ports
        output wire [31:0] bram_i_addr ,//[11:0]
        output wire bram_clk ,
        output wire [31:0] bram_i_wrdata ,
        input wire [31:0] bram_i_rddata ,
        output wire bram_en ,
        output wire bram_rst ,
        output wire [3:0] bram_i_we ,
        //BRAM W ports
        output wire [31:0] bram_w_addr , //[5:0]
        output wire [31:0] bram_w_wrdata ,
        input wire [31:0] bram_w_rddata ,
        output wire [3:0] bram_w_we ,
        //BRAM O ports
        input wire        bram_oc_clk ,
        input wire       bram_oc_rst ,
        input wire        bram_oc_en ,
        input wire [3:0] bram_oc_we ,
        input wire [31:0] bram_oc_addr ,//[11:0]
        input wire [31:0] bram_oc_wrdata ,
        output wire [31:0] bram_oc_rddata ,
   //     output wire        bram_oc_rstb ,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
	    wire [31:0] ps_control , pl_status , bias , n_val, k_val, c_val;
// Instantiation of Axi Bus Interface S00_AXI
	dnn_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) dnn_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		. pl_status ( pl_status ),
        . ps_control ( ps_control ),
        . bias (bias),
        . n_val (n_val),
        . k_val (k_val),
        . c_val (c_val)
	);

	// Add user logic here
    assign bram_clk = s00_axi_aclk ;
    assign bram_en = 1;
    assign bram_rst = ~ s00_axi_aresetn ;
    assign bram_i_we = 4'h0;
    assign bram_w_we = 4'h0;
    assign bram_i_wrdata = 4'h0;
    assign bram_w_wrdata = 4'h0;
	// User logic ends
    dnn nn(.clk(s00_axi_aclk), .reset(bram_rst), .ps_control(ps_control), .pl_status(pl_status), .bias(bias), .n_val(n_val), .k_val(k_val), .c_val(c_val),
       .bram_i_addr(bram_i_addr), .bram_i_rddata(bram_i_rddata), .bram_w_addr(bram_w_addr), .bram_w_rddata(bram_w_rddata), 
       .bram_oc_clk(bram_oc_clk), .bram_oc_rst(bram_oc_rst), .bram_oc_en(bram_oc_en),.bram_oc_we(bram_oc_we), .bram_oc_addr(bram_oc_addr),
       .bram_oc_wrdata(bram_oc_wrdata), .bram_oc_rddata(bram_oc_rddata));//, .bram_oc_rstb(bram_oc_rstb));
	endmodule
