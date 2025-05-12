// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Memory;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  LoxLanguage.VirtualMachine.Consts,
  LoxLanguage.VirtualMachine.chunk,
  LoxLanguage.VirtualMachine.Value,
  LoxLanguage.VirtualMachine.Obj,
  LoxLanguage.VirtualMachine.Types;

function GROW_CAPACITY(Capacity: Integer): Integer;
function GROW_ARRAY(Previous: PUint8; OldCount, Count: Integer): PUint8; overload;
function GROW_ARRAY(Previous: PInt; OldCount, Count: Integer): PInt; overload;
function GROW_ARRAY(Previous: PValue; OldCount, Count: Integer): PValue; overload;
procedure FREE_ARRAY(Pointer: PUint8; OldCount: Integer); overload;
procedure FREE_ARRAY(Pointer: PInt; OldCount: Integer); overload;
procedure FREE_ARRAY(Pointer: PValue; OldCount: Integer); overload;
procedure FREE_ARRAY(Pointer: PUTF8Char; OldCount: Integer); overload;
procedure FREE_ARRAY(Pointer: PEntry; OldCount: Integer); overload;

procedure FREE_ARRAY(Pointer: PPObjUpvalue; OldCount: Integer); overload;

function Reallocate(Previous: Pointer; OldSize: Cardinal; NewSize: Cardinal): Pointer;

procedure GrayObject(Obj: PObj);
procedure GrayValue(value: TValue);
procedure CollectGarbage();
procedure blackenObject(Obj: PObj);

procedure FreeObjects();

implementation

uses
  LoxLanguage.VirtualMachine.Table,
  LoxLanguage.VirtualMachine.Compiler,
  LoxLanguage.VirtualMachine;

function GROW_CAPACITY(Capacity: Integer): Integer;
begin

  if Capacity < 8 then
    Result := 8
  else
    Result := Capacity * 2;

end;

function GROW_ARRAY(Previous: PUint8; OldCount, Count: Integer): PUint8;
begin
  Result := Reallocate(Previous, SizeOf(Byte) * OldCount,  SizeOf(Byte) * Count)
end;

function GROW_ARRAY(Previous: PInt; OldCount, Count: Integer): PInt;
begin
  Result := Reallocate(Previous, SizeOf(Integer) * OldCount,  SizeOf(Integer) * Count)
end;

function GROW_ARRAY(Previous: PValue; OldCount, Count: Integer): PValue;
begin
  Result := Reallocate(Previous, SizeOf(TValue) * OldCount,  SizeOf(TValue) * Count)
end;

procedure FREE_ARRAY(Pointer: PUint8; OldCount: Integer);
begin
  Reallocate(Pointer, SizeOf(Byte) * OldCount, 0);
end;

procedure FREE_ARRAY(Pointer: PInt; OldCount: Integer);
begin
  Reallocate(Pointer, SizeOf(Integer) * OldCount, 0);
end;

procedure FREE_ARRAY(Pointer: PValue; OldCount: Integer);
begin
  Reallocate(Pointer, SizeOf(TValue) * OldCount, 0);
end;

procedure FREE_ARRAY(Pointer: PUTF8Char; OldCount: Integer); overload;
begin
  Reallocate(Pointer, SizeOf(UTF8Char) * OldCount, 0);
end;

procedure FREE_ARRAY(Pointer: PEntry; OldCount: Integer); overload;
begin
  Reallocate(Pointer, SizeOf(TEntry) * OldCount, 0);
end;

procedure FREE_ARRAY(Pointer: PPObjUpvalue; OldCount: Integer); overload;
begin
  Reallocate(Pointer, SizeOf(TObjUpvalue) * OldCount, 0);
end;


function Reallocate(Previous: Pointer; OldSize: Cardinal; NewSize: Cardinal): Pointer;
begin


  vm.bytesAllocated := vm.bytesAllocated + newSize - oldSize;

  if (newSize > oldSize) then
  begin
//#ifdef DEBUG_STRESS_GC
//    collectGarbage();
//#endif

    if (vm.bytesAllocated > vm.nextGC) then
      CollectGarbage();
  end;

  if (newSize = 0) then
  begin
    FreeMemory(Previous);
    Exit(nil);
  end;

  Result := ReallocMemory(previous, newSize);

end;

procedure FreeObject(Obj: PObj);
var
  ObjString: PObjString;
  Func: PObjFunction;
  Closure: PObjClosure;
  Instance: PObjInstance;
  Klass: PObjClass;
begin
//#ifdef DEBUG_TRACE_GC
//  printf("%p free ", object);
//  printValue(OBJ_VAL(object));
//  printf("\n");
//#endif


  case Obj^.ObjType of
    TObjType.OBJ_BOUND_METHOD: reallocate(Obj, sizeof(TObjBoundMethod), 0);

    TObjType.OBJ_CLASS:
    begin
      Klass := PObjClass(obj);
      freeTable(@Klass^.methods);
      Reallocate(Obj, sizeof(TObjClass), 0);
    end;
    TObjType.OBJ_CLOSURE:
    begin

      Closure := PObjClosure(Obj);
      FREE_ARRAY(Closure^.Upvalues, Closure^.upvalueCount);

      Reallocate(Obj, SizeOf(TObjClosure), 0);
    end;
    TObjType.OBJ_FUNCTION:
    begin
      func := PObjFunction(Obj);
      FreeChunk(@Func^.chunk);
      Reallocate(Obj, SizeOf(TObjFunction), 0);
    end;
    TObjType.OBJ_INSTANCE:
    begin
      Instance := PObjInstance(obj);
      FreeTable(@instance^.Fields);
      Reallocate(Obj, SizeOf(TObjInstance), 0);
    end;
    TObjType.OBJ_NATIVE:
    begin
      Reallocate(Obj, SizeOf(TObjNative), 0);
    end;
    TObjType.OBJ_STRING:
    begin
      ObjString := PObjString(Obj);
      FREE_ARRAY(ObjString^.Chars, ObjString^.length + 1);
      Reallocate(Obj, SizeOf(TObjString), 0);
    end;
    TObjType.OBJ_UPVALUE:
      Reallocate(Obj, SizeOf(TObjUpvalue), 0);
  end;
end;

procedure FreeObjects();
var
  Obj,
  Next: PObj;
begin
  Obj := VM.objects;

  while not (Obj = nil) do
  begin
    Next := Obj^.Next;
    FreeObject(Obj);
    Obj := Next;
  end;

  FreeMemory(VM.GrayStack);
end;

procedure GrayObject(Obj: PObj);
begin
  if (Obj = nil) then
    Exit();

  // Don't get caught in cycle.
  if (obj^.isDark) then
    Exit();

//#ifdef DEBUG_TRACE_GC
//  printf("%p gray ", object);
//  printValue(OBJ_VAL(object));
//  printf("\n");
//#endif

  Obj^.isDark := true;

  if (vm.grayCapacity < vm.grayCount + 1) then
  begin
    vm.grayCapacity := GROW_CAPACITY(vm.grayCapacity);

    // Not using reallocate() here because we don't want to trigger the
    // GC inside a GC!
    vm.grayStack := ReallocMemory(vm.grayStack,
                                  sizeof(PObj) * vm.grayCapacity);
  end;

  vm.grayStack[vm.grayCount] := obj;
  vm.grayCount := vm.grayCount + 1;
end;

procedure GrayValue(value: TValue);
begin
  if not IS_OBJ(Value) then
    Exit();

  GrayObject(AS_OBJ(Value));
end;

procedure CollectGarbage();
var
  Slot: PValue;
  i: Integer;
  Upvalue: PObjUpvalue;
  Obj: PObj;
  ObjPtr: PPObj;
  unreached: PObj;
begin

//#ifdef DEBUG_TRACE_GC
//  printf("-- gc begin\n");
//  size_t before = vm.bytesAllocated;
//#endif

  // Mark the stack roots.

  for i := Low(vm.stack) to High(vm.stack)  do
  begin
    Slot := @vm.Stack[i];

    if Slot = vm.StackTop then
      Break;

    grayValue(slot^);
  end;

  for i := 0 to vm.frameCount - 1 do
    grayObject(PObj(vm.frames[i].closure));

  // Mark the open upvalues.
  upvalue := vm.openUpvalues;
  while True do
  begin
    if upvalue = nil then
      Break;

    grayObject(PObj(upvalue));

    upvalue := upvalue^.Next;
  end;


  // Mark the global roots.
  grayTable(@vm.globals);
  grayCompilerRoots();
//> Methods and Initializers not-yet
  grayObject(PObj(vm.initString));
//< Methods and Initializers not-yet

  // Traverse the references.
  while (vm.grayCount > 0) do
  begin
    // Pop an item from the gray stack.
    vm.grayCount := vm.grayCount - 1;
    Obj := vm.grayStack[vm.grayCount];
    blackenObject(obj);
  end;

  // Delete unused interned strings.
  tableRemoveWhite(@vm.strings);

  // Collect the white objects.
  ObjPtr := @vm.objects;
  while ObjPtr^ <> nil do
  begin
    if not ObjPtr^.isDark then
    begin
      // This object wasn't reached, so remove it from the list and
      // free it.
      unreached := ObjPtr^;
      ObjPtr^ := unreached^.next;
      freeObject(unreached);
    end
    else
    begin
      // This object was reached, so unmark it (for the next GC) and
      // move on to the next.
      objPtr^.isDark := false;
      objPtr := @ObjPtr^.next;
    end;
  end;

  // Adjust the heap size based on live memory.
  vm.nextGC := vm.bytesAllocated * GC_HEAP_GROW_FACTOR;

//#ifdef DEBUG_TRACE_GC
//  printf("-- gc collected %ld bytes (from %ld to %ld) next at %ld\n",
//         before - vm.bytesAllocated, before, vm.bytesAllocated,
//         vm.nextGC);
//#endif

end;


procedure GrayArray(ValueArray: PValueArray);
var
  i: Integer;
begin
  for i := 0 to ValueArray^.count - 1 do
    grayValue(ValueArray^.values[i]);
end;

procedure blackenObject(Obj: PObj);
var
  bound: PObjBoundMethod;
  Klass: PObjClass;
  Closure: PObjClosure;
  Func: PObjFunction;
  Instance: PObjInstance;
  i: Integer;
begin
//#ifdef DEBUG_TRACE_GC
//  printf("%p blacken ", object);
//  printValue(OBJ_VAL(object));
//  printf("\n");
//#endif

  case obj^.ObjType of
    TObjType.OBJ_BOUND_METHOD:
    begin
      Bound := PObjBoundMethod(Obj);
      GrayValue(bound^.Receiver);
      GrayObject(PObj(bound^.method));
    end;
    TObjType.OBJ_CLASS:
    begin
      Klass := PObjClass(obj);
      grayObject(PObj(klass^.name));
      grayTable(@klass^.methods);
    end;
    TObjType.OBJ_CLOSURE:
    begin
      Closure := PObjClosure(obj);
      grayObject(PObj(closure^.func));

      for i := 0 to closure^.upvalueCount - 1 do
        grayObject(PObj(closure^.Upvalues[i]));
    end;
    TObjType.OBJ_FUNCTION:
    begin
      Func := PObjFunction(obj);
      grayObject(PObj(func^.name));
      grayArray(@func^.chunk.constants);
    end;
    TObjType.OBJ_INSTANCE:
    begin
      instance := PObjInstance(obj);
      grayObject(PObj(instance^.klass));
      grayTable(@instance^.Fields);
    end;
    TObjType.OBJ_UPVALUE:
    begin
      grayValue((PObjUpvalue(obj).closed));
    end;
    TObjType.OBJ_NATIVE,
    TObjType.OBJ_STRING:
      //;
  end;
end;


end.
