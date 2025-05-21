// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  System.SysUtils,
  WinAPI.Windows,
  System.AnsiStrings,
  LoxLanguage.VirtualMachine.Value,
  LoxLanguage.VirtualMachine.Consts,
  LoxLanguage.VirtualMachine.Chunk,
  LoxLanguage.VirtualMachine.Table,
  LoxLanguage.VirtualMachine.Obj,
  LoxLanguage.VirtualMachine.Types;

type
  TInterpretResult = (INTERPRET_OK, INTERPRET_COMPILE_ERROR, INTERPRET_RUNTIME_ERROR);

  PCallFrame = ^TCallFrame;
  TCallFrame = record
    Closure: PObjClosure;
    IP: PUint8;
    Slots: PValue;
  end;

  TVM = record
    Frames: array[0..FRAMES_MAX-1] of TCallFrame;
    FrameCount: Integer;
    Stack: array[0..STACK_MAX-1] of TValue;
    StackTop: PValue;
    Globals: TTable;
    Strings: TTable;
    InitString: PObjString;
    OpenUpvalues: PObjUpvalue;
    bytesAllocated: Cardinal;
    nextGC: Cardinal;

    Objects: PObj;

    GrayCount: Integer;
    GrayCapacity: Integer;
    GrayStack: PPObj;
  end;

procedure Push(Value: TValue);
function Pop(): TValue;
function Interpret(Source: UTF8String): TInterpretResult;
procedure InitVM();
procedure FreeVM();

var
  VM: TVM;

implementation

uses
  LoxLanguage.VirtualMachine.Debug,
  LoxLanguage.VirtualMachine.Memory,
  LoxLanguage.VirtualMachine.Compiler;

function Peek(Distance: Integer): TValue; forward;
function IsFalsey(Value: TValue): Boolean; forward;
procedure Concatenate(); forward;
function CallValue(Callee: TValue; ArgCount: Integer): Boolean; forward;
function CaptureUpvalue(local: PValue): PObjUpvalue; forward;
procedure CloseUpvalues(last: PValue); forward;
function Run(): TInterpretResult; forward;
procedure DefineNative(const Name: PUTF8Char; Func: TNativeFn); forward;
function ClockNative(argCount: Integer; Args: PValue): TValue; forward;

procedure ResetStack();
begin
  VM.StackTop := @VM.Stack[0];
  VM.FrameCount := 0;
  vm.OpenUpvalues := nil;
end;

procedure InitVM();
begin
  VM := Default(TVM);
  ResetStack();
  vm.Objects := nil;

  vm.bytesAllocated := 0;
  vm.nextGC := 1024 * 1024;

  vm.grayCount := 0;
  vm.grayCapacity := 0;
  vm.grayStack := nil;

  InitTable(@VM.Globals);
  InitTable(@VM.Strings);

  vm.initString := CopyString('init', 4);

  DefineNative('clock', ClockNative);
end;

function ClockNative(argCount: Integer; Args: PValue): TValue;
begin
  Result := NUMBER_VAL(GetTickCount() / CLOCKS_PER_SEC);
end;



procedure RuntimeError(const FormatStr: string; const Args: array of const);
var
  Instruction: Cardinal;
  Frame: PCallFrame;
  Func: PObjFunction;
  i: Integer;
begin
  Writeln(Format(FormatStr, Args));

  for i := vm.frameCount - 1 downto 0 do
  begin
    Frame := @VM.Frames[i];
    Func := Frame^.Closure^.Func;

    Instruction := Frame^.IP - Func^.Chunk.Code - 1;
    Write(Format('[Linha %d] em ', [Func^.Chunk.Lines[instruction]]));
    if Func^.name = nil then
      WriteLn('script')
    else
      WriteLn(Format('%s()', [System.AnsiStrings.StrPas(Func^.Name^.Chars)]));
  end;

  ResetStack();
end;

