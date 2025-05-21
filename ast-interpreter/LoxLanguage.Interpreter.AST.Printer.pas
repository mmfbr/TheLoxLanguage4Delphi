// Marcello Mello
// 28/09/2019
unit LoxLanguage.Interpreter.AST.Printer;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  LoxLanguage.Interpreter.AST,
  LoxLanguage.Interpreter.Types;

type

  TAstPrinterVisitor = class(TInterfacedObject, IAstVisitor)
  private
    function Parenthesize(Name: string; Exprs: TArray<TExpressionNode>): ShortString;
    function Parenthesize2(Name: string; Parts: array of const): ShortString;
    procedure Transform(Builder: TStringBuilder; Parts: array of const);
  public
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
    function Print(Stmt: TStatementNode): ShortString; overload;
    function Print(Expr: TAstNode): ShortString; overload;
  end;

implementation

uses
  System.Variants;

{ TAstPrinterVisitor }

function TAstPrinterVisitor.Visit(BinaryExpression: TBinaryExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize(BinaryExpression.Operador.Lexeme, [BinaryExpression.Left, BinaryExpression.Right]);
end;

function TAstPrinterVisitor.Visit(GroupingExpression: TGroupingExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize('group', [GroupingExpression.Expr]);
end;

function TAstPrinterVisitor.Visit(LiteralExpression: TLiteralExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;

 if (LiteralExpression.value.ValueType = TLoxValueType.IS_OBJECT) and
    (LiteralExpression.value.ObjectInstanceValue = nil) then
   Result.StrValue := 'nil'
 else
 begin
   if LiteralExpression.value.ValueType = TLoxValueType.IS_STRING then
     Result.StrValue := LiteralExpression.Value.StrValue
   else if LiteralExpression.value.ValueType = TLoxValueType.IS_INT32 then
     Result.StrValue := UTF8Encode(IntToStr(LiteralExpression.Value.Int32Value))
   else if LiteralExpression.value.ValueType = TLoxValueType.IS_INT64 then
     Result.StrValue := UTF8Encode(IntToStr(LiteralExpression.Value.Int64Value))
   else if LiteralExpression.value.ValueType = TLoxValueType.IS_DOUBLE then
     Result.StrValue := UTF8Encode(FloatToStr(LiteralExpression.Value.DoubleValue))
   else
     Result.StrValue := 'undef';
 end;

end;

function TAstPrinterVisitor.Visit(UnaryExpression: TUnaryExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue :=  Parenthesize(UnaryExpression.Operador.Lexeme, [UnaryExpression.Right]);
end;

function TAstPrinterVisitor.Visit(SuperExpression: TSuperExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize2('super', [SuperExpression.Method]);
end;

function TAstPrinterVisitor.Visit(ThisExpression: TThisExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := 'this';
end;

function TAstPrinterVisitor.Visit(VariableExpression: TVariableExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := UTF8Encode(VariableExpression.Name.Lexeme);
end;

function TAstPrinterVisitor.Visit(BlockStatement: TBlockStatementNode): TLoxValue;
var
  Statement: TStatementNode;
begin
  Result.ValueType := TLoxValueType.IS_STRING;

  Result.StrValue := '(block ';

  for Statement in BlockStatement.Statements do
    Result.StrValue := Result.StrValue + Statement.Accept(Self).StrValue;

  Result.StrValue := Result.StrValue + ')';
end;

function TAstPrinterVisitor.Visit(SetExpression: TSetExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize2('=',
        [SetExpression.Obj, SetExpression.Name.Lexeme, SetExpression.Value]);
end;

function TAstPrinterVisitor.Visit(AssignExpression: TAssignExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize2('=', [AssignExpression.Name.Lexeme,
    AssignExpression.Value]);
end;

function TAstPrinterVisitor.Visit(CallExpression: TCallExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue :=Parenthesize2('call', [CallExpression.Callee, CallExpression.Arguments]);
end;

function TAstPrinterVisitor.Visit(GetExpression: TGetExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize2('.', [GetExpression.Obj, GetExpression.Name.Lexeme]);
end;

function TAstPrinterVisitor.Visit(LogicalExpression: TLogicalExpressionNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize(LogicalExpression.Operador.Lexeme, [LogicalExpression.left, LogicalExpression.right]);
end;

function TAstPrinterVisitor.Visit(BreakStatement: TBreakStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := 'break';
end;

function TAstPrinterVisitor.Visit(ClassStatement: TClassStatementNode): TLoxValue;
var
  Method: TFunctionStatementNode;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := UTF8Encode('(class ' + ClassStatement.Name.Lexeme);
  // > Inheritance omit

  if (ClassStatement.SuperClass <> nil) then
    Result.StrValue := Result.StrValue + ' < ' + Print(ClassStatement.SuperClass);
  // < Inheritance omit

  for Method in ClassStatement.Methods do
    Result.StrValue := Result.StrValue + ' ' + Print(Method);

  Result.StrValue := Result.StrValue + ')';
end;

function TAstPrinterVisitor.Visit(ReturnStatement: TReturnStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;

  if (ReturnStatement.Value = nil) then
  begin
    Result.StrValue := '(return)';
    Exit();
  end;

  Result.StrValue := Parenthesize('return', [ReturnStatement.Value]);
end;

function TAstPrinterVisitor.Visit(VarStatement: TVarStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;

  if (VarStatement.Initializer = nil) then
    Result.StrValue := Parenthesize2('var', [VarStatement.Name])
  else
    Result.StrValue := Parenthesize2('var', [VarStatement.Name, '=',
      VarStatement.Initializer]);
end;

function TAstPrinterVisitor.Print(Stmt: TStatementNode): ShortString;
begin
  Result := Stmt.Accept(Self).StrValue;
end;

function TAstPrinterVisitor.Parenthesize(Name: string;
  Exprs: TArray<TExpressionNode>): ShortString;
var
  Expr: TExpressionNode;
begin
  Result := UTF8Encode('(' + name);

  for Expr in Exprs do
  begin
    Result := Result + ' ';
    Result := Result + Expr.Accept(Self).StrValue;
  end;

  Result := Result + ')';
end;

function TAstPrinterVisitor.Print(Expr: TAstNode): ShortString;
begin
  Result := Expr.Accept(Self).StrValue;
end;

function TAstPrinterVisitor.Visit(WhileStatement: TWhileStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize2('while', [WhileStatement.Condition,
    WhileStatement.Body]);
end;

function TAstPrinterVisitor.Visit(PrintStatement: TPrintStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize('print', [PrintStatement.Expr]);
end;

function TAstPrinterVisitor.Visit(ContinueStatement: TContinueStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := 'continue';
end;

function TAstPrinterVisitor.Visit(ExpressionStatement: TExpressionStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := Parenthesize(';', [ExpressionStatement.Expression]);
end;

function TAstPrinterVisitor.Visit(IfStatement: TIfStatementNode): TLoxValue;
begin
  Result.ValueType := TLoxValueType.IS_STRING;

  if (IfStatement.elseBranch = nil) then
  begin
    Result.StrValue := Parenthesize2('if', [IfStatement.Condition,
      IfStatement.thenBranch]);
    Exit();
  end;

  Result.StrValue := Parenthesize2('if-else', [IfStatement.Condition,
    IfStatement.thenBranch, IfStatement.elseBranch]);
end;

function TAstPrinterVisitor.Parenthesize2(Name: string; Parts: array of const): ShortString;
var
  Builder: TStringBuilder;
begin
  Builder := TStringBuilder.Create;
  Builder.Append('(').Append(Name);
  Transform(Builder, Parts);
  Builder.Append(')');

  Result := UTF8Encode(Builder.ToString());

  Builder.Free();
end;

procedure TAstPrinterVisitor.Transform(Builder: TStringBuilder;
  Parts: array of const);
var
  Part: TVarRec;
  VarRecList: array of TVarRec;
  ExpressionList: TArray<TExpressionNode>;
  i: Integer;
begin

  for Part in Parts do
  begin
    Builder.Append(' ');

    if Part.VType = vtObject then
    begin
      if (Part.VObject is TExpressionNode) then
      begin
        Builder.Append(TStatementNode(Part.VObject).Accept(Self).StrValue);
      end
      else if (Part.VObject is TStatementNode) then
      begin
        Builder.Append(TStatementNode(Part.VObject).Accept(Self).StrValue);
      end
      else if (Part.VObject is TLoxToken) then
      begin
        Builder.Append(TLoxToken(Part.VObject).Lexeme);
      end
      else if (Part.VObject is TObjectList<TExpressionNode>) then
      begin
        ExpressionList := TObjectList<TExpressionNode>(Part.VObject).ToArray();
        SetLength(VarRecList, Length(ExpressionList));

        for i := Low(ExpressionList) to High(ExpressionList) do
          VarRecList[i]:= TValue.From(ExpressionList[i]).AsVarRec;

        Transform(Builder, VarRecList);
      end
      else
      begin
        raise Exception.Create('tipo nao suportado ainda, verifique');
        // Builder.append(Part);
      end;
    end
    else if Part.VType = vtWideString then
    begin
      Builder.Append(Part.VWideString);
    end
    else if Part.VType = vtWideChar then
    begin
      Builder.Append(Part.VWideChar);
    end
    else if Part.VType = vtUnicodeString then
    begin
      Builder.Append(String(Part.VUnicodeString));
    end
    else if Part.VType = vtChar then
    begin
      Builder.Append(Part.VChar);
    end
    else
    begin
      raise Exception.Create('tipo nao suportado ainda, verifique');
      // Builder.append(Part);
    end;
  end;
end;

function TAstPrinterVisitor.Visit(FunctionStatement: TFunctionStatementNode): TLoxValue;
var
  Param: TLoxToken;
  Body: TStatementNode;
begin
  Result.ValueType := TLoxValueType.IS_STRING;
  Result.StrValue := UTF8Encode('(fun ' + FunctionStatement.Name.Lexeme + '(');

  for Param in FunctionStatement.Params do
  begin
    if (Param <> FunctionStatement.Params[0]) then
      Result.StrValue := Result.StrValue + ' ';

    Result.StrValue := Result.StrValue + UTF8Encode(Param.Lexeme);
  end;

  Result.StrValue := Result.StrValue + ') ';

  for Body in FunctionStatement.Body do
    Result.StrValue := Result.StrValue + Body.Accept(Self).StrValue;

  Result.StrValue := Result.StrValue + ')';
end;

end.
