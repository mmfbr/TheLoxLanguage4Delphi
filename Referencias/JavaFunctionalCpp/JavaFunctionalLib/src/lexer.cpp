

#include "lexer.hpp"
#include "syntaxtoken.hpp"
#include <iostream>
#include <map>

Lexer::Lexer(std::string program)
{
	this->program = program;
}

char Lexer::Current()
{
	return LookAhead(0);
}

char Lexer::PeekNext()
{
	return LookAhead(1);
}

char Lexer::LookAhead(int offset)
{
	size_t size = this->program.size();
	size_t index = this->index + offset;
	if (index >= size)
	{
		return '\0';
	}
	return program[index];
}

void Lexer::advance()
{
	size_t size = this->program.size();
	if (this->index < size)
	{
		this->index++;
	}
}

std::vector<SyntaxToken> Lexer::LexAll()
{
	std::vector<SyntaxToken> tokens;
	//temp 'token' will be overwritten.
	SyntaxToken token = SyntaxToken::SyntaxToken(END_OF_FILE_TOKEN, "", 0, 0, 0);
	while (token.GetToken_t() != BAD_TOKEN)
	{
		token = Lex();
		if (token.GetToken_t() == END_OF_FILE_TOKEN)
		{
			tokens.push_back(token); // pushing END_OF_FILE_TOKEN
			break;
		}
		tokens.push_back(token);
	}
	return tokens;
}

