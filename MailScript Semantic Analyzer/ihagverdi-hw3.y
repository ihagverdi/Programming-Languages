%{
/*
Author: Hagverdi Ibrahimli
Date:   December 11th, 2023
*/
#ifdef YYDEBUG
  yydebug = 1;
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ihagverdi-hw3.h"

void yyerror (const char *msg) /* Called by yyparse on error */ {return; }
char* checkIdent(ListNode*, char* );
void createIdentNodeForGlobalList(char* , char* );
void createIdentNodeForLocalList(char* , char* );
ListNode* createRecipientNode(char* , char* , int );
ListNode* createRecipientList(ListNode* , ListNode* );
ListNode* createSendNodeList(char* , ListNode* , int );
ListNode* createSendNode(char* , ListNode* , int );
ListNode* createScheduleList(char* , char* , ListNode* , int , int);
ListNode* createScheduleNode(char* , char* , ListNode* );
int firstDateEarlier(ListNode* , ListNode* );
void substring(char * , char * , int , int );
char* getMonthName(char* );
void printSendListNotifications();
void printScheduleListNotifications();
int isLeapYear(int );

int found_error = 0;

ListNode* globalIdentList = NULL; //list of global identifiers
ListNode* identList = NULL; //list of identifier nodes - local
ListNode* AllSendStatements = NULL; 
ListNode* AllScheduleStatements = NULL; 

ListNode* rootNodeSend = NULL; //root that keeps dif. mail block statements
ListNode* rootNodeSchedule = NULL;//root that keeps dif. mail block schedule statements

ListNode* errorList = NULL; //list of error nodes
%}

%union {
    char* str;
    IdentVal identVal;
    ListNode* listNode;
}

%token <identVal> tIDENT
%token <identVal> tDATE
%token <identVal> tTIME
%token <str> tSTRING
%token <str> tADDRESS


%type <listNode> recipient
%type <listNode> setStatement
%type <listNode> recipientList
%type <listNode> scheduleStatement
%type <listNode> sendStatement
%type <listNode> sendStatements

%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tTO tFROM tSET tCOMMA tCOLON tLPR tRPR tLBR tRBR tAT 
%start program
%%

program : statements
;

statements : 
            | setStatement statements{
            }
            | mailBlock statements{

            }
;

mailBlock: tMAIL tFROM tADDRESS tCOLON statementList tENDMAIL{
    char* address = strdup($3);
    ListNode* ptr = AllSendStatements;
    while(ptr != NULL) {
        ptr->node->send.sender = (address);
        ptr = ptr->node->send.next;
    }
    
    if (rootNodeSend == NULL)   {
        rootNodeSend = AllSendStatements;
    }
    
    else {
        ListNode* tmp = rootNodeSend;
        while (tmp->node->send.next != NULL) {
            tmp = tmp->node->send.next;
        }
        tmp->node->send.next = AllSendStatements;
    }

    ListNode* ptr1 = AllScheduleStatements;
    while(ptr1 != NULL) {
        ptr1->node->schedule.sender = (address);
        ptr1 = ptr1->node->schedule.next;
    }
    //point of interest
    if (rootNodeSchedule == NULL) {
        rootNodeSchedule = AllScheduleStatements;
    }

    else {
        //combine two sorted schedule lists into one sorted list and assign it to rootSchedule
        ListNode* newhead = (ListNode*)malloc(sizeof(ListNode));
        newhead->type = SCHEDULE_NODE;
        newhead->node = (Node*)malloc(sizeof(Node));
        // Set newhead as the head of the merged list
        newhead->node->schedule.next = NULL;
        ListNode* tail = newhead;

        ListNode* current1 = AllScheduleStatements; //AllScheduleStatements
        ListNode* current2 = rootNodeSchedule; //rootNodeSchedule
        ListNode* temp;

    // Traverse both lists
        while (current1 != NULL && current2 != NULL) {
            if (firstDateEarlier(current1, current2) == 1)  {
                // Move a node from list1 to the merged list
                temp = current1->node->schedule.next; 
                current1->node->schedule.next = NULL; // Disconnect the node from the original list
                tail->node->schedule.next = current1;
                tail = current1;
                current1 = temp;
            } else {
                // Move a node from list2 to the merged list
                temp = current2->node->schedule.next;
                current2->node->schedule.next = NULL; // Disconnect the node from the original list
                tail->node->schedule.next = current2;
                tail = current2;
                current2 = temp;
            }
        }

        // If there are remaining nodes in list1, add them to the merged list
        while (current1 != NULL) {
            temp = current1->node->schedule.next;
            current1->node->schedule.next = NULL;
            tail->node->schedule.next = current1;
            tail = current1;
            current1 = temp;
        }

        // If there are remaining nodes in list2, add them to the merged list
        while (current2 != NULL) {
            temp = current2->node->schedule.next;
            current2->node->schedule.next = NULL;
            tail->node->schedule.next = current2;
            tail = current2;
            current2 = temp;
        }

        rootNodeSchedule = newhead->node->schedule.next;
    }
    //reset the lists of the mail block
    AllSendStatements = NULL;
    AllScheduleStatements = NULL;
    //reset local ident list by freeing memory
    ListNode* tmp1 = identList;
    while (tmp1 != NULL) {
        ListNode* tmp2 = tmp1;
        tmp1 = tmp1->node->ident.next;
        free(tmp2);
    }
    identList = NULL;
}
;

