#pragma once

#include <iostream>
#include "lexer.hpp"
#include "astnode.hpp"

class BinaryExpression : public AstNode
{
public:
	std::unique_ptr<AstNode> left;
	std::unique_ptr<AstNode> right;
	Token_t op;

	BinaryExpression(std::unique_ptr<AstNode> left, Token_t op, std::unique_ptr<AstNode> right);
	BinaryExpression(std::unique_ptr<AstNode> left);

	std::any Accept(Visitor& visitor);
};
