
#include <iostream>
#include <optional>
#include <string>
#include <vector>

#include "syntaxtoken.hpp"
#include "token.hpp"

#include "ast_node_headers.hpp"

#include "parser.hpp"

Parser::Parser(std::string program, EnvStack env_stack, FunctionMemory& function_memory)
	: function_memory(function_memory)
{
	this->env_stack = std::move(env_stack);

	Lexer lexer(program);

	this->tokens = lexer.LexAll();
	this->index = 0;
}

SyntaxToken Parser::NextToken()
{
	size_t size = this->tokens.size();
	if (this->index < size)
	{
		return this->tokens[this->index++];
	}
	return SyntaxToken::SyntaxToken(END_OF_FILE_TOKEN, "", this->index - 1, 0, -1);
}

bool Parser::IsAtEnd()
{
	if (this->index >= this->tokens.size() ||
		this->tokens[this->index].GetToken_t() == BAD_TOKEN ||
		this->tokens[this->index].GetToken_t() == END_OF_FILE_TOKEN)
	{
		return true;
	}
	return false;
}

void Parser::Advance()
{
	size_t size = this->tokens.size();
	if (this->index < size)
	{
		this->index++;
	}
}

SyntaxToken Parser::PeekNextNext()
{
	return LookAhead(2);
}

SyntaxToken Parser::PeekNext()
{
	return LookAhead(1);
}

SyntaxToken Parser::Peek()
{
	return LookAhead(0);
}

SyntaxToken Parser::Previous()
{
	return LookAhead(-1);
}

SyntaxToken Parser::PreviousPrevious()
{
	return LookAhead(-2);
}

void Parser::Back()
{
	if (this->index - 1 >= 0)
	{
		--this->index;
	}
}

SyntaxToken Parser::LookAhead(int offset)
{
	int index = offset + this->index;
	if (index < this->tokens.size())
	{
		return this->tokens[index];
	}
	return this->tokens[this->tokens.size() - 1];
}

SyntaxToken Parser::Expect(Token_t expect)
{
	if (Peek().GetToken_t() == expect)
	{
		return NextToken();
	}
	SyntaxToken curr = Peek();
	Report("Expected " + TokenName(expect));
	return SyntaxToken::SyntaxToken(BAD_TOKEN, "", -1, 0, 0);
}

std::optional<SyntaxToken> Parser::ExpectOptional(Token_t expect)
{
	if (Peek().GetToken_t() == expect)
	{
		return NextToken();
	}
	return std::nullopt;
}

std::optional<SyntaxToken> Parser::FindVarType()
{
	std::optional<SyntaxToken> dt_op = std::nullopt;
	if (ExpectOptional(BOOL_TYPE))
	{
		dt_op = Previous();
	}
	if (ExpectOptional(SHORT_TYPE))
	{
		dt_op = Previous();
	}
	if (ExpectOptional(INT_TYPE))
	{
		dt_op = Previous();
	}
	if (ExpectOptional(LONG_TYPE))
	{
		dt_op = Previous();
	}
	if (ExpectOptional(FLOAT_TYPE))
	{
		dt_op = Previous();
	}
	if (ExpectOptional(DOUBLE_TYPE))
	{
		dt_op = Previous();
	}
	return dt_op;
}

bool Parser::Match(Token_t match)
{
	if (Peek().GetToken_t() == match)
	{
		return true;
	}
	return false;
}

bool Parser::MatchAny(std::vector<Token_t> tokens)
{
	for (Token_t token : tokens)
	{
		if (Match(token))
		{
			return true;
		}
	}
	return false;
}

std::vector<std::unique_ptr<AstNode>> Parser::Parse()
{
	std::vector<std::unique_ptr<AstNode>> statements;
	while (!IsAtEnd() && this->GetErrorReports().empty())
	{
		try
		{
			std::unique_ptr<AstNode> statement = ParseStatement();
			if (statement == nullptr)
			{
				break;
			}
			statements.push_back(std::move(statement));
		}
		catch (std::invalid_argument e)
		{
			Report(e.what());
		}
	}

	return statements;
}

