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
  SysTools,
  FSTools,
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
{$IFDEF DEBUG}
    DebugLog('GetCommandLine: ' + IntToStr(ParamCount) + ' parameter(s)');
{$ENDIF}
    for i := 1 to ParamCount do
    begin
      Param := Trim(ParamStr(i));
      if not IsEmpty(Param) then
      begin
        if FileExists(Param) or DirectoryExists(Param) then
          Param := SystemToUnixPath(Param);
{$IFDEF DEBUG}
        DebugLog('  ' + Param);
{$ENDIF}
        Buffer.Add(Param);
      end;
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

  ExitCode := ERROR_SUCCESS;

  if IsGetModuleVersionCommand then
  begin
    SaveModuleVersion;
    Exit;
  end;

  ShellCommandLine := GetCommandLine;
{$IFDEF DEBUG}
  DebugLog('ShellCommandLine: [' + ShellCommandLine + ']');
{$ENDIF}

  if not IsEmpty(ShellCommandLine) then
    with TDreamcastSoftwareDevelopmentKitRunner.Create do
      try
        if CheckHealty then
          ExitCode := StartShellCommand(ShellCommandLine)
        else
          ExitCode := ERROR_ENVVAR_NOT_FOUND;
      finally
        Free;
      end;
end.

