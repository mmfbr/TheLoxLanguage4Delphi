#pragma once
#include <iostream>
#include <vector>
#include <optional>

#include "lexer.hpp"
#include "nodes/astnode.hpp"
#include "environment.hpp"
#include "envstack.hpp"

#include "functionmemory.hpp"

class Parser
{
public:
	Parser(std::string program, EnvStack env, FunctionMemory& function_memory);

	std::vector<std::unique_ptr<AstNode>> Parse();
	std::vector<std::string> GetErrorReports();
private:
	EnvStack env_stack;
	FunctionMemory& function_memory;
	std::vector<SyntaxToken> tokens;
	int index;

	void Report(std::string error);
	std::vector<std::string> error_reports;


	SyntaxToken NextToken();
	bool IsAtEnd();
	void Advance();
	SyntaxToken PeekNextNext();
	SyntaxToken PeekNext();
	SyntaxToken Peek();
	SyntaxToken Previous();
	SyntaxToken PreviousPrevious();
	void Back();
	SyntaxToken Expect(Token_t match);
	std::optional<SyntaxToken> ExpectOptional(Token_t expect);
	std::optional<SyntaxToken> FindVarType();
	bool Match(Token_t match);
	bool MatchAny(std::vector<Token_t> tokens);
	SyntaxToken LookAhead(int offset);
	std::unique_ptr<AstNode> ParseStatement();
	std::unique_ptr<AstNode> ParseIfStatement();
	std::unique_ptr<AstNode> ParsePrintStatement();
	std::unique_ptr<AstNode> DeclarationStatement();
	std::unique_ptr<AstNode> FunctionDeclarationStatement();
	std::unique_ptr<AstNode> FunctionCall();
	std::vector<Variable> Parameters();
	std::vector<std::unique_ptr<AstNode>> Arguments();
	std::unique_ptr<AstNode> ParseBlockStatement(std::vector<Variable> pre_vars = {}, std::string func_id = "main");
	std::unique_ptr<AstNode> VarDeclarationStatement();
	std::unique_ptr<AstNode> VarAssignmentStatement();
	std::unique_ptr<AstNode> ParseExpression();
	std::unique_ptr<AstNode> Group();
	std::unique_ptr<AstNode> ParseBinaryExpression(int precedence = 0);
	std::unique_ptr<AstNode> ParseTerm();
	std::unique_ptr<AstNode> ParseFactor();
	std::unique_ptr<AstNode> ParseUnary();
	std::unique_ptr<AstNode> ParsePrimary();

};

