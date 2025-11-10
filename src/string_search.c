#include <stdio.h>
#include <string.h>

// Simple string search (strstr-like implementation)
char* string_search(const char* haystack, const char* needle) {
    if (!*needle) return (char*)haystack;
    
    for (const char* h = haystack; *h; h++) {
        const char* h_temp = h;
        const char* n_temp = needle;
        
        while (*h_temp && *n_temp && (*h_temp == *n_temp)) {
            h_temp++;
            n_temp++;
        }
        
        if (!*n_temp) {
            return (char*)h;
        }
    }
    
    return NULL;
}

int main() {
    const char* text = "The quick brown fox jumps over the lazy dog";
    const char* pattern1 = "fox";
    const char* pattern2 = "lazy";
    const char* pattern3 = "cat";
    
    char* result1 = string_search(text, pattern1);
    char* result2 = string_search(text, pattern2);
    char* result3 = string_search(text, pattern3);
    
    // Output positions for verification
    int pos1 = result1 ? (int)(result1 - text) : -1;
    int pos2 = result2 ? (int)(result2 - text) : -1;
    int pos3 = result3 ? (int)(result3 - text) : -1;
    
    printf("%d\n", pos1 + pos2 + pos3);
    return 0;
}
