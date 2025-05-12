// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Obj;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  LoxLanguage.VirtualMachine.Value,
  LoxLanguage.VirtualMachine.Types,
  LoxLanguage.VirtualMachine.Chunk;


function NewBoundMethod(receiver: TValue; Method: PObjClosure): PObjBoundMethod;
function NewClass(Name: PObjString): PObjClass;
function NewInstance(Klass: PObjClass): PObjInstance;


function NewClosure(Func: PObjFunction): PObjClosure;
function NewFunction(): PObjFunction;


function NewNative(Func: TNativeFn): PObjNative;

function CopyString(Chars: PUTF8Char; Length: Integer): PObjString;
function TakeString(Chars: PUTF8Char; Length: Integer): PObjString;

function OBJ_TYPE(Value: TValue): TObjType;

function IS_CLOSURE(Value: TValue): Boolean;
function IS_FUNCTION(Value: TValue): Boolean;
function IS_NATIVE(Value: TValue): Boolean;
function IS_STRING(Value: TValue): Boolean;
function IS_INSTANCE(Value: TValue): Boolean;
function IS_CLASS(Value: TValue): Boolean;

function AS_CLOSURE(Value: TValue): PObjClosure;
function AS_FUNCTION(Value: TValue): PObjFunction;

function AS_CLASS(Value: TValue): PObjClass;
function AS_BOUND_METHOD(Value: TValue): PObjBoundMethod;
function AS_INSTANCE(Value: TValue): PObjInstance;

function AS_NATIVE(Value: TValue): TNativeFn;
function AS_STRING(Value: TValue): PObjString;
function AS_CSTRING(Value: TValue): PUTF8Char;

procedure PrintObject(Value: TValue);

function NewUpvalue(Slot: Pointer): PObjUpValue;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  LoxLanguage.VirtualMachine,
  LoxLanguage.VirtualMachine.Memory,
  LoxLanguage.VirtualMachine.Table;

function IsObjType(Value: TValue; ObjType: TObjType): Boolean;
begin
  Result := IS_OBJ(Value) and (PObj(AS_OBJ(Value))^.ObjType = ObjType);
end;

function OBJ_TYPE(Value: TValue): TObjType;
var
  Obj: ^TObj;
begin
  Obj := AS_OBJ(Value);
  Result := Obj^.ObjType;
end;

function IS_STRING(Value: TValue): Boolean;
begin
  Result := IsObjType(Value, TObjType.OBJ_STRING);
end;

function IS_INSTANCE(Value: TValue): Boolean;
begin
  Result := IsObjType(Value, TObjType.OBJ_INSTANCE);
end;

function IS_CLASS(Value: TValue): Boolean;
begin
  Result := IsObjType(Value, TObjType.OBJ_CLASS);
end;


function IS_CLOSURE(Value: TValue): Boolean;
begin
  Result := IsObjType(Value, TObjType.OBJ_CLOSURE);
end;


function IS_FUNCTION(Value: TValue): Boolean;
begin
  Result := IsObjType(Value, TObjType.OBJ_FUNCTION);
end;

function IS_NATIVE(Value: TValue): Boolean;
begin
  Result := IsObjType(Value, TObjType.OBJ_NATIVE);
end;

function AS_FUNCTION(Value: TValue): PObjFunction;
begin
  Result := AS_OBJ(Value);
end;

function AS_CLASS(Value: TValue): PObjClass;
begin
  Result := AS_OBJ(Value);
end;


function AS_BOUND_METHOD(Value: TValue): PObjBoundMethod;
begin
  Result := PObjBoundMethod(AS_OBJ(Value));
end;

function AS_INSTANCE(Value: TValue): PObjInstance;
begin
  Result := AS_OBJ(Value);
end;

function AS_CLOSURE(Value: TValue): PObjClosure;
begin
  Result := AS_OBJ(Value);
end;

function AS_NATIVE(Value: TValue): TNativeFn;
begin
  Result := PObjNative(AS_OBJ(Value))^.Func;
end;

function AS_STRING(Value: TValue): PObjString;
begin
  Result := AS_OBJ(Value);
end;

function AS_CSTRING(Value: TValue): PUTF8Char;
var
  Obj: PObjString;
begin
  Obj := AS_OBJ(Value);
  Result := Obj^.Chars;
end;

function AllocateObject(Size: Integer; ObjType: TObjType): Pointer;
var
  Obj: PObj;
begin
  Obj := Reallocate(nil, 0, Size);
  Obj^.ObjType := ObjType;
  Obj^.IsDark := False;

  Obj^.Next := VM.Objects;
  VM.Objects := Obj;

  Result := Obj;
end;

function AllocateString(Chars: PUTF8Char; Length: Integer; Hash: Cardinal): PObjString;
var
  Str: PObjString;
begin
  Str := AllocateObject(SizeOf(TObjString), TObjType.OBJ_STRING);
  Str^.length := Length;
  Str^.Chars := Chars;
  Str^.Hash := Hash;

  Push(OBJ_VAL(Str));

  TableSet(@VM.strings, Str, NIL_VAL);

  Pop();

  Result := Str;
end;

function HashString(const Key: PUTF8Char; Length: Integer): Cardinal;
var
  i: Integer;
begin
  Result := 2166136261;

  for i := 0 to Length - 1 do
    Result := (Result xor Ord(Key[i])) * 16777619;
end;

function CopyString(Chars: PUTF8Char; Length: Integer): PObjString;
var
  HeapChars: PUTF8Char;
  Hash: Cardinal;
  Interned: PObjString;
begin
  Hash := HashString(Chars, Length);

  Interned := TableFindString(@VM.Strings, Chars, Length, Hash);
  if not (Interned = nil) then
    Exit(Interned);

  HeapChars :=  Reallocate(nil, 0, SizeOf(UTF8Char) * (Length + 1));

  CopyMemory(HeapChars, Chars, Length);
  HeapChars[Length] := #0;

  Result := AllocateString(HeapChars, Length, Hash);
end;

procedure PrintFunction(Func: PObjFunction);
begin
  if (func^.name = nil) then
  begin
    Write('<script>');
    Exit();
  end;

  Write(Format('<fn %s>', [func^.name^.chars]));
end;

procedure PrintObject(Value: TValue);
begin
  case OBJ_TYPE(Value) of
      TObjType.OBJ_CLASS: Write(Format('%s', [AS_CLASS(value)^.name^.chars]));
      TObjType.OBJ_BOUND_METHOD: PrintFunction(AS_BOUND_METHOD(value)^.method^.func);
      TObjType.OBJ_CLOSURE: PrintFunction(AS_CLOSURE(Value)^.Func);
      TObjType.OBJ_FUNCTION: PrintFunction(AS_FUNCTION(value));
      TObjType.OBJ_INSTANCE: Write(Format('%s instance', [AS_INSTANCE(value)^.klass^.name^.chars]));
      TObjType.OBJ_NATIVE: Write('<native fn>');
      TObjType.OBJ_STRING: Write(Format('%s', [AS_CSTRING(Value)]));
      TObjType.OBJ_UPVALUE: Write('upvalue');
  end;
end;

function TakeString(Chars: PUTF8Char; Length: Integer): PObjString;
var
  Hash: Cardinal;
  Interned: PObjString;
begin
  Hash := HashString(Chars, Length);

  Interned := TableFindString(@vm.strings, chars, length, hash);
  if (interned <> nil) then
  begin
    FREE_ARRAY(Chars, length + 1);
    Exit(Interned);
  end;

  Result := AllocateString(Chars, Length, Hash);
end;

function NewClosure(Func: PObjFunction): PObjClosure;
var
  Closure: PObjClosure;
  Upvalues: PPObjUpvalue;
  i: Integer;
begin
  Upvalues := Reallocate(nil, 0, SizeOf(PObjUpvalue) * func^.upvalueCount);

  for i := 0 to Func^.UpvalueCount - 1 do
    Upvalues[i] := nil;

  Closure := AllocateObject(SizeOf(TObjClosure), TObjType.OBJ_CLOSURE);
  Closure^.Func := func;
  Closure^.Upvalues := Upvalues;
  Closure^.UpvalueCount := Func^.UpvalueCount;
  Result := Closure;
end;

function NewFunction(): PObjFunction;
var
  Func: PObjFunction;
begin
  Func := AllocateObject(SizeOf(TObjFunction), TObjType.OBJ_FUNCTION);

  Func^.Arity := 0;
  Func^.UpvalueCount := 0;
  Func^.Name := nil;
  initChunk(@Func^.Chunk);
  Result := Func;
end;

function NewNative(Func: TNativeFn): PObjNative;
var
  Native: PObjNative;
begin
  Native := AllocateObject(SizeOf(TObjNative), TObjType.OBJ_NATIVE);
  Native^.Func := Func;
  Result := Native;
end;

function NewUpvalue(Slot: Pointer): PObjUpValue;
var
  Upvalue: PObjUpvalue;
begin
  Upvalue := AllocateObject(SizeOf(TObjUpvalue), TObjType.OBJ_UPVALUE);
  Upvalue^.Closed := NIL_VAL;
  upvalue^.Location := Slot;
  Upvalue^.Next := nil;
  Result := Upvalue;
end;

function NewBoundMethod(receiver: TValue; Method: PObjClosure): PObjBoundMethod;
var
  bound: PObjBoundMethod;
begin

  bound := AllocateObject(sizeof(TObjBoundMethod), TObjType.OBJ_BOUND_METHOD);

  bound^.receiver := receiver;
  bound^.method := method;
  Result := bound;

end;

function NewClass(Name: PObjString): PObjClass;
var
  Klass: PObjClass;
begin

  klass := AllocateObject(SizeOf(TObjClass), TObjType.OBJ_CLASS);
  klass^.name := name;
  initTable(@klass^.methods);
  Result := klass;

end;

function NewInstance(Klass: PObjClass): PObjInstance;
var
  ObjInstance: PObjInstance;
begin

  ObjInstance := AllocateObject(SizeOf(TObjInstance), TObjType.OBJ_INSTANCE);
  ObjInstance^.Klass := Klass;
  initTable(@ObjInstance^.Fields);
  Result := ObjInstance;

end;


end.
