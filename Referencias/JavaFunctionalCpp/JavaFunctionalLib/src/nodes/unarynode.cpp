#include "unarynode.hpp"

UnaryNode::UnaryNode(Token_t token, std::unique_ptr<AstNode> left)
{
	this->token = token;
	this->left = std::move(left);
}

std::any UnaryNode::Accept(Visitor& visitor)
{
	return visitor.VisitUnaryNode(*this);
}