SyntaxToken Lexer::Lex()
{
	if (Current() == '\0')
	{
		return SyntaxToken(END_OF_FILE_TOKEN, "", this->index, 0, this->row);
	}
	while (Current() == '\n')
	{
		this->row++;
		advance();
	}
	while (isspace(Current()))
	{
		advance();
	}
	if (isdigit(Current()))
	{
		size_t start = this->index;
		while (isdigit(Current()))
		{
			advance();
		}
		if (Current() == '.')
		{
			advance();
			while (isdigit(Current()))
			{
				advance();
			}
		}
		size_t length = this->index - start;
		std::string text = this->program.substr(start, length);
		return SyntaxToken(NUMBER_LITERAL_TOKEN, text, start, this->row, length);
	}
	if (isalpha(Current()) || Current() == '_')
	{
		size_t start = this->index;
		while (Current() == '_' || isalpha(Current()))
		{
			advance();
			while (isdigit(Current()))
			{
				advance();
			}
		}
		size_t length = this->index - start;
		std::string text = this->program.substr(start, length);
		if (text == DisplayToken(PRINT_KW))
		{
			return SyntaxToken(PRINT_KW, DisplayToken(PRINT_KW), start, this->row, length);
		}
		if (text == DisplayToken(FALSE_TOKEN))
		{
			return SyntaxToken(FALSE_TOKEN, DisplayToken(FALSE_TOKEN), start, this->row, length);
		}
		if (text == DisplayToken(TRUE_TOKEN))
		{
			return SyntaxToken(TRUE_TOKEN, DisplayToken(TRUE_TOKEN), start, this->row, length);
		}

		if (text == DisplayToken(BOOL_TYPE))
		{
			return SyntaxToken(BOOL_TYPE, DisplayToken(BOOL_TYPE), start, this->row, length);
		}
		if (text == DisplayToken(SHORT_TYPE))
		{
			return SyntaxToken(SHORT_TYPE, DisplayToken(SHORT_TYPE), start, this->row, length);
		}
		if (text == DisplayToken(INT_TYPE))
		{
			return SyntaxToken(INT_TYPE, DisplayToken(INT_TYPE), start, this->row, length);
		}
		if (text == DisplayToken(LONG_TYPE))
		{
			return SyntaxToken(LONG_TYPE, DisplayToken(LONG_TYPE), start, this->row, length);
		}
		if (text == DisplayToken(FLOAT_TYPE))
		{
			return SyntaxToken(FLOAT_TYPE, DisplayToken(FLOAT_TYPE), start, this->row, length);
		}
		if (text == DisplayToken(DOUBLE_TYPE))
		{
			return SyntaxToken(DOUBLE_TYPE, DisplayToken(DOUBLE_TYPE), start, this->row, length);
		}

		if (text == DisplayToken(IF_KW))
		{
			return SyntaxToken(IF_KW, DisplayToken(IF_KW), start, this->row, length);
		}
		if (text == DisplayToken(RETURN_KW))
		{
			return SyntaxToken(RETURN_KW, DisplayToken(RETURN_KW), start, this->row, length);
		}

		return SyntaxToken(IDENTIFIER_TOKEN, text, start, this->row, length);
	}

	switch (Current())
	{
	case '+':
		if (PeekNext() == '+' && LookAhead(2) == '+')
		{
			this->index += 3;
			return SyntaxToken(TRIPLE_PLUS_TOKEN, "+++", this->index - 3, this->row, 3);
		}
		if (PeekNext() == '+')
		{
			this->index += 2;
			return SyntaxToken(PLUS_PLUS_TOKEN, "++", this->index - 2, this->row, 2);
		}
		if (PeekNext() == '=')
		{
			this->index += 2;
			return SyntaxToken(PLUS_EQUAL_TOKEN, "+=", this->index - 2, this->row, 2);
		}
		return SyntaxToken(PLUS_TOKEN, "+", this->index++, this->row, 1);
	case '-':
		if (PeekNext() == '-')
		{
			this->index += 2;
			return SyntaxToken(MINUS_MINUS_TOKEN, "--", this->index - 2, this->row, 2);
		}
		if (PeekNext() == '=')
		{
			this->index += 2;
			return SyntaxToken(MINUS_EQUAL_TOKEN, "-=", this->index - 2, this->row, 2);
		}
		return SyntaxToken(MINUS_TOKEN, "-", this->index++, this->row, 1);
	case '*':
		if (PeekNext() == '=')
		{
			this->index += 2;
			return SyntaxToken(STAR_EQUAL_TOKEN, "*=", this->index - 2, this->row, 2);
		}
		return SyntaxToken(STAR_TOKEN, "*", this->index++, this->row, 1);
	case '/':
		if (PeekNext() == '=')
		{
			this->index += 2;
			return SyntaxToken(SLASH_EQUAL_TOKEN, "/=", this->index - 2, this->row, 2);
		}
		if (PeekNext() == '*')
		{
			advance();
			advance();

			while (Current() != '*' || PeekNext() != '/')
			{
				advance();
			}
			advance();
			advance();
			return Lex();
		}
		return SyntaxToken(SLASH_TOKEN, "/", this->index++, this->row, 1);

	case ',':
		return SyntaxToken(COMMA_TOKEN, ",", this->index++, this->row, 1);

	case '(':
		return SyntaxToken(OPEN_PAREN, "(", this->index++, this->row, 1);
	case ')':
		return SyntaxToken(CLOSE_PAREN, ")", this->index++, this->row, 1);
	case '{':
		return SyntaxToken(OPEN_CURLY_BRACKET, "{", this->index++, this->row, 1);
	case '}':
		return SyntaxToken(CLOSE_CURLY_BRACKET, "}", this->index++, this->row, 1);

	case '=':
		if (PeekNext() == '=')
		{
			this->index += 2;
			return SyntaxToken(EQUAL_EQUAL_TOKEN, "==", this->index - 2, this->row, 2);
		}
		return SyntaxToken(EQUAL_TOKEN, "=", this->index++, this->row, 1);
	case '!':
		if (PeekNext() == '=')
		{
			this->index += 2;
			return SyntaxToken(BANG_EQUAL_TOKEN, "!=", this->index - 2, this->row, 2);
		}
		return SyntaxToken(BANG_TOKEN, "!", this->index - 1, this->row, 1);
	case '&':
		if (PeekNext() == '&')
		{
			this->index += 2;
			return SyntaxToken(AMPERSAND_AMPERSAND_TOKEN, "&&", this->index - 2, this->row, 2);
		}
		break;
	case '|':
		if (PeekNext() == '|')
		{
			this->index += 2;
			return SyntaxToken(PIPE_PIPE_TOKEN, "||", this->index - 2, this->row, 2);
		}
		break;

	case '"':
	{
		advance();
		size_t start = this->index;
		while (Current() != '"')
		{
			advance();
		}
		size_t length = this->index - start;
		std::string text = this->program.substr(start, length);
		advance(); // deleting the last "
		return SyntaxToken(STRING_LITERAL_TOKEN, text, start, this->row, length);
	}
		break;
	case ';':
		return SyntaxToken(SEMICOLON_TOKEN, ";", this->index++, this->row, 1);
	default:
		return SyntaxToken(BAD_TOKEN, "", this->index++, 0, this->row);
	}
	return SyntaxToken(BAD_TOKEN, "", this->index++, 0, this->row);
}