#pragma once
#include <vector>
#include "nodes/astnode.hpp"
#include "environment.hpp"
#include "envstack.hpp"
#include "variable.hpp"
#include "functionmemory.hpp"

class Semantic : public Visitor
{
public:
	EnvStack env_stack;
	FunctionMemory& function_memory;
	Semantic(EnvStack env, FunctionMemory& function_memory);

	std::vector<std::string> Analyse(std::vector<std::unique_ptr<AstNode>>& statements);


private:
	std::vector<std::string> errors;
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