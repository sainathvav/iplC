#include <string>
#include <iostream>
#include <vector>
#include <map>
#include <algorithm>
#include "utils.hh"
#include "gencode.hh"

extern std::vector<std::string> instructions;
extern std::vector<std::string> metadata;
extern int instr_count;
extern std::map<std::string, int> local_offsets;
extern std::map<std::string, int> param_offsets;
extern std::map<std::string, std::map<std::string, int> > struct_offsets;
extern int stack_top_offset;
extern int add_to_last_param_offset;

extern std::map<std::string, int> fun_cum_param_size;

extern int curr_offset;

extern int store_true_addr;
extern std::string curr_func_name;

extern SymbTab gst;
extern std::map<std::string, dataType*> fun_types;

extern int cum_param_size;
int load_ptr_value = 1;
int load_arr_value = 1;

int MAXREGS = 6;
extern std::vector<std::string> registers;
int rstack_ptr = 0;
int curr_label = 1;

int load_address_flag = 0;

std::vector<int> rstack_ptrs;
std::vector<int> stack_top_offsets;

int remove_result = 1;

#define ADD_INSTRUCTION instructions.push_back(instruction); instr_count++;

void genCode (exp_astnode* genexp_astnode) {
    std::string exp_type = genexp_astnode->exp_type;
    if (exp_type == "IDENTIFIER") {
        generateIdentifierCode(genexp_astnode);
    }
    else if (exp_type == "INT_CONST") {
        generateIntConstCode(genexp_astnode);
    }
    else if (exp_type == "ADD" || exp_type == "SUB" || exp_type == "MULT") {
        generateArithCode(genexp_astnode);
    }
    else if (exp_type == "DIV") {
        generateDivCode(genexp_astnode);
    }
    else if (exp_type == "LT" || exp_type == "GT" || exp_type == "LTE" || exp_type == "GTE" || exp_type == "EQ" || exp_type == "NEQ") {
        generateRelationalCode(genexp_astnode);
    }
    else if (exp_type == "OR" || exp_type == "AND") {
        generateBoolAsExprCode(genexp_astnode);
    }
    else if (exp_type == "UMINUS") {
        generateUminusCode(genexp_astnode);
    }
    else if (exp_type == "NOT") {
        generateNotCode(genexp_astnode);
    }
    else if (exp_type == "ASSIGN") {
        generateAssignCode(genexp_astnode);
    }
    else if (exp_type == "FUNCALL") {
        generateFuncCallCode(genexp_astnode);
    }
    else if (exp_type == "INC") {
        generateIncCode(genexp_astnode);
    }
    else if (exp_type == "MEM_ACCESS") {
        generateMemAccessCode(genexp_astnode);
    }
    else if (exp_type == "ADDR") {
        generateAddrCode(genexp_astnode);
    }
    else if (exp_type == "DEREF") {
        generateDerefCode(genexp_astnode);
    }
    else if (exp_type == "STRUCT_PTR") {
        generateStructPtrCode(genexp_astnode);
    }
    else if (exp_type == "ARRAY_REF") {
        generateArrayRefCode(genexp_astnode);
    }
}

void generateIdentifierCode (exp_astnode* variable_astnode) {
    std::string instruction;
    int variable_offset = variable_astnode->addr->offset;
    
    /* Don't know if this is correct */
    if (variable_offset > 0) {
        variable_offset += add_to_last_param_offset;
    }
    /**/
    // std::cout << variable_astnode -> name << " " << load_address_flag << std::endl;
    if ((variable_astnode -> dtype -> isArray()  && variable_offset < 0)) {
        instruction = "leal " + to_string(variable_offset) + "(%ebp), " + registers[rstack_ptr];
    }
    else if (variable_offset > 0) {
        instruction = "movl " + to_string(variable_offset) + "(%ebp), " + registers[rstack_ptr];
    }
    else if (load_address_flag) {
        instruction = "leal " + to_string(variable_offset) + "(%ebp), " + registers[rstack_ptr];
    }
    else if (load_address_flag == 0) {
        instruction = "movl " + to_string(variable_offset) + "(%ebp), " + registers[rstack_ptr];   
    }
    ADD_INSTRUCTION

    if (store_true_addr) {
        variable_astnode->addr->reg = "%ebp";
        variable_astnode->addr->offset = variable_offset;
    }
    else {
        variable_astnode->addr->reg = registers[rstack_ptr];
        variable_astnode->addr->offset = 0;
    }
}

void generateIntConstCode (exp_astnode* int_astnode) {
    std::string instruction;
    int value = int_astnode -> value;
    instruction = "movl $" + to_string(value) + ", " + registers[rstack_ptr];
    ADD_INSTRUCTION
}

