#include "pch.h"
#include "parser.hpp"
#include "ast_node_headers.hpp"
#include <vector>

class ParserTest : public testing::Test
{
protected:
	void SetUp() override
	{
		
	}

	void TearDown() override
	{

	}

	Parser InitParser()
	{
		EnvStack envstack;
		FunctionMemory functionMemory;
		return Parser(program, std::move(envstack), functionMemory);
	}

	std::string program;
	
};

TEST_F(ParserTest, SimpleBinaryExpressionParser)
{
	program = "2+3";
	Parser parser = InitParser();
	std::vector<std::unique_ptr<AstNode>> statements = parser.Parse();
	
	std::unique_ptr<BinaryExpression> expected = std::make_unique<BinaryExpression>(std::make_unique<NumberNode>(2), SyntaxToken(PLUS_TOKEN, "+", 1, 0, 1), std::make_unique<NumberNode>(3));

	ASSERT_EQ(statements.size(), 1);
	std::unique_ptr<AstNode> stmt = std::move(statements.back());

	std::unique_ptr<BinaryExpression> stmt_parsed = std::make_unique<BinaryExpression>(dynamic_cast<BinaryExpression*>(stmt.release()));
	
}
