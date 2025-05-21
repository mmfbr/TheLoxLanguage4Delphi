// Marcello Mello
// 02/10/2019

unit LoxLanguage.Interpreter.Resolver;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  VCL.Dialogs,
  LoxLanguage.Interpreter.AST,
  LoxLanguage.Interpreter,
  LoxLanguage.Interpreter.Types;

type

  TOnResolverErrorEvent = procedure(Token: TLoxToken; Msg: string) of object;

  EResolverError = class(Exception)
  end;

  TResolverVisitor = class(TInterfacedObject, IAstVisitor)
  private
    FCurrentClass: TLoxClassType;
    FInterpreter: TAstInterpreterVisitor;
    FCurrentFunction: TLoxFunctionType;
    FScopes: TObjectStack<TDictionary<string, Boolean>>;
    FOnError: TOnResolverErrorEvent;
    procedure BeginScope;
    procedure Resolve(Expr: TExpressionNode); overload;
    procedure Resolve(Statement: TStatementNode); overload;
    procedure EndScope();
    procedure Declare(Name: TLoxToken);
    procedure Define(Name: TLoxToken);
    function Error(Token: TLoxToken; Msg: string): EResolverError;
    procedure ResolveLocal(Expr: TExpressionNode; Name: TLoxToken);
    procedure ResolveFunction(FunctionStatement: TFunctionStatementNode; FunctionType: TLoxFunctionType);
  private
    function Visit(AssignExpression: TAssignExpressionNode): TLoxValue; overload;
    function Visit(BinaryExpression: TBinaryExpressionNode): TLoxValue; overload;
    function Visit(CallExpression: TCallExpressionNode): TLoxValue; overload;
    function Visit(GetExpression: TGetExpressionNode): TLoxValue; overload;
    function Visit(GroupingExpression: TGroupingExpressionNode): TLoxValue; overload;
    function Visit(LiteralExpression: TLiteralExpressionNode): TLoxValue; overload;
    function Visit(LogicalExpression: TLogicalExpressionNode): TLoxValue; overload;
    function Visit(SetExpression: TSetExpressionNode): TLoxValue; overload;
    function Visit(SuperExpression: TSuperExpressionNode): TLoxValue; overload;
    function Visit(ThisExpression: TThisExpressionNode): TLoxValue; overload;
    function Visit(UnaryExpression: TUnaryExpressionNode): TLoxValue; overload;
    function Visit(VariableExpression: TVariableExpressionNode): TLoxValue; overload;
    function Visit(BlockStatement: TBlockStatementNode): TLoxValue; overload;
    function Visit(BreakStatement: TBreakStatementNode): TLoxValue; overload;
    function Visit(ContinueStatement: TContinueStatementNode): TLoxValue; overload;
    function Visit(ExpressionStatement: TExpressionStatementNode): TLoxValue; overload;
    function Visit(IfStatement: TIfStatementNode): TLoxValue; overload;
    function Visit(FunctionStatement: TFunctionStatementNode): TLoxValue; overload;
    function Visit(PrintStatement: TPrintStatementNode): TLoxValue; overload;
    function Visit(ClassStatement: TClassStatementNode): TLoxValue; overload;
    function Visit(ReturnStatement: TReturnStatementNode): TLoxValue; overload;
    function Visit(VarStatement: TVarStatementNode): TLoxValue; overload;
    function Visit(WhileStatement: TWhileStatementNode): TLoxValue; overload;
  public
    constructor Create(Interpreter: TAstInterpreterVisitor);
    destructor Destroy; override;
    procedure Resolve(Statements: TObjectList<TStatementNode>); overload;
    property OnError: TOnResolverErrorEvent read FOnError write FOnError;
  end;

implementation

{ TResolverVisitor }

function TResolverVisitor.Visit(LiteralExpression: TLiteralExpressionNode): TLoxValue;
begin
  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(LogicalExpression: TLogicalExpressionNode): TLoxValue;
begin
  Resolve(LogicalExpression.Left);
  Resolve(LogicalExpression.Right);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(UnaryExpression: TUnaryExpressionNode): TLoxValue;
begin
  Resolve(UnaryExpression.Right);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Error(Token: TLoxToken; Msg: string): EResolverError;
begin
  if Assigned(OnError) then
    OnError(Token, Msg);

  Result := EResolverError.Create(Msg);
end;

