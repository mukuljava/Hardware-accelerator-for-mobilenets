// Peter Milder
// ESE 587 Hardware Architectures for Deep Learning
// Reference code for "CLP-Nano" design

// Description:
// This C code will serve as a demonstration of the function of the "CLP-Nano" design
// presented as part of Topic 11. Please see Topic 11 slides for more information.

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char *argv[]) {

	// -----------------------------------------------------------
	// Arguments
	if (argc != 8) {
		printf("error: N, M, R, C, S, K, G\n");
		return(1);
	}


	int N=atoi(argv[1]);
	int M=atoi(argv[2]);
	int R=atoi(argv[3]);
	int C=atoi(argv[4]);
	int S=atoi(argv[5]);
	int K=atoi(argv[6]);
	int G=atoi(argv[7]);

	int RPrime = (R-1)*S+K;
	int CPrime = (C-1)*S+K;

	if ((N<=0) || (M<=0) || (R<=0) || (C<=0) || (S<=0) || (K<=0) || (G<=0)) {
		printf("ERROR: 0 or negative parameter\n");
		return(1);
	}
	if(N%G!=0){
        printf("ERROR: G should be a factor of N");
        return(1);
	}

	// ------------------------------------------------------------
	// Declare data structures that will reside in off chip memory.
	// Note: if these get too large, you will eventually run out of space
	// on your stack, and this will cause a segmentation fault. A more flexible
	// approach would be to use malloc and store this data on the heap.
	float I[N][RPrime][CPrime];
	float O[M][R][C];
	float B[M];
	float W[M][N/G][K][K];

	// -----------------------------------------------------------
	// Declare data structures that will reside in BRAM in your hardware
	// design. These will be accessible to your CLP-Lite hardware system
	float Ibuf[RPrime][CPrime];
	float Wbuf[K][K];
	float Obuf[R][C];
	float Bbuf;


	// -----------------------------------------------------------
	// As an example, we will generate random inputs, weights, and bias.
	// We will also store these and the parameters to a text file (to
	// make it easy to later verify the correctness of this design)
	FILE *ip, *op, *test;
	ip = fopen("ip.txt", "w");
	test = fopen("test.txt", "w");

	fprintf(ip, "%d\n%d\n%d\n%d\n%d\n%d\n%d\n", N, M, R, C, S, K, G);

	// Init. RNG
	srand((unsigned int)time(NULL));

	// Generate random test inputs
	fprintf(ip, "INPUT: ");
	for (int n=0; n<N; n++) {
		for (int r=0; r<RPrime; r++) {
			for (int c=0; c<CPrime; c++) {
				I[n][r][c] = 2*((float)rand())/RAND_MAX-1;
				fprintf(ip, "%.20f\n", I[n][r][c]);
			}
		}
	}
    fprintf(ip, "WEIGHTS: ");
	// Generate random weights
	for (int m=0; m<M; m++)
		for (int n=0; n<N/G; n++)
			for (int i=0; i<K; i++)
				for (int j=0; j<K; j++) {
					W[m][n][i][j] = 2*((float)rand())/RAND_MAX-1;
					fprintf(ip, "%.20f\n", W[m][n][i][j]);
				}

	// Generate random biases
	fprintf(ip, "BIASES ");
	for (int m=0; m<M; m++) {
		B[m] = 2*((float)rand())/RAND_MAX-1;
		fprintf(ip, "%.20f\n", B[m]);
	}

	fclose(ip);

	// --------------------------------------------------------------
	// Main loops
	// For normal Convolution
	if(G == 1){
        for (int m=0; m<M; m++) {

            // Copy this output's bias value to bias buffer
            Bbuf = B[m];

            for (int n=0; n<N; n++) {

                // Copy the current input feature map to the
                // input buffer.
                for (int rr=0; rr<RPrime; rr++) {
                    for (int cc=0; cc<CPrime; cc++) {
                        Ibuf[rr][cc] = I[n][rr][cc];
                    }
                }

                // Copy this feature map's weights into Wbuf
                for (int i=0; i<K; i++) {
                    for (int j=0; j<K; j++) {
                        Wbuf[i][j] = W[m][n][i][j];
                    }
                }

                // -------------------------------------------------
                // Begin hardware functionality. Your HW system should do
                // do the following operations
                for (int i=0; i<K; i++) {
                    for (int j=0; j<K; j++) {
                        fprintf(test, "########i,j %d %d == %d##########\n", i, j, (i*3+j));
                        for (int rr=0; rr<R; rr++) {
                            for (int cc=0; cc<C; cc++) {
                                float t1 = Wbuf[i][j] * Ibuf[S*rr+i][S*cc+j];
                                fprintf(test, "Intermediate vals: %d %d == %d\n", S*rr+i,S*cc+j, ((S*rr+i)*32+S*cc+j) );
                                // mux: if i==0, j==0, and n==0 we need to add bias.
                                // otherwise, we accumulate
                                float t2 = (i==0 && j==0 && n==0) ? Bbuf : Obuf[rr][cc];
                                Obuf[rr][cc] = t1 + t2;
                                //write values
                            }
                        }
                    }
                }
                // End hardware functionality
                // ---------------------------------------------------
            }

            // Read data from Obuf and store it into main memory O buffer
            // Note again we have to check that we don't go past the end of
            // the O buffer
            for (int rr=0; rr < R; rr++) {
                for (int cc=0; cc < C; cc++) {
                    O[m][rr][cc] = Obuf[rr][cc];
                }
            }
        }
	}
	//For depthwise convolution
	else if(G == N){
            for (int m=0, n = 0; m<M && n<N; m++, n++) {

            // Copy this output's bias value to bias buffer
            Bbuf = 0;//B[m];

                // Copy the current input feature map to the
                // input buffer.
                for (int rr=0; rr<RPrime; rr++) {
                    for (int cc=0; cc<CPrime; cc++) {
                        Ibuf[rr][cc] = I[n][rr][cc];
                    }
                }

                // Copy this feature map's weights into Wbuf
                for (int i=0; i<K; i++) {
                    for (int j=0; j<K; j++) {
                        Wbuf[i][j] = W[m][0][i][j];
                    }
                }

                // -------------------------------------------------
                // Begin hardware functionality. Your HW system should do
                // do the following operations
                for (int i=0; i<K; i++) {
                    for (int j=0; j<K; j++) {
                        for (int rr=0; rr<R; rr++) {
                            for (int cc=0; cc<C; cc++) {
                                float t1 = Wbuf[i][j] * Ibuf[S*rr+i][S*cc+j];

                                // mux: if i==0, j==0, and n==0 we need to add bias.
                                // otherwise, we accumulate
                                float t2 = (i==0 && j==0 && n==0) ? Bbuf : Obuf[rr][cc];
                                Obuf[rr][cc] = t1 + t2;
                            }
                        }
                    }
                }
                // End hardware functionality
                // ---------------------------------------------------

            // Read data from Obuf and store it into main memory O buffer
            // Note again we have to check that we don't go past the end of
            // the O buffer
            for (int rr=0; rr < R; rr++) {
                for (int cc=0; cc < C; cc++) {
                    O[m][rr][cc] = Obuf[rr][cc];
                }
            }
        }
	}
    fclose(test);
	// ---------------------------------------------------
	// Store results to text file for easy checking.
	// Write the results to op.txt
	op = fopen("op.txt", "w");
	for (int m=0; m<M; m++)
		for (int r=0; r<R; r++)
			for (int c=0; c<C; c++)
				fprintf(op,"%.20f\n", O[m][r][c]);

	fclose(op);

	return 0;
}



