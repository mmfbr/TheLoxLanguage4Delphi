
#pragma once
#include "visitor.hpp"

#include "nodes/astnode.hpp"

class Traverser : public Visitor
{
public:
	void Traverse(std::unique_ptr<AstNode>& statement);

private:
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