statementList : 
                |  statementList setStatement{
                }
                |  statementList sendStatement{
                    if (AllSendStatements == NULL) {
                        AllSendStatements = $2;
                    }
                    else {
                        ListNode* ptr = AllSendStatements;
                        while(ptr->node->send.next != NULL) {
                            ptr = ptr->node->send.next;
                        }
                        ptr->node->send.next = $2;
                    }
                }
                |  statementList scheduleStatement{
                    if (AllScheduleStatements == NULL) {
                        AllScheduleStatements = $2;
                    }
                    else {
                        ListNode* newSchList = $2;

                        if(firstDateEarlier(newSchList, AllScheduleStatements) == 1) {
                            ListNode* tmp = newSchList;
                            while (tmp->node->schedule.next != NULL) {
                                tmp = tmp->node->schedule.next;
                            }
                            tmp->node->schedule.next = AllScheduleStatements;
                            AllScheduleStatements = newSchList;
                        }
                        else {
                            ListNode* tmp = AllScheduleStatements;
                            // int flag = 0;
                            while (tmp->node->schedule.next != NULL){
                                if (firstDateEarlier(newSchList, tmp->node->schedule.next) == 1) {
                                    // flag = 1;
                                    break;
                                }
                                tmp = tmp->node->schedule.next;
                            }
                            ListNode* ptr = newSchList;
                            while (ptr->node->schedule.next != NULL) {
                                ptr = ptr->node->schedule.next;
                            }
                            ptr->node->schedule.next = tmp->node->schedule.next;
                            tmp->node->schedule.next = newSchList;
                        }

                    }
                }
;

sendStatements : sendStatement {$$ = $1;}
                | sendStatement sendStatements {
                    ListNode* ptr = $1;
                    while(ptr->node->send.next != NULL) {
                        ptr = ptr->node->send.next;
                    }
                    ptr->node->send.next = $2;
                    $$ = $1;
                }
;

sendStatement : tSEND tLBR tSTRING tRBR tTO tLBR recipientList tRBR {$$ = createSendNodeList($3, $7, -1);}
              | tSEND tLBR tIDENT tRBR tTO tLBR recipientList tRBR  {$$ = createSendNodeList($3.identifier, $7, $3.lineNum);}


;

recipientList : recipient { $$ = $1; }
            | recipient tCOMMA recipientList { $$ = createRecipientList($1, $3); }
;

recipient : tLPR tADDRESS tRPR { $$ = createRecipientNode(NULL, $2, -1); } 
            | tLPR tSTRING tCOMMA tADDRESS tRPR { $$ = createRecipientNode($2, $4, -1); }
            | tLPR tIDENT tCOMMA tADDRESS tRPR { $$ = createRecipientNode($2.identifier, $4, $2.lineNum); }
;

scheduleStatement : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON sendStatements tENDSCHEDULE{
    $$ = createScheduleList($4.identifier, $6.identifier, $9, $4.lineNum, $6.lineNum);
}
;