void Parser::Report(std::string error)
{
	this->error_reports.push_back(error);
}

std::vector<std::string> Parser::GetErrorReports()
{
	return this->error_reports;
}

std::unique_ptr<AstNode> Parser::ParseStatement()
{
	if (Match(PRINT_KW))
	{
		return ParsePrintStatement();
	}
	if (MatchAny({ BOOL_TYPE, SHORT_TYPE, INT_TYPE, LONG_TYPE, FLOAT_TYPE, DOUBLE_TYPE }))
	{
		return DeclarationStatement();
	}

	if (Match(IF_KW))
	{
		return ParseIfStatement();
	}

	if (Match(OPEN_CURLY_BRACKET))
	{
		return ParseBlockStatement();
	}
	return ParseExpression();
}

std::unique_ptr<AstNode> Parser::ParseIfStatement()
{
	Expect(IF_KW);
	Expect(OPEN_PAREN);
	std::unique_ptr<AstNode> expression = ParseExpression();
	Expect(CLOSE_PAREN);

	std::unique_ptr<AstNode> blockstmt = ParseBlockStatement();
	return std::make_unique<IfStmtNode>(std::move(expression), std::move(blockstmt));
}

std::unique_ptr<AstNode> Parser::ParsePrintStatement()
{
	Advance();
	std::unique_ptr<AstNode> expression = ParseExpression();
	if (expression != nullptr)
	{
		Expect(SEMICOLON_TOKEN);
	}
	return std::make_unique<PrintStmtNode>(std::move(expression));
}

std::unique_ptr<AstNode> Parser::DeclarationStatement()
{
	if (MatchAny({
		BOOL_TYPE,
		SHORT_TYPE,
		INT_TYPE,
		LONG_TYPE,
		FLOAT_TYPE,
		DOUBLE_TYPE }) && PeekNext().GetToken_t() == IDENTIFIER_TOKEN)
	{
		if (PeekNextNext().GetToken_t() == OPEN_PAREN)
		{
			return FunctionDeclarationStatement();
		}
		return VarDeclarationStatement();
	}

	return nullptr;
}

std::unique_ptr<AstNode> Parser::FunctionDeclarationStatement()
{
	std::optional<SyntaxToken> dt_op = FindVarType();

	SyntaxToken identifier = Expect(IDENTIFIER_TOKEN);
	if (not dt_op.has_value())
	{
		throw std::invalid_argument("Data type for identifier: " + identifier.GetValue() + " not found.");
	}
	SyntaxToken dt = dt_op.value();
	FuncVariable func_var;
	func_var.return_type = FromToken_tToDataType(dt.GetToken_t());
	func_var.identifier = identifier.GetValue();

	Expect(OPEN_PAREN);
	std::vector<Variable> formal_parameters;
	if (not Match(CLOSE_PAREN))
	{
		formal_parameters = Parameters();
	}
	Expect(CLOSE_PAREN);

	std::unique_ptr<AstNode> blockstmt = ParseBlockStatement(formal_parameters, func_var.identifier);
	func_var.block_stmt = std::move(blockstmt);
	func_var.parameters = std::move(formal_parameters);
	this->function_memory.Add(std::move(func_var));
	return {}; // nullptr for std::unique_ptr
}

std::unique_ptr<AstNode> Parser::FunctionCall()
{
	SyntaxToken identifier = Expect(IDENTIFIER_TOKEN);
	std::vector<std::unique_ptr<AstNode>> args = Arguments();
	Expect(CLOSE_PAREN);
	return std::make_unique<FunctionCallExpr>(identifier.GetValue(), std::move(args));;
}

