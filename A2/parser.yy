%skeleton "lalr1.cc"
%require  "3.0.1"

%defines 
%define api.namespace {IPL}
%define api.parser.class {Parser}

%define parse.trace
%locations

%code requires{
  #include "ast.hh"
  #include "symbtab.hh"
  #include "location.hh"

  namespace IPL {
    class Scanner;
  }

  // # ifndef YY_NULLPTR
  // #  if defined __cplusplus && 201103L <= __cplusplus
  // #   define YY_NULLPTR nullptr
  // #  else
  // #   define YY_NULLPTR 0
  // #  endif
  // # endif

}

%printer { std::cerr << $$; } STRUCT
%printer { std::cerr << $$; } VOID
%printer { std::cerr << $$; } INT
%printer { std::cerr << $$; } FLOAT
%printer { std::cerr << $$; } IF
%printer { std::cerr << $$; } ELSE
%printer { std::cerr << $$; } WHILE
%printer { std::cerr << $$; } FOR
%printer { std::cerr << $$; } RETURN 
%printer { std::cerr << $$; } IDENTIFIER
%printer { std::cerr << $$; } INT_CONSTANT
%printer { std::cerr << $$; } FLOAT_CONSTANT
%printer { std::cerr << $$; } STRING_LITERAL
%printer { std::cerr << $$; } AND_OP
%printer { std::cerr << $$; } OR_OP
%printer { std::cerr << $$; } EQ_OP
%printer { std::cerr << $$; } NE_OP
%printer { std::cerr << $$; } LE_OP
%printer { std::cerr << $$; } GE_OP
%printer { std::cerr << $$; } INC_OP
%printer { std::cerr << $$; } PTR_OP
%printer { std::cerr << $$; } OTHERS


%parse-param { Scanner  &scanner  }
%locations
%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   #include <string>
   #include <map>
   #include <vector>
   #include <utility>

   #include "scanner.hh"

   extern SymbTab gst, gstfun, gststruct;
   std::map<std::string, abstract_astnode*> ast;

   int curr_offset = 0;
   declaration_list_class* func_declarations = new declaration_list_class();
   std::map<std::string, dataType*> variables;
   std::map<std::string, dataType*> fun_types;
   std::vector<fun_declarator_class*> functions;
   std::map<std::string, std::map<std::string, dataType*> > struct_variables;
   int curr_struct = 0;
   std::string curr_struct_name;
   dataType* curr_dtype;
#undef yylex
#define yylex IPL::Parser::scanner.yylex

}

%define api.value.type variant
%define parse.assert

%start translation_unit



%token '\n'
%token <std::string>  STRUCT
%token <std::string>  VOID
%token <std::string>  INT
%token <std::string>  FLOAT
%token <std::string>  IF
%token <std::string>  ELSE
%token <std::string>  WHILE
%token <std::string>  FOR
%token <std::string>  RETURN
%token <std::string>  IDENTIFIER
%token <std::string>  INT_CONSTANT
%token <std::string>  FLOAT_CONSTANT
%token <std::string>  STRING_LITERAL
%token <std::string>  AND_OP
%token <std::string>  OR_OP
%token <std::string>  EQ_OP
%token <std::string>  NE_OP
%token <std::string>  LE_OP
%token <std::string>  GE_OP
%token <std::string>  INC_OP
%token <std::string>  PTR_OP
%token <std::string>  OTHERS
%token '-' '!' '&' '<' '>' '+' ',' '(' ')' ':' '{' '}' '*' ';' '[' ']' '=' '/' '.'

%nterm <abstract_astnode*> translation_unit 
%nterm <abstract_astnode*> struct_specifier 
%nterm <abstract_astnode*> function_definition 
%nterm <std::string> type_specifier 
%nterm <fun_declarator_class*> fun_declarator 
%nterm <parameter_list_class*> parameter_list 
%nterm <parameter_class*> parameter_declaration
%nterm <declarator_class*> declarator_arr
%nterm <declarator_class*> declarator 
%nterm <abstract_astnode*> compound_statement 
%nterm <seq_astnode*> statement_list 
%nterm <statement_astnode*> statement 
%nterm <exp_astnode*> assignment_expression
%nterm <statement_astnode*> assignment_statement 
%nterm <proccall_astnode*> procedure_call 
%nterm <exp_astnode*> expression 
%nterm <exp_astnode*> logical_and_expression
%nterm <exp_astnode*> equality_expression
%nterm <exp_astnode*> relational_expression
%nterm <exp_astnode*> additive_expression 
%nterm <exp_astnode*> unary_expression 
%nterm <exp_astnode*> multiplicative_expression 
%nterm <exp_astnode*> postfix_expression 
%nterm <exp_astnode*> primary_expression 
%nterm <std::vector<exp_astnode*>* > expression_list
%nterm <std::string> unary_operator 
%nterm <statement_astnode*> selection_statement 
%nterm <statement_astnode*> iteration_statement 
%nterm <declaration_list_class*> declaration_list 
%nterm <declaration_class*> declaration 
%nterm <declarator_list_class*> declarator_list

