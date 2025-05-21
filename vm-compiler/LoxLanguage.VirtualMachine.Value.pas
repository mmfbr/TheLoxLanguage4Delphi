// Marcello Mello
// 30/09/2019

unit LoxLanguage.VirtualMachine.Value;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  LoxLanguage.VirtualMachine.Types;

procedure InitValueArray(ValueArray: PValueArray);
procedure WriteValueArray(ValueArray: PValueArray; Value: TValue);
procedure FreeValueArray(ValueArray: PValueArray);
procedure PrintValue(Value: TValue);

function BOOL_VAL(Value: Boolean): TValue;
function NIL_VAL: TValue;
function NUMBER_VAL(Value: Double): TValue;
function OBJ_VAL(Value: Pointer): TValue;

function IS_BOOL(Value: TValue): Boolean;
function IS_NIL(Value: TValue): Boolean;
function IS_NUMBER(Value: TValue): Boolean;
function IS_OBJ(Value: TValue): Boolean;

function AS_OBJ(Value: TValue): Pointer;
function AS_BOOL(Value: TValue): Boolean;
function AS_NUMBER(Value: TValue): Double;
function AS_INSTANCE(Value: TValue): PObjInstance;

function ValuesEqual(a: TValue; b: TValue): Boolean;

implementation

uses
  System.SysUtils,
  System.Math,
  System.StrUtils,
  LoxLanguage.VirtualMachine.Utils,
  LoxLanguage.VirtualMachine.Consts,
  LoxLanguage.VirtualMachine.Obj,
  LoxLanguage.VirtualMachine.Memory;

function BOOL_VAL(Value: Boolean): TValue;
begin
  Result.ValueType := TValueType.VAL_BOOL;
  Result.AsValue.Bool := Value;
end;

function NIL_VAL: TValue;
begin
  Result.ValueType := TValueType.VAL_NIL;
  Result.AsValue.Number := 0;
end;

function NUMBER_VAL(Value: Double): TValue;
begin
  Result.ValueType := TValueType.VAL_NUMBER;
  Result.AsValue.Number := Value;
end;

function OBJ_VAL(Value: Pointer): TValue;
begin
  Result.ValueType := TValueType.VAL_OBJ;
  Result.AsValue.Obj := Value;
end;

function IS_BOOL(Value: TValue): Boolean;
begin
  Result := Value.ValueType = TValueType.VAL_BOOL;
end;

function IS_NIL(Value: TValue): Boolean;
begin
  Result := Value.ValueType = TValueType.VAL_NIL;
end;

function IS_NUMBER(Value: TValue): Boolean;
begin
  Result := Value.ValueType = TValueType.VAL_NUMBER;
end;

function IS_OBJ(Value: TValue): Boolean;
begin
  Result := Value.ValueType = TValueType.VAL_OBJ;
end;

function AS_OBJ(Value: TValue): Pointer;
begin
  Result := Value.AsValue.Obj;
end;

function AS_BOOL(Value: TValue): Boolean;
begin
  Result := Value.AsValue.Bool;
end;

function AS_NUMBER(Value: TValue): Double;
begin
  Result := Value.AsValue.Number;
end;

function AS_INSTANCE(Value: TValue): PObjInstance;
begin
  Result := AS_OBJ(Value);
end;


procedure InitValueArray(ValueArray: PValueArray);
begin
  ValueArray.Values := nil;
  ValueArray.Capacity := 0;
  ValueArray.Count := 0;
end;

procedure WriteValueArray(ValueArray: PValueArray; Value: TValue);
var
  OldCapacity: Integer;
begin
  if ValueArray.Capacity < ValueArray.Count + 1 then
  begin
    OldCapacity := ValueArray.Capacity;
    ValueArray.Capacity := GROW_CAPACITY(OldCapacity);
    ValueArray.Values := GROW_ARRAY(ValueArray.Values, OldCapacity, ValueArray.Capacity);
  end;

  ValueArray.Values[ValueArray.Count] := Value;
  ValueArray.Count := ValueArray.Count + 1;
end;

procedure FreeValueArray(ValueArray: PValueArray);
begin
  FREE_ARRAY(ValueArray.Values, ValueArray.Capacity);
  InitValueArray(ValueArray);
end;

procedure PrintValue(Value: TValue);
begin
  case Value.ValueType of
    TValueType.VAL_BOOL:   Write(IfThen(AS_BOOL(value), 'true', 'false'));
    TValueType.VAL_NIL:    Write('nil');
    TValueType.VAL_NUMBER: Write(FormatFloat(',0.', AS_NUMBER(Value)));
    TValueType.VAL_OBJ: PrintObject(value);
  end;
end;

function ValuesEqual(a: TValue; b: TValue): Boolean;
begin
  if (a.ValueType <> b.ValueType) then
    Exit(False);

  case a.ValueType of
    TValueType.VAL_BOOL: Result := AS_BOOL(a) = AS_BOOL(b);
    TValueType.VAL_NIL: Result := True;
    TValueType.VAL_NUMBER: Result := AS_NUMBER(a) = AS_NUMBER(b);
    TValueType.VAL_OBJ: Result := AS_OBJ(a) = AS_OBJ(b);
  else
    Exit(False);
  end;
end;

end.