procedure DefineNative(const Name: PUTF8Char; Func: TNativeFn);
begin
  Push(OBJ_VAL(CopyString(name, System.AnsiStrings.StrLen(name))));
  Push(OBJ_VAL(NewNative(Func)));
  TableSet(@VM.Globals, AS_STRING(VM.Stack[0]), VM.Stack[1]);
  Pop();
  Pop();
end;


procedure FreeVM();
begin
  FreeTable(@VM.Globals);
  FreeTable(@VM.Strings);
  vm.initString := nil;
  FreeObjects();
end;

function READ_BYTE: Byte;
begin
  Result := VM.Frames[VM.FrameCount - 1].IP^;
  VM.Frames[VM.FrameCount - 1].IP := VM.Frames[VM.FrameCount - 1].IP + 1;
end;

function READ_CONSTANT(): TValue;
begin
  Result := VM.Frames[VM.FrameCount - 1].Closure^.Func^.chunk.Constants.Values[READ_BYTE()];
end;

procedure BINARY_OP_ADD;
var
  b: Double;
  a: Double;
begin
  b := AS_NUMBER(Pop());
  a := AS_NUMBER(Pop());
  Push(NUMBER_VAL(a + b));
end;

procedure BINARY_OP_GREATER;
var
  b: Double;
  a: Double;
begin
  b := AS_NUMBER(Pop());
  a := AS_NUMBER(Pop());
  Push(BOOL_VAL(a > b));
end;

procedure BINARY_OP_LESS;
var
  b: Double;
  a: Double;
begin
  b := AS_NUMBER(Pop());
  a := AS_NUMBER(Pop());
  Push(BOOL_VAL(a < b));
end;

procedure BINARY_OP_SUB;
var
  b: Double;
  a: Double;
begin
  b := AS_NUMBER(Pop());
  a := AS_NUMBER(Pop());
  Push(NUMBER_VAL(a - b));
end;

procedure BINARY_OP_MUL;
var
  b: Double;
  a: Double;
begin
  b := AS_NUMBER(Pop());
  a := AS_NUMBER(Pop());
  Push(NUMBER_VAL(a * b));
end;

procedure BINARY_OP_DIV;
var
  b: Double;
  a: Double;
begin
  b := AS_NUMBER(Pop());
  a := AS_NUMBER(Pop());
  Push(NUMBER_VAL(a / b));
end;

function READ_STRING: PObjString;
begin
  Result := AS_STRING(READ_CONSTANT());
end;

function READ_SHORT: UInt16;
begin
  VM.Frames[VM.FrameCount - 1].IP := VM.Frames[VM.FrameCount - 1].IP + 2;
  Result := UInt16((VM.Frames[VM.FrameCount - 1].IP[-2] shl 8) or VM.Frames[VM.FrameCount - 1].IP[-1]);
end;

function BindMethod(klass: PObjClass; Name: PObjString): Boolean;
var
  method: TValue;
  bound: PObjBoundMethod;
begin

  if not tableGet(@klass^.methods, name, @method) then
  begin
    runtimeError('Somente instâncias têm propriedades... "%s".', [name^.chars]);
    Exit(False);
  end;

  bound := newBoundMethod(peek(0), AS_CLOSURE(method));
  pop(); // Instance.
  push(OBJ_VAL(bound));
  Result := true;
end;

function Call(ObjClosure: PObjClosure; ArgCount: Integer): Boolean;
var
  Frame: PCallFrame;
begin
  if (ArgCount <> ObjClosure^.Func^.Arity) then
  begin
    RuntimeError('Esperado %d argumentos, mas tem %d.', [ObjClosure^.Func^.Arity, ArgCount]);
    Exit(False);
  end;

  if (VM.FrameCount = FRAMES_MAX) then
  begin
    RuntimeError('Estouro de pilha.', []);
    Exit(False);
  end;

  Frame := @VM.Frames[VM.FrameCount];
  VM.FrameCount := VM.FrameCount + 1;
  Frame^.Closure := ObjClosure;
  Frame^.IP := ObjClosure^.Func^.chunk.code;

  Frame^.Slots := VM.StackTop - ArgCount - 1;
  Result := True;
end;


function invokeFromClass(klass: PObjClass; name: PObjString; argCount: integer): Boolean;
var
  method: TValue;
begin
  // Look for the method.

  if not tableGet(@klass^.methods, name, @method) then
  begin
    RuntimeError('Propriedade indefinida "%s".', [name^.chars]);
    Exit(false);
  end;

  Result := Call(AS_CLOSURE(method), argCount);
end;


function Invoke(Name: PObjString; argCount: Integer): Boolean;
var
  Receiver: TValue;
  instance: PObjInstance;
  value: TValue;
begin
  Receiver := Peek(ArgCount);

  if not IS_INSTANCE(Receiver) then
  begin
    runtimeError('Somente instâncias têm métodos.', []);
    Exit(false);
  end;

  Instance := AS_INSTANCE(Receiver);

  // First look for a field which may shadow a method.

  if (tableGet(@instance^.fields, name, @value)) then
  begin
    vm.stackTop[-argCount] := value;
    Exit(callValue(value, argCount));
  end;

  Result := invokeFromClass(instance^.klass, name, argCount);
end;

procedure DefineMethod(Name: PObjString);
var
  method: TValue;
  Klass: PObjClass;
begin
  Method := Peek(0);
  Klass := AS_CLASS(Peek(1));
  tableSet(@klass^.methods, name, method);
  pop();
  pop();
end;

procedure Hack(b: Boolean);
begin
  // Hack to avoid unused function error. run() is not used in the
  // scanning chapter.
  run();

  if (b) then
    hack(false);
end;


function Run(): TInterpretResult;
var
  Instruction: Byte;
  Constant: TValue;
  SlotIndex: UInt8;
  b: TValue;
  a: TValue;
  Name: PObjString;
  i: Integer;
  superclassValue: TValue;
  subclass: PObjClass;
  superclass: PObjClass;
  instance: pObjInstance;
  method: PObjString;
  Value,
  Return: TValue;
  Offset: UInt16;
  IsLocal,
  Index: Integer;
  Frame: PCallFrame;
  ArgCount: Integer;
  ObjFunc: PObjFunction;
  ObjClosure: PObjClosure;
  PasCount: Integer;
begin
  Frame := @VM.Frames[VM.FrameCount - 1];
  PasCount := 0;
  while True do
  begin
{$IFDEF DEBUG_TRACE_EXECUTION}
    System.Write('          ');
    Slot := @VM.Stack[0];

    while Slot <= VM.StackTop do
    begin
      Write('[ ');
      PrintValue(Slot^);
      Write(' ]');
      inc(Slot);
    end;

    Writeln('');

    DisassembleInstruction(@Frame^.Closure^.Func^.chunk, Frame^.IP - Frame^.Closure^.Func.chunk.Code);
{$ENDIF}

    Instruction := READ_BYTE();

    Inc(PasCount);

    if PasCount = 515 then
    begin
      PasCount := PasCount + 1;
    end;

    case TOpCode(Instruction) of
      TOpCode.OP_CONSTANT:
      begin
        Constant := READ_CONSTANT();
        Push(Constant);
      end;
      TOpCode.OP_NIL: Push(NIL_VAL());
      TOpCode.OP_TRUE: Push(BOOL_VAL(True));
      TOpCode.OP_FALSE: Push(BOOL_VAL(False));
      TOpCode.OP_POP: Pop();
      TOpCode.OP_GET_LOCAL:
      begin
        SlotIndex := READ_BYTE();
        push(Frame^.Slots[SlotIndex]);
      end;
      TOpCode.OP_SET_LOCAL:
      begin
        SlotIndex := READ_BYTE();
        Frame^.Slots[SlotIndex] := peek(0);
      end;
      TOpCode.OP_GET_GLOBAL:
      begin
        Name := READ_STRING();
        if not TableGet(@VM.Globals, Name, @Value) then
        begin
          RuntimeError('Variável indefinida "%s".', [Name^.Chars]);
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
        end;
        push(value);
      end;
      TOpCode.OP_DEFINE_GLOBAL:
      begin
        Name := READ_STRING();
        TableSet(@VM.Globals, Name, Peek(0));
        Pop();
      end;
      TOpCode.OP_SET_GLOBAL:
      begin
        Name := READ_STRING();
        if (TableSet(@VM.Globals, Name, Peek(0))) then
        begin
          TableDelete(@vm.globals, Name);
          RuntimeError('Variável indefinida "%s".', [Name^.Chars]);
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
        end;
      end;
      TOpCode.OP_GET_UPVALUE:
      begin
        SlotIndex := READ_BYTE();
        Push(Frame^.Closure^.Upvalues[SlotIndex]^.Location^);
      end;
      TOpCode.OP_SET_UPVALUE:
      begin
        SlotIndex := READ_BYTE();
        Frame^.Closure^.Upvalues[SlotIndex]^.Location^ := peek(0);
      end;
      TOpCode.OP_GET_PROPERTY:
      begin
        if not IS_INSTANCE(peek(0)) then
        begin
          RuntimeError('Somente instâncias têm propriedades.', []);
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
        end;

        instance := AS_INSTANCE(peek(0));
        name := READ_STRING();

        if (tableGet(@instance^.fields, name, @value)) then
        begin
          pop(); // Instance.
          push(value);
        end
        else if not BindMethod(instance^.Klass, name) then
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
      end;


      TOpCode.OP_SET_PROPERTY:
      begin
        if not IS_INSTANCE(peek(1)) then
        begin
          runtimeError('Somente instâncias têm campos.', []);
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
        end;

        instance := AS_INSTANCE(peek(1));
        tableSet(@instance^.fields, READ_STRING(), peek(0));
        value := pop();
        pop();
        push(Value);
      end;

      TOpCode.OP_GET_SUPER:
      begin
        name := READ_STRING();
        superclass := AS_CLASS(pop());
        if not bindMethod(superclass, name) then
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
      end;


      TOpCode.OP_EQUAL:
      begin
        b := Pop();
        a := Pop();
        Push(BOOL_VAL(ValuesEqual(a, b)));
      end;
      TOpCode.OP_GREATER: BINARY_OP_GREATER();
      TOpCode.OP_LESS: BINARY_OP_LESS();
      TOpCode.OP_ADD:
      begin
        if (IS_STRING(peek(0)) and IS_STRING(peek(1))) then
          Concatenate()
        else if (IS_NUMBER(peek(0)) and IS_NUMBER(peek(1))) then
        begin
          b := Pop();
          a := Pop();
          Push(NUMBER_VAL(AS_NUMBER(a) + AS_NUMBER(b)));
        end
        else
        begin
          RuntimeError('Os operandos devem ter dois números ou duas strings.', []);
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
        end;
      end;
      TOpCode.OP_SUBTRACT: BINARY_OP_SUB();
      TOpCode.OP_MULTIPLY: BINARY_OP_MUL();
      TOpCode.OP_DIVIDE: BINARY_OP_DIV();
      TOpCode.OP_NOT: Push(BOOL_VAL(IsFalsey(Pop())));
      TOpCode.OP_NEGATE:
      begin
        if not IS_NUMBER(Peek(0)) then
        begin
          RuntimeError('O operando deve ser um número.', []);
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
        end;

        Push(NUMBER_VAL(-AS_NUMBER(Pop())));
      end;
      TOpCode.OP_PRINT:
      begin
        PrintValue(Pop());
        Writeln('');
      end;
      TOpCode.OP_JUMP:
      begin
        offset := READ_SHORT();
        Frame^.IP := Frame^.IP + offset;
      end;
      TOpCode.OP_JUMP_IF_FALSE:
      begin
        offset := READ_SHORT();
        if (isFalsey(peek(0))) then
          Frame^.IP := Frame^.IP + offset;
      end;
      TOpCode.OP_LOOP:
      begin
        offset := READ_SHORT();
        Frame^.IP := Frame^.IP - offset;
      end;
      TOpCode.OP_CALL:
      begin
        ArgCount := READ_BYTE();
        if not CallValue(Peek(ArgCount), ArgCount) then
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);

        Frame := @VM.Frames[VM.FrameCount - 1];
      end;

      TOpCode.OP_INVOKE:
      begin
        argCount := READ_BYTE();
        method := READ_STRING();
        if not Invoke(method, argCount) then
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);

        frame := @vm.frames[vm.frameCount - 1];
      end;

      TOpCode.OP_SUPER:
      begin
        argCount := READ_BYTE();
        method := READ_STRING();
        superclass := AS_CLASS(pop());
        if not invokeFromClass(superclass, method, argCount) then
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);

        frame := @vm.frames[vm.frameCount - 1];
      end;


      TOpCode.OP_CLOSURE:
      begin
        ObjFunc := AS_FUNCTION(READ_CONSTANT());
        ObjClosure := NewClosure(ObjFunc);
        Push(OBJ_VAL(ObjClosure));


        for i := 0 to ObjClosure^.UpvalueCount - 1 do
        begin
          IsLocal := READ_BYTE();
          Index := READ_BYTE();
          if (IsLocal <> 0) then
            ObjClosure^.Upvalues[i] := CaptureUpvalue(Frame^.Slots + Index)
          else
            ObjClosure^.Upvalues[i] := Frame^.Closure^.Upvalues[index]
        end;

      end;
      TOpCode.OP_CLOSE_UPVALUE:
      begin
        CloseUpvalues(vm.stackTop - 1);
        Pop();
      end;
      TOpCode.OP_RETURN:
      begin
        Return := Pop();

        CloseUpvalues(Frame^.Slots);

        VM.FrameCount := VM.FrameCount - 1;
        if (VM.FrameCount = 0) then
        begin
          Pop();
          Exit(TInterpretResult.INTERPRET_OK);
        end;

        VM.StackTop := Frame^.Slots;
        Push(Return);

        Frame := @VM.Frames[vm.frameCount - 1];
      end;


      TOpCode.OP_CLASS:
      begin
        push(OBJ_VAL(newClass(READ_STRING())));
      end;
      TOpCode.OP_INHERIT:
      begin
        superclassValue := peek(1);
        if not IS_CLASS(superclassValue) then
        begin
          runtimeError('A superclasse deve ser uma classe.', []);
          Exit(TInterpretResult.INTERPRET_RUNTIME_ERROR);
        end;

        subclass := AS_CLASS(peek(0));
        tableAddAll(@AS_CLASS(superclassValue)^.methods, @subclass^.methods);
        pop(); // Subclass.
      end;
      TOpCode.OP_METHOD:
      begin
        DefineMethod(READ_STRING());
      end;
    end;
  end;
end;

function Interpret(Source: UTF8String): TInterpretResult;
var
  Func: PObjFunction;
  Closure: PObjClosure;
begin
  Func := Compile(PUTF8Char(source));
  if (Func = nil) then
    Exit(TInterpretResult.INTERPRET_COMPILE_ERROR);

  Push(OBJ_VAL(Func));
  Closure := NewClosure(Func);
  Pop();
  Push(OBJ_VAL(Closure));
  CallValue(OBJ_VAL(Closure), 0);

  Result := Run();

end;

procedure Push(Value: TValue);
begin
  VM.StackTop^ := Value;
  VM.StackTop := VM.StackTop + 1;
end;

function Pop(): TValue;
begin
  Dec(VM.StackTop);
  Result := VM.StackTop^;
end;

function Peek(Distance: Integer): TValue;
begin
  Result := VM.StackTop[-1 - Distance];
end;


function CallValue(Callee: TValue; ArgCount: Integer): Boolean;
var
  Native: TNativeFn;
  Return: TValue;
  Bound: PObjBoundMethod;
  klass: PObjClass;
  initializer: TValue;
begin
  if (IS_OBJ(Callee)) then
  begin
    case (OBJ_TYPE(callee)) of
      TObjType.OBJ_BOUND_METHOD:
      begin
        bound := AS_BOUND_METHOD(callee);

        // Replace the bound method with the receiver so it's in the
        // right slot when the method is called.
        vm.stackTop[-argCount - 1] := bound^.receiver;
        Exit(call(bound^.method, argCount));
      end;
      TObjType.OBJ_CLASS:
      begin
        klass := AS_CLASS(callee);

        // Create the instance.
        vm.stackTop[-argCount - 1] := OBJ_VAL(newInstance(klass));
        // Call the initializer, if there is one.
        if (tableGet(@klass^.methods, vm.initString, @initializer)) then
          Exit(call(AS_CLOSURE(initializer), argCount))
        else if (argCount <> 0) then
        begin
          runtimeError('Esperado 0 argumentos, mas tenho %d.', [argCount]);
          eXIT(false);
        end;

        Exit(true);
      end;
      TObjType.OBJ_CLOSURE:
      begin
        Exit(Call(AS_CLOSURE(callee), argCount));
      end;
      TObjType.OBJ_NATIVE:
      begin
        native := AS_NATIVE(callee);
        Return := native(argCount, vm.stackTop - argCount);
        vm.stackTop := vm.stackTop - argCount + 1;
        push(return);
        Exit(true);
      end;
    else
        // Non-callable object type.
        ;//break;
    end;
  end;

  RuntimeError('Só pode fazer chamada de funções e classes.', []);
  Result := False;
end;

function CaptureUpvalue(Local: PValue): PObjUpvalue;
var
  CreatedUpvalue: PObjUpvalue;
  PrevUpvalue: PObjUpvalue;
  Upvalue: PObjUpvalue;
begin

  PrevUpvalue := nil;
  Upvalue := VM.OpenUpvalues;

  while (Upvalue <> nil) and (Upvalue^.Location > Local) do
  begin
    PrevUpvalue := Upvalue;
    Upvalue := Upvalue^.Next;
  end;

  if (Upvalue <> nil) and (Upvalue^.Location = Local) then
    Exit(Upvalue);

  CreatedUpvalue := NewUpvalue(Local);
  createdUpvalue^.Next := Upvalue;

  if (PrevUpvalue = nil) then
    VM.OpenUpvalues := CreatedUpvalue
  else
    PrevUpvalue^.Next := CreatedUpvalue;

  Result := CreatedUpvalue;
end;

procedure CloseUpvalues(last: PValue);
var
  ObjUpvaluePtr: PObjUpvalue;
begin
  while (vm.openUpvalues <> nil) and (vm.openUpvalues^.Location >= Last) do
  begin
    ObjUpvaluePtr := vm.openUpvalues;
    ObjUpvaluePtr^.closed := ObjUpvaluePtr^.Location^;
    ObjUpvaluePtr^.location := @ObjUpvaluePtr^.Closed;
    vm.openUpvalues := ObjUpvaluePtr^.next;
  end;
end;



function IsFalsey(Value: TValue): Boolean;
begin
  Result := (IS_NIL(Value) or (IS_BOOL(value)) and not AS_BOOL(Value));
end;

procedure Concatenate();
var
  b,
  a: PObjString;
  Length: Integer;
  chars: PUTF8Char;
  Return: PObjString;
begin
  b := AS_STRING(peek(0));
  a := AS_STRING(peek(1));

  Length := a^.Length + b^.length;
  chars := reallocate(nil, 0, sizeof(UTF8Char) * (length + 1));
  CopyMemory(chars, a^.chars, a^.length);
  CopyMemory(chars + a^.length, b^.chars, b^.length);
  chars[length] := #0;

  Return := TakeString(chars, length);

  pop();
  pop();

  push(OBJ_VAL(Return));
end;

end.
