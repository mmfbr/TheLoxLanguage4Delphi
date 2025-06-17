#pragma once
#include <vector>

#include "astnode.hpp"
class FunctionCallExpr : public AstNode
{
public:
	std::string identifier;
	std::vector<std::unique_ptr<AstNode>> arguments;

	FunctionCallExpr(std::string identifier, std::vector<std::unique_ptr<AstNode>> arguments);

	std::any Accept(Visitor& visitor);
};