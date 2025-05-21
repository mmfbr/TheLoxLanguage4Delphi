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

  TLoxTokenType = (
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

  TLoxFunctionType = (NONE, &FUNCTION, INITIALIZER, METHOD);
  TLoxClassType = (NONE, &CLASS, SUBCLASS);

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

  TLoxToken = class
  private
    FTokenType: TLoxTokenType;
    FLexeme: string;
    FLiteral: TLoxValue;
    FLineNro: Integer;
  public
    constructor Create(TokenType: TLoxTokenType; Lexeme: string; Literal: TLoxValue; LineNro: Integer);
    function ToString(): string; override;
    property TokenType: TLoxTokenType read FTokenType;
    property Lexeme: string read FLexeme;
    property Literal: TLoxValue read FLiteral;
    property LineNro: Integer read FLineNro;
  end;

  ELoxRuntimeError = class(Exception)
  private
    FToken: TLoxToken;
  public
    constructor Create(Token: TLoxToken; Msg: string);
    property Token: TLoxToken read FToken;
  end;

var
  LoxReservedKeywords: TDictionary<string, TLoxTokenType>;

implementation

uses
  LoxLanguage.Interpreter.Utils;

{ TToken }

constructor TLoxToken.Create(TokenType: TLoxTokenType; Lexeme: string; Literal: TLoxValue; LineNro: Integer);
begin
  FTokenType := TokenType;
  FLexeme := Lexeme;
  FLiteral := Literal;
  FLineNro := LineNro;
end;

function TLoxToken.ToString: string;
var
  StrValue: string;
begin

  if FLiteral.ValueType = TLoxValueType.IS_STRING then
    StrValue := String(FLiteral.StrValue)
  else
    StrValue := '';

  Result := Format('%s %s %s',
                   [TEnumConversor<TLoxTokenType>.ToString(FTokenType),
                   FLexeme,
                   StrValue]);
end;

{ ERuntimeError }

constructor ELoxRuntimeError.Create(Token: TLoxToken; Msg: string);
begin
  inherited Create(Msg);
  FToken := Token;
end;

{ TLoxValue }

initialization
  LoxReservedKeywords := TDictionary<string, TLoxTokenType>.Create();
  LoxReservedKeywords.Add('and',    TLoxTokenType.AND_KEYWORD);
  LoxReservedKeywords.Add('break',  TLoxTokenType.BREAK_KEYWORD);
  LoxReservedKeywords.Add('class',  TLoxTokenType.CLASS_KEYWORD);
  LoxReservedKeywords.Add('continue',  TLoxTokenType.CONTINUE_KEYWORD);
  LoxReservedKeywords.Add('do',  TLoxTokenType.DO_KEYWORD);
  LoxReservedKeywords.Add('else',   TLoxTokenType.ELSE_KEYWORD);
  LoxReservedKeywords.Add('false',  TLoxTokenType.FALSE_KEYWORD);
  LoxReservedKeywords.Add('for',    TLoxTokenType.FOR_KEYWORD);
  LoxReservedKeywords.Add('fun',    TLoxTokenType.FUN_KEYWORD);
  LoxReservedKeywords.Add('if',     TLoxTokenType.IF_KEYWORD);
  LoxReservedKeywords.Add('nil',    TLoxTokenType.NIL_KEYWORD);
  LoxReservedKeywords.Add('or',     TLoxTokenType.OR_KEYWORD);
  LoxReservedKeywords.Add('print',  TLoxTokenType.PRINT_KEYWORD);
  LoxReservedKeywords.Add('return', TLoxTokenType.RETURN_KEYWORD);
  LoxReservedKeywords.Add('super',  TLoxTokenType.SUPER_KEYWORD);
  LoxReservedKeywords.Add('this',   TLoxTokenType.THIS_KEYWORD);
  LoxReservedKeywords.Add('true',   TLoxTokenType.TRUE_KEYWORD);
  LoxReservedKeywords.Add('var',    TLoxTokenType.VAR_KEYWORD);
  LoxReservedKeywords.Add('while',  TLoxTokenType.WHILE_KEYWORD);

finalization
  LoxReservedKeywords.Free();


end.
