// Marcello Mello
// 28/09/2019

unit LoxLanguage.Interpreter.AST.Generate;

interface

uses
  System.Generics.Collections;

type

  TAstItem = class
    Name: string;
    Fields: string;
  end;

  TAstGrupo = class
    Nome: string;
    Items: TObjectList<TAstItem>;
  public
    constructor Create;
    destructor Destroy; override;

  end;

procedure DefineAst(OutputDir: string; AstGrupos: TObjectList<TAstGrupo>);

implementation

uses
  System.SysUtils,
  System.Classes;

procedure DefineType(Writer: TStringList; BaseName, ClassName, FieldList: string);
var
  Fields: TArray<string>;
  Field,
  name: string;
begin
  // Construtor.
  Writer.Add('constructor ' + className + BaseName + '.Create(' + fieldList + ');');
  Writer.Add('begin');

  // Armazenar parâmetros em campos.
  Fields := FieldList.split(['; ']);
  for Field in Fields do
  begin
    Name := field.split([': '])[0];
    Writer.Add('  F' + Name + ' := ' + Name + ';');
  end;

  Writer.Add('end;');
  Writer.Add('');


  Writer.Add('function ' + className + BaseName + '.Accept(Visitor: IAstVisitor): TLoxValue; ');
  Writer.Add('begin');
  Writer.Add('  Result := Visitor.Visit(Self);');
  Writer.Add('end;');
  Writer.Add('');

end;

procedure DefineInterfaceType(Writer: TStringList; BaseName, ClassName, FieldList: string);
var
  Fields: TArray<string>;
  Field: string;
  FieldName: string;
  FieldTypeName: string;
begin

  Writer.Add('  ' + className + BaseName + ' = class(T' + baseName + ')');

  // Campos.
  Writer.Add('  private');
  fields := fieldList.split(['; ']);
  for field in fields do
  begin
    Writer.Add('    F' + Field + ';');
  end;

  // Metodos publicos.
  Writer.Add('  public');
  Writer.Add('    constructor Create(' + FieldList + ');');
  Writer.Add('    function Accept(Visitor: IAstVisitor): TLoxValue; override; ');

  // Propriedades publicas.
  fields := fieldList.split(['; ']);
  for Field in fields do
  begin
    FieldName := Field.split([': '])[0];
    FieldTypeName := Field.split([': '])[1];
    Writer.Add('    property ' + FieldName + ': ' + FieldTypeName + ' read F' + FieldName + ' write F' + FieldName + ';');
  end;

  Writer.Add('  end;');
end;

procedure DefineVisitor(Writer: TStringList; AstGrupos: TObjectList<TAstGrupo>);
var
  AstGrupo: TAstGrupo;
  AstItem: TAstItem;
begin
  Writer.Add('  IAstVisitor = interface');
  Writer.Add('  [''{E92FFE0B-F01A-4F30-BF88-0C866382851F}'']');

  for AstGrupo in AstGrupos do
  begin
    for AstItem in AstGrupo.Items do
      Writer.Add('    function Visit(' + Copy(AstItem.Name, 2) + AstGrupo.Nome + ': ' + AstItem.Name + AstGrupo.Nome + '): TLoxValue; overload;');
  end;

  Writer.Add('  end;');
end;

procedure DefineAst(OutputDir: string; AstGrupos: TObjectList<TAstGrupo>);

const
  TARGET_UNIT_NAME = 'LoxLanguage.Interpreter.AST';

var
  AstGrupo: TAstGrupo;
  AstItem: TAstItem;
  Writer: TStringList;
  OutputFile: string;
begin

  Writer := TStringList.Create();
  Writer.Add('// ******************************************************************************');
  Writer.Add('//                                                                               ');
  Writer.Add('//               The Lox Language - Abstract Syntax Tree                         ');
  Writer.Add('//                                                                               ');
  Writer.Add('// ESSE ARQUIVO É GERADO DE FORMA AUTOMATICA PELO PROGRAMA "GenerateApp"         ');
  Writer.Add('//                                                                               ');
  Writer.Add('// GenerateApp: ' + ExtractFileName(ParamStr(0)));
  Writer.Add('// Data: ' + DateTimeToStr(Now()));
  Writer.Add('//                                                                               ');
  Writer.Add('// ******************************************************************************');
  Writer.Add('');
  Writer.Add(Format('unit %s;', [TARGET_UNIT_NAME]));
  Writer.Add('');
  Writer.Add('interface');
  Writer.Add('');
  Writer.Add('uses');
  Writer.Add('  System.Generics.Collections,');
  Writer.Add('  LoxLanguage.Interpreter.Types;');
  Writer.Add('');
  Writer.Add('type');
  Writer.Add('');
  Writer.Add('  IAstVisitor = interface;');
  Writer.Add('');
  Writer.Add('  TAstNode = class');
  Writer.Add('    function Accept(Visitor: IAstVisitor): TLoxValue; virtual; abstract;');
  Writer.Add('  end;');
  Writer.Add('');

  for AstGrupo in AstGrupos do
  begin
    Writer.Add('  { T' + AstGrupo.Nome + ' }');
    Writer.Add('');
    Writer.Add('  T' + AstGrupo.Nome + ' = class(TAstNode)');
    Writer.Add('  end;');

    for AstItem in AstGrupo.Items do
    begin
      Writer.Add('');
      DefineInterfaceType(Writer, AstGrupo.Nome, AstItem.Name, AstItem.Fields);
    end;

    Writer.Add('');
  end;

  DefineVisitor(Writer, AstGrupos);

  Writer.Add('');
  Writer.Add('implementation');
  Writer.Add('');

  for AstGrupo in AstGrupos do
  begin
    Writer.Add('  { T' + AstGrupo.Nome + ' }');
    Writer.Add('');

    for AstItem in AstGrupo.Items do
      DefineType(Writer, AstGrupo.Nome, AstItem.Name, AstItem.Fields);
  end;

  Writer.Add('end.');

  OutputFile := OutputDir + Format('\%s.pas', [TARGET_UNIT_NAME]);
  Writer.SaveToFile(OutputFile, TEncoding.UTF8);
  Writer.Free();

end;

{ TAstFile }

constructor TAstGrupo.Create;
begin
  Items := TObjectList<TAstItem>.Create();
end;

destructor TAstGrupo.Destroy;
begin
  Items.Free();
  inherited;
end;

end.
