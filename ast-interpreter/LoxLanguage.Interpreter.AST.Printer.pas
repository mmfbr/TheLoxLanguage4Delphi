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

  TAstPrinter = class(TInterfacedObject, IVisitor)
  private
    function Parenthesize(Name: string; Exprs: TArray<TExpression>): ShortString;
    function Parenthesize2(Name: string; Parts: array of const): ShortString;
    procedure Transform(Builder: TStringBuilder; Parts: array of const);
  public
    function Visit(AssignExpression: TAssignExpression): TSSLangValue; overload;
    function Visit(BinaryExpression: TBinaryExpression): TSSLangValue; overload;
    function Visit(CallExpression: TCallExpression): TSSLangValue; overload;
    function Visit(GetExpression: TGetExpression): TSSLangValue; overload;
    function Visit(GroupingExpression: TGroupingExpression): TSSLangValue; overload;
    function Visit(LiteralExpression: TLiteralExpression): TSSLangValue; overload;
    function Visit(LogicalExpression: TLogicalExpression): TSSLangValue; overload;
    function Visit(SetExpression: TSetExpression): TSSLangValue; overload;
    function Visit(SuperExpression: TSuperExpression): TSSLangValue; overload;
    function Visit(ThisExpression: TThisExpression): TSSLangValue; overload;
    function Visit(UnaryExpression: TUnaryExpression): TSSLangValue; overload;
    function Visit(VariableExpression: TVariableExpression): TSSLangValue; overload;
    function Visit(BlockStatement: TBlockStatement): TSSLangValue; overload;
    function Visit(BreakStatement: TBreakStatement): TSSLangValue; overload;
    function Visit(ContinueStatement: TContinueStatement): TSSLangValue; overload;
    function Visit(ExpressionStatement: TExpressionStatement): TSSLangValue; overload;
    function Visit(IfStatement: TIfStatement): TSSLangValue; overload;
    function Visit(FunctionStatement: TFunctionStatement): TSSLangValue; overload;
    function Visit(PrintStatement: TPrintStatement): TSSLangValue; overload;
    function Visit(ClassStatement: TClassStatement): TSSLangValue; overload;
    function Visit(ReturnStatement: TReturnStatement): TSSLangValue; overload;
    function Visit(VarStatement: TVarStatement): TSSLangValue; overload;
    function Visit(WhileStatement: TWhileStatement): TSSLangValue; overload;
    function Print(Stmt: TStatement): ShortString; overload;
    function Print(Expr: TASTNode): ShortString; overload;
  end;

implementation

uses
  System.Variants;

{ TAstPrinter }

function TAstPrinter.Visit(BinaryExpression: TBinaryExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize(BinaryExpression.Operador.Lexeme, [BinaryExpression.Left, BinaryExpression.Right]);
end;

function TAstPrinter.Visit(GroupingExpression: TGroupingExpression)
  : TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize('group', [GroupingExpression.Expr]);
end;

function TAstPrinter.Visit(LiteralExpression: TLiteralExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;

 if (LiteralExpression.value.ValueType = TSSLangValueType.IS_OBJECT) and
    (LiteralExpression.value.ObjectInstanceValue = nil) then
   Result.StrValue := 'nil'
 else
 begin
   if LiteralExpression.value.ValueType = TSSLangValueType.IS_STRING then
     Result.StrValue := LiteralExpression.Value.StrValue
   else if LiteralExpression.value.ValueType = TSSLangValueType.IS_INT32 then
     Result.StrValue := UTF8Encode(IntToStr(LiteralExpression.Value.Int32Value))
   else if LiteralExpression.value.ValueType = TSSLangValueType.IS_INT64 then
     Result.StrValue := UTF8Encode(IntToStr(LiteralExpression.Value.Int64Value))
   else if LiteralExpression.value.ValueType = TSSLangValueType.IS_DOUBLE then
     Result.StrValue := UTF8Encode(FloatToStr(LiteralExpression.Value.DoubleValue))
   else
     Result.StrValue := 'undef';
 end;

end;

function TAstPrinter.Visit(UnaryExpression: TUnaryExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue :=  Parenthesize(UnaryExpression.Operador.Lexeme, [UnaryExpression.Right]);
end;

function TAstPrinter.Visit(SuperExpression: TSuperExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize2('super', [SuperExpression.Method]);
end;

function TAstPrinter.Visit(ThisExpression: TThisExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := 'this';
end;

function TAstPrinter.Visit(VariableExpression: TVariableExpression)
  : TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := UTF8Encode(VariableExpression.Name.Lexeme);
end;

function TAstPrinter.Visit(BlockStatement: TBlockStatement): TSSLangValue;
var
  Statement: TStatement;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;

  Result.StrValue := '(block ';

  for Statement in BlockStatement.Statements do
    Result.StrValue := Result.StrValue + Statement.Accept(Self).StrValue;

  Result.StrValue := Result.StrValue + ')';
end;

function TAstPrinter.Visit(SetExpression: TSetExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize2('=',
        [SetExpression.Obj, SetExpression.Name.Lexeme, SetExpression.Value]);
end;

function TAstPrinter.Visit(AssignExpression: TAssignExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize2('=', [AssignExpression.Name.Lexeme,
    AssignExpression.Value]);
end;

function TAstPrinter.Visit(CallExpression: TCallExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue :=Parenthesize2('call', [CallExpression.Callee, CallExpression.Arguments]);
end;

function TAstPrinter.Visit(GetExpression: TGetExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize2('.', [GetExpression.Obj, GetExpression.Name.Lexeme]);
end;

function TAstPrinter.Visit(LogicalExpression: TLogicalExpression): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize(LogicalExpression.Operador.Lexeme, [LogicalExpression.left, LogicalExpression.right]);
end;

function TAstPrinter.Visit(BreakStatement: TBreakStatement): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := 'break';
end;

function TAstPrinter.Visit(ClassStatement: TClassStatement): TSSLangValue;
var
  Method: TFunctionStatement;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := UTF8Encode('(class ' + ClassStatement.Name.Lexeme);
  // > Inheritance omit

  if (ClassStatement.SuperClass <> nil) then
    Result.StrValue := Result.StrValue + ' < ' + Print(ClassStatement.SuperClass);
  // < Inheritance omit

  for Method in ClassStatement.Methods do
    Result.StrValue := Result.StrValue + ' ' + Print(Method);

  Result.StrValue := Result.StrValue + ')';
end;

function TAstPrinter.Visit(ReturnStatement: TReturnStatement): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;

  if (ReturnStatement.Value = nil) then
  begin
    Result.StrValue := '(return)';
    Exit();
  end;

  Result.StrValue := Parenthesize('return', [ReturnStatement.Value]);
end;

function TAstPrinter.Visit(VarStatement: TVarStatement): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;

  if (VarStatement.Initializer = nil) then
    Result.StrValue := Parenthesize2('var', [VarStatement.Name])
  else
    Result.StrValue := Parenthesize2('var', [VarStatement.Name, '=',
      VarStatement.Initializer]);
end;

function TAstPrinter.Print(Stmt: TStatement): ShortString;
begin
  Result := Stmt.Accept(Self).StrValue;
end;

function TAstPrinter.Parenthesize(Name: string;
  Exprs: TArray<TExpression>): ShortString;
var
  Expr: TExpression;
begin
  Result := UTF8Encode('(' + name);

  for Expr in Exprs do
  begin
    Result := Result + ' ';
    Result := Result + Expr.Accept(Self).StrValue;
  end;

  Result := Result + ')';
end;

function TAstPrinter.Print(Expr: TASTNode): ShortString;
begin
  Result := Expr.Accept(Self).StrValue;
end;

function TAstPrinter.Visit(WhileStatement: TWhileStatement): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize2('while', [WhileStatement.Condition,
    WhileStatement.Body]);
end;

function TAstPrinter.Visit(PrintStatement: TPrintStatement): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize('print', [PrintStatement.Expr]);
end;

function TAstPrinter.Visit(ContinueStatement: TContinueStatement): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := 'continue';
end;

function TAstPrinter.Visit(ExpressionStatement: TExpressionStatement)
  : TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
  Result.StrValue := Parenthesize(';', [ExpressionStatement.Expression]);
end;

function TAstPrinter.Visit(IfStatement: TIfStatement): TSSLangValue;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;

  if (IfStatement.elseBranch = nil) then
  begin
    Result.StrValue := Parenthesize2('if', [IfStatement.Condition,
      IfStatement.thenBranch]);
    Exit();
  end;

  Result.StrValue := Parenthesize2('if-else', [IfStatement.Condition,
    IfStatement.thenBranch, IfStatement.elseBranch]);
end;

function TAstPrinter.Parenthesize2(Name: string; Parts: array of const): ShortString;
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

procedure TAstPrinter.Transform(Builder: TStringBuilder;
  Parts: array of const);
var
  Part: TVarRec;
  VarRecList: array of TVarRec;
  ExpressionList: TArray<TExpression>;
  i: Integer;
begin

  for Part in Parts do
  begin
    Builder.Append(' ');

    if Part.VType = vtObject then
    begin
      if (Part.VObject is TExpression) then
      begin
        Builder.Append(TStatement(Part.VObject).Accept(Self).StrValue);
      end
      else if (Part.VObject is TStatement) then
      begin
        Builder.Append(TStatement(Part.VObject).Accept(Self).StrValue);
      end
      else if (Part.VObject is TToken) then
      begin
        Builder.Append(TToken(Part.VObject).Lexeme);
      end
      else if (Part.VObject is TObjectList<TExpression>) then
      begin
        ExpressionList := TObjectList<TExpression>(Part.VObject).ToArray();
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

function TAstPrinter.Visit(FunctionStatement: TFunctionStatement): TSSLangValue;
var
  Param: TToken;
  Body: TStatement;
begin
  Result.ValueType := TSSLangValueType.IS_STRING;
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
