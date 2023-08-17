#ifndef SYMBTAB_H
#define SYMBTAB_H

#include <map>
#include <string>

class SymbTab;

class SymbTabEntry {
    public :
    std::string varfun;
    std::string scope;
    int width;
    int offset;
    std::string type;
    SymbTab* symbtab;
    SymbTabEntry(std::string varfun, std::string scope, int width, int offset, std::string type, SymbTab* symbtab);
};

class SymbTab {
    public :
    std::map<std::string, SymbTabEntry*> Entries; 
    void print();
    void printgst();
};

#endif