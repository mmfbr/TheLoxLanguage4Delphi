// Marcello Mello
// 28/09/2019

unit LoxLanguage.Interpreter.Parser;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  LoxLanguage.Interpreter.Types,
  LoxLanguage.Interpreter.AST;

type

  TOnParserErrorEvent = procedure(Token: TToken; Msg: string) of object;

  EParseError = class(Exception)
  end;

  TParser = class
  private
    FLoopDepth: Integer;
    FOnError: TOnParserErrorEvent;
    FTokens: TObjectList<TToken>;
    FCurrent: Integer;
    function Expression(): TExpressionNode;
    function Assignment(): TExpressionNode;
    function LogicalOr(): TExpressionNode;
    function LogicalAnd(): TExpressionNode;
    function Unary(): TExpressionNode;
    function Call(): TExpressionNode;
    function FinishCall(Callee: TExpressionNode): TExpressionNode;
    function Addition(): TExpressionNode;
    function Multiplication(): TExpressionNode;
    function Equality(): TExpressionNode;
    function Primary(): TExpressionNode;
    function Match(TokenType: TTokenType): Boolean; overload;
    function Match(TokenTypeA, TokenTypeB: TTokenType): Boolean; overload;
    function Match(TokenTypes: array of TTokenType): Boolean; overload;
    function Check(TokenType: TTokenType): Boolean;
    function Consume(TokenType: TTokenType; Msg: string): TToken;
    function Error(Token: TToken; Msg: string): EParseError;
    function Comparison(): TExpressionNode;
    function AdvanceToken(): TToken;
    function Previous(): TToken;
    function IsAtEnd(): Boolean;
    function Peek(): TToken;
    procedure Synchronize();
    function Statement(): TStatementNode;
    function BreakStatement(): TStatementNode;
    function DoStatement(): TStatementNode;
    function ContinueStatement(): TStatementNode;
    function ReturnStatement(): TStatementNode;
    function ForStatement(): TStatementNode;
    function WhileStatement(): TStatementNode;
    function ifStatement(): TStatementNode;
    function Declaration(): TStatementNode;
    function ClassDeclaration(): TStatementNode;
    function FunctionDeclaration(Kind: string): TFunctionStatementNode;
    function VarDeclaration(): TStatementNode;
    function ExpressionStatement(): TStatementNode;
    function Block(): TObjectList<TStatementNode>;
    function PrintStatement(): TStatementNode;
  public
    constructor Create(Tokens: TObjectList<TToken>);
    function Parse(): TObjectList<TStatementNode>;
    property OnError: TOnParserErrorEvent read FOnError write FOnError;
  end;

implementation

{ TParser }

constructor TParser.Create(Tokens: TObjectList<TToken>);
begin
  FLoopDepth := 0;
  FCurrent := 0;
  FTokens := Tokens;
end;

function TParser.Expression(): TExpressionNode;
begin
  Result := Assignment();
end;

function TParser.Assignment(): TExpressionNode;
var
  Expr: TExpressionNode;
  Get: TGetExpressionNode;
  Equals: TToken;
  Value: TExpressionNode;
  Name: TToken;
begin
  Expr := LogicalOr();

  if Match(TTokenType.EQUAL) then
  begin
    Equals := Previous();
    Value := Assignment();

    if Expr is TVariableExpressionNode then
    begin
      Name := TVariableExpressionNode(Expr).Name;
      Exit(TAssignExpressionNode.Create(name, value));
    end
    else if (Expr is TGetExpressionNode) then
    begin
      Get := TGetExpressionNode(Expr);
      Exit(TSetExpressionNode.Create(Get.Obj, Get.Name, Value));
    end;

    Error(Equals, 'Destino de atribuição inválido.');
  end;

  Result := Expr;
end;

