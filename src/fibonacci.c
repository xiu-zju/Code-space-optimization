#include <stdio.h>

// Recursive implementation
int fib_recursive(int n) {
    if (n <= 1) return n;
    return fib_recursive(n - 1) + fib_recursive(n - 2);
}

// Iterative implementation
int fib_iterative(int n) {
    if (n <= 1) return n;
    int a = 0, b = 1, c;
    for (int i = 2; i <= n; i++) {
        c = a + b;
        a = b;
        b = c;
    }
    return b;
}

// Tail-recursive implementation (with helper)
int fib_tail_helper(int n, int a, int b) {
    if (n == 0) return a;
    if (n == 1) return b;
    return fib_tail_helper(n - 1, b, a + b);
}

int fib_tail_recursive(int n) {
    return fib_tail_helper(n, 0, 1);
}

int main() {
    int n = 20;
    
    // Test all three implementations
    int result1 = fib_recursive(n);
    int result2 = fib_iterative(n);
    int result3 = fib_tail_recursive(n);
    
    // Output for verification (all should be the same)
    printf("%d\n", result1 + result2 + result3);
    return 0;
}
