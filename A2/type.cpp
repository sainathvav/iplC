#include "type.hh"
#include <iostream>

dataType::dataType(std::string type, int ptr_count, std::vector<int> dimensions) {
    this->type = type;
    this->ptr_count = ptr_count;
    this->dimensions = dimensions;
}

dataType::dataType(std::string type) {
    this->type = type;
    this->ptr_count = 0;
}

std::string createType(std::string type, int ptr_count, std::vector<int> dimensions) {
    std::string result = type;
    for (int i = 0; i < ptr_count; i++) {
        result += "*";
    }
    for (int i = 0; i < dimensions.size(); i++) {
        result += "[";
        result += std::to_string(dimensions[i]);
        result += "]";
    }
    return result;
}

std::string getStructName(std::string type) {
    int start = 0;
    std::string ans;
    for (int i = 0; i < type.length(); i++) {
        if (start) {
            ans += type[i];
        }
        if (type[i] == ' ') {
            start = 1;
        }
    }
    return ans;
}

int dataType::isInt() {
    if (this->type == "int" && this->ptr_count == 0 && this->dimensions.size() == 0) {
        return 1;
    }
    return 0;
}

int dataType::isFloat() {
    if (this->type == "float" && this->ptr_count == 0 && this->dimensions.size() == 0) {
        return 1;
    }
    return 0;
}

int dataType::isString() {
    if (this->type == "string" && this->ptr_count == 0 && this->dimensions.size() == 0) {
        return 1;
    }
    return 0;
}

int dataType::isPointer() {
    if (this->ptr_count + this->dimensions.size() > 0) {
        return 1;
    }
    return 0;
}

int dataType::isPurePointer() {
    if (this->ptr_count > 0 && this->dimensions.size() == 0) {
        return 1;
    }
    return 0;
}

int dataType::isArray() {
    if (this->dimensions.size() > 0) {
        return 1;
    }
    return 0;
}

int dataType::isStruct() {
    if (this->type != "int" && this->type != "float" && this->type != "void" && this->type != "string") {
        if (this->ptr_count == 0 && this->dimensions.size() == 0) {
            return 1;
        }
    }
    return 0;
}

int dataType::isStructPtr() {
    if (this->type != "int" && this->type != "float" && this->type != "void" && this->type != "string") {
        if (this->ptr_count + this->dimensions.size() == 1) {
            return 1;
        }
    }
    return 0;
}

int dataType::isVoidPtr() {
    if (this->type == "void" && this->ptr_count == 1 && this->dimensions.size() == 0) {
        return 1;
    }
    return 0;
}

int dataType::isArithmeticType() {
    if (this->isStruct() == 0) {
        return 1;
    }
    return 0;
}

int areCompatible(dataType* t1, dataType* t2) {
    // if ((t1->isInt() && t2->isFloat()) || (t1->isFloat() && t2->isInt())) {
    //     return 1;
    // }
    int t1dim = t1->dimensions.size();
    int t2dim = t2->dimensions.size();
    if (t1->ptr_count + t1dim > 0 && t2->ptr_count + t2dim > 0) {
        if (t1->isVoidPtr() || t2->isVoidPtr()) {
            return 1;
        }
    }
    if (t1->type == t2->type) {
        if (t1->ptr_count - t2->ptr_count == 1 && t1dim == 0 && t2dim == 1) {
            return 1;
        }
    }
    if (t1->type == t2->type) {
        if (t1->ptr_count - t2->ptr_count == -1 && t1dim == 1 && t2dim == 0) {
            return 1;
        }
    }
    if (t1->type == t2->type && t1->ptr_count == t2->ptr_count && t1dim == t2dim) {
        for (int i = 1; i < t1dim; i++) {
            if (t1->dimensions[i] != t2->dimensions[i]) {
                return 0;
            }
        }
        return 1;
    }
    return 0;
}

int areStrictlyCompatible(dataType* t1, dataType* t2) {
    // if ((t1->isInt() && t2->isFloat()) || (t1->isFloat() && t2->isInt())) {
    //     return 1;
    // }
    int t1dim = t1->dimensions.size();
    int t2dim = t2->dimensions.size();
    if (t1->type == t2->type) {
        if (t1->ptr_count - t2->ptr_count == 1 && t1dim == 0 && t2dim == 1) {
            return 1;
        }
    }
    if (t1->type == t2->type) {
        if (t1->ptr_count - t2->ptr_count == -1 && t1dim == 1 && t2dim == 0) {
            return 1;
        }
    }
    if (t1->type == t2->type && t1->ptr_count == t2->ptr_count && t1dim == t2dim) {
        for (int i = 1; i < t1dim; i++) {
            if (t1->dimensions[i] != t2->dimensions[i]) {
                return 0;
            }
        }
        return 1;
    }
    return 0;
}

std::string dataType::toString() {
    std::string res = this->type;
    for (int i = 0; i < this->ptr_count; i++) {
        res += "*";
    }
    if (this->dimensions.size() > 0) {
        res += "(*)";
    }
    for (int i = 1; i < this->dimensions.size(); i++) {
        res += "[";
        res += std::to_string(this->dimensions[i]);
        res += "]";
    }
    return res;
}

std::string getOpType(dataType* t1, dataType* t2, std::string basetype) {
    std::string op = basetype + "_";
    if (t1->isInt() && t2->isInt()) {
        op += "INT";
    }
    else if (t1->isFloat() && t2->isInt()) {
        op += "FLOAT";
    }
    else if (t1->isInt() && t2->isFloat()) {
        op += "FLOAT";
    }
    else if (t1->isFloat() && t2->isFloat()) {
        op += "FLOAT";
    }
    else {
        op = "incompatible";
    }
    return op;
}