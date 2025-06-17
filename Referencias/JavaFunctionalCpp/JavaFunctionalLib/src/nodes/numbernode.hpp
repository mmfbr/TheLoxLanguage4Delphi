#pragma once
#ifndef NUMBER_DT
#define NUMBER_DT std::variant<short, int, long, float, double>
#endif // !NUMBER_DT

#include "astnode.hpp"
#include <variant>

class NumberNode : public AstNode
{
public:
	NUMBER_DT number;
	NumberNode(NUMBER_DT number);

	std::any Accept(Visitor& visitor);
};
