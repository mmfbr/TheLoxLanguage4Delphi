#include <iostream>

#include "token.hpp"

std::string TokenName(Token_t token)
{
	switch (token)
	{
		case NUMBER_LITERAL_TOKEN:
			return "Number Token";
		case STRING_LITERAL_TOKEN:
			return "String Token";

		case PLUS_TOKEN:
			return "Plus Token";
		case MINUS_TOKEN:
			return "Minus Token";
		case STAR_TOKEN:
			return "Star Token";
		case SLASH_TOKEN:
			return "Slash Token";

		case EQUAL_TOKEN:
			return "Equal Token";
		case EQUAL_EQUAL_TOKEN:
			return "Equal Equal Token";


		case SEMICOLON_TOKEN:
			return "Semicolon Token";

		case BAD_TOKEN:
			return "Bad Token";
		case END_OF_FILE_TOKEN:
			return "End Of File Token";
		default:
			return "Invalid Token";
	}
	return "Invalid Token";
}

std::string DisplayToken(Token_t token)
{
	switch (token)
	{
		case BOOL_TYPE:
			return "bool";
		case SHORT_TYPE:
			return "short";
		case INT_TYPE:
			return "int";
		case LONG_TYPE:
			return "long";
		case FLOAT_TYPE:
			return "float";
		case DOUBLE_TYPE:
			return "double";

		case EQUAL_TOKEN:
			return "=";
		case BANG_TOKEN:
			return "!";

		case EQUAL_EQUAL_TOKEN:
			return "==";
		case BANG_EQUAL_TOKEN:
			return "!=";
		case AMPERSAND_AMPERSAND_TOKEN:
			return "&&";
		case PIPE_PIPE_TOKEN:
			return "||";

		case SEMICOLON_TOKEN:
			return ";";

		case PRINT_KW:
			return "print";

		case FALSE_TOKEN:
			return "false";
		case TRUE_TOKEN:
			return "true";

		case IF_KW:
			return "if";
		case RETURN_KW:
			return "return";
	}
	return TokenName(token) + " not found";
}

unsigned short GetUnaryOperatorPrecedence(Token_t unary_op)
{
	switch (unary_op)
	{
		case PLUS_TOKEN:
		case MINUS_TOKEN:
			return 1;
	}
	return 0;
}

unsigned short GetBinaryOperatorPrecedence(Token_t binary_op)
{
	switch (binary_op)
	{
		case EQUAL_EQUAL_TOKEN:
		case BANG_EQUAL_TOKEN:
		case AMPERSAND_AMPERSAND_TOKEN:
		case PIPE_PIPE_TOKEN:
			return 2;

		case STAR_TOKEN:
		case SLASH_TOKEN:
			return 4;

		case PLUS_TOKEN:
		case MINUS_TOKEN:
			return 6;
	}
	return 0;
}