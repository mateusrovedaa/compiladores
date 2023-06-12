grammar LexerRules;

/*---------------- LEXER RULES ----------------*/

PLUS  : '+' ;
MINUS : '-' ;
TIMES : '*' ;
OVER  : '/' ;
REMAINDER: '%' ;
OP_PAR: '(' ;
CL_PAR: ')' ;
OP_CUR: '{' ;
CL_CUR: '}' ;
ATTRIB: '=' ;
COMMA: ',' ;
DOT: '.' ;

EQ: '==' ;
NE: '!=' ;
GT: '>' ;
GE: '>=' ;
LT: '<' ;
LE: '<=' ;

CONSOLE: 'console' ;
IF: 'if' ;
ELSE: 'else' ;
WHILE: 'while' ;
READINT: 'readInt' ;
READSTRING: 'readString' ;
BREAK: 'break' ;
CONTINUE: 'continue' ;
FUNCTION: 'function' ;
INT: 'int' ;
RETURN: 'return' ;
BEEP: 'beep';

NUMBER: '0'..'9'+ ;
VARIABLE: 'a'..'z'+ ;
STRING: '"' ~["]* '"' ;

COMMENT: '//' ~('\n')* { skip(); };
SPACE: (' '|'\t'|'\r'|'\n')+ { skip(); } ;