`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.05.2020 04:38:07
// Design Name: 
// Module Name: tbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


parameter T = 32;
module tbench();
    parameter T = 32;
    logic clk, reset;
    logic  [T-1:0] ps_control;
    logic [T-1:0] pl_status;
	logic [T-1:0] bias;
	logic [T-1:0] bram_i_addr;
	logic  [T-1:0] bram_i_rddata;
    logic [T-1:0] bram_w_addr;
    logic  [T-1:0] bram_w_rddata;
	logic [T-1:0] n_val, c_val, k_val;
	logic [T-1:0] bram_o_rddata;
	logic [T-1:0] bram_w_wrdata;
	logic [T-1:0]bram_i_wrdata;
	logic [T-1:0] bram_o_wrdata;
	logic [3:0] bram_w_we, bram_i_we, bram_o_we;
	
	logic          bram_oc_clk;
    logic          bram_oc_rst;
    logic          bram_oc_en;
    logic  [3:0]   bram_oc_we;    
    logic  [T-1:0] bram_oc_addr;  //[11:0]
    logic  [T-1:0] bram_oc_wrdata;
    logic [T-1:0]  bram_oc_rddata;
    //logic          bram_oc_rstb;
	
    dnn dnntb(.clk(clk), .reset(reset), .ps_control(ps_control), .pl_status(pl_status), .bias(bias), .n_val(n_val), .c_val(c_val), .k_val(k_val),
       .bram_i_addr(bram_i_addr), .bram_i_rddata(bram_i_rddata), .bram_w_addr(bram_w_addr), .bram_w_rddata(bram_w_rddata),
       .bram_oc_clk(bram_oc_clk), .bram_oc_rst(bram_oc_rst), .bram_oc_en(bram_oc_en), .bram_oc_we(bram_oc_we), 
       .bram_oc_addr(bram_oc_addr), .bram_oc_wrdata(bram_oc_wrdata), .bram_oc_rddata(bram_oc_rddata));//, .bram_oc_rstb(bram_oc_rstb));
    
    w_memory_sim wms(.clk(clk), .reset(reset), .bram_w_addr(bram_w_addr), 
                     .bram_w_rddata(bram_w_rddata), .bram_w_wrdata(bram_w_wrdata),
                     .bram_w_we(bram_w_we));
    i_memory_sim ims(.clk(clk), .reset(reset), .bram_i_addr(bram_i_addr),
                     .bram_i_rddata(bram_i_rddata), .bram_i_wrdata(bram_i_wrdata),
                     .bram_i_we(bram_i_we));
    assign bias = 4'h0000;
    assign bram_oc_clk = clk;
    assign bram_oc_rst = reset;
    assign bram_oc_en = 1;
    assign bram_oc_we = 4'h0;
 //   assign bram_oc_addr = 4'h0000;
    assign bram_oc_wrdata = 4'h0000;
	int j, i;
    initial clk=0;
    int filehandle, filehandle1;
    initial begin 
        filehandle = $fopen("optb.mem","w");
        filehandle1 = $fopen("optb1.mem","w");
    end
    always #5 clk = ~clk;
    
    initial begin
        bram_oc_addr = 4'h0000;
        n_val = 4'h0000 ;
        k_val = 3;//4'h0003 ;
        c_val = 30;//4'h001E ;
        @(posedge clk);
        @(posedge clk);
        ps_control = 0;
        @(posedge clk);
        @(posedge clk);
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        @(posedge clk); 
		for(j=0;j<2;j=j+1) begin	
		    n_val = 4'h0000;	    
			@(posedge clk);
			@(posedge clk);
			ps_control = 1;
          
            wait(pl_status[0] == 1'b1);

            @(posedge clk);
            @(posedge clk);
        
            ps_control = 0;
            @(posedge clk);
	        @(posedge clk);

			wait(pl_status[0] == 1'b0);
		    @(posedge clk);
            @(posedge clk);
            
            n_val = 4'h0001;
            for(i = 0; i< 900; i++) begin
                @(posedge clk);
                bram_oc_addr = bram_oc_addr + 4;
                $fdisplay (filehandle, "%h" ,bram_oc_rddata);
            end
            @(posedge clk);
            @(posedge clk);
            n_val = 4'h0000;
		end    
    end              
  /*  always @(posedge clk) begin
       if(pl_status[0] == 1'b1) begin
           $fdisplay (filehandle, bram_oc_rddata);
           bram_oc_addr <= bram_oc_addr + 1;
       end
    end*/
endmodule

module w_memory_sim(
    input         clk,
    input         reset,
    input        [T-1:0] bram_w_addr,
    output logic [T-1:0] bram_w_rddata,
    input        [T-1:0] bram_w_wrdata,
    input         [3:0] bram_w_we);

    logic signed [8:0][T-1:0] testDataw;
    integer filehandle, i;
    real j;

    initial begin
        filehandle=$fopen("testdataw.mem", "r");
        if (filehandle == 0) $error("testdataw.mem not opened");
        for (i=0; i<9; i=i+1) begin
            j = $fscanf(filehandle,"%h", testDataw [i]);
            if (j != 1) begin
                testDataw[i] = j;
            end
        end
    end 
    always @(posedge clk) begin
        bram_w_rddata <= testDataw[bram_w_addr[31:2]];
        if (bram_w_we == 4'hf)
            testDataw[bram_w_addr[31:2]] <= bram_w_wrdata;
        else if (bram_w_we != 0)
            $display("ERROR: Memory simulation model only implemented we = 0 and we=4'hf. Simulation will be incorrect.");              
    end
endmodule // memory_sim

module i_memory_sim(
    input         clk,
    input         reset,
    input        [T-1:0] bram_i_addr,
    output logic [T-1:0] bram_i_rddata,
    input        [T-1:0] bram_i_wrdata,
    input         [3:0] bram_i_we);

    logic signed [1023:0][T-1:0] testDatai;
	integer filehandle, i;
	real j;
	
    initial begin
        filehandle=$fopen("testdatai.mem", "r");
        if (filehandle == 0) $error("testdatai.mem not opened");
        for (i=0; i<1024; i=i+1) begin
            j = $fscanf(filehandle,"%h", testDatai [i]);
            if (j != 1) begin
                testDatai[i] = j;
            end
        end
    end 
    always @(posedge clk) begin
        bram_i_rddata <= testDatai[bram_i_addr[31:2]];
        if (bram_i_we == 4'hf)
            testDatai[bram_i_addr[31:2]] <= bram_i_wrdata;
        else if (bram_i_we != 0)
            $display("ERROR: Memory simulation model only implemented we = 0 and we=4'hf. Simulation will be incorrect.");             
    end
endmodule // memory_sim 