%%
translation_unit :
struct_specifier
{

}
| function_definition
{

}
| translation_unit struct_specifier
{

}
| translation_unit function_definition
{

}


struct_specifier :
STRUCT IDENTIFIER 
{
  curr_struct = 1;
  curr_struct_name = "struct " + $2;
  if (gst.Entries.count(curr_struct_name) > 0) {
    std::string err_msg = "\"" + curr_struct_name + "\" has a previous declaration";
    error(@$, err_msg);
  }
  gst.Entries[curr_struct_name] = new SymbTabEntry("struct", "global", 0, 0, "-", nullptr);
} 
'{' declaration_list '}' ';'
{
	std::string struct_name = $2;
  // if (gst.Entries.count(struct_name) > 0) {
  //   std::string err_msg = "\"" + struct_name + "\" has a previous declaration";
  //   error(@$, err_msg);
  // }
  std::string type = "struct " + struct_name;
  int struct_size = -curr_offset;
  SymbTab* struct_symbTab = new SymbTab();

  // Constructing the symbol table of the struct
  // $4 is of type declaration_list_class
  // declaration below is of type declaration_class*

  for (auto declaration : $5 -> declarations) {
    for (auto entry : declaration -> symbTabEntries) {
      struct_symbTab->Entries[entry.first] = entry.second;
    }
  }

  gst.Entries["struct " + struct_name] = new SymbTabEntry("struct", "global", struct_size, 0, "-", struct_symbTab);
  
  // Reset curr_offset back to 0
  curr_offset = 0;
  func_declarations = new declaration_list_class();
  struct_variables["struct " + $2] = variables;
  variables.clear();
  curr_struct = 0;
  curr_struct_name = "";
}


type_specifier :
VOID
{
	$$ = "void";
}
| INT
{
	$$ = "int";
}
| FLOAT
{
	$$ = "float";
}
| STRUCT IDENTIFIER
{
	$$ = "struct " + $2;
}


parameter_declaration :
type_specifier declarator
{
  std::string type = createType($1, $2->ptr_count, $2->dimensions);
  std::string name = $2->identifier_name;
  if ($1 == "void" && $2->ptr_count == 0) {
    std::string err_msg = "Cannot declare variable of type \"void\"";
    error(@$, err_msg);
  }
  if (variables.count(name) > 0) {
    std::string err_msg = "\"" + name + "\" has a previous declaration";
    error(@$, err_msg);
  }
  else {
    variables[name] = new dataType($1, $2->ptr_count, $2->dimensions);
  }
  int width = 1;
  for (auto dim : $2->dimensions) {
    width *= dim;
  }
  int data_type_width;
  if ($2->ptr_count > 0) {
    data_type_width = PTR_SIZE;
  }
  else if ($1 == "int") {
    data_type_width = INT_SIZE;
  }
  else if ($1 == "float") {
    data_type_width = FLOAT_SIZE;
  }
  else if ($1 == "void") {
    if ($2->ptr_count > 0) {
      data_type_width = PTR_SIZE;
    }
  }
  else {

    data_type_width = gst.Entries[$1]->width;
  }
  width *= data_type_width;
  curr_offset += width;
  $$ = new parameter_class(name, width, type);
  $$->dtype = new dataType($1, $2->ptr_count, $2->dimensions);
}

parameter_list :
parameter_declaration
{
	$$ = new parameter_list_class();
  $$->parameters.push_back($1);
}
| parameter_list ',' parameter_declaration
{
	$$ = $1;
  $$->parameters.push_back($3);
}


fun_declarator :
IDENTIFIER '(' parameter_list ')'
{
  curr_offset += 12;
  std::string func_name = $1;
  if (gst.Entries.count(func_name) > 0) {
    std::string err_msg = "\"" + func_name + "\" has a previous declaration";
    error(@$, err_msg);
  }
	$$ = new fun_declarator_class();
  $$->name = $1;
  for (auto parameter : $3->parameters) {
    std::string varfun_str = "var";
    std::string param_str = "param";
    $$->funParamEntries.push_back(make_pair(parameter->name, new SymbTabEntry(varfun_str, param_str, parameter->width, curr_offset - parameter->width, parameter->type, nullptr)));
    $$->funParamTypes.push_back(parameter -> dtype);
    curr_offset -= parameter->width;
  }
  functions.push_back($$);
  curr_offset = 0;
}
| IDENTIFIER '(' ')'
{
  std::string func_name = $1;
  if (gst.Entries.count(func_name) > 0) {
    std::string err_msg = "\"" + func_name + "\" has a previous declaration";
    error(@$, err_msg);
  }
	$$ = new fun_declarator_class();
  $$->name = $1;
  functions.push_back($$);
}



compound_statement :
'{' '}'
{
	$$ = new seq_astnode();
}
| '{' statement_list '}'
{
	$$ = $2;
}
| '{' declaration_list '}'
{
  $$ = new seq_astnode();
}
| '{' declaration_list statement_list '}'
{
	$$ = $3;
}


