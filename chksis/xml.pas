unit XML;


interface

Uses LibXmlParser, SysUtils;

Function XML_RetornaValor(Tag : String; Fonte : String) : String;

implementation


Function XML_RetornaValor(Tag : String; Fonte : String): String;
VAR
  Parser : TXmlParser;
begin
  Parser := TXmlParser.Create;
  Parser.Normalize := TRUE;
  Parser.LoadFromBuffer(PAnsiChar(Fonte));
  Parser.StartScan;
  WHILE Parser.Scan DO
  Begin
    if (Parser.CurPartType in [ptContent, ptCData]) Then  // Process Parser.CurContent field here
    begin
         if (UpperCase(Parser.CurName) = UpperCase(Tag)) then
         Begin
           Result := Parser.CurContent;
         end;
     end;
  end;
  Parser.Free;
end;

end.
