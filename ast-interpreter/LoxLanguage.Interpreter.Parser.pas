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

  TOnParserErrorEvent = procedure(Token: TLoxToken; Msg: string) of object;

  EParseError = class(Exception)
  end;

  TParser = class
  private
    FLoopDepth: Integer;
    FOnError: TOnParserErrorEvent;
    FTokens: TObjectList<TLoxToken>;
    FCurrent: Integer;
    function ProcessExpression(): TExpressionNode;
    function ProcessAssignmentExpression(): TExpressionNode;
    function ProcessLogicalOrExpression(): TExpressionNode;
    function ProcessLogicalAndExpression(): TExpressionNode;
    function ProcessUnaryExpression(): TExpressionNode;
    function ProcessCallExpression(): TExpressionNode;
    function ProcessFinishCallExpression(Callee: TExpressionNode): TExpressionNode;
    function ProcessAdditionExpression(): TExpressionNode;
    function ProcessMultiplicationExpression(): TExpressionNode;
    function ProcessEqualityExpression(): TExpressionNode;
    function ProcessPrimaryExpression(): TExpressionNode;
    function MatchToken(TokenType: TLoxTokenType): Boolean; overload;
    function MatchTokens(TokenTypeA, TokenTypeB: TLoxTokenType): Boolean; overload;
    function MatchTokens(TokenTypes: array of TLoxTokenType): Boolean; overload;
    function CheckToken(TokenType: TLoxTokenType): Boolean;
    function ConsumeToken(TokenType: TLoxTokenType; Msg: string): TLoxToken;
    function Error(Token: TLoxToken; Msg: string): EParseError;
    function ProcessComparisonExpression(): TExpressionNode;
    function AdvanceToken(): TLoxToken;
    function PreviousToken(): TLoxToken;
    function IsAtEnd(): Boolean;
    function PeekToken(): TLoxToken;
    procedure Synchronize();
    function ProcessStatement(): TStatementNode;
    function ProcessBreakStatements(): TStatementNode;
    function ProcessDoStatement(): TStatementNode;
    function ProcessContinueStatement(): TStatementNode;
    function ProcessReturnStatement(): TStatementNode;
    function ProcessForStatement(): TStatementNode;
    function ProcessWhileStatement(): TStatementNode;
    function ProcessIfStatement(): TStatementNode;
    function ProcessDeclaration(): TStatementNode;
    function ProcessClassDeclaration(): TStatementNode;
    function ProcessFunctionDeclaration(Kind: string): TFunctionStatementNode;
    function ProcessVarDeclaration(): TStatementNode;
    function ProcessExpressionStatements(): TStatementNode;
    function ProcessBlockStatements(): TObjectList<TStatementNode>;
    function ProcessPrintStatement(): TStatementNode;
  public
    constructor Create(Tokens: TObjectList<TLoxToken>);
    function Parse(): TObjectList<TStatementNode>;
    property OnError: TOnParserErrorEvent read FOnError write FOnError;
  end;

implementation

{ TParser }

constructor TParser.Create(Tokens: TObjectList<TLoxToken>);
begin
  FLoopDepth := 0;
  FCurrent := 0;
  FTokens := Tokens;
end;

function TParser.ProcessExpression(): TExpressionNode;
begin
  Result := ProcessAssignmentExpression();
end;

function TParser.ProcessAssignmentExpression(): TExpressionNode;
var
  Expr: TExpressionNode;
  Get: TGetExpressionNode;
  Equals: TLoxToken;
  Value: TExpressionNode;
  Name: TLoxToken;
begin
  Expr := ProcessLogicalOrExpression();

  if MatchToken(TLoxTokenType.EQUAL_SYMBOL) then
  begin
    Equals := PreviousToken();
    Value := ProcessAssignmentExpression();

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

