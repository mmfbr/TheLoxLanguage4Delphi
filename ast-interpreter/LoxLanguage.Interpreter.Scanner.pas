// Marcello Mello
// 28/09/2019

unit LoxLanguage.Interpreter.Scanner;

interface

uses
  System.SysUtils,
  System.Math,
  System.StrUtils,
  System.Generics.Collections,
  LoxLanguage.Interpreter.Types;

{$SCOPEDENUMS ON}

type

  TOnScannerErrorEvent = procedure (LineNro: Integer; Msg: string) of object;

  TScanner = class
  private
    FSource: string;
    FTokens: TObjectList<TLoxToken>;
    FStart: Integer;
    FCurrent: Integer;
    FLineNro: Integer;
    FOnError: TOnScannerErrorEvent;
    function IsAtEnd: Boolean;
    function Advance: Char;
    procedure ScanToken;
    procedure AddToken(TokenType: TLoxTokenType); overload;
    procedure AddToken(TokenType: TLoxTokenType; Literal: TLoxValue); overload;
    procedure Error(Line: Integer; Msg: string);
    function Match(Expected: Char): Boolean;
    function Peek: Char;
    procedure ScanString;
    procedure ScanNumber;
    function IsDigit(c: Char): Boolean;
    function PeekNext: Char;
    function IsAlpha(c: Char): Boolean;
    function IsAlphaNumeric(c: Char): Boolean;
    procedure ScanIdentifier;
  public
    constructor Create(Source: string);
    function ScanTokens: TObjectList<TLoxToken>;
    destructor Destroy; override;
    property OnError: TOnScannerErrorEvent read FOnError write FOnError;
  end;

implementation

uses
  LoxLanguage.Interpreter.Utils;

{ TScanner }

constructor TScanner.Create(Source: string);
begin
  FTokens := TObjectList<TLoxToken>.Create();
  FSource := Source;
  FStart := 1;
  Fcurrent := 1;
  FLineNro := 1;
end;

destructor TScanner.Destroy;
begin
  FTokens.Free();
  inherited;
end;

function TScanner.IsAtEnd(): Boolean;
begin
  Result := FCurrent > FSource.Length;
end;

function TScanner.Advance(): Char;
begin
  Inc(FCurrent);
  Result := FSource[FCurrent-1];
end;

procedure TScanner.AddToken(TokenType: TLoxTokenType);
var
  NullValue: TLoxValue;
begin
  NullValue := Default(TLoxValue);
  NullValue.ValueType := TLoxValueType.IS_NULL;
  AddToken(TokenType, NullValue);
end;

procedure TScanner.AddToken(TokenType: TLoxTokenType; Literal: TLoxValue);
var
  Text: string;
begin
  Text := Copy(FSource, FStart, FCurrent - FStart);
  FTokens.Add(TLoxToken.Create(TokenType, Text, Literal, FLineNro));
end;

procedure TScanner.ScanToken();
var
  c: Char;