setStatement : tSET tIDENT tLPR tSTRING tRPR{
    //check local variable
    if (isLocal == 0) {
        //global variable
        createIdentNodeForGlobalList($2.identifier, $4); //global variable
    }
    else {
        createIdentNodeForLocalList($2.identifier, $4); //local variable
    }
}
;
%%

char* checkIdent(ListNode* myList, char* identifier)
{
    ListNode* temp = myList;
    while(temp != NULL)
    {
        if(strcmp(temp -> node -> ident.identifier, identifier) == 0)
        {
            return temp -> node -> ident.value;
        }
        temp = temp -> node -> ident.next;
    }
    //identifier is not in the list
    return NULL;
}
void createIdentNodeForLocalList(char* identifier, char* value)
{
    ListNode* ln = (ListNode*)malloc(sizeof(ListNode));
    ln->type = IDENT_NODE;
    ln -> node = (Node*)malloc(sizeof(Node));

    ln -> node -> ident.identifier = strdup(identifier);
    ln -> node -> ident.value = strdup(value);
    ln -> node -> ident.next = NULL;

    if(identList == NULL) //note the head
    {
        identList = ln;
    }
    else
    {
        //handle the case if the identifier is already in the list (update the value)
        ListNode* temp = identList;
        while(temp -> node -> ident.next != NULL)
        {
            if(strcmp(temp -> node -> ident.identifier, identifier) == 0)
            {
                temp -> node -> ident.value = strdup(value);
                return;
            }
            temp = temp -> node -> ident.next;
        }
        if(strcmp(temp -> node -> ident.identifier, identifier) == 0)
            {
                temp -> node -> ident.value = strdup(value);
                return;
            }
        else {
            temp -> node ->ident.next = ln;
        }
    }
}

void createIdentNodeForGlobalList(char* identifier, char* value)
{
    ListNode* ln = (ListNode*)malloc(sizeof(ListNode));
    ln->type = IDENT_NODE;
    ln -> node = (Node*)malloc(sizeof(Node));

    ln -> node -> ident.identifier = strdup(identifier);
    ln -> node -> ident.value = strdup(value);
    ln -> node -> ident.next = NULL;

    if(globalIdentList == NULL) //note the head
    {
        globalIdentList = ln;
    }
    else
    {
        //handle the case if the identifier is already in the list (update the value)
        ListNode* temp = globalIdentList;
        while(temp -> node -> ident.next != NULL)
        {
            if(strcmp(temp -> node -> ident.identifier, identifier) == 0)
            {
                temp -> node -> ident.value = strdup(value);
                return;
            }
            temp = temp -> node -> ident.next;
        }
        if(strcmp(temp -> node -> ident.identifier, identifier) == 0)
            {
                temp -> node -> ident.value = strdup(value);
                return;
            }
        else {
            temp -> node ->ident.next = ln;
        }
    }
}
ListNode* createRecipientNode(char* name, char* address, int lineNum)
{
    ListNode* ln = (ListNode*)malloc(sizeof(ListNode));
    ln->type = RECIPIENT_NODE;
    ln -> node = (Node*)malloc(sizeof(Node));

    if (name == NULL) { //just an address for the recipient
            ln -> node -> recipient.name_exists = 0;
            ln -> node -> recipient.name = NULL;
            ln -> node -> recipient.address = strdup(address);
            ln -> node -> recipient.next = NULL;
            return ln;
    }
    else if (name != NULL && lineNum == -1) {
        //name exists and it is a string
        char tmp[400];
        //process the string to remove the quotes
        substring(tmp, name, 1, strlen(name)-1);
        ln -> node -> recipient.name = strdup(tmp);
    }

    else if (name != NULL && lineNum != -1) {
        //name exists and it is an identifier
        //check if the identifier is in the list
        char* x = NULL; //value of the identifier set to null at first
        if (checkIdent(identList, name) == NULL) {
            if (checkIdent(globalIdentList, name) == NULL) {
                x = NULL;
            }
            else {
               x = checkIdent(globalIdentList, name); 
            }
        }
        else {
            x = checkIdent(identList, name);
        }

        if(x == NULL)
        {
            //identifier is not in the list
            found_error = 1;
            char* e = "ERROR at line %d: %s is undefined\n";
            char * dest = (char *)malloc(strlen(e) + strlen(name) + lineNum + 10);
            sprintf(dest, e, lineNum, name);
            if (errorList == NULL) {
                errorList = (ListNode*)malloc(sizeof(ListNode));
                errorList->type = ERROR_NODE;
                errorList->node = (Node*)malloc(sizeof(Node));
                errorList->node->error.errorMessage = dest;
                errorList->node->error.next = NULL;
            }
            else {
                
                ListNode* newError = (ListNode*)malloc(sizeof(ListNode));
                newError->type = ERROR_NODE;
                newError->node = (Node*)malloc(sizeof(Node));
                newError->node->error.errorMessage = dest;
                ListNode* tmp = errorList;
                while (tmp->node->error.next != NULL) {
                    tmp = tmp->node->error.next;
                }
                tmp->node->error.next = newError;
            }
        }
        else if (x != NULL) {
            //identifier is in the list
            char tmp[500];
            substring(tmp, x, 1, strlen(x)-1);
            ln -> node -> recipient.name = strdup(tmp);
        }
    }
    ln -> node -> recipient.name_exists = 1;
    ln -> node -> recipient.address = strdup(address);
    ln -> node -> recipient.next = NULL;
    return ln;

}

