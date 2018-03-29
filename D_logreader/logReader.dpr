program logReader;

{$R 'res.res' 'res\res.rc'}

uses
  FastMM4 in 'H:\Delphi\FastMMnew\FastMM4.pas',
  FastMM4Messages in 'H:\Delphi\FastMMnew\FastMM4Messages.pas',
  Forms,
  p_main in 'p_main.pas' {Form1},
  I_logReader in 'logReader\I_logReader.pas',
  Sql2014LogReader in 'logReader\Sql2014LogReader.pas',
  RemoteDbLogProvider in 'LogProvider\RemoteDbLogProvider.pas',
  LdfLogProvider in 'LogProvider\LdfLogProvider.pas',
  I_LogProvider in 'LogProvider\I_LogProvider.pas',
  LogSource in 'LogSource.pas',
  p_structDefine in 'p_structDefine.pas',
  LocalDbLogProvider in 'LogProvider\LocalDbLogProvider.pas',
  pluginlog in 'H:\Delphi\通用的自定义单元\pluginlog.pas',
  MakCommonfuncs in 'H:\Delphi\通用的自定义单元\MakCommonfuncs.pas',
  Memory_Common in 'H:\Delphi\通用的自定义单元\Memory_Common.pas',
  databaseConnection in 'databaseConnection.pas',
  dbConnectionCfg in 'UI\dbConnectionCfg.pas' {frm_dbConnectionCfg},
  dbHelper in 'dbHelper.pas',
  comm_func in 'comm_func.pas',
  LogtransPkg in 'LogtransPkg.pas',
  OpCode in 'OpCode.pas',
  contextCode in 'contextCode.pas',
  Unit2 in 'tst\Unit2.pas' {Form2},
  plugins in 'plugins.pas',
  I_logAnalyzer in 'LogAnalyzer\I_logAnalyzer.pas',
  Sql2014logAnalyzer in 'LogAnalyzer\Sql2014logAnalyzer.pas',
  LogtransPkgMgr in 'LogtransPkgMgr.pas',
  hexValUtils in 'hexValUtils.pas',
  dbDict in 'dbDict.pas',
  BinDataUtils in 'BinDataUtils.pas',
  dbFieldTypes in 'dbFieldTypes.pas',
  SqlDDLs in 'LogAnalyzer\SqlDDLs.pas',
  Vcl.Dialogs,
  impConfig in 'impConfig.pas',
  ResHelper in 'res\ResHelper.pas',
  sqlextendedprocHelper in 'sqlextendedprocHelper.pas',
  winshellHelper in 'winshellHelper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if IsRunningAsAdmin then
  begin
    Application.CreateForm(TForm1, Form1);
    Application.CreateForm(TForm2, Form2);
    Application.Run;
  end else begin
    showmessage('必须“使用管理员身份”运行本程序');
  end;
end.