void generateUminusCode(exp_astnode* uminus_astnode) {
    std::string instruction;
    genCode(uminus_astnode->left);

    instruction = "negl " + registers[rstack_ptr];  ADD_INSTRUCTION
    uminus_astnode->addr->offset = 0;
    uminus_astnode->addr->reg = registers[rstack_ptr];
}

void generateNotCode(exp_astnode* not_astnode) {
    std::string instruction;
    genCode(not_astnode -> left);

    instruction = "cmpl $0, " + registers[rstack_ptr]; ADD_INSTRUCTION

    curr_label++;
    instruction = "jne .L" + to_string(curr_label); ADD_INSTRUCTION

    instruction = "movl $1, " + registers[rstack_ptr]; ADD_INSTRUCTION

    curr_label++;
    instruction = "jmp .L" + to_string(curr_label); ADD_INSTRUCTION

    instruction = ".L" + to_string(curr_label - 1) + ":"; ADD_INSTRUCTION
    instruction = "movl $0, " + registers[rstack_ptr]; ADD_INSTRUCTION

    instruction = ".L" + to_string(curr_label) + ":"; ADD_INSTRUCTION
    not_astnode->addr->offset = 0;
    not_astnode->addr->reg = registers[rstack_ptr];
}

void generateArithCode (exp_astnode* arith_astnode) {
    int N1 = arith_astnode->left->label;      /* Label of the first child */
    int N2 = arith_astnode->right->label;     /* Label of the second child */

    std::string instruction;
    std::string instr_code;
    if (arith_astnode->exp_type == "ADD") {
        instr_code = "addl";
    }
    else if (arith_astnode -> exp_type == "SUB") {
        instr_code = "subl";
    }
    else if (arith_astnode -> exp_type == "MULT") {
        instr_code = "imull";
    }

    if (arith_astnode->right->isLeaf) {
        genCode(arith_astnode->left);

        /* In this case, the right subtree is a leaf meaning that it is a variable */
        int variable_offset = arith_astnode->right->addr->offset;
    
        if (arith_astnode->right->isConstant) {
            if (arith_astnode -> exp_type == "SUB" && arith_astnode -> left -> dtype -> isPointer()) {
                instruction = instr_code + " $" + to_string(4*arith_astnode->right->value) + ", " + registers[rstack_ptr];
            }
            else {
                instruction = instr_code + " $" + to_string(arith_astnode->right->value) + ", " + registers[rstack_ptr];
            }
        }
        else {
            /* Don't know if this is correct */
            if (variable_offset > 0) {
                variable_offset += add_to_last_param_offset;
            }
            /**/
            instruction = instr_code + " " + to_string(variable_offset) + "(%ebp), " + registers[rstack_ptr];
        }
    }
    else if (N1 < N2 && N1 < MAXREGS) {
        std::string temp = registers[rstack_ptr];
        registers[rstack_ptr] = registers[rstack_ptr + 1];
        registers[rstack_ptr+1] = temp;

        genCode(arith_astnode->right);

        if (arith_astnode -> exp_type == "SUB" && arith_astnode -> left -> dtype -> isPointer()) {
            instruction = "imull $4, " + registers[rstack_ptr]; ADD_INSTRUCTION
        }

        rstack_ptr++;

        genCode(arith_astnode->left);
        instruction = instr_code + " " + registers[rstack_ptr - 1] + ", " + registers[rstack_ptr];

        registers[rstack_ptr] = registers[rstack_ptr - 1];
        rstack_ptr--;
        registers[rstack_ptr] = temp;
    }
    else if (N2 <= N1 && N2 < MAXREGS) {
        genCode(arith_astnode -> left);

        rstack_ptr++;
        genCode(arith_astnode -> right);

        if (arith_astnode -> exp_type == "SUB" && arith_astnode -> left -> dtype -> isPointer()) {
            instruction = "imull $4, " + registers[rstack_ptr]; ADD_INSTRUCTION
        }

        instruction = instr_code + " " + registers[rstack_ptr] + ", " + registers[rstack_ptr - 1];

        rstack_ptr--;
    }
    else {
        genCode(arith_astnode->right);
        
        /* Not enough registers. Make space to store the computation in the stack */
        instruction = "subl $4, %esp"; ADD_INSTRUCTION
        stack_top_offset -= 4;

        /* Actually store the computation in the stack */
        instruction = "movl " + registers[rstack_ptr]  + ", " + to_string(stack_top_offset) + "(%ebp)"; ADD_INSTRUCTION

        arith_astnode->right->addr->offset = -stack_top_offset;
        arith_astnode->right->addr->reg = "%ebp";

        genCode(arith_astnode->left);
        if (arith_astnode -> exp_type == "SUB" && arith_astnode -> left -> dtype -> isPointer()) {
            instruction = "popl " + registers[rstack_ptr + 1]; ADD_INSTRUCTION
            instruction = "imull $4, " + registers[rstack_ptr + 1]; ADD_INSTRUCTION
            instruction = instr_code + " " + registers[rstack_ptr + 1] + ", " + registers[rstack_ptr]; ADD_INSTRUCTION
        }
        instruction = instr_code + " " + to_string(arith_astnode->right->addr->offset) + "(%ebp)" + ", " + registers[rstack_ptr]; 

        /* Clearing the space we've used to store the value of the RHS from the top of the stack */
        instruction = "addl $4, %esp";

        stack_top_offset += 4;
    }

    arith_astnode->addr->offset = 0;
    arith_astnode->addr->reg = registers[rstack_ptr];
    ADD_INSTRUCTION
} 