function TResolverVisitor.Visit(VariableExpression: TVariableExpressionNode): TLoxValue;
begin
  if (not FScopes.Count = 0) and (FScopes.peek()[VariableExpression.Name.Lexeme] = False) then
    Error(VariableExpression.Name, 'Não é possível ler a variável local em seu próprio inicializador.');

  ResolveLocal(VariableExpression, VariableExpression.Name);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

procedure TResolverVisitor.ResolveLocal(Expr: TExpressionNode; Name: TLoxToken);
var
  i: Integer;
begin

  for i := FScopes.Count - 1 downto 0 do
  begin
    if FScopes.List[i].ContainsKey(Name.Lexeme) then
    begin
      FInterpreter.Resolve(Expr, FScopes.Count - 1 - i);
      Exit();
    end;
  end;

  // Não encontrado. Suponha que seja global.
end;

function TResolverVisitor.Visit(AssignExpression: TAssignExpressionNode): TLoxValue;
begin
  Resolve(AssignExpression.value);
  ResolveLocal(AssignExpression, AssignExpression.name);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(BinaryExpression: TBinaryExpressionNode): TLoxValue;
begin
  Resolve(BinaryExpression.Left);
  Resolve(BinaryExpression.Right);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(CallExpression: TCallExpressionNode): TLoxValue;
var
  Argument: TExpressionNode;
begin
  Resolve(CallExpression.Callee);

  for Argument in CallExpression.Arguments do
    Resolve(Argument);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(GroupingExpression: TGroupingExpressionNode): TLoxValue;
begin
  Resolve(GroupingExpression.Expr);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(PrintStatement: TPrintStatementNode): TLoxValue;
begin
  Resolve(PrintStatement.Expr);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(ReturnStatement: TReturnStatementNode): TLoxValue;
begin
  if (FCurrentFunction = TLoxFunctionType.NONE) then
    Error(ReturnStatement.Keyword, 'Não é possível retornar do código de nível superior.');


  if Assigned(ReturnStatement.Value) then
  begin
    if (FCurrentFunction = TLoxFunctionType.INITIALIZER) then
      Error(ReturnStatement.Keyword, 'Não é possível retornar um valor de um inicializador.');

    Resolve(ReturnStatement.Value);
  end;

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

procedure TResolverVisitor.Declare(Name: TLoxToken);
var
  Scope: TDictionary<string, Boolean>;
begin
  if (FScopes.Count = 0) then
    Exit();

  Scope := FScopes.Peek();

  if Scope.ContainsKey(Name.lexeme) then
    Error(name, 'Variável com este nome já declarada neste escopo.');

  Scope.Add(Name.Lexeme, False);
end;

procedure TResolverVisitor.Define(Name: TLoxToken);
var
  Scope: TDictionary<string, Boolean>;
begin
  if (FScopes.Count = 0) then
    Exit();

  Scope := FScopes.Peek();
  Scope.AddOrSetValue(Name.Lexeme, True);
end;

function TResolverVisitor.Visit(VarStatement: TVarStatementNode): TLoxValue;
begin
  Declare(VarStatement.Name);

  if Assigned(VarStatement.initializer) then
    Resolve(VarStatement.Initializer);

  Define(VarStatement.name);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

constructor TResolverVisitor.Create(Interpreter: TAstInterpreterVisitor);
begin
  FCurrentFunction := TLoxFunctionType.NONE;
  FCurrentClass := TLoxClassType.NONE;
  FScopes := TObjectStack<TDictionary<string, Boolean>>.Create();
  FInterpreter := Interpreter;
end;

destructor TResolverVisitor.Destroy;
begin
  FScopes.Free();

  inherited;
end;

function TResolverVisitor.Visit(WhileStatement: TWhileStatementNode): TLoxValue;
begin
  Resolve(WhileStatement.Condition);
  Resolve(WhileStatement.Body);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(ContinueStatement: TContinueStatementNode): TLoxValue;
begin
  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(BreakStatement: TBreakStatementNode): TLoxValue;
begin
  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(SuperExpression: TSuperExpressionNode): TLoxValue;
begin
  if (FCurrentClass = TLoxClassType.NONE) then
    Error(SuperExpression.Keyword, 'Não é possível usar "super" fora de uma classe.')
  else if not (FCurrentClass = TLoxClassType.SUBCLASS) then
    Error(SuperExpression.Keyword, 'Não é possível usar "super" em uma classe sem superclasse.');

  ResolveLocal(SuperExpression, SuperExpression.Keyword);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(ThisExpression: TThisExpressionNode): TLoxValue;