ListNode* createRecipientList(ListNode* recipient, ListNode* recipientList)
{
    recipient -> node -> recipient.next = recipientList;
    ListNode* ptr1 = recipient;
    while(ptr1 -> node -> recipient.next != NULL)
    {
        ListNode* ptr2 = ptr1 -> node -> recipient.next; //ptr2 points to the next node in the list
        if (strcmp(recipient->node->recipient.address, ptr2 -> node -> recipient.address) == 0)
        {
            ptr1 -> node -> recipient.next = ptr2 -> node -> recipient.next; //keep first occurrence of the same address
            return recipient;
        }

        ptr1 = ptr1 -> node -> recipient.next;
    }
    return recipient;
}

ListNode* createSendNodeList(char* msg, ListNode* recipientList, int lineNum) {
    char* checkMessage = NULL;
    if (lineNum == -1) {
        //msg is a string
        checkMessage = strdup(msg);
        
    }
    else {
        if (checkIdent(identList, msg) == NULL) {
            if (checkIdent(globalIdentList, msg) == NULL) {
                checkMessage = NULL;
            }
            else {
               checkMessage = checkIdent(globalIdentList, msg); 
            }
        }
        else {
            checkMessage = checkIdent(identList, msg);
        }
        if (checkMessage == NULL) {
            //identifier is not in the list
            found_error = 1;
            printf("ERROR at line %d: %s is undefined\n", lineNum, msg);
        }
    }
    //now print the subsequent error messages (if any)
            ListNode* ptr = errorList;
            while (ptr != NULL) {
                ListNode* tmp = ptr;
                printf("%s", ptr->node->error.errorMessage);
                ptr = ptr->node->error.next;
                free(tmp);
            }
            errorList = NULL;
    ListNode* ln = createSendNode(checkMessage, recipientList, lineNum);
    ListNode* tmp = ln;
    ListNode* ptr1 = recipientList->node->recipient.next;
    while (ptr1 != NULL) {
        ListNode* ln2 = createSendNode(checkMessage, ptr1, lineNum);
        tmp->node->send.next = ln2;
        tmp = ln2;
        ptr1 = ptr1->node->recipient.next;
    }
    return ln;
}

ListNode* createSendNode(char* msg, ListNode* recipientList, int lineNum) {
    ListNode* ln = (ListNode*)malloc(sizeof(ListNode));
    ln->type = SEND_NODE;
    ln -> node = (Node*)malloc(sizeof(Node));
    ln -> node -> send.message = msg;

    if (recipientList -> node -> recipient.name_exists == 1) {
        ln->node->send.recipient = recipientList -> node -> recipient.name;
    }
    else {
        ln->node->send.recipient = recipientList -> node -> recipient.address;
    }
    ln -> node -> send.next = NULL;
    return ln;
}

