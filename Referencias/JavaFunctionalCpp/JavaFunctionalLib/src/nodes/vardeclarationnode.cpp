#include "vardeclarationnode.hpp"

VarDeclarationNode::VarDeclarationNode(Token_t variableType, std::string identifier, std::unique_ptr<AstNode> expression)
{
	this->variableType = variableType;
	this->identifier = identifier;
	this->expression = std::move(expression);
}

std::any VarDeclarationNode::Accept(Visitor& visitor)
{
	return visitor.VisitVarDeclarationStmt(*this);
}

