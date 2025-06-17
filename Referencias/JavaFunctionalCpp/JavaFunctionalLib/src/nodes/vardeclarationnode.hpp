#pragma once
#include "astnode.hpp"
#include "token.hpp"
#include "variable.hpp"

class VarDeclarationNode : public AstNode {
public:
	Token_t variableType;
	std::string identifier;
	std::unique_ptr<AstNode> expression;
	VarDeclarationNode(Token_t variableType, std::string identifier, std::unique_ptr<AstNode> expression);

	std::any Accept(Visitor& visitor);

};

