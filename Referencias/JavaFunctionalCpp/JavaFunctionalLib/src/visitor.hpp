#pragma once
#include <any>
#include <iostream>
#include <vector>

class BinaryExpression;
class BoolNode;
class NumberNode;
class StringNode;
class IdentifierNode;
class UnaryNode;

class IfStmtNode;
class PrintStmtNode;
class VarDeclarationNode;
class VarAssignmentStmtNode;

class FunctionStmtNode;
class FunctionCallExpr;
class BlockStmtNode;

struct Variable;

class Visitor {
public:
	virtual std::any VisitBinaryExpression(BinaryExpression& binaryExpression) = 0;
	virtual std::any VisitBoolNode(BoolNode& boolNode) = 0;
	virtual std::any VisitNumberNode(NumberNode& numberNode) = 0;
	virtual std::any VisitStringNode(StringNode& stringNode) = 0;
	virtual std::any VisitIdentifierNode(IdentifierNode& identifierNode) = 0;
	virtual std::any VisitUnaryNode(UnaryNode& unaryNode) = 0;

	virtual std::any VisitIfStmtNode(IfStmtNode& ifStmtNode) = 0;
	virtual std::any VisitPrintStmt(PrintStmtNode& printStmtNode) = 0;
	virtual std::any VisitVarDeclarationStmt(VarDeclarationNode& varDeclarationNode) = 0;
	virtual std::any VisitVarAssignmentStmt(VarAssignmentStmtNode& varAssignmentNode) = 0;

	virtual std::any VisitFunctionCallNode(FunctionCallExpr& functionCallExpr) = 0;
	virtual std::any VisitBlockStmtNode(BlockStmtNode& blockStmtNode) = 0;
};

