// Marcello Mello
// 28/09/2019

program LoxLanguage.Interpreter.AST.PrinterApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Generics.Collections,
  LoxLanguage.Interpreter.AST in '..\LoxLanguage.Interpreter.AST.pas',
  LoxLanguage.Interpreter.Utils in '..\LoxLanguage.Interpreter.Utils.pas',
  LoxLanguage.Interpreter.Types in '..\LoxLanguage.Interpreter.Types.pas',
  LoxLanguage.Interpreter.AST.Printer in '..\LoxLanguage.Interpreter.AST.Printer.pas',
  LoxLanguage.Interpreter.Runner in '..\LoxLanguage.Interpreter.Runner.pas',
  LoxLanguage.Interpreter.Scanner in '..\LoxLanguage.Interpreter.Scanner.pas',
  LoxLanguage.Interpreter.Parser in '..\LoxLanguage.Interpreter.Parser.pas',
  LoxLanguage.Interpreter in '..\LoxLanguage.Interpreter.pas',
  LoxLanguage.Interpreter.Env in '..\LoxLanguage.Interpreter.Env.pas',
  LoxLanguage.Interpreter.Resolver in '..\LoxLanguage.Interpreter.Resolver.pas';

var
//  Expression: TBinaryExpression;
  AstPrinter: IVisitor;
  source: string;

  Scanner: TScanner;
  Tokens: TObjectList<TToken>;
  Parser: TParser;
  Statements: TObjectList<TStatement>;
//  Interpreter: IVisitor;
//  Resolver: IVisitor;
  HadError: Boolean;
  Statement: TStatement;
begin
  source := '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            'class TRosquinha {                                            ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  cozinhar() {                                                ' + sLineBreak +
            '    print "Frite ateh dourar.";                               ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  init() {                                                    ' + sLineBreak +
            '    print "construido rosquinha.";                            ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '}                                                             ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            'class TCremeDeBoston < TRosquinha {                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  cozinhar() {                                                ' + sLineBreak +
            '    super.cozinhar();                                         ' + sLineBreak +
            '    print "Tubo cheio de creme com chocolate.";               ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '  init() {                                                    ' + sLineBreak +
            '    super.init();                                             ' + sLineBreak +
            '    print "construido TCremeDeBoston.";                       ' + sLineBreak +
            '  }                                                           ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '}                                                             ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            'var creme = TCremeDeBoston();                                 ' + sLineBreak +
            'creme.cozinhar();                                             ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ' + sLineBreak +
            '                                                              ';

  HadError := False;

  Scanner := TScanner.Create(source);
//  Scanner.OnError := Error;

  Tokens := Scanner.ScanTokens();

  Parser := TParser.Create(Tokens);
//  Parser.OnError := ParserError;

  Statements := Parser.Parse();

  if (HadError) then
    Halt(64);

  AstPrinter := TAstPrinter.Create();

  for Statement in Statements do
  begin
    Writeln('');
    Writeln(Statement.Accept(AstPrinter).StrValue);
  end;

  Writeln('');
  Writeln('Pressione qualque tecla para fechar...');
  Readln;

end.
