// Marcello Mello
// 02/10/2019

unit LoxLanguage.Interpreter.Env;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  LoxLanguage.Interpreter.Types;

type

  TEnvironment = class
  private
    FValues: TDictionary<string, TLoxValue>;
    FEnclosing: TEnvironment;
  public
    constructor Create(Enclosing: TEnvironment = nil);
    destructor Destroy; override;
    procedure Define(const Name: string; Value: TLoxValue);
    function Ancestor(Distance: Integer): TEnvironment;
    function GetAt(Distance: Integer; Name: string): TLoxValue;
    procedure AssignAt(Distance: Integer; Name: TToken; Value: TLoxValue);
    function Get(Name: TToken): TLoxValue;
    procedure Assign(Name: TToken; Value: TLoxValue);
    property Enclosing: TEnvironment read FEnclosing;
  end;

implementation

{ TEnvironment }

destructor TEnvironment.Destroy;
begin
  FValues.Free();
  inherited;
end;

constructor TEnvironment.Create(Enclosing: TEnvironment = nil);
begin
  FEnclosing := Enclosing;
  FValues := TDictionary<string, TLoxValue>.Create();
end;

procedure TEnvironment.Define(const Name: string; Value: TLoxValue);
begin
  FValues.AddOrSetValue(Name, Value);
end;

function TEnvironment.Ancestor(Distance: Integer): TEnvironment;
var
  Environment: TEnvironment;
  i: Integer;
begin
  Environment := Self;

  for i := 0 to Distance - 1 do
    Environment := Environment.FEnclosing;

  Result := Environment;
end;

function TEnvironment.GetAt(Distance: Integer; Name: string): TLoxValue;
begin
  Result := Ancestor(distance).FValues[Name];
end;

procedure TEnvironment.AssignAt(Distance: Integer; Name: TToken; Value: TLoxValue);
begin
  Ancestor(distance).FValues[Name.lexeme] := Value;
end;

function TEnvironment.Get(Name: TToken): TLoxValue;
begin

  if FValues.ContainsKey(Name.Lexeme) then
    Result := FValues[Name.Lexeme]
  else if not (FEnclosing = nil) then
    Result := FEnclosing.Get(Name)
  else
    raise ERuntimeError.Create(Name, 'Variável indefinida "' + Name.Lexeme + '".');

end;

procedure TEnvironment.Assign(Name: TToken; Value: TLoxValue);
begin

  if (FValues.ContainsKey(Name.Lexeme)) then
    FValues.AddOrSetValue(Name.lexeme, Value)
  else if Assigned(FEnclosing) then
    FEnclosing.Assign(Name, Value)
  else
    raise ERuntimeError.Create(Name, 'Variável indefinida "' + name.lexeme + '".');

end;

end.
