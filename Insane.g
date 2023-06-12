grammar Insane;
import LexerRules;

/*---------------- PARSER INTERNALS ----------------*/

@parser::header
{
    import java.util.ArrayList;
    import java.awt.Toolkit;
}

@parser::members
{
    private static ArrayList<String> symbol_table;
    private static ArrayList<String> symbol_not_utilized; 
    
    private static ArrayList<Character> type_table;
    private static ArrayList<String> function_table;

    private static ArrayList<Integer> f_num_param;
    private static ArrayList<Boolean> f_returns;
    
    private static int stack_cur, max_stack;
    private String comp_op;
    private static int comp_label;
    private static int position_label;

    private static ArrayList<String> errors;
    private static ArrayList<String> warnings;

    private static boolean f_return;
    private static boolean return_statement_declared;

    public static void main(String[] args) throws Exception
    {
        ANTLRInputStream input = new ANTLRInputStream(System.in);
        InsaneLexer lexer = new InsaneLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        InsaneParser parser = new InsaneParser(tokens);

        symbol_table = new ArrayList<String>();
        type_table = new ArrayList<Character>();
        symbol_not_utilized = new ArrayList<String>();
        comp_label = 0;
        position_label = -1;
        function_table = new ArrayList<String>();
        f_num_param = new ArrayList<Integer>();
        f_returns = new ArrayList<Boolean>();
        errors = new ArrayList<String>();
        warnings = new ArrayList<String>();
        f_return = false;
        return_statement_declared = false;
        parser.program();

        if(symbol_not_utilized.size() > 0)
        {
            warnings.add("Warning: " + symbol_not_utilized + " defined but not used");
        }

        if(!warnings.isEmpty())
        {
            for(int i = 0; i < warnings.size(); i++)
            {
                System.err.println(warnings.get(i));
            }
        }

        System.out.println("; symbols: " + symbol_table);
        System.out.println("; types: " + type_table);
        System.out.println("; functions: " + function_table);
        System.out.println("; f_num_param: " + f_num_param);
        System.out.println("; f_returns: " + f_returns);

        if(!errors.isEmpty())
        {
            for(int i = 0; i < errors.size(); i++)
            {
                System.err.println(errors.get(i));
            }
            System.exit(1);
        }
    }

    private static void emit(String bytecode, int delta) {
        System.out.println("    " + bytecode);
        stack_cur += delta;
        if (max_stack < stack_cur) { max_stack = stack_cur; }
    }

    private static void sound() {
        Toolkit.getDefaultToolkit().beep(); // Plays the bell sound
    }
}

/*---------------- PARSER RULES ----------------*/

program
    :
        {   System.out.println(".source Test.j");
            System.out.println(".class  public Test");
            System.out.println(".super  java/lang/Object");
            System.out.println();
            System.out.println(".method public <init>()V");
            System.out.println("    aload_0");
            System.out.println("    invokenonvirtual java/lang/Object/<init>()V");
            System.out.println("    return");
            System.out.println(".end method");
            System.out.println();
        }
        ( function )* main EOF
    ;

main
    :   
        {   
            System.out.println(".method public static main([Ljava/lang/String;)V");
            symbol_table.add("args");
            type_table.add('a');
        }    
        ( statement )+
        {   System.out.println("    return");
            System.out.println(".limit stack " + max_stack);
            System.out.println(".limit locals " + symbol_table.size());
            System.out.println(".end method");
        } 

    ;