std::vector<Variable> Parser::Parameters()
{
	std::vector<Variable> formal_parameters;

	std::optional<SyntaxToken> var_dt = FindVarType();
	SyntaxToken identifier = Expect(IDENTIFIER_TOKEN);
	if (not var_dt.has_value())
	{
		throw std::invalid_argument("Data type for identifier: " + identifier.GetValue() + " not found.");
	}
	Variable var1;
	var1.dtType = FromToken_tToDataType(var_dt.value().GetToken_t());
	var1.identifier = identifier.GetValue();

	formal_parameters.push_back(var1);

	while (Match(COMMA_TOKEN))
	{
		Advance();
		std::optional<SyntaxToken> var_dt = FindVarType();
		SyntaxToken identifier = Expect(IDENTIFIER_TOKEN);
		if (not var_dt.has_value())
		{
			throw std::invalid_argument("Data type for identifier: " + identifier.GetValue() + " not found.");
		}
		Variable var2;
		var2.dtType = FromToken_tToDataType(var_dt.value().GetToken_t());
		var2.identifier = identifier.GetValue();
		formal_parameters.push_back(var2);
	}
	return formal_parameters;
}

std::vector<std::unique_ptr<AstNode>> Parser::Arguments()
{
	Expect(OPEN_PAREN);
	std::vector<std::unique_ptr<AstNode>> args;
	while (not Match(CLOSE_PAREN))
	{
		args.push_back(ParseExpression());
		if (Match(CLOSE_PAREN))
		{
			break;
		}
		Expect(COMMA_TOKEN);
	}
	Expect(CLOSE_PAREN);
	return args;
}

std::unique_ptr<AstNode> Parser::ParseBlockStatement(std::vector<Variable> pre_vars, std::string func_id)
{
	Expect(OPEN_CURLY_BRACKET);

	Environment block_env;
	for (auto pre_var : pre_vars)
	{
		block_env.env_var.Set(pre_var);
	}
	this->env_stack.Push(std::move(block_env));

	std::vector<std::unique_ptr<AstNode>> stmts;
	while (not Match(CLOSE_CURLY_BRACKET))
	{
		std::unique_ptr<AstNode> stmt = ParseStatement();
		if (!stmt)
		{
			break;
		}
		stmts.push_back(std::move(stmt));
	}
	Expect(CLOSE_CURLY_BRACKET);
	return std::make_unique<BlockStmtNode>(std::move(stmts));
}

std::unique_ptr<AstNode> Parser::VarDeclarationStatement()
{
	std::optional<SyntaxToken> dt_op = FindVarType();

	SyntaxToken identifier = Expect(IDENTIFIER_TOKEN);

	if (not dt_op.has_value())
	{
		throw std::invalid_argument("Data type for identifier: " + identifier.GetValue() + " not found.");
	}
	SyntaxToken dt = dt_op.value();
	Variable var;
	var.dtType = FromToken_tToDataType(dt.GetToken_t());
	var.identifier = identifier.GetValue();
	this->env_stack.Add(var);
	std::unique_ptr<AstNode> expression;
	if (ExpectOptional(EQUAL_TOKEN))
	{
		expression = std::move(ParseExpression());
	}
	Expect(SEMICOLON_TOKEN);

	return std::make_unique<VarDeclarationNode>(dt.GetToken_t(), identifier.GetValue(), std::move(expression));
}

