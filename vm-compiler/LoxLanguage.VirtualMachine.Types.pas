// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Types;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  LoxLanguage.VirtualMachine.Consts;

type

  TScanner = record
    Start: PUTF8Char;
    Current: PUTF8Char;
    Line: Integer;
  end;

  TTokenType = (
    // Single-character tokens.
    TOKEN_LEFT_PAREN, TOKEN_RIGHT_PAREN,
    TOKEN_LEFT_BRACE, TOKEN_RIGHT_BRACE,
    TOKEN_COMMA, TOKEN_DOT, TOKEN_MINUS, TOKEN_PLUS,
    TOKEN_SEMICOLON, TOKEN_SLASH, TOKEN_STAR,

    // One or two character tokens.
    TOKEN_BANG, TOKEN_BANG_EQUAL,
    TOKEN_EQUAL, TOKEN_EQUAL_EQUAL,
    TOKEN_GREATER, TOKEN_GREATER_EQUAL,
    TOKEN_LESS, TOKEN_LESS_EQUAL,

    // Literals.
    TOKEN_IDENTIFIER, TOKEN_STRING, TOKEN_NUMBER,

    // Keywords.
    TOKEN_AND, TOKEN_CLASS, TOKEN_ELSE, TOKEN_FALSE,
    TOKEN_FOR, TOKEN_FUN, TOKEN_IF, TOKEN_NIL, TOKEN_OR,
    TOKEN_PRINT, TOKEN_RETURN, TOKEN_SUPER, TOKEN_THIS,
    TOKEN_TRUE, TOKEN_VAR, TOKEN_WHILE,

    TOKEN_ERROR,
    TOKEN_EOF
  );

  PToken = ^TToken;
  TToken = record
    TokenType: TTokenType;
    Start: PUTF8Char;
    Length: Integer;
    Line: Integer;
  end;

  PObjString = ^TObjString;

  TOpCode = (
    OP_CONSTANT,
    OP_NIL,
    OP_TRUE,
    OP_FALSE,
    OP_POP,
    OP_GET_LOCAL,
    OP_SET_LOCAL,
    OP_GET_GLOBAL,
    OP_DEFINE_GLOBAL,
    OP_SET_GLOBAL,
    OP_GET_UPVALUE,
    OP_SET_UPVALUE,
    OP_GET_PROPERTY,
    OP_SET_PROPERTY,
    OP_GET_SUPER,
    OP_EQUAL,
    OP_GREATER,
    OP_LESS,
    OP_ADD,
    OP_SUBTRACT,
    OP_MULTIPLY,
    OP_DIVIDE,
    OP_NOT,
    OP_NEGATE,
    OP_PRINT,
    OP_JUMP,
    OP_JUMP_IF_FALSE,
    OP_LOOP,
    OP_CALL,
    OP_INVOKE,
    OP_SUPER,
    OP_CLOSURE,
    OP_CLOSE_UPVALUE,
    OP_RETURN,
    OP_CLASS,
    OP_INHERIT,
    OP_METHOD
  );

