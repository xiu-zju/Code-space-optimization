#include <stdio.h>
#include <stdlib.h>

typedef struct Node {
    int data;
    struct Node* next;
} Node;

// Function pointer type for callback
typedef void (*NodeCallback)(Node* node, void* context);

// Create a new node
Node* create_node(int data) {
    Node* node = (Node*)malloc(sizeof(Node));
    node->data = data;
    node->next = NULL;
    return node;
}

// Traverse list with callback
void traverse_list(Node* head, NodeCallback callback, void* context) {
    Node* current = head;
    while (current != NULL) {
        callback(current, context);
        current = current->next;
    }
}

// Callback to sum node values
void sum_callback(Node* node, void* context) {
    int* sum = (int*)context;
    *sum += node->data;
}

// Callback to count nodes
void count_callback(Node* node, void* context) {
    int* count = (int*)context;
    (*count)++;
}

// Free the list
void free_list(Node* head) {
    Node* current = head;
    while (current != NULL) {
        Node* next = current->next;
        free(current);
        current = next;
    }
}

int main() {
    // Create a linked list: 1 -> 2 -> 3 -> 4 -> 5
    Node* head = create_node(1);
    head->next = create_node(2);
    head->next->next = create_node(3);
    head->next->next->next = create_node(4);
    head->next->next->next->next = create_node(5);
    
    int sum = 0;
    int count = 0;
    
    traverse_list(head, sum_callback, &sum);
    traverse_list(head, count_callback, &count);
    
    free_list(head);
    
    // Output for verification
    printf("%d\n", sum + count);
    return 0;
}
