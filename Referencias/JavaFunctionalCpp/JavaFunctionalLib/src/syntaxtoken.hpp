#pragma once
#include <iostream>

#include "token.hpp"

class SyntaxToken
{
public:
	SyntaxToken(Token_t token_t, std::string value, size_t pos, unsigned int row, size_t len);
	Token_t GetToken_t();
	std::string GetValue();
	size_t GetPos();
	unsigned int GetRow();
	size_t GetLen();
private:
	Token_t token_t;
	std::string value;
	size_t pos;
	unsigned int row;
	size_t len;
};