{$POINTERMATH ON}
  PUint8 = ^UInt8;
  PInt         = ^Integer;
  PValue = ^TValue;
{$POINTERMATH OFF}

  PValueArray = ^TValueArray;
  TValueArray = record
    Capacity: Integer;
    Count: Integer;
    Values: PValue;
  end;

  PChunk = ^TChunk;
  TChunk = record
    Count: Integer;
    Capacity: Integer;
    Code: PUInt8;
    Lines: PInt;
    Constants: TValueArray;
  end;


  TValueType = (
    VAL_BOOL,
    VAL_NIL,
    VAL_NUMBER,
    VAL_OBJ
   );

  TAsValue = record
    case SmallInt of
      0: (Bool: Boolean);
      1: (Number: Double);
      2: (Obj: Pointer);
  end;


  TValue = record
    ValueType: TValueType;
    AsValue: TAsValue;
  end;


  {$POINTERMATH ON}
  PEntry = ^TEntry;
  {$POINTERMATH OFF}

  TEntry = record
    Key: PObjString;
    Value: TValue;
  end;

  PTable = ^TTable;
  TTable = record
    Count: Integer;
    CapacityMask: Integer;
    Entries: PEntry;
  end;


  TObjType = (
    OBJ_BOUND_METHOD,
    OBJ_CLASS,
    OBJ_CLOSURE,
    OBJ_FUNCTION,
    OBJ_INSTANCE,
    OBJ_NATIVE,
    OBJ_STRING,
    OBJ_UPVALUE
  );

  {$POINTERMATH ON}
  PPObj = ^PObj;
  {$POINTERMATH OFF}

  PObj = ^TObj;
  TObj = record
    ObjType: TObjType;
    IsDark: Boolean;
    Next: PObj;
  end;


  TObjFunction = record
    Obj: TObj;
    Arity: Integer;
    UpvalueCount: Integer;
    Chunk: TChunk;
    Name: PObjString;
  end;

  TNativeFn = function(ArgCount: Integer; Args: PValue): TValue;

  PObjNative = ^TObjNative;
  TObjNative = record
    Obj: TObj;
    Func: TNativeFn;
  end;

  TObjString = record
    Obj: TObj;
    Length: Integer;
    Chars: PUTF8Char;
    Hash: Cardinal;
  end;

  PObjUpValue = ^TObjUpValue;
  TObjUpValue = record
    Obj: TObj;
    Location: PValue;
    closed: TValue;
    Next: PObjUpvalue;
  end;

  {$POINTERMATH ON}
  PPObjUpValue = ^PObjUpValue;
  {$POINTERMATH OFF}


  PObjFunction = ^TObjFunction;


  PObjClosure = ^TObjClosure;
  TObjClosure = record
    Obj: TObj;
    Func: PObjFunction;
    Upvalues: PPObjUpvalue;
    UpvalueCount: Integer;
  end;


  PObjClass = ^TObjClass;

  TObjClass = record
    Obj: TObj;
    Name: PObjString;
    Methods: TTable;
  end;

  PObjInstance = ^TObjInstance;
  TObjInstance = record
    Obj: TObj;
    klass: PObjClass;
    Fields: TTable;
  end;

  PObjBoundMethod = ^TObjBoundMethod;
  TObjBoundMethod = record
    Obj: TObj;
    Receiver: TValue;
    Method: PObjClosure;
  end;

  TParser = record
    Current: TToken;
    Previous: TToken;
    HadError: Boolean;
    PanicMode: Boolean;
  end;

  TPrecedence = (
    PREC_NONE,
    PREC_ASSIGNMENT,  // =
    PREC_OR,          // or
    PREC_AND,         // and
    PREC_EQUALITY,    // == !=
    PREC_COMPARISON,  // < > <= >=
    PREC_TERM,        // + -
    PREC_FACTOR,      // * /
    PREC_UNARY,       // ! -
    PREC_CALL,        // . () []
    PREC_PRIMARY
  );

  PParseRule = ^TParseRule;
  TParseRule = record
    Prefix: Pointer;
    Infix: Pointer;
    Precedence: TPrecedence;
  end;

  PLocal = ^TLocal;
  TLocal = record
    Name: TToken;
    Depth: Integer;
    IsCaptured: Boolean;
  end;

  PUpvalue = ^TUpvalue;
  TUpvalue = record
    index: UInt8;
    IsLocal: Boolean;
  end;

  TFunctionType = (
    TYPE_FUNCTION,
    TYPE_INITIALIZER,
    TYPE_METHOD,
    TYPE_SCRIPT
  );

  PCompiler = ^TCompiler;
  TCompiler = record
    Enclosing: PCompiler;
    Func: PObjFunction;
    FunctionType: TFunctionType;
    Locals: array[0..UINT8_COUNT-1] of TLocal;
    LocalCount: Integer ;
    Upvalues: array[0..UINT8_COUNT-1] of TUpvalue;
    ScopeDepth: Integer;
  end;


  PClassCompiler = ^TClassCompiler;

  TClassCompiler = record

    Enclosing: PClassCompiler;
    Name: TToken;
    HasSuperclass: Boolean;
  end;



implementation

end.
