// Marcello Mello
// 25/11/2019

unit LoxLanguage.VirtualMachine.Table;

{$I LoxLanguage.VirtualMachine.inc}

interface

uses
  System.Math,
  System.StrUtils,
  System.SysUtils,
  LoxLanguage.VirtualMachine.Types,
  LoxLanguage.VirtualMachine.Value;


procedure InitTable(Table: PTable);
procedure FreeTable(Table: PTable);
function TableGet(Table: PTable; Key: PObjString; Value: PValue): Boolean;
function TableSet(Table: PTable; Key: PObjString; Value: TValue): Boolean;
function TableDelete(Table: PTable; Key: PObjString): Boolean;
function FindEntry(Entries: PEntry; CapacityMask: Integer; Key: PObjString): PEntry;
procedure TableAddAll(From: PTable; To_: PTable);
function TableFindString(Table: PTable; Chars: PUTF8Char; Length: Integer; Hash: Cardinal): PObjString;

procedure TableRemoveWhite(Table: PTable);
procedure GrayTable(Table: PTable);


implementation

uses
  LoxLanguage.VirtualMachine.Memory;

const
  TABLE_MAX_LOAD = 0.75;

procedure InitTable(Table: PTable);
begin
  Table^.Count := 0;
  Table^.capacityMask := -1;
  Table^.Entries := nil;
end;

procedure FreeTable(Table: PTable);
begin
  FREE_ARRAY(Table^.Entries, Table^.capacityMask + 1);
  InitTable(Table);
end;

function TableGet(Table: PTable; Key: PObjString; Value: PValue): Boolean;
var
  Entry: PEntry;
begin
 if (Table^.Count = 0) then
   Exit(False);

  Entry := FindEntry(Table^.Entries, Table^.capacityMask, Key);
  if (Entry^.Key = nil) then
    Exit(False);

  Value^ := Entry^.Value;
  Result := True;
end;

function FindEntry(Entries: PEntry; CapacityMask: Integer; Key: PObjString): PEntry;
var
  Index: Cardinal;
  Entry: PEntry;
  Tombstone: PEntry;
begin
  Index := Key^.Hash and CapacityMask;
  Tombstone := nil;

  while True do
  begin
    Entry := @Entries[Index];

    if (Entry^.Key = nil) then
    begin
      if (IS_NIL(Entry^.Value)) then
      begin
        // Empty entry.
        if Tombstone <> nil then
          Result := Tombstone
        else
          Result := Entry;

        Exit();
      end
      else
      begin
        // Encontramos uma lápide.
        if (Tombstone = nil) then
          Tombstone := Entry;
      end;
    end
    else if (Entry^.Key = Key)  then
      Exit(Entry);

    Index := (Index + 1) and CapacityMask;
  end;

end;

procedure AdjustCapacity(Table: PTable; CapacityMask: Integer);
var
  Entries,
  Entry,
  dest: PEntry;
  i: Integer;
begin
  Entries := Reallocate(nil, 0, SizeOf(TEntry) * (CapacityMask + 1));
  for i := 0 to CapacityMask do
  begin
    Entries[i].Key := nil;
    Entries[i].Value := NIL_VAL();
  end;

  Table^.Count := 0;
  for i := 0 to Table^.CapacityMask do
  begin
    Entry := @Table^.Entries[i];
    if (Entry^.Key = nil) then
      Continue;

    Dest := FindEntry(Entries, CapacityMask, Entry^.Key);
    Dest^.Key := Entry^.key;
    Dest^.Value := Entry^.value;
    Table^.Count := Table^.Count + 1;
  end;


  FREE_ARRAY(Table^.Entries, Table^.CapacityMask + 1);

  Table^.Entries := Entries;
  Table^.CapacityMask := CapacityMask;
end;

function TableDelete(Table: PTable; Key: PObjString): Boolean;
var
  Entry: PEntry;
begin
  if (Table^.Count = 0) then
    Exit(False);

  // Find the entry.
  Entry := FindEntry(Table^.Entries, Table^.CapacityMask, Key);
  if (Entry^.Key = nil) then
    Exit(False);

  // Coloque uma lápide na entrada. (Sepultamento da entrada na tabela)
  Entry^.Key := nil;
  Entry^.Value := BOOL_VAL(True);

  Result := True;
end;

function TableSet(Table: PTable; Key: PObjString; Value: TValue): Boolean;
var
  Entry: PEntry;
  IsNewKey: Boolean;
  capacityMask: Integer;
begin
  if (Table^.Count + 1 > ((Table^.CapacityMask + 1) * TABLE_MAX_LOAD)) then
  begin
    capacityMask := GROW_CAPACITY(Table^.CapacityMask + 1) - 1;
    AdjustCapacity(Table, capacityMask);
  end;

  Entry := FindEntry(Table^.Entries, Table^.CapacityMask, Key);

  IsNewKey := Entry^.Key = nil;
  if IsNewKey and IS_NIL(Entry^.Value) then
    Table^.Count := Table^.Count + 1;

  Entry^.Key := Key;
  Entry^.Value := Value;
  Result := IsNewKey;
end;

procedure TableAddAll(From: PTable; To_: PTable);
var
  i: Integer;
  Entry: PEntry;
begin
  for i := 0 to From^.CapacityMask  do
  begin
    Entry := @From^.Entries[i];
    if (Entry^.Key <> nil) then
      TableSet(To_, Entry^.key, Entry^.value);
  end;
end;

function TableFindString(Table: PTable; Chars: PUTF8Char; Length: Integer; Hash: Cardinal): PObjString;
var
  Index: Cardinal;
  Entry: PEntry;
begin
  if (Table^.Count = 0) then
    Exit(nil);

  Index := Hash and Table^.CapacityMask;

  while true do
  begin
    Entry := @Table^.Entries[Index];

    if (Entry^.Key = nil) then
    begin
      // Pare se encontrarmos uma entrada vazia que não seja uma lápide.
      if (IS_NIL(Entry^.Value)) then
        Exit(nil);
    end
    else if (entry^.key^.length = length) and
            (entry^.key^.hash = hash) and
            CompareMem(entry^.key^.Chars, Chars, length)  then
      // Nós achamos.
    begin
      Exit(Entry^.Key);
    end;

    Index := (Index + 1) and Table^.CapacityMask;
  end;

end;

procedure TableRemoveWhite(Table: PTable);
var
  Entry: PEntry;
  i: Integer;
begin
  for i := 0 to Table^.CapacityMask do
  begin
  //< Optimization not-yet
    Entry := @table^.Entries[i];
    if (entry^.key <> nil) and not entry^.key^.obj.isDark then
      TableDelete(table, entry^.key);
  end;
end;

procedure GrayTable(Table: PTable);
var
  Entry: PEntry;
  i: Integer;
begin

  for i := 0 to table^.capacityMask do
  begin
    Entry := @Table^.Entries[i];
    GrayObject(PObj(entry^.key));
    GrayValue(entry^.value);
  end;

end;



end.