void generateDivCode (exp_astnode* arith_astnode) {
    int N1 = arith_astnode->left->label;      /* Label of the first child */
    int N2 = arith_astnode->right->label;     /* Label of the second child */

    std::string instruction;
    std::string instr_code = "idivl";

    instruction = "pushl %eax"; ADD_INSTRUCTION
    instruction = "pushl %ebx"; ADD_INSTRUCTION
    instruction = "pushl %edx"; ADD_INSTRUCTION

    stack_top_offset -= 12;

    if (arith_astnode->right->isLeaf) {
        genCode(arith_astnode->left);
        
        instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION
        stack_top_offset -= 4;

        /* In this case, the right subtree is a leaf meaning that it is a variable */
        int variable_offset = arith_astnode->right->addr->offset;
    
        if (arith_astnode->right->isConstant) {
            instruction = "movl $" + to_string(arith_astnode->right->value) + ", %ebx"; ADD_INSTRUCTION
        }
        else {
            /* Don't know if this is correct */
            if (variable_offset > 0) {
                variable_offset += add_to_last_param_offset;
            }
            /**/
            instruction = "movl " + to_string(variable_offset) + "(%ebp), %ebx"; ADD_INSTRUCTION
        }

        
        instruction = "popl %eax"; ADD_INSTRUCTION
        stack_top_offset += 4;
        instruction = "cltd"; ADD_INSTRUCTION
        instruction = "idivl %ebx"; ADD_INSTRUCTION
        instruction = "movl %eax, " + registers[rstack_ptr]; ADD_INSTRUCTION

    }
    else if (N1 < N2 && N1 < MAXREGS) {
        std::string temp = registers[rstack_ptr];
        registers[rstack_ptr] = registers[rstack_ptr + 1];
        registers[rstack_ptr + 1] = temp;

        genCode(arith_astnode->right);
        instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION
        stack_top_offset -= 4;
        rstack_ptr++;

        genCode(arith_astnode->left);
        instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION
        stack_top_offset -= 4;

        // instruction = "movl " + registers[rstack_ptr - 1] + ", %ebx"; ADD_INSTRUCTION
        // instruction = "movl " + registers[rstack_ptr] + ", %eax"; ADD_INSTRUCTION

        instruction = "popl %eax"; ADD_INSTRUCTION
        instruction = "cltd"; ADD_INSTRUCTION
        instruction = "popl %ebx"; ADD_INSTRUCTION

        stack_top_offset += 8;

        instruction = "idivl %ebx"; ADD_INSTRUCTION
        instruction = "movl %eax, " + registers[rstack_ptr]; ADD_INSTRUCTION

        registers[rstack_ptr] = registers[rstack_ptr - 1];
        rstack_ptr--;
        registers[rstack_ptr] = temp;
    }
    else if (N2 <= N1 && N2 < MAXREGS) {
        genCode(arith_astnode -> left);
        instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION
        stack_top_offset -= 4;
        rstack_ptr++;
        genCode(arith_astnode -> right);
        instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION
        stack_top_offset -= 4;

        // instruction = "movl " + registers[rstack_ptr] + ", %ebx"; ADD_INSTRUCTION
        // instruction = "movl " + registers[rstack_ptr - 1] + ", %eax"; ADD_INSTRUCTION

        instruction = "popl %ebx"; ADD_INSTRUCTION
        instruction = "popl %eax"; ADD_INSTRUCTION
        stack_top_offset += 8;
        instruction = "cltd"; ADD_INSTRUCTION

        instruction = "idivl %ebx"; ADD_INSTRUCTION
        instruction = "movl %eax, " + registers[rstack_ptr-1]; ADD_INSTRUCTION

        rstack_ptr--;
    }
    else {
        genCode(arith_astnode->right);
        
        /* Actually store the computation in the stack */
        instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION
        stack_top_offset -= 4;

        arith_astnode->right->addr->offset = -stack_top_offset;
        arith_astnode->right->addr->reg = "%ebp";

        genCode(arith_astnode->left);
        instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION
        stack_top_offset -= 4;

        instruction = "popl %eax"; ADD_INSTRUCTION
        instruction = "cltd"; ADD_INSTRUCTION
        instruction = "popl %ebx"; ADD_INSTRUCTION
        stack_top_offset += 8;
        instruction = "idivl %ebx"; ADD_INSTRUCTION
        instruction = "movl %eax, " + registers[rstack_ptr]; ADD_INSTRUCTION
    }
    if (registers[rstack_ptr] == "%edx") {
        instruction = "addl $4, %esp"; ADD_INSTRUCTION
    }
    else {
        instruction = "popl %edx"; ADD_INSTRUCTION
    }
    if (registers[rstack_ptr] == "%ebx") {
        instruction = "addl $4, %esp"; ADD_INSTRUCTION
    }
    else {
        instruction = "popl %ebx"; ADD_INSTRUCTION
    }
    if (registers[rstack_ptr] == "%eax") {
        instruction = "addl $4, %esp"; ADD_INSTRUCTION
    }
    else {
        instruction = "popl %eax"; ADD_INSTRUCTION
    }
    stack_top_offset += 12;
    arith_astnode->addr->offset = 0;
    arith_astnode->addr->reg = registers[rstack_ptr];
} 

