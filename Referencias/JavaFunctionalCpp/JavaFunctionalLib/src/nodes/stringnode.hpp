#pragma once
#include <iostream>
#include "astnode.hpp"

class StringNode : public AstNode
{
public:
	std::string value;

	StringNode(std::string value);
	std::any Accept(Visitor& visitor);
};

