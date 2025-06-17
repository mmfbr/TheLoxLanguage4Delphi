#pragma once
#include <iostream>

#include "astnode.hpp"
#include "token.hpp"

class UnaryNode : public AstNode {
public:
	UnaryNode(Token_t token, std::unique_ptr<AstNode> left);

	std::any Accept(Visitor& visitor);

	std::unique_ptr<AstNode> left;
	Token_t token;

};