void generateRelationalCode(exp_astnode* relexp_astnode) {
    int N1 = relexp_astnode->left->label;      /* Label of the first child */
    int N2 = relexp_astnode->right->label;     /* Label of the second child */

    std::string instruction;
    std::string instr_code;

    std::string exp_type = relexp_astnode->exp_type;
    std::string jump_code;


    if (exp_type == "LT") {
        jump_code = "jge";
    }
    else if (exp_type == "GT") {
        jump_code = "jle";
    }
    else if (exp_type == "LTE") {
        jump_code = "jg";
    }
    else if (exp_type == "GTE") {
        jump_code = "jl";
    }
    else if (exp_type == "EQ") {
        jump_code = "jne";
    }
    else if (exp_type == "NEQ") {
        jump_code = "je";
    }

    if (relexp_astnode->right->isLeaf) {
        genCode(relexp_astnode->left);

        /* In this case, the right subtree is a leaf meaning that it is a variable */
        int variable_offset = relexp_astnode->right->addr->offset;
    
        if (relexp_astnode->right->isConstant) {
            instruction = "cmpl $" + to_string(relexp_astnode->right->value) + ", " + registers[rstack_ptr]; ADD_INSTRUCTION
        }
        else {
            /* Don't know if this is correct */
            if (variable_offset > 0) {
                variable_offset += add_to_last_param_offset;
            }
            /**/
            instruction = "cmpl " + to_string(variable_offset) + "(%ebp), " + registers[rstack_ptr]; ADD_INSTRUCTION
        }
    }
    else if (N1 < N2 && N1 < MAXREGS) {
        std::string temp = registers[rstack_ptr];
        registers[rstack_ptr] = registers[rstack_ptr + 1];
        registers[rstack_ptr] = temp;

        genCode(relexp_astnode->right);
        rstack_ptr++;

        genCode(relexp_astnode->left);
        instruction = "cmpl " + registers[rstack_ptr - 1] + ", " + registers[rstack_ptr]; ADD_INSTRUCTION

        registers[rstack_ptr] = registers[rstack_ptr - 1];
        rstack_ptr--;
        registers[rstack_ptr] = temp;


    }
    else if (N2 <= N1 && N2 < MAXREGS) {
        genCode(relexp_astnode -> left);
        rstack_ptr++;
        genCode(relexp_astnode -> right);
        rstack_ptr--;
        instruction = "cmpl " + registers[rstack_ptr + 1] + ", " + registers[rstack_ptr]; ADD_INSTRUCTION
    }
    else {
        genCode(relexp_astnode->right);
        
        /* Not enough registers. Make space to store the computation in the stack */
        instruction = "subl $4, %esp";  ADD_INSTRUCTION

        stack_top_offset -= 4;

        /* Actually store the computation in the stack */
        instruction = "movl " + registers[rstack_ptr]  + ", " + to_string(stack_top_offset) + "(%ebp)"; ADD_INSTRUCTION

        relexp_astnode->right->addr->offset = -stack_top_offset;
        relexp_astnode->right->addr->reg = "%ebp";

        genCode(relexp_astnode->left);
        instruction = "cmpl " + to_string(relexp_astnode->right->addr->offset) + "(%ebp)" + ", " + registers[rstack_ptr]; ADD_INSTRUCTION

        /* Clearing the space we've used to store the value of the RHS from the top of the stack */
        instruction = "addl $4, %esp"; ADD_INSTRUCTION

        stack_top_offset += 4;
    }

    curr_label++;
    instruction =  jump_code + " .L" + to_string(curr_label); ADD_INSTRUCTION

    instruction = "movl $1, " + registers[rstack_ptr]; ADD_INSTRUCTION

    curr_label++;
    instruction = "jmp .L" + to_string(curr_label); ADD_INSTRUCTION


    instruction = ".L" + to_string(curr_label - 1) + ":"; ADD_INSTRUCTION
    instruction = "movl $0, " + registers[rstack_ptr]; ADD_INSTRUCTION

    instruction = ".L" + to_string(curr_label) + ":"; ADD_INSTRUCTION

    relexp_astnode->addr->offset = 0;
    relexp_astnode->addr->reg = registers[rstack_ptr];
}


