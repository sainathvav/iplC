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
  #include "gencode.hh"
  #include "utils.hh"

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

%printer { std::cerr << $$; }  STRUCT
%printer { std::cerr << $$; }  MAIN
%printer { std::cerr << $$; }  PRINTF
%printer { std::cerr << $$; }  VOID
%printer { std::cerr << $$; }  INT
%printer { std::cerr << $$; }  IF
%printer { std::cerr << $$; }  ELSE
%printer { std::cerr << $$; }  WHILE
%printer { std::cerr << $$; }  FOR
%printer { std::cerr << $$; }  RETURN
%printer { std::cerr << $$; }  IDENTIFIER
%printer { std::cerr << $$; }  CONSTANT_INT
%printer { std::cerr << $$; }  CONSTANT_STR
%printer { std::cerr << $$; }  OP_OR
%printer { std::cerr << $$; }  OP_AND
%printer { std::cerr << $$; }  OP_EQ
%printer { std::cerr << $$; }  OP_NEQ
%printer { std::cerr << $$; }  OP_LT
%printer { std::cerr << $$; }  OP_GT
%printer { std::cerr << $$; }  OP_LTE
%printer { std::cerr << $$; }  OP_GTE
%printer { std::cerr << $$; }  OP_ADD
%printer { std::cerr << $$; }  OP_SUB
%printer { std::cerr << $$; }  OP_MUL
%printer { std::cerr << $$; }  OP_DIV
%printer { std::cerr << $$; }  OP_INC
%printer { std::cerr << $$; }  OP_MEM
%printer { std::cerr << $$; }  OP_PTR
%printer { std::cerr << $$; }  OP_NOT
%printer { std::cerr << $$; }  OP_ADDR
%printer { std::cerr << $$; }  OP_ASSIGN
%printer { std::cerr << $$; }  LCB
%printer { std::cerr << $$; }  RCB
%printer { std::cerr << $$; }  LRB
%printer { std::cerr << $$; }  RRB
%printer { std::cerr << $$; }  LSB
%printer { std::cerr << $$; }  RSB
%printer { std::cerr << $$; }  COMMA
%printer { std::cerr << $$; }  EOS
%printer { std::cerr << $$; }  OTHERS


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
   #include <algorithm>

   #include "scanner.hh"

   extern SymbTab gst, gstfun, gststruct;
   extern std::vector<std::string> instructions;
   extern std::vector<std::string> metadata;
   extern int instr_count;
   extern int stack_top_offset;
   
   extern std::vector<std::string> registers;
   extern int rstack_ptr;
   extern int curr_label;

   int constant_str_count = 0;
   int dup_curr_label;

   int return_label_for_curr_fun = 0;
   int curr_main = 0;

   int add_to_last_param_offset = -4;

   int store_true_addr = 0;
   std::string curr_func_name;

   std::map<std::string, abstract_astnode*> ast;

   int cum_param_size;
   std::map<std::string, int> fun_cum_param_size;

   int curr_offset = 0;
   declaration_list_class* func_declarations = new declaration_list_class();
   std::map<std::string, dataType*> variables;
   std::map<std::string, dataType*> fun_types;
   std::vector<fun_declarator_class*> functions;
   std::map<std::string, std::map<std::string, dataType*> > struct_variables;
   int curr_struct = 0;
   std::string curr_struct_name;
   dataType* curr_dtype;

   /* These are for the current function */
   std::map<std::string, int> local_offsets;
   std::map<std::string, int> param_offsets;

   /* This is for storing the offsets of the members of the struct 
   from the starting address of the structure */
   std::map<std::string, std::map<std::string, int> > struct_offsets;

#undef yylex
#define yylex IPL::Parser::scanner.yylex

}

%define api.value.type variant
%define parse.assert

%start program



