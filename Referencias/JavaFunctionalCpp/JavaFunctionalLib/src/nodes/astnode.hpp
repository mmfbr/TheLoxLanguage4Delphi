#pragma once
#include "visitor.hpp"

class AstNode
{
public:
	virtual	std::any Accept(Visitor& visitor) = 0;
};

