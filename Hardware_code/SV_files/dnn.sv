`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.05.2020 04:12:49
// Design Name: 
// Module Name: dnn
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


module dnn(clk, reset, ps_control, pl_status, bias, n_val, k_val, c_val, bram_i_addr, bram_i_rddata, 
           bram_w_addr, bram_w_rddata, bram_oc_clk, bram_oc_rst, bram_oc_en, bram_oc_we, 
           bram_oc_addr, bram_oc_wrdata, bram_oc_rddata);//, bram_oc_rstb);
    parameter            T = 32;
    input                clk;
    input                reset;
    //bias, N, control, status
    input        [T-1:0] ps_control;
    output       [T-1:0] pl_status;
    input        [T-1:0] bias;
    input logic  [T-1:0] n_val;
    input        [T-1:0] k_val;
    input        [T-1:0] c_val;
  //  input        [T-1:0] read_val;
    //BRAM I signals
    output       [T-1:0] bram_i_addr; //[11:0]
    input        [T-1:0] bram_i_rddata;
    //BRAM W signals
    output       [T-1:0]   bram_w_addr; //[5:0]
    input        [T-1:0] bram_w_rddata;
    //controller signals
    input logic          bram_oc_clk;
    input logic          bram_oc_rst;
    input logic          bram_oc_en;
    input logic  [3:0]   bram_oc_we;	
    input logic  [T-1:0] bram_oc_addr;  //[11:0]
    input logic  [T-1:0] bram_oc_wrdata;
    output logic [T-1:0] bram_oc_rddata;
    logic                bram_oc_rstb; //removed  output
    //output bram port A signals
    logic        [T-1:0] bram_oa_addr; //[11-1]
    logic        [T-1:0] bram_oa_wrdata;
    logic        [T-1:0] bram_oa_rddata;
    logic        [3:0]   bram_oa_we;
    logic                rsta_busy;
    //output bram port B signals
    logic        [T-1:0] bram_ob_addr; //[11-1]
    logic        [T-1:0] bram_ob_wrdata;
    logic        [T-1:0] bram_ob_rddata;
    logic        [3:0]   bram_ob_we;
    logic                bram_ob_rstb;
    //output bram port B signals
    logic                clkb;
    logic                rstb;
    logic                enb;
    logic        [3:0]   web;
	logic        [T-1:0] addrb; //[11-1]
    logic        [T-1:0] dinb;
    logic        [T-1:0] doutb;
    logic                rstb_busy;
    //floating point signals
    logic                i_valid, w_valid, a_valid, o_valid;
    logic        [T-1:0] acc;
    //common signal for output bram enable
    logic                bram_o_en;
    logic                w_add_g;
    //temporary for debugging
    /////////////////////////////////////////////////////////
    int                  filehandle1;
    initial begin 
        filehandle1 = $fopen("tester","w");
    end
    always@(posedge clk) begin
        $fdisplay (filehandle1, "%h" ,bram_oa_rddata);
    end
    //////////////////////////////////////////////////////////
    std_conv lay1(.clk(clk), .reset(reset),  .ps_control(ps_control), .pl_status(pl_status), .bias(bias), .k_val(k_val), .c_val(c_val), .bram_i_addr(bram_i_addr), 
                  .bram_w_addr(bram_w_addr), .bram_oa_addr(bram_oa_addr), .bram_oa_we(bram_oa_we), .bram_ob_addr(bram_ob_addr), 
				  .bram_ob_we(bram_ob_we), .i_valid(i_valid), .w_valid(w_valid), .a_valid(a_valid), .o_valid(o_valid), .w_add_g(w_add_g));
    floating_point_0 mac(
                    .aclk(clk),
                    .s_axis_a_tvalid(i_valid),
                    .s_axis_a_tdata(bram_i_rddata),
                    .s_axis_b_tvalid(w_valid),
                    .s_axis_b_tdata(bram_w_rddata),
                    .s_axis_c_tvalid(a_valid),
                    .s_axis_c_tdata(acc),
                    .m_axis_result_tvalid(o_valid),
                    .m_axis_result_tdata(bram_oa_wrdata)
                  );
     blk_mem_gen_0 op_bram (
                  .clka(clk), 
                  .rsta(reset),
                  .ena(bram_o_en), 
                  .wea(bram_oa_we), 
                  .addra(bram_oa_addr),
                  .dina(bram_oa_wrdata), 
                  .douta(bram_oa_rddata),
                  .clkb(clkb),
                  .rstb(rstb),
                  .enb(enb), 
                  .web(web),
                  .addrb(addrb),
                  .dinb(dinb),
                  .doutb(doutb),
                  .rsta_busy(rsta_busy),
                  .rstb_busy(rstb_busy)
                );
                  

     //logic to control when to send bram_o_rddata or bias
	 always_comb begin
		if ((n_val == 0) & (w_add_g == 0))begin
		    acc = bias;
		end
		else begin
		    acc = bram_ob_rddata;
		end
	 end
	 
   	 always_comb begin
	     if ((n_val == 4'h0001) & (ps_control == 0) & (pl_status == 0)) begin
	         clkb = clk;//bram_oc_clk;
	         rstb = reset;//bram_oc_rst;
	         enb = bram_oc_en;
	         web = bram_oc_we;
	         addrb = bram_oc_addr;
	         dinb = bram_oc_wrdata;
	         bram_oc_rddata = doutb;
	         bram_oc_rstb = rstb_busy;
	         bram_ob_rddata = doutb;
	     end
		 else begin
		 	 clkb = clk;
             rstb = reset;
             enb = bram_o_en;
		     web = bram_ob_we; 
			 addrb = bram_ob_addr;
			 dinb = bram_ob_wrdata;
			 bram_ob_rddata = doutb;
			 bram_ob_rstb = rstb_busy;
			 bram_oc_rddata = doutb; 
		 end
     end
     
     assign bram_o_en = 1;
     assign bram_ob_wrdata = 4'h0000;
endmodule

module std_conv(clk, reset,  ps_control, pl_status, bias, k_val, c_val, bram_i_addr, bram_w_addr, bram_oa_addr, bram_oa_we, 
                bram_ob_addr, bram_ob_we, i_valid, w_valid, a_valid, o_valid, w_add_g);
    parameter            T = 32;
    input                clk;
    input                reset;
    input        [T-1:0] ps_control;
    output logic [T-1:0] pl_status;
    input logic  [T-1:0] bias, k_val, c_val;
    output logic [T-1:0]  bram_i_addr; //[11:0]
    output logic [T-1:0]  bram_w_addr; //[5:0]
    output logic [T-1:0]  bram_oa_addr;//[11:1]
    output logic [3:0]    bram_oa_we;
	output logic [T-1:0]  bram_ob_addr;//[11:1]
    output logic [3:0]   bram_ob_we; 
    output logic         i_valid, w_valid, a_valid;
    input logic          o_valid;
    logic        [T-1:0] counter1, counter2, counter3, counter4;
    logic                start, r_done, m_done, k_done, c_done;
    logic        [3:0]   row, col;
    output logic         w_add_g;
    
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            bram_i_addr <= 0;
            bram_w_addr <= 0;
            bram_oa_addr <= 0;
			bram_ob_addr <= 0;
            pl_status <= 0;
            i_valid <= 0;
            w_valid <= 0;
            a_valid <= 0;
            counter1 <= 0;
            counter2 <= 0;
            counter3 <= 0;
            counter4 <= 0;
            row <= 1;
            col <= 1;
            k_done <= 0;
            w_add_g <= 0;
        //    g_done <= 0;
        end
        if ((ps_control == 1) & (pl_status == 0) & (k_done == 0)) begin
            bram_i_addr <= bram_i_addr + 4;// change +1
			bram_ob_addr <= bram_ob_addr + 4; //bram_ob_addr <= bram_ob_addr ;// change +1
            counter1 <= counter1 + 1;
            counter2 <= counter2 + 1;
            i_valid <= 1;
            w_valid <= 1;
            a_valid <= 1;
        end
        if ((r_done == 1) & (k_done == 0) & (pl_status == 0)) begin             //one row done
            bram_i_addr <= bram_i_addr + (k_val * 4);//change +3
            counter1 <= 0;
        end
        if ((m_done == 1) & (k_done == 0) & (pl_status == 0)) begin                           //one matrix done
            bram_w_addr <= bram_w_addr + 4;                // inc weight// change +1
            if((((bram_w_addr+4)%(k_val * 4)) == 0)) begin // if row change in weight// change %3
                row <= row + 1;
                bram_i_addr <= row * ((c_val + k_val -1) * 4);//change *32
                col <= 1;
            end
            else begin
                bram_i_addr <= (row-1)*((c_val + k_val -1) * 4) + col*4;//change (row-1)*32 + col;
                col <= col + 1;
            end
            counter2 <= 0;                                  
            bram_ob_addr <= 0;
        end
        if ((bram_w_addr > 0) & (start == 1)) begin
            w_add_g <= 1;
        end
        if ((o_valid == 1) & (start == 1)) begin
            bram_oa_addr <= bram_oa_addr + 4;//bram_oa_addr <= bram_oa_addr + 1;                //write data
            counter3 <= counter3 + 1;
            counter4 <= counter4 + 1;
        end
        if ((counter3 == ((c_val * c_val) -1)) & (start == 1)) begin         
            bram_oa_addr <= 0;//bram_oa_addr <= 0;
            counter3 <= 0;
        end
        if((c_done == 1) & (pl_status == 0)) begin
            pl_status <= 1;
            counter4 <= 0;
        end 
        if ((counter2 == ((c_val * c_val) -1)) & (r_done == 1) & (bram_w_addr == (k_val * k_val * 4)) & (pl_status == 0)) begin //bram_i_addr == 1023) begin//change 8
            k_done <= 1;
        end
        if ((k_done == 1) & (pl_status == 0)) begin
            i_valid <= 0;
            w_valid <= 0;
            a_valid <= 0;
        end
        if ((ps_control == 0) & (pl_status == 0)) begin
            w_add_g <= 0;
        end
        if ((ps_control == 0) & (pl_status == 1)) begin
            bram_i_addr <= 0;
            bram_w_addr <= 0;
            bram_oa_addr <= 0;
            bram_ob_addr <= 0;
            pl_status <= 0;
            i_valid <= 0;
            w_valid <= 0;
            a_valid <= 0;
            counter1 <= 0;
            counter2 <= 0;
            counter3 <= 0;
            counter4 <= 0;
            row <= 1;
            col <= 1;
            k_done <= 0;
            w_add_g <= 0;
        end
    end
    assign r_done = (counter1 == (c_val -1)) & (ps_control == 1);
    assign m_done = (counter2 == ((c_val * c_val) -1)) & (r_done == 1) & (ps_control == 1);
    assign c_done = (counter3 == ((c_val * c_val) -1)) & (counter4 == (((c_val * c_val) * (k_val * k_val))-1)) & (ps_control == 1);
	assign bram_oa_we = ((o_valid == 1) & (start == 1)) ? 4'hf : 4'h0;
	assign start = (pl_status == 0) & (ps_control == 1);
	assign bram_ob_we = 4'h0;
endmodule