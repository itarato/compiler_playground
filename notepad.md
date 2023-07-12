Prog ::= Expr
Expr ::= num Expr'
Expr' ::= Op Expr Expr' | ε

Prog ::= Expr
Expr ::= num Expr' | num
Expr' ::= Op Expr Expr'
