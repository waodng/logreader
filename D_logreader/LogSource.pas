unit LogSource;

interface

uses
  I_LogProvider, databaseConnection, p_structDefine, Types,
  System.Classes, System.SyncObjs, System.Contnrs, loglog, I_LogSource;

type
   TLogPicker = class(TThread)

   public
     function GetRawLogByLSN(LSN: Tlog_LSN; var OutBuffer: TMemory_data): Boolean;virtual;abstract;
   end;

type
  LS_STATUE = (tLS_unknown, tLS_NotConfig, tLS_NotConnectDB, tLs_noLogReader, tLS_running, tLS_stopped, tLS_suspension);

type
  TLogSource = class(TLogSourceBase)
  private
    FCfgFilePath:string;
    FRunCs: TCriticalSection;
    FmsgCs:TCriticalSection;
    procedure ClrLogSource;
    procedure ReSetLoger;
  public
    FFmsg: TStringList;
    FProcCurLSN: Tlog_LSN;  //当前处理的位置

    Fdbc: TdatabaseConnection;
    FLogPicker:TLogPicker;
    FisLocal:Boolean;
    FFFFIsDebug:Boolean;
    pageDatalist:TObjectList;
    MainMSGDISPLAY:TMsgCallBack;
    constructor Create;
    destructor Destroy; override;
    function GetVlf_SeqNo(SeqNo:DWORD): PVLF_Info;
    function GetRawLogByLSN(LSN: Tlog_LSN;var OutBuffer: TMemory_data): Boolean;
    function Create_picker(AutoRun:Boolean):Boolean;
    procedure Stop_picker;
    function status:LS_STATUE;

    function loadFromFile_bin(aPath: string):Boolean;
    function saveToFile_bin(aPath: string = ''):Boolean;

    function loadFromFile_Xml(aPath: string):Boolean;
    function saveToFile_Xml(aPath: string = ''):Boolean;

    /// <summary>
    /// 从数据库对比字典差异
    /// </summary>
    /// <returns></returns>
    function CompareDict:string;
    procedure AddFmsg(aMsg: string; level: Integer);

    /// <summary>
    /// 监测数据库状态，如果在线则连接，如果不在线，等待上线后连接。
    /// </summary>
    procedure CreateAutoStartTimer;
  end;

  TLogSourceList = class(TObject)
  private
    ObjList:TList;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(Item: TLogSource): Integer;
    function Get(Index: Integer): TLogSource;
    function Count: Integer;
    procedure Delete(Index: Integer);
    function Exists(Item: TLogSource):Boolean;
  end;


function getLogReader(Fdbc: TdatabaseConnection):TClass;

var
  LogSourceList:TLogSourceList;

implementation

uses
  MakCommonfuncs, Windows, SysUtils, Xml.XMLDoc, Xml.XMLIntf,
  Sql2014LogReader;


function getLogReader(Fdbc: TdatabaseConnection):TClass;
begin
  Result := nil;
  if Fdbc.CheckIsLocalHost then
  begin
    if (Fdbc.dbVer_Major > 10) and (Fdbc.dbVer_Major <= 12) then
    begin
      //2008之后的版本都用这个读取方式
      Result := TSql2014LogPicker;
    end;
  end;
end;
{ TLogSource }

procedure TLogSource.AddFmsg(aMsg: string; level: Integer);
begin
  FmsgCs.Enter;
  try
    FFmsg.Add(FormatDateTime('yyyy-MM-dd HH:nn:ss.zzz', Now) + IntToStr(level) + ' >> ' + aMsg);
    if FFmsg.Count >= 100 then
    begin
      FFmsg.Delete(0);
    end;
  finally
    FmsgCs.Leave
  end;
  if Assigned(MainMSGDISPLAY) then
    MainMSGDISPLAY(aMsg, level);
end;

procedure TLogSource.ClrLogSource;
begin
  Stop_picker;
  if Fdbc <> nil then
    FreeAndNil(Fdbc);
end;

function TLogSource.CompareDict: string;
begin
  Result := Fdbc.CompareDict;
end;

constructor TLogSource.Create;
begin
  FmsgCs:=TCriticalSection.Create;
  MainMSGDISPLAY := nil;
  inherited;
  FLoger := DefLoger;
  FProcCurLSN.LSN_1 := 0;
  FProcCurLSN.LSN_2 := 0;
  FProcCurLSN.LSN_3 := 0;
  FisLocal := True;
  Fdbc := nil;
  FLogPicker := nil;
  FRunCs:=TCriticalSection.Create;
  FFFFIsDebug := False;
  pageDatalist := nil;

  FFmsg := TStringList.Create;
end;

procedure TLogSource.CreateAutoStartTimer;
begin
  //TODO:测试数据库连接状态。启动前，应该先监测数据库状态。
  if Fdbc<>nil then
  begin


  end;
end;

function TLogSource.Create_picker(AutoRun:Boolean): Boolean;
var
  logreaderClass:TClass;
