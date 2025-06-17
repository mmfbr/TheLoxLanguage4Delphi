#pragma once
#include "astnode.hpp"

class IfStmtNode : public AstNode
{
public:
	std::unique_ptr<AstNode> expression;
	std::unique_ptr<AstNode> blockStmt;

	IfStmtNode(std::unique_ptr<AstNode> expression, std::unique_ptr<AstNode> blockStmt);
	std::any Accept(Visitor& visitor);
};