%token '\n'
%token <std::string>  STRUCT
%token <std::string>  MAIN
%token <std::string>  PRINTF
%token <std::string>  VOID
%token <std::string>  INT
%token <std::string>  IF
%token <std::string>  ELSE
%token <std::string>  WHILE
%token <std::string>  FOR
%token <std::string>  RETURN
%token <std::string>  IDENTIFIER
%token <std::string>  CONSTANT_INT
%token <std::string>  CONSTANT_STR
%token <std::string>  OP_OR
%token <std::string>  OP_AND
%token <std::string>  OP_EQ
%token <std::string>  OP_NEQ
%token <std::string>  OP_LT
%token <std::string>  OP_GT
%token <std::string>  OP_LTE
%token <std::string>  OP_GTE
%token <std::string>  OP_ADD
%token <std::string>  OP_SUB
%token <std::string>  OP_MUL
%token <std::string>  OP_DIV
%token <std::string>  OP_INC
%token <std::string>  OP_MEM
%token <std::string>  OP_PTR
%token <std::string>  OP_NOT
%token <std::string>  OP_ADDR
%token <std::string>  OP_ASSIGN
%token <std::string>  LCB
%token <std::string>  RCB
%token <std::string>  LRB
%token <std::string>  RRB
%token <std::string>  LSB
%token <std::string>  RSB
%token <std::string>  COMMA
%token <std::string>  EOS
%token <std::string>  OTHERS

%nterm <abstract_astnode*> main_definition
%nterm <abstract_astnode*> translation_unit 
%nterm <abstract_astnode*> struct_specifier 
%nterm <abstract_astnode*> function_definition 
%nterm <std::string> type_specifier 
%nterm <parameter_list_class*> parameter_list 
%nterm <parameter_class*> parameter_declaration
%nterm <declarator_class*> declarator_arr
%nterm <declarator_class*> declarator 
%nterm <abstract_astnode*> compound_statement 
%nterm <seq_astnode*> statement_list 
%nterm <statement_astnode*> statement 
%nterm <exp_astnode*> assignment_expression
%nterm <proccall_astnode*> procedure_call 
%nterm <proccall_astnode*> printf_call
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
%nterm <int> M
%nterm <int> N

%%
program :
main_definition
{

}
| translation_unit main_definition
{

}

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
LCB declaration_list RCB EOS
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

      /* Storing the offsets of the members of the struct w.r.t the 
      base address of the structure */
      struct_offsets["struct " + struct_name][entry.first] = entry.second->offset;
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
  /* Passing array width as 4 */
  if ($2->dimensions.size() > 0) {
    width = 4;
  }
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
| parameter_list COMMA parameter_declaration
{
	$$ = $1;
  $$->parameters.push_back($3);
}

compound_statement :
LCB RCB
{
	$$ = new seq_astnode();
}
| LCB statement_list RCB
{
	$$ = $2;
}
| LCB declaration_list RCB
{
  /* Adding this if for the case when there are no declarations. Just speculating */
  if (curr_offset < 0) {
    instructions.push_back("subl $" + to_string(-curr_offset) + ", %esp");  instr_count++;
    stack_top_offset += curr_offset;

  }
  $$ = new seq_astnode();
}
| LCB declaration_list 
{
  /* Adding this if for the case when there are no declarations. Just speculating */
  if (curr_offset < 0) {
    instructions.push_back("subl $" + to_string(-curr_offset) + ", %esp"); instr_count++;
    stack_top_offset += curr_offset;
  }
}
statement_list RCB
{
	$$ = $4;
}