begin
  Result := False;
  FRunCs.Enter;
  try
    if FLogPicker = nil then
    begin
      logreaderClass := getLogReader(Fdbc);
      if logreaderClass<>nil then
      begin
        //2008之后的版本都用这个读取方式
        FLogPicker := TSql2014LogPicker.Create(AutoRun, Self);
        Result := True;
      end;
    end else begin
      FLogPicker.Start;
    end;
  finally
    FRunCs.Leave;
  end;
end;

destructor TLogSource.Destroy;
begin
  ClrLogSource;
  FRunCs.Free;
  pageDatalist.Free;
  if FLoger = DefLoger then
  begin
    Loger.removeCallBack(Self, AddFmsg);
  end else begin
    FLoger.Free;
  end;
  FFmsg.Free;
  FmsgCs.Free;
  inherited;
end;

function TLogSource.GetVlf_SeqNo(SeqNo:DWORD): PVLF_Info;
var
  I: Integer;
begin
  if Length(Fdbc.FVLF_List) = 0 then
    Fdbc.getDb_VLFs;

  Result := nil;
  for I := 0 to Length(Fdbc.FVLF_List) - 1 do
  begin
    if Fdbc.FVLF_List[I].SeqNo = SeqNo then
    begin
      new(Result);
      Result^ := Fdbc.FVLF_List[I];
      Break;
    end;
  end;
end;

function TLogSource.GetRawLogByLSN(LSN: Tlog_LSN;var OutBuffer: TMemory_data): Boolean;
begin
  if FLogPicker=nil then
    Create_picker(False);
  Result := FLogPicker.GetRawLogByLSN(LSN, OutBuffer);
end;

function TLogSource.status: LS_STATUE;
begin
  if Fdbc = nil then
  begin
    Result := tLS_NotConfig;
  end else if FLogPicker = nil then
  begin
    Result := tLS_stopped;
  end else
  begin
    Result := tLS_running;
  end;
end;

procedure TLogSource.ReSetLoger;
var
  newLog:String;
begin
  if Fdbc <> nil then
  begin
    if FLoger = DefLoger then
    begin
      Loger.removeCallBack(Self, AddFmsg);
    end else begin
      FLoger.Free;
    end;
    newLog := Fdbc.dbName + '_' + Fdbc.getCfgUid;
    Loger.Add('Log redirect ==> ' + newLog);
    FLoger := TeventRecorder.Create(newLog);
    Loger.registerCallBack(Self, AddFmsg);
  end;
end;

procedure TLogSource.Stop_picker;
begin
  if FLogPicker <> nil then
  begin
    FLogPicker.Terminate;
    FLogPicker.WaitFor;
    FLogPicker.Free;
    FLogPicker := nil;
  end;
end;

function TLogSource.loadFromFile_bin(aPath: string):Boolean;
var
  mmo: TMemoryStream;
  Rter: TReader;
  tmpStr: string;
begin
  Result := False;
  ClrLogSource;

  mmo := TMemoryStream.Create;
  try
    try
      mmo.LoadFromFile(aPath);
      Rter := TReader.Create(mmo, 1);
      try
        if Rter.ReadInteger = $FB then
        begin
          tmpStr := Rter.ReadStr;
          if tmpStr = 'TDbDict v 1.0' then
          begin
            Fdbc := TdatabaseConnection.create(Self);
            Fdbc.Host := Rter.ReadString;
            Fdbc.user := Rter.ReadString;
            Fdbc.PassWd := Rter.ReadString;
            Fdbc.dbName := Rter.ReadString;
            Fdbc.dbID :=  Rter.ReadInteger;
            Fdbc.dbVer_Major :=  Rter.ReadInteger;
            Fdbc.dbVer_Minor :=  Rter.ReadInteger;
            Fdbc.dbVer_BuildNumber :=  Rter.ReadInteger;
            FProcCurLSN.LSN_1 := Rter.ReadInteger;
            FProcCurLSN.LSN_2 := Rter.ReadInteger;
            FProcCurLSN.LSN_3 := Rter.ReadInteger;
            Fdbc.dict.Deserialize(mmo);
            //init;
            Result := True;

            FCfgFilePath := aPath;
          end;
        end;
      finally
        Rter.Free;
      end;
    except
      on EE:Exception do
      begin
        Loger.Add('配置文件读取失败:'+aPath);
      end;
    end;
  finally
    mmo.Free;
  end;
end;

function TLogSource.loadFromFile_Xml(aPath: string): Boolean;
begin

end;

function TLogSource.saveToFile_bin(aPath: string):Boolean;
var
  wter: TWriter;
  mmo: TMemoryStream;
  dictBin: TMemoryStream;
  pathName:string;
