#include <stdio.h>

#define N 4

void mat_mult(int A[N][N], int B[N][N], int C[N][N]) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            C[i][j] = 0;
            for (int k = 0; k < N; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}

int main() {
    int A[N][N], B[N][N], C[N][N];
    
    // Initialize matrices
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i][j] = i + j + 1;
            B[i][j] = (i == j) ? 1 : 0;  // Identity matrix
        }
    }
    
    mat_mult(A, B, C);
    
    // Output result for verification
    printf("%d\n", C[N-1][N-1]);
    return 0;
}