function TParser.ProcessLogicalOrExpression(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TLoxToken;
begin
  Expr := ProcessLogicalAndExpression();

  while MatchToken(TLoxTokenType.OR_KEYWORD) do
  begin
    Oper := PreviousToken();
    Right := ProcessLogicalAndExpression();
    Expr := TLogicalExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.ProcessLogicalAndExpression(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TLoxToken;
begin
  Expr := ProcessEqualityExpression();

  while MatchToken(TLoxTokenType.AND_KEYWORD) do
  begin
    Oper := PreviousToken();
    Right := ProcessEqualityExpression();
    Expr := TLogicalExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.ProcessUnaryExpression(): TExpressionNode;
var
  Right: TExpressionNode;
  Oper: TLoxToken;
begin

  if MatchTokens([TLoxTokenType.NOT_SYMBOL, TLoxTokenType.MINUS_SYMBOL]) then
  begin
    Oper := PreviousToken();
    Right := ProcessUnaryExpression();
    Exit(TUnaryExpressionNode.Create(Oper, Right));
  end;

  Result := ProcessCallExpression();
end;

function TParser.ProcessCallExpression(): TExpressionNode;
var
  Expr: TExpressionNode;
  Name: TLoxToken;
begin
  Expr := ProcessPrimaryExpression();

  while True do
  begin
    if MatchToken(TLoxTokenType.LEFT_PAREN_SYMBOL) then
      Expr := ProcessFinishCallExpression(Expr)
    else if MatchToken(TLoxTokenType.DOT_SYMBOL) then
    begin
      Name := ConsumeToken(TLoxTokenType.IDENTIFIER_TOKEN, 'Espere o nome da propriedade depois "."');
      Expr := TGetExpressionNode.Create(Expr, Name);
    end
    else
      Break;
  end;

  Result := Expr;
end;

function TParser.ProcessFinishCallExpression(Callee: TExpressionNode): TExpressionNode;
var
  Arguments: TObjectList<TExpressionNode>;
  Paren: TLoxToken;
begin
  Arguments := TObjectList<TExpressionNode>.Create();

  if not CheckToken(TLoxTokenType.RIGHT_PAREN_SYMBOL) then
  begin
    repeat
      if (Arguments.Count >= 255) then
        Error(PeekToken(), 'Não pode ter mais de 255 argumentos.');

      Arguments.Add(ProcessExpression());
    until not MatchToken(TLoxTokenType.COMMA_SYMBOL);
  end;

  Paren := ConsumeToken(TLoxTokenType.RIGHT_PAREN_SYMBOL, 'Esperado ")" após argumentos.');

  Result := TCallExpressionNode.Create(Callee, Paren, Arguments);
end;

function TParser.ProcessPrimaryExpression(): TExpressionNode;
var
  Expr: TExpressionNode;
  Value: TLoxValue;
  Keyword,
  Method: TLoxToken;
begin

  if (MatchToken(TLoxTokenType.FALSE_KEYWORD)) then
  begin
    Value.ValueType := TLoxValueType.IS_BOOLEAN;
    Value.BooleanValue := False;
    Result := TLiteralExpressionNode.Create(Value);
    Exit();
  end;

  if (MatchToken(TLoxTokenType.TRUE_KEYWORD)) then
  begin
    Value.ValueType := TLoxValueType.IS_BOOLEAN;
    Value.BooleanValue := True;
    Result := TLiteralExpressionNode.Create(Value);
    Exit();
  end;

  if MatchToken(TLoxTokenType.NIL_KEYWORD) then
  begin
    Value.ValueType := TLoxValueType.IS_NULL;
    Result := TLiteralExpressionNode.Create(Value);
    Exit();
  end;

  if MatchTokens(TLoxTokenType.NUMBER_LITERAL, TLoxTokenType.STRING_LITERAL) then
  begin
    Result := TLiteralExpressionNode.Create(PreviousToken().Literal);
    Exit();
  end;

  if MatchToken(TLoxTokenType.SUPER_KEYWORD) then
  begin
    Keyword := PreviousToken();
    ConsumeToken(TLoxTokenType.DOT_SYMBOL, 'Esperado "." depois de "super".');
    Method := ConsumeToken(TLoxTokenType.IDENTIFIER_TOKEN, 'Espere o nome do método da superclasse.');
    Result := TSuperExpressionNode.Create(Keyword, Method);
    Exit();
  end;

  if MatchToken(TLoxTokenType.THIS_KEYWORD) then
  begin
    Result := TThisExpressionNode.Create(PreviousToken());
    Exit();
  end;

  if MatchToken(TLoxTokenType.IDENTIFIER_TOKEN) then
  begin
    Result := TVariableExpressionNode.Create(PreviousToken());
    Exit();
  end;

  if (MatchToken(TLoxTokenType.LEFT_PAREN_SYMBOL)) then
  begin
    Expr := ProcessExpression();
    ConsumeToken(TLoxTokenType.RIGHT_PAREN_SYMBOL, 'Esperado um ")" após a expressão.');
    Exit(TGroupingExpressionNode.Create(Expr));
  end;

  raise Error(PeekToken(), 'Esperado expressão.');
end;

function TParser.ConsumeToken(TokenType: TLoxTokenType; Msg: string): TLoxToken;
begin
  if (CheckToken(TokenType)) then
    Exit(AdvanceToken());

  raise Error(PeekToken(), Msg);
end;

function TParser.ProcessContinueStatement(): TStatementNode;
begin
  if (FLoopDepth = 0) then
    Error(PreviousToken(), 'Cannot use "continue" outside of a loop.');

  ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Expect ";" after continue.');

  Result := TContinueStatementNode.Create();
end;

function TParser.Error(Token: TLoxToken; Msg: string): EParseError;
begin
  if Assigned(OnError) then
    OnError(Token, Msg);

  Result := EParseError.Create(Msg);
end;

function TParser.ProcessAdditionExpression(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TLoxToken;
begin
  Expr := ProcessMultiplicationExpression();

  while (MatchTokens([TLoxTokenType.MINUS_SYMBOL, TLoxTokenType.PLUS_SYMBOL])) do
  begin
    Oper := PreviousToken();
    Right := ProcessMultiplicationExpression();
    Expr := TBinaryExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.ProcessMultiplicationExpression(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TLoxToken;
begin
    expr := ProcessUnaryExpression();

    while (MatchTokens(TLoxTokenType.SLASH_SYMBOL, TLoxTokenType.STAR_SYMBOL)) do
    begin
      Oper := PreviousToken();
      right := ProcessUnaryExpression();
      expr := TBinaryExpressionNode.Create(expr, Oper, right);
    end;

    Result := Expr;
end;

function TParser.ProcessComparisonExpression(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TLoxToken;
begin
  Expr := ProcessAdditionExpression();

  while (MatchTokens([TLoxTokenType.GREATER_SYMBOL, TLoxTokenType.GREATER_EQUAL_PAIRS_SYMBOL, TLoxTokenType.LESS_SYMBOL, TLoxTokenType.LESS_EQUAL_PAIRS_SYMBOL])) do
  begin
    Oper := PreviousToken();
    Right := ProcessAdditionExpression();
    Expr := TBinaryExpressionNode.Create(Expr, Oper, Right);
  end;

  Result := Expr;
end;

function TParser.IsAtEnd(): Boolean;
begin
  Result := PeekToken().TokenType = TLoxTokenType.END_OF_FILE_TOKEN;
end;

function TParser.PeekToken(): TLoxToken;
begin
  Result := FTokens[FCurrent];
end;

function TParser.PreviousToken(): TLoxToken;
begin
  Result := FTokens[FCurrent - 1];
end;

function TParser.ProcessEqualityExpression(): TExpressionNode;
var
  Expr,
  Right: TExpressionNode;
  Oper: TLoxToken;
begin
  Expr := ProcessComparisonExpression();

  while (MatchTokens(TLoxTokenType.NOT_EQUAL_PAIRS_SYMBOL, TLoxTokenType.EQUAL_EQUAL_PAIRS_SYMBOL)) do
  begin
    Oper := PreviousToken();
    Right := ProcessComparisonExpression();
    Expr := TBinaryExpressionNode.Create(expr, Oper, right);
  end;

  Result := Expr;
end;

function TParser.CheckToken(TokenType: TLoxTokenType): Boolean;
begin
  if (IsAtEnd()) then
    Exit(False);

  Result := PeekToken().TokenType = TokenType;
end;

function TParser.MatchTokens(TokenTypes: array of TLoxTokenType): Boolean;
var
  TokenType: TLoxTokenType;
begin

  for TokenType in TokenTypes do
  begin
    if (CheckToken(TokenType)) then
    begin
      AdvanceToken();
      Exit(True);
    end;
  end;

  Result := False;
end;

function TParser.MatchToken(TokenType: TLoxTokenType): Boolean;
begin
  Result := MatchTokens([TokenType]);
end;

function TParser.MatchTokens(TokenTypeA, TokenTypeB: TLoxTokenType): Boolean;
begin
  Result := MatchTokens([TokenTypeA, TokenTypeB]);
end;

function TParser.AdvanceToken(): TLoxToken;
begin
  if not isAtEnd() then
    Inc(FCurrent);

  Result := PreviousToken();
end;

procedure TParser.Synchronize();
begin
  AdvanceToken();

  while not isAtEnd() do
  begin
    if (PreviousToken().TokenType = TLoxTokenType.SEMICOLON_SYMBOL) then
      Exit();

    case PeekToken().TokenType of
      TLoxTokenType.CLASS_KEYWORD,
      TLoxTokenType.FUN_KEYWORD,
      TLoxTokenType.VAR_KEYWORD,
      TLoxTokenType.FOR_KEYWORD,
      TLoxTokenType.IF_KEYWORD,
      TLoxTokenType.WHILE_KEYWORD,
      TLoxTokenType.PRINT_KEYWORD,
      TLoxTokenType.RETURN_KEYWORD: Exit();
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
    Statements.Add(ProcessDeclaration());

  Result := Statements;
end;

function TParser.ProcessStatement(): TStatementNode;
begin
  if MatchToken(TLoxTokenType.FOR_KEYWORD) then
    Result := ProcessForStatement()
  else if MatchToken(TLoxTokenType.BREAK_KEYWORD) then
    Result := ProcessBreakStatements()
  else if MatchToken(TLoxTokenType.CONTINUE_KEYWORD) then
    Result := ProcessContinueStatement()
  else if MatchToken(TLoxTokenType.DO_KEYWORD) then
    Result := ProcessDoStatement()
  else if MatchToken(TLoxTokenType.IF_KEYWORD) then
    Result := ProcessIfStatement()
  else if MatchToken(TLoxTokenType.PRINT_KEYWORD) then
    Result := ProcessPrintStatement()
  else if MatchToken(TLoxTokenType.RETURN_KEYWORD) then
    Result := ProcessReturnStatement()
  else if MatchToken(TLoxTokenType.WHILE_KEYWORD) then
    Result := ProcessWhileStatement()
  else if MatchToken(TLoxTokenType.LEFT_BRACE_SYMBOL) then
    Result := TBlockStatementNode.Create(ProcessBlockStatements())
  else
    Result := ProcessExpressionStatements();
end;

function TParser.ProcessBreakStatements(): TStatementNode;
begin
  if (FLoopDepth = 0) then
    Error(PreviousToken(), 'Cannot use "continue" outside of a loop.');

  ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Expect ";" after break.');

  Result := TBreakStatementNode.Create();
end;

function TParser.ProcessReturnStatement(): TStatementNode;
var
  Keyword: TLoxToken;
  Value: TExpressionNode;
begin
  Keyword := PreviousToken();
  Value := nil;

  if not CheckToken(TLoxTokenType.SEMICOLON_SYMBOL) then
    Value := ProcessExpression();

  ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Esperado ";" após o valor de retorno.');
  Result := TReturnStatementNode.Create(Keyword, Value);
end;

function TParser.ProcessForStatement(): TStatementNode;
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
    ConsumeToken(TLoxTokenType.LEFT_PAREN_SYMBOL, 'Esperado "(" depois de "for".');

    if MatchToken(TLoxTokenType.SEMICOLON_SYMBOL) then
      Initializer := nil
    else if MatchToken(TLoxTokenType.VAR_KEYWORD) then
      Initializer := ProcessVarDeclaration()
    else
      Initializer := ProcessExpressionStatements();

    if not CheckToken(TLoxTokenType.SEMICOLON_SYMBOL) then
      Condition := ProcessExpression()
    else
      Condition := nil;

    ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Esperado ";" após condição do loop.');

    Increment := nil;

    if not CheckToken(TLoxTokenType.RIGHT_PAREN_SYMBOL) then
      Increment := ProcessExpression();

    ConsumeToken(TLoxTokenType.RIGHT_PAREN_SYMBOL, 'Esperado ")" depois da cláusula "for".');

    Body := ProcessStatement();

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

function TParser.ProcessWhileStatement(): TStatementNode;
var
  Condition: TExpressionNode;
  Body: TStatementNode;
begin
  Inc(FLoopDepth);
  try

    ConsumeToken(TLoxTokenType.LEFT_PAREN_SYMBOL, 'Esperado "(" depois de "while".');
    Condition := ProcessExpression();

    ConsumeToken(TLoxTokenType.RIGHT_PAREN_SYMBOL, 'Esperado ")" após a condição.');
    Body := ProcessStatement();

    Result := TWhileStatementNode.Create(Condition, Body);
  finally
    Dec(FLoopDepth);
  end;
end;

function TParser.ProcessIfStatement(): TStatementNode;
var
  Condition: TExpressionNode;
  ThenBranch,
  ElseBranch: TStatementNode;
begin
  ConsumeToken(TLoxTokenType.LEFT_PAREN_SYMBOL, 'Esperado "(" depois do "if".');
  Condition := ProcessExpression();

  ConsumeToken(TLoxTokenType.RIGHT_PAREN_SYMBOL, 'Esperado ")" após a condição "if".');

  ThenBranch := ProcessStatement();

  if MatchToken(TLoxTokenType.ELSE_KEYWORD) then
    ElseBranch := ProcessStatement()
  else
    ElseBranch := nil;

  Result :=  TIfStatementNode.Create(Condition, ThenBranch, ElseBranch);
end;

function TParser.ProcessDeclaration(): TStatementNode;
begin
  Result := nil;

  try
    if MatchToken(TLoxTokenType.CLASS_KEYWORD) then
      Result := ProcessClassDeclaration()
    else if MatchToken(TLoxTokenType.FUN_KEYWORD) then
      Result := ProcessFunctionDeclaration('function')
    else if MatchToken(TLoxTokenType.VAR_KEYWORD) then
      Result := ProcessVarDeclaration()
    else
      Result := ProcessStatement();
  except on Error: EParseError do
    Synchronize();
  end;

end;

function TParser.ProcessDoStatement(): TStatementNode;
var
  Body: TObjectList<TStatementNode>;
  Condition: TExpressionNode;
  Value: TLoxValue;
begin

  Inc(FLoopDepth);
  try
    // Body must be a ProcessBlockStatements
    ConsumeToken(TLoxTokenType.LEFT_BRACE_SYMBOL, 'Expect "{" after do.');
    Body := ProcessBlockStatements();

    // While
    ConsumeToken(TLoxTokenType.WHILE_KEYWORD, 'Expect "while" after do loop body.');

    // Condition
    ConsumeToken(TLoxTokenType.LEFT_PAREN_SYMBOL, 'Expect "(" after "while."');
    Condition := ProcessExpression();
    ConsumeToken(TLoxTokenType.RIGHT_PAREN_SYMBOL, 'Expect ")" after while condition.');
    ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Expect ";" after while condition.');

    Body.Add(TIfStatementNode.Create(Condition, TBlockStatementNode.Create(TObjectList<TStatementNode>.Create()), TBreakStatementNode.Create()));


    Value := Default(TLoxValue);
    Value.ValueType := TLoxValueType.IS_BOOLEAN;
    Value.BooleanValue := True;

    Result := TWhileStatementNode.Create(TLiteralExpressionNode.Create(Value), TBlockStatementNode.Create(Body));
  finally
    Dec(FLoopDepth);
  end;

end;

function TParser.ProcessClassDeclaration(): TStatementNode;
var
  Name: TLoxToken;
  Methods: TObjectList<TFunctionStatementNode>;
  Superclass: TVariableExpressionNode;
begin
  Name := ConsumeToken(TLoxTokenType.IDENTIFIER_TOKEN, 'Espere o nome da classe.');

  if MatchToken(TLoxTokenType.LESS_SYMBOL) then
  begin
    ConsumeToken(TLoxTokenType.IDENTIFIER_TOKEN, 'Esperado o nome da superclasse.');
    Superclass := TVariableExpressionNode.Create(PreviousToken());
  end
  else
    Superclass := nil;

  ConsumeToken(TLoxTokenType.LEFT_BRACE_SYMBOL, 'Esperado "{" antes do corpo da classe');

  Methods := TObjectList<TFunctionStatementNode>.Create();

  while not CheckToken(TLoxTokenType.RIGHT_BRACE_SYMBOL) and not IsAtEnd() do
    Methods.Add(ProcessFunctionDeclaration('method'));

  ConsumeToken(TLoxTokenType.RIGHT_BRACE_SYMBOL, 'Esperado "}" após o corpo da classe.');

  Result := TClassStatementNode.Create(Name, Superclass, Methods);

end;

function TParser.ProcessFunctionDeclaration(Kind: string): TFunctionStatementNode;
var
  Name: TLoxToken;
  Parameters: TObjectList<TLoxToken>;
  Body: TObjectList<TStatementNode>;
begin
  Name := ConsumeToken(TLoxTokenType.IDENTIFIER_TOKEN, 'Esperado o nome ' + kind + '.');

  ConsumeToken(TLoxTokenType.LEFT_PAREN_SYMBOL, 'Esperado "(" após o nome ' + kind + ' .');

  Parameters := TObjectList<TLoxToken>.Create();

  if not CheckToken(TLoxTokenType.RIGHT_PAREN_SYMBOL) then
  begin
    repeat
      if (Parameters.Count >= 255) then
        Error(PeekToken(), 'Não pode ter mais de 255 parâmetros.');

      Parameters.Add(ConsumeToken(TLoxTokenType.IDENTIFIER_TOKEN, 'Espere o nome do parâmetro.'));
    until not MatchToken(TLoxTokenType.COMMA_SYMBOL);
  end;

  ConsumeToken(TLoxTokenType.RIGHT_PAREN_SYMBOL, 'Esperado ")" depois dos parâmetros.');
  ConsumeToken(TLoxTokenType.LEFT_BRACE_SYMBOL, 'Esperado "{" antes ' + kind + ' body.');

  Body := ProcessBlockStatements();

  Result := TFunctionStatementNode.Create(Name, Parameters, Body);
end;

function TParser.ProcessVarDeclaration(): TStatementNode;
var
  Name: TLoxToken;
  Initializer: TExpressionNode;
begin
  Name := ConsumeToken(TLoxTokenType.IDENTIFIER_TOKEN, 'Esperado o nome da variável.');

  if MatchToken(TLoxTokenType.EQUAL_SYMBOL) then
    Initializer := ProcessExpression()
  else
    Initializer := nil;

  ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Esperado ";" após declaração de variável.');
  Result := TVarStatementNode.Create(Name, Initializer);
end;

function TParser.ProcessExpressionStatements(): TStatementNode;
var
  expr: TExpressionNode;
begin
  Expr := ProcessExpression();
  ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Esperado ";" depois da expressão.');
  Result := TExpressionStatementNode.Create(expr);
end;

function TParser.ProcessBlockStatements(): TObjectList<TStatementNode>;
var
  Statements: TObjectList<TStatementNode>;
begin
  Statements := TObjectList<TStatementNode>.Create();

  while not CheckToken(TLoxTokenType.RIGHT_BRACE_SYMBOL) and not IsAtEnd() do
    Statements.add(ProcessDeclaration());

  ConsumeToken(TLoxTokenType.RIGHT_BRACE_SYMBOL, 'Espere "}" após o bloco.');
  Result := Statements;
end;

function TParser.ProcessPrintStatement(): TStatementNode;
var
  Value: TExpressionNode;
begin
  Value := ProcessExpression();

  ConsumeToken(TLoxTokenType.SEMICOLON_SYMBOL, 'Esperado ";" depois do valor.');

  Result := TPrintStatementNode.Create(Value);
end;

end.