std::unique_ptr<AstNode> Parser::VarAssignmentStatement()
{
	SyntaxToken identifier = Expect(IDENTIFIER_TOKEN);

	if (ExpectOptional(PLUS_PLUS_TOKEN))
	{
		std::unique_ptr<AstNode> ppt = std::make_unique<BinaryExpression>(std::make_unique<IdentifierNode>(identifier.GetValue()), PLUS_TOKEN, std::make_unique<NumberNode>(1));
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(ppt));
	}
	if (ExpectOptional(TRIPLE_PLUS_TOKEN))
	{
		std::unique_ptr<AstNode> ppt = std::make_unique<BinaryExpression>(std::make_unique<IdentifierNode>(identifier.GetValue()), PLUS_TOKEN, std::make_unique<NumberNode>(2));
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(ppt));
	}
	if (ExpectOptional(MINUS_MINUS_TOKEN))
	{
		std::unique_ptr<AstNode> ppt = std::make_unique<BinaryExpression>(std::make_unique<IdentifierNode>(identifier.GetValue()), MINUS_TOKEN, std::make_unique<NumberNode>(1));
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(ppt));
	}
	if (ExpectOptional(PLUS_EQUAL_TOKEN))
	{
		std::unique_ptr<AstNode> ppt = std::make_unique<BinaryExpression>(std::make_unique<IdentifierNode>(identifier.GetValue()), PLUS_TOKEN, std::move(ParseExpression()));
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(ppt));
	}
	if (ExpectOptional(MINUS_EQUAL_TOKEN))
	{
		std::unique_ptr<AstNode> ppt = std::make_unique<BinaryExpression>(std::make_unique<IdentifierNode>(identifier.GetValue()), MINUS_TOKEN, std::move(ParseExpression()));
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(ppt));
	}
	if (ExpectOptional(STAR_EQUAL_TOKEN))
	{
		std::unique_ptr<AstNode> ppt = std::make_unique<BinaryExpression>(std::make_unique<IdentifierNode>(identifier.GetValue()), STAR_TOKEN, std::move(ParseExpression()));
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(ppt));
	}
	if (ExpectOptional(SLASH_EQUAL_TOKEN))
	{
		std::unique_ptr<AstNode> ppt = std::make_unique<BinaryExpression>(std::make_unique<IdentifierNode>(identifier.GetValue()), SLASH_TOKEN, std::move(ParseExpression()));
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(ppt));
	}

	if (ExpectOptional(EQUAL_TOKEN))
	{
		std::unique_ptr<AstNode> expression = ParseExpression();
		Expect(SEMICOLON_TOKEN);
		return std::make_unique<VarAssignmentStmtNode>(identifier.GetValue(), std::move(expression));
	}
	Back();
	return ParseTerm();
}

std::unique_ptr<AstNode> Parser::ParseExpression()
{
	if (Match(OPEN_PAREN))
	{
		return Group();
	}
	if (Match(IDENTIFIER_TOKEN) && PeekNext().GetToken_t() == OPEN_PAREN)
	{
		return FunctionCall();
	}
	if (Match(IDENTIFIER_TOKEN) && PeekNext().GetToken_t() != OPEN_PAREN)
	{
		return VarAssignmentStatement();
	}
	return ParseBinaryExpression();
}

std::unique_ptr<AstNode> Parser::Group()
{
	Expect(OPEN_PAREN);
	std::unique_ptr<AstNode> expression = ParseExpression();
	Expect(CLOSE_PAREN);
	return expression;
}

std::unique_ptr<AstNode> Parser::ParseBinaryExpression(int parentPrecedence)
{
	std::unique_ptr<AstNode> left;

	unsigned short unary_prec = GetUnaryOperatorPrecedence(Peek().GetToken_t());
	if (unary_prec != 0 && unary_prec >= parentPrecedence)
	{
		SyntaxToken operatorToken = NextToken();
		std::unique_ptr<AstNode> operand = ParseBinaryExpression(unary_prec);
		left = std::make_unique<UnaryNode>(operatorToken.GetToken_t(), std::move(operand));
	}
	else
	{
		left = ParsePrimary();
	}

	while (true)
	{
		unsigned short prec = GetBinaryOperatorPrecedence(Peek().GetToken_t());
		if (prec == 0 || prec <= parentPrecedence)
		{
			break;
		}
		SyntaxToken operatorToken = NextToken();
		std::unique_ptr<AstNode> right = ParseBinaryExpression(prec);
		left = std::make_unique<BinaryExpression>(std::move(left), operatorToken.GetToken_t(), std::move(right));
	}

	return left;
}