function
    :   
        {   String r_type = "V"; int qtd_param = 0;   }
            FUNCTION var = VARIABLE OP_PAR ( parameters  { qtd_param = $parameters.qtd; })? CL_PAR ( INT { r_type = "I"; f_return = true; } )? OP_CUR
        {   if(function_table.contains($var.text))
        	{
                errors.add("Error: function '" + $var.text + "' is already declared. Line: " + $var.line);
            } 
            else 
            {
                function_table.add($var.text);
                f_num_param.add(qtd_param);
                f_returns.add(f_return);
                String s_param = "";
                for (int i = 0; i < qtd_param; i++)
                {
                    s_param = s_param + "I";
                }
                System.out.println(".method public static " + $var.text  + "(" + s_param + ")" + r_type);   
            }            
        }
        ( statement )+
        {   
            if(f_return)
            {
                if(return_statement_declared == false)
                {
                    errors.add("Error: missing return statement in returning function. Line: " + $var.line);
                }
            }

            System.out.println("    return");
            System.out.println(".limit stack " + max_stack);
            System.out.println(".limit locals " + symbol_table.size());
            System.out.println(".end method");

            if(symbol_not_utilized.size() > 0)
            {
                    warnings.add("Warning: " + symbol_not_utilized + " defined but not used");
            }

            System.out.println("; symbols: " + symbol_table);
            System.out.println("; types: " + type_table);
            System.out.println();

            symbol_table = new ArrayList<String>();
            type_table = new ArrayList<Character>();
            symbol_not_utilized = new ArrayList<String>();
            max_stack = 0;
            stack_cur = 0;
            f_return = false;
            return_statement_declared = false;
        } 
        CL_CUR
    ;

parameters returns [int qtd]
    :   var = VARIABLE {
            int qtd = 0;
            if(!symbol_table.contains($var.text)) 
            {
                qtd++;
                symbol_table.add($var.text);
                type_table.add('i');
            }}
        ( COMMA var2 = VARIABLE
        {
            if (symbol_table.contains($var2.text)) 
            {
                errors.add("Error: parameter names must be unique. Line: " + $var2.line);
            } 
            else 
            {
                symbol_table.add($var2.text);
                type_table.add('i');
            }
            qtd++;
        }
        )* { $qtd = qtd; }
    ;

statement
    :   beep | st_console | st_attrib | st_if | st_while | st_break | st_continue | st_call | st_return
    ;

beep
    :   BEEP
            {   sound(); }
    ;

st_console
    :   CONSOLE OP_PAR
        {   emit("getstatic java/lang/System/out Ljava/io/PrintStream;", 1); }
        exp1 = expression
        {   
             if ($exp1.type == 'i') { emit("invokevirtual java/io/PrintStream/print(I)V", -2); }
             if ($exp1.type == 'a') { emit("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V", -2); }
        }
        (
            {   emit("getstatic java/lang/System/out Ljava/io/PrintStream;", 1); }
            COMMA exp2 = expression
            {   
                if ($exp2.type == 'i') { emit("invokevirtual java/io/PrintStream/print(I)V", -2); }
                if ($exp2.type == 'a') { emit("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V", -2); }
            }
        )*
        {   emit("getstatic java/lang/System/out Ljava/io/PrintStream;", 1); }
        {   emit("invokevirtual java/io/PrintStream/println()V\n", -1); }
        CL_PAR
    ;

st_attrib
    :   VARIABLE ATTRIB exp = expression
        {
            if(symbol_table.indexOf($VARIABLE.text) == -1)
            {
                symbol_table.add($VARIABLE.text);
                symbol_not_utilized.add($VARIABLE.text);
                if($exp.type == 'i') 
                {
                    type_table.add('i');
                    emit("istore " + symbol_table.indexOf($VARIABLE.text),-1); 
                }
                if($exp.type == 'a') 
                {
                    type_table.add('a');
                    emit("astore " + symbol_table.indexOf($VARIABLE.text),-1); 
                }
            } 
            else
            {
                if(!symbol_not_utilized.contains($VARIABLE.text))
                {
                    symbol_not_utilized.add($VARIABLE.text);
                }
                if($exp.type == 'i') 
                {
                    if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'i')
                    {
                        emit("istore " + symbol_table.indexOf($VARIABLE.text),-1);
                    }  
                    else if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'a')
                    {
                        errors.add("Error: '" + $VARIABLE.text + "' is String. Line: " + $VARIABLE.line);
                    } 
                    else if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'v')
                    {
                        errors.add("Error: '" + $VARIABLE.text + "' is Array. Line: " + $VARIABLE.line);
                    }
                }
                if($exp.type == 'a') 
                {
                    if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'a')
                    {
                    	emit("astore " + symbol_table.indexOf($VARIABLE.text),-1);
                    }  
                    else if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'i')
                    {
                        errors.add("Error: '" + $VARIABLE.text + "' is integer. Line: " + $VARIABLE.line);
                    } 
                    else if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'v')
                    {
                        errors.add("Error: '" + $VARIABLE.text + "' is Array. Line: " + $VARIABLE.line);
                    }
                 }
                if($exp.type == 'v') 
                {
                    if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'a')
                    {
                        errors.add("Error: '" + $VARIABLE.text + "' is String. Line: " + $VARIABLE.line);
                    } 
                    else if(type_table.get(symbol_table.indexOf($VARIABLE.text)) == 'i')
                    {
                        errors.add("Error: '" + $VARIABLE.text + "' is integer. Line: " + $VARIABLE.line);
                    }
                }
            }
        }
    ;