function_definition :
type_specifier fun_declarator 
{
  curr_dtype = new dataType($1);
  SymbTab* func_symbTab = new SymbTab();
  for (auto paramEntry : $2->funParamEntries) {
    func_symbTab->Entries[paramEntry.first] = paramEntry.second;
  }
  gst.Entries[$2->name] = new SymbTabEntry("fun", "global", 0, 0, $1, func_symbTab);
  fun_types[$2->name] = new dataType($1);
} 
compound_statement
{
  std::string func_name = $2->name;
  SymbTab* fun_symbTab = new SymbTab();
  for (auto paramEntry : $2->funParamEntries) {
    fun_symbTab->Entries[paramEntry.first] = paramEntry.second;
  }
  for (auto declaration : func_declarations -> declarations) {
    for (auto paramEntry : declaration -> symbTabEntries) {
      fun_symbTab->Entries[paramEntry.first] = paramEntry.second;
    }
  }
	gst.Entries[func_name] = new SymbTabEntry("fun", "global", 0, 0, $1, fun_symbTab);
  $$ = $4;
  ast[func_name] = $$;
  func_declarations = new declaration_list_class();
  variables.clear();
  //fun_types[func_name] = new dataType($1);
  curr_offset = 0;
}

statement_list :
statement
{
  $$ = new seq_astnode();
  $$->statements.push_back($1);
}
| statement_list statement
{
	$$ = $1;
  $$->statements.push_back($2);
}


statement :
';'
{
	$$ = new empty_astnode();
}
| '{' statement_list '}'
{
	$$ = $2;
}
| selection_statement
{
	$$ = $1;
}
| iteration_statement
{
  $$ = $1;
}
| assignment_statement
{
	$$ = $1;
}
| procedure_call
{
	$$ = $1;
}
| RETURN expression ';'
{
  if (curr_dtype->isInt() && $2->dtype->isInt()) {
	  $$ = new return_astnode($2);
  }
  else if (curr_dtype->isInt() && $2->dtype->isFloat()) {
	  $$ = new return_astnode(new op_unary_astnode("TO_INT", $2));
  }
  else if (curr_dtype->isFloat() && $2->dtype->isInt()) {
	  $$ = new return_astnode(new op_unary_astnode("TO_FLOAT", $2));
  }
  else if (curr_dtype->isFloat() && $2->dtype->isFloat()) {
	  $$ = new return_astnode($2);
  }
  else if (curr_dtype->type == $2->dtype->type && !($2->dtype->isPointer())) {
	  $$ = new return_astnode($2);
  }
  else {
    std::string err_msg = "Incompatible type \"" + $2->dtype->toString() + "\" returned, expected \"" + curr_dtype->toString() + "\"";
    error(@$, err_msg);
  }
}


assignment_expression :
unary_expression '=' expression
{
  if ($1->lval == 0) {
    std::string err_msg = "Left operand of assignment should have an lvalue";
    error(@$, err_msg);
  }
  if ($1->dtype->isArray()) {
    std::string err_msg = "Left operand of assignment should have a modifiable lvalue";
    error(@$, err_msg);
  }
  if ($1->dtype->isInt() && $3->dtype->isFloat()) {
    $$ = new assignE_astnode($1, new op_unary_astnode("TO_INT", $3));
  }
  else if ($1->dtype->isFloat() && $3->dtype->isInt()) {
    $$ = new assignE_astnode($1, new op_unary_astnode("TO_FLOAT", $3));
  }
  else if ($1->dtype->isPointer() && $3->dtype->isInt() && $3->isZero) {
    $$ = new assignE_astnode($1, $3);
  }
  else if (areCompatible($1->dtype, $3->dtype)) {
    $$ = new assignE_astnode($1, $3);
  }
  else {
    std::string err_msg = "Incompatible assignment when assigning to type \"" + $1->dtype->toString() + "\" from type \"" + $3->dtype->toString() + "\"";
    error(@$, err_msg);
  }
  if ($1->dtype->isVoidPtr() == 1) {
    $$->dtype = $3->dtype;
  }
  else {
    $$->dtype = $1->dtype;
  }
  $$->lval = 0;
}


assignment_statement :
assignment_expression ';'
{
  $$ = new assignS_astnode($1 -> left, $1 -> right);
}