void generateAssignCode (exp_astnode* assign_astnode) {
    std::string instruction;
    
    if (assign_astnode -> left -> exp_type == "STRUCT_PTR" || assign_astnode -> left -> exp_type == "DEREF") {
        // store_true_addr = 1;
        load_ptr_value = 0;
        genCode(assign_astnode -> left);
        rstack_ptr++;
        load_ptr_value = 1;
        // store_true_addr = 0;
    }
    if (assign_astnode->left->exp_type == "ARRAY_REF") {
        load_arr_value = 0;
        genCode(assign_astnode->left);
        rstack_ptr++;
        load_arr_value = 1;
    }
    genCode(assign_astnode->right);
    int lhs_offset = assign_astnode->left->addr->offset;
    
    if (lhs_offset > 0 && assign_astnode -> left -> exp_type != "STRUCT_PTR" && assign_astnode -> left -> exp_type != "DEREF") {
        lhs_offset += add_to_last_param_offset;
    }
    if (!assign_astnode->left->dtype->isStruct()) {
        if (assign_astnode -> left ->exp_type == "STRUCT_PTR" || assign_astnode -> left -> exp_type == "DEREF") {
            instruction = "movl "  + registers[rstack_ptr] + ", " + to_string(lhs_offset) + "(" + assign_astnode -> left -> addr -> reg + ")";
            
            // instruction = "movl " + registers[rstack_ptr] + ", (%edi)";  ADD_INSTRUCTION;
            // instruction = "popl %edi";
        }
        else if (assign_astnode -> left -> exp_type == "ARRAY_REF") {
            instruction = "movl " + registers[rstack_ptr] + ", " + to_string(lhs_offset) + + "(" + assign_astnode->left->addr->reg + ")"; 
        }
        else {
            instruction = "movl " + registers[rstack_ptr] + ", " + to_string(lhs_offset) + "(%ebp)"; 
        }
        ADD_INSTRUCTION

        assign_astnode->addr->offset = 0;
        assign_astnode->addr->reg = registers[rstack_ptr];
    }

    // std::cout << assign_astnode->right->exp_type << std::endl;
    if (assign_astnode->left->dtype->isStruct()) {
        std::map<std::string, int>::iterator it;
        std::vector<int> struct_var_offsets;
        for (it = struct_offsets[assign_astnode->left->dtype->type].begin(); it != struct_offsets[assign_astnode->left->dtype->type].end(); ++it) {
            struct_var_offsets.push_back(it->second);
        }
        sort(struct_var_offsets.begin(), struct_var_offsets.end());

        int nvars = struct_var_offsets.size();
        for (int i = 0; i < nvars; i++) {
            int var_offset = struct_var_offsets[i] + assign_astnode->right->addr->offset;
            instructions.push_back("movl " + to_string(var_offset) + "(%ebp), " + registers[rstack_ptr]); instr_count++;
            instructions.push_back("movl " + registers[rstack_ptr] + ", " + to_string(struct_var_offsets[i] + lhs_offset) + "(%ebp)"); instr_count++;
        }
        instruction = "addl $" + to_string(gst.Entries[assign_astnode->left->dtype->type]->width) + ", %esp"; ADD_INSTRUCTION
        stack_top_offset += gst.Entries[assign_astnode->left->dtype->type]->width;

        instruction = "popl %edx"; ADD_INSTRUCTION
        instruction = "popl %ecx"; ADD_INSTRUCTION
        instruction = "popl %eax"; ADD_INSTRUCTION
        stack_top_offset += 12;
    }

    if (assign_astnode -> left -> exp_type == "STRUCT_PTR" || assign_astnode -> left -> exp_type == "DEREF" 
            || assign_astnode -> left -> exp_type == "ARRAY_REF") {
        rstack_ptr--;
    }
}

