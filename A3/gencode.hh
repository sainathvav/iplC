#ifndef GENCODE_H
#define GENCODE_H

#include "ast.hh"

void genCode (exp_astnode* generic_exp_astnode);

void generateIdentifierCode (exp_astnode* variable_astnode);

void generateIntConstCode (exp_astnode* int_astnode);

void generateUminusCode (exp_astnode* uminus_astnode);

void generateNotCode(exp_astnode* not_astnode);

void generateArithCode (exp_astnode* arith_astnode);

void generateDivCode (exp_astnode* arith_astnode);

void generateRelationalCode (exp_astnode* relexp_astnode);

void generateAssignCode (exp_astnode* assign_astnode);

void generateBoolAsExprCode (exp_astnode* boolean_astnode);

void generateFuncCallCode(exp_astnode* genexp_astnode);

void generateIncCode (exp_astnode* inc_astnode);

void generateMemAccessCode(exp_astnode* memaccess_astnode);

void generateAddrCode (exp_astnode* addr_astnode);

void generateDerefCode (exp_astnode* deref_astnode);

void generateStructPtrCode(exp_astnode* struct_ptr_astnode);

void generateArrayRefCode (exp_astnode* array_ref_astnode);

#endif