procedure_call :
IDENTIFIER '(' ')' ';'
{
  if ($1 != "printf" && $1 != "scanf") {
    if ( (gst.Entries.count($1) == 0) || (gst.Entries.count($1) > 0 && gst.Entries[$1]->varfun != "fun") ) {
      std::string err_msg = "Procedure \"" + $1 + "\" not declared";
      error(@$, err_msg);
    }
    int fun_index;
    for (int i = 0; i < functions.size(); i++) {
      if (functions[i]->name == $1) {
        fun_index = i;
      }
    }
    int nparams = functions[fun_index]->funParamTypes.size();
    if (nparams > 0) {
      std::string err_msg = "Procedure \"" + $1 + "\" called with too few arguments";
      error(@$, err_msg);
    }
  }
	$$ = new proccall_astnode($1);
}
| IDENTIFIER '(' expression_list ')' ';'
{
  std::vector<exp_astnode*> ast_params;
  if ($1 != "printf" && $1 != "scanf") {
    if ( (gst.Entries.count($1) == 0) || (gst.Entries.count($1) > 0 && gst.Entries[$1]->varfun != "fun") ) {
      std::string err_msg = "Procedure \"" + $1 + "\" not declared";
      error(@$, err_msg);
    }
    std::vector<exp_astnode*> given_params = *($3);
    int fun_index;
    for (int i = 0; i < functions.size(); i++) {
      if (functions[i]->name == $1) {
        fun_index = i;
      }
    }
    int nparams = functions[fun_index]->funParamTypes.size();
    if (given_params.size() > nparams) {
      std::string err_msg = "Procedure \"" + $1 + "\" called with too many arguments";
      error(@$, err_msg);
    }
    else if (given_params.size() < nparams) {
      std::string err_msg = "Procedure \"" + $1 + "\" called with too few arguments";
      error(@$, err_msg);
    }
    for (int i = 0; i < given_params.size(); i++) {
      dataType* given_dtype = given_params[i]->dtype;
      dataType* template_dtype = functions[fun_index]->funParamTypes[i];
      if (given_dtype->isInt() && template_dtype->isFloat()) {
        ast_params.push_back(new op_unary_astnode("TO_FLOAT", given_params[i]));
      }
      else if (given_dtype->isFloat() && template_dtype->isInt()) {
        ast_params.push_back(new op_unary_astnode("TO_INT", given_params[i]));
      }
      else if (given_params[i]->isZero && (template_dtype->isPointer() || template_dtype->isArray())) {
        ast_params.push_back(given_params[i]);
      }
      else if (areCompatible(given_dtype, template_dtype)) {
        ast_params.push_back(given_params[i]);
      }
      else {
        std::string err_msg = "Expected \"" + template_dtype->toString() + "\" but argument is of type \"" + given_dtype->toString() + "\"";
        error(@$, err_msg);
      }
    }
  }
  else {
    ast_params = *($3);
  }
	$$ = new proccall_astnode($1,ast_params);
}


