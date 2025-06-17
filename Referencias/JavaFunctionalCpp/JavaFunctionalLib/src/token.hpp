#pragma once
#include <iostream>

enum Token_t
{
	NUMBER_LITERAL_TOKEN,
	STRING_LITERAL_TOKEN, // something like "hello world" (with "")
	IDENTIFIER_TOKEN,
	FALSE_TOKEN,
	TRUE_TOKEN,

	PLUS_TOKEN,
	MINUS_TOKEN,
	STAR_TOKEN,
	SLASH_TOKEN,

	PLUS_PLUS_TOKEN,
	TRIPLE_PLUS_TOKEN,
	MINUS_MINUS_TOKEN,
	PLUS_EQUAL_TOKEN,
	MINUS_EQUAL_TOKEN,
	STAR_EQUAL_TOKEN,
	SLASH_EQUAL_TOKEN,

	EQUAL_TOKEN,
	BANG_TOKEN,

	EQUAL_EQUAL_TOKEN,
	BANG_EQUAL_TOKEN,
	AMPERSAND_AMPERSAND_TOKEN,
	PIPE_PIPE_TOKEN,

	COMMA_TOKEN,

	OPEN_PAREN,
	CLOSE_PAREN,

	OPEN_CURLY_BRACKET,
	CLOSE_CURLY_BRACKET,

	SEMICOLON_TOKEN,

	//variable types
	BOOL_TYPE,
	SHORT_TYPE,
	INT_TYPE,
	LONG_TYPE,
	FLOAT_TYPE,
	DOUBLE_TYPE,

	//keywords
	PRINT_KW,
	IF_KW,
	RETURN_KW,

	BAD_TOKEN,
	END_OF_FILE_TOKEN
};

std::string TokenName(Token_t token);
std::string DisplayToken(Token_t token);

unsigned short GetUnaryOperatorPrecedence(Token_t unary_op);
unsigned short GetBinaryOperatorPrecedence(Token_t binary_op);