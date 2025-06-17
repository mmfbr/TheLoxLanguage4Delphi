// Marcello Mello
// 28/09/2019

program LoxLanguage.Interpreter.AST.GenerateApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  LoxLanguage.Interpreter.AST.Generate in '..\LoxLanguage.Interpreter.AST.Generate.pas';

var
  OutputDir: string;
  AstItem: TAstItem;
  ExprGrupo: TAstGrupo;
  StmtGrupo: TAstGrupo;
  AstGrupos: TObjectList<TAstGrupo>;
begin

  if (ParamCount <> 1) then
  begin
    Writeln('uso: ' + TPath.GetFileNameWithoutExtension(ParamStr(0)) + ' <diretório de saída>');
    WriteLn;
    WriteLn('Pressione qualquer tecla para fechar...');
    ReadlN;
    Exit();
  end;

  AstGrupos := TObjectList<TAstGrupo>.Create();

  ExprGrupo := TAstGrupo.Create();
  ExprGrupo.Nome := 'ExpressionNode';

  AstItem := TAstItem.Create();
  AstItem.Name := 'TAssign';
  AstItem.Fields := 'Name: TToken; Value: TExpressionNode';
  ExprGrupo.Items.Add(AstItem);
  AstItem := TAstItem.Create();
  AstItem.Name := 'TBinary';
  AstItem.Fields := 'Left: TExpressionNode; Operador: TToken; Right: TExpressionNode';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TCall';
  AstItem.Fields := 'Callee: TExpressionNode; Paren: TToken; Arguments: TObjectList<TExpressionNode>';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TGet';
  AstItem.Fields := 'Obj: TExpressionNode; Name: TToken';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TGrouping';
  AstItem.Fields := 'Expr: TExpressionNode';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TLiteral';
  AstItem.Fields := 'Value: TLoxValue';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TLogical';
  AstItem.Fields := 'Left: TExpressionNode; Operador: TToken; Right: TExpressionNode';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TSet';
  AstItem.Fields := 'Obj: TExpressionNode; Name: TToken; Value: TExpressionNode';
  ExprGrupo.Items.Add(AstItem);


  AstItem := TAstItem.Create();
  AstItem.Name := 'TSuper';
  AstItem.Fields := 'Keyword: TToken; Method: TToken';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TThis';
  AstItem.Fields := 'Keyword: TToken';
  ExprGrupo.Items.Add(AstItem);


  AstItem := TAstItem.Create();
  AstItem.Name := 'TUnary';
  AstItem.Fields := 'Operador: TToken; Right: TExpressionNode';
  ExprGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TVariable';
  AstItem.Fields := 'Name: TToken';
  ExprGrupo.Items.Add(AstItem);
  AstGrupos.Add(ExprGrupo);


  StmtGrupo := TAstGrupo.Create();
  StmtGrupo.Nome := 'StatementNode';

  AstItem := TAstItem.Create();
  AstItem.Name := 'TBlock';
  AstItem.Fields := 'Statements: TObjectList<TStatementNode>';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TBreak';
  AstItem.Fields := '';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TContinue';
  AstItem.Fields := '';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TExpression';
  AstItem.Fields := 'Expression: TExpressionNode';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TIf';
  AstItem.Fields := 'Condition: TExpressionNode; ThenBranch: TStatementNode; ElseBranch: TStatementNode';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TFunction';
  AstItem.Fields := 'Name: TToken; Params: TObjectList<TToken>; Body: TObjectList<TStatementNode>';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TPrint';
  AstItem.Fields := 'Expr: TExpressionNode';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TClass';
  AstItem.Fields := 'Name: TToken; SuperClass: TVariableExpressionNode; Methods: TObjectList<TFunctionStatementNode>';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TReturn';
  AstItem.Fields := 'Keyword: TToken; Value: TExpressionNode';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TVar';
  AstItem.Fields := 'Name: TToken; Initializer: TExpressionNode';
  StmtGrupo.Items.Add(AstItem);

  AstItem := TAstItem.Create();
  AstItem.Name := 'TWhile';
  AstItem.Fields := 'Condition: TExpressionNode; Body: TStatementNode';
  StmtGrupo.Items.Add(AstItem);
  AstGrupos.Add(StmtGrupo);

  try
    OutputDir := ParamStr(1);
    DefineAst(OutputDir, AstGrupos);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
