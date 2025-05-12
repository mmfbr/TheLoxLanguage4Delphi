// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Compiler;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  System.SysUtils,
  System.Math,
  System.StrUtils,
  System.AnsiStrings,
  LoxLanguage.VirtualMachine.Utils,
  LoxLanguage.VirtualMachine.Chunk,
  LoxLanguage.VirtualMachine.Scanner,
  LoxLanguage.VirtualMachine.Consts,
  LoxLanguage.VirtualMachine.Obj,
  LoxLanguage.VirtualMachine.Value,
  LoxLanguage.VirtualMachine.Types;

function Compile(const Source: PUTF8Char): PObjFunction;
procedure GrayCompilerRoots();
procedure Expression;
procedure Grouping(CanAssign: Boolean);
procedure Unary(CanAssign: Boolean);
procedure Number(CanAssign: Boolean);
procedure StringEmit(CanAssign: Boolean);
procedure Variable(CanAssign: Boolean);
procedure Binary(CanAssign: Boolean);
procedure Call(CanAssign: Boolean);
procedure Dot(CanAssign: Boolean);
procedure Super_(canAssign: Boolean);
procedure This_(canAssign: Boolean);
procedure classDeclaration();

procedure Literal(CanAssign: Boolean);
function GetRule(TokenType: TTokenType): PParseRule;
procedure ParsePrecedence(Precedence: TPrecedence);
procedure Statement();
function IdentifierConstant(Name: PToken): UInt8;
procedure Declaration();
procedure AddLocal(Name: TToken);
function ResolveLocal(Compiler: PCompiler; Name: PToken): Integer;
function ResolveUpvalue(Compiler: PCompiler; Name: PToken): Integer;
procedure And_(CanAssign: Boolean);
procedure Or_(CanAssign: Boolean);
function emitJump(Instruction: UInt8): Integer;
procedure patchJump(offset: Integer );
procedure Block();
function ArgumentList(): UInt8;

