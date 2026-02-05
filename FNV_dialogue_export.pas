// -----------------------------------------------------------------------------
// FNV_dialogue_export.pas
// -----------------------------------------------------------------------------
// Description: 
// A delphi FNVEdit-friendly script for exporting textual data from the Fallout
// New Vegas game.
// -----------------------------------------------------------------------------
// Author: 36.739237, -2.115694
// Date: 02.02.2026
// License: Unlicense
// Listening: Meredith Ann Brooks
// Discovery: William-Adolphe Bouguereau
// -----------------------------------------------------------------------------
unit UserScript;

interface
uses Classes, SysUtils;

implementation

var
  OutLines: TStringList;
  OutFile: string;
  RecordCounter: Integer;

{================ SAFE HELPERS ================}

function SigEquals(const a, b: string): Boolean;
begin
  Result := UpperCase(a) = UpperCase(b);
end;

function EncodeNewlines(const s: string): string;
var
  i: Integer;
  c: string;
begin
  Result := '';
  i := 1;
  while i <= Length(s) do begin
    c := Copy(s, i, 1);
    if c = #13 then begin
      Result := Result + '\n';
      if (i < Length(s)) and (Copy(s, i+1, 1) = #10) then Inc(i);
    end
    else if c = #10 then
      Result := Result + '\n'
    else
      Result := Result + c;
    Inc(i);
  end;
end;

function QuoteCSV(const s: string): string;
var
  i: Integer;
  t, c: string;
begin
  t := '';
  for i := 1 to Length(s) do begin
    c := Copy(s, i, 1);
    if c = '"' then
      t := t + '""'
    else
      t := t + c;
  end;

  if (Pos(';', t) > 0) or (Pos('"', t) > 0) or
     (Pos(#10, t) > 0) or (Pos(#13, t) > 0) then
    Result := '"' + t + '"'
  else
    Result := t;
end;

function FileNameOf(e: IInterface): string;
var
  f: IInterface;
begin
  Result := '';
  f := GetFile(e);
  if Assigned(f) then
    Result := ExtractFileName(GetFileName(f));
end;

function SafeEditValue(e: IInterface; const path: string): string;
begin
  try
    Result := GetElementEditValues(e, path);
  except
    Result := '';
  end;
end;

{================ INFO HELPERS ================}

function CollectINFOResponses(info: IInterface): string;
var
  responses, resp, nam1: IInterface;
  i: Integer;
  part, outText: string;
begin
  Result := '';
  responses := ElementByName(info, 'Responses');
  if not Assigned(responses) then Exit;

  outText := '';
  for i := 0 to ElementCount(responses) - 1 do begin
    resp := ElementByIndex(responses, i);
    if not Assigned(resp) then Continue;

    nam1 := ElementByName(resp, 'NAM1 - Response Text');
    if not Assigned(nam1) then Continue;

    part := GetEditValue(nam1);
    if part = '' then Continue;

    if outText <> '' then outText := outText + '|';
    outText := outText + EncodeNewlines(part);
  end;

  Result := outText;
end;

{================ MESG HELPERS ================}

function CollectITXT(menuButtons: IInterface): string;
var
  i: Integer;
  btn, itxt: IInterface;
  part, outText: string;
begin
  Result := '';
  if not Assigned(menuButtons) then Exit;

  outText := '';
  for i := 0 to ElementCount(menuButtons) - 1 do begin
    btn := ElementByIndex(menuButtons, i);
    if not Assigned(btn) then Continue;

    itxt := ElementByName(btn, 'ITXT - Button Text');
    if not Assigned(itxt) then Continue;

    part := GetEditValue(itxt);
    if part = '' then Continue;

    if outText <> '' then outText := outText + '|';
    outText := outText + EncodeNewlines(part);
  end;

  Result := outText;
end;

{================ CORE SCAN ================}

procedure ScanContainer(container: IInterface);
var
  i: Integer;
  e: IInterface;
  sig, line: string;

  textContent, contentSource: string;
  nameField, topicField, questField: string;
  additionalContent: string;
  speakerField: string;
begin
  for i := 0 to ElementCount(container) - 1 do begin
    e := ElementByIndex(container, i);
    if not Assigned(e) then Continue;

    sig := Signature(e);

    if SigEquals(sig, 'GRUP') then begin
      ScanContainer(e);
      Continue;
    end;

    if not (
      SigEquals(sig, 'INFO') or
      SigEquals(sig, 'MESG') or
      SigEquals(sig, 'DIAL') or
      SigEquals(sig, 'NOTE') or
      SigEquals(sig, 'LSCR')
    ) then
      Continue;

    Inc(RecordCounter);
    if (RecordCounter mod 500 = 0) then
      AddMessage('Processed ' + IntToStr(RecordCounter));

    textContent := '';
    contentSource := '';
    nameField := '';
    topicField := '';
    questField := '';
    additionalContent := '';
    speakerField := '';

    { INFO }
    if SigEquals(sig, 'INFO') then begin
      textContent := CollectINFOResponses(e);
      if textContent <> '' then
        contentSource := 'NAM1';

      nameField   := SafeEditValue(e, 'Topic');
      topicField  := SafeEditValue(e, 'DATA - DATA\Type');
      questField  := SafeEditValue(e, 'QSTI - Quest');
      speakerField := SafeEditValue(e, 'ANAM - Speaker');
    end;

    { MESG }
    if SigEquals(sig, 'MESG') then begin
      nameField := SafeEditValue(e, 'FULL - Name');

      textContent := SafeEditValue(e, 'DESC - Description');
      if textContent <> '' then
        contentSource := 'DESC - Description';

      additionalContent := CollectITXT(ElementByName(e, 'Menu Buttons'));
    end;

    { DIAL }
    if SigEquals(sig, 'DIAL') then begin
      textContent := SafeEditValue(e, 'FULL - Name');
      if textContent <> '' then
        contentSource := 'FULL - Name';

      nameField := SafeEditValue(e, 'Record Header\FormID');
      topicField := SafeEditValue(e, 'DATA - DATA\Type');
    end;

    { NOTE }
    if SigEquals(sig, 'NOTE') then begin
      nameField := SafeEditValue(e, 'FULL - Name');

      textContent := SafeEditValue(e, 'TNAM - Text / Topic\Text');
      if textContent <> '' then
        contentSource := 'TNAM - Text / Topic';

      topicField := SafeEditValue(e, 'DATA - Type');
      questField := SafeEditValue(e, 'Quests\ONAM - Quest');
    end;

    { LSCR }
    if SigEquals(sig, 'LSCR') then begin
      textContent := SafeEditValue(e, 'DESC - Description');
      if textContent <> '' then
        contentSource := 'DESC - Description';
    end;

    line :=
      QuoteCSV(sig) + ';' +
      QuoteCSV(FileNameOf(e)) + ';' +
      QuoteCSV(IntToHex(FixedFormID(e), 8)) + ';' +
      QuoteCSV(SafeEditValue(e, 'EDID')) + ';' +
      QuoteCSV(textContent) + ';' +
      QuoteCSV(contentSource) + ';' +
      QuoteCSV(nameField) + ';' +
      QuoteCSV(topicField) + ';' +
      QuoteCSV(questField) + ';' +
      QuoteCSV(PathName(e)) + ';' +
      QuoteCSV(additionalContent) + ';' +
      QuoteCSV(speakerField);

    OutLines.Add(line);
  end;
end;

{================ ENTRY ================}

function Initialize: Integer;
var
  f: Integer;
begin
  if not DirectoryExists(wbTempPath) then
    ForceDirectories(wbTempPath);

  OutFile := wbTempPath + 'Export_All_Dialogue.csv';
  OutLines := TStringList.Create;

  OutLines.Add(
    'signature;file_name;formID;editorID;text_content;content_source;' +
    'name;topic;quest;topLevelPath;additional_content;speaker'
  );

  RecordCounter := 0;
  AddMessage('Starting dialogue export...');

  for f := 0 to FileCount - 1 do
    ScanContainer(FileByIndex(f));

  OutLines.SaveToFile(OutFile);
  OutLines.Free;

  AddMessage('Finished. Exported ' + IntToStr(RecordCounter) + ' records.');
  Result := 0;
end;

end.
