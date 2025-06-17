#include "semantic.hpp"
#include "ast_node_headers.hpp"

Semantic::Semantic(EnvStack env_stack, FunctionMemory& function_memory)
	: function_memory(function_memory)
{
	this->env_stack = std::move(env_stack);
}

std::vector<std::string> Semantic::Analyse(std::vector<std::unique_ptr<AstNode>>& statements)
{
	for (auto& stmt : statements)
	{
		if (stmt == nullptr)
		{
			continue;
		}
		stmt->Accept(*this);
	}
	return this->errors;
}

std::any Semantic::VisitBinaryExpression(BinaryExpression& binaryExpression)
{
	std::any left = binaryExpression.left->Accept(*this);
	std::any right = binaryExpression.right->Accept(*this);
	Token_t op = binaryExpression.op;
	switch (op)
	{
		case PLUS_TOKEN:
		case MINUS_TOKEN:
		case STAR_TOKEN:
		case SLASH_TOKEN:
			if (left.type() == typeid(short) && right.type() == typeid(short))
			{
				return (short)1;
			}
			if (left.type() == typeid(int) && right.type() == typeid(int))
			{
				return (int)1;
			}
			if (left.type() == typeid(long) && right.type() == typeid(long))
			{
				return (long)1;
			}
			if (left.type() == typeid(float) && right.type() == typeid(float))
			{
				return (float)1;
			}
			if (left.type() == typeid(double) && right.type() == typeid(double))
			{
				return (double)1;
			}

			break;
	}

	return std::any();
}

std::any Semantic::VisitBoolNode(BoolNode& boolNode)
{
	bool v = boolNode.value;
	if (not (v == false || v == true))
	{
		Report("Boolean value is invalid (must be either 'true' or 'false').");
	}
	return (bool)true;
}

std::any Semantic::VisitNumberNode(NumberNode& numberNode)
{
	NUMBER_DT nn = numberNode.number;
	if (std::holds_alternative<short>(nn))
	{
		return (short)1;
	}
	if (std::holds_alternative<int>(nn))
	{
		return (int)1;
	}
	if (std::holds_alternative<long>(nn))
	{
		return (long)1;
	}
	if (std::holds_alternative<float>(nn))
	{
		return (float)1;
	}
	if (std::holds_alternative<double>(nn))
	{
		return (double)1;
	}

	Report("Number value is invalid.");
	return std::any();
}

std::any Semantic::VisitStringNode(StringNode& stringNode)
{
	return stringNode.value;
}

std::any Semantic::VisitIdentifierNode(IdentifierNode& identifierNode)
{
	try
	{
		std::pair<Variable, Environment> v = this->env_stack.Get(identifierNode.identifier);
		return v.first.value;
	}
	catch (std::invalid_argument e)
	{
		Report(e.what());
	}
	return std::any();
}

std::any Semantic::VisitUnaryNode(UnaryNode& unaryNode)
{
	unaryNode.left->Accept(*this);
	return std::any();
}

std::any Semantic::VisitIfStmtNode(IfStmtNode& ifStmtNode)
{
	return std::any();
}

std::any Semantic::VisitPrintStmt(PrintStmtNode& printStmtNode)
{
	printStmtNode.expression->Accept(*this);
	return std::any();
}

std::any Semantic::VisitVarDeclarationStmt(VarDeclarationNode& varDeclarationNode)
{
	Variable var;
	var.identifier = varDeclarationNode.identifier;
	var.dtType = FromToken_tToDataType(varDeclarationNode.variableType);
	var.value = varDeclarationNode.expression->Accept(*this);
	try
	{
		this->env_stack.Add(var);
	}
	catch (std::invalid_argument e)
	{
		Report(e.what());
	}
	return std::any();
}

std::any Semantic::VisitVarAssignmentStmt(VarAssignmentStmtNode& varAssignmentNode)
{
	varAssignmentNode.expression->Accept(*this);
	try
	{
		return this->env_stack.Get(varAssignmentNode.identifier).first.dtType;
	}
	catch (std::invalid_argument e)
	{
		Report(e.what());
	}
	return std::any();
}

std::any Semantic::VisitFunctionCallNode(FunctionCallExpr& functionCallExpr)
{
	return std::any();
}

std::any Semantic::VisitBlockStmtNode(BlockStmtNode& blockStmtNode)
{
	return std::any();
}

void Semantic::Report(std::string error)
{
	this->errors.push_back(error);
}