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
  StrTools,
  FSTools,
  VerIntf,
  Runner;

var
  LogContext: TLogMessageContext;
  ShellCommandLine: string;

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
    Sep := EmptyStr;

    for i := 1 to ParamCount do
    begin
      Param := Trim(ParamStr(i));
      if not IsEmpty(Param) then
      begin
        if FileExists(Param) or DirectoryExists(Param) then
          Param := SystemToUnixPath(Param);
        Buffer.Append(Sep + Param);
      end;
      Sep := WhiteSpaceStr;
    end;

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
      LogMessage(LogContext, Format('ShellCommandLine: [%s]', [ShellCommandLine]));

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