expression :
logical_and_expression
{
  $$ = $1;
}
| expression OR_OP logical_and_expression
{
  if (!($1->dtype->isArithmeticType() && $3->dtype->isArithmeticType())) {
    std::string err_msg = "Invalid operand types for binary &&, \"" + $1->dtype->toString() + "\" and \"" + $3->dtype->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode("OR_OP", $1, $3);
  $$->dtype = new dataType("int");
  $$->lval = 0;
}


logical_and_expression :
equality_expression
{
	$$ = $1;
}
| logical_and_expression AND_OP equality_expression
{
  if (!($1->dtype->isArithmeticType() && $3->dtype->isArithmeticType())) {
    std::string err_msg = "Invalid operand types for binary &&, \"" + $1->dtype->toString() + "\" and \"" + $3->dtype->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode("AND_OP", $1, $3);
  $$->dtype = new dataType("int");
  $$->lval = 0;
}


equality_expression :
relational_expression
{
  $$ = $1;
}
| equality_expression EQ_OP relational_expression
{
  if ($1->dtype->isInt() && $3->dtype->isInt()) {
    $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else if ($1->dtype->isInt() && $3->dtype->isFloat()) {
    $$ = new op_binary_astnode("EQ_OP_FLOAT", new op_unary_astnode("TO_FLOAT", $1), $3);
  }
  else if ($1->dtype->isFloat() && $3->dtype->isInt()) {
    $$ = new op_binary_astnode("EQ_OP_FLOAT", $1, new op_unary_astnode("TO_FLOAT", $3));
  }
  else if ($1->dtype->isFloat() && $3->dtype->isFloat()) {
    $$ = new op_binary_astnode("EQ_OP_FLOAT", $1, $3);
  }
  else if ($1->dtype->isPointer() && $3->dtype->isPointer() && areStrictlyCompatible($1->dtype, $3->dtype)) {
	  $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else if ($1->dtype->isPointer() && $3->dtype->isPointer() && ($1->dtype->isVoidPtr() || $3->dtype->isVoidPtr())) {
    $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else if ($1->dtype->isPointer() && $3->isZero) {
    $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else if ($1->isZero && $3->dtype->isPointer()) {
    $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else {
    std::string err_msg = "Invalid operand types for binary ==, \"" + $1->dtype->toString() + "\" and \"" + $3->dtype->toString() + "\"";
    error(@$, err_msg);
  }
  $$->dtype = new dataType("int");
  $$->lval = 0;
}
| equality_expression NE_OP relational_expression
{
  if ($1->dtype->isInt() && $3->dtype->isInt()) {
    $$ = new op_binary_astnode("NE_OP_INT", $1, $3);
  }
  else if ($1->dtype->isInt() && $3->dtype->isFloat()) {
    $$ = new op_binary_astnode("NE_OP_FLOAT", new op_unary_astnode("TO_FLOAT", $1), $3);
  }
  else if ($1->dtype->isFloat() && $3->dtype->isInt()) {
    $$ = new op_binary_astnode("NE_OP_FLOAT", $1, new op_unary_astnode("TO_FLOAT", $3));
  }
  else if ($1->dtype->isFloat() && $3->dtype->isFloat()) {
    $$ = new op_binary_astnode("NE_OP_FLOAT", $1, $3);
  }
  else if ($1->dtype->isPointer() && $3->dtype->isPointer() && areStrictlyCompatible($1->dtype, $3->dtype)) {
	  $$ = new op_binary_astnode("NE_OP_INT", $1, $3);
  }
  else if ($1->dtype->isPointer() && $3->dtype->isPointer() && ($1->dtype->isVoidPtr() || $3->dtype->isVoidPtr())) {
    $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else if ($1->dtype->isPointer() && $3->isZero) {
    $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else if ($1->isZero && $3->dtype->isPointer()) {
    $$ = new op_binary_astnode("EQ_OP_INT", $1, $3);
  }
  else {
    std::string err_msg = "Invalid operand types for binary !=, \"" + $1->dtype->toString() + "\" and \"" + $3->dtype->toString() + "\"";
    error(@$, err_msg);
  }
  $$->dtype = new dataType("int");
  $$->lval = 0;
}


relational_expression :
additive_expression
{
	$$ = $1;
}
| relational_expression '<' additive_expression
{
  dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "LT_OP_";
  dataType* result_dtype = new dataType("int");
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
  }
  else if (t1->isArithmeticType() && t2->isArithmeticType() && areStrictlyCompatible(t1, t2)) {
    op += "INT";
  }
  else {
    std::string err_msg = "Invalid operands for binary <,\"" + t1->toString() + "\" and \"" + t2->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}
| relational_expression '>' additive_expression
{
  dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "GT_OP_";
  dataType* result_dtype = new dataType("int");
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
  }
  else if (t1->isArithmeticType() && t2->isArithmeticType() && areStrictlyCompatible(t1, t2)) {
    op += "INT";
  }
  else {
    std::string err_msg = "Invalid operands for binary >,\"" + t1->toString() + "\" and \"" + t2->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}
| relational_expression LE_OP additive_expression
{
	dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "LE_OP_";
  dataType* result_dtype = new dataType("int");
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
  }
  else if (t1->isArithmeticType() && t2->isArithmeticType() && areStrictlyCompatible(t1, t2)) {
    op += "INT";
  }
  else {
    std::string err_msg = "Invalid operands for binary <=,\"" + t1->toString() + "\" and \"" + t2->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}
| relational_expression GE_OP additive_expression
{
  dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "GE_OP_";
  dataType* result_dtype = new dataType("int");
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
  }
  else if (t1->isArithmeticType() && t2->isArithmeticType() && areStrictlyCompatible(t1, t2)) {
    op += "INT";
  }
  else {
    std::string err_msg = "Invalid operands for binary >=,\"" + t1->toString() + "\" and \"" + t2->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}


additive_expression :
multiplicative_expression
{
	$$ = $1;
}
| additive_expression '+' multiplicative_expression
{
  dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "PLUS_";
  dataType* result_dtype;
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
    result_dtype = new dataType("int");
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
    result_dtype = new dataType("float");
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
    result_dtype = new dataType("float");
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
    result_dtype = new dataType("float");
  }
  else if (t1->isPointer() && t2->isInt()) {
    op += "INT";
    result_dtype = t1;
  }
  else if (t1->isInt() && t2->isPointer() > 0) {
    op += "INT";
    result_dtype = t2;
  }
  else {
    std::string err_msg = "Invalid operands for binary \"+\",\"" + t1->toString() + "\" and \"" + t2->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}
| additive_expression '-' multiplicative_expression
{
  dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "MINUS_";
  dataType* result_dtype;
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
    result_dtype = new dataType("int");
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
    result_dtype = new dataType("float");
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
    result_dtype = new dataType("float");
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
    result_dtype = new dataType("float");
  }
  else if (t1->isPointer() && t2->isInt()) {
    op += "INT";
    result_dtype = t1;
  }
  else if (t1->isPointer() && t2->isPointer() && areStrictlyCompatible(t1, t2)) {
    op += "INT";
    //result_dtype = t1;
    result_dtype = new dataType("int");
  }
  else {
    std::string err_msg = "Invalid operands for binary \"-\", \"" + t1->toString() + "\" and \"" + t2->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}


unary_operator :
'-'
{
	$$ = "UMINUS";
}
| '!'
{
  $$ = "NOT";
}
| '&'
{
	$$ = "ADDRESS";
}
| '*'
{
	$$ = "DEREF";
}

unary_expression :
postfix_expression
{
	$$ = $1;
}
| unary_operator unary_expression
{
  int exp_lval;
  dataType* exp_dtype;
	if ($1 == "UMINUS") {
    if ($2->dtype->isInt() == 0 && $2->dtype->isFloat() == 0) {
      std::string err_msg = "Wrong type argument to unary \"-\"";
      error(@$, err_msg);
    }
    exp_lval = 0;
    exp_dtype = $2->dtype;
  }
  else if ($1 == "NOT") {
    if (!$2->dtype->isArithmeticType()) {
      std::string err_msg = "Operand of NOT should be an int, float or pointer";
      error(@$, err_msg);
    }
    exp_lval = 0;
    exp_dtype = new dataType("int");
  }
  else if ($1 == "ADDRESS") {
    /* The line below previously used to be isPointer() */
    // if (!($2->dtype->isArray()) && $2->lval == 0) {
    //   std::string err_msg = "Operand to & should have an lvalue";
    //   error(@$, err_msg);
    // }
    if ($2->lval == 0) {
      std::string err_msg = "Operand to & should have an lvalue";
      error(@$, err_msg);
    }
    std::vector<int> exp_dimensions;
    exp_dimensions.push_back(1);
    for (auto dim : $2->dtype->dimensions) {
      exp_dimensions.push_back(dim);
    }
    exp_dtype = new dataType($2->dtype->type, $2->dtype->ptr_count, exp_dimensions);
    exp_lval = 0;
  }
  else if ($1 == "DEREF") {
    if ($2->dtype->isPointer() == 0) {
      std::string err_msg = "Invalid operand type \"" + $2->dtype->toString() + "\" of unary *";
      error(@$, err_msg);
    }
    int isarr = 1;
    std::vector<int> exp_dimensions;
    int exp_ptr_count = $2->dtype->ptr_count;
    if ($2->dtype->dimensions.size() > 0) {
      for (int i = 1; i < $2->dtype->dimensions.size(); i++) {
        exp_dimensions.push_back($2->dtype->dimensions[i]);
      }
    }
    else {
      exp_ptr_count--;
    }
    exp_dtype = new dataType($2->dtype->type, exp_ptr_count, exp_dimensions);
    // if (exp_dtype->isArray()) {
    //   exp_lval = 0;
    // }
    // else {
    //   exp_lval = 1;
    // }
    exp_lval = 1;
  }
  $$ = new op_unary_astnode($1, $2);
  $$->lval = exp_lval;
  $$->dtype = exp_dtype;
}


multiplicative_expression :
unary_expression
{
	$$ = $1;
}
| multiplicative_expression '*' unary_expression
{
  dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "MULT_";
  dataType* result_dtype;
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
    result_dtype = new dataType("int");
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
    result_dtype = new dataType("float");
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
    result_dtype = new dataType("float");
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
    result_dtype = new dataType("float");
  }
  else {
    std::string err_msg = "Invalid operands for binary *," + t1->toString() + " and " + t2->toString();
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}
| multiplicative_expression '/' unary_expression
{
  dataType* t1 = $1->dtype;
  dataType* t2 = $3->dtype;
  exp_astnode* left = $1;
  exp_astnode* right = $3;
  std::string op;
  op = "DIV_";
  dataType* result_dtype;
  if (t1->isInt() && t2->isInt()) {
    op += "INT";
    result_dtype = new dataType("int");
  }
  else if (t1->isFloat() && t2->isInt()) {
    op += "FLOAT";
    right = new op_unary_astnode("TO_FLOAT", $3);
    result_dtype = new dataType("float");
  }
  else if (t1->isInt() && t2->isFloat()) {
    op += "FLOAT";
    left = new op_unary_astnode("TO_FLOAT", $1);
    result_dtype = new dataType("float");
  }
  else if (t1->isFloat() && t2->isFloat()) {
    op += "FLOAT";
    result_dtype = new dataType("float");
  }
  else {
    std::string err_msg = "Invalid operands for binary /," + t1->toString() + " and " + t2->toString();
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode(op, left, right);
  $$->dtype = result_dtype;
  $$->lval = 0;
}


postfix_expression :
primary_expression
{
	$$ = $1;
}
| postfix_expression '[' expression ']'
{
  if ($3->dtype->isInt() == 0) {
    std::string err_msg = "Array subscript is not an integer";
    error(@$, err_msg);
  }
  if ($1->dtype->isPointer() == 0) {
    std::string err_msg = "Subscripted value is neither array nor pointer";
    error(@$, err_msg);
  }
	$$ = new arrayref_astnode($1, $3);
  std::string exp_type = $1->dtype->type;
  int exp_ptr_count = $1->dtype->ptr_count;
  std::vector<int> exp_dimensions;
  if ($1->dtype->dimensions.size() > 0) {
    for (int i = 1; i < $1->dtype->dimensions.size(); i++) {
      exp_dimensions.push_back($1->dtype->dimensions[i]);
    }
  }
  else {
    exp_ptr_count--;
  }
  $$->dtype = new dataType(exp_type, exp_ptr_count, exp_dimensions);
  // if ($$->dtype->isArray() > 0) {
  //   $$->lval = 0;
  // }
  // else {
  //   $$->lval = 1;
  // }
  $$->lval = 1;
}
| IDENTIFIER '(' ')'
{
  if ($1 != "printf" && $1 != "scanf") {
    if ( (gst.Entries.count($1) == 0) || (gst.Entries.count($1) > 0 && gst.Entries[$1]->varfun != "fun") ) {
      std::string err_msg = "Function \"" + $1 + "\" not declared";
      error(@$, err_msg);
    }
    int fun_index;
    for (int i = 0; i < functions.size(); i++) {
      if (functions[i]->name == $1) {
        fun_index = i;
      }
    }
    int nparams = functions[fun_index]->funParamTypes.size();
    if (nparams > 0) {
      std::string err_msg = "Function \"" + $1 + "\" called with too few arguments";
      error(@$, err_msg);
    }
  }
  $$ = new funcall_astnode($1);
  if ($1 == "printf" || $1 == "scanf") {
    $$->dtype = new dataType("void");
  }
  else {
    $$->dtype = fun_types[$1];
  }
  $$->lval = 0;
}
| IDENTIFIER '(' expression_list ')'
{
  std::vector<exp_astnode*> ast_params;
  if ($1 != "printf" && $1 != "scanf") {
    if ( (gst.Entries.count($1) == 0) || (gst.Entries.count($1) > 0 && gst.Entries[$1]->varfun != "fun") ) {
      std::string err_msg = "Function \"" + $1 + "\" not declared";
      error(@$, err_msg);
    }
    std::vector<exp_astnode*> given_params = *($3);
    int fun_index;
    for (int i = 0; i < functions.size(); i++) {
      if (functions[i]->name == $1) {
        fun_index = i;
      }
    }
    int nparams = functions[fun_index]->funParamTypes.size();
    if (given_params.size() > nparams) {
      std::string err_msg = "Function \"" + $1 + "\" called with too many arguments";
      error(@$, err_msg);
    }
    else if (given_params.size() < nparams) {
      std::string err_msg = "Function \"" + $1 + "\" called with too few arguments";
      error(@$, err_msg);
    }
    for (int i = 0; i < given_params.size(); i++) {
      dataType* given_dtype = given_params[i]->dtype;
      dataType* template_dtype = functions[fun_index]->funParamTypes[i];
      if (given_dtype->isInt() && template_dtype->isFloat()) {
        ast_params.push_back(new op_unary_astnode("TO_FLOAT", given_params[i]));
      }
      else if (given_dtype->isFloat() && template_dtype->isInt()) {
        ast_params.push_back(new op_unary_astnode("TO_INT", given_params[i]));
      }
      else if (given_params[i]->isZero && (template_dtype->isPointer() || template_dtype->isArray())) {
        ast_params.push_back(given_params[i]);
      }
      else if (areCompatible(given_dtype, template_dtype)) {
        ast_params.push_back(given_params[i]);
      }
      else {
        std::string err_msg = "Expected \"" + template_dtype->toString() + "\" but argument is of type \"" + given_dtype->toString() + "\"";
        error(@$, err_msg);
      }
    }
  }
  else {
    ast_params = *($3);
  }
	$$ = new funcall_astnode($1, ast_params);
  $$->lval = 0;
  if ($1 == "printf" || $1 == "scanf") {
    $$->dtype = new dataType("void");
  }
  else {
    $$->dtype = fun_types[$1];
  }
}
| postfix_expression '.' IDENTIFIER
{
  if ($1->dtype->isStruct() == 0) {
    std::string err_msg = "Left operand of \".\" is not a structure";
    error(@$, err_msg);
  }
  std::string struct_name = $1->dtype->type;
  SymbTab* struct_symbtab = gst.Entries[struct_name]->symbtab;
  if (struct_symbtab->Entries.count($3) == 0) {
    std::string err_msg = "Struct \"" + $1->dtype->type + "\" has no member named \"" + $3 + "\"";
    error(@$, err_msg);
  }
	$$ = new member_astnode($1, new identifier_astnode($3));
  $$->dtype = struct_variables[struct_name][$3];
  // if ($$->dtype->isArray()) {
  //   $$->lval = 0;
  // }
  // else {
  //   $$->lval = 1;
  // }
  $$->lval = 1;
  
}
| postfix_expression PTR_OP IDENTIFIER
{
  if ($1->dtype->isStructPtr() == 0) {
    std::string err_msg = "Left operand of \"->\" is not a pointer to structure";
    error(@$, err_msg);
  }
  std::string struct_name = $1->dtype->type;
  SymbTab* struct_symbtab = gst.Entries[struct_name]->symbtab;
  if (struct_symbtab->Entries.count($3) == 0) {
    std::string err_msg = "Struct \"" + $1->dtype->type + "\" has no member named \"" + $3 + "\"";
    error(@$, err_msg);
  }
	$$ = new arrow_astnode($1, new identifier_astnode($3));
  $$->dtype = struct_variables[struct_name][$3];
  // if ($$->dtype->isArray()) {
  //   $$->lval = 0;
  // }
  // else {
  //   $$->lval = 1;
  // }
  $$->lval = 1;
}
| postfix_expression INC_OP
{
  if ($1->dtype->isInt() == 0 && $1->dtype->isFloat() == 0 && $1->dtype->isPurePointer() == 0) {
    std::string err_msg = "Operand of \"++\" should be an int, float or a pointer";
    error(@$, err_msg);
  }
  if ($1->lval == 0) {
    std::string err_msg = "Operand of \"++\" should have lvalue";
    error(@$, err_msg);
  }
  $$ = new op_unary_astnode("PP", $1);
  $$->dtype = $1->dtype;
  $$->lval = 0;
}


primary_expression :
IDENTIFIER
{
  if (variables.count($1) == 0) {
    std::string err_msg = "Variable \"" + $1 + "\" not declared";
    error(@$, err_msg);
  }
  $$ = new identifier_astnode($1);
  $$->dtype = variables[$1];
  // if ($$->dtype->isArray()) {
  //   $$->lval = 0;
  // }
  // else {
  //   $$->lval = 1;
  // }
  $$->lval = 1;
}
| INT_CONSTANT
{
	$$ = new intconst_astnode(stoi($1));
  $$->lval = 0;
  $$->dtype = new dataType("int");
}
| FLOAT_CONSTANT
{
	$$ = new floatconst_astnode(stof($1));
  $$->lval = 0;
  $$->dtype = new dataType("float");
}
| STRING_LITERAL
{
	$$ = new stringconst_astnode($1);
  $$->lval = 0;
  $$->dtype = new dataType("string");
}
| '(' expression ')'
{
	$$ = $2;
}


expression_list :
expression
{
	$$ = new std::vector<exp_astnode*>;
  $$->push_back($1);
}
| expression_list ',' expression
{
  $$ = $1;
  $$->push_back($3);
}


selection_statement :
IF '(' expression ')' statement ELSE statement
{
  if ($3->dtype->isStruct()) {
    std::string err_msg = "Used struct type where scalar is required";
    error(@$, err_msg);
  }
  $$ = new if_astnode($3, $5, $7);
}


iteration_statement :
WHILE '(' expression ')' statement
{
  if ($3->dtype->isStruct()) {
    std::string err_msg = "Used struct type where scalar is required";
    error(@$, err_msg);
  }
  $$ = new while_astnode($3, $5);
}
| FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement
{
  if ($5->dtype->isStruct()) {
    std::string err_msg = "Used struct type where scalar is required";
    error(@$, err_msg);
  }
	$$ = new for_astnode($3, $5, $7, $9);
}


declarator_arr :
IDENTIFIER
{
	$$ = new declarator_class();
  $$->identifier_name = $1;
}
| declarator_arr '[' INT_CONSTANT ']'
{
	$$ = $1;
  $$->dimensions.push_back(stoi($3));
}


declarator :
declarator_arr
{
	$$ = $1;
}
| '*' declarator
{
  $$ = $2;
  $$->ptr_count++;
}



declarator_list :
declarator
{
	$$ = new declarator_list_class();
  $$->declarators.push_back($1);
}
| declarator_list ',' declarator
{
	$$ = $1;
  $$->declarators.push_back($3);
}

declaration :
type_specifier declarator_list ';'
{
	$$ = new declaration_class();
  for (auto it = $2->declarators.begin(); it != $2->declarators.end(); ++it) {
    declarator_class* declarator = *it;
    std::string name = declarator->identifier_name;
    if ($1 != "int" && $1 != "float" && $1 != "void") {
      if (gst.Entries.count($1) == 0) {
        std::string err_msg = "\"" + $1 + "\" is not defined";
        error(@$, err_msg); 
      }
    }
    if ($1 == curr_struct_name && declarator->ptr_count == 0) {
      std::string err_msg = "Field \"" + name + "\" has incomplete type";
      error(@$, err_msg);
    }
    if ($1 == "void" && declarator->ptr_count == 0) {
      std::string err_msg = "Cannot declare variable of type \"void\"";
      error(@$, err_msg);
    }
    if (variables.count(name) > 0) {
      std::string err_msg = "\"" + name + "\" has a previous declaration";
      error(@$, err_msg);
    }
    else {
      variables[name] = new dataType($1, declarator->ptr_count, declarator->dimensions);
    }
    int width = 1;
    for (auto dim : declarator->dimensions) {
      width *= dim;
    }
    int data_type_width;
    if (declarator->ptr_count > 0) {
      data_type_width = PTR_SIZE;
    }
    else if ($1 == "int") {
      data_type_width = INT_SIZE;
    }
    else if ($1 == "float") {
      data_type_width = FLOAT_SIZE;
    }
    else if ($1 == "void") {
      if (declarator->ptr_count > 0) {
        data_type_width = PTR_SIZE;
      }
    }
    else {
      data_type_width = gst.Entries[$1]->width;
    }
    width *= data_type_width;
    curr_offset -= width;
    std::string type = createType($1, declarator->ptr_count, declarator->dimensions);
    if (curr_struct) {
      $$->symbTabEntries.push_back(make_pair(name, new SymbTabEntry("var", "local", width, -curr_offset-width, type, nullptr)));
    } 
    else {
      $$->symbTabEntries.push_back(make_pair(name, new SymbTabEntry("var", "local", width, curr_offset, type, nullptr)));
    }
  }
}

declaration_list :
declaration
{
	$$ = new declaration_list_class();
  $$->declarations.push_back($1);
  func_declarations = $$;
}
| declaration_list declaration
{
	$$ = $1;
  $$->declarations.push_back($2);
  func_declarations = $$;
}

%%


void IPL::Parser::error( const location_type &l, const std::string &err_message )
{
   std::cout << "Error at line " << l.begin.line << ": " << err_message << "\n";
   exit(1);
}