ListNode* createScheduleList(char* date, char* time, ListNode* sendStatements, int dateLineNum, int timeLineNum) {
    //first check if date and time are correct
    
    char date1Day[100], date1Month[100], date1Year[100], time1Hour[100], time1Minute[100];

    substring(date1Day, date, 0, 2);
    substring(date1Month, date, 3, 5);
    substring(date1Year, date, 6, 10);
    substring(time1Hour, time, 0, 2);
    substring(time1Minute, time, 3, 5);

    int flag = 0;
    int timeFlag = 0;
    int febFlag = 0;
    //check if date is valid
    if (atoi(date1Day) < 1 || atoi(date1Day) > 31) {
        found_error = 1;
        printf("ERROR at line %d: date object is not correct (%s)\n", dateLineNum, date);
        flag = 1;
    }
    else if (atoi(date1Month) == 2 && flag == 0) {
        //february
        if (atoi(date1Day) > 29) {
            febFlag = 1;
        }
        else if (atoi(date1Day) == 29) {
            if (isLeapYear(atoi(date1Year)) == 0) {
                febFlag = 1;
            }
        }
        if (febFlag == 1) {
            found_error = 1;
            printf("ERROR at line %d: date object is not correct (%s)\n", dateLineNum, date);
            flag = 1;
        }
    }
    if ((atoi(date1Month) < 1 || atoi(date1Month) > 12) && flag == 0) {
        found_error = 1;
        printf("ERROR at line %d: date object is not correct (%s)\n", dateLineNum, date);
        flag = 1;
    }
    
    //check if time is valid
    if ((atoi(time1Hour) < 0 || atoi(time1Hour) > 23)&& timeFlag == 0) {
        found_error = 1;
        printf("ERROR at line %d: time object is not correct (%s)\n", timeLineNum, time);
        timeFlag = 1;
    }
    if ((atoi(time1Minute) < 0 || atoi(time1Minute) > 59)&& timeFlag == 0) {
        found_error = 1;
        printf("ERROR at line %d: time object is not correct (%s)\n", timeLineNum, time);
        timeFlag = 1;
    }

    char* d = strdup(date);
    char* t = strdup(time);

    ListNode* rt = createScheduleNode(d, t, sendStatements); //root node
    ListNode* tmp = rt;
    ListNode* ptr = sendStatements->node->send.next; //first one handled in createScheduleNode
    while (ptr != NULL) {
        ListNode* nw = createScheduleNode(d, t, ptr);
        tmp->node->schedule.next = nw;
        tmp = nw;

        ptr = ptr->node->send.next;
    }
    return rt;
}

ListNode* createScheduleNode(char* date, char* time, ListNode* sendStatements) {
    ListNode* ln = (ListNode*)malloc(sizeof(ListNode));
    ln->type = SCHEDULE_NODE;
    ln -> node = (Node*)malloc(sizeof(Node));

    char* recipient =  sendStatements -> node -> send.recipient;
    char* message = sendStatements -> node -> send.message;

    ln -> node -> schedule.recipient = recipient;
    ln -> node -> schedule.message = message;

    ln -> node -> schedule.date = date;
    ln -> node -> schedule.time = time;

    ln -> node -> schedule.next = NULL;
    return ln;
}

