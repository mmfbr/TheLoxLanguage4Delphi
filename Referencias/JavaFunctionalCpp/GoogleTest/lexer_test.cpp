#include "pch.h"
#include "parser.hpp"

static void AssertEqSyntaxTokens(std::vector<SyntaxToken> expected_output, std::vector<SyntaxToken> lexer_output)
{
	ASSERT_EQ(lexer_output.size(), expected_output.size());
	for (int i = 0; i < lexer_output.size(); i++)
	{
		SyntaxToken expected_syntaxtoken = expected_output.at(i);
		SyntaxToken lexer_syntaxtoken = lexer_output.at(i);

		ASSERT_EQ(expected_syntaxtoken.GetLen(), lexer_syntaxtoken.GetLen());
		ASSERT_EQ(expected_syntaxtoken.GetPos(), lexer_syntaxtoken.GetPos());
		ASSERT_EQ(expected_syntaxtoken.GetRow(), lexer_syntaxtoken.GetRow());
		ASSERT_EQ(expected_syntaxtoken.GetToken_t(), lexer_syntaxtoken.GetToken_t());
		ASSERT_EQ(expected_syntaxtoken.GetValue(), lexer_syntaxtoken.GetValue());
	}
}

class LexerTest : public testing::Test
{
protected:
	void SetUp() override
	{
		lexer = Lexer(program);
	}

	void TearDown() override
	{
		
	}

	std::string program;
	Lexer lexer = Lexer("");
};