void generateBoolAsExprCode (exp_astnode* boolean_astnode) {
    int N1 = boolean_astnode->left->label;      /* Label of the first child */
    int N2 = boolean_astnode->right->label;     /* Label of the second child */

    std::string instruction;
    std::string instr_code;

    std::string exp_type = boolean_astnode -> exp_type;
    if (exp_type == "OR") {
        instr_code = "jne";
    }
    else if (exp_type == "AND") {
        instr_code = "je";
    }

    genCode(boolean_astnode -> left);

    if (boolean_astnode -> left -> addr -> offset == 0) {
        instruction = "cmpl $0, " + boolean_astnode -> left -> addr -> reg;
    }
    else {
        instruction = "cmpl $0, " + to_string(boolean_astnode->left->addr->offset) + "(%ebp)";
    }
    ADD_INSTRUCTION
    curr_label++;
    instruction =  instr_code + " .L" + to_string(curr_label); ADD_INSTRUCTION

    int where_to_jump = curr_label;

    genCode(boolean_astnode -> right);

    if (boolean_astnode -> right -> addr -> offset == 0) {
        instruction = "cmpl $0, " + boolean_astnode -> right -> addr -> reg;
    }
    else {
        instruction = "cmpl $0, " + to_string(boolean_astnode->right->addr->offset) + "(%ebp)";
    }
    ADD_INSTRUCTION
    
    instruction = instr_code + " .L" + to_string(where_to_jump); ADD_INSTRUCTION

    if (exp_type == "OR") {
        instruction = "movl $0, " + registers[rstack_ptr];  ADD_INSTRUCTION
    }
    else if (exp_type == "AND") {
        instruction = "movl $1, " + registers[rstack_ptr]; ADD_INSTRUCTION
    }
    curr_label++;
    instruction =  "jmp .L" + to_string(curr_label); ADD_INSTRUCTION

    instruction = ".L" + to_string(where_to_jump) + ":"; ADD_INSTRUCTION
    if (exp_type == "AND") {
        instruction = "movl $0, " + registers[rstack_ptr];  ADD_INSTRUCTION
    }
    else if (exp_type == "OR") {
        instruction = "movl $1, " + registers[rstack_ptr]; ADD_INSTRUCTION
    }

    instruction = ".L" + to_string(curr_label) + ":"; ADD_INSTRUCTION

    boolean_astnode->addr->offset = 0;
    boolean_astnode->addr->reg = registers[rstack_ptr];
}

