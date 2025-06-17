#pragma once
#include "astnode.hpp"

class PrintStmtNode : public AstNode
{
public:
	std::unique_ptr<AstNode> expression;

	PrintStmtNode(std::unique_ptr<AstNode> expression);
	std::any Accept(Visitor& visitor);
};