TEST_F(LexerTest, EndOfFileLexer)
{
	program = "";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(END_OF_FILE_TOKEN, "", 0, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, KeywordsLexer)
{
	program = "print if return printifreturn";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(PRINT_KW, DisplayToken(PRINT_KW), 0, row, 5),
		SyntaxToken(IF_KW, DisplayToken(IF_KW), 6, row, 2),
		SyntaxToken(RETURN_KW, DisplayToken(RETURN_KW), 9, row, 6),
		SyntaxToken(IDENTIFIER_TOKEN, "printifreturn", 16, row, 13),
		SyntaxToken(END_OF_FILE_TOKEN, "", 16+13, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, VariableTypesLexer)
{
	program = "bool short int long float double boolshortintlongfloatdouble";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(BOOL_TYPE, DisplayToken(BOOL_TYPE), 0, row, 4),
		SyntaxToken(SHORT_TYPE, DisplayToken(SHORT_TYPE), 5, row, 5),
		SyntaxToken(INT_TYPE, DisplayToken(INT_TYPE), 11, row, 3),
		SyntaxToken(LONG_TYPE, DisplayToken(LONG_TYPE), 15, row, 4),
		SyntaxToken(FLOAT_TYPE, DisplayToken(FLOAT_TYPE), 20, row, 5),
		SyntaxToken(DOUBLE_TYPE, DisplayToken(DOUBLE_TYPE), 26, row, 6),
		SyntaxToken(IDENTIFIER_TOKEN, "boolshortintlongfloatdouble", 33, row, strlen("boolshortintlongfloatdouble")),
		SyntaxToken(END_OF_FILE_TOKEN, "", 33 + strlen("boolshortintlongfloatdouble"), row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, ParenLexer)
{
	program = "(){}}";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(OPEN_PAREN, "(", 0, row, 1),
		SyntaxToken(CLOSE_PAREN, ")", 1, row, 1),
		SyntaxToken(OPEN_CURLY_BRACKET, "{", 2, row, 1),
		SyntaxToken(CLOSE_CURLY_BRACKET, "}", 3, row, 1),
		SyntaxToken(CLOSE_CURLY_BRACKET, "}", 4, row, 1),
		SyntaxToken(END_OF_FILE_TOKEN, "", 5, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, OperatorsLexer)
{
	program = "+ - * / ++ +++ -- += -= *= /= = == != && || ,";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(PLUS_TOKEN, "+", 0, row, 1),
		SyntaxToken(MINUS_TOKEN, "-", 2, row, 1),
		SyntaxToken(STAR_TOKEN, "*", 4, row, 1),
		SyntaxToken(SLASH_TOKEN, "/", 6, row, 1),
		SyntaxToken(PLUS_PLUS_TOKEN, "++", 8, row, 2),
		SyntaxToken(TRIPLE_PLUS_TOKEN, "+++", 11, row, 3),
		SyntaxToken(MINUS_MINUS_TOKEN, "--", 15, row, 2),
		SyntaxToken(PLUS_EQUAL_TOKEN, "+=", 18, row, 2),
		SyntaxToken(MINUS_EQUAL_TOKEN, "-=", 21, row, 2),
		SyntaxToken(STAR_EQUAL_TOKEN, "*=", 24, row, 2),
		SyntaxToken(SLASH_EQUAL_TOKEN, "/=", 27, row, 2),
		SyntaxToken(EQUAL_TOKEN, "=", 30, row, 1),
		SyntaxToken(EQUAL_EQUAL_TOKEN, "==", 32, row, 2),
		SyntaxToken(BANG_EQUAL_TOKEN, "!=", 35, row, 2),
		SyntaxToken(AMPERSAND_AMPERSAND_TOKEN, "&&", 38, row, 2),
		SyntaxToken(PIPE_PIPE_TOKEN, "||", 41, row, 2),
		SyntaxToken(COMMA_TOKEN, ",", 44, row, 1),
		SyntaxToken(END_OF_FILE_TOKEN, "", 45, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, BoolTokensLexer)
{
	program = "true false true true";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(TRUE_TOKEN, "true", 0, row, 4),
		SyntaxToken(FALSE_TOKEN, "false", 5, row, 5),
		SyntaxToken(TRUE_TOKEN, "true", 11, row, 4),
		SyntaxToken(TRUE_TOKEN, "true", 16, row, 4),
		SyntaxToken(END_OF_FILE_TOKEN, "", 20, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, IdentifierLiteralsLexer)
{
	program = "var1 _vs2 VARIA __MALO__";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(IDENTIFIER_TOKEN, "var1", 0, row, 4),
		SyntaxToken(IDENTIFIER_TOKEN, "_vs2", 5, row, 4),
		SyntaxToken(IDENTIFIER_TOKEN, "VARIA", 10, row, 5),
		SyntaxToken(IDENTIFIER_TOKEN, "__MALO__", 16, row, 8),
		SyntaxToken(END_OF_FILE_TOKEN, "", 24, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, StringLiteralsLexer)
{
	program = "\"hello\" \"world\"";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(STRING_LITERAL_TOKEN, "hello", 1, row, 5),
		SyntaxToken(STRING_LITERAL_TOKEN, "world", 9, row, 5),
		SyntaxToken(END_OF_FILE_TOKEN, "", 15, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, NumberLiteralsLexer)
{
	program = "2 123 1465 94";
	SetUp();
	int row = 0;
	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(NUMBER_LITERAL_TOKEN, "2", 0, row, 1),
		SyntaxToken(NUMBER_LITERAL_TOKEN, "123", 2, row, 3),
		SyntaxToken(NUMBER_LITERAL_TOKEN, "1465", 6, row, 4),
		SyntaxToken(NUMBER_LITERAL_TOKEN, "94", 11, row, 2),
		SyntaxToken(END_OF_FILE_TOKEN, "", 13, row, 0)
	};
	std::vector<SyntaxToken> lexer_output = lexer.LexAll();
	AssertEqSyntaxTokens(expected_output, lexer_output);
}

TEST_F(LexerTest, FunctionDeclarationLexer)
{
	program = "int f(int a, int b){print a + b;}f(2, 52);";
	SetUp();
	int row = 0;

	std::vector<SyntaxToken> expected_output = {
		SyntaxToken(INT_TYPE, DisplayToken(INT_TYPE), 0, row, 3),
		SyntaxToken(IDENTIFIER_TOKEN, "f", 4, row, 1),
		SyntaxToken(OPEN_PAREN, "(", 5, row, 1),
		SyntaxToken(INT_TYPE, DisplayToken(INT_TYPE), 6, row, 3),
		SyntaxToken(IDENTIFIER_TOKEN, "a", 10, row, 1),
		SyntaxToken(COMMA_TOKEN, ",", 11, row, 1),
		SyntaxToken(INT_TYPE, DisplayToken(INT_TYPE), 13, row, 3),
		SyntaxToken(IDENTIFIER_TOKEN, "b", 17, row, 1),
		SyntaxToken(CLOSE_PAREN, ")", 18, row, 1),
		SyntaxToken(OPEN_CURLY_BRACKET, "{", 19, row, 1),
		SyntaxToken(PRINT_KW, DisplayToken(PRINT_KW), 20, row, 5),
		SyntaxToken(IDENTIFIER_TOKEN, "a", 26, row, 1),
		SyntaxToken(PLUS_TOKEN, "+", 28, row, 1),
		SyntaxToken(IDENTIFIER_TOKEN, "b", 30, row, 1),
		SyntaxToken(SEMICOLON_TOKEN, ";", 31, row, 1),
		SyntaxToken(CLOSE_CURLY_BRACKET, "}", 32, row ,1),
		SyntaxToken(IDENTIFIER_TOKEN, "f", 33, row, 1),
		SyntaxToken(OPEN_PAREN, "(", 34, row, 1),
		SyntaxToken(NUMBER_LITERAL_TOKEN, "2", 35, row, 1),
		SyntaxToken(COMMA_TOKEN, ",", 36, row, 1),
		SyntaxToken(NUMBER_LITERAL_TOKEN, "52", 38, row, 2),
		SyntaxToken(CLOSE_PAREN, ")", 40, row, 1),
		SyntaxToken(SEMICOLON_TOKEN, ";", 41, row ,1),

		SyntaxToken(END_OF_FILE_TOKEN, "", 42, row, 0)
	};

	std::vector<SyntaxToken> lexer_output = lexer.LexAll();

	AssertEqSyntaxTokens(expected_output, lexer_output);
}

