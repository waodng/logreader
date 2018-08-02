library lr_fullSync;

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
  Winapi.Windows,
  dbhelper in 'dbhelper.pas',
  Log4D in 'H:\Delphi\ͨ�õ��Զ��嵥Ԫ\Log4D.pas',
  loglog in 'H:\Delphi\ͨ�õ��Զ��嵥Ԫ\loglog.pas',
  Des in 'H:\Delphi\�㷨\Des.pas',
  cfgForm in 'cfgForm.pas' {frm_cfg};

const
  STATUS_SUCCESS = $00000000;   //�ɹ�

const
  CurrentPluginVersion = 100;


/// <summary>
/// �����Ϣ
/// </summary>
/// <param name="shortname">����������</param>
/// <returns>��ǰ����汾</returns>
function _Lr_PluginInfo(var shortname: PChar): integer; stdcall;
begin
  shortname := 'lr_fullSync';
  Result := CurrentPluginVersion;
end;

/// <summary>
/// ��ʼ���������
/// </summary>
/// <param name="engineVersion">����ϵͳ�汾</param>
/// <returns>״̬��ʶ</returns>
function _Lr_PluginInit(engineVersion: Integer): integer; stdcall;
begin
  Result := STATUS_SUCCESS;
end;

/// <summary>
/// �ͷŲ��
/// </summary>
/// <returns>״̬��ʶ</returns>
function _Lr_PluginUnInit(): integer; stdcall;
begin
  Result := STATUS_SUCCESS;
end;

/// <summary>
/// ��ȡ����е�������Ĵ���
/// </summary>
/// <param name="engineVersion">״̬��ʶ</param>
/// <returns>״̬��ʶ��������Ϣ</returns>
function _Lr_PluginGetErrMsg(StatusCode: Cardinal): PChar; stdcall;
begin
  if StatusCode = STATUS_SUCCESS then
  begin
    Result := '�ɹ�'
  end
  else
  begin
    Result := 'δ����Ĵ��󣡣�'
  end;
end;

/// <summary>
/// Sql���
/// </summary>
/// <param name="Sql"></param>
/// <returns></returns>
function _Lr_PluginRegSQL(Sql: PChar): integer; stdcall;
begin
  RunSql(Sql);
  Result := STATUS_SUCCESS;
end;

function _Lr_PluginMenu(var Xml: PChar): integer; stdcall;
begin
  Xml := '<root><item caption="���"><item caption="ȫ��ͬ��"><item caption="���ݿ�����" actionid="1"></item></item></item></root>';
  Result := STATUS_SUCCESS;
end;

procedure _Lr_PluginMenuAction(actionId: PChar); stdcall;
begin
  if actionId = '1' then
  begin
    frm_cfg:=Tfrm_cfg.Create(nil);
    frm_cfg.ShowModal;
    frm_cfg.Free;
  end;
end;

{$R *.res}

exports
  _Lr_PluginInfo,
  _Lr_PluginInit,
  _Lr_PluginUnInit,
  _Lr_PluginGetErrMsg,
  _Lr_PluginRegSQL,
  _Lr_PluginMenuAction,
  _Lr_PluginMenu;

begin



end.