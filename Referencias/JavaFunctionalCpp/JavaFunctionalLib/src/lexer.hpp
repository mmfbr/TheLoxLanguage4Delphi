#pragma once
#include <iostream>
#include <map>
#include <vector>
#include "syntaxtoken.hpp"

class LexerTest;

class Lexer {
public:
	Lexer(std::string program);
	std::vector<SyntaxToken> LexAll();
	SyntaxToken Lex();
private:
	char Current();
	char PeekNext();
	char LookAhead(int offset);
	void advance();
	int index = 0;
	std::string program;

	unsigned int row = 0;
};


