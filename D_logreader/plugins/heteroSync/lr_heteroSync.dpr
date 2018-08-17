//library lr_heteroSync;
program lr_heteroSync;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  System.SysUtils,
  System.Classes,
  Vcl.Forms,
  p_main in 'p_main.pas' {frm_main},
  Log4D in '..\..\..\Common\Log4D.pas',
  loglog in '..\..\..\Common\loglog.pas',
  p_impl in 'p_impl.pas' {frm_impl},
  dbcfg in 'dbcfg.pas' {frm_dbcfg};

const
  STATUS_SUCCESS = $00000000;   //成功

const
  CurrentPluginVersion = 100;


/// <summary>
/// 插件信息
/// </summary>
/// <param name="shortname">输出插件名称</param>
/// <returns>当前插件版本</returns>
function _Lr_PluginInfo(var shortname: PChar): integer; stdcall;
begin
  shortname := 'lr_heteroSync';
  Result := CurrentPluginVersion;
end;

/// <summary>
/// 初始化插件调用
/// </summary>
/// <param name="engineVersion">调用系统版本</param>
/// <returns>状态标识</returns>
function _Lr_PluginInit(engineVersion: Integer): integer; stdcall;
begin
  Result := STATUS_SUCCESS;
end;

/// <summary>
/// 释放插件
/// </summary>
/// <returns>状态标识</returns>
function _Lr_PluginUnInit(): integer; stdcall;
begin
  Result := STATUS_SUCCESS;
end;

/// <summary>
/// 获取插件中单独定义的错误
/// </summary>
/// <param name="engineVersion">状态标识</param>
/// <returns>状态标识的描述信息</returns>
function _Lr_PluginGetErrMsg(StatusCode: Cardinal): PChar; stdcall;
begin
  if StatusCode = STATUS_SUCCESS then
  begin
    Result := '成功'
  end
  else
  begin
    Result := '未定义的错误！！'
  end;
end;

/// <summary>
/// Sql语句
/// </summary>
/// <param name="Sql"></param>
/// <returns></returns>
function _Lr_PluginRegXML(Xml: PChar): integer; stdcall;
begin

  Result := STATUS_SUCCESS;
end;

function _Lr_PluginMenu(var Xml: PChar): integer; stdcall;
begin
  Xml := '<root><item caption="插件"><item caption="异构同步"><item caption="数据库设置" actionid="1"></item></item></item></root>';
  Result := STATUS_SUCCESS;
end;

procedure _Lr_PluginMenuAction(actionId: PChar); stdcall;
begin
  if actionId = '1' then
  begin

  end;
end;

exports
  _Lr_PluginInfo,
  _Lr_PluginInit,
  _Lr_PluginUnInit,
  _Lr_PluginGetErrMsg,
  _Lr_PluginRegXML,
  _Lr_PluginMenuAction,
  _Lr_PluginMenu;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(Tfrm_dbcfg, frm_dbcfg);
  Application.CreateForm(Tfrm_main, frm_main);
  Application.CreateForm(Tfrm_impl, frm_impl);

  Application.Run;
end.
