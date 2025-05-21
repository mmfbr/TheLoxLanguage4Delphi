// ******************************************************************************
//                                                                               
//               The Lox Language - Abstract Syntax Tree                         
//                                                                               
// ESSE ARQUIVO É GERADO DE FORMA AUTOMATICA PELO PROGRAMA "GenerateApp"         
//                                                                               
// GenerateApp: LoxLanguage.Interpreter.AST.GenerateApp.exe
// Data: 21/05/2025 16:53:50
//                                                                               
// ******************************************************************************

unit LoxLanguage.Interpreter.AST;

interface

uses
  System.Generics.Collections,
  LoxLanguage.Interpreter.Types;

type

  IAstVisitor = interface;

  TAstNode = class
    function Accept(Visitor: IAstVisitor): TLoxValue; virtual; abstract;
  end;

  { TExpressionNode }

  TExpressionNode = class(TAstNode)
  end;

  TAssignExpressionNode = class(TExpressionNode)
  private
    FName: TLoxToken;
    FValue: TExpressionNode;
  public
    constructor Create(Name: TLoxToken; Value: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Name: TLoxToken read FName write FName;
    property Value: TExpressionNode read FValue write FValue;
  end;

  TBinaryExpressionNode = class(TExpressionNode)
  private
    FLeft: TExpressionNode;
    FOperador: TLoxToken;
    FRight: TExpressionNode;
  public
    constructor Create(Left: TExpressionNode; Operador: TLoxToken; Right: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Left: TExpressionNode read FLeft write FLeft;
    property Operador: TLoxToken read FOperador write FOperador;
    property Right: TExpressionNode read FRight write FRight;
  end;

  TCallExpressionNode = class(TExpressionNode)
  private
    FCallee: TExpressionNode;
    FParen: TLoxToken;
    FArguments: TObjectList<TExpressionNode>;
  public
    constructor Create(Callee: TExpressionNode; Paren: TLoxToken; Arguments: TObjectList<TExpressionNode>);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Callee: TExpressionNode read FCallee write FCallee;
    property Paren: TLoxToken read FParen write FParen;
    property Arguments: TObjectList<TExpressionNode> read FArguments write FArguments;
  end;

  TGetExpressionNode = class(TExpressionNode)
  private
    FObj: TExpressionNode;
    FName: TLoxToken;
  public
    constructor Create(Obj: TExpressionNode; Name: TLoxToken);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Obj: TExpressionNode read FObj write FObj;
    property Name: TLoxToken read FName write FName;
  end;

  TGroupingExpressionNode = class(TExpressionNode)
  private
    FExpr: TExpressionNode;
  public
    constructor Create(Expr: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Expr: TExpressionNode read FExpr write FExpr;
  end;

  TLiteralExpressionNode = class(TExpressionNode)
  private
    FValue: TLoxValue;
  public
    constructor Create(Value: TLoxValue);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Value: TLoxValue read FValue write FValue;
  end;

  TLogicalExpressionNode = class(TExpressionNode)
  private
    FLeft: TExpressionNode;
    FOperador: TLoxToken;
    FRight: TExpressionNode;
  public
    constructor Create(Left: TExpressionNode; Operador: TLoxToken; Right: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Left: TExpressionNode read FLeft write FLeft;
    property Operador: TLoxToken read FOperador write FOperador;
    property Right: TExpressionNode read FRight write FRight;
  end;

  TSetExpressionNode = class(TExpressionNode)
  private
    FObj: TExpressionNode;
    FName: TLoxToken;
    FValue: TExpressionNode;
  public
    constructor Create(Obj: TExpressionNode; Name: TLoxToken; Value: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Obj: TExpressionNode read FObj write FObj;
    property Name: TLoxToken read FName write FName;
    property Value: TExpressionNode read FValue write FValue;
  end;

  TSuperExpressionNode = class(TExpressionNode)
  private
    FKeyword: TLoxToken;
    FMethod: TLoxToken;
  public
    constructor Create(Keyword: TLoxToken; Method: TLoxToken);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Keyword: TLoxToken read FKeyword write FKeyword;
    property Method: TLoxToken read FMethod write FMethod;
  end;

  TThisExpressionNode = class(TExpressionNode)
  private
    FKeyword: TLoxToken;
  public
    constructor Create(Keyword: TLoxToken);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Keyword: TLoxToken read FKeyword write FKeyword;
  end;

  TUnaryExpressionNode = class(TExpressionNode)
  private
    FOperador: TLoxToken;
    FRight: TExpressionNode;
  public
    constructor Create(Operador: TLoxToken; Right: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Operador: TLoxToken read FOperador write FOperador;
    property Right: TExpressionNode read FRight write FRight;
  end;

  TVariableExpressionNode = class(TExpressionNode)
  private
    FName: TLoxToken;
  public
    constructor Create(Name: TLoxToken);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Name: TLoxToken read FName write FName;
  end;

  { TStatementNode }

  TStatementNode = class(TAstNode)
  end;

  TBlockStatementNode = class(TStatementNode)
  private
    FStatements: TObjectList<TStatementNode>;
  public
    constructor Create(Statements: TObjectList<TStatementNode>);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Statements: TObjectList<TStatementNode> read FStatements write FStatements;
  end;

  TBreakStatementNode = class(TStatementNode)
  private
  public
    constructor Create();
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
  end;

  TContinueStatementNode = class(TStatementNode)
  private
  public
    constructor Create();
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
  end;

  TExpressionStatementNode = class(TStatementNode)
  private
    FExpression: TExpressionNode;
  public
    constructor Create(Expression: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Expression: TExpressionNode read FExpression write FExpression;
  end;

  TIfStatementNode = class(TStatementNode)
  private
    FCondition: TExpressionNode;
    FThenBranch: TStatementNode;
    FElseBranch: TStatementNode;
  public
    constructor Create(Condition: TExpressionNode; ThenBranch: TStatementNode; ElseBranch: TStatementNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Condition: TExpressionNode read FCondition write FCondition;
    property ThenBranch: TStatementNode read FThenBranch write FThenBranch;
    property ElseBranch: TStatementNode read FElseBranch write FElseBranch;
  end;

  TFunctionStatementNode = class(TStatementNode)
  private
    FName: TLoxToken;
    FParams: TObjectList<TLoxToken>;
    FBody: TObjectList<TStatementNode>;
  public
    constructor Create(Name: TLoxToken; Params: TObjectList<TLoxToken>; Body: TObjectList<TStatementNode>);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Name: TLoxToken read FName write FName;
    property Params: TObjectList<TLoxToken> read FParams write FParams;
    property Body: TObjectList<TStatementNode> read FBody write FBody;
  end;

  TPrintStatementNode = class(TStatementNode)
  private
    FExpr: TExpressionNode;
  public
    constructor Create(Expr: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Expr: TExpressionNode read FExpr write FExpr;
  end;

  TClassStatementNode = class(TStatementNode)
  private
    FName: TLoxToken;
    FSuperClass: TVariableExpressionNode;
    FMethods: TObjectList<TFunctionStatementNode>;
  public
    constructor Create(Name: TLoxToken; SuperClass: TVariableExpressionNode; Methods: TObjectList<TFunctionStatementNode>);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Name: TLoxToken read FName write FName;
    property SuperClass: TVariableExpressionNode read FSuperClass write FSuperClass;
    property Methods: TObjectList<TFunctionStatementNode> read FMethods write FMethods;
  end;

  TReturnStatementNode = class(TStatementNode)
  private
    FKeyword: TLoxToken;
    FValue: TExpressionNode;
  public
    constructor Create(Keyword: TLoxToken; Value: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Keyword: TLoxToken read FKeyword write FKeyword;
    property Value: TExpressionNode read FValue write FValue;
  end;

  TVarStatementNode = class(TStatementNode)
  private
    FName: TLoxToken;
    FInitializer: TExpressionNode;
  public
    constructor Create(Name: TLoxToken; Initializer: TExpressionNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Name: TLoxToken read FName write FName;
    property Initializer: TExpressionNode read FInitializer write FInitializer;
  end;

  TWhileStatementNode = class(TStatementNode)
  private
    FCondition: TExpressionNode;
    FBody: TStatementNode;
  public
    constructor Create(Condition: TExpressionNode; Body: TStatementNode);
    function Accept(Visitor: IAstVisitor): TLoxValue; override; 
    property Condition: TExpressionNode read FCondition write FCondition;
    property Body: TStatementNode read FBody write FBody;
  end;

  IAstVisitor = interface
  ['{E92FFE0B-F01A-4F30-BF88-0C866382851F}']
    function Visit(AssignExpressionNode: TAssignExpressionNode): TLoxValue; overload;
    function Visit(BinaryExpressionNode: TBinaryExpressionNode): TLoxValue; overload;
    function Visit(CallExpressionNode: TCallExpressionNode): TLoxValue; overload;
    function Visit(GetExpressionNode: TGetExpressionNode): TLoxValue; overload;
    function Visit(GroupingExpressionNode: TGroupingExpressionNode): TLoxValue; overload;
    function Visit(LiteralExpressionNode: TLiteralExpressionNode): TLoxValue; overload;
    function Visit(LogicalExpressionNode: TLogicalExpressionNode): TLoxValue; overload;
    function Visit(SetExpressionNode: TSetExpressionNode): TLoxValue; overload;
    function Visit(SuperExpressionNode: TSuperExpressionNode): TLoxValue; overload;
    function Visit(ThisExpressionNode: TThisExpressionNode): TLoxValue; overload;
    function Visit(UnaryExpressionNode: TUnaryExpressionNode): TLoxValue; overload;
    function Visit(VariableExpressionNode: TVariableExpressionNode): TLoxValue; overload;
    function Visit(BlockStatementNode: TBlockStatementNode): TLoxValue; overload;
    function Visit(BreakStatementNode: TBreakStatementNode): TLoxValue; overload;
    function Visit(ContinueStatementNode: TContinueStatementNode): TLoxValue; overload;
    function Visit(ExpressionStatementNode: TExpressionStatementNode): TLoxValue; overload;
    function Visit(IfStatementNode: TIfStatementNode): TLoxValue; overload;
    function Visit(FunctionStatementNode: TFunctionStatementNode): TLoxValue; overload;
    function Visit(PrintStatementNode: TPrintStatementNode): TLoxValue; overload;
    function Visit(ClassStatementNode: TClassStatementNode): TLoxValue; overload;
    function Visit(ReturnStatementNode: TReturnStatementNode): TLoxValue; overload;
    function Visit(VarStatementNode: TVarStatementNode): TLoxValue; overload;
    function Visit(WhileStatementNode: TWhileStatementNode): TLoxValue; overload;
  end;

implementation

  { TExpressionNode }

constructor TAssignExpressionNode.Create(Name: TLoxToken; Value: TExpressionNode);
begin
  FName := Name;
  FValue := Value;
end;

function TAssignExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TBinaryExpressionNode.Create(Left: TExpressionNode; Operador: TLoxToken; Right: TExpressionNode);
begin
  FLeft := Left;
  FOperador := Operador;
  FRight := Right;
end;

function TBinaryExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TCallExpressionNode.Create(Callee: TExpressionNode; Paren: TLoxToken; Arguments: TObjectList<TExpressionNode>);
begin
  FCallee := Callee;
  FParen := Paren;
  FArguments := Arguments;
end;

function TCallExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TGetExpressionNode.Create(Obj: TExpressionNode; Name: TLoxToken);
begin
  FObj := Obj;
  FName := Name;
end;

function TGetExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TGroupingExpressionNode.Create(Expr: TExpressionNode);
begin
  FExpr := Expr;
end;

function TGroupingExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TLiteralExpressionNode.Create(Value: TLoxValue);
begin
  FValue := Value;
end;

function TLiteralExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TLogicalExpressionNode.Create(Left: TExpressionNode; Operador: TLoxToken; Right: TExpressionNode);
begin
  FLeft := Left;
  FOperador := Operador;
  FRight := Right;
end;

function TLogicalExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TSetExpressionNode.Create(Obj: TExpressionNode; Name: TLoxToken; Value: TExpressionNode);
begin
  FObj := Obj;
  FName := Name;
  FValue := Value;
end;

function TSetExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TSuperExpressionNode.Create(Keyword: TLoxToken; Method: TLoxToken);
begin
  FKeyword := Keyword;
  FMethod := Method;
end;

function TSuperExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TThisExpressionNode.Create(Keyword: TLoxToken);
begin
  FKeyword := Keyword;
end;

function TThisExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TUnaryExpressionNode.Create(Operador: TLoxToken; Right: TExpressionNode);
begin
  FOperador := Operador;
  FRight := Right;
end;

function TUnaryExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TVariableExpressionNode.Create(Name: TLoxToken);
begin
  FName := Name;
end;

function TVariableExpressionNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

  { TStatementNode }

constructor TBlockStatementNode.Create(Statements: TObjectList<TStatementNode>);
begin
  FStatements := Statements;
end;

function TBlockStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TBreakStatementNode.Create();
begin
end;

function TBreakStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TContinueStatementNode.Create();
begin
end;

function TContinueStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TExpressionStatementNode.Create(Expression: TExpressionNode);
begin
  FExpression := Expression;
end;

function TExpressionStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TIfStatementNode.Create(Condition: TExpressionNode; ThenBranch: TStatementNode; ElseBranch: TStatementNode);
begin
  FCondition := Condition;
  FThenBranch := ThenBranch;
  FElseBranch := ElseBranch;
end;

function TIfStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TFunctionStatementNode.Create(Name: TLoxToken; Params: TObjectList<TLoxToken>; Body: TObjectList<TStatementNode>);
begin
  FName := Name;
  FParams := Params;
  FBody := Body;
end;

function TFunctionStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TPrintStatementNode.Create(Expr: TExpressionNode);
begin
  FExpr := Expr;
end;

function TPrintStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TClassStatementNode.Create(Name: TLoxToken; SuperClass: TVariableExpressionNode; Methods: TObjectList<TFunctionStatementNode>);
begin
  FName := Name;
  FSuperClass := SuperClass;
  FMethods := Methods;
end;

function TClassStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TReturnStatementNode.Create(Keyword: TLoxToken; Value: TExpressionNode);
begin
  FKeyword := Keyword;
  FValue := Value;
end;

function TReturnStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TVarStatementNode.Create(Name: TLoxToken; Initializer: TExpressionNode);
begin
  FName := Name;
  FInitializer := Initializer;
end;

function TVarStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TWhileStatementNode.Create(Condition: TExpressionNode; Body: TStatementNode);
begin
  FCondition := Condition;
  FBody := Body;
end;

function TWhileStatementNode.Accept(Visitor: IAstVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

end.
