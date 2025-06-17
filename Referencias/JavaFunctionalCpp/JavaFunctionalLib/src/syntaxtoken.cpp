#include <iostream>

#include "syntaxtoken.hpp"
#include "token.hpp"



SyntaxToken::SyntaxToken(Token_t token_t, std::string value, size_t pos, unsigned int row, size_t len)
{
	this->token_t = token_t;
	this->pos = pos;
	this->len = len;
	this->value = value;
	this->row = row;
}

Token_t SyntaxToken::GetToken_t()
{
	return this->token_t;
}

std::string SyntaxToken::GetValue()
{
	return this->value;
}

size_t SyntaxToken::GetPos()
{
	return this->pos;
}

size_t SyntaxToken::GetLen()
{
	return this->len;
}

unsigned int SyntaxToken::GetRow()
{
	return this->row;
}