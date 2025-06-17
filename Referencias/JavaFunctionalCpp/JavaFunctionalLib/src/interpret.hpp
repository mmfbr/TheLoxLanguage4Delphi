#pragma once
#include <iostream>
#include <any>
#include "visitor.hpp"
#include "token.hpp"
#include "variable.hpp"

#include "ast_node_headers.hpp"

#include "environment.hpp"
#include "functionmemory.hpp"
#include "envstack.hpp"

class Interpreter : public Visitor {
public:
	Interpreter(EnvStack env_stack, FunctionMemory& function_memory);
	std::any Interpret(std::unique_ptr<AstNode> root);
	std::vector<std::string> GetRuntimeErrors();


private:
	EnvStack env_stack;
	FunctionMemory& function_memory;
	std::vector<Variable> buffer_function_parameters;

	std::vector<std::string> runtime_errors;
	void Report(std::string error);

	std::any VisitBinaryExpression(BinaryExpression& binaryExpression);
	std::any VisitBoolNode(BoolNode& boolNode);
	std::any VisitNumberNode(NumberNode& numberNode);
	std::any VisitStringNode(StringNode& stringNode);
	std::any VisitIdentifierNode(IdentifierNode& identifierNode);
	std::any VisitUnaryNode(UnaryNode& unaryNode);

	std::any VisitIfStmtNode(IfStmtNode& ifStmtNode);
	std::any VisitPrintStmt(PrintStmtNode& printStmtNode);
	std::any VisitVarDeclarationStmt(VarDeclarationNode& varDeclarationNode);
	std::any VisitVarAssignmentStmt(VarAssignmentStmtNode& varAssignmentNode);

	std::any VisitFunctionCallNode(FunctionCallExpr& functionCallExpr);
	std::any VisitBlockStmtNode(BlockStmtNode& blockStmtNode);
};