function_definition :
type_specifier IDENTIFIER LRB RRB
{
  std::string func_name = $2;
  if (gst.Entries.count(func_name) > 0) {
    std::string err_msg = "\"" + func_name + "\" has a previous declaration";
    error(@$, err_msg);
  }
	fun_declarator_class* new_function = new fun_declarator_class();
  new_function->name = $2;
  functions.push_back(new_function);

  curr_dtype = new dataType($1);
  SymbTab* func_symbTab = new SymbTab();
  gst.Entries[func_name] = new SymbTabEntry("fun", "global", 0, 0, $1, func_symbTab);
  fun_types[func_name] = new dataType($1);


  instructions.push_back(".text");
  instructions.push_back(".globl " + func_name);
  instructions.push_back(".type " + func_name + ", @function");
  instructions.push_back(func_name + ":");
  instructions.push_back("pushl	%ebp");
	instructions.push_back("movl %esp, %ebp");
  instructions.push_back("pushl %edi");
  instructions.push_back("pushl %esi");
  instructions.push_back("pushl %ebx");
  stack_top_offset -= 12;

  curr_func_name = $2;


  instr_count += 9;
} 
compound_statement
{
  std::string func_name = $2;
  SymbTab* fun_symbTab = new SymbTab();
  for (auto declaration : func_declarations -> declarations) {
    for (auto paramEntry : declaration -> symbTabEntries) {
      fun_symbTab->Entries[paramEntry.first] = paramEntry.second;
    }
  }
	gst.Entries[func_name] = new SymbTabEntry("fun", "global", 0, 0, $1, fun_symbTab);
  $$ = $6;
  ast[func_name] = $$;
  func_declarations = new declaration_list_class();
  variables.clear();
  local_offsets.clear();
  param_offsets.clear();

  /* Instructions for returning from a function call */
  
  if (return_label_for_curr_fun == 0) {
    curr_label++;
    return_label_for_curr_fun = curr_label;
    for (int i = 0; i < instructions.size(); i++) {
      if (instructions[i][instructions[i].size() - 1] == 'L') {
        instructions[i] += to_string(curr_label);
      }
    }
  }
  instructions.push_back(".L" + to_string(return_label_for_curr_fun) + ":");
  instructions.push_back("popl %ebx");
  instructions.push_back("popl %esi");
  instructions.push_back("popl %edi");
  instructions.push_back("leave");
  instructions.push_back("ret");
  instructions.push_back(".size	" + func_name + ", .-" + func_name);

  stack_top_offset += 12;
  curr_offset = 0;
  return_label_for_curr_fun = 0;

  instr_count += 7;
}
| type_specifier IDENTIFIER LRB parameter_list RRB 
{
  // std::cout << curr_offset << " at beginning " << std::endl;
  curr_offset += 12;
  std::string func_name = $2;
  if (gst.Entries.count(func_name) > 0) {
    std::string err_msg = "\"" + func_name + "\" has a previous declaration";
    error(@$, err_msg);
  }
	fun_declarator_class* new_function = new fun_declarator_class();
  new_function->name = $2;

  curr_dtype = new dataType($1);
  fun_types[func_name] = new dataType($1);

  for (auto parameter : $4->parameters) {
    std::string varfun_str = "var";
    std::string param_str = "param";

    /**/
    int new_offset = curr_offset;
    int new_width;
    if (parameter->dtype->isArray()) {
      new_offset = curr_offset - 4;
      new_width = 4;
    }
    else {
      new_width = parameter->width;
      new_offset = curr_offset - parameter -> width;
    }
    // std::cout << "Hey " << new_offset << std::endl;
    /**/
    new_function->funParamEntries.push_back(make_pair(parameter->name, new SymbTabEntry(varfun_str, param_str, new_width, new_offset, parameter->type, nullptr)));
    new_function->funParamTypes.push_back(parameter -> dtype);
    curr_offset -= parameter->width;

    /* Storing offsets of params from ebp */
    /*******************************************************/
    param_offsets[parameter->name] = curr_offset;
    if (parameter->dtype->isArray()) {
      param_offsets[parameter->name] += (parameter->width - 4);
    }
    cum_param_size += parameter->width;
    if (parameter->dtype->isArray()) {
      cum_param_size -= parameter->width;
      cum_param_size += 4;
    }
  }
  fun_cum_param_size[func_name] = cum_param_size;
  functions.push_back(new_function);
  curr_offset = 0; 

  instructions.push_back(".text");
  instructions.push_back(".globl " + func_name);
  instructions.push_back(".type " + func_name + ", @function");
  instructions.push_back(func_name + ":");
  instructions.push_back("pushl	%ebp");
	instructions.push_back("movl %esp, %ebp");
  instructions.push_back("pushl %edi");
  instructions.push_back("pushl %esi");
  instructions.push_back("pushl %ebx");
  stack_top_offset -= 12;
  
  curr_func_name = $2;

  instr_count += 9;

  // if (fun_types[func_name]->isStruct()) {
  //   add_to_last_param_offset += gst.Entries[$1]->width;
  // }
}
compound_statement 
{
  std::string func_name = $2;
  SymbTab* fun_symbTab = new SymbTab();
  int fun_index;
  for (int i = 0; i < functions.size(); i++) {
    if (functions[i]->name == func_name) {
      fun_index = i;
    }
  }
  for (auto paramEntry : functions[fun_index]->funParamEntries) {
    fun_symbTab->Entries[paramEntry.first] = paramEntry.second;
  }
  for (auto declaration : func_declarations -> declarations) {
    for (auto paramEntry : declaration -> symbTabEntries) {
      fun_symbTab->Entries[paramEntry.first] = paramEntry.second;
    }
  }
	gst.Entries[func_name] = new SymbTabEntry("fun", "global", 0, 0, $1, fun_symbTab);
  $$ = $7;
  ast[func_name] = $$;
  func_declarations = new declaration_list_class();
  variables.clear();
  local_offsets.clear();
  param_offsets.clear();


  if (return_label_for_curr_fun == 0) {
    curr_label++;
    return_label_for_curr_fun = curr_label;
    for (int i = 0; i < instructions.size(); i++) {
      if (instructions[i][instructions[i].size() - 1] == 'L') {
        instructions[i] += to_string(curr_label);
      }
    }
  }
  instructions.push_back(".L" + to_string(return_label_for_curr_fun) + ":");
  instructions.push_back("popl %ebx");
  instructions.push_back("popl %esi");
  instructions.push_back("popl %edi");
  instructions.push_back("leave");
  instructions.push_back("ret");
  instructions.push_back(".size	" + func_name + ", .-" + func_name);

  stack_top_offset += 12;
  cum_param_size = 0;
  instr_count += 7;
  curr_offset = 0;
  return_label_for_curr_fun = 0;

  // if (fun_types[func_name]->isStruct()) {
  //   add_to_last_param_offset -= gst.Entries[$1]->width;
  // }
}

