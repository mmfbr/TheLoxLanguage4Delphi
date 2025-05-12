program LoxLanguage.VirtualMachine.RunApp;

{$APPTYPE CONSOLE}

uses
  LoxLanguage.VirtualMachine.Main in 'LoxLanguage.VirtualMachine.Main.pas',
  LoxLanguage.VirtualMachine.Consts in 'LoxLanguage.VirtualMachine.Consts.pas',
  LoxLanguage.VirtualMachine.Chunk in 'LoxLanguage.VirtualMachine.Chunk.pas',
  LoxLanguage.VirtualMachine.Memory in 'LoxLanguage.VirtualMachine.Memory.pas',
  LoxLanguage.VirtualMachine.Debug in 'LoxLanguage.VirtualMachine.Debug.pas',
  LoxLanguage.VirtualMachine.Value in 'LoxLanguage.VirtualMachine.Value.pas',
  LoxLanguage.VirtualMachine in 'LoxLanguage.VirtualMachine.pas',
  LoxLanguage.VirtualMachine.Compiler in 'LoxLanguage.VirtualMachine.Compiler.pas',
  LoxLanguage.VirtualMachine.Scanner in 'LoxLanguage.VirtualMachine.Scanner.pas',
  LoxLanguage.VirtualMachine.Utils in 'LoxLanguage.VirtualMachine.Utils.pas',
  LoxLanguage.VirtualMachine.Obj in 'LoxLanguage.VirtualMachine.Obj.pas',
  LoxLanguage.VirtualMachine.Table in 'LoxLanguage.VirtualMachine.Table.pas',
  LoxLanguage.VirtualMachine.Types in 'LoxLanguage.VirtualMachine.Types.pas';

begin
  Main();
end.
