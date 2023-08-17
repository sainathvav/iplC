#include <iostream>
#include "ast.hh"

declarator_class::declarator_class() {
    this->ptr_count = 0;
}

parameter_class::parameter_class(std::string name, int width, std::string type) {
    this->name = name;
    this->width = width;
    this->type = type;
}

/* Start statement astnodes */

void empty_astnode::print(int blanks) 
{
    std::cout << "\"empty\"";
}

empty_astnode::empty_astnode() {
    this->isEmpty = 1;
}

// seq_astnode

void seq_astnode :: print(int blanks) 
{
    std::cout << "\"seq\" : [ ";
    int count = 0;
    for (auto statement : this->statements) {
        if (statement->isEmpty) {
            statement->print(0);
        }
        else {
            std::cout << "{ ";
            statement->print(0);
            std::cout << "}";
        }
        count++;
        if (count < this->statements.size()) {
            std::cout << ", ";
        }
        else {
            std::cout << " ";
        }
    }
    std::cout << "]";
}


void assignS_astnode :: print(int blanks)
{
    std::cout << "\"assignS\" : { ";
    std::cout << "\"left\" : { ";
    this->left->print(0);
    std::cout << "}, ";
    std::cout << "\"right\" : { ";
    this->right->print(0);
    std::cout << "} ";
    std::cout << "} ";
}

assignS_astnode :: assignS_astnode(exp_astnode* left, exp_astnode* right)
{
    this->isEmpty = 0;
    this->left = left;
    this->right = right;
}

// return_astnode

void return_astnode :: print(int blanks)
{
    std::cout << "\"return\" : { ";
    this->return_val->print(0);
    std::cout << "}";
}

return_astnode :: return_astnode(exp_astnode* return_val)
{
    this->isEmpty = 0;
    this->return_val =  return_val;
}

// if_astnode

void if_astnode :: print(int blanks)
{
    std::cout << "\"if\" : { ";
    std::cout << "\"cond\" : { ";
    this->cond->print(0);
    std::cout << "}, ";
    if (this->then_st->isEmpty) {
        std::cout << "\"then\" : ";
        this->then_st->print(0);
        std::cout << ", ";
    }
    else {
        std::cout << "\"then\" : { ";
        this->then_st->print(0);
        std::cout << "}, ";
    }
    if (this->else_st->isEmpty) {
        std::cout << "\"else\" :  ";
        this->else_st->print(0);
    }
    else {
        std::cout << "\"else\" : { ";
        this->else_st->print(0);
        std::cout << "} ";
    }
    std::cout << "}";
}

if_astnode :: if_astnode(exp_astnode* cond, statement_astnode* then_st, statement_astnode* else_st)
{
    this->isEmpty = 0;
    this->cond = cond;
    this->then_st = then_st;
    this->else_st = else_st;
    this->stmt_type = "IF";
}


// while_astnode

void while_astnode :: print(int blanks)
{
    std::cout << "\"while\" : { ";
    std::cout << "\"cond\" : { ";
    this->cond->print(0);
    std::cout << "}, ";
    if (this->body->isEmpty) {
        std::cout << "\"stmt\" :  ";
        this->body->print(0);
    }
    else {
        std::cout << "\"stmt\" : { ";
        this->body->print(0);
        std::cout << "} ";
    }
    std::cout << "}";
}

while_astnode :: while_astnode(exp_astnode* cond, statement_astnode* body)
{
    this->isEmpty = 0;
    this->cond = cond;
    this->body = body;
    this->stmt_type = "WHILE";
}

// for_astnode

void for_astnode :: print(int blanks)
{
    std::cout << "\"for\" : { ";
    std::cout << "\"init\" : {";
    this->init->print(0);
    std::cout << "}, ";
    std::cout << "\"guard\" : {";
    this->guard->print(0);
    std::cout << "}, ";
    std::cout << "\"step\" : {";
    this->step->print(0);
    std::cout << "}, ";
    if (this->body->isEmpty) {
        std::cout << "\"body\" : ";
        this->body->print(0);
    }   
    else {
        std::cout << "\"body\" : {";
        this->body->print(0);
        std::cout << "} ";
    }
    std::cout << "}";

}

for_astnode :: for_astnode(exp_astnode* init, exp_astnode* guard, exp_astnode* step, statement_astnode* body)
{
    this->isEmpty = 0;
    this->init = init;
    this->guard = guard;
    this->step = step;
    this->body = body; 
    this->stmt_type = "FOR";
}

// proccall_astnode

void proccall_astnode :: print(int blanks)
{
    std::cout << "\"proccall\" : { ";
    std::cout << "\"fname\" : { \"identifier\" : \"" << this->name << "\" }, ";
    std::cout << "\"params\" : [ ";
    int count = 0;
    for (auto param : this->params) {
        std::cout << "{ ";
        param->print(0);
        std::cout << "}";
        count++;
        if (count < this->params.size()) {
            std::cout << ", ";
        }
        else {
            std::cout << " "; 
        }
    }
    std::cout << "]"; 
    std::cout << " }";
}


proccall_astnode :: proccall_astnode(std::string name)
{
    this->isEmpty = 0;
    this->name = name;
}

proccall_astnode :: proccall_astnode(std::string name, std::vector<exp_astnode*> params)
{
    this->isEmpty = 0;
    this->name = name;
    this->params = params;
}

/* End statement astnodes */

/* Start reference astnodes */

// identifier_astnode

void identifier_astnode :: print(int blanks)
{
    std::cout << "\"identifier\": \"" << this->identifier << "\"" << std::endl;
}

identifier_astnode :: identifier_astnode(std::string identifier)
{
    this->isZero = 0;
    this->identifier = identifier;

    this->isLeaf = 1;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
    this->exp_type = "IDENTIFIER";
}

// member_astnode

void member_astnode :: print(int blanks)
{
    std::cout << "\"member\" : { ";
    std::cout << "\"struct\" : { ";
    this->structure->print(0);
    std::cout << "}, ";
    std::cout << "\"field\" : { ";
    this->member->print(0);
    std::cout << "} ";
    std::cout << "}";
} 

member_astnode :: member_astnode(exp_astnode* structure, identifier_astnode* member)
{
    this->isZero = 0;
    this->structure = structure;
    this->member = member;

    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->addr = new address();
    this->exp_type = "MEM_ACCESS";
}

// arrow_astnode

void arrow_astnode :: print(int blanks)
{
    std::cout << "\"arrow\" : { ";
    std::cout << "\"pointer\" : { ";
    this->pointer->print(0);
    std::cout << "}, ";
    std::cout << "\"field\" : { ";
    this->member->print(0);
    std::cout << "}";
    std::cout << "}";
    //printAst("arrow", "aa", "pointer", this->pointer, "field", this->member);
}

arrow_astnode :: arrow_astnode(exp_astnode* pointer, identifier_astnode* member)
{
    this->isZero = 0;
    this->pointer = pointer;
    this->member = member;

    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
    this->exp_type = "STRUCT_PTR";
}

// arrayref_astnode

void arrayref_astnode :: print(int blanks)
{
    std::cout << "\"arrayref\" : { ";
    std::cout << "\"array\" : { ";
    this->array->print(0);
    std::cout << "}, ";
    std::cout << "\"index\" :  { ";
    this->index->print(0);
    std::cout << "} ";
    std::cout << "}";
    
}

arrayref_astnode :: arrayref_astnode(exp_astnode* array, exp_astnode* index)
{
    this->isZero = 0;
    this->array = array;
    this->index = index;

    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
    this->exp_type = "ARRAY_REF";
}

/* Start expression astnodes */

// op_binary_astnode

void op_binary_astnode :: print(int blanks)
{
    std::cout << "\"op_binary\" : { ";
    std::cout << "\"op\" : \"" << this->op << "\", ";
    std::cout << "\"left\" : { ";
    this->left->print(0);
    std::cout << "}, ";
    std::cout << "\"right\" : { ";
    this->right->print(0);
    std::cout << "} ";
    std::cout << "}";
}

op_binary_astnode :: op_binary_astnode(std::string op, exp_astnode* left, exp_astnode* right)
{
    this->isZero = 0;
    this->op = op;
    this->left = left;
    this->right = right;
    
    /* Setting new attributes */
    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
}

// op_unary_astnode

void op_unary_astnode :: print(int blanks)
{
    std::cout << "\"op_unary\" : { ";
    std::cout << "\"op\" : \"" << this->op << "\", ";
    std::cout << "\"child\" : { ";
    this->child->print(0);
    std::cout << "} ";
    std::cout << "}";
}

op_unary_astnode :: op_unary_astnode(std::string op, exp_astnode* child)
{
    this->isZero = 0;
    this->op = op;
    this->child = child;

    /* Setting new attributes */
    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
}

// assignE_astnode

void assignE_astnode :: print(int blanks)
{
    std::cout << "\"assignE\" : { ";
    std::cout << "\"left\" : { ";
    this->left->print(0);
    std::cout << "}, ";
    std::cout << "\"right\" : { ";
    this->right->print(0);
    std::cout << "} ";
    std::cout << "}";
}

assignE_astnode :: assignE_astnode(exp_astnode* left, exp_astnode* right)
{
    this->isZero = 0;
    this->left = left;
    this->right = right;

    /* Setting new attributes */
    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
}

// funcall_astnode

void funcall_astnode :: print(int blanks)
{
    std::cout << "\"funcall\" : { ";
    std::cout << "\"fname\" : { \"identifier\" : \"" << this->name << "\" }, ";
    std::cout << "\"params\" : [ ";
    int count = 0;
    for (auto param : this->params) {
        std::cout << "{ ";
        param->print(0);
        std::cout << "}";
        count++;
        if (count < this->params.size()) {
            std::cout << ", ";
        }
        else {
            std::cout << " "; 
        }
    }
    std::cout << "]"; 
    std::cout << " }";
}

funcall_astnode :: funcall_astnode(std::string name) 
{   
    this->isZero = 0;
    this->name = name;

    /* Setting new attributes */
    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
    this->exp_type = "FUNCALL";
}

funcall_astnode :: funcall_astnode(std::string name, std::vector<exp_astnode*> params)
{
    this->isZero = 0;
    this->name = name;
    this->params = params;

    /* Setting new attributes */
    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->addr = new address();
    this->exp_type = "FUNCALL";
}

// intconst_astnode

void intconst_astnode :: print(int blanks)
{
    std::cout << "\"intconst\":" << this->val << std::endl;
}

intconst_astnode :: intconst_astnode(int val)
{
    if (val == 0) {
        this->isZero = 1;
    }
    else {
        this->isZero = 0;
    }
    this->val = val;

    /* Setting new attributes */
    this->isLeaf = 1;
    this->label = 0;
    this->isConstant = 1;
    this->value = val;
    this->addr = new address();
    this->exp_type = "INT_CONST";
}

//  floatconst_astnode

void floatconst_astnode :: print(int blanks)
{
    std::cout << "\"floatconst\":" << this->val << std::endl; 
}

floatconst_astnode :: floatconst_astnode(float val)
{
    this->isZero = 0;
    this->val = val;

    /* Setting new attributes */
    this->isLeaf = 1;
    this->label = 0;
    this->isConstant = 1;
    this->value = val;
    this->addr = new address();
    this->exp_type = "FLOAT_CONST";
}

// std::stringconst_astnode

void stringconst_astnode :: print(int blanks)
{
    std::cout << "\"stringconst\":" << this->val << std::endl;
}

stringconst_astnode :: stringconst_astnode(std::string val)
{
    this->isZero = 0;
    this->val = val;

    /* Setting new attributes */
    this->isLeaf = 0;
    this->label = 0;
    this->isConstant = 0;
    this->value = 0;
    this->addr = new address();
}

/* end of expression nodes */