#include <iostream>
#include "token.hpp"
#include "binaryexpression.hpp"

BinaryExpression::BinaryExpression(std::unique_ptr<AstNode> left, Token_t op, std::unique_ptr<AstNode> right)
{
	this->left = std::move(left);
	this->op = op;
	this->right = std::move(right);
}

std::any BinaryExpression::Accept(Visitor& visitor)
{
	return visitor.VisitBinaryExpression(*this);
}