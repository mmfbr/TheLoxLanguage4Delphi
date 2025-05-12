// Marcello Mello
// 28/09/2019
// LPS (Linguagem de programação Se7e)
// Lets go

program LoxLanguage.Interpreter.ConsoleApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  VCL.Dialogs,
  LoxLanguage.Interpreter.Runner in 'LoxLanguage.Interpreter.Runner.pas',
  LoxLanguage.Interpreter.Types in 'LoxLanguage.Interpreter.Types.pas',
  LoxLanguage.Interpreter.Scanner in 'LoxLanguage.Interpreter.Scanner.pas',
  LoxLanguage.Interpreter.Utils in 'LoxLanguage.Interpreter.Utils.pas',
  LoxLanguage.Interpreter.Parser in 'LoxLanguage.Interpreter.Parser.pas',
  LoxLanguage.Interpreter in 'LoxLanguage.Interpreter.pas',
  LoxLanguage.Interpreter.AST in 'LoxLanguage.Interpreter.AST.pas',
  LoxLanguage.Interpreter.Env in 'LoxLanguage.Interpreter.Env.pas',
  LoxLanguage.Interpreter.Resolver in 'LoxLanguage.Interpreter.Resolver.pas';

var
  SSLangRun: TSSLangRunner;
//  Script: string;
begin
  ReportMemoryLeaksOnShutdown := True;

//  Script := '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            'class TRosquinha {                                            ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '  cozinhar() {                                                ' + sLineBreak +
//            '    print "Frite ateh dourar.";                               ' + sLineBreak +
//            '  }                                                           ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '  init() {                                             ' + sLineBreak +
//            '    print "construido rosquinha.";                                      ' + sLineBreak +
//            '  }                                                           ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '}                                                             ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            'class TCremeDeBoston < TRosquinha {                      ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '  cozinhar() {                                                ' + sLineBreak +
//            '    super.cozinhar();                                         ' + sLineBreak +
//            '    print "Tubo cheio de creme com chocolate.";               ' + sLineBreak +
//            '  }                                                           ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '  init() {                                             ' + sLineBreak +
//            '    super.init();                                         ' + sLineBreak +
//            '    print "construido cremedeboston.";                                      ' + sLineBreak +
//            '  }                                                           ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '}                                                             ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            'var creme = TCremeDeBoston();                             ' + sLineBreak +
//            'creme.cozinhar();                                             ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ' + sLineBreak +
//            '                                                              ';
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//  Script := 'var i = 0;                                     ' + sLineBreak +
//            'while (true)                                   ' + sLineBreak +
//            '{                                              ' + sLineBreak +
//            '	i = i + 1;                                    ' + sLineBreak +
//            '                                               ' + sLineBreak +
//            '	print i;                                      ' + sLineBreak +
//            '                                               ' + sLineBreak +
//            '	if (i > 10)                                   ' + sLineBreak +
//            '	{                                             ' + sLineBreak +
//            '		print "breaking";                           ' + sLineBreak +
//            '		break;                                      ' + sLineBreak +
//            '	}                                             ' + sLineBreak +
//            '                                               ' + sLineBreak +
//            '	if (i > 5)                                    ' + sLineBreak +
//            '	{                                             ' + sLineBreak +
//            '		print "continuing";                         ' + sLineBreak +
//            '		continue();                                   ' + sLineBreak +
//            '	}                                             ' + sLineBreak +
//            '                                               ' + sLineBreak +
//            '	print "looping";                              ' + sLineBreak +
//            '}                                              ' + sLineBreak +
//            '                                               ' + sLineBreak +
//            'print "Complete";                              ' + sLineBreak +
//            '                                               ' + sLineBreak +
//            '                                               ';
//
//  Script := ' var i = 10;               ' + sLineBreak +
//            ' do {                      ' + sLineBreak +
//            '    print i;                ' + sLineBreak +
//            ' 	 i = i - 1;              ' + sLineBreak +
//            ' } while (i > 0);          ' + sLineBreak +
//            '                           ' + sLineBreak +
//            ' print "Complete";         ' + sLineBreak +
//            '                           ' + sLineBreak +
//            '                           ';
//
//  Script := ' var i = 10;                  ' + sLineBreak +
//            ' print i + 10 + " Complete";  ' + sLineBreak +
//            '                              ' + sLineBreak +
//            '                              ';
//
//
//  SSLangRun := TSSLangRunner.Create();
//  SSLangRun.RunScript(Script);
//  SSLangRun.Free();
//  Exit();


  if (ParamCount <> 1) then
  begin
    Writeln('Uso: ' +  TPath.GetFileNameWithoutExtension(ParamStr(0)) + ' [lox script file]');
    WriteLn;
    WriteLn('Pressione qualquer tecla para fechar...');
    ReadlN;
  end
  else if (ParamCount = 1) then
  begin
    SSLangRun := TSSLangRunner.Create();
    try
		SSLangRun.RunFile(ParamStr(1));
    finally
      FreeAndNil(SSLangRun);
    end;
  end;

end.
