#include <iostream>
#include "symbtab.hh"

SymbTabEntry::SymbTabEntry(std::string varfun, std::string scope, int width, int offset, std::string type, SymbTab* symbtab) {
    this->varfun = varfun;
    this->scope = scope;
    this->width = width;
    this->offset = offset;
    this->type = type;
    this->symbtab = symbtab;
}

void SymbTab::printgst() {
    std::cout << "[" << std::endl;
    for (auto it = this->Entries.begin(); it != this->Entries.end(); it++) {
        std::cout << "[" << std::endl;
        std::cout << "\"" << it->first << "\"," << std::endl;
        std::cout << "\"" << it->second->varfun << "\"," << std::endl;
        std::cout << "\"" << it->second->scope << "\"," << std::endl;
        std::cout << it->second->width << "," << std::endl;
        if (it->second->varfun == "struct") {
            std::cout << "\"-\"," << std::endl;
        }
        else {
            std::cout << it->second->offset << "," << std::endl;
        }
        std::cout << "\"" << it->second->type << "\"" << std::endl;
        std::cout << "]";
        if (next(it, 1) != this->Entries.end()) {
            std::cout << "," << std::endl;
        }
    }
    std::cout << "]" << std::endl;
}

void SymbTab::print() {
    this->printgst();
}