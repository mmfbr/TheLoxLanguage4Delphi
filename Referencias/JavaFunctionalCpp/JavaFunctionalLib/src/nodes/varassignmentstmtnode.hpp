#pragma once
#include "astnode.hpp"

class VarAssignmentStmtNode : public AstNode
{
public:
	std::string identifier;
	std::unique_ptr<AstNode> expression;
	
	VarAssignmentStmtNode(std::string identifier, std::unique_ptr<AstNode> expression);
	std::any Accept(Visitor& visitor);
};