// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Scanner;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  LoxLanguage.VirtualMachine.Types;

procedure InitScanner(const Source: PUTF8Char);
function ScanToken(): TToken;

implementation

uses
  System.SysUtils,
  System.AnsiStrings;

var
  Scanner: TScanner;

procedure InitScanner(const Source: PUTF8Char);
begin
  Scanner.Start := Source;
  Scanner.Current := Source;
  Scanner.Line := 1;
end;

function isAlpha(c: UTF8Char): Boolean;
begin
  Result := ((c >= 'a') and (c <= 'z')) or
            ((c >= 'A') and (c <= 'Z')) or
            (c = '_');
end;

function IsDigit(c: UTF8Char): Boolean;
begin
  Result := (c >= '0') and (c <= '9');
end;

function IsAtEnd(): Boolean;
begin
  Result := Scanner.Current^ = #0;
end;

function Advance(): UTF8Char;
begin
  Inc(Scanner.current);
  Result := Scanner.Current[-1];
end;

function Peek(): UTF8Char;
begin
  Result := Scanner.Current^;
end;

function PeekNext(): UTF8Char;
begin
  if IsAtEnd() then
    Exit(#0);

  Result := Scanner.Current[1];
end;

function Match(Expected: UTF8Char): Boolean;
begin
  if IsAtEnd() then
    Exit(False);

  if Scanner.Current^ <> Expected then
    Exit(False);

  Inc(Scanner.Current);
  Result := True;
end;

function MakeToken(TokenType: TTokenType): TToken;
var
  Token: TToken;
begin
  Token.TokenType := TokenType;
  Token.Start := Scanner.Start;
  Token.Length := Integer(Scanner.Current - Scanner.Start);
  Token.Line := Scanner.Line;

  Result := Token;
end;

function ErrorToken(Msg: PUTF8Char): TToken;
var
  Token: TToken;
begin
  Token.TokenType := TTokenType.TOKEN_ERROR;
  Token.start := Msg;
  Token.Length := System.AnsiStrings.StrLen(Msg);
  Token.Line := Scanner.Line;

  Result := Token;
end;

procedure SkipWhitespace();
var
  c: UTF8Char;
begin
  while True do
  begin
    c := Peek();

    case c of
      ' ',
      #13,
      #9: Advance();
      #10:
      begin
        Inc(Scanner.Line);
        Advance();
      end;
      '/':
      begin
        if (PeekNext() = '/') then
        begin
          // Um comentário vai até o final da linha.
          while (Peek() <> #10) and not IsAtEnd() do
            Advance();
        end
        else
          Break;
      end;
    else
      Break;
    end;
  end;
end;

function CheckKeyword(Start: Integer; Length: Integer; const rest: PUTF8Char; TokenType: TTokenType): TTokenType;
begin
  if (Scanner.current - Scanner.Start = Start + Length) then
  begin
    if CompareMem(Scanner.Start + Start, Rest, Length) then
      Exit(TokenType);
  end;

  Result := TTokenType.TOKEN_IDENTIFIER;
end;

function IdentifierType: TTokenType;
begin

  case Scanner.Start[0] of
    'a': Exit(CheckKeyword(1, 2, 'nd', TTokenType.TOKEN_AND));
    'c': Exit(CheckKeyword(1, 4, 'lass', TTokenType.TOKEN_CLASS));
    'e': Exit(CheckKeyword(1, 3, 'lse', TTokenType.TOKEN_ELSE));
    'f':
    begin
      if (Scanner.Current - Scanner.Start > 1) then
      begin
        case Scanner.Start[1] of
          'a': Exit(CheckKeyword(2, 3, 'lse', TTokenType.TOKEN_FALSE));
          'o': Exit(CheckKeyword(2, 1, 'r', TTokenType.TOKEN_FOR));
          'u': Exit(CheckKeyword(2, 1, 'n', TTokenType.TOKEN_FUN));
        end;
      end;
    end;
    'i': Exit(CheckKeyword(1, 1, 'f', TTokenType.TOKEN_IF));
    'n': Exit(CheckKeyword(1, 2, 'il', TTokenType.TOKEN_NIL));
    'o': Exit(CheckKeyword(1, 1, 'r', TTokenType.TOKEN_OR));
    'p': Exit(CheckKeyword(1, 4, 'rint', TTokenType.TOKEN_PRINT));
    'r': Exit(CheckKeyword(1, 5, 'eturn', TTokenType.TOKEN_RETURN));
    's': Exit(CheckKeyword(1, 4, 'uper', TTokenType.TOKEN_SUPER));
    't':
    begin
      if (scanner.current - scanner.start > 1) then
      begin
        case scanner.start[1] of
          'h': Exit(CheckKeyword(2, 2, 'is', TTokenType.TOKEN_THIS));
          'r': Exit(CheckKeyword(2, 2, 'ue', TTokenType.TOKEN_TRUE));
        end;
      end;
    end;
    'v': Exit(CheckKeyword(1, 2, 'ar', TTokenType.TOKEN_VAR));
    'w': Exit(CheckKeyword(1, 4, 'hile', TTokenType.TOKEN_WHILE));
  end;

  Result := TTokenType.TOKEN_IDENTIFIER;
end;

function ScanIdentifier(): TToken;
begin
  while IsAlpha(Peek()) or IsDigit(Peek()) do
    Advance();

  Result := MakeToken(IdentifierType());
end;

function ScanNumber(): TToken;
begin
  while IsDigit(Peek()) do
    Advance();

  // Look for a fractional part.
  if (Peek() = '.') and IsDigit(PeekNext()) then
  begin
    // Consume the ".".
    Advance();

    while IsDigit(Peek()) do
      Advance();
  end;

  Result := MakeToken(TTokenType.TOKEN_NUMBER);
end;

function ScanString(): TToken;
begin
  while (Peek() <> '"') and not isAtEnd() do
  begin
    if Peek() = #10 then
      Inc(Scanner.Line);

    Advance();
  end;

  if (isAtEnd()) then
    Exit(ErrorToken('String não terminada.'));

  // The closing quote.
  Advance();
  Result := MakeToken(TTokenType.TOKEN_STRING);
end;

function ScanToken(): TToken;
var
  c: UTF8Char;
begin
  SkipWhitespace();

  Scanner.Start := Scanner.Current;

  if IsAtEnd() then
  begin
    Result := MakeToken(TTokenType.TOKEN_EOF);
    Exit();
  end;

  c := Advance();

  if IsAlpha(c) then
  begin
    Result := ScanIdentifier();
    Exit();
  end;

  if IsDigit(c) then
  begin
    Result := ScanNumber();
    Exit();
  end;

  case c of
    '(': Exit(MakeToken(TTokenType.TOKEN_LEFT_PAREN));
    ')': Exit(MakeToken(TTokenType.TOKEN_RIGHT_PAREN));
    '{': Exit(MakeToken(TTokenType.TOKEN_LEFT_BRACE));
    '}': Exit(MakeToken(TTokenType.TOKEN_RIGHT_BRACE));
    ';': Exit(MakeToken(TTokenType.TOKEN_SEMICOLON));
    ',': Exit(MakeToken(TTokenType.TOKEN_COMMA));
    '.': Exit(MakeToken(TTokenType.TOKEN_DOT));
    '-': Exit(MakeToken(TTokenType.TOKEN_MINUS));
    '+': Exit(MakeToken(TTokenType.TOKEN_PLUS));
    '/': Exit(MakeToken(TTokenType.TOKEN_SLASH));
    '*': Exit(MakeToken(TTokenType.TOKEN_STAR));
    '!':
    begin
      if Match('=') then
        Exit(MakeToken(TTokenType.TOKEN_BANG_EQUAL))
      else
        Exit(MakeToken(TTokenType.TOKEN_BANG));
    end;
    '=':
    begin
      if Match('=') then
        Exit(MakeToken(TTokenType.TOKEN_EQUAL_EQUAL))
      else
        Exit(MakeToken(TTokenType.TOKEN_EQUAL));
    end;
    '<':
    begin
      if Match('=') then
        Exit(MakeToken(TTokenType.TOKEN_LESS_EQUAL))
      else
        Exit(MakeToken(TTokenType.TOKEN_LESS));
    end;
    '>':
    begin
      if Match('=') then
        Exit(MakeToken(TTokenType.TOKEN_GREATER_EQUAL))
      else
        Exit(MakeToken(TTokenType.TOKEN_GREATER));
    end;
    '"': Exit(ScanString());
  end;

  Result := ErrorToken('Caráter inesperado.');

end;

end.
