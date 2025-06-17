#include "stringnode.hpp"

StringNode::StringNode(std::string value)
{
	this->value = value;
}


std::any StringNode::Accept(Visitor& visitor)
{
	return visitor.VisitStringNode(*this);
}
