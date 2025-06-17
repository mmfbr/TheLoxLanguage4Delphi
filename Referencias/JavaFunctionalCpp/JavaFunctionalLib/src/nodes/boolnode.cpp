
#include "boolnode.hpp"

BoolNode::BoolNode(bool value)
{
	this->value = value;
}

std::any BoolNode::Accept(Visitor& visitor)
{
	return visitor.VisitBoolNode(*this);
}