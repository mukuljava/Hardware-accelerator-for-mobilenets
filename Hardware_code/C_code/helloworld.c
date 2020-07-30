/******************************************************************************
 *
 * Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Use of the Software is limited solely to applications:
 * (a) running on a Xilinx device, or
 * (b) that interact with a Xilinx device through a bus or interconnect.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of the Xilinx shall not be used
 * in advertising or otherwise to promote the sale, use or other dealings in
 * this Software without prior written authorization from Xilinx.
 *
 ******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "onetestdata.h"
#include "twotestdata.h"
#include "threetestdata.h"

#define XPAR_DNN_0_S00_AXI_BASEADDR_BIAS 0x43C00008;

int verify_results_con1(float expected[XM1 * XR1 * XC1], float y[XM1][XR1][XC1]);
int verify_results_con2(float expected[XM2 * XR2 * XC2], float y[XM2][XR2][XC2]);
int verify_results_con3(float expected[XM3 * XR3 * XC3], float y[XM3][XR3][XC3]);
int main()
{
	init_platform();
	volatile float* bramW = (float*)XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR;
	volatile float* bramI = (float*)XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR;
	volatile float* bramO = (float*)XPAR_AXI_BRAM_CTRL_2_S_AXI_BASEADDR;
	volatile float* bias = (float*)XPAR_DNN_0_S00_AXI_BASEADDR_BIAS;
	volatile unsigned int* hw = (unsigned int*)XPAR_DNN_0_S00_AXI_BASEADDR;
	int N1=3, M1=3, R1=30, C1=30, S1=1, K1=3, G1=1, RPrime1 = (R1-1)*S1+K1, CPrime1 = (C1-1)*S1+K1;
	int N2=3, M2=3, R2=28, C2=28, S2=1, K2=3, G2=3, RPrime2 = (R2-1)*S2+K2, CPrime2 = (C2-1)*S2+K2;
	int N3=3, M3=3, R3=28, C3=28, S3=1, K3=1, G3=1, RPrime3 = (R3-1)*S3+K3, CPrime3 = (C3-1)*S3+K3;

	//////////////////////////////////////////////////////////////////////////
	float I1[N1][RPrime1][CPrime1];
	float O1[M1][R1][C1];
	float B1[M1];
	float W1[M1][N1/G1][K1][K1];

	///////////////////////////////////////////////////////////////////////////
	float O2[M2][R2][C2];
	float B2[M2];
	float W2[M2][N2/G2][K2][K2];

	////////////////////////////////////////////////////////////////////////////
	float O3[M3][R3][C3];
	float B3[M3];
	float W3[M3][N3/G3][K3][K3];

	////////////////////////////////////////////////////////////////////////////

	int cnt1= 0;
	for (int n=0; n<N1; n++) {
		for (int r=0; r<RPrime1; r++) {
			for (int c=0; c<CPrime1; c++) {
				I1[n][r][c] = i_val[cnt1];
				cnt1++;
			}
		}
	}

	cnt1 = 0;
	for (int m=0; m<M1; m++) {
		for (int n=0; n<N1/G1; n++) {
			for (int i=0; i<K1; i++) {
				for (int j=0; j<K1; j++) {
					W1[m][n][i][j] = w_val1[cnt1];
					cnt1++;
				}
			}
		}
	}

	cnt1 = 0;
	for (int m=0; m<M2; m++) {
		for (int n=0; n<N2/G2; n++) {
			for (int i=0; i<K2; i++) {
				for (int j=0; j<K2; j++) {
					W2[m][n][i][j] = w_val2[cnt1];
					cnt1++;
				}
			}
		}
	}

	cnt1 = 0;
	for (int m=0; m<M3; m++) {
		for (int n=0; n<N3/G3; n++) {
			for (int i=0; i<K3; i++) {
				for (int j=0; j<K3; j++) {
					W3[m][n][i][j] = w_val3[cnt1];
					cnt1++;
				}
			}
		}
	}

	cnt1= 0;
	for (int m=0; m<M1; m++) {
		B1[m] =  b_val1[cnt1];
		cnt1++;
	}

	cnt1= 0;
	for (int m=0; m<M2; m++) {
		B2[m] = b_val2[cnt1];
		cnt1++;
	}

	cnt1= 0;
	for (int m=0; m<M3; m++) {
		B3[m] =  b_val3[cnt1];
		cnt1++;
	}

	int z = 0, y = 0, x = 0;
	if(G1 ==1){
		for (int m=0; m<M1; m++) {
			//Load bias
			bias[0] = B1[m];
			//Load C and K
			hw[4] = K1;
			hw[5] = C1;
			int n;
			for (n=0; n<N1; n++) {
				//Load n-val
				hw[3] = n;
				//load input map
				z = 0;
				for (int rr=0; rr<RPrime1; rr++) {
					for (int cc=0; cc<CPrime1; cc++) {
						bramI[z] = I1[n][rr][cc];
						//printf("bram_val Input %.20f\n", bramI[z]);
						z++;
					}
				}
				//load weight map
				y = 0;
				for (int i=0; i<K1; i++) {
					for (int j=0; j<K1; j++) {
						bramW[y] = W1[m][n][i][j];
						//printf("bram_val Weights %.20f\n", bramW[y]);
						y++;
					}
				}
				//Start accelerator
				hw[0] = 1;
				//Wait for your accelerator to finish
				while ( (hw[1] & 0x1) == 0) {
					;
				}

				hw[0] = 0;
				//Wait for acknowledgment
				while ( (hw[1] & 0x1) != 0) {
					;
				}
			}
			// load 1 to n_val to a read data, when pl_status, ps_control is zero and n_val is 1 port switches
			hw[3] = 1;
			x = 0;
			//read output values
			for (int rr=0; rr < R1; rr++) {
				for (int cc=0; cc < C1; cc++) {
					//printf("%d bram_val output %.20f\n", x, bramO[x]);
					O1[m][rr][cc] = bramO[x];
					x++;
				}
			}
			hw[3] = 0;
		}
	}
	int errors1 = verify_results_con1(o_val1, O1);
//For testing layer 3 disable this part and enable next commented section
	if(G2 ==N2){
		for (int m=0; m<M2; m++) {
			//Load bias
			bias[0] = B2[m];
			//Load C and K
			hw[4] = K2;
			hw[5] = C2;
			//Load 0 to n-val
			hw[3] = 0;
			//load input map
			z = 0;
			for (int rr=0; rr<RPrime2; rr++) {
				for (int cc=0; cc<CPrime2; cc++) {
					bramI[z] = O1[m][rr][cc];
					//printf("bram_val Input %.20f\n", bramI[z]);
					z++;
				}
			}
			//load weight map
			y = 0;
			for (int i=0; i<K2; i++) {
				for (int j=0; j<K2; j++) {
					bramW[y] = W2[m][m][i][j];
					//printf("bram_val Weights %.20f\n", bramW[y]);
					y++;
				}
			}
			//Start accelerator
			hw[0] = 1;
			//Wait for your accelerator to finish
			while ( (hw[1] & 0x1) == 0) {
				;
			}
			hw[0] = 0;
			//Wait for acknowledgment
			while ( (hw[1] & 0x1) != 0) {
				;
			}
			// load 1 to n_val to read data, when pl_status, ps_control is zero and n_val is 1 port switches
			hw[3] = 1;
			x = 0;
			//read output
			for (int rr=0; rr < R2; rr++) {
				for (int cc=0; cc < C2; cc++) {
					//printf("%d bram_val output %.20f\n", x, bramO[x]);
					O2[m][rr][cc] = bramO[x];
					x++;
				}
			}
			hw[3] = 0;
		}
	}

 //For test purpose of layer 3 uncomment this part and disable layer2
/*	x=0;
	for (int m=0; m<M2; m++) {
		for (int rr=0; rr < R2; rr++) {
			for (int cc=0; cc < C2; cc++) {
				//printf("%d bram_val output %.20f\n", x, bramO[x]);
				O2[m][rr][cc] = o_val2[x];
				x++;
			}
		}
	}*/

	int errors2 = verify_results_con1(o_val2, O2);

	if(G3 ==1){
		for (int m=0; m<M3; m++) {
			//Load bias
			bias[0] = B3[m];
			//Load C and K
			hw[4] = K3;
			hw[5] = C3;
			int n;
			for (n=0; n<N3; n++) {
				//Load n-val
				hw[3] = n;
				//load input map
				z = 0;
				for (int rr=0; rr<RPrime3; rr++) {
					for (int cc=0; cc<CPrime3; cc++) {
						bramI[z] = O2[n][rr][cc];
						//printf("bram_val Input %.20f\n", bramI[z]);
						z++;
					}
				}
				//load weight map
				y = 0;
				for (int i=0; i<K3; i++) {
					for (int j=0; j<K3; j++) {
						bramW[y] = W3[m][n][i][j];
						//printf("bram_val Weights %.20f\n", bramW[y]);
						y++;
					}
				}
				//Start accelerator
				hw[0] = 1;
				//Wait for your accelerator to finish
				while ( (hw[1] & 0x1) == 0) {
					;
				}
				hw[0] = 0;
				//Wait for acknowledgment
				while ( (hw[1] & 0x1) != 0) {
					;
				}
			}
			// load 1 to n_val, when pl_status, ps_control is zero and n_val is 1 port switches
			hw[3] = 1;
			x = 0;
			for (int rr=0; rr < R3; rr++) {
				for (int cc=0; cc < C3; cc++) {
					//printf("%d bram_val output %.20f\n", x, bramO[x]);
					O3[m][rr][cc] = bramO[x];
					x++;
				}
			}
			hw[3] = 0;
		}
	}

	int errors3 = verify_results_con1(o_val3, O3);
	cleanup_platform();
	return 0;
}