/**
  New additions
**/
main_definition :
INT MAIN LRB RRB
{
  std::string func_name = "main";
  if (gst.Entries.count(func_name) > 0) {
    std::string err_msg = "\"" + func_name + "\" has a previous declaration";
    error(@$, err_msg);
  }
	fun_declarator_class* new_function = new fun_declarator_class();
  new_function->name = "main";
  functions.push_back(new_function);

  curr_dtype = new dataType("int");
  SymbTab* func_symbTab = new SymbTab();
  gst.Entries[func_name] = new SymbTabEntry("fun", "global", 0, 0, $1, func_symbTab);
  fun_types[func_name] = new dataType("int");

  instructions.push_back(".text");
  instructions.push_back(".globl " + func_name);
  instructions.push_back(".type " + func_name + ", @function");
  instructions.push_back(func_name + ":");
  instructions.push_back("pushl %ebp");
	instructions.push_back("movl %esp, %ebp");
  instructions.push_back("pushl %edi");
  instructions.push_back("pushl %esi");
  instructions.push_back("pushl %ebx");
  stack_top_offset -= 12;
  instr_count += 9;

  curr_func_name = "main";

  curr_main = 1;
}
compound_statement
{
  std::string func_name = "main";
  SymbTab* fun_symbTab = new SymbTab();
  for (auto declaration : func_declarations -> declarations) {
    for (auto paramEntry : declaration -> symbTabEntries) {
      fun_symbTab->Entries[paramEntry.first] = paramEntry.second;
    }
  }
	gst.Entries[func_name] = new SymbTabEntry("fun", "global", 0, 0, $1, fun_symbTab);
  $$ = $6;
  ast[func_name] = $$;
  func_declarations = new declaration_list_class();
  variables.clear();
  local_offsets.clear();
  param_offsets.clear();

  instructions.push_back("popl %ebx");
  instructions.push_back("popl %esi");
  instructions.push_back("popl %edi");
  instructions.push_back("leave");
  instructions.push_back("ret");
  instructions.push_back(".size	main, .-main");

  stack_top_offset += 12;
  instr_count += 6;

  curr_offset = 0;
  curr_main = 0;
}

