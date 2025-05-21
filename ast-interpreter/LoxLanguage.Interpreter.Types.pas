// Marcello Mello
// 13/05/2025
//
unit LoxLanguage.Interpreter.Types;

{$SCOPEDENUMS ON}

interface

uses
  SysUtils,
  Classes,
  Generics.Collections;

type

  TTokenType = (
    // Tokens de caractere único
    LEFT_PAREN_SYMBOL,
    RIGHT_PAREN_SYMBOL,
    LEFT_BRACE_SYMBOL,
    RIGHT_BRACE_SYMBOL,
    COMMA_SYMBOL,
    DOT_SYMBOL,
    MINUS_SYMBOL,
    PLUS_SYMBOL,
    SEMICOLON_SYMBOL,
    SLASH_SYMBOL,
    STAR_SYMBOL,

    // Um ou dois tokens de caracteres
    NOT_SYMBOL,
    NOT_EQUAL_PAIRS_SYMBOL,
    EQUAL_SYMBOL,
    EQUAL_EQUAL_PAIRS_SYMBOL,
    GREATER_SYMBOL,
    GREATER_EQUAL_PAIRS_SYMBOL,
    LESS_SYMBOL,
    LESS_EQUAL_PAIRS_SYMBOL,

    // Literais
    IDENTIFIER_TOKEN,
    STRING_LITERAL,
    NUMBER_LITERAL,
    INTEGER_LITERAL,

    // Palavras-chave
    AND_KEYWORD,
    BREAK_KEYWORD,
    CLASS_KEYWORD,
    CONTINUE_KEYWORD,
    DO_KEYWORD,
    ELSE_KEYWORD,
    FALSE_KEYWORD,
    FUN_KEYWORD,
    FOR_KEYWORD,
    IF_KEYWORD,
    NIL_KEYWORD,
    OR_KEYWORD,
    PRINT_KEYWORD,
    RETURN_KEYWORD,
    SUPER_KEYWORD,
    THIS_KEYWORD,
    TRUE_KEYWORD,
    VAR_KEYWORD,
    WHILE_KEYWORD,

    END_OF_FILE_TOKEN
  );

  TFunctionType = (NONE, &FUNCTION, INITIALIZER, METHOD);
  TClassType = (NONE, &CLASS, SUBCLASS);

  TLoxValueType = (
    IS_UNDEF     = 0,
    IS_NULL      = 1,
    IS_FALSE     = 2,
    IS_TRUE      = 3,
    IS_INT32     = 4,
    IS_INT64     = 5,
    IS_DOUBLE    = 6,
    IS_STRING    = 7,
    IS_BOOLEAN   = 8,
    IS_CHAR      = 9,
    IS_CALLABLE	 = 10,
    IS_CLASS	 = 11,
    IS_OBJECT	 = 12,
    IS_METHOD    = 13
  );

  TLoxCallableValue = Pointer;
  TLoxObjectValue = Pointer;
  TLoxClassValue = Pointer;
  TLoxMethodValue = Pointer;

  TLoxValue = record
    ValueType: TLoxValueType;
    case Byte of
      0: (Int32Value: Integer);
      1: (Int64Value: Int64);
      2: (DoubleValue: Double);
      3: (StrValue: ShortString);
      4: (BooleanValue: Boolean);
      5: (CharValue: Char);
      6: (CallableValue: TLoxCallableValue);
      7: (ClassValue: TLoxClassValue);
      8: (ObjectInstanceValue: TLoxObjectValue);
      9: (MethodValue: TLoxMethodValue);
  end;

  TToken = class
  private
    FTokenType: TTokenType;
    FLexeme: string;
    FLiteral: TLoxValue;
    FLineNro: Integer;
  public
    constructor Create(TokenType: TTokenType; Lexeme: string; Literal: TLoxValue; LineNro: Integer);
    function ToString(): string; override;
    property TokenType: TTokenType read FTokenType;
    property Lexeme: string read FLexeme;
    property Literal: TLoxValue read FLiteral;
    property LineNro: Integer read FLineNro;
  end;

  ERuntimeError = class(Exception)
  private
    FToken: TToken;
  public
    constructor Create(Token: TToken; Msg: string);
    property Token: TToken read FToken;
  end;

var
  Keywords: TDictionary<string, TTokenType>;

implementation

uses
  LoxLanguage.Interpreter.Utils;

{ TToken }

constructor TToken.Create(TokenType: TTokenType; Lexeme: string; Literal: TLoxValue; LineNro: Integer);
begin
  FTokenType := TokenType;
  FLexeme := Lexeme;
  FLiteral := Literal;
  FLineNro := LineNro;
end;

function TToken.ToString: string;
var
  StrValue: string;
begin

  if FLiteral.ValueType = TLoxValueType.IS_STRING then
    StrValue := String(FLiteral.StrValue)
  else
    StrValue := '';

  Result := Format('%s %s %s',
                   [TEnumConversor<TTokenType>.ToString(FTokenType),
                   FLexeme,
                   StrValue]);
end;

{ ERuntimeError }

constructor ERuntimeError.Create(Token: TToken; Msg: string);
begin
  inherited Create(Msg);
  FToken := Token;
end;

{ TLoxValue }

initialization
  Keywords := TDictionary<string, TTokenType>.Create();
  keywords.Add('and',    TTokenType.AND_KEYWORD);
  keywords.Add('break',  TTokenType.BREAK_KEYWORD);
  keywords.Add('class',  TTokenType.CLASS_KEYWORD);
  keywords.Add('continue',  TTokenType.CONTINUE_KEYWORD);
  keywords.Add('do',  TTokenType.DO_KEYWORD);
  keywords.Add('else',   TTokenType.ELSE_KEYWORD);
  keywords.Add('false',  TTokenType.FALSE_KEYWORD);
  keywords.Add('for',    TTokenType.FOR_KEYWORD);
  keywords.Add('fun',    TTokenType.FUN_KEYWORD);
  keywords.Add('if',     TTokenType.IF_KEYWORD);
  keywords.Add('nil',    TTokenType.NIL_KEYWORD);
  keywords.Add('or',     TTokenType.OR_KEYWORD);
  keywords.Add('print',  TTokenType.PRINT_KEYWORD);
  keywords.Add('return', TTokenType.RETURN_KEYWORD);
  keywords.Add('super',  TTokenType.SUPER_KEYWORD);
  keywords.Add('this',   TTokenType.THIS_KEYWORD);
  keywords.Add('true',   TTokenType.TRUE_KEYWORD);
  keywords.Add('var',    TTokenType.VAR_KEYWORD);
  keywords.Add('while',  TTokenType.WHILE_KEYWORD);

finalization
  Keywords.Free();


end.