st_if
    : IF OP_PAR comparision CL_PAR
      { int label = comp_label; comp_label++; boolean have_else = false; emit(comp_op + " NOT_IF_" + label, -2);}
      OP_CUR ( statement )* CL_CUR
      ( {emit("goto END_ELSE_" + label, 0); emit("NOT_IF_" + label + ":", 0); have_else = true;} ELSE OP_CUR ( statement )* CL_CUR )*
      {     if(have_else)
      		{
                emit("END_ELSE_" + label + ":", 0);
            } 
            else 
            {
                emit("NOT_IF_" + label + ":", 0);
            }
      }
    ;

st_while
    : WHILE { int label = comp_label; comp_label++; emit("BEGIN_WHILE_" + label + ":", 0);}
      OP_PAR comparision CL_PAR
      {emit(comp_op + " END_WHILE_" + label, -2); position_label = label;}
      OP_CUR ( statement )* CL_CUR
      {emit("goto BEGIN_WHILE_" + label, 0);}
      {emit("END_WHILE_" + label + ":", 0); position_label = -1;}
    ;

st_break
    : BREAK
        {   if(position_label != -1)
        	{
                emit("goto END_WHILE_" + position_label, 0);
            }
            else 
            {
                errors.add("Error: Cannot use break outside a loop! Line: " + $BREAK.line);
            } 
        }
    ;

st_continue
    : CONTINUE
        {   if(position_label != -1)
        	{
                emit("goto BEGIN_WHILE_" + position_label, 0);
            } 
            else 
            {
                errors.add("Error: Cannot use continue outside a loop! Line: " + $CONTINUE.line);
            } 
        } 
    ;

st_call
    : {int qtd_args = 0; } var = VARIABLE OP_PAR ( arguments { qtd_args = $arguments.qtd; })? CL_PAR
        {   
        	if(!function_table.contains($var.text))
        	{
                errors.add("Error: function '" + $var.text + "' is not declared. Line: " + $var.line);
            } 
            else 
            {
                if(f_num_param.get(function_table.indexOf($var.text)) != qtd_args)
                {
                    errors.add("Error: wrong number of arguments. Line: " + $var.line);
                }
                if(f_returns.get(function_table.indexOf($var.text)))
                {
                    errors.add("Error: return value cannot be ignored. Line: " + $var.line);
                }
            }
            
            String s_arg = "";
            for (int i = 0; i < qtd_args; i++)
            {
                s_arg = s_arg + "I";
            }   
            emit("invokestatic Test/" + $var.text + "("+ s_arg + ")V", 0);  
        }
    ;

arguments returns [int qtd]
    : e1 = expression
        {
            int qtd = 1;
            if($e1.type != 'i') 
            {
                errors.add("Error: all arguments must be integer.");
            }
        }
     ( COMMA e2 = expression
        {   if($e2.type != 'i') 
        	{
                errors.add("Error: all arguments must be integer.");
            }
            qtd++;
        }
     )* { $qtd = qtd; }
    ;

st_return
    : RETURN e = expression
        {
            if(f_return == false) 
            {
                errors.add("Error: a void function does not return a value. Line: " + $RETURN.line);
            }
            if($e.type != 'i') 
            {
                return_statement_declared = true;
                errors.add("Error: return value must be of integer type. Line: " + $RETURN.line);
            } else 
            {
                return_statement_declared = true;
                emit("ireturn", - 1);
            }
        }

    ;

