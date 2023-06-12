grammar Statements;

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