begin
  c := Advance();

  case (c) of
    '(': AddToken(TLoxTokenType.LEFT_PAREN_SYMBOL);
    ')': AddToken(TLoxTokenType.RIGHT_PAREN_SYMBOL);
    '{': AddToken(TLoxTokenType.LEFT_BRACE_SYMBOL);
    '}': AddToken(TLoxTokenType.RIGHT_BRACE_SYMBOL);
    ',': AddToken(TLoxTokenType.COMMA_SYMBOL);
    '.': AddToken(TLoxTokenType.DOT_SYMBOL);
    '-': AddToken(TLoxTokenType.MINUS_SYMBOL);
    '+': AddToken(TLoxTokenType.PLUS_SYMBOL);
    ';': AddToken(TLoxTokenType.SEMICOLON_SYMBOL);
    '*': AddToken(TLoxTokenType.STAR_SYMBOL);
    '!': AddToken(IfThen(Match('='), TLoxTokenType.NOT_EQUAL_PAIRS_SYMBOL, TLoxTokenType.NOT_SYMBOL));
    '=': AddToken(IfThen(Match('='), TLoxTokenType.EQUAL_EQUAL_PAIRS_SYMBOL, TLoxTokenType.EQUAL_SYMBOL));
    '<': AddToken(IfThen(Match('='), TLoxTokenType.LESS_EQUAL_PAIRS_SYMBOL, TLoxTokenType.LESS_SYMBOL));
    '>': AddToken(IfThen(Match('='), TLoxTokenType.GREATER_EQUAL_PAIRS_SYMBOL, TLoxTokenType.GREATER_SYMBOL));
    '/':
    begin
      if (match('/')) then
      begin
        // Um comentário vai até o final da linha.
        while (Peek() <> #10) and not isAtEnd() do
          Advance();
      end
      else
        AddToken(TLoxTokenType.SLASH_SYMBOL);
    end;
    ' ', #13, #9: ; // Ignorar espaço em branco, retorno do carro e tabulação.
    #10: Inc(FLineNro); // Nova linha.
    '"': ScanString();
    '0'..'9': ScanNumber();
    'a'..'z', 'A'..'Z', '_': ScanIdentifier();
  else
    Error(FLineNro, 'Caráter inesperado.');
  end;

end;

procedure TScanner.ScanIdentifier();
var
  Text: string;
  TokenType: TLoxTokenType;
begin

  while (IsAlphaNumeric(Peek())) do
    Advance();

  // See if the identifier is a reserved word.
  Text := Copy(FSource, FStart, FCurrent - FStart);

  if not LoxReservedKeywords.TryGetValue(Text, TokenType) then
    TokenType := TLoxTokenType.IDENTIFIER_TOKEN;

  AddToken(TokenType);
end;

function TScanner.IsAlphaNumeric(c: Char): Boolean;
begin
  Result := isAlpha(c) or isDigit(c);
end;

function TScanner.IsAlpha(c: Char): Boolean;
begin
  Result := ((c >= 'a') and (c <= 'z')) or
            ((c >= 'A') and (c <= 'Z')) or
            (c = '_');
end;

function TScanner.IsDigit(c: Char): Boolean;
begin
  Result := (c >= '0') and (c <= '9');
end;

procedure TScanner.ScanNumber;
var
  Value: TLoxValue;
  OldDecimalSeparator: Char;
begin
  while IsDigit(Peek()) do
    Advance();

  // Procure uma parte fracionária.
  if (Peek() = '.') and isDigit(PeekNext()) then
  begin
    // Consuma o "."
    Advance();

    while IsDigit(Peek()) do
      Advance();
  end;

  OldDecimalSeparator := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := '.';
    Value := Default(TLoxValue);
    Value.ValueType := TLoxValueType.IS_DOUBLE;
    Value.DoubleValue := StrToFloat(Copy(FSource, FStart, FCurrent - FStart));
    AddToken(TLoxTokenType.NUMBER_LITERAL, Value);
  finally
    FormatSettings.DecimalSeparator := OldDecimalSeparator;
  end;
end;

procedure TScanner.ScanString();
var
  Value: TLoxValue;
begin

  while (Peek() <> '"') and not IsAtEnd() do
  begin
    if (Peek() = #10) then
      Inc(FLineNro);

    Advance();
  end;

  // String não terminada.
  if (isAtEnd()) then
  begin
    Error(FLineNro, 'String não terminada.');
    Exit();
  end;

  // O fechamento da string ".
  Advance();

  // Apare as aspas circundantes.
  Value := Default(TLoxValue);
  Value.ValueType := TLoxValueType.IS_STRING;
  Value.StrValue := ShortString(Copy(FSource, FStart + 1, FCurrent - FStart - 2));
  AddToken(TLoxTokenType.STRING_LITERAL, Value);
end;

function TScanner.Peek(): Char;
begin
  if (isAtEnd()) then
    Exit(#0);

  Result := FSource[FCurrent];
end;

function TScanner.PeekNext(): Char;
begin
  if (FCurrent + 1) > FSource.Length then
    Exit(#0);

  Result := FSource[FCurrent + 1];
end;

function TScanner.Match(Expected: Char): Boolean;
begin
  if IsAtEnd() then
    Exit(False);

  if (FSource[FCurrent] <> Expected) then
    Exit(False);

  Inc(FCurrent);

  Result := True;
end;

procedure TScanner.Error(Line: Integer; Msg: string);
begin
  if Assigned(FOnError) then
    FOnError(Line, Msg);
end;

function TScanner.ScanTokens: TObjectList<TLoxToken>;
var
  NullValue: TLoxValue;
begin

  while not IsAtEnd() do
  begin
    // Estamos no início do próximo léxico.
    FStart := FCurrent;
    ScanToken();
  end;

  NullValue.ValueType := TLoxValueType.IS_NULL;
  FTokens.Add(TLoxToken.Create(TLoxTokenType.END_OF_FILE_TOKEN, '', NullValue, FLineNro));
  Result := FTokens;

end;

end.