/**
  This is similar to a procedure call
**/
printf_call : PRINTF LRB CONSTANT_STR RRB EOS 
{
  if (constant_str_count == 0) {
    metadata.push_back(".text");
    metadata.push_back(".section .rodata");
  }
  metadata.push_back(".LC" + to_string(constant_str_count) + ":");
  metadata.push_back(".string " + $3);
  
  instructions.push_back("pushl $.LC" + to_string(constant_str_count)); instr_count++; stack_top_offset -= 4;
  instructions.push_back("call printf"); instr_count++;

  constant_str_count++;

  $$ = new proccall_astnode("printf");

  instructions.push_back("addl $4, %esp"); instr_count++;
  stack_top_offset += 4;
}
| PRINTF LRB CONSTANT_STR COMMA expression_list RRB EOS 
{
  if (constant_str_count == 0) {
    metadata.push_back(".text");
    metadata.push_back(".section .rodata");
  }
  metadata.push_back(".LC" + to_string(constant_str_count) + ":");
  metadata.push_back(".string " + $3);

  std::vector<exp_astnode*> parameters = *($5);
  int num_param = $5->size();
  for (int i = num_param - 1; i >= 0; i--) {
    genCode(parameters[i]);
    instructions.push_back("pushl " + registers[rstack_ptr]); instr_count++;
    stack_top_offset -= 4;
  }
  instructions.push_back("pushl $.LC" + to_string(constant_str_count)); instr_count++; stack_top_offset -=4;
  instructions.push_back("call printf"); instr_count++;
  instructions.push_back("addl $" + to_string((num_param+1)*4) + ", %esp"); instr_count++;
  stack_top_offset += (num_param+1)*4;
  constant_str_count++;

  $$ = new proccall_astnode("printf", parameters);
}

/**
  End of new additions
**/

statement_list :
statement
{
  $$ = new seq_astnode();
  $$->statements.push_back($1);
  $$->next = $1->next;
}
| statement_list
{
  if ($1->next.size() > 0) {
    curr_label++;
    instructions.push_back(".L" + to_string(curr_label) + ":"); instr_count++;
    backpatch($1, curr_label);
  }
}
statement
{
	$$ = $1;
  $$->statements.push_back($3);

  $$->next = $3->next;
}


statement :
EOS
{
	$$ = new empty_astnode();
}
| LCB statement_list RCB
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
| assignment_expression EOS
{
	$$ = new assignS_astnode($1 -> left, $1 -> right);
  genCode($1);
}
| procedure_call
{
	$$ = $1;
}
| printf_call
{
  $$ = $1;
}
| RETURN expression EOS
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

  genCode($2);
  if (!curr_dtype->isStruct()) {
    instructions.push_back("movl " + registers[rstack_ptr] + ", %eax"); instr_count++;
  }
  else {
    std::map<std::string, int>::iterator it;
    std::vector<int> struct_var_offsets;
    for (it = struct_offsets[curr_dtype->type].begin(); it != struct_offsets[curr_dtype->type].end(); ++it) {
      struct_var_offsets.push_back(it->second);
    }
    sort(struct_var_offsets.begin(), struct_var_offsets.end());
    int nvars = struct_var_offsets.size();
    for (int i = 0; i < nvars; i++) {
      int var_offset = struct_var_offsets[i] + $2->addr->offset;
      instructions.push_back("movl " + to_string(var_offset) + "(%ebp), " + registers[rstack_ptr]); instr_count++;
      instructions.push_back("movl " + registers[rstack_ptr] + ", " + to_string(struct_var_offsets[i] + cum_param_size) + "(%ebp)"); instr_count++;
    }
  }

  if (curr_main == 0) {
    if (return_label_for_curr_fun == 0) {
      curr_label++;
      return_label_for_curr_fun = curr_label;
    }
    instructions.push_back("jmp .L" + to_string(return_label_for_curr_fun)); instr_count++;
  }
}


