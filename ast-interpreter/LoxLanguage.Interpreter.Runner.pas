// Marcello Mello
// 28/09/2019

unit LoxLanguage.Interpreter.Runner;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Generics.Collections,
  VCL.Dialogs,
  LoxLanguage.Interpreter.Types;

type

  TLoxRunner = class
  private
    FHadError: Boolean;
    procedure Error(LineNro: Integer; Msg: string);
    procedure Report(LineNro: Integer; Where, Msg: string);
    procedure Run(source: string);
    procedure ParserError(Token: TLoxToken; Msg: string);
  public
    procedure RunFile(Path: string);
    procedure RunScript(Script: string);
    constructor Create;
  end;

implementation


uses
  LoxLanguage.Interpreter.Scanner,
  LoxLanguage.Interpreter.Parser,
  LoxLanguage.Interpreter.AST,
  LoxLanguage.Interpreter,
  LoxLanguage.Interpreter.Resolver;

procedure TLoxRunner.Report(LineNro: Integer; Where: string; Msg: string);
begin
  Writeln(Format('[Linha %d] Erro %s : %s', [LineNro, Where, Msg]));
  FHadError := True;
end;

constructor TLoxRunner.Create;
begin

end;

procedure TLoxRunner.Error(LineNro: Integer; Msg: string);
begin
  Report(LineNro, '', Msg);
end;

procedure TLoxRunner.ParserError(Token: TLoxToken; Msg: string);
begin
  Report(Token.LineNro, '', Msg);
end;

procedure TLoxRunner.Run(source: string);
var
  Scanner: TScanner;
  Tokens: TObjectList<TLoxToken>;
  Parser: TParser;
  Statements: TObjectList<TStatementNode>;
  Interpreter: IAstVisitor;
  Resolver: IAstVisitor;
begin
  FHadError := False;

  Scanner := TScanner.Create(source);
  Scanner.OnError := Error;

  Tokens := Scanner.ScanTokens();

  Parser := TParser.Create(Tokens);
  Parser.OnError := ParserError;

  Statements := Parser.Parse();

  if (FHadError) then
    Halt(64);

  Interpreter := TAstInterpreterVisitor.Create();

  Resolver := TResolverVisitor.Create(TAstInterpreterVisitor(Interpreter));
  TResolverVisitor(Resolver).Resolve(Statements);

  TAstInterpreterVisitor(Interpreter).Interpret(Statements);
end;

procedure TLoxRunner.RunFile(Path: string);
begin
  Run(TFile.ReadAllText(Path));

  if (hadRuntimeError) then
    Halt(70);
end;


procedure TLoxRunner.RunScript(Script: string);
begin
  Run(Script);
end;

end.