int verify_results_con1(float expected[XM1 * XR1 * XC1], float y[XM1][XR1][XC1]){
	int errors=0, z=0;
	for (int i=0; i<XM1; i++){
		for (int j=0; j<XR1; j++){
			for (int k=0; j<XC1; j++){
				float precision = 0.001;
				if (((expected[z] - precision) < y[i][j][k]) &&
						((expected[z] + precision) > y[i][j][k])){
					;
				}
				else{
					errors++;
				}

				z++;
			}
		}
	}
	return errors;
}

int verify_results_con2(float expected[XM2 * XR2 * XC2], float y[XM2][XR2][XC2]){
	int errors=0, z=0;
	for (int i=0; i<XM2; i++){
		for (int j=0; j<XR2; j++){
			for (int k=0; j<XC2; j++){
				float precision = 0.001;
				if (((expected[z] - precision) < y[i][j][k]) &&
						((expected[z] + precision) > y[i][j][k])){
					;
				}
				else{
					errors++;
				}

				z++;
			}
		}
	}
	return errors;
}

int verify_results_con3(float expected[XM3 * XR3 * XC3], float y[XM3][XR3][XC3]){
	int errors=0, z=0;
	for (int i=0; i<XM3; i++){
		for (int j=0; j<XR3; j++){
			for (int k=0; j<XC3; j++){
				float precision = 0.001;
				if (((expected[z] - precision) < y[i][j][k]) &&
						((expected[z] + precision) > y[i][j][k])){
					;
				}
				else{
					errors++;
				}

				z++;
			}
		}
	}
	return errors;
}
