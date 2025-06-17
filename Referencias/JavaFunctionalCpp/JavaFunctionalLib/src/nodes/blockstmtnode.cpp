#include "blockstmtnode.hpp"
BlockStmtNode::BlockStmtNode(std::vector<std::unique_ptr<AstNode>> stmts)
{
	this->stmts = std::move(stmts);
}

std::any BlockStmtNode::Accept(Visitor& visitor)
{
	return visitor.VisitBlockStmtNode(*this);
}