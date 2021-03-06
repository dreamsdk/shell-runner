program DreamSDK_Runner;

{$mode objfpc}{$H+}
{$R *.res}

uses
  Interfaces,
  {$IFDEF Windows}
  Windows,
  {$ENDIF}
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils,
  Classes,
  VerIntf,
  Runner;

var
  ShellCommandLine: string;

function GetCommandLine: string;
var
  i: Integer;
  Buffer: TStringList;
  Param: string;

begin
  Buffer := TStringList.Create;
  try
    for i := 1 to ParamCount do
    begin
      Param := Trim(ParamStr(i));
      if Param <> '' then
        Buffer.Add(Param);
    end;
    Result := Trim(StringReplace(Buffer.Text, sLineBreak, ' ', [rfReplaceAll]));
  finally
    Buffer.Free;
  end;
end;

begin
{$IFDEF DEBUG}
  WriteLn('*** START ***');
{$ENDIF}
  if not IsGetModuleVersionCommand then
  begin
    ShellCommandLine := GetCommandLine;
    if ShellCommandLine <> '' then
      with TDreamcastSoftwareDevelopmentKitRunner.Create do
        try
          if CheckHealty then
            ExitCode := StartShellCommand(ShellCommandLine);
        finally
          Free;
        end;
  end
  else
    SaveModuleVersion;
end.