assignment_expression :
unary_expression OP_ASSIGN expression
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
  $$->exp_type = "ASSIGN";
}



procedure_call :
IDENTIFIER LRB RRB EOS
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
  genCode(new funcall_astnode($1));
}
| IDENTIFIER LRB expression_list RRB EOS
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
  genCode(new funcall_astnode($1, ast_params));
}


expression :
logical_and_expression
{
  $$ = $1;
}
| expression OP_OR logical_and_expression
{
  if (!($1->dtype->isArithmeticType() && $3->dtype->isArithmeticType())) {
    std::string err_msg = "Invalid operand types for binary &&, \"" + $1->dtype->toString() + "\" and \"" + $3->dtype->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode("OR_OP", $1, $3);
  $$->exp_type = "OR";
  $$->dtype = new dataType("int");
  $$->lval = 0;
}


logical_and_expression :
equality_expression
{
	$$ = $1;
}
| logical_and_expression OP_AND equality_expression
{
  if (!($1->dtype->isArithmeticType() && $3->dtype->isArithmeticType())) {
    std::string err_msg = "Invalid operand types for binary &&, \"" + $1->dtype->toString() + "\" and \"" + $3->dtype->toString() + "\"";
    error(@$, err_msg);
  }
	$$ = new op_binary_astnode("AND_OP", $1, $3);
  $$->exp_type = "AND";
  $$->dtype = new dataType("int");
  $$->lval = 0;
}


equality_expression :
relational_expression
{
  $$ = $1;
}
| equality_expression OP_EQ relational_expression
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
  $$->exp_type = "EQ";
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}
| equality_expression OP_NEQ relational_expression
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
  $$->exp_type = "NEQ";
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}


relational_expression :
additive_expression
{
	$$ = $1;
}
| relational_expression OP_LT additive_expression
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
  $$->exp_type = "LT";
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}
| relational_expression OP_GT additive_expression
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
  $$->exp_type = "GT";
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}
| relational_expression OP_LTE additive_expression
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
  $$->exp_type = "LTE";
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}
| relational_expression OP_GTE additive_expression
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
  $$->exp_type = "GTE";
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}


additive_expression :
multiplicative_expression
{
	$$ = $1;
}
| additive_expression OP_ADD multiplicative_expression
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
  $$->exp_type = "ADD";
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
    $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}
| additive_expression OP_SUB multiplicative_expression
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
  $$->exp_type = "SUB";
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}


unary_operator :
OP_SUB
{
	$$ = "UMINUS";
}
| OP_NOT
{
  $$ = "NOT";
}
| OP_ADDR
{
	$$ = "ADDRESS";
}
| OP_MUL
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

  if ($1 == "UMINUS") {
    if ($2->isLeaf) {
      $2->label = 1;
    }
    $$->label = $2->label;
    $$->exp_type = "UMINUS";

    $$->left = $2;
  }
  else if ($1 == "NOT") {
    if ($2->isLeaf) {
      $2->label = 1;
    }
    $$->label = $2->label;
    $$->exp_type = "NOT";

    $$->left = $2;
  }
  else if ($1 == "ADDRESS") {
    $$->label = 1;
    $$->exp_type = "ADDR";
    $$->left = $2;
  }
  else if ($1 == "DEREF") {
    $$->label = 1;
    $$->exp_type = "DEREF";
    $$->left = $2;
  }
}