std::unique_ptr<AstNode> Parser::ParseTerm()
{
	std::unique_ptr<AstNode> left = ParseFactor();
	while (MatchAny({ PLUS_TOKEN, MINUS_TOKEN, EQUAL_EQUAL_TOKEN, AMPERSAND_AMPERSAND_TOKEN, BANG_EQUAL_TOKEN, PIPE_PIPE_TOKEN }))
	{
		SyntaxToken op = NextToken();
		std::unique_ptr<AstNode> right = ParseFactor();
		left = std::make_unique<BinaryExpression>(std::move(left), op.GetToken_t(), std::move(right));
	}
	return left;
}

std::unique_ptr<AstNode> Parser::ParseFactor()
{
	std::unique_ptr<AstNode> left = ParseUnary();

	while (MatchAny({ STAR_TOKEN, SLASH_TOKEN }))
	{
		SyntaxToken op = NextToken();
		std::unique_ptr<AstNode> right = ParseUnary();
		left = std::make_unique<BinaryExpression>(std::move(left), op.GetToken_t(), std::move(right));
	}

	return left;
}

std::unique_ptr<AstNode> Parser::ParseUnary()
{
	if (MatchAny({ MINUS_TOKEN, BANG_TOKEN }))
	{
		SyntaxToken token = NextToken();
		std::unique_ptr<AstNode> unary = ParseUnary();
		return std::make_unique<UnaryNode>(token.GetToken_t(), std::move(unary));
	}
	return ParsePrimary();
}

std::unique_ptr<AstNode> Parser::ParsePrimary()
{
	std::unique_ptr<AstNode> primary = {};
	SyntaxToken token = SyntaxToken::SyntaxToken(BAD_TOKEN, "", -1, 0, 0);

	SyntaxToken prev = Previous();
	SyntaxToken prev_prev = PreviousPrevious();
	if (Match(NUMBER_LITERAL_TOKEN) &&
		prev.GetToken_t() == EQUAL_TOKEN &&
		prev_prev.GetToken_t() == IDENTIFIER_TOKEN)
	{
		token = NextToken();
		std::pair<Variable, Environment> var = std::move(this->env_stack.Get(prev_prev.GetValue()));
		switch (var.first.dtType)
		{
			case DT_SHORT:
				return std::make_unique<NumberNode>((short)stoi(token.GetValue()));
			case DT_INT:
				return std::make_unique<NumberNode>(stoi(token.GetValue()));
			case DT_LONG:
				return std::make_unique<NumberNode>(stol(token.GetValue()));
			case DT_FLOAT:
				return std::make_unique<NumberNode>(stof(token.GetValue()));
			case DT_DOUBLE:
				return std::make_unique<NumberNode>(stod(token.GetValue()));
			default:
				return std::make_unique<NumberNode>(stoi(token.GetValue()));
		}
	}
	else if (Match(NUMBER_LITERAL_TOKEN))
	{
		token = NextToken();
		if (token.GetValue().find('.') != std::string::npos)
		{
			return std::make_unique<NumberNode>(stod(token.GetValue()));
		}
		return std::make_unique<NumberNode>(stoi(token.GetValue()));
	}
	else if (Match(STRING_LITERAL_TOKEN))
	{
		token = NextToken();
		return std::make_unique<StringNode>(token.GetValue());
	}
	else if (Match(IDENTIFIER_TOKEN))
	{
		token = NextToken();
		return std::make_unique<IdentifierNode>(token.GetValue());
	}
	else if (Match(FALSE_TOKEN))
	{
		Advance();
		return std::make_unique<BoolNode>(false);
	}
	else if (Match(TRUE_TOKEN))
	{
		Advance();
		return std::make_unique<BoolNode>(true);
	}
	return primary;
}