function TParser.LogicalOr(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TToken;
begin
  Expr := LogicalAnd();

  while Match(TTokenType.OR) do
  begin
    Oper := Previous();
    Right := LogicalAnd();
    Expr := TLogicalExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.LogicalAnd(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TToken;
begin
  Expr := Equality();

  while Match(TTokenType.AND) do
  begin
    Oper := Previous();
    Right := equality();
    Expr := TLogicalExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.Unary(): TExpressionNode;
var
  Right: TExpressionNode;
  Oper: TToken;
begin

  if Match([TTokenType.BANG, TTokenType.MINUS]) then
  begin
    Oper := Previous();
    Right := Unary();
    Exit(TUnaryExpressionNode.Create(Oper, Right));
  end;

  Result := Call();
end;

function TParser.Call(): TExpressionNode;
var
  Expr: TExpressionNode;
  Name: TToken;
begin
  Expr := Primary();

  while True do
  begin
    if Match(TTokenType.LEFT_PAREN) then
      Expr := FinishCall(Expr)
    else if Match(TTokenType.DOT) then
    begin
      Name := Consume(TTokenType.IDENTIFIER, 'Espere o nome da propriedade depois "."');
      Expr := TGetExpressionNode.Create(Expr, Name);
    end
    else
      Break;
  end;

  Result := Expr;
end;

function TParser.FinishCall(Callee: TExpressionNode): TExpressionNode;
var
  Arguments: TObjectList<TExpressionNode>;
  Paren: TToken;
begin
  Arguments := TObjectList<TExpressionNode>.Create();

  if not Check(TTokenType.RIGHT_PAREN) then
  begin
    repeat
      if (Arguments.Count >= 255) then
        Error(Peek(), 'Não pode ter mais de 255 argumentos.');

      Arguments.Add(Expression());
    until not Match(TTokenType.COMMA);
  end;

  Paren := Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" após argumentos.');

  Result := TCallExpressionNode.Create(Callee, Paren, Arguments);
end;

function TParser.Primary(): TExpressionNode;
var
  Expr: TExpressionNode;
  Value: TLoxValue;
  Keyword,
  Method: TToken;
begin

  if (Match(TTokenType.FALSE)) then
  begin
    Value.ValueType := TLoxValueType.IS_BOOLEAN;
    Value.BooleanValue := False;
    Result := TLiteralExpressionNode.Create(Value);
    Exit();
  end;

  if (Match(TTokenType.TRUE)) then
  begin
    Value.ValueType := TLoxValueType.IS_BOOLEAN;
    Value.BooleanValue := True;
    Result := TLiteralExpressionNode.Create(Value);
    Exit();
  end;

  if Match(TTokenType.NIL) then
  begin
    Value.ValueType := TLoxValueType.IS_NULL;
    Result := TLiteralExpressionNode.Create(Value);
    Exit();
  end;

  if Match(TTokenType.NUMBER, TTokenType.STRING) then
  begin
    Result := TLiteralExpressionNode.Create(Previous().Literal);
    Exit();
  end;

  if Match(TTokenType.SUPER) then
  begin
    Keyword := Previous();
    Consume(TTokenType.DOT, 'Esperado "." depois de "super".');
    Method := Consume(TTokenType.IDENTIFIER, 'Espere o nome do método da superclasse.');
    Result := TSuperExpressionNode.Create(Keyword, Method);
    Exit();
  end;

  if Match(TTokenType.THIS) then
  begin
    Result := TThisExpressionNode.Create(Previous());
    Exit();
  end;

  if Match(TTokenType.IDENTIFIER) then
  begin
    Result := TVariableExpressionNode.Create(Previous());
    Exit();
  end;

  if (Match(TTokenType.LEFT_PAREN)) then
  begin
    Expr := Expression();
    Consume(TTokenType.RIGHT_PAREN, 'Esperado um ")" após a expressão.');
    Exit(TGroupingExpressionNode.Create(Expr));
  end;

  raise Error(Peek(), 'Esperado expressão.');
end;

function TParser.Consume(TokenType: TTokenType; Msg: string): TToken;
begin
  if (Check(TokenType)) then
    Exit(AdvanceToken());

  raise Error(Peek(), Msg);
end;

function TParser.ContinueStatement(): TStatementNode;
begin
  if (FLoopDepth = 0) then
    Error(Previous(), 'Cannot use "continue" outside of a loop.');

  Consume(TTokenType.SEMICOLON, 'Expect ";" after continue.');

  Result := TContinueStatementNode.Create();
end;

function TParser.Error(Token: TToken; Msg: string): EParseError;
begin
  if Assigned(OnError) then
    OnError(Token, Msg);

  Result := EParseError.Create(Msg);
end;

function TParser.Addition(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TToken;
begin
  Expr := Multiplication();

  while (Match([TTokenType.MINUS, TTokenType.PLUS])) do
  begin
    Oper := Previous();
    Right := multiplication();
    Expr := TBinaryExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.Multiplication(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TToken;
begin
    expr := Unary();

    while (Match(TTokenType.SLASH, TTokenType.STAR)) do
    begin
      Oper := previous();
      right := Unary();
      expr := TBinaryExpressionNode.Create(expr, Oper, right);
    end;

    Result := Expr;
end;

function TParser.Comparison(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TToken;
begin
  Expr := Addition();

  while (Match([TTokenType.GREATER, TTokenType.GREATER_EQUAL, TTokenType.LESS, TTokenType.LESS_EQUAL])) do
  begin
    Oper := Previous();
    Right := Addition();
    Expr := TBinaryExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.IsAtEnd(): Boolean;
begin
  Result := Peek().TokenType = TTokenType.EOF;
end;

function TParser.Peek(): TToken;
begin
  Result := FTokens[FCurrent];
end;

function TParser.Previous(): TToken;
begin
  Result := FTokens[FCurrent - 1];
end;

function TParser.Equality(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TToken;
begin
  Expr := Comparison();

  while (Match(TTokenType.BANG_EQUAL, TTokenType.EQUAL_EQUAL)) do
  begin
    Oper := Previous();
    Right := Comparison();
    Expr := TBinaryExpressionNode.Create(expr, Oper, right);
  end;

  Result := Expr;
end;

function TParser.Check(TokenType: TTokenType): Boolean;
begin
  if (IsAtEnd()) then
    Exit(False);

  Result := Peek().TokenType = TokenType;
end;

function TParser.Match(TokenTypes: array of TTokenType): Boolean;
var
  TokenType: TTokenType;
begin

  for TokenType in TokenTypes do
  begin
    if (Check(TokenType)) then
    begin
      AdvanceToken();
      Exit(True);
    end;
  end;

  Result := False;
end;

function TParser.Match(TokenType: TTokenType): Boolean;
begin
  Result := Match([TokenType]);
end;

function TParser.Match(TokenTypeA, TokenTypeB: TTokenType): Boolean;
begin
  Result := Match([TokenTypeA, TokenTypeB]);
end;

function TParser.AdvanceToken(): TToken;
begin
  if not isAtEnd() then
    Inc(FCurrent);

  Result := previous();
end;

procedure TParser.Synchronize();
begin
  AdvanceToken();

  while not isAtEnd() do
  begin
    if (Previous().TokenType = TTokenType.SEMICOLON) then
      Exit();

    case peek().TokenType of
      TTokenType.CLASS,
      TTokenType.FUN,
      TTokenType.VAR,
      TTokenType.FOR,
      TTokenType.IF,
      TTokenType.WHILE,
      TTokenType.PRINT,
      TTokenType.RETURN: Exit();
    end;

    AdvanceToken();
  end;

end;

function TParser.Parse(): TObjectList<TStatementNode>;
var
  Statements: TObjectList<TStatementNode>;
begin
  Statements := TObjectList<TStatementNode>.Create();

  while not IsAtEnd() do
    Statements.Add(Declaration());

  Result := Statements;
end;

function TParser.Statement(): TStatementNode;
begin
  if Match(TTokenType.FOR) then
    Result := ForStatement()
  else if Match(TTokenType.BREAK) then
    Result := BreakStatement()
  else if Match(TTokenType.CONTINUE) then
    Result := ContinueStatement()
  else if Match(TTokenType.DO) then
    Result := DoStatement()
  else if Match(TTokenType.IF) then
    Result := ifStatement()
  else if Match(TTokenType.PRINT) then
    Result := PrintStatement()
  else if Match(TTokenType.RETURN) then
    Result := ReturnStatement()
  else if Match(TTokenType.WHILE) then
    Result := WhileStatement()
  else if Match(TTokenType.LEFT_BRACE) then
    Result := TBlockStatementNode.Create(Block())
  else
    Result := ExpressionStatement();
end;

function TParser.BreakStatement(): TStatementNode;
begin
  if (FLoopDepth = 0) then
    Error(Previous(), 'Cannot use "continue" outside of a loop.');

  Consume(TTokenType.SEMICOLON, 'Expect ";" after break.');

  Result := TBreakStatementNode.Create();
end;

function TParser.ReturnStatement(): TStatementNode;
var
  Keyword: TToken;
  Value: TExpressionNode;
begin
  Keyword := Previous();
  Value := nil;

  if not Check(TTokenType.SEMICOLON) then
    Value := Expression();

  Consume(TTokenType.SEMICOLON, 'Esperado ";" após o valor de retorno.');
  Result := TReturnStatementNode.Create(Keyword, Value);
end;

function TParser.ForStatement(): TStatementNode;
var
  Initializer: TStatementNode;
  Condition: TExpressionNode;
  Increment: TExpressionNode;
  Body: TStatementNode;
  Statements: TObjectList<TStatementNode>;
  Value: TLoxValue;
begin

  Inc(FLoopDepth);
  try
    Consume(TTokenType.LEFT_PAREN, 'Esperado "(" depois de "for".');

    if Match(TTokenType.SEMICOLON) then
      Initializer := nil
    else if Match(TTokenType.VAR) then
      Initializer := VarDeclaration()
    else
      Initializer := ExpressionStatement();

    if not Check(TTokenType.SEMICOLON) then
      Condition := Expression()
    else
      Condition := nil;

    Consume(TTokenType.SEMICOLON, 'Esperado ";" após condição do loop.');

    Increment := nil;

    if not check(TTokenType.RIGHT_PAREN) then
      Increment := Expression();

    Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" depois da cláusula "for".');

    Body := Statement();

    if Assigned(Increment) then
    begin
      Statements := TObjectList<TStatementNode>.Create();
      Statements.Add(body);
      Statements.Add(TExpressionStatementNode.Create(Increment));
      Body := TBlockStatementNode.Create(Statements);
    end;

    if (Condition = nil) then
    begin
      Value.ValueType := TLoxValueType.IS_BOOLEAN;
      Value.BooleanValue := True;
      Condition := TLiteralExpressionNode.Create(Value);
    end;

    Body := TWhileStatementNode.Create(Condition, Body);

    if not (Initializer = nil) then
    begin
      Statements := TObjectList<TStatementNode>.Create();
      Statements.Add(Initializer);
      Statements.Add(Body);
      Body := TBlockStatementNode.Create(Statements);
    end;

    Result := Body;
  finally
    Dec(FLoopDepth);
  end;

end;

function TParser.WhileStatement(): TStatementNode;
var
  Condition: TExpressionNode;
  Body: TStatementNode;
begin
  Inc(FLoopDepth);
  try

    Consume(TTokenType.LEFT_PAREN, 'Esperado "(" depois de "while".');
    Condition := Expression();

    Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" após a condição.');
    Body := Statement();

    Result := TWhileStatementNode.Create(Condition, Body);
  finally
    Dec(FLoopDepth);
  end;
end;

function TParser.IfStatement(): TStatementNode;
var
  Condition: TExpressionNode;
  ThenBranch,
  ElseBranch: TStatementNode;
begin
  Consume(TTokenType.LEFT_PAREN, 'Esperado "(" depois do "if".');
  Condition := Expression();

  Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" após a condição "if".');

  ThenBranch := Statement();

  if Match(TTokenType.ELSE) then
    ElseBranch := statement()
  else
    ElseBranch := nil;

  Result :=  TIfStatementNode.Create(Condition, ThenBranch, ElseBranch);
end;

function TParser.Declaration(): TStatementNode;
begin
  Result := nil;

  try
    if Match(TTokenType.CLASS) then
      Result := ClassDeclaration()
    else if Match(TTokenType.FUN) then
      Result := FunctionDeclaration('function')
    else if Match(TTokenType.VAR) then
      Result := VarDeclaration()
    else
      Result := Statement();
  except on Error: EParseError do
    Synchronize();
  end;

end;

function TParser.DoStatement(): TStatementNode;
var
  Body: TObjectList<TStatementNode>;
  Condition: TExpressionNode;
  Value: TLoxValue;
begin

  Inc(FLoopDepth);
  try
    // Body must be a block
    Consume(TTokenType.LEFT_BRACE, 'Expect "{" after do.');
    Body := Block();

    // While
    Consume(TTokenType.WHILE, 'Expect "while" after do loop body.');

    // Condition
    Consume(TTokenType.LEFT_PAREN, 'Expect "(" after "while."');
    Condition := Expression();
    Consume(TTokenType.RIGHT_PAREN, 'Expect ")" after while condition.');
    Consume(TTokenType.SEMICOLON, 'Expect ";" after while condition.');

    Body.Add(TIfStatementNode.Create(Condition, TBlockStatementNode.Create(TObjectList<TStatementNode>.Create()), TBreakStatementNode.Create()));


    Value := Default(TLoxValue);
    Value.ValueType := TLoxValueType.IS_BOOLEAN;
    Value.BooleanValue := True;

    Result := TWhileStatementNode.Create(TLiteralExpressionNode.Create(Value), TBlockStatementNode.Create(Body));
  finally
    Dec(FLoopDepth);
  end;

end;

function TParser.ClassDeclaration(): TStatementNode;
var
  Name: TToken;
  Methods: TObjectList<TFunctionStatementNode>;
  Superclass: TVariableExpressionNode;
begin
  Name := Consume(TTokenType.IDENTIFIER, 'Espere o nome da classe.');

  if Match(TTokenType.LESS) then
  begin
    Consume(TTokenType.IDENTIFIER, 'Esperado o nome da superclasse.');
    Superclass := TVariableExpressionNode.Create(Previous());
  end
  else
    Superclass := nil;

  Consume(TTokenType.LEFT_BRACE, 'Esperado "{" antes do corpo da classe');

  Methods := TObjectList<TFunctionStatementNode>.Create();

  while not Check(TTokenType.RIGHT_BRACE) and not IsAtEnd() do
    Methods.Add(FunctionDeclaration('method'));

  Consume(TTokenType.RIGHT_BRACE, 'Esperado "}" após o corpo da classe.');

  Result := TClassStatementNode.Create(Name, Superclass, Methods);

end;

function TParser.FunctionDeclaration(Kind: string): TFunctionStatementNode;
var
  Name: TToken;
  Parameters: TObjectList<TToken>;
  Body: TObjectList<TStatementNode>;
begin
  Name := Consume(TTokenType.IDENTIFIER, 'Esperado o nome ' + kind + '.');

  Consume(TTokenType.LEFT_PAREN, 'Esperado "(" após o nome ' + kind + ' .');

  Parameters := TObjectList<TToken>.Create();

  if not Check(TTokenType.RIGHT_PAREN) then
  begin
    repeat
      if (Parameters.Count >= 255) then
        Error(Peek(), 'Não pode ter mais de 255 parâmetros.');

      Parameters.Add(Consume(TTokenType.IDENTIFIER, 'Espere o nome do parâmetro.'));
    until not Match(TTokenType.COMMA);
  end;

  Consume(TTokenType.RIGHT_PAREN, 'Esperado ")" depois dos parâmetros.');
  Consume(TTokenType.LEFT_BRACE, 'Esperado "{" antes ' + kind + ' body.');

  Body := Block();

  Result := TFunctionStatementNode.Create(Name, Parameters, Body);
end;

function TParser.VarDeclaration(): TStatementNode;
var
  Name: TToken;
  Initializer: TExpressionNode;
begin
  Name := Consume(TTokenType.IDENTIFIER, 'Esperado o nome da variável.');

  if Match(TTokenType.EQUAL) then
    Initializer := Expression()
  else
    Initializer := nil;

  Consume(TTokenType.SEMICOLON, 'Esperado ";" após declaração de variável.');
  Result := TVarStatementNode.Create(Name, Initializer);
end;

function TParser.ExpressionStatement(): TStatementNode;
var
  expr: TExpressionNode;
begin
  Expr := Expression();
  Consume(TTokenType.SEMICOLON, 'Esperado ";" depois da expressão.');
  Result := TExpressionStatementNode.Create(expr);
end;

function TParser.Block(): TObjectList<TStatementNode>;
var
  Statements: TObjectList<TStatementNode>;
begin
  Statements := TObjectList<TStatementNode>.Create();

  while not Check(TTokenType.RIGHT_BRACE) and not IsAtEnd() do
    Statements.add(Declaration());

  Consume(TTokenType.RIGHT_BRACE, 'Espere "}" após o bloco.');
  Result := Statements;
end;

function TParser.PrintStatement(): TStatementNode;
var
  Value: TExpressionNode;
begin
  Value := Expression();

  Consume(TTokenType.SEMICOLON, 'Esperado ";" depois do valor.');

  Result := TPrintStatementNode.Create(Value);
end;

end.
