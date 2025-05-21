// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Chunk;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  LoxLanguage.VirtualMachine.Types,
  LoxLanguage.VirtualMachine.Consts,
  LoxLanguage.VirtualMachine.Value;


procedure InitChunk(Chunk: PChunk);
procedure FreeChunk(Chunk: PChunk);
procedure WriteChunk(Chunk: PChunk; AByte: UInt8; Line: Integer);
function AddConstant(Chunk: PChunk; Value: TValue): Integer;

implementation

uses
  LoxLanguage.VirtualMachine,
  LoxLanguage.VirtualMachine.Memory;

procedure InitChunk(Chunk: PChunk);
begin
  Chunk^.Count := 0;
  Chunk^.Capacity := 0;
  Chunk^.Code := nil;
  Chunk^.Lines := nil;
  InitValueArray(@Chunk^.Constants);
end;

procedure WriteChunk(Chunk: PChunk; AByte: UInt8; Line: Integer);
var
  OldCapacity: Integer;
begin
  if Chunk^.Capacity < (chunk^.Count + 1) then
  begin
    OldCapacity := Chunk^.Capacity;
    Chunk^.Capacity := GROW_CAPACITY(OldCapacity);
    Chunk^.Code := GROW_ARRAY(Chunk^.Code, OldCapacity, Chunk^.Capacity);
    chunk^.Lines := GROW_ARRAY(Chunk^.Lines, OldCapacity, Chunk^.Capacity);
  end;

  Chunk^.Code[Chunk^.Count] := AByte;
  chunk^.Lines[Chunk^.Count] := Line;
  Chunk^.Count := Chunk^.Count + 1;
end;

procedure FreeChunk(Chunk: PChunk);
begin
  FREE_ARRAY(Chunk^.Code, Chunk^.Capacity);
  FREE_ARRAY(Chunk^.Lines, Chunk^.Capacity);
  FreeValueArray(@Chunk^.Constants);
  InitChunk(Chunk);
end;

function AddConstant(Chunk: PChunk; Value: TValue): Integer;
begin
  Push(Value);
  WriteValueArray(@Chunk^.Constants, Value);
  Pop();
  Result := Chunk^.Constants.Count - 1;
end;

end.
