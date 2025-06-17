

#include "identifiernode.hpp"

IdentifierNode::IdentifierNode(std::string identifier)
{
	this->identifier = identifier;
}

std::any IdentifierNode::Accept(Visitor& visitor)
{
	return visitor.VisitIdentifierNode(*this);
}