multiplicative_expression :
unary_expression
{
	$$ = $1;
}
| multiplicative_expression OP_MUL unary_expression
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
  $$->exp_type = "MULT"; 
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}
| multiplicative_expression OP_DIV unary_expression
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
  $$->exp_type = "DIV";
  $$->dtype = result_dtype;
  $$->lval = 0;

  /* Assigning labels for nodes */
  if ($1->isLeaf && $3->isLeaf) { /* Both subtrees are leaves */
      $1->label = 1; $3->label = 0; $$->label = 1;
  }
  else if ($1->isLeaf) {    /* Left subtree is a leaf */
    $1->label = 0; $$->label = $3->label;
  }
  else if ($3->isLeaf) {    /* Right subtree is a leaf */
    $3->label = 0; $$->label = $1->label;
  }
  else {      /* Both are not leaves */
    if ($1->label > $3->label) {
      $$->label = $1->label;
    }
    else if ($3->label > $1->label) {
      $$->label = $3->label;
    }
    else {
      $$->label = $1->label + 1;
    }
  }
}


postfix_expression :
primary_expression
{
	$$ = $1;
}
| postfix_expression LSB expression RSB
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


  $$->exp_type = "ARRAY_REF";
  $$->left = $1;
  $$->right = $3;
  $$->label = 7;      /* Giving very high priority to array reference operations */

  int basesize;
  if ($$->dtype->type == "int") {
    basesize = 4;
  }
  else { /* Struct type */
    basesize = gst.Entries[$$->dtype->type]->width;
  }
  $$->dtype->size = dtSize(basesize, $$->dtype);
  // std::cout << $$->dtype->size << std::endl;

}
| IDENTIFIER LRB RRB
{
  if ($1 != "printf" && $1 != "scanf") {
    /* The below part is a valid part from assignment 2. Adding the code below to handle recursive functions */

    // if ( (gst.Entries.count($1) == 0) || (gst.Entries.count($1) > 0 && gst.Entries[$1]->varfun != "fun") ) {
    //   std::string err_msg = "Function \"" + $1 + "\" not declared";
    //   error(@$, err_msg);
    // }

    /* The above part is a valid part from assignment 2. Adding the code below to handle recursive functions */

    int found = 0;
    for (int i = 0; i < functions.size(); i++) {
      if (functions[i] -> name == $1) {
        found = 1;
        break;
      }
    }

    if (!found) {
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
| IDENTIFIER LRB expression_list RRB
{
  std::vector<exp_astnode*> ast_params;
  if ($1 != "printf" && $1 != "scanf") {
    // if ( (gst.Entries.count($1) == 0) || (gst.Entries.count($1) > 0 && gst.Entries[$1]->varfun != "fun") ) {
    //   std::string err_msg = "Function \"" + $1 + "\" not declared";
    //   error(@$, err_msg);
    // }

    int found = 0;
    for (int i = 0; i < functions.size(); i++) {
      if (functions[i] -> name == $1) {
        found = 1;
        break;
      }
    }

    if (!found) {
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
| postfix_expression OP_MEM IDENTIFIER
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

  $$->left = $1;    // Need this for getting the base address of the structure
  $$->name = $3;    // Need this for getting the offset

  $$->addr->offset = $1->addr->offset + struct_offsets[struct_name][$3];
  $$->addr->reg = $1->addr->reg;
  
}
| postfix_expression OP_PTR IDENTIFIER
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

  $$->addr->offset = struct_offsets[struct_name][$3];
  // std::cout << struct_name << " " << $3 << " " << $$->addr->offset << std::endl;
  $$->left = $1;
  $$->exp_type = "STRUCT_PTR";
  $$->label = 1;
}
| postfix_expression OP_INC
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

  $$->exp_type = "INC";
  $$->label = $1->label;
  $$->left = $1;
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

  $$->addr->reg = "%ebp";
  if (local_offsets.count($1) > 0) {
    $$->addr->offset = local_offsets[$1];
  }
  else {
    $$->addr->offset = param_offsets[$1];
  }
  $$->array_offset = $$->addr->offset;
  $$->name = $1;
}
| CONSTANT_INT
{
	$$ = new intconst_astnode(stoi($1));
  $$->lval = 0;
  $$->dtype = new dataType("int");
}
| LRB expression RRB
{
	$$ = $2;
}


expression_list :
expression
{
	$$ = new std::vector<exp_astnode*>;
  $$->push_back($1);
}
| expression_list COMMA expression
{
  $$ = $1;
  $$->push_back($3);
}

M :
{
  $$ = instr_count;
}

N :
{
  curr_label++;
  instructions.push_back(".L" + to_string(curr_label) + ":"); instr_count++;
  $$ = curr_label;
}

selection_statement :
IF LRB expression RRB
{
  genCode($3);

  instructions.push_back("cmpl $0, " + registers[rstack_ptr]); instr_count++;
  instructions.push_back("je .L"); instr_count++;
}
M statement
{
  instructions[$6-1] += to_string(curr_label + 1);
  instructions.push_back("jmp .L"); instr_count++;
} 
M ELSE N statement
{
  if ($3->dtype->isStruct()) {
    std::string err_msg = "Used struct type where scalar is required";
    error(@$, err_msg);
  }
  $$ = new if_astnode($3, $7, $12);
  $$->next.push_back($9);
  for (int i = 0; i < $7->next.size(); i++) {
    $$->next.push_back($7->next[i]);
  }
  for (int i = 0; i < $12->next.size(); i++) {
    $$->next.push_back($12->next[i]);
  }
}


iteration_statement :
WHILE N LRB expression 
{
  genCode($4);
  instructions.push_back("cmpl $0, " + registers[rstack_ptr]); instr_count++;
  instructions.push_back("je .L"); instr_count++;
}
M RRB statement
{
  if ($4->dtype->isStruct()) {
    std::string err_msg = "Used struct type where scalar is required";
    error(@$, err_msg);
  }
  $$ = new while_astnode($4, $8);
  $$->next.push_back($6);
  backpatch($8, $2);

  instructions.push_back("jmp .L" + to_string($2)); instr_count++;
}
| FOR LRB assignment_expression EOS 
{
  genCode($3);
} 
N expression EOS 
{
  genCode($7);
  instructions.push_back("cmpl $0, " + registers[rstack_ptr]); instr_count++;
  instructions.push_back("je .L"); instr_count++;
} 
M 
{
  instructions.push_back("cmpl $0, " + registers[rstack_ptr]); instr_count++;
  instructions.push_back("jne .L"); instr_count++; 
}
M assignment_expression RRB 
{
  instructions[$12-1] += to_string(curr_label + 1);
}
N statement
{
  if ($7->dtype->isStruct()) {
    std::string err_msg = "Used struct type where scalar is required";
    error(@$, err_msg);
  }
  curr_label++;
  instructions.push_back(".L" + to_string(curr_label) + ":"); instr_count++;
  dup_curr_label = curr_label;
  genCode($13);
  backpatch($17, dup_curr_label);
  instructions.push_back("jmp .L" + to_string($6)); instr_count++;
	$$ = new for_astnode($3, $7, $13, $17);

  $$->next.push_back($10);
}


declarator_arr :
IDENTIFIER
{
	$$ = new declarator_class();
  $$->identifier_name = $1;
}
| declarator_arr LSB CONSTANT_INT RSB
{
	$$ = $1;
  $$->dimensions.push_back(stoi($3));
}


declarator :
declarator_arr
{
	$$ = $1;
}
| OP_MUL declarator
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
| declarator_list COMMA declarator
{
	$$ = $1;
  $$->declarators.push_back($3);
}

declaration :
type_specifier declarator_list EOS
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
      
      /* Storing the offsets of locals from ebp */
      local_offsets[name] = curr_offset;
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