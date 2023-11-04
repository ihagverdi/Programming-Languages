%{
#include <stdio.h>
void yyerror (const char *s)
{
    return;
}
%}
%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tSET tTO tFROM tAT tCOMMA tCOLON tLPR tRPR  tLBR tRBR tIDENT tSTRING tDATE tTIME tADDRESS
%%

mailProgram: 
           | components
;

components: component
          | component components
;

component: mail_block
         | set_stmt
;

mail_block: tMAIL tFROM tADDRESS tCOLON mail_body tENDMAIL
;

mail_body: 
         | statement_list
;

statement_list: statement
              | statement statement_list
;

statement: set_stmt
         | send_stmt
         | schedule_stmt
;

set_stmt: tSET tIDENT tLPR tSTRING tRPR
;

send_stmt: tSEND tLBR tIDENT tRBR tTO recipient_block
         | tSEND tLBR tSTRING tRBR tTO recipient_block
;

schedule_stmt: tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON schedule_body tENDSCHEDULE
;

schedule_body: send_stmt
             | send_stmt schedule_body
;

recipient_block: tLBR recipient_list tRBR
;

recipient_list: recipient_object
              | recipient_object tCOMMA recipient_list
;

recipient_object: tLPR tADDRESS tRPR
                | tLPR tIDENT tCOMMA tADDRESS tRPR
                | tLPR tSTRING tCOMMA tADDRESS tRPR
;

%%
int main () {
    if (yyparse()) {
        // parse error
        printf("ERROR\n");
        return 1;
    }
    else {
        // successful parsing
        printf("OK\n");
        return 0;
    }
}