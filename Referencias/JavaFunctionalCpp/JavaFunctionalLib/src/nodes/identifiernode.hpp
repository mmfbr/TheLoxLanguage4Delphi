#pragma once
#include "astnode.hpp"

class IdentifierNode : public AstNode
{
public:
	std::string identifier;
	IdentifierNode(std::string identifier);
	std::any Accept(Visitor& visitor);
};