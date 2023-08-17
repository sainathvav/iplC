#ifndef AST_H
#define AST_H

#include "type.hh"
#include "symbtab.hh"
#include <string>

class abstract_astnode {
    public :
    virtual void print(int blanks) = 0;
    // enum typeExp astnode_type;
};

class statement_astnode : public abstract_astnode {
    public :
    int isEmpty;
};

class exp_astnode : public abstract_astnode {
    public :
    exp_astnode* left;
    exp_astnode* right;
    int lval;
    dataType* dtype;
    int isZero;
};

class ref_astnode : public exp_astnode {

};

/* Start expression astnodes */

class op_binary_astnode : public exp_astnode {
    private :
    std::string op;
    // exp_astnode* left;
    // exp_astnode* right;

    public :
    op_binary_astnode(std::string op, exp_astnode* left, exp_astnode* right);
    void print(int blanks);
};

class op_unary_astnode : public exp_astnode {
    private :
    std::string op;
    exp_astnode* child;

    public :
    op_unary_astnode(std::string op, exp_astnode* child);
    void print(int blanks);
};

class assignE_astnode : public exp_astnode {
    private :
    // exp_astnode* left;
    // exp_astnode* right;

    public :
    assignE_astnode(exp_astnode* left, exp_astnode* right);
    void print(int blanks);
};

class funcall_astnode : public exp_astnode {
    private :
    std::string name;
    std::vector<exp_astnode*> params;

    public :
    funcall_astnode(std::string name);
    funcall_astnode(std::string name, std::vector<exp_astnode*> params);
    void print(int blanks);
};

class intconst_astnode : public exp_astnode {
    private :
    int val;

    public :
    intconst_astnode(int val);
    void print(int blanks);
};

class floatconst_astnode : public exp_astnode {
    private :
    float val;

    public :
    floatconst_astnode(float val);
    void print(int blanks);
};

class stringconst_astnode : public exp_astnode {
    private :
    std::string val;

    public :
    stringconst_astnode(std::string val);
    void print(int blanks);
};

/* End of expression astnodes */


/* Start reference astnodes */

class identifier_astnode : public ref_astnode {
    private :
    std::string identifier;

    public :
    identifier_astnode(std::string identifier);
    void print(int blanks);
};

class member_astnode : public ref_astnode {
    private :
    exp_astnode* structure;
    identifier_astnode* member;
    
    public :
    member_astnode(exp_astnode* structure, identifier_astnode* member);
    void print(int blanks);
};

class arrow_astnode : public ref_astnode {
    private :
    exp_astnode* pointer;       //Give better name
    identifier_astnode* member;

    public :
    arrow_astnode(exp_astnode* pointer, identifier_astnode* member);
    void print(int blanks);
};

class arrayref_astnode : public ref_astnode {
    private :
    exp_astnode* array;      //Give better name
    exp_astnode* index;     //Give better name
    
    public :
    arrayref_astnode(exp_astnode* array, exp_astnode* index);
    void print(int blanks);
};

/* End reference astnodes */

/* Start statement astnodes */

class empty_astnode : public statement_astnode {
    public :
    empty_astnode();
    void print(int blanks);
};

class seq_astnode : public statement_astnode {
    public :
    std::vector<statement_astnode*> statements;
    // seq_astnode(std::vector<statement_astnode*> statements);
    void print(int blanks);
};

class assignS_astnode : public statement_astnode {
    private :
    exp_astnode* left;
    exp_astnode* right;

    public :
    assignS_astnode(exp_astnode* left, exp_astnode* right);
    void print(int blanks);
    
};

class return_astnode : public statement_astnode {
    private :
    exp_astnode* return_val;

    public :
    return_astnode(exp_astnode* return_val);
    void print(int blanks);
};

class if_astnode : public statement_astnode {
    private :
    exp_astnode* cond;
    statement_astnode* then_st;
    statement_astnode* else_st;

    public :
    if_astnode(exp_astnode* cond, statement_astnode* then_st, statement_astnode* else_st);
    void print(int blanks);
};

class while_astnode : public statement_astnode {
    private :
    exp_astnode* cond;
    statement_astnode* body;

    public :
    while_astnode(exp_astnode* cond, statement_astnode* body);
    void print(int blanks);
};

class for_astnode : public statement_astnode {
    private :
    exp_astnode* init;
    exp_astnode* guard;
    exp_astnode* step;
    statement_astnode* body;

    public :
    for_astnode(exp_astnode* init, exp_astnode* guard, exp_astnode* step, statement_astnode* body);
    void print(int blanks);
};

class proccall_astnode : public statement_astnode {
    private :
    std::string name;
    std::vector<exp_astnode*> params;

    public :
    proccall_astnode(std::string name);
    proccall_astnode(std::string name, std::vector<exp_astnode*> params);
    void print(int blanks);
};

/* End statement astnodes */

/* Additional classes */

class type_specifier_class {
    public :
    std::string variant;
    std::string type;
    std::string data_type;
};

class declarator_class {
    public :
    std::string identifier_name;
    std::vector<int> dimensions;
    int ptr_count;
    declarator_class();
};

class declarator_list_class {
    public :
    std::vector<declarator_class*> declarators;
};

class declaration_class {
    public :
    std::vector<std::pair<std::string, SymbTabEntry*> > symbTabEntries; // std::string is the name of the declared variable
};

class declaration_list_class {
    public :
    std::vector<declaration_class*> declarations;
};

class parameter_class {
    public :
    std::string name;
    int width;
    std::string type;
    dataType* dtype;
    parameter_class(std::string name, int width, std::string type);
};

class parameter_list_class {
    public :
    std::vector<parameter_class*> parameters;
};

class fun_declarator_class {
    public :
    std::string name;
    std::vector<std::pair<std::string, SymbTabEntry*> > funParamEntries;
    std::vector<dataType*> funParamTypes;
};

#endif