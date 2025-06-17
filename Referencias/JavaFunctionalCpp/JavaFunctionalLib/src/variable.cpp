#include "variable.hpp"

DataType FromToken_tToDataType(Token_t token)
{
    switch (token)
    {
        case BOOL_TYPE:
            return DT_BOOL;
        case SHORT_TYPE:
            return DT_SHORT;
        case INT_TYPE:
            return DT_INT;
        case LONG_TYPE:
            return DT_LONG;
        case FLOAT_TYPE:
            return DT_FLOAT;
        case DOUBLE_TYPE:
            return DT_DOUBLE;
    }

    return DT_NOT_VALID;
}