begin
  Result := False;
  if aPath = '' then
    aPath := FCfgFilePath;

  if aPath <> '' then
  begin
    FCfgFilePath := aPath;

    Result := False;
    mmo := TMemoryStream.Create;
    try
      wter := TWriter.Create(mmo, 1);
      wter.WriteInteger($FB);
      wter.WriteStr('TDbDict v 1.0');
      //连接信息
      wter.WriteString(Fdbc.Host);
      wter.WriteString(Fdbc.user);
      wter.WriteString(Fdbc.PassWd);
      wter.WriteString(Fdbc.dbName);
      wter.WriteInteger(Fdbc.dbID);
      wter.WriteInteger(Fdbc.dbVer_Major);
      wter.WriteInteger(Fdbc.dbVer_Minor);
      wter.WriteInteger(Fdbc.dbVer_BuildNumber);
      wter.WriteInteger(FProcCurLSN.LSN_1);
      wter.WriteInteger(FProcCurLSN.LSN_2);
      wter.WriteInteger(FProcCurLSN.LSN_3);
      //表结构
      dictBin := Fdbc.dict.Serialize;
      dictBin.seek(0, 0);
      wter.Write(dictBin.Memory^, dictBin.Size);
      dictBin.Free;
      //
      wter.FlushBuffer;
      wter.Free;

      pathName := ExtractFilePath(aPath);
      if not DirectoryExists(pathName) then
      begin
        Loger.Add('目录创建:' + BoolToStr(ForceDirectories(pathName), true) + ':' + pathName);
      end;

      try
        mmo.SaveToFile(aPath);
        Result := True;
      except
        on ee:Exception do
        begin
          Loger.Add('LogSource.saveToFile 配置保存失败！' + ee.message);
        end;
      end;
    finally
      mmo.Free;
    end;
  end;
end;

function TLogSource.saveToFile_Xml(aPath: string): Boolean;
var
  xmlDoc:IXMLDocument;
  RootNode,xmlNode:IXMLNode;
  pathName:string;
begin
  Result := False;
  if aPath = '' then
    aPath := FCfgFilePath;
  if aPath <> '' then
  begin
    xmlDoc := TXMLDocument.Create(nil);
    xmlDoc.Active := True;
    RootNode := xmlDoc.AddChild('LogSource');
    RootNode.Attributes['Cdate'] := FormatDateTime('yyyy-MM-dd HH:nn:ss.zzz', Now);
    RootNode.AddChild('LSN').Text := LSN2Str(FProcCurLSN);

    xmlNode := RootNode.AddChild('DBC');
    xmlNode.Attributes['Host'] := Fdbc.Host;
    xmlNode.Attributes['user'] := Fdbc.user;
    xmlNode.Attributes['PassWd'] := Fdbc.PassWd;
    xmlNode.Attributes['dbName'] := Fdbc.dbName;
    xmlNode.Attributes['dbID'] := Fdbc.dbID;
    xmlNode.Attributes['dbV1'] := Fdbc.dbVer_Major;
    xmlNode.Attributes['dbV2'] := Fdbc.dbVer_Minor;
    xmlNode.Attributes['dbV3'] := Fdbc.dbVer_BuildNumber;
    xmlNode := RootNode.AddChild('tables');
    Fdbc.dict.toXml(xmlNode);

    pathName := ExtractFilePath(aPath);
    if not DirectoryExists(pathName) then
    begin
      Loger.Add('目录创建:' + BoolToStr(ForceDirectories(pathName), true) + ':' + pathName);
    end;
    try
      xmlDoc.SaveToFile(aPath);
      Result := True;
    except
      on ee: Exception do
      begin
        Loger.Add('LogSource.saveToFile 配置保存失败！' + ee.message);
      end;
    end;
  end;
end;

{ TLogSourceList }

function TLogSourceList.Exists(Item: TLogSource): Boolean;
var
  I:Integer;
begin
  for I := 0 to ObjList.Count - 1 do
  begin
    if (Get(I).Fdbc.Host = Item.Fdbc.Host) and
       (Get(I).Fdbc.dbName = Item.Fdbc.dbName) then
    begin
      Result := True;
      Exit;
    end;
  end;
  Result := False;
end;

function TLogSourceList.Add(Item: TLogSource): Integer;
begin
  if not Exists(Item) then
  begin
    Result := ObjList.Add(Item);
  end else
    Result := -1;
end;

function TLogSourceList.Count: Integer;
begin
  Result := ObjList.Count;
end;

constructor TLogSourceList.Create;
begin
  ObjList := TList.Create;
end;

procedure TLogSourceList.Delete(Index: Integer);
begin
  ObjList.Delete(Index);
end;

destructor TLogSourceList.Destroy;
var
  I: Integer;
begin
  for I := 0 to ObjList.Count - 1 do
  begin
    TLogSource(ObjList[i]).free;
  end;
  ObjList.Free;
  inherited;
end;


function TLogSourceList.Get(Index: Integer): TLogSource;
begin
  Result := ObjList[Index];
end;

initialization
  LogSourceList := TLogSourceList.Create;

finalization
  LogSourceList.Free;

end.

