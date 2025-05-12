// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Debug;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  System.SysUtils,
  LoxLanguage.VirtualMachine.Chunk,
  LoxLanguage.VirtualMachine.Types;

procedure DisassembleChunk(Chunk: PChunk; Name: PUTF8Char);
function DisassembleInstruction(Chunk: PChunk; Offset: Integer): Integer;

implementation

uses
  System.Math,
  System.StrUtils,
  LoxLanguage.VirtualMachine.Value,
  LoxLanguage.VirtualMachine.Obj;

procedure DisassembleChunk(Chunk: PChunk; Name: PUTF8Char);
var
  Offset: Integer;
begin
  Writeln(Format('== %s ==', [Name]));

  Offset := 0;

  while Offset < Chunk.Count do
    Offset := DisassembleInstruction(Chunk, Offset);
end;

function invokeInstruction(const name: PUTF8Char; Chunk: PChunk; offset: Integer): Integer;
var
  argCount,
  constant: uint8;
begin
  argCount := Chunk^.code[offset + 1];
  constant := Chunk^.code[offset + 2];
  Write(Format('%-16s (%d args) %4d "', [name, argCount, constant]));
  printValue(Chunk^.constants.values[constant]);
  Writeln('');
  Result := Offset + 2;
end;


function SimpleInstruction(const Name: string; Offset: Integer): Integer;
begin
  Writeln(Format('%s', [name]));
  Result := Offset + 1;
end;

function ByteInstruction(const Name: string; chunk: PChunk; Offset: integer): Integer;
var
  slot: UInt8;
begin
  slot := chunk^.code[offset + 1];
  Writeln(Format('%-16s %4d', [name, slot]));
  Result := Offset + 2;
end;

function jumpInstruction(const Name: string; sign: integer; Chunk: pchunk; offset: Integer): Integer;
var
  jump: UInt16;
begin
  jump := UInt16(chunk^.code[offset + 1] shl 8);
  jump := jump or chunk^.code[offset + 2];
  Writeln(Format('%-16s %4d -> %d', [name, offset, offset + 3 + sign * jump]));
  Result := offset + 3;
end;

function ConstantInstruction(const Name: string; Chunk: PChunk; Offset: Integer): Integer;
var
  Constant: UInt8;
begin
  Constant := Chunk.Code[Offset + 1];
  System.Write(Format('%-16s %4d "', [Name, Constant]));
  PrintValue(Chunk.Constants.Values[Constant]);
  Writeln('"');
  Result := Offset + 2;
end;

function DisassembleInstruction(Chunk: PChunk; Offset: Integer): Integer;
var
  Instruction: Byte;
  Constant: UInt8;
  FunctionPtr: PObjFunction;
  j,
  isLocal,
  index: Integer;
begin
  Write(FormatFloat('0000 ', Offset));

  if (offset > 0) and (Chunk.Lines[Offset] = Chunk.Lines[Offset - 1]) then
    Write('   | ')
  else
    Write(Format('%4d ', [Chunk.Lines[Offset]]));

  Instruction := Chunk.Code[Offset];
  case TOpCode(Instruction) of
    TOpCode.OP_PRINT: Exit(SimpleInstruction('OP_PRINT', Offset));
    TOpCode.OP_JUMP: Exit(JumpInstruction('OP_JUMP', 1, chunk, offset));
    TOpCode.OP_JUMP_IF_FALSE: Exit(jumpInstruction('OP_JUMP_IF_FALSE', 1, chunk, offset));
    TOpCode.OP_LOOP: Exit(JumpInstruction('OP_LOOP', -1, chunk, offset));
    TOpCode.OP_CALL: Exit(ByteInstruction('OP_CALL', chunk, offset));
    TOpCode.OP_CLOSURE:
    begin
      Inc(Offset);
      Constant := Chunk^.Code[Offset];
      Inc(Offset);
      Write(Format('%-16s %4d ', ['OP_CLOSURE', Constant]));
      PrintValue(Chunk^.Constants.Values[Constant]);
      Writeln('');

      FunctionPtr := AS_FUNCTION(Chunk^.Constants.Values[constant]);
      for j := 0 to FunctionPtr^.UpvalueCount - 1 do
      begin
        isLocal := Chunk^.Code[Offset];
        Inc(Offset);
        index := Chunk^.Code[Offset];
        Inc(Offset);
        writeln(Format('%04d      |                     %s %d', [offset - 2, IfThen(isLocal <> 0, 'local', 'upvalue'), index]));
      end;

      Exit(Offset);
    end;
    TOpCode.OP_CLOSE_UPVALUE: Exit(SimpleInstruction('OP_CLOSE_UPVALUE', Offset));
    TOpCode.OP_RETURN: Exit(SimpleInstruction('OP_RETURN', Offset));
    TOpCode.OP_CONSTANT: Exit(ConstantInstruction('OP_CONSTANT', Chunk, Offset));
    TOpCode.OP_NIL: Exit(SimpleInstruction('OP_NIL', Offset));
    TOpCode.OP_TRUE: Exit(SimpleInstruction('OP_TRUE', Offset));
    TOpCode.OP_FALSE: Exit(SimpleInstruction('OP_FALSE', Offset));
    TOpCode.OP_POP: Exit(SimpleInstruction('OP_POP', Offset));
    TOpCode.OP_GET_LOCAL: Exit(ByteInstruction('OP_GET_LOCAL', chunk, offset));
    TOpCode.OP_SET_LOCAL: Exit(ByteInstruction('OP_SET_LOCAL', chunk, offset));
    TOpCode.OP_GET_GLOBAL: Exit(ConstantInstruction('OP_GET_GLOBAL', Chunk, Offset));
    TOpCode.OP_DEFINE_GLOBAL: Exit(ConstantInstruction('OP_DEFINE_GLOBAL', Chunk, Offset));
    TOpCode.OP_SET_GLOBAL: Exit(ConstantInstruction('OP_SET_GLOBAL', chunk, offset));

    TOpCode.OP_INVOKE: Exit(InvokeInstruction('OP_INVOKE', chunk, offset));
    TOpCode.OP_SUPER: Exit(invokeInstruction('OP_SUPER_', chunk, offset));


    TOpCode.OP_GET_UPVALUE: Exit(byteInstruction('OP_GET_UPVALUE', chunk, offset));
    TOpCode.OP_SET_UPVALUE: Exit(byteInstruction('OP_SET_UPVALUE', chunk, offset));


    TOpCode.OP_GET_PROPERTY: Exit(constantInstruction('OP_GET_PROPERTY', Chunk, Offset));
    TOpCode.OP_SET_PROPERTY: Exit(constantInstruction('OP_SET_PROPERTY', chunk, offset));
    TOpCode.OP_GET_SUPER: Exit(constantInstruction('OP_GET_SUPER', chunk, offset));

    TOpCode.OP_EQUAL: Exit(SimpleInstruction('OP_EQUAL', Offset));
    TOpCode.OP_GREATER: Exit(SimpleInstruction('OP_GREATER', Offset));
    TOpCode.OP_LESS: Exit(SimpleInstruction('OP_LESS', Offset));
    TOpCode.OP_ADD: Exit(SimpleInstruction('OP_ADD', Offset));
    TOpCode.OP_SUBTRACT: Exit(SimpleInstruction('OP_SUBTRACT', Offset));
    TOpCode.OP_MULTIPLY: Exit(SimpleInstruction('OP_MULTIPLY', Offset));
    TOpCode.OP_DIVIDE: Exit(SimpleInstruction('OP_DIVIDE', Offset));
    TOpCode.OP_NOT: Exit(SimpleInstruction('OP_NOT', Offset));
    TOpCode.OP_NEGATE: Exit(SimpleInstruction('OP_NEGATE', Offset));

    TOpCode.OP_CLASS: Exit(constantInstruction('OP_CLASS', chunk, offset));
    TOpCode.OP_INHERIT: Exit(simpleInstruction('OP_INHERIT', offset));
    TOpCode.OP_METHOD: Exit(constantInstruction('OP_METHOD', chunk, offset));

    else
    begin
      Writeln(Format('opcode desconhecido %d', [Instruction]));
      Result := Offset + 1;
    end;
  end;

end;


end.
