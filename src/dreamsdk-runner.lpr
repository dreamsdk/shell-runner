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
  LazFileUtils,
  SysTools,
  StrTools,
  FSTools,
  VerIntf,
  Runner;

var
  LogContext: TLogMessageContext;
  ShellCommandLine: string = '';
  RootSystemPath: string = '';

function GetRootSystemPath: string;
var
  ConfigurationFileName: TFileName;

begin
  if IsEmpty(RootSystemPath) then
  begin
    ConfigurationFileName := ChangeFileExt(ParamStr(0), '.cfg');
    if FileExists(ConfigurationFileName) then
      RootSystemPath := LoadFileToString(ConfigurationFileName);
  end;
  Result := RootSystemPath;
end;

function GetRootSystemCommand: string;
begin
  Result := EmptyStr;
  if not IsEmpty(GetRootSystemPath) then
    Result := GetRootSystemPath + '/'
      + ExtractFileNameWithoutExt(GetProgramName);
end;

function GetCommandLine: string;
var
  LogContext: TLogMessageContext;
  i: Integer;
  Buffer: TStringBuilder;
  Param, Sep: string;

begin
  LogContext := LogMessageEnter({$I %FILE%}, {$I %CURRENTROUTINE%});
  Buffer := TStringBuilder.Create;
  try
    LogMessage(LogContext, Format('Parsing %d parameter(s)', [ParamCount]));

    // Add system command first
    Sep := EmptyStr;
    Param := GetRootSystemCommand;
    if not IsEmpty(Param) then
    begin
      Buffer.Append(Param);
      Sep := WhiteSpaceStr;
    end;

    // Add all parameters after system command if any
    for i := 1 to ParamCount do
    begin
      Param := Trim(ParamStr(i));
      if not IsEmpty(Param) then
      begin
        Param := SystemToUnixPath(Param);
        Buffer.Append(Sep + Param);
      end;
      Sep := WhiteSpaceStr;
    end;

    // Return the result!
    Result := Buffer.ToString;
    LogMessage(LogContext, Format('Result="%s"', [Result]));
  finally
    Buffer.Free;
    LogMessageExit(LogContext);
  end;
end;

begin
  ExitCode := ERROR_SUCCESS;

  // Handle module version inquery from DreamSDK Manager
  if IsGetModuleVersionCommand then
  begin
    SaveModuleVersion;
    Exit;
  end;

  // Run the real code now
  LogContext := LogMessageEnter({$I %FILE%}, {$I %CURRENTROUTINE%});
  try

    try
      // Grab the command-line passed to DreamSDK Runner
      ShellCommandLine := GetCommandLine;
      LogMessage(LogContext, Format('ShellCommandLine [workdir: "%s"]: [%s]', [
        GetCurrentDir,
        ShellCommandLine
      ]));

      // Check if the command-line to execute in Bash is passed
      if IsEmpty(ShellCommandLine) then
      begin
        ExitCode := ERROR_INVALID_PARAMETER;
        Exit;
      end;

      // Will try to execute the command now!
      with TDreamcastSoftwareDevelopmentKitRunner.Create do
        try
          if CheckHealty then
          begin
            // We can execute, so do it!
            RootSystemPath := GetRootSystemPath;
            WorkingDirectory := GetCurrentDir;
            ExitCode := StartShellCommand(ShellCommandLine);
          end
          else
            // The installation have problems...
            ExitCode := ERROR_ENVVAR_NOT_FOUND;
        finally
          Free;
        end;

    except
      raise; // Oops...
    end;

  finally
    LogMessageExit(LogContext);
  end;
end.