comparision
    : e1 = expression op = ( EQ | NE | GT | GE | LT | LE ) e2 = expression
      {
        if($e1.type == $e2.type  && $e1.type == 'i' && $e2.type == 'i')
        {
            if($op.type == EQ){ comp_op = "if_icmpne";} 
            else if($op.type == NE){ comp_op = "if_icmpeq";}
            else if($op.type == GT){ comp_op = "if_icmple";}
            else if($op.type == GE){ comp_op = "if_icmplt";}
            else if($op.type == LT){ comp_op = "if_icmpge";}
            else if($op.type == LE){ comp_op = "if_icmpgt";}
        } else 
        {
            errors.add("Error: cannot mix types. Line: " + $op.line);
        }
      }
    ;

expression returns [char type]
    :   t1 = term ( op = ( PLUS | MINUS ) t2 = term 
        {   
        	if($t1.type == $t2.type && $t1.type == 'i' && $t2.type == 'i')
        	{
                if($op.type == PLUS) {emit("iadd",-1);}  else { emit("isub",-1);}
            } 
            else 
            {
                errors.add("Error: cannot mix types. Line: " + $op.line);
            }
        }
        )*
        {   $type = $t1.type;   }
    ;

term returns [char type]
    :   f1 = factor ( op = ( TIMES | OVER | REMAINDER) f2 = factor
        {   if($f1.type == $f2.type && $f1.type == 'i' && $f2.type == 'i'){
                if($op.type == TIMES) {emit("imul",-1);} else if ($op.type == OVER) {emit("idiv",-1);} else {emit("irem",-1);}
            } else {
                errors.add("Error: cannot mix types. Line: " + $op.line);
            }
        }
        )*
        {   $type = $f1.type;   }
    ;

factor returns [char type]
    :   NUMBER
        { emit("ldc " + $NUMBER.text,1); $type = 'i'; }
    |   OP_PAR exp = expression CL_PAR
        { $type = $exp.type; }
    |   VARIABLE
        {   int pos_table = symbol_table.indexOf($VARIABLE.text);
            if(pos_table == -1){
                errors.add("Error: Variable " + $VARIABLE.text + " not declared. Line: " + $VARIABLE.line);
            } else {
                    symbol_not_utilized.remove($VARIABLE.text);
                    if(type_table.get(pos_table) == 'i'){
                        emit("iload " + pos_table, 1);
                        $type = 'i';  
                    } else if(type_table.get(pos_table) == 'a'){
                        emit("aload " + pos_table, 1);
                        $type = 'a';  
                    } else if(type_table.get(pos_table) == 'v'){
                        emit("aload " + pos_table, 1);
                        emit("invokevirtual Array/string()Ljava/lang/String;", 0);
                        $type = 'a';  
                    }
            }
        }
    |   READINT OP_PAR CL_PAR
        { emit("invokestatic Runtime/readInt()I", 1); $type = 'i'; }
    |   STRING
        { emit("ldc " + $STRING.text,1); $type = 'a'; }
    |   READSTRING OP_PAR CL_PAR
        { emit("invokestatic Runtime/readString()Ljava/lang/String;", 1); $type = 'a'; }
    | var = VARIABLE { int qtd_args = 0; } OP_PAR ( arguments { qtd_args = $arguments.qtd; })? CL_PAR
        {
            if(!function_table.contains($var.text)) {
                errors.add("Error: function '" + $var.text + "' do not exists. Line: " + $var.line);
            } else {
                if(f_num_param.get(function_table.indexOf($var.text)) != qtd_args){
                    errors.add("Error: wrong number of arguments. Line: " + $var.line);
                }
                if (!f_returns.get(function_table.indexOf($var.text))) {
                    errors.add("Error: void function '" + $var.text + "' does not return a value. Line: " + $var.line);
                }
            }
            String s_arg = "";
            for (int i = 0; i < qtd_args; i++) {
                s_arg = s_arg + "I";
            }
            emit("invokestatic Test/" + $var.text + "(" + s_arg + ")I", 0);
            $type = 'i';
        }
;