int firstDateEarlier(ListNode* nodeDate1, ListNode* nodeDate2) {
    //returns 1 if date1 is earlier than date2
    //returns 0 if date2 is earlier than date1
    //returns 2 if they are the same dates
    char* date1str = nodeDate1->node->schedule.date;
    char* time1str = nodeDate1->node->schedule.time;

    char* date2str = nodeDate2->node->schedule.date;
    char* time2str = nodeDate2->node->schedule.time;

    char date1Day[100], date1Month[100], date1Year[100], time1Hour[100], time1Minute[100];
    char date2Day[100], date2Month[100], date2Year[100], time2Hour[100], time2Minute[100];

    substring(date1Day, date1str, 0, 2);
    substring(date1Month, date1str, 3, 5);
    substring(date1Year, date1str, 6, 10);
    substring(time1Hour, time1str, 0, 2);
    substring(time1Minute, time1str, 3, 5);

    substring(date2Day, date2str, 0, 2);
    substring(date2Month, date2str, 3, 5);
    substring(date2Year, date2str, 6, 10);
    substring(time2Hour, time2str, 0, 2);
    substring(time2Minute, time2str, 3, 5);

    //determine which date is earlier
    if (strcmp(date1Year, date2Year) < 0) {
        return 1; //date1 is earlier
    }
    else if (strcmp(date1Year, date2Year) > 0) {
        return 0; //date2 is earlier
    }
    else {
        if (strcmp(date1Month, date2Month) < 0) {
            return 1;
        }
        else if (strcmp(date1Month, date2Month) > 0) {
            return 0;
        }
        else {
            if (strcmp(date1Day, date2Day) < 0) {
                return 1;
            }
            else if (strcmp(date1Day, date2Day) > 0) {
                return 0;
            }
            else {
                //same date, check time
                if (strcmp(time1Hour, time2Hour) < 0) {
                    return 1;
                }
                else if (strcmp(time1Hour, time2Hour) > 0) {
                    return 0;
                }
                else {
                    if (strcmp(time1Minute, time2Minute) < 0) {
                        return 1;
                    }
                    else if (strcmp(time1Minute, time2Minute) > 0) {
                        return 0;
                    }
                    else {
                        //same time
                        return 2; 
                    }
                }
            }
        }
    }

}
void substring(char * dest, char * src, int start, int end) {
    int i = 0;
    while (start < end) {
        dest[i] = src[start];
        i++;
        start++;
    }
    dest[i] = '\0';
}

char* getMonthName(char* monthNum) {
    if (strcmp(monthNum, "01") == 0) {
        return "January";
    }
    else if (strcmp(monthNum, "02") == 0) {
        return "February";
    }
    else if (strcmp(monthNum, "03") == 0) {
        return "March";
    }
    else if (strcmp(monthNum, "04") == 0) {
        return "April";
    }
    else if (strcmp(monthNum, "05") == 0) {
        return "May";
    }
    else if (strcmp(monthNum, "06") == 0) {
        return "June";
    }
    else if (strcmp(monthNum, "07") == 0) {
        return "July";
    }
    else if (strcmp(monthNum, "08") == 0) {
        return "August";
    }
    else if (strcmp(monthNum, "09") == 0) {
        return "September";
    }
    else if (strcmp(monthNum, "10") == 0) {
        return "October";
    }
    else if (strcmp(monthNum, "11") == 0) {
        return "November";
    }
    else if (strcmp(monthNum, "12") == 0) {
        return "December";
    }
    else {
        return NULL;
    }
}

void printSendListNotifications() {
    ListNode* ptr = rootNodeSend;
    while (ptr != NULL) {
        printf("E-mail sent from %s to %s: %s\n", ptr->node->send.sender, ptr->node->send.recipient, ptr->node->send.message);
        ptr = ptr->node->send.next;
    }
}

void printScheduleListNotifications() {
    ListNode* ptr = rootNodeSchedule;
    while (ptr != NULL) {
        char* date = ptr->node->schedule.date;
        char* time = ptr->node->schedule.time;

        char* sender = ptr->node->schedule.sender;
        char* recipient = ptr->node->schedule.recipient;
        char* message = ptr->node->schedule.message;

        char dateDay[100], dateMonth[100], dateYear[100];
        // char timeHour[100], timeMinute[100];
        substring(dateDay, date, 0, 2);
        substring(dateMonth, date, 3, 5);
        substring(dateYear, date, 6, 10);
        // substring(timeHour, time, 0, 2);
        // substring(timeMinute, time, 3, 5);
        //check for single digit day
        if (dateDay[0] == '0') {
            substring(dateDay, date, 1, 2);
        }
        printf("E-mail scheduled to be sent from %s on %s %s, %s, %s to %s: %s\n", sender, getMonthName(dateMonth), dateDay, dateYear, time, recipient, message);
        ptr = ptr->node->schedule.next;
    }
}

int isLeapYear(int year) {
    if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 1; // Leap year
    } else {
        return 0; // Not a leap year
    }
}

int main () 
{
   if (yyparse())
   {
      printf("ERROR\n");
      return 1;
    } 
    else 
    {
        if (found_error == 1) {
            //found an error in semantics
            //errors will be printed
        }
        else {
            printSendListNotifications();
            printScheduleListNotifications();
        }
        // printf("OK\n");
        return 0;
    } 
}