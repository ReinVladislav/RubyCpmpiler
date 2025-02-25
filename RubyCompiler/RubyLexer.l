%option noyywrap
%option never-interactive
%option yylineno
%option header-file="lex.yy.h"

%{
	#include <stdio.h>    
    #include "parser.tab.h" 
    #include "tree_nodes.h"   

    void removeCharacterFromString(const char * str, char * dest, char deleted_char);
    int binstrToDec(const char * str);
%}

DIGIT [0-9]
HEX_DIGIT [0-9A-Fa-f]
OCT_DIGIT [0-7]
BIN_DIGIT [01]

OCT_NUMBER {DIGIT}*(_{DIGIT}+)*
HEX_NUMBER {HEX_DIGIT}*(_{HEX_DIGIT}+)*
BIN_NUMBER {BIN_DIGIT}*(_{BIN_DIGIT}+)*
DIGIT_NUMBER {DIGIT}*(_{DIGIT}+)*

LETTER_NUMBER_UNDERSCOPE [a-zA-Z0-9_]
EXPONENT [eE][+-]?[1-9]{DIGIT_NUMBER}

%x ML_COMMENT
%x STRING

%% 

%{   
    int num;
    float real_num;
    char temp1[100];
    char temp2[100];
    char comment[1000];
    char string[1000];
    int concatenation = 0;
%}

and             { return AND; }
begin		    { return BEGIN_KEYWORD; }
class           { return CLASS; }
def             { return DEF; }
"defined?"	    { return DEFINED; }
do              { return DO; }
if              { return IF; }
else            { return ELSE; }
elsif           { return ELSIF; }
end             { return END; }
false           { return FALSE; }
for             { return FOR; }
in              { return IN; }
not             { return NOT; }
or              { return OR; }
return          { return RETURN; }
self            { return SELF; }
super           { return SUPER; }
then            { return THEN; }
true            { return TRUE; }
until           { return UNTIL; }
while           { return WHILE; }

"+"         { return ARITHMETIC_PLUS_OP; }
"-"         { return ARITHMETIC_MINUS_OP; }
"*"         { return ARITHMETIC_MUL_OP; }
"/"         { return ARITHMETIC_DIV_OP; }
"%"         { return ARITHMETIC_MOD_OP; }
"**"        { return ARITHMETIC_POW_OP; }

"=="        { return EQL_OP; }
"!="        { return NOT_EQL_OP; }
">"         { return GREATER_OP; }
"<"         { return LESS_OP; }
">="        { return GREATER_OR_EQL_OP; }
"<="        { return LESS_OR_EQL_OP; }
"<=>"       { return COMB_COMPRASION_OP; }
"==="       { return CASE_EQL_OP; }

"="         { return ASSIGN_OP; }

"&&"        { return LOGICAL_AND_OP; }
"||"        { return LOGICAL_OR_OP; }
"!"         { return LOGICAL_NOT_OP; }

".."        { return INCLUSIVE_RANGE_OP; }
"..."       { return EXCLUSIVE_RANGE_OP; }

"."         { return DOT_SYMBOL; }
","         { return COMMA_SYMBOL; }
";"         { return SEMICOLON_SYMBOL; }
\n          { return NEW_LINE_SYMBOL;  }
"("         { return OPEN_ROUND_BRACKET; }
")"         { return CLOSE_ROUND_BRACKET; }
"{"         { return OPEN_CURLY_BRACKET; }
"}"         {
                    return CLOSE_CURLY_BRACKET;
            }
"["         { return OPEN_SQUARE_BRACKET; }
"]"         { return CLOSE_SQUARE_BRACKET; }
"@"         { return COMMERCIAL_AT; }

\"          { 
                string[0] = 0; 
                BEGIN(STRING);    
            }
          

<STRING>[^\\\"\n#{}]+     { strcat(string, yytext); }
<STRING>[#{}]             { strcat(string, yytext); }
<STRING>\\n               { strcat(string, "\n"); }
<STRING>\\a               { strcat(string, "\a"); }
<STRING>\\b               { strcat(string, "\b"); }
<STRING>\\t               { strcat(string, "\t"); }
<STRING>\\v               { strcat(string, "\v"); }
<STRING>\\f               { strcat(string, "\f"); }
<STRING>\\r               { strcat(string, "\r"); }
<STRING>\\e               { strcat(string, "\e"); }
<STRING>\\s               { strcat(string, " "); }
<STRING>\\\\              { strcat(string, "\\"); }
<STRING>\\\"              { strcat(string, "\""); }
<STRING>\\{OCT_DIGIT}{1,3} { 
                                sscanf(yytext + 1, "%o", &num);
                                temp1[0] = (char) num;
                                temp1[1] = 0;
                                strcat(string, temp1);
                            }

<STRING>\\x{HEX_DIGIT}{1,2} { 
                                sscanf(yytext + 2, "%x", &num);
                                temp1[0] = (char) num;
                                temp1[1] = 0;
                                strcat(string, temp1);
                            }
<STRING>\\x[^0-9A-Fa-f\n"]* { printf("ERROR: invalid hex escape \n"); } 
<STRING><<EOF>>             { printf("ERROR: expected \" \n");}
<STRING>\" { 
                yylval.string_un=(char *)malloc(strlen(string)+1);
                strcpy(yylval.string_un, string);
                BEGIN(INITIAL);
                return STR;
            }

#.*                         { printf("Single-line comment: %s\n", yytext + 1); }

^=begin                 {                                     
                            comment[0] = 0; 
                            BEGIN(ML_COMMENT);
                        }

<ML_COMMENT>^=end       {
                            strcat(comment, yytext + 5);
                            printf("Multi-line comment: %s\n", comment);
                            BEGIN(INITIAL);
                        }

<ML_COMMENT>.*          { 
                            strcat(comment, yytext); 
                        }

<ML_COMMENT><<EOF>>     { 
                            printf("expected =end"); BEGIN(INITIAL); 
                        }

{DIGIT_NUMBER}       { 
                                removeCharacterFromString(yytext,temp1,'_');
                                yylval.int_un = atoi(temp1);
                                return INTEGER_NUMBER;
                            }

(_*{DIGIT}+)*_*        { printf("ERROR: invalid decimal number: %s\n", yytext); }

0[dD][1-9]{DIGIT_NUMBER}    {
                                removeCharacterFromString(yytext+2,temp1,'_');
                                yylval.int_un = atoi(temp1);
                                return INTEGER_NUMBER;              
                            }

0_*[dD]_*[1-9](_*{DIGIT}+)*_* { printf("ERROR: invalid decimal number with dD: %s\n", yytext); }

0[oO]{OCT_NUMBER}          {
                                removeCharacterFromString(yytext,temp1,'_');
                                removeCharacterFromString(temp1,temp2,'o');
                                removeCharacterFromString(temp2,temp1,'O');
                                yylval.int_un = strtol(temp1, NULL, 8);
                                return INTEGER_NUMBER;
                            }

0_*[oO]_*{OCT_DIGIT}(_*{OCT_DIGIT}+)*_* { printf("ERROR: invalid octal number: %s\n", yytext); }

0[xX]{HEX_NUMBER}           {
                                removeCharacterFromString(yytext,temp1,'_');
                                removeCharacterFromString(temp1,temp2,'x');
                                removeCharacterFromString(temp2,temp1,'X');
                                yylval.int_un = strtol(temp1, NULL, 16);
                                return INTEGER_NUMBER;
                            }

0_*[xX]_*{HEX_DIGIT}(_*{HEX_DIGIT}+)*_* { printf("ERROR: invalid hexadecimal number: %s\n", yytext); }

0[bB]{BIN_NUMBER}           {
                                removeCharacterFromString(yytext,temp1,'_');
                                removeCharacterFromString(temp1,temp2,'b');
                                removeCharacterFromString(temp2,temp1,'B');
                                yylval.int_un = strtol(temp1, NULL, 2);
                                return INTEGER_NUMBER;
                            }

0_*[bB]_*{BIN_DIGIT}(_*{BIN_DIGIT}+)*_* { printf("ERROR: invalid binary number: %s\n", yytext); }


(0|[1-9](_?{DIGIT})*)(\.{DIGIT}+(_{DIGIT}+)*)?({EXPONENT})? {
                                                                removeCharacterFromString(yytext,temp1,'_');                                                                  
                                                                real_num = (float) atof(temp1);
                                                                yylval.float_un = (float) real_num;
                                                                return FLOAT_NUMBER;
                                                            }
([1-9]*_*(\.|\.{4,})_*{DIGIT}+)+(_*{DIGIT}*)*           { printf("ERROR: invalid float number: %s\n", yytext); }
([1-9]+((_|\.)*{DIGIT}*)*[Ee]+((_|\.)*{DIGIT}*)*)+      { printf("ERROR: invalid float number with eE: %s\n", yytext); }

{LETTER_NUMBER_UNDERSCOPE}*\??           {
                                                yylval.string_un=(char *)malloc(strlen(yytext)+1);
                                                strcpy(yylval.string_un, yytext); 
                                                return VAR_OR_METHOD_NAME;
                                            }

\@[a-z_]{LETTER_NUMBER_UNDERSCOPE}*         {
                                                yylval.string_un=(char *)malloc(strlen(yytext)+1);
                                                strcpy(yylval.string_un, yytext); 
                                                return INSTANCE_VAR_NAME;
                                            }

\@\@[a-z_]{LETTER_NUMBER_UNDERSCOPE}*       {
                                                yylval.string_un=(char *)malloc(strlen(yytext)+1);
                                                strcpy(yylval.string_un, yytext); 
                                                return CLASS_VAR_NAME;
                                            }

%% 

void removeCharacterFromString(const char * str, char * dest, char deleted_char) {
	int j = 0;
	
    for(int i = 0; str[i] != 0; i++) {
        if(str[i] != deleted_char) {
            dest[j++] = str[i];
        }
    }

    dest[j] = 0;
}

int binstrToDec(const char * str) {
    const unsigned char *p = reinterpret_cast<const unsigned char *> (str);
    unsigned int   r = 0;

    while (p && *p ) {
        r <<= 1;
        r += (unsigned int)((*p++) & 0x01);
    }

    return (int) r;
}