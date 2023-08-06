Prog ::= Expr
Expr ::= num Expr'
Expr' ::= Op Expr Expr' | ε

Prog ::= Expr
Expr ::= num Expr' | num
Expr' ::= Op Expr Expr'

Call = popen CallRest
CallRest = pclose | ArgList pclose
ArgList = name | LeftArglist name
LeftArglist = name comma | name comma LeftArglist