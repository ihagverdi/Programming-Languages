#ifndef __HW3__
#define __HW3__

typedef enum  {IDENT_NODE, SEND_NODE, SCHEDULE_NODE, RECIPIENT_NODE, ERROR_NODE} NodeType;

extern int isLocal; //for scoping purposes



typedef struct IdentVal {
    int lineNum;
    char* identifier;
} IdentVal;

typedef struct IdentNode {
    int isLocal;
    char* identifier;
    char* value;
    struct ListNode* next;
} IdentNode;

typedef struct RecipientNode {
    int name_exists;
    char* name;
    char* address;
    struct ListNode* next;
} RecipientNode;

typedef struct SendNode {
    char* sender;
    char* recipient;
    char* message;
    struct ListNode* next;
} SendNode;

typedef struct ScheduleNode {
    char* sender;    
    char* recipient;
    char* date;
    char* time;
    char* message;
    struct ListNode* next;
} ScheduleNode;

typedef struct ErrorNode {
    int lineNum;
    char* errorMessage;    
    struct ListNode* next;
} ErrorNode;

typedef union {
    IdentNode ident;
    SendNode send;
    ScheduleNode schedule;
    RecipientNode recipient;
    ErrorNode error;
} Node;

typedef struct ListNode {
    NodeType type;
    Node* node;
} ListNode;

#endif
