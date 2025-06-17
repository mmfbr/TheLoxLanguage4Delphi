

#include "traverse_ast.hpp"
#include "token.hpp"

#include "ast_node_headers.hpp"


#pragma execution_character_set( "utf-8" )


// ├───
// ────  // 4 characters
// └───

std::string tab = "|";

void AddSpaceTab()
{
    tab += "   ";
}

void DeleteSpaceTab()
{
    if (tab.size() < 4)
    {
        return;
    }
    tab = tab.substr(0, tab.size() - 4);
}

void Traverser::Traverse(std::unique_ptr<AstNode>& statement)
{
    statement->Accept(*this);
}

std::any Traverser::VisitFunctionCallNode(FunctionCallExpr& functionCallExpr)
{
    std::cout << tab + "FunctionCallExprNode (" + functionCallExpr.identifier + ")" << std::endl;
    std::cout << tab + "└─── Arguments" << std::endl;
    AddSpaceTab();
    for (auto& arg : functionCallExpr.arguments)
    {
        arg->Accept(*this);
    }
    DeleteSpaceTab();
    return std::any();
}

std::any Traverser::VisitBlockStmtNode(BlockStmtNode& blockStmtNode)
{
    std::cout << tab + "BlockStatementNode" << std::endl;
    size_t stmt_counter = 0;
    for (auto& stmt : blockStmtNode.stmts)
    {
        if (blockStmtNode.stmts.size() == stmt_counter - 1)
        {
            std::cout << tab + "└───";
        }
        else
        {
            std::cout << tab + "├───";
        }
        stmt_counter++;
        stmt->Accept(*this);
        std::cout << std::endl;
    }
    return std::any();
}

std::any Traverser::VisitBinaryExpression(BinaryExpression& binaryExpression)
{
    std::cout << tab + "BinaryExpressionNode (" + TokenName(binaryExpression.op) + ")" << std::endl;

    std::string character = "├─── ";
    if (binaryExpression.right == nullptr)
    {
        character = "└─── ";
    }
    std::cout << tab + character;
    AddSpaceTab();
    binaryExpression.left->Accept(*this);
    DeleteSpaceTab();
    std::cout << tab + "└─── ";
    AddSpaceTab();
    binaryExpression.right->Accept(*this);
    DeleteSpaceTab();
    return std::any();
}

std::any Traverser::VisitBoolNode(BoolNode& boolNode)
{
    std::cout << tab + "BoolNode" << std::endl;
    return std::any();
}

std::any Traverser::VisitNumberNode(NumberNode& numberNode)
{
    std::cout << tab + "NumberNode" << std::endl;
    return std::any();
}

std::any Traverser::VisitStringNode(StringNode& stringNode)
{
    std::cout << tab + "StringNode" << std::endl;
    return std::any();
}

std::any Traverser::VisitIdentifierNode(IdentifierNode& identifierNode)
{
    std::cout << tab + "IdentifierNode" << std::endl;
    return std::any();
}

std::any Traverser::VisitUnaryNode(UnaryNode& unaryNode)
{
    std::cout << tab + "UnaryNode" << std::endl;
    return std::any();
}

std::any Traverser::VisitIfStmtNode(IfStmtNode& ifStmtNode)
{
    std::cout << tab + "IfStatmentNode" << std::endl;
    std::cout << tab + "├───";
    AddSpaceTab();
    ifStmtNode.expression->Accept(*this);
    DeleteSpaceTab();
    std::cout << tab + "└───";
    AddSpaceTab();
    ifStmtNode.blockStmt->Accept(*this);
    DeleteSpaceTab();
    return std::any();
}

std::any Traverser::VisitPrintStmt(PrintStmtNode& printStmtNode)
{
    std::cout << tab + "PrintStatementNode" << std::endl;
    std::cout << tab + "└───";
    AddSpaceTab();
    printStmtNode.expression->Accept(*this);
    DeleteSpaceTab();
    return std::any();
}

std::any Traverser::VisitVarDeclarationStmt(VarDeclarationNode& varDeclarationNode)
{
    std::cout << tab + "VarDeclarationNode";
    return std::any();
}

std::any Traverser::VisitVarAssignmentStmt(VarAssignmentStmtNode& varAssignmentNode)
{
    std::cout << tab + "VarAssignmentNode";
    return std::any();
}