const
  Rules: array[TTokenType] of TParseRule = (
    ( Prefix: @Grouping; Infix: @Call;   Precedence: TPrecedence.PREC_CALL),       // TOKEN_LEFT_PAREN
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_RIGHT_PAREN
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_LEFT_BRACE
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_RIGHT_BRACE
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_COMMA
    ( Prefix: nil;       Infix: @Dot;     Precedence: TPrecedence.PREC_CALL),      // TOKEN_DOT
    ( Prefix: @Unary;    Infix: @Binary; Precedence: TPrecedence.PREC_TERM),       // TOKEN_MINUS
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_TERM),       // TOKEN_PLUS
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_SEMICOLON
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_FACTOR),     // TOKEN_SLASH
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_FACTOR),     // TOKEN_STAR
    ( Prefix: @Unary;    Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_BANG
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_EQUALITY),   // TOKEN_BANG_EQUAL
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_EQUAL
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_EQUALITY),   // TOKEN_EQUAL_EQUAL
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_COMPARISON), // TOKEN_GREATER
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_COMPARISON), // TOKEN_GREATER_EQUAL
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_COMPARISON), // TOKEN_LESS
    ( Prefix: nil;       Infix: @Binary; Precedence: TPrecedence.PREC_COMPARISON), // TOKEN_LESS_EQUAL
    ( Prefix: @Variable; Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_IDENTIFIER
    ( Prefix: @StringEmit;   Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_STRING
    ( Prefix: @Number;   Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_NUMBER
    ( Prefix: nil;       Infix: @and_;     Precedence: TPrecedence.PREC_AND),       // TOKEN_AND
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_CLASS
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_ELSE
    ( Prefix: @Literal;  Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_FALSE
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_FOR
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_FUN
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_IF
    ( Prefix: @Literal;  Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_NIL
    ( Prefix: nil;       Infix: @Or_;     Precedence: TPrecedence.PREC_OR),       // TOKEN_OR
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_PRINT
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_RETURN
    ( Prefix: @Super_;   Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_SUPER
    ( Prefix: @This_;    Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_THIS
    ( Prefix: @Literal;  Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_TRUE
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_VAR
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_WHILE
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE),       // TOKEN_ERROR
    ( Prefix: nil;       Infix: nil;     Precedence: TPrecedence.PREC_NONE)        // TOKEN_EOF
  );

implementation

uses
  LoxLanguage.VirtualMachine.Memory,
  LoxLanguage.VirtualMachine.Debug;

var
  Parser: TParser;
  Current: PCompiler;
  CurrentClass: PClassCompiler;

function CurrentChunk(): PChunk;
begin
  Result := @Current^.Func^.Chunk;
end;

procedure InitCompiler(Compiler: PCompiler; FunctionType: TFunctionType);
var
  Local: PLocal;
begin
  Compiler^.Enclosing := Current;
  Compiler^.Func := nil;
  Compiler^.FunctionType := FunctionType;
  Compiler^.LocalCount := 0;
  Compiler^.ScopeDepth := 0;
  compiler^.Func := NewFunction();
  Current := Compiler;

  if (FunctionType <> TFunctionType.TYPE_SCRIPT) then
    Current^.Func^.Name := CopyString(Parser.previous.start,
                                      Parser.previous.length);

  Local := @current^.Locals[current^.localCount];
  Current^.LocalCount := Current^.LocalCount + 1;
  local^.depth := 0;
  Local^.IsCaptured := False;

  if (FunctionType <> TFunctionType.TYPE_FUNCTION) then
  begin
    // In a method, it holds the receiver, "this".
    local^.name.start := 'this';
    local^.name.length := 4;
  end
  else
  begin
    // In a function, it holds the function, but cannot be referenced,
    // so has no name.
    local^.name.start := '';
    local^.name.length := 0;
  end;

end;

procedure ErrorAt(Token: PToken; const Msg: PUTF8Char);
begin
  if Parser.PanicMode then
    Exit();

  Parser.PanicMode := True;

  Write(Format('[Linha %d] Erro', [Token^.Line]));

  if (Token^.TokenType = TTokenType.TOKEN_EOF) then
    Write(' no final')
  else if (Token^.TokenType = TTokenType.TOKEN_ERROR) then
    // Nothing.
  else
    Write(Format(' proximo de "%.*s"', [Token^.Length, Token^.Start]));


  Writeln(Format(': %s', [Msg]));
  Parser.HadError := True;
end;

procedure Error(const Msg: PUTF8Char);
begin
  ErrorAt(@Parser.Previous, Msg);
end;

procedure ErrorAtCurrent(const Msg: PUTF8Char);
begin
  ErrorAt(@Parser.Current, Msg);
end;

procedure Advance();
begin
  Parser.Previous := Parser.Current;

  while True do
  begin
    Parser.Current := ScanToken();
    if (Parser.Current.TokenType <> TTokenType.TOKEN_ERROR) then
      Break;

    ErrorAtCurrent(Parser.Current.Start);
  end;
end;

procedure Consume(TokenType: TTokenType; const Msg: PUTF8Char);
begin
  if (Parser.Current.TokenType = TokenType) then
  begin
    Advance();
    Exit();
  end;

  ErrorAtCurrent(Msg);
end;

function Check(TokenType: TTokenType): Boolean;
begin
  Result := Parser.Current.TokenType = TokenType;
end;

function Match(TokenType: TTokenType): Boolean;
begin
  if not Check(TokenType) then
    Exit(False);

  Advance();
  Result := True;
end;

procedure EmitByte(AByte: UInt8);
begin
  WriteChunk(CurrentChunk(), AByte, Parser.Previous.Line);
end;

procedure EmitLoop(loopStart: integer );
var
  Offset: Integer;
begin
  EmitByte(Byte(TOpCode.OP_LOOP));

  Offset := currentChunk()^.count - loopStart + 2;
  if (offset > UINT16_MAX) then
    error('Corpo do laço muito grande.');

  emitByte((offset shr 8) and $ff);
  emitByte(offset and $ff);
end;

procedure EmitBytes(Byte1, Byte2: Byte);
begin
  EmitByte(Byte1);
  EmitByte(Byte2);
end;

procedure EmitReturn();
begin
  if (Current^.FunctionType = TFunctionType.TYPE_INITIALIZER) then
    EmitBytes(Byte(TOpCode.OP_GET_LOCAL), 0)
  else
    EmitByte(Byte(TOpCode.OP_NIL));


  EmitByte(Byte(TOpCode.OP_RETURN));
end;

function MakeConstant(Value: TValue): UInt8;
var
  Constant: Integer;
begin
  Constant := AddConstant(CurrentChunk(), Value);
  if Constant > UINT8_MAX then
  begin
    error('Muitas constantes em um pedaço.');
    Exit(0);
  end;

  Result := Constant;
end;

function EndCompiler(): PObjFunction;
var
  Func: PObjFunction;
begin
  EmitReturn();
  Func := Current^.Func;

{$IFDEF DEBUG_PRINT_CODE}
  if not Parser.HadError then
  begin
    if Func^.name <> nil then
      DisassembleChunk(CurrentChunk(), func^.name^.Chars)
    else
      DisassembleChunk(CurrentChunk(), '<script>');
  end;
{$ENDIF}

  Current := Current^.Enclosing;
  Result := Func;
end;

procedure BeginScope();
begin
  Current^.ScopeDepth := Current^.ScopeDepth + 1;
end;

procedure EndScope();
begin
  Current^.ScopeDepth := Current^.ScopeDepth - 1;

  while (current^.localCount > 0) and (current^.locals[current^.localCount - 1].depth > current^.scopeDepth) do
  begin
//    emitByte(Byte(TOpCode.OP_POP));


    if Current^.Locals[Current^.LocalCount - 1].IsCaptured then
      EmitByte(Byte(TOpCode.OP_CLOSE_UPVALUE))
    else
      EmitByte(Byte(TOpCode.OP_POP));

    current^.LocalCount := current^.LocalCount - 1;
  end;
end;

procedure Or_(CanAssign: Boolean);
var
  endJump,
  elseJump: Integer;
begin
  elseJump := emitJump(Byte(TOpCode.OP_JUMP_IF_FALSE));
  endJump := emitJump(Byte(TOpCode.OP_JUMP));

  patchJump(elseJump);
  emitByte(Byte(TOpCode.OP_POP));

  parsePrecedence(TPrecedence.PREC_OR);
  patchJump(endJump);
end;


procedure And_(CanAssign: Boolean);
var
  endJump: Integer;
begin
  EndJump := EmitJump(Byte(TOpCode.OP_JUMP_IF_FALSE));

  emitByte(Byte(TOpCode.OP_POP));
  parsePrecedence(TPrecedence.PREC_AND);

  patchJump(endJump);
end;

procedure Binary(CanAssign: Boolean);
var
  OperatorType: TTokenType;
  Precedence: TPrecedence;
begin
  // Remember the operator.
  OperatorType := Parser.Previous.TokenType;

  // Compile the right operand.
  Precedence := GetRule(OperatorType)^.Precedence;
  Inc(Precedence);
  ParsePrecedence(Precedence);

  // Emit the operator instruction.
  case OperatorType of
    TTokenType.TOKEN_BANG_EQUAL: EmitBytes(Byte(TOpCode.OP_EQUAL), Byte(TOpCode.OP_NOT));
    TTokenType.TOKEN_EQUAL_EQUAL: EmitByte(Byte(TOpCode.OP_EQUAL));
    TTokenType.TOKEN_GREATER: EmitByte(Byte(TOpCode.OP_GREATER));
    TTokenType.TOKEN_GREATER_EQUAL: EmitBytes(Byte(TOpCode.OP_LESS), Byte(TOpCode.OP_NOT));
    TTokenType.TOKEN_LESS: EmitByte(Byte(TOpCode.OP_LESS));
    TTokenType.TOKEN_LESS_EQUAL: EmitBytes(Byte(TOpCode.OP_GREATER), Byte(TOpCode.OP_NOT));
    TTokenType.TOKEN_PLUS:  EmitByte(Byte(TOpCode.OP_ADD));
    TTokenType.TOKEN_MINUS: EmitByte(Byte(TOpCode.OP_SUBTRACT));
    TTokenType.TOKEN_STAR:  EmitByte(Byte(TOpCode.OP_MULTIPLY));
    TTokenType.TOKEN_SLASH: EmitByte(Byte(TOpCode.OP_DIVIDE));
  else
    Exit(); // Unreachable.
  end;
end;

procedure Literal(CanAssign: Boolean);
begin
  case Parser.Previous.TokenType of
    TTokenType.TOKEN_FALSE: EmitByte(Byte(TOpCode.OP_FALSE));
    TTokenType.TOKEN_NIL: EmitByte(Byte(TOpCode.OP_NIL));
    TTokenType.TOKEN_TRUE: EmitByte(Byte(TOpCode.OP_TRUE));
  else
    Exit(); // Unreachable.
  end;
end;

procedure Grouping(CanAssign: Boolean);
begin
  Expression();
  Consume(TTokenType.TOKEN_RIGHT_PAREN, 'Esperado ")" depois da expressão.');
end;

procedure Call(CanAssign: Boolean);
var
  ArgCount: UInt8;
begin
  ArgCount := ArgumentList();
  EmitBytes(Byte(TOpCode.OP_CALL), ArgCount);
end;


procedure Dot(CanAssign: Boolean);
var
  name,
  argCount: UInt8;
begin
  consume(TTokenType.TOKEN_IDENTIFIER, 'Espere o nome da propriedade depois ".".');
  Name := IdentifierConstant(@parser.previous);

  if (canAssign and match(TTokenType.TOKEN_EQUAL)) then
  begin
    expression();
    emitBytes(Byte(TOpCode.OP_SET_PROPERTY), name);
  end
  else if (match(TTokenType.TOKEN_LEFT_PAREN)) then
  begin
    argCount := argumentList();
    emitBytes(Byte(TOpCode.OP_INVOKE), argCount);
    emitByte(name);
  end
  else
    emitBytes(Byte(TOpCode.OP_GET_PROPERTY), name);

end;


procedure emitConstant(Value: TValue);
begin
  EmitBytes(Byte(TOpCode.OP_CONSTANT), MakeConstant(value));
end;

procedure PatchJump(Offset: Integer);
var
  jump: Integer;
begin
  // -2 to adjust for the bytecode for the jump offset itself.
  jump := CurrentChunk()^.count - offset - 2;

  if (jump > UINT16_MAX) then
    error('Muito código para pular.');

  currentChunk()^.code[offset] := (jump shr 8) and $ff;
  currentChunk()^.code[offset + 1] := jump and $ff;
end;

function emitJump(Instruction: UInt8): Integer;
begin
  emitByte(Instruction);
  emitByte($ff);
  emitByte($ff);
  Result := CurrentChunk()^.count - 2;
end;

procedure Number(CanAssign: Boolean);
var
  Value: Double;
begin
  Value := AnsiStringToFloat(Parser.Previous.Start, nil);
  EmitConstant(NUMBER_VAL(Value));
end;

procedure StringEmit(CanAssign: Boolean);
begin
  EmitConstant(OBJ_VAL(CopyString(Parser.Previous.Start + 1,
                                  Parser.Previous.Length - 2)));
end;

procedure NamedVariable(Name: TToken; CanAssign: Boolean);
var
  Arg: Integer;
  GetOp, SetOp: TOpCode;
begin

  Arg := ResolveLocal(Current, @name);
  if (Arg <> -1) then
  begin
    getOp := TOpCode.OP_GET_LOCAL;
    setOp := TOpCode.OP_SET_LOCAL;
  end
  else
  begin
    Arg := ResolveUpvalue(Current, @Name);

    if (Arg <> -1) then
    begin
      GetOp := TOpCode.OP_GET_UPVALUE;
      SetOp := TOpCode.OP_SET_UPVALUE;
    end
    else
    begin
      Arg := identifierConstant(@name);
      getOp := TOpCode.OP_GET_GLOBAL;
      setOp := TOpCode.OP_SET_GLOBAL;
    end;
  end;

  if CanAssign and (Match(TTokenType.TOKEN_EQUAL)) then
  begin
    Expression();
    EmitBytes(Byte(SetOp), UInt8(Arg));
  end
  else
    EmitBytes(Byte(GetOp), UInt8(Arg));
end;

procedure Variable(CanAssign: Boolean);
begin
  NamedVariable(Parser.Previous, CanAssign);
end;

procedure ParsePrecedence(Precedence: TPrecedence);
var
  PrefixRule: procedure(CanAssign: Boolean);
  InfixRule: procedure(CanAssign: Boolean);
  CanAssign: Boolean;
begin
  Advance();
  PrefixRule := GetRule(Parser.Previous.TokenType)^.Prefix;

  if not Assigned(PrefixRule) then
  begin
    Error('Esperado expressão.');
    Exit();
  end;

  CanAssign := Precedence <= TPrecedence.PREC_ASSIGNMENT;

  PrefixRule(CanAssign);

  while (Precedence <= GetRule(Parser.Current.TokenType)^.Precedence) do
  begin
    Advance();
    InfixRule := GetRule(Parser.Previous.TokenType)^.Infix;
    InfixRule(canAssign);
  end;

  if CanAssign and Match(TTokenType.TOKEN_EQUAL) then
  begin
    Error('Destino de atribuição inválido.');
    Expression();
  end;
end;

function IdentifierConstant(Name: PToken): UInt8;
begin
  Result := MakeConstant(OBJ_VAL(CopyString(Name^.Start, Name^.Length)));
end;

function IdentifiersEqual(a: pToken; b: pToken): Boolean;
begin
  if (a^.length <> b^.length) then
    Exit(false);

  Result := CompareMem(a^.start, b^.start, a^.length);
end;

function ResolveLocal(Compiler: PCompiler; Name: PToken): Integer;
var
  i: Integer;
  Local: PLocal;
begin
  for i := compiler^.LocalCount - 1 downto 0 do
  begin
    Local := @compiler^.locals[i];
    if (IdentifiersEqual(name, @local^.name)) then
    begin
      if (local^.depth = -1) then
        error('Não é possível ler a variável local em seu próprio inicializador.');

      Exit(i);
    end;
  end;

  Result := -1;
end;

function AddUpvalue(Compiler: PCompiler; Index: UInt8; IsLocal: Boolean): Integer;
var
  UpvalueCount: Integer;
  Upvalue: PUpvalue;
  i: Integer;
begin
  UpvalueCount := Compiler^.Func^.UpvalueCount;

  for i := 0 to UpvalueCount - 1 do
  begin
    Upvalue := @Compiler^.Upvalues[i];
    if (Upvalue^.Index = Index) and (Upvalue^.IsLocal = IsLocal) then
      Exit(i);
  end;

  if (UpvalueCount = UINT8_COUNT) then
  begin
    Error('Muitas variáveis de fechamento na função.');
    Exit(0);
  end;

  Compiler^.Upvalues[UpvalueCount].IsLocal := IsLocal;
  compiler^.Upvalues[UpvalueCount].Index := Index;
  Result := Compiler^.Func^.UpvalueCount;
  Compiler^.Func^.UpvalueCount := Compiler^.Func^.UpvalueCount + 1;
end;

function ResolveUpvalue(Compiler: PCompiler; Name: PToken): Integer;
var
  Local,
  Upvalue: Integer;
begin
  if (Compiler^.Enclosing = nil) then
    Exit(-1);

  Local := ResolveLocal(Compiler^.Enclosing, Name);
  if (local <> -1) then
  begin
    Compiler^.Enclosing^.Locals[Local].IsCaptured := True;
    Exit(AddUpvalue(Compiler, UInt8(Local), True));
  end;

  Upvalue := ResolveUpvalue(Compiler^.Enclosing, Name);
  if (Upvalue <> -1) then
    Exit(AddUpvalue(compiler, UInt8(Upvalue), False));

  Result := -1;
end;

procedure AddLocal(Name: TToken);
var
  Local: PLocal;
begin
  if (current^.localCount = UINT8_COUNT) then
  begin
    error('Muitas variáveis locais na função.');
    Exit;
  end;

  Local := @current^.Locals[current^.LocalCount];
  Current^.LocalCount := Current^.LocalCount + 1;
  Local^.Name := Name;
  Local^.Depth := -1;
  Local^.IsCaptured := False;
end;

procedure DeclareVariable();
var
  name: PToken;
  i: Integer;
  local: PLocal;
begin
  // Global variables are implicitly declared.
  if (current^.ScopeDepth = 0) then
    Exit();

  name := @parser.previous;


  for i := Current^.LocalCount - 1 downto 0 do
  begin
    local := @current^.locals[i];
    if (local^.depth <> -1) and (local^.depth < current^.scopeDepth) then
      break;

    if IdentifiersEqual(name, @local^.name) then
      error('Variável com este nome já declarada neste escopo.');
  end;

  addLocal(name^);
end;

function ParseVariable(ErrorMessage: PUTF8Char): UInt8;
begin
  Consume(TTokenType.TOKEN_IDENTIFIER, ErrorMessage);

  DeclareVariable();

  if (Current^.ScopeDepth > 0) then
    Exit(0);

  Result := IdentifierConstant(@Parser.Previous);
end;

procedure MarkInitialized();
begin
  if (Current^.ScopeDepth = 0) then
    Exit();

  Current^.Locals[current^.localCount - 1].Depth := Current^.ScopeDepth;
end;

procedure DefineVariable(Global: UInt8);
begin
  if (Current^.ScopeDepth > 0) then
  begin
    MarkInitialized();
    Exit();
  end;

  EmitBytes(Byte(TOpCode.OP_DEFINE_GLOBAL), Global);
end;

function ArgumentList(): UInt8;
var
  ArgCount: UInt8;
begin
  ArgCount := 0;

  if not Check(TTokenType.TOKEN_RIGHT_PAREN) then
  begin
    repeat
      Expression();

      if (ArgCount = 255) then
        Error('Não pode ter mais de 255 argumentos.');

      ArgCount := ArgCount + 1;
    until not (Match(TTokenType.TOKEN_COMMA));
  end;

  consume(TTokenType.TOKEN_RIGHT_PAREN, 'Esperado ")" depois de argumentos.');
  Result := ArgCount;
end;

function GetRule(TokenType: TTokenType): PParseRule;
begin
  Result := @Rules[TokenType];
end;

procedure Unary(CanAssign: Boolean);
var
  OperatorType: TTokenType;
begin
  OperatorType := Parser.Previous.TokenType;

  // Compile the operand.
  ParsePrecedence(TPrecedence.PREC_UNARY);

  // Emit the operator instruction.
  case (OperatorType) of
    TTokenType.TOKEN_BANG: EmitByte(Byte(TOpCode.OP_NOT));
    TTokenType.TOKEN_MINUS: EmitByte(Byte(TOpCode.OP_NEGATE));
    else
      Exit(); // Unreachable.
  end;
end;

procedure Expression();
begin
  ParsePrecedence(TPrecedence.PREC_ASSIGNMENT);
end;

procedure Func(FunctionType: TFunctionType);
var
  Compiler: TCompiler;
  FunctionPtr: PObjFunction;
  ParamConstant: UInt8;
  i: Integer;
begin
  InitCompiler(@Compiler, FunctionType);
  BeginScope();

  // Compile the parameter list.
  Consume(TTokenType.TOKEN_LEFT_PAREN, 'Esperado "(" após o nome da função.');


  if not Check(TTokenType.TOKEN_RIGHT_PAREN) then
  begin
    repeat
      Current^.Func^.Arity := Current^.Func^.Arity + 1;
      if (Current^.Func^.arity > 255) then
        ErrorAtCurrent('Não pode ter mais de 255 parâmetros.');

      ParamConstant := ParseVariable('Espere o nome do parâmetro.');
      DefineVariable(ParamConstant);
    until not Match(TTokenType.TOKEN_COMMA);
  end;

  Consume(TTokenType.TOKEN_RIGHT_PAREN, 'Esperado ")" depois dos parâmetros.');

  // The body.
  Consume(TTokenType.TOKEN_LEFT_BRACE, 'Esperado "{" antes do corpo da função.');
  Block();

  // Create the function object.
  FunctionPtr := EndCompiler();
  EmitBytes(Byte(TOpCode.OP_CLOSURE), MakeConstant(OBJ_VAL(FunctionPtr)));

  for i := 0 to FunctionPtr^.UpvalueCount - 1 do
  begin
    EmitByte(IfThen(compiler.Upvalues[i].IsLocal, 1, 0));
    EmitByte(compiler.Upvalues[i].Index);
  end;
end;

procedure Block();
begin
  while not Check(TTokenType.TOKEN_RIGHT_BRACE) and not Check(TTokenType.TOKEN_EOF) do
    Declaration();

  Consume(TTokenType.TOKEN_RIGHT_BRACE, 'Esperado "}" depois do bloco.');
end;




procedure FunDeclaration();
var
  Global: UInt8;
begin
  Global := ParseVariable('Esperado o nome da função.');
  MarkInitialized();

  Func(TFunctionType.TYPE_FUNCTION);

  DefineVariable(Global);
end;

procedure VarDeclaration();
var
  Global: UInt8;
begin
  Global := ParseVariable('Esperado o nome da variável.');

  if Match(TTokenType.TOKEN_EQUAL) then
    Expression()
  else
    EmitByte(Byte(TOpCode.OP_NIL));

  consume(TTokenType.TOKEN_SEMICOLON, 'Esperado ";" após declaração de variável.');

  DefineVariable(Global);
end;

procedure ExpressionStatement();
begin
  Expression();
  Consume(TTokenType.TOKEN_SEMICOLON, 'Esperado ";" depois da expressão.');
  EmitByte(Byte(TOpCode.OP_POP));
end;

procedure forStatement();
var
  loopStart,
  exitJump,
  bodyJump,
  incrementStart: Integer;
begin
  beginScope();
  Consume(TTokenType.TOKEN_LEFT_PAREN, 'Esperado "(" depois de "for".');

  if (match(TTokenType.TOKEN_SEMICOLON)) then
    // No initializer.
  else if (match(TTokenType.TOKEN_VAR)) then
    varDeclaration()
  else
    expressionStatement();

  loopStart := currentChunk()^.count;

  exitJump := -1;

  if (not match(TTokenType.TOKEN_SEMICOLON)) then
  begin
    expression();
    consume(TTokenType.TOKEN_SEMICOLON, 'Esperado ";" após condição do loop.');

    // Jump out of the loop if the condition is false.
    exitJump := emitJump(Byte(TOpCode.OP_JUMP_IF_FALSE));
    emitByte(Byte(TOpCode.OP_POP)); // Condition.
  end;

  if (not match(TTokenType.TOKEN_RIGHT_PAREN)) then
  begin
    bodyJump := emitJump(Byte(TOpCode.OP_JUMP));

    incrementStart := currentChunk()^.count;
    expression();
    emitByte(Byte(TOpCode.OP_POP));
    consume(TTokenType.TOKEN_RIGHT_PAREN, 'Esperado ")" apos a clausula "for".');

    emitLoop(loopStart);
    loopStart := incrementStart;
    patchJump(bodyJump);
  end;

  Statement();

  emitLoop(loopStart);

  if (exitJump <> -1) then
  begin
    patchJump(exitJump);
    emitByte(Byte(TOpCode.OP_POP)); // Condition.
  end;

  endScope();
end;

procedure IfStatement();
var
  ThenJump,
  ElseJump: Integer;
begin
  Consume(TTokenType.TOKEN_LEFT_PAREN, 'Esperado "(" apos "if".');
  Expression();
  Consume(TTokenType.TOKEN_RIGHT_PAREN, 'Esperado ")" após condição.');

  ThenJump := EmitJump(Byte(TOpCode.OP_JUMP_IF_FALSE));
  emitByte(Byte(TOpCode.OP_POP));
  Statement();

  ElseJump := emitJump(Byte(TOpCode.OP_JUMP));

  PatchJump(ThenJump);
  emitByte(Byte(TOpCode.OP_POP));

  if (Match(TTokenType.TOKEN_ELSE)) then
    Statement();

  PatchJump(ElseJump);
end;

procedure PrintStatement();
begin
  Expression();
  Consume(TTokenType.TOKEN_SEMICOLON, 'Espero ";" depois do valor.');
  EmitByte(Byte(TOpCode.OP_PRINT));
end;

procedure ReturnStatement();
begin
  if (Current^.FunctionType = TFunctionType.TYPE_SCRIPT) then
    Error('Não é possível retornar do código de nível superior.');

  if (Match(TTokenType.TOKEN_SEMICOLON)) then
    EmitReturn()
  else
  begin
    if (Current^.FunctionType = TFunctionType.TYPE_INITIALIZER) then
      Error('Não é possível retornar um valor de um inicializador.');

    Expression();
    Consume(TTokenType.TOKEN_SEMICOLON, 'Esperado ";" após o valor de retorno.');
    EmitByte(Byte(TOpCode.OP_RETURN));
  end;
end;

procedure WhileStatement();
var
  exitJump,
  loopStart: Integer;
begin
  loopStart := currentChunk()^.count;
  consume(TTokenType.TOKEN_LEFT_PAREN, 'Esperado "(" apos "while".');
  expression();
  consume(TTokenType.TOKEN_RIGHT_PAREN, 'Esperado ")" apos a condição.');

  exitJump := emitJump(Byte(TOpCode.OP_JUMP_IF_FALSE));

  emitByte(Byte(TOpCode.OP_POP));
  statement();

  EmitLoop(loopStart);

  patchJump(exitJump);
  emitByte(Byte(TOpCode.OP_POP));
end;

procedure Synchronize();
begin
  Parser.PanicMode := False;

  while (Parser.Current.TokenType <> TTokenType.TOKEN_EOF) do
  begin
    if (Parser.previous.TokenType = TTokenType.TOKEN_SEMICOLON) then
      Exit();

    case Parser.Current.TokenType of
      TTokenType.TOKEN_CLASS,
      TTokenType.TOKEN_FUN,
      TTokenType.TOKEN_VAR,
      TTokenType.TOKEN_FOR,
      TTokenType.TOKEN_IF,
      TTokenType.TOKEN_WHILE,
      TTokenType.TOKEN_PRINT,
      TTokenType.TOKEN_RETURN: Exit();
      else
        // Do nothing.
        ;
    end;

    Advance();
  end;
end;

procedure Declaration();
begin
  if (match(TTokenType.TOKEN_CLASS)) then
    ClassDeclaration()
  else if Match(TTokenType.TOKEN_FUN) then
    FunDeclaration()
  else if Match(TTokenType.TOKEN_VAR) then
    VarDeclaration()
  else
    Statement();

  if (Parser.PanicMode) then
    Synchronize();
end;

procedure Statement();
begin
  if Match(TTokenType.TOKEN_PRINT) then
    PrintStatement()
  else if (Match(TTokenType.TOKEN_IF)) then
    IfStatement()
  else if (Match(TTokenType.TOKEN_RETURN)) then
    ReturnStatement()
  else if (match(TTokenType.TOKEN_WHILE)) then
    WhileStatement()
  else if (match(TTokenType.TOKEN_FOR)) then
    ForStatement()
  else if Match(TTokenType.TOKEN_LEFT_BRACE) then
  begin
    BeginScope();
    Block();
    EndScope();
  end
  else
    ExpressionStatement();
end;

function Compile(const Source: PUTF8Char): PObjFunction;
var
  Compiler: TCompiler;
  Func: PObjFunction;
begin
  InitScanner(Source);
  InitCompiler(@Compiler, TFunctionType.TYPE_SCRIPT);

  Parser.HadError := False;
  Parser.PanicMode := False;

  Advance();

  while not Match(TTokenType.TOKEN_EOF) do
    Declaration();

  Func := EndCompiler();

  if Parser.HadError then
    Result := nil
  else
    Result := Func;
end;

function SyntheticToken(Text: PUTF8Char): TToken;
var
  token: TToken;
begin
  token.start := text;
  token.length := System.AnsiStrings.StrLen(text);
  Result := token;
end;

procedure PushSuperclass();
begin
  if (CurrentClass = nil) then
    Exit();

  NamedVariable(SyntheticToken('super'), False);
end;

procedure Super_(canAssign: Boolean);
var
  Name,
  argCount: UInt8;
begin
  if (CurrentClass = nil) then
    Error('Não é possível usar "super" fora de uma classe.')
  else if not currentClass^.hasSuperclass then
    error('Não é possível usar "super" em uma classe sem superclasse.');

  Consume(TTokenType.TOKEN_DOT, 'Esperado "." apos "super".');
  Consume(TTokenType.TOKEN_IDENTIFIER, 'Espere o nome do método da superclasse.');
  Name := IdentifierConstant(@parser.previous);

  // Push the receiver.
  namedVariable(syntheticToken('this'), false);

  if (match(TTokenType.TOKEN_LEFT_PAREN)) then
  begin
    argCount := ArgumentList();

    pushSuperclass();
    emitBytes(Byte(TOpCode.OP_SUPER), argCount);
    emitByte(Name);
  end
  else
  begin
    pushSuperclass();
    emitBytes(Byte(TOpCode.OP_GET_SUPER), Name);
  end;
end;

//< Superclasses not-yet
//> Methods and Initializers not-yet
procedure This_(canAssign: Boolean);
begin
  if (CurrentClass = nil) then
    error('Não é possível usar "this" fora de uma classe.')
  else
    variable(False);

end;


procedure method();
const
  INIT_METHOD: PUTF8Char = 'init';
var
  constant: UInt8;
  FunctionType: TFunctionType;
begin
  consume(TTokenType.TOKEN_IDENTIFIER, 'Espere o nome do método.');
  Constant := IdentifierConstant(@parser.previous);

  // If the method is named "init", it's an initializer.
  FunctionType := TFunctionType.TYPE_METHOD;
  if (parser.previous.length = 4) and  CompareMem(parser.previous.start, INIT_METHOD, parser.previous.Length) then
    FunctionType := TFunctionType.TYPE_INITIALIZER;

  func(FunctionType);

  emitBytes(Byte(TOpCode.OP_METHOD), constant);
end;


procedure classDeclaration();
var
  ClassName: TToken;
  NameConstant: UInt8;
  ClassCompiler: TClassCompiler;
begin
  Consume(TTokenType.TOKEN_IDENTIFIER, 'Espere o nome da classe.');
  ClassName := Parser.Previous;
  NameConstant := IdentifierConstant(@parser.previous);
  DeclareVariable();

  EmitBytes(Byte(TOpCode.OP_CLASS), NameConstant);
  DefineVariable(NameConstant);

  ClassCompiler.Name := Parser.previous;
  ClassCompiler.HasSuperclass := False;
  ClassCompiler.Enclosing := CurrentClass;
  CurrentClass := @ClassCompiler;

  if (match(TTokenType.TOKEN_LESS)) then
  begin
    consume(TTokenType.TOKEN_IDENTIFIER, 'Esperado o nome da superclasse.');

    if (identifiersEqual(@className, @parser.previous)) then
      error('Uma classe não pode herdar de si mesma.');

    classCompiler.HasSuperclass := True;


    BeginScope();

    // Store the superclass in a local variable named "super".
    Variable(False);
    AddLocal(syntheticToken('super'));
    DefineVariable(0);

    NamedVariable(ClassName, False);
    EmitByte(Byte(TOpCode.OP_INHERIT));
  end;

  Consume(TTokenType.TOKEN_LEFT_BRACE, 'Esperado "{" antes do corpo da classe.');

  while not check(TTokenType.TOKEN_RIGHT_BRACE) and not Check(TTokenType.TOKEN_EOF) do
  begin
    NamedVariable(className, false);
    Method();
  end;

  consume(TTokenType.TOKEN_RIGHT_BRACE, 'Esperado "}" depois do corpo da aula.');

  if (classCompiler.hasSuperclass) then
    EndScope();

  CurrentClass := CurrentClass^.Enclosing;
end;


procedure grayCompilerRoots();
var
  compiler: PCompiler;
begin
  compiler := current;

  while (compiler <> nil) do
  begin
    grayObject(PObj(compiler^.func));
    compiler := compiler^.enclosing;
  end;
end;


end.
