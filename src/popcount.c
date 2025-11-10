#include <stdio.h>

// Naive implementation
int popcount_naive(unsigned int x) {
    int count = 0;
    while (x) {
        count += x & 1;
        x >>= 1;
    }
    return count;
}

// Brian Kernighan's algorithm
int popcount_kernighan(unsigned int x) {
    int count = 0;
    while (x) {
        x &= x - 1;
        count++;
    }
    return count;
}

// Lookup table method
int popcount_lookup(unsigned int x) {
    static const int lookup[16] = {0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4};
    int count = 0;
    for (int i = 0; i < 8; i++) {
        count += lookup[x & 0xF];
        x >>= 4;
    }
    return count;
}

// Parallel counting (SWAR algorithm)
int popcount_parallel(unsigned int x) {
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4)) & 0x0F0F0F0F;
    x = x + (x >> 8);
    x = x + (x >> 16);
    return x & 0x3F;
}

int main() {
    unsigned int test_values[] = {0x12345678, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555, 0x0F0F0F0F};
    int n = sizeof(test_values) / sizeof(test_values[0]);
    
    int total = 0;
    for (int i = 0; i < n; i++) {
        total += popcount_naive(test_values[i]);
        total += popcount_kernighan(test_values[i]);
        total += popcount_lookup(test_values[i]);
        total += popcount_parallel(test_values[i]);
    }
    
    printf("%d\n", total);
    return 0;
}