void generateFuncCallCode(exp_astnode* genexp_astnode) {
    std::string func_name = genexp_astnode -> name;

    /* Return type struct, allocate space for the return value pointer */
    // if (fun_types[func_name]->isStruct()) {
    //     add_to_last_param_offset += gst.Entries[fun_types[func_name]->type]->width;
    // }

    std::string instruction;
    instruction = "pushl %eax"; ADD_INSTRUCTION
    instruction = "pushl %ecx"; ADD_INSTRUCTION
    instruction = "pushl %edx"; ADD_INSTRUCTION
    stack_top_offset -= 12;

    if (fun_types[func_name]->isStruct()) {
        instruction = "subl $" + to_string(gst.Entries[fun_types[func_name]->type]->width) + ", %esp"; ADD_INSTRUCTION
        stack_top_offset -= gst.Entries[fun_types[func_name]->type]->width;
    }
    
    rstack_ptrs.push_back(rstack_ptr);
    stack_top_offsets.push_back(stack_top_offset);

    std::vector<exp_astnode*> func_params = (genexp_astnode->params);

    stack_top_offset = 0;
    rstack_ptr = 0;

    int Cum_param_size = 0;
    // std::map<std::string, SymbTabEntry*>::iterator it;
    // for (it = gst.Entries[func_name]->symbtab->Entries.begin(); it != gst.Entries[func_name]->symbtab->Entries.end(); ++it) {
    //   if (it->second->scope == "param") {
    //     Cum_param_size += it->second->width;
    //   }
    // }
    Cum_param_size = fun_cum_param_size[func_name];
    // std::cout << Cum_param_size << std::endl;
    for (int i = 0; i < func_params.size(); i++) {  
        if (func_params[i]->dtype->isStruct()) {
            std::map<std::string, int>::iterator it;
            std::vector<int> struct_var_offsets;
            for (it = struct_offsets[func_params[i]->dtype->type].begin(); it != struct_offsets[func_params[i]->dtype->type].end(); ++it) {
                struct_var_offsets.push_back(it->second);
            }
            sort(struct_var_offsets.begin(), struct_var_offsets.end());

            int nvars = struct_var_offsets.size();
            for (int j = nvars - 1; j >= 0; j--) {
                int var_offset = struct_var_offsets[j] + func_params[i]->addr->offset;
                instruction = "pushl " + to_string(var_offset) + "(%ebp)"; ADD_INSTRUCTION 
            }
        }
        else {
            genCode(func_params[i]);
            instruction = "pushl " + registers[rstack_ptr]; ADD_INSTRUCTION;
        }
        // stack_top_offset -= 4;
    }


    instruction = "call " + genexp_astnode->name; ADD_INSTRUCTION

    // instruction = "addl $" + to_string(4*func_params.size()) + ", %esp";  ADD_INSTRUCTION
    instruction = "addl $" + to_string(Cum_param_size) + ", %esp";  ADD_INSTRUCTION
    // stack_top_offset += Cum_param_size;


    /* Restoring old values of register stack pointer and top of stack pointer */
    rstack_ptr = rstack_ptrs[rstack_ptrs.size() - 1];
    stack_top_offset = stack_top_offsets[stack_top_offsets.size() - 1];

    if (!fun_types[func_name]->isStruct()) {
        instruction = "movl %eax, " + registers[rstack_ptr]; ADD_INSTRUCTION 
    }

    rstack_ptrs.pop_back();
    stack_top_offsets.pop_back();

    if (!fun_types[func_name]->isStruct()) {
        if (registers[rstack_ptr] == "%edx") {
            instruction = "addl $4, %esp"; ADD_INSTRUCTION
        }
        else {
            instruction = "popl %edx"; ADD_INSTRUCTION
        }
        if (registers[rstack_ptr] == "%ecx") {
            instruction = "addl $4, %esp"; ADD_INSTRUCTION
        }
        else {
            instruction = "popl %ecx"; ADD_INSTRUCTION
        }
        if (registers[rstack_ptr] == "%eax") {
            instruction = "addl $4, %esp"; ADD_INSTRUCTION
        }
        else {
            instruction = "popl %eax"; ADD_INSTRUCTION
        }
        stack_top_offset += 12;

    }
    // else {
    //     instruction = "popl %edx"; ADD_INSTRUCTION
    //     instruction = "popl %ecx"; ADD_INSTRUCTION
    //     instruction = "popl %eax"; ADD_INSTRUCTION
    //     stack_top_offset += 12;

    // }

    if (!fun_types[func_name]->isStruct()) {
        genexp_astnode->addr->offset = 0;
        genexp_astnode->addr->reg = registers[rstack_ptr];
    }
    else {
        genexp_astnode->addr->offset = curr_offset - 12 - gst.Entries[fun_types[func_name]->type]->width;
        genexp_astnode->addr->reg = "%ebp";

    }

}

void generateIncCode (exp_astnode* inc_astnode) {
    std::string instruction;
    store_true_addr = 1;
    genCode(inc_astnode -> left);
    store_true_addr = 0;

    int child_offset = inc_astnode->left->addr->offset;

    instruction = "addl $1, " + registers[rstack_ptr]; ADD_INSTRUCTION
    instruction = "movl " + registers[rstack_ptr] + ", " + to_string(child_offset) + "(%ebp)"; ADD_INSTRUCTION
    instruction = "subl $1, " + registers[rstack_ptr]; ADD_INSTRUCTION

    inc_astnode->addr->offset = 0;
    inc_astnode->addr->reg = registers[rstack_ptr];
}

void generateMemAccessCode(exp_astnode* memaccess_astnode) {
    std::string instruction;
    int variable_offset = memaccess_astnode->addr->offset;

    /* Take note. Commenting this part */
    // if (variable_offset > 0) {
    //     variable_offset += add_to_last_param_offset;
    // }

    // variable_offset += struct_offsets[memaccess_astnode -> dtype -> type][memaccess_astnode->left->name];
    // if (!store_true_addr) {
    if (load_address_flag) {
        int changing_load_arr_val = 0;
        if (load_arr_value == 1) {
            load_arr_value = 0;
            changing_load_arr_val = 1;
        }
        genCode(memaccess_astnode -> left);
        if (changing_load_arr_val) {
            load_arr_value = 1;
        }
        instruction = "addl $" + to_string(variable_offset) + ", " + registers[rstack_ptr]; ADD_INSTRUCTION
        if (load_address_flag == 0) {
            instruction = "movl (" + registers[rstack_ptr] + "), " + registers[rstack_ptr]; ADD_INSTRUCTION
        }
    }   
    else {
        instruction = "movl " + to_string(variable_offset) + "(%ebp), " + registers[rstack_ptr]; ADD_INSTRUCTION
    }
    // }

    if (store_true_addr) {
        memaccess_astnode->addr->reg = "%ebp";
        memaccess_astnode->addr->offset = variable_offset;
    }
    else {
        memaccess_astnode->addr->reg = registers[rstack_ptr];
        memaccess_astnode->addr->offset = 0;
    }
}


void generateAddrCode (exp_astnode* addr_astnode) {
    store_true_addr = 1;
    std::string instruction;
    
    genCode(addr_astnode->left);
    int operand_offset = addr_astnode->left->addr->offset;

    instruction = "leal " + to_string(operand_offset) + "(%ebp), " + registers[rstack_ptr]; ADD_INSTRUCTION

    addr_astnode->addr->reg = "%ebp";
    addr_astnode->addr->offset = operand_offset;
    store_true_addr = 0;
}

void generateDerefCode (exp_astnode* deref_astnode) {
    std::string instruction;

    genCode(deref_astnode->left);

    if (load_ptr_value) {
        instruction = "movl " + to_string(deref_astnode->left->addr->offset) + "(" + deref_astnode->left->addr->reg + "), " + registers[rstack_ptr];
        ADD_INSTRUCTION
    }
    deref_astnode->addr->offset = 0;
    deref_astnode->addr->reg = registers[rstack_ptr];

}

void generateStructPtrCode(exp_astnode* struct_ptr_astnode) {
    std::string instruction;

    genCode(struct_ptr_astnode -> left);

    // std::cout << struct_ptr_astnode -> addr -> offset << std::endl;

    if (store_true_addr) {
        struct_ptr_astnode->addr->reg = "%ebp";
        struct_ptr_astnode->addr->offset = struct_ptr_astnode->left->addr->offset + struct_ptr_astnode->addr->offset;
    }
    else {
        if (load_ptr_value) {
            instruction = "movl " + to_string(struct_ptr_astnode->left->addr->offset + struct_ptr_astnode->addr->offset) + "(" + struct_ptr_astnode->left->addr->reg + "), " + registers[rstack_ptr]; ADD_INSTRUCTION
        }
        struct_ptr_astnode->addr->reg = registers[rstack_ptr];
    }
}


void generateArrayRefCode (exp_astnode* array_ref_astnode) {
    std::string instruction;

    int ch_la_flag = 0;
    if ((array_ref_astnode -> left ->exp_type == "IDENTIFIER" || array_ref_astnode -> left -> exp_type == "MEM_ACCESS" )&& load_address_flag == 0) {
        // std::cout << "Setting " << array_ref_astnode -> left -> name << std::endl;
        ch_la_flag = 1;
        load_address_flag = 1;
    }
    genCode(array_ref_astnode->left);
    if (ch_la_flag) {
        // std::cout << "Unsetting " << array_ref_astnode -> left -> name << std::endl;
        load_address_flag = 0;
    }
    rstack_ptr++;
    int ch_la_flag2 = 0;
    int ch_lav_flag = 0;
    if (load_arr_value == 0) {
        ch_lav_flag = 1;
        load_arr_value = 1;
    }
    if (load_address_flag == 1) {
        ch_la_flag2 = 1;
        load_address_flag = 0;
    }
    genCode(array_ref_astnode->right);
    if (ch_la_flag2 == 1) {
        load_address_flag = 1;
    }
    if (ch_lav_flag) {
        load_arr_value = 0;
    }

    int array_elem_size = array_ref_astnode->dtype->size;
    instruction = "imull $" + to_string(array_elem_size) + ", " + registers[rstack_ptr]; ADD_INSTRUCTION

    instruction = "addl " + registers[rstack_ptr] + ", " + registers[rstack_ptr - 1]; ADD_INSTRUCTION

    if (!(array_ref_astnode -> dtype -> isArray()) && load_arr_value) {
        instruction = "movl (" + registers[rstack_ptr - 1] + "), " + registers[rstack_ptr-1]; ADD_INSTRUCTION 
    }

    rstack_ptr--;
    array_ref_astnode->addr->reg = registers[rstack_ptr];
    array_ref_astnode->addr->offset = 0;
}