begin
  if (FCurrentClass = TLoxClassType.NONE) then
  begin
    Error(ThisExpression.Keyword, 'Não é possível usar "this" fora de uma classe.');

    Result := Default(TLoxValue);
    Result.ValueType := TLoxValueType.IS_NULL;
    Exit();
  end;

  ResolveLocal(ThisExpression, ThisExpression.Keyword);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(SetExpression: TSetExpressionNode): TLoxValue;
begin
  Resolve(SetExpression.Value);
  Resolve(SetExpression.Obj);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(GetExpression: TGetExpressionNode): TLoxValue;
begin
  Resolve(GetExpression.Obj);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(ClassStatement: TClassStatementNode): TLoxValue;
var
  Method: TFunctionStatementNode;
  Declaration: TLoxFunctionType;
  EnclosingClass: TLoxClassType;
begin
  EnclosingClass := FCurrentClass;
  FCurrentClass := TLoxClassType.CLASS;

  Declare(ClassStatement.Name);
  Define(ClassStatement.Name);

  if Assigned(ClassStatement.SuperClass) and (ClassStatement.Name.Lexeme = ClassStatement.SuperClass.Name.Lexeme) then
    Error(ClassStatement.Superclass.Name, 'Uma classe não pode herdar de si mesma.');

  if Assigned(ClassStatement.Superclass) then
  begin
    FCurrentClass := TLoxClassType.SUBCLASS;
    Resolve(ClassStatement.SuperClass);
  end;

  if Assigned(ClassStatement.Superclass) then
  begin
    BeginScope();
    FScopes.Peek().Add('super', True);
  end;

  BeginScope();
  FScopes.Peek().Add('this', True);

  for Method in ClassStatement.Methods do
  begin
    Declaration := TLoxFunctionType.METHOD;

    if (Method.Name.Lexeme = 'init') then
      Declaration := TLoxFunctionType.INITIALIZER;

    ResolveFunction(Method, Declaration);
  end;


  EndScope();

  if Assigned(ClassStatement.SuperClass) then
    EndScope();

  FCurrentClass := EnclosingClass;

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

procedure TResolverVisitor.EndScope();
begin
  FScopes.Pop();
end;

procedure TResolverVisitor.Resolve(Expr: TExpressionNode);
begin
  Expr.Accept(Self);
end;

procedure TResolverVisitor.Resolve(Statement: TStatementNode);
begin
  Statement.Accept(Self);
end;

function TResolverVisitor.Visit(BlockStatement: TBlockStatementNode): TLoxValue;
begin
  BeginScope();
  Resolve(BlockStatement.Statements);
  EndScope();

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

procedure TResolverVisitor.Resolve(Statements: TObjectList<TStatementNode>);
var
  Statement: TStatementNode;
begin
  for Statement in Statements do
    Resolve(Statement);
end;

procedure TResolverVisitor.BeginScope;
var
  Item: TDictionary<string, Boolean>;
begin
  Item := TDictionary<string, Boolean>.Create();
  FScopes.Push(Item);
end;

function TResolverVisitor.Visit(ExpressionStatement: TExpressionStatementNode): TLoxValue;
begin
  Resolve(ExpressionStatement.Expression);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(IfStatement: TIfStatementNode): TLoxValue;
begin
  Resolve(IfStatement.Condition);
  Resolve(IfStatement.ThenBranch);

  if Assigned(IfStatement.ElseBranch) then
    Resolve(IfStatement.ElseBranch);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

function TResolverVisitor.Visit(FunctionStatement: TFunctionStatementNode): TLoxValue;
begin
  Declare(FunctionStatement.name);
  Define(FunctionStatement.name);

  ResolveFunction(FunctionStatement, TLoxFunctionType.FUNCTION);

  Result := Default(TLoxValue);
  Result.ValueType := TLoxValueType.IS_NULL;
end;

procedure TResolverVisitor.ResolveFunction(FunctionStatement: TFunctionStatementNode; FunctionType: TLoxFunctionType);
var
  Param: TLoxToken;
  EnclosingFunction: TLoxFunctionType;
begin

  EnclosingFunction := FCurrentFunction;
  FCurrentFunction := FunctionType;
  try
    BeginScope();

    for Param in FunctionStatement.Params do
    begin
      Declare(Param);
      Define(Param);
    end;

    Resolve(FunctionStatement.Body);
    EndScope();

  finally
    FCurrentFunction := EnclosingFunction;
  end;

end;

end.
