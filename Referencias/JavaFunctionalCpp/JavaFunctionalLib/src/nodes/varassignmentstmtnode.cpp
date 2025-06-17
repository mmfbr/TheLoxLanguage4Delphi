#include "varassignmentstmtnode.hpp"

VarAssignmentStmtNode::VarAssignmentStmtNode(std::string identifier, std::unique_ptr<AstNode> expression)
{
	this->identifier = identifier;
	this->expression = std::move(expression);
}

std::any VarAssignmentStmtNode::Accept(Visitor& visitor)
{
	return visitor.VisitVarAssignmentStmt(*this);
}
