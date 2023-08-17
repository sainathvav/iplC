#include "utils.hh"

extern std::vector<std::string> instructions;

std::string to_string (int num) {
    if (num == 0) {
        return "0";
    }
    std::string result;
    int flag = 0;
    if (num < 0) {
        flag = 1;
        num = -num;
    }
    while (num > 0) {
        char dig = '0' + num%10;
        num /= 10;
        result = dig + result;
    }
    if (flag) {
        result = "-" + result;
    }
    return result;
}

void backpatch(statement_astnode* stmt, int label) {
    for (int i = 0; i < stmt->next.size(); i++) {
        instructions[stmt->next[i] - 1] += to_string(label);
    }
}