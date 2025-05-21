// ******************************************************************************
//                                                                               
//               The Lox Language - Abstract Syntax Tree                         
//                                                                               
// ESSE ARQUIVO É GERADO DE FORMA AUTOMATICA PELO PROGRAMA "GenerateApp.exe"     
//                                                                               
// GenerateApp: LoxLanguage.Interpreter.AST.GenerateApp.exe
// Data: 21/05/2025 07:20:51
//                                                                               
// ******************************************************************************

unit LoxLanguage.Interpreter.AST;

interface

uses
  System.Generics.Collections,
  LoxLanguage.Interpreter.Types;

type

  IVisitor = interface;

  TASTNode = class
    function Accept(Visitor: IVisitor): TLoxValue; virtual; abstract;
  end;

  { TExpressionNode }

  TExpressionNode = class(TASTNode)
  end;

  TAssignExpressionNode = class(TExpressionNode)
  private
    FName: TToken;
    FValue: TExpressionNode;
  public
    constructor Create(Name: TToken; Value: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Name: TToken read FName write FName;
    property Value: TExpressionNode read FValue write FValue;
  end;

  TBinaryExpressionNode = class(TExpressionNode)
  private
    FLeft: TExpressionNode;
    FOperador: TToken;
    FRight: TExpressionNode;
  public
    constructor Create(Left: TExpressionNode; Operador: TToken; Right: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Left: TExpressionNode read FLeft write FLeft;
    property Operador: TToken read FOperador write FOperador;
    property Right: TExpressionNode read FRight write FRight;
  end;

  TCallExpressionNode = class(TExpressionNode)
  private
    FCallee: TExpressionNode;
    FParen: TToken;
    FArguments: TObjectList<TExpressionNode>;
  public
    constructor Create(Callee: TExpressionNode; Paren: TToken; Arguments: TObjectList<TExpressionNode>);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Callee: TExpressionNode read FCallee write FCallee;
    property Paren: TToken read FParen write FParen;
    property Arguments: TObjectList<TExpressionNode> read FArguments write FArguments;
  end;

  TGetExpressionNode = class(TExpressionNode)
  private
    FObj: TExpressionNode;
    FName: TToken;
  public
    constructor Create(Obj: TExpressionNode; Name: TToken);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Obj: TExpressionNode read FObj write FObj;
    property Name: TToken read FName write FName;
  end;

  TGroupingExpressionNode = class(TExpressionNode)
  private
    FExpr: TExpressionNode;
  public
    constructor Create(Expr: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Expr: TExpressionNode read FExpr write FExpr;
  end;

  TLiteralExpressionNode = class(TExpressionNode)
  private
    FValue: TLoxValue;
  public
    constructor Create(Value: TLoxValue);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Value: TLoxValue read FValue write FValue;
  end;

  TLogicalExpressionNode = class(TExpressionNode)
  private
    FLeft: TExpressionNode;
    FOperador: TToken;
    FRight: TExpressionNode;
  public
    constructor Create(Left: TExpressionNode; Operador: TToken; Right: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Left: TExpressionNode read FLeft write FLeft;
    property Operador: TToken read FOperador write FOperador;
    property Right: TExpressionNode read FRight write FRight;
  end;

  TSetExpressionNode = class(TExpressionNode)
  private
    FObj: TExpressionNode;
    FName: TToken;
    FValue: TExpressionNode;
  public
    constructor Create(Obj: TExpressionNode; Name: TToken; Value: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Obj: TExpressionNode read FObj write FObj;
    property Name: TToken read FName write FName;
    property Value: TExpressionNode read FValue write FValue;
  end;

  TSuperExpressionNode = class(TExpressionNode)
  private
    FKeyword: TToken;
    FMethod: TToken;
  public
    constructor Create(Keyword: TToken; Method: TToken);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Keyword: TToken read FKeyword write FKeyword;
    property Method: TToken read FMethod write FMethod;
  end;

  TThisExpressionNode = class(TExpressionNode)
  private
    FKeyword: TToken;
  public
    constructor Create(Keyword: TToken);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Keyword: TToken read FKeyword write FKeyword;
  end;

  TUnaryExpressionNode = class(TExpressionNode)
  private
    FOperador: TToken;
    FRight: TExpressionNode;
  public
    constructor Create(Operador: TToken; Right: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Operador: TToken read FOperador write FOperador;
    property Right: TExpressionNode read FRight write FRight;
  end;

  TVariableExpressionNode = class(TExpressionNode)
  private
    FName: TToken;
  public
    constructor Create(Name: TToken);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Name: TToken read FName write FName;
  end;

  { TStatementNode }

  TStatementNode = class(TASTNode)
  end;

  TBlockStatementNode = class(TStatementNode)
  private
    FStatements: TObjectList<TStatementNode>;
  public
    constructor Create(Statements: TObjectList<TStatementNode>);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Statements: TObjectList<TStatementNode> read FStatements write FStatements;
  end;

  TBreakStatementNode = class(TStatementNode)
  private
  public
    constructor Create();
    function Accept(Visitor: IVisitor): TLoxValue; override; 
  end;

  TContinueStatementNode = class(TStatementNode)
  private
  public
    constructor Create();
    function Accept(Visitor: IVisitor): TLoxValue; override; 
  end;

  TExpressionStatementNode = class(TStatementNode)
  private
    FExpression: TExpressionNode;
  public
    constructor Create(Expression: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Expression: TExpressionNode read FExpression write FExpression;
  end;

  TIfStatementNode = class(TStatementNode)
  private
    FCondition: TExpressionNode;
    FThenBranch: TStatementNode;
    FElseBranch: TStatementNode;
  public
    constructor Create(Condition: TExpressionNode; ThenBranch: TStatementNode; ElseBranch: TStatementNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Condition: TExpressionNode read FCondition write FCondition;
    property ThenBranch: TStatementNode read FThenBranch write FThenBranch;
    property ElseBranch: TStatementNode read FElseBranch write FElseBranch;
  end;

  TFunctionStatementNode = class(TStatementNode)
  private
    FName: TToken;
    FParams: TObjectList<TToken>;
    FBody: TObjectList<TStatementNode>;
  public
    constructor Create(Name: TToken; Params: TObjectList<TToken>; Body: TObjectList<TStatementNode>);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Name: TToken read FName write FName;
    property Params: TObjectList<TToken> read FParams write FParams;
    property Body: TObjectList<TStatementNode> read FBody write FBody;
  end;

  TPrintStatementNode = class(TStatementNode)
  private
    FExpr: TExpressionNode;
  public
    constructor Create(Expr: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Expr: TExpressionNode read FExpr write FExpr;
  end;

  TClassStatementNode = class(TStatementNode)
  private
    FName: TToken;
    FSuperClass: TVariableExpressionNode;
    FMethods: TObjectList<TFunctionStatementNode>;
  public
    constructor Create(Name: TToken; SuperClass: TVariableExpressionNode; Methods: TObjectList<TFunctionStatementNode>);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Name: TToken read FName write FName;
    property SuperClass: TVariableExpressionNode read FSuperClass write FSuperClass;
    property Methods: TObjectList<TFunctionStatementNode> read FMethods write FMethods;
  end;

  TReturnStatementNode = class(TStatementNode)
  private
    FKeyword: TToken;
    FValue: TExpressionNode;
  public
    constructor Create(Keyword: TToken; Value: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Keyword: TToken read FKeyword write FKeyword;
    property Value: TExpressionNode read FValue write FValue;
  end;

  TVarStatementNode = class(TStatementNode)
  private
    FName: TToken;
    FInitializer: TExpressionNode;
  public
    constructor Create(Name: TToken; Initializer: TExpressionNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Name: TToken read FName write FName;
    property Initializer: TExpressionNode read FInitializer write FInitializer;
  end;

  TWhileStatementNode = class(TStatementNode)
  private
    FCondition: TExpressionNode;
    FBody: TStatementNode;
  public
    constructor Create(Condition: TExpressionNode; Body: TStatementNode);
    function Accept(Visitor: IVisitor): TLoxValue; override; 
    property Condition: TExpressionNode read FCondition write FCondition;
    property Body: TStatementNode read FBody write FBody;
  end;

  IVisitor = interface
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

constructor TAssignExpressionNode.Create(Name: TToken; Value: TExpressionNode);
begin
  FName := Name;
  FValue := Value;
end;

function TAssignExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TBinaryExpressionNode.Create(Left: TExpressionNode; Operador: TToken; Right: TExpressionNode);
begin
  FLeft := Left;
  FOperador := Operador;
  FRight := Right;
end;

function TBinaryExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TCallExpressionNode.Create(Callee: TExpressionNode; Paren: TToken; Arguments: TObjectList<TExpressionNode>);
begin
  FCallee := Callee;
  FParen := Paren;
  FArguments := Arguments;
end;

function TCallExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TGetExpressionNode.Create(Obj: TExpressionNode; Name: TToken);
begin
  FObj := Obj;
  FName := Name;
end;

function TGetExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TGroupingExpressionNode.Create(Expr: TExpressionNode);
begin
  FExpr := Expr;
end;

function TGroupingExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TLiteralExpressionNode.Create(Value: TLoxValue);
begin
  FValue := Value;
end;

function TLiteralExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TLogicalExpressionNode.Create(Left: TExpressionNode; Operador: TToken; Right: TExpressionNode);
begin
  FLeft := Left;
  FOperador := Operador;
  FRight := Right;
end;

function TLogicalExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TSetExpressionNode.Create(Obj: TExpressionNode; Name: TToken; Value: TExpressionNode);
begin
  FObj := Obj;
  FName := Name;
  FValue := Value;
end;

function TSetExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TSuperExpressionNode.Create(Keyword: TToken; Method: TToken);
begin
  FKeyword := Keyword;
  FMethod := Method;
end;

function TSuperExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TThisExpressionNode.Create(Keyword: TToken);
begin
  FKeyword := Keyword;
end;

function TThisExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TUnaryExpressionNode.Create(Operador: TToken; Right: TExpressionNode);
begin
  FOperador := Operador;
  FRight := Right;
end;

function TUnaryExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TVariableExpressionNode.Create(Name: TToken);
begin
  FName := Name;
end;

function TVariableExpressionNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

  { TStatementNode }

constructor TBlockStatementNode.Create(Statements: TObjectList<TStatementNode>);
begin
  FStatements := Statements;
end;

function TBlockStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TBreakStatementNode.Create();
begin
end;

function TBreakStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TContinueStatementNode.Create();
begin
end;

function TContinueStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TExpressionStatementNode.Create(Expression: TExpressionNode);
begin
  FExpression := Expression;
end;

function TExpressionStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TIfStatementNode.Create(Condition: TExpressionNode; ThenBranch: TStatementNode; ElseBranch: TStatementNode);
begin
  FCondition := Condition;
  FThenBranch := ThenBranch;
  FElseBranch := ElseBranch;
end;

function TIfStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TFunctionStatementNode.Create(Name: TToken; Params: TObjectList<TToken>; Body: TObjectList<TStatementNode>);
begin
  FName := Name;
  FParams := Params;
  FBody := Body;
end;

function TFunctionStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TPrintStatementNode.Create(Expr: TExpressionNode);
begin
  FExpr := Expr;
end;

function TPrintStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TClassStatementNode.Create(Name: TToken; SuperClass: TVariableExpressionNode; Methods: TObjectList<TFunctionStatementNode>);
begin
  FName := Name;
  FSuperClass := SuperClass;
  FMethods := Methods;
end;

function TClassStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TReturnStatementNode.Create(Keyword: TToken; Value: TExpressionNode);
begin
  FKeyword := Keyword;
  FValue := Value;
end;

function TReturnStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TVarStatementNode.Create(Name: TToken; Initializer: TExpressionNode);
begin
  FName := Name;
  FInitializer := Initializer;
end;

function TVarStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

constructor TWhileStatementNode.Create(Condition: TExpressionNode; Body: TStatementNode);
begin
  FCondition := Condition;
  FBody := Body;
end;

function TWhileStatementNode.Accept(Visitor: IVisitor): TLoxValue; 
begin
  Result := Visitor.Visit(Self);
end;

end.
