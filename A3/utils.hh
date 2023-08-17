#ifndef UTILS_H
#define UTILS_H

#include "ast.hh"
#include <string>

std::string to_string(int num);
void backpatch(statement_astnode* stmt, int label);

#endif