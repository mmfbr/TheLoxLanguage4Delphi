// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Main;

interface

procedure Main;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.SysUtils,
  LoxLanguage.VirtualMachine.Chunk,
  LoxLanguage.VirtualMachine.Debug,
  LoxLanguage.VirtualMachine;

procedure Repl();
var
  Linha: array[0..1023] of Byte;
  str: UTF8String;
  Count: LongInt;
begin

  Writeln('The Lox Language Repl v1.0.2 (alpha)');

  while true do
  begin
    Write('> ');

    Count := Length(Linha);

    if not ReadFile(GetStdHandle(STD_INPUT_HANDLE), Linha, Count, LongWord(Count), nil) then
      Count := 0;

    if Count = 0 then
    begin
      Writeln('');
      break;
    end;


    str := UTF8Encode(TEncoding.ANSI.GetString(Linha));
    str[Count-1] := #0;

    Interpret(Str);
  end;

end;

procedure RunFile(Path: string);
var
  Source: string;
  Return: TInterpretResult;
begin
  Source := TFile.ReadAllText(Path);

  Return := Interpret(UTF8Encode(Source));

  if (Return = TInterpretResult.INTERPRET_COMPILE_ERROR) then
    Halt(65)
  else if (Return = TInterpretResult.INTERPRET_RUNTIME_ERROR) then
    Halt(70);
end;


procedure Main;
begin
  InitVM();

  if (ParamCount = 0) then
    Repl()
  else if (ParamCount = 1) then
    RunFile(ParamStr(1))
  else
  begin
    Writeln('Usage: ' + TPath.GetFileNameWithoutExtension(ParamStr(0)) + ' [path]');
    WriteLn('Pressione qualquer tecla para fechar...');
    ReadlN;
    Halt(64);
  end;

  FreeVM();
end;

end.
