#ifndef TYPE_H
#define TYPE_H

#define INT_SIZE 4
#define FLOAT_SIZE 4
#define PTR_SIZE 4

#include <string>
#include <vector>

std::string createType(std::string type, int ptr_count, std::vector<int> dimensions);
std::string getStructName(std::string type);

class dataType {
    public :
    std::string type;
    int ptr_count;
    std::vector<int> dimensions;
    dataType(std::string type);
    dataType(std::string type, int ptr_count, std::vector<int> dimensions);
    int isInt();
    int isArray();
    int isPurePointer();
    int isPointer();
    int isFloat();
    int isString();
    int isStruct();
    int isStructPtr();
    int isVoidPtr();
    int isArithmeticType();
    std::string toString();

    int size;
};

int areCompatible(dataType* t1, dataType* t2);
int areStrictlyCompatible(dataType* t1, dataType* t2);
std::string getOpType(dataType* t1, dataType* t2, std::string basetype);

int dtSize(int basesize, dataType* dtype);

#endif