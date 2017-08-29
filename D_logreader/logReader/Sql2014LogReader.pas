unit Sql2014LogReader;

interface

uses
  I_LogProvider, I_logReader, p_structDefine, Types, databaseConnection,
  LogSource, Classes, LogtransPkg;

type
  TSql2014LogReader = class(TlogReader)
  private
    FLogSource: TLogSource;
    FdataProvider: array[0..256] of TLogProvider;     //���ֻ����256��������־�ļ�
  public
    constructor Create(LogSource: TLogSource);
    destructor Destroy; override;
    procedure listVlfs(fid: Byte); override;
    procedure listLogBlock(vlfs: PVLF_Info); override;
    function GetRawLogByLSN(LSN: Tlog_LSN; vlfs: PVLF_Info; var OutBuffer: TMemory_data): Boolean; override;
    procedure custRead(fileId: byte; posi, size: Int64; var OutBuffer: TMemory_data); override;
  end;

  TSql2014LogPicker = class(TLogPicker)
  private
    FLogReader: TSql2014LogReader;
    FLogSource: TLogSource;
    FBeginLsn:Tlog_LSN;
    FvlfHeader: PVLFHeader;
    FlogBlock: PlogBlock;
    Fvlf:PVLF_Info;
    pkgMgr: TTransPkgMgr;
  public
    constructor Create(LogSource: TLogSource; BeginLsn: Tlog_LSN);
    destructor Destroy; override;
    procedure Execute; override;
    procedure getTransBlock(rawlog: PRawLog_COMMIT_XACT);
  end;

implementation

uses
  Windows, SysUtils, Memory_Common, pluginlog, LocalDbLogProvider, OpCode;

{ TSql2014LogReader }

constructor TSql2014LogReader.Create(LogSource: TLogSource);
var
  I: Integer;
  logp: TLocalDbLogProvider;
begin
  FLogSource := LogSource;

  for I := 0 to Length(FLogSource.Fdbc.FlogFileList) - 1 do
  begin
    if LogSource.Fdbc.CheckIsLocalHost then
    begin
      logp := TLocalDbLogProvider.Create;
      logp.init(FLogSource.Fdbc.FlogFileList[I].filehandle);
      FdataProvider[FLogSource.Fdbc.FlogFileList[I].fileId] := logp;
    end
    else
    begin
      //TODO:֧��Զ������
      Loger.Add('Զ�����У�', log_error);
    end;

  end;
end;

procedure TSql2014LogReader.custRead(fileId: byte; posi, size: Int64; var OutBuffer: TMemory_data);
begin
  if size = -1 then
    size := FdataProvider[fileId].getFileSize;

  OutBuffer.data := AllocMem(size);
  OutBuffer.dataSize := size;
  FdataProvider[fileId].Seek(posi, soBeginning);
  if FdataProvider[fileId].Read(OutBuffer.data^, size) = 0 then
  begin
    Loger.Add('��ȡ�ļ�ʧ�ܣ�@��');
    FreeMem(OutBuffer.data);
    OutBuffer.data := nil;
    OutBuffer.dataSize := 0;
    Exit;
  end
  else
  begin

  end;
end;

destructor TSql2014LogReader.Destroy;
var
  I: Integer;
begin
  for I := 0 to Length(FdataProvider) - 1 do
  begin
    if FdataProvider[I] <> nil then
      FdataProvider[I].Free;
  end;
  inherited;
end;

function TSql2014LogReader.GetRawLogByLSN(LSN: Tlog_LSN; vlfs: PVLF_Info; var OutBuffer: TMemory_data): Boolean;
var
  pbb: PVLFHeader;
  abuf: PlogBlock;
  LogBlockPosi, RowPosi, RowLength: Integer;
  RowOffset, RowOffset2: Word;
begin
  Result := False;
  OutBuffer.data := nil;
  OutBuffer.dataSize := 0;
  if (LSN.LSN_1 = 0) or (LSN.LSN_2 = 0) or (LSN.LSN_3 = 0) then
  begin
    Loger.Add('invalid lsn [0]!%s', [LSN2Str(LSN)]);
    Exit;
  end;

  if (vlfs = nil) or (vlfs.SeqNo <> LSN.LSN_1) then
  begin
    Loger.Add('invalid lsn [1]!%s', [LSN2Str(LSN)]);
    Exit;
  end;
  FdataProvider[vlfs.fileId].Seek(vlfs.VLFOffset, soBeginning);
  New(pbb);
  new(abuf);
  try
    if (FdataProvider[vlfs.fileId].Read(pbb^, SizeOf(TVLFHeader)) = 0) then
    begin
      Loger.Add('invalid lsn [2] VLFOffset out of range !%s', [LSN2Str(LSN)]);
      Exit;
    end;
    if (pbb.VLFHeadFlag <> $AB) or (pbb.SeqNo <> LSN.LSN_1) then
    begin
      Loger.Add('invalid lsn [3] VLFOffset Error !%s', [LSN2Str(LSN)]);
      Exit;
    end;

    LogBlockPosi := $200;
    //���Ҵ�vlf�е�һ���飨��Ȼ�������Ͽ���һ����������$2000��λ�ã�
    while LogBlockPosi < vlfs.VLFSize do
    begin
      FdataProvider[vlfs.fileId].Seek(LogBlockPosi + vlfs.VLFOffset, soBeginning);
      if (FdataProvider[vlfs.fileId].Read(abuf^, SizeOf(TlogBlock)) = 0) then
      begin
        Loger.Add('read data Error...........');
        Exit;
      end;
      if abuf.flag <> 0 then
      begin
        if abuf.BeginLSN.LSN_1 <> vlfs.SeqNo then
        begin
          //�ߵ����˵����ǰvlf��ǰ�벿�ֱ�����־���ǣ������������ݣ�����ʹ�õ�vlf��
          Exit;
        end
        else
        begin
          if abuf.BeginLSN.LSN_2 = LSN.LSN_2 then
          begin
            //�ҵ���־��
            Break;
          end;
          LogBlockPosi := LogBlockPosi + abuf.Size;
        end;
      end
      else
      begin
        LogBlockPosi := LogBlockPosi + $200;
      end;
    end;
    if abuf.BeginLSN.LSN_2 = LSN.LSN_2 then
    begin
      LogBlockPosi := LogBlockPosi + vlfs.VLFOffset;
      if LSN.LSN_3 > abuf.OperationCount then
      begin
        //��ǰ����û�����id
        Loger.Add('invalid lsn [4] RowId no found !%s', [LSN2Str(LSN)]);
        Exit;
      end
      else if LSN.LSN_3 = abuf.OperationCount then
      begin
        //���һ��
        RowPosi := LogBlockPosi;
        LogBlockPosi := LogBlockPosi + abuf.endOfBlock - LSN.LSN_3 * 2;
        if not FdataProvider[vlfs.fileId].Read_Word(RowOffset, LogBlockPosi) then
        begin
          Loger.Add('invalid lsn [5] get RowOffset Fail!%s', [LSN2Str(LSN)]);
          Exit;
        end;
        RowPosi := RowPosi + RowOffset;
        RowLength := LogBlockPosi - RowPosi;
      end
      else
      begin
        RowPosi := LogBlockPosi;
        LogBlockPosi := LogBlockPosi + abuf.endOfBlock - LSN.LSN_3 * 2;
        if not FdataProvider[vlfs.fileId].Read_Word(RowOffset, LogBlockPosi) then
        begin
          Loger.Add('invalid lsn [6] get RowOffset Fail!%s', [LSN2Str(LSN)]);
          Exit;
        end;
        if not FdataProvider[vlfs.fileId].Read_Word(RowOffset2, LogBlockPosi + 1) then
        begin
          Loger.Add('invalid lsn [7] get RowOffset Fail!%s', [LSN2Str(LSN)]);
          Exit;
        end;
        RowPosi := RowPosi + RowOffset;
        RowLength := RowOffset - RowOffset2;
      end;

      OutBuffer.data := AllocMem(RowLength);
      FdataProvider[vlfs.fileId].Seek(RowPosi, soBeginning);
      if FdataProvider[vlfs.fileId].Read(OutBuffer.data^, RowLength) = 0 then
      begin
        Loger.Add('get Row log fail!%s', [LSN2Str(LSN)]);
        FreeMem(OutBuffer.data);
        OutBuffer.data := nil;
        Exit;
      end;
      OutBuffer.dataSize := RowLength;
    end;
  finally
    Dispose(abuf);
    Dispose(pbb);
  end;
end;

procedure TSql2014LogReader.listLogBlock(vlfs: PVLF_Info);
var
  abuf: PlogBlock;
  posi: Integer;
begin
  // ÿ�������0xFFFF  ��С0x0200
  new(abuf);
  posi := $200;
  while posi < vlfs.VLFSize do
  begin
    FdataProvider[vlfs.fileId].Seek(posi + vlfs.VLFOffset, soBeginning);
    if (FdataProvider[vlfs.fileId].Read(abuf^, SizeOf(TlogBlock)) = 0) then
    begin
      Loger.Add('read data Error...........');
      break;
    end;
    if abuf.flag <> 0 then
    begin
      if abuf.BeginLSN.LSN_1 <> vlfs.SeqNo then
      begin
        break;
      end
      else
      begin
        OutputDebugString(PChar(bytestostr(abuf, SizeOf(TlogBlock))));
        posi := posi + abuf.Size;
      end;
    end
    else
    begin
      posi := posi + $200;
    end;
  end;
  Dispose(abuf);
end;

procedure TSql2014LogReader.listVlfs(fid: Byte);
var
  pbb: PVLFHeader;
  iiiii: integer;
  ssIze: Integer;
begin
  iiiii := 0;
  FdataProvider[fid].Seek($2000, soBeginning);
  ssIze := SizeOf(TVLFHeader);
  New(pbb);
  repeat
    if (FdataProvider[fid].Read(pbb^, ssIze) = 0) then
      break;
    OutputDebugString(PChar(bytestostr(pbb, ssIze)));
    FdataProvider[fid].Seek(pbb^.CurrentBlockSize - ssIze, soCurrent);

    iiiii := iiiii + 1;

  until (pbb^.CurrentBlockSize = 0) or (iiiii > 200);

  Dispose(pbb);
end;

{ TSql2014LogPicker }

constructor TSql2014LogPicker.Create(LogSource: TLogSource; BeginLsn: Tlog_LSN);
begin
  inherited Create(True);
  FLogReader := LogSource.FLogReader as TSql2014LogReader;
  FLogSource := LogSource;
  FBeginLsn := BeginLsn;

  pkgMgr := TTransPkgMgr.Create;

  New(FvlfHeader);
  New(FlogBlock);
  New(Fvlf);
end;

destructor TSql2014LogPicker.Destroy;
begin
  Dispose(FvlfHeader);
  Dispose(FlogBlock);
  Dispose(Fvlf);

  pkgMgr.Free;
  Loger.Add('LogPicker.Destroy.....');
  inherited;
end;

procedure TSql2014LogPicker.Execute;
label
  ExitLabel;
var
  vlf: PVLF_Info;
  LogBlockPosi: Int64;
  RowLength, RowOffset: Integer;
  RowdataBuffer: Pointer;
  RowOffsetTable: array of Word;
  RIdx: Integer; //Ҫ��ȡ�ĵ�N��
  I: Integer;
  NowLsn: Tlog_LSN;
  RawData: TMemory_data;
begin
  if (FBeginLsn.LSN_1 = 0) or (FBeginLsn.LSN_2 = 0) or (FBeginLsn.LSN_3 = 0) then
  begin
    Loger.Add('LogPicker.Execute:invalid lsn [0]!%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
    Exit;
  end;
  vlf := FLogSource.GetVlf_LSN(FBeginLsn);
  if (vlf = nil) or (vlf.SeqNo <> FBeginLsn.LSN_1) then
  begin
    Loger.Add('LogPicker.Execute:lsn out of vlfs [1]!%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
    Exit;
  end;
  Fvlf^ := vlf^;
  if (FLogReader.FdataProvider[Fvlf.fileId].Read_Bytes(FvlfHeader^, Fvlf.VLFOffset, SizeOf(TVLFHeader)) <> SizeOf(TVLFHeader)) then
  begin
    Loger.Add('LogPicker.Execute:vlfHeader Read fail! no more data !%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
    Exit;
  end;
  if (FvlfHeader.VLFHeadFlag <> $AB) or (FvlfHeader.SeqNo <> FBeginLsn.LSN_1) then
  begin
    Loger.Add('LogPicker.Execute:vlfHeader check Error !%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
    Exit;
  end;
  LogBlockPosi := Fvlf.VLFOffset + $2000;
  //DONE: �ɴ�ֱ�Ӵ�$2000��ʼ��ȡ�ɣ��򵥿�� ,��Ȼò���з���
  while LogBlockPosi < Fvlf.VLFOffset + Fvlf.VLFSize do
  begin
    if (FLogReader.FdataProvider[Fvlf.fileId].Read_Bytes(FlogBlock^, LogBlockPosi, SizeOf(TlogBlock)) <> SizeOf(TlogBlock)) then
    begin
      Loger.Add('LogPicker.Execute:logBlock Read fail! no more data !%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
      Exit;
    end;
    if FlogBlock.flag <> 0 then
    begin
      if FlogBlock.BeginLSN.LSN_1 <> Fvlf.SeqNo then
      begin
        //�ߵ����˵����ǰvlf��ǰ�벿�ֱ�����־���ǣ������������ݣ�����ʹ�õ�vlf��
        Exit;
      end
      else
      begin
        if FlogBlock.BeginLSN.LSN_2 = FBeginLsn.LSN_2 then
        begin
          //�ҵ���־��
          Break;
        end;
        LogBlockPosi := LogBlockPosi + FlogBlock.Size;
      end;
    end
    else
    begin
      LogBlockPosi := LogBlockPosi + $200;
    end;
  end;
  if FlogBlock.BeginLSN.LSN_2 <> FBeginLsn.LSN_2 then
  begin
    Loger.Add('LogPicker.Execute:logBlock No found! vlf Eof!%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
    Exit;
  end;

  if FBeginLsn.LSN_3 > FlogBlock.OperationCount then
  begin
    //��ǰ����û�����id
    Loger.Add('LogPicker.Execute:LSN RowId no found !%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
    Exit;
  end;

  while not Terminated do
  begin
    while True do  //ѭ����
    begin
      SetLength(RowOffsetTable, FlogBlock.OperationCount);
      for I := 0 to FlogBlock.OperationCount - 1 do
      begin
        if not FLogReader.FdataProvider[Fvlf.fileId].Read_word(RowOffsetTable[I], LogBlockPosi + FlogBlock.endOfBlock - I * 2 - 2) then
        begin
          Loger.Add('LogPicker.Execute:get RowOffsetTable fail!%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
          SetLength(RowOffsetTable, 0);
          Exit;
        end;
      end;
      RIdx := FBeginLsn.LSN_3;
      while RIdx <= FlogBlock.OperationCount do  //ѭ����
      begin
        //TODO 1: �������������RIdx����id��������Ǵ�1��ʼ�ľ͹Ҳ���
        if FlogBlock.BeginLSN.LSN_3 <> 1 then
        begin
          Loger.Add('LogPicker.Execute:FlogBlock is not begin from 1!%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
        end;

        if RIdx = FlogBlock.OperationCount then
        begin
          //���һ��
          RowOffset := LogBlockPosi + RowOffsetTable[RIdx - 1];
          RowLength := LogBlockPosi + (FlogBlock.endOfBlock - FlogBlock.OperationCount * 2) - RowOffset;
        end
        else
        begin
          RowOffset := LogBlockPosi + RowOffsetTable[RIdx - 1];
          RowLength := RowOffsetTable[RIdx] - RowOffsetTable[RIdx - 1];
        end;
        RowdataBuffer := AllocMem(RowLength);
        if FLogReader.FdataProvider[Fvlf.fileId].Read_bytes(RowdataBuffer^, RowOffset, RowLength) <> RowLength then
        begin
          Loger.Add('LogPicker.Execute:get Row log fail!%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
          FreeMem(RowdataBuffer);
          Exit;
        end;
        //����ɹ�����
        NowLsn.LSN_1 := FlogBlock.BeginLSN.LSN_1;
        NowLsn.LSN_2 := FlogBlock.BeginLSN.LSN_2;
        NowLsn.LSN_3 := RIdx;
        RawData.data := RowdataBuffer;
        RawData.dataSize := RowLength;

        if pkgMgr.addRawLog(NowLsn, RawData, False) = Pkg_Err_NoBegin then
        begin
          //TODO 5:����������Ҫ�������� LOP_COMMIT_XACT ץȡ��������
          getTransBlock(RowdataBuffer);
          FreeMem(RowdataBuffer);
        end;
        //��һ��
        RIdx := RIdx + 1;
        FBeginLsn.LSN_3 := RIdx;

        if Terminated then
        begin
          //��Ӧ Terminated
          goto ExitLabel;
        end;
      end;
      //һ����������� ������һ����
      LogBlockPosi := LogBlockPosi + FlogBlock.Size;
      if (LogBlockPosi + SizeOf(TlogBlock)) > (Fvlf.VLFOffset + Fvlf.VLFSize) then
      begin
        //vlf�Ѷ���
        break;
      end;
      while True do
      begin
        FLogReader.FdataProvider[Fvlf.fileId].flush();
        if (FLogReader.FdataProvider[Fvlf.fileId].Read_Bytes(FlogBlock^, LogBlockPosi, SizeOf(TlogBlock)) <> SizeOf(TlogBlock)) then
        begin
          Loger.Add('LogPicker.Execute:Next logBlock Read fail! no more data !%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
          Exit;
        end;
        if (FlogBlock.flag <> 0) and (FlogBlock.Size <> 0) then
        begin
          Break
        end;
        //�������黹û�б���ʼ�����͵�10s�ڶ�ȡһ��. <<<����ÿ����Ӧһ�� Terminated>>>
        for I := 0 to 10 - 1 do
        begin
          Sleep(1000);
          if Terminated then
          begin
            //��Ӧ Terminated
            goto ExitLabel;
          end;
        end;
      end;
      FBeginLsn.LSN_2 := FlogBlock.BeginLSN.LSN_2;
      FBeginLsn.LSN_3 := FlogBlock.BeginLSN.LSN_3;
    end;
    //��ǰvlf�Ѷ�ȡ�꣬������һ��vlf
    while True do
    begin
      FLogSource.Fdbc.getDb_VLFs();
      vlf := FLogSource.GetVlf_SeqNo(FBeginLsn.LSN_1 + 1);
      if vlf <> nil then
      begin
        Fvlf^ := vlf^;
        FLogReader.FdataProvider[Fvlf.fileId].flush();
        if (FLogReader.FdataProvider[Fvlf.fileId].Read_Bytes(FvlfHeader^, Fvlf.VLFOffset, SizeOf(TVLFHeader)) = SizeOf(TVLFHeader)) then
        begin
          if (FvlfHeader.VLFHeadFlag = $AB) and (FvlfHeader.SeqNo = FBeginLsn.LSN_1 + 1) then
          begin
            //ȷ���ҵ�Vlf
            Break;
          end;
        end;
      end;
      //���û���ҵ����͵�10s����  <<<����ÿ����Ӧһ�� Terminated>>>
      for I := 0 to 10 - 1 do
      begin
        Sleep(1000);
        if Terminated then
        begin
          //��Ӧ Terminated
          goto ExitLabel;
        end;
      end;
    end;
    FBeginLsn.LSN_1 := FBeginLsn.LSN_1 + 1;
    //�ҵ�Vlf�еĵ�һ����
    LogBlockPosi := Fvlf.VLFOffset + $2000;
    if (FLogReader.FdataProvider[Fvlf.fileId].Read_Bytes(FlogBlock^, LogBlockPosi, SizeOf(TlogBlock)) <> SizeOf(TlogBlock)) then
    begin
      Loger.Add('LogPicker.Execute:vlf first logBlock Read fail! no more data !%s', [LSN2Str(FBeginLsn)], LOG_ERROR);
      Exit;
    end;
    FBeginLsn.LSN_2 := FlogBlock.BeginLSN.LSN_2;
    FBeginLsn.LSN_3 := FlogBlock.BeginLSN.LSN_3;
  end;

ExitLabel:


end;

procedure TSql2014LogPicker.getTransBlock(rawlog: PRawLog_COMMIT_XACT);
label
  ExitLabel;
var
  vlf: PVLF_Info;
  Fpxvlf: TVLF_Info;
  LogBlockPosi: Int64;
  RowLength, RowOffset: Integer;
  RowdataBuffer: Pointer;
  RowOffsetTable: array of Word;
  RIdx: Integer; //Ҫ��ȡ�ĵ�N��
  I: Integer;
  NowLsn: Tlog_LSN;
  RawData: TMemory_data;
  vlfHeader: PVLFHeader;
  logBlock: PlogBlock;
  prl:PRawLog;
  OpCode:Integer;
begin
  New(vlfHeader);
  New(logBlock);

  if rawlog = nil then
  begin
    Loger.Add('LogPicker.getTransBlock:BeginLsn lsn invalid[0]! NULL', LOG_ERROR);
    Exit;
  end;
  if (rawlog.BeginLsn.LSN_1 = 0) or (rawlog.BeginLsn.LSN_2 = 0) or (rawlog.BeginLsn.LSN_3 = 0) then
  begin
    Loger.Add('LogPicker.getTransBlock:BeginLsn lsn invalid[0]!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
    Exit;
  end;
  vlf := FLogSource.GetVlf_LSN(rawlog.BeginLsn);
  if (vlf = nil) or (vlf.SeqNo <> rawlog.BeginLsn.LSN_1) then
  begin
    Loger.Add('LogPicker.getTransBlock:lsn out of vlfs [1]!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
    Exit;
  end;
  Fpxvlf := vlf^;
  if (FLogReader.FdataProvider[Fpxvlf.fileId].Read_Bytes(vlfHeader^, Fpxvlf.VLFOffset, SizeOf(TVLFHeader)) <> SizeOf(TVLFHeader)) then
  begin
    Loger.Add('LogPicker.getTransBlock:vlfHeader Read fail! no more data !%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
    Exit;
  end;
  if (vlfHeader.VLFHeadFlag <> $AB) or (vlfHeader.SeqNo <> rawlog.BeginLsn.LSN_1) then
  begin
    Loger.Add('LogPicker.getTransBlock:vlfHeader check Error !%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
    Exit;
  end;
  LogBlockPosi := Fpxvlf.VLFOffset + $2000;
  //DONE: �ɴ�ֱ�Ӵ�$2000��ʼ��ȡ�ɣ��򵥿�� ,��Ȼò���з���
  while LogBlockPosi < Fpxvlf.VLFOffset + Fpxvlf.VLFSize do
  begin
    if (FLogReader.FdataProvider[Fpxvlf.fileId].Read_Bytes(logBlock^, LogBlockPosi, SizeOf(TlogBlock)) <> SizeOf(TlogBlock)) then
    begin
      Loger.Add('LogPicker.getTransBlock:logBlock Read fail! no more data !%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
      Exit;
    end;
    if logBlock.flag <> 0 then
    begin
      if logBlock.BeginLSN.LSN_1 <> Fpxvlf.SeqNo then
      begin
        //�ߵ����˵����ǰvlf��ǰ�벿�ֱ�����־���ǣ������������ݣ�����ʹ�õ�vlf��
        Exit;
      end
      else
      begin
        if logBlock.BeginLSN.LSN_2 = rawlog.BeginLsn.LSN_2 then
        begin
          //�ҵ���־��
          Break;
        end;
        LogBlockPosi := LogBlockPosi + logBlock.Size;
      end;
    end
    else
    begin
      LogBlockPosi := LogBlockPosi + $200;
    end;
  end;
  if logBlock.BeginLSN.LSN_2 <> rawlog.BeginLsn.LSN_2 then
  begin
    Loger.Add('LogPicker.getTransBlock:logBlock No found! vlf Eof!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
    Exit;
  end;

  if rawlog.BeginLsn.LSN_3 > logBlock.OperationCount then
  begin
    //��ǰ����û�����id
    Loger.Add('LogPicker.getTransBlock:LSN RowId no found !%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
    Exit;
  end;

  while True do // ѭ��Vlfs ֱ�� LOP_COMMIT_XACT
  begin
    while True do  //ѭ����
    begin
      SetLength(RowOffsetTable, logBlock.OperationCount);
      for I := 0 to logBlock.OperationCount - 1 do
      begin
        if not FLogReader.FdataProvider[Fpxvlf.fileId].Read_word(RowOffsetTable[I], LogBlockPosi + logBlock.endOfBlock - I * 2 - 2) then
        begin
          Loger.Add('LogPicker.getTransBlock:get RowOffsetTable fail!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
          SetLength(RowOffsetTable, 0);
          Exit;
        end;
      end;
      RIdx := rawlog.BeginLsn.LSN_3;
      while RIdx <= logBlock.OperationCount do  //ѭ����
      begin
        //TODO 1: �������������RIdx����id��������Ǵ�1��ʼ�ľ͹Ҳ���
        if logBlock.BeginLSN.LSN_3 <> 1 then
        begin
          Loger.Add('LogPicker.getTransBlock:FlogBlock is not begin from 1!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
        end;

        if RIdx = logBlock.OperationCount then
        begin
          //���һ��
          RowOffset := LogBlockPosi + RowOffsetTable[RIdx - 1];
          RowLength := LogBlockPosi + (logBlock.endOfBlock - logBlock.OperationCount * 2) - RowOffset;
        end
        else
        begin
          RowOffset := LogBlockPosi + RowOffsetTable[RIdx - 1];
          RowLength := RowOffsetTable[RIdx] - RowOffsetTable[RIdx - 1];
        end;
        RowdataBuffer := AllocMem(RowLength);
        if FLogReader.FdataProvider[Fpxvlf.fileId].Read_bytes(RowdataBuffer^, RowOffset, RowLength) <> RowLength then
        begin
          Loger.Add('LogPicker.getTransBlock:get Row log fail!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
          FreeMem(RowdataBuffer);
          Exit;
        end;
        //����ɹ�����
        prl := RowdataBuffer;
        if (prl.TransID.Id1=rawlog.normalData.TransID.Id1) and (prl.TransID.Id2=rawlog.normalData.TransID.Id2) then
        begin
          //ֻ��������������
          NowLsn.LSN_1 := logBlock.BeginLSN.LSN_1;
          NowLsn.LSN_2 := logBlock.BeginLSN.LSN_2;
          NowLsn.LSN_3 := RIdx;
          RawData.data := RowdataBuffer;
          RawData.dataSize := RowLength;
          OpCode := prl.OpCode;
          if pkgMgr.addRawLog(NowLsn, RawData, True) = Pkg_Err_NoBegin then
          begin
            FreeMem(RowdataBuffer);
          end;
          if OpCode = LOP_COMMIT_XACT then
            goto ExitLabel;
        end else begin
          //���ǵ�ǰ��������ݣ�����ֱ���ͷŵ�
          FreeMem(RowdataBuffer);
        end;
        //��һ��
        RIdx := RIdx + 1;
        rawlog.BeginLsn.LSN_3 := RIdx;

        if Terminated then
        begin
          //��Ӧ Terminated
          goto ExitLabel;
        end;
      end;
      //һ����������� ������һ����
      LogBlockPosi := LogBlockPosi + logBlock.Size;
      if (LogBlockPosi + SizeOf(TlogBlock)) > (Fpxvlf.VLFOffset + Fpxvlf.VLFSize) then
      begin
        //vlf�Ѷ���
        break;
      end;

      if (FLogReader.FdataProvider[Fpxvlf.fileId].Read_Bytes(logBlock^, LogBlockPosi, SizeOf(TlogBlock)) <> SizeOf(TlogBlock)) then
      begin
        Loger.Add('LogPicker.getTransBlock:Next logBlock Read fail! no more data !%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
        Exit;
      end;
      if (logBlock.flag = 0) or (logBlock.Size = 0) then
      begin
        Loger.Add('LogPicker.getTransBlock:Next logBlock is null!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
        Exit;
      end;
      //�������黹û�б���ʼ�����͵�10s�ڶ�ȡһ��. <<<����ÿ����Ӧһ�� Terminated>>>

      rawlog.BeginLsn.LSN_2 := logBlock.BeginLSN.LSN_2;
      rawlog.BeginLsn.LSN_3 := logBlock.BeginLSN.LSN_3;
    end;
    //��ǰvlf�Ѷ�ȡ�꣬������һ��vlf
    vlf := FLogSource.GetVlf_SeqNo(rawlog.BeginLsn.LSN_1 + 1);
    if vlf <> nil then
    begin
      Fpxvlf := vlf^;
      if (FLogReader.FdataProvider[Fpxvlf.fileId].Read_Bytes(vlfHeader^, Fpxvlf.VLFOffset, SizeOf(TVLFHeader)) = SizeOf(TVLFHeader)) then
      begin
        if (vlfHeader.VLFHeadFlag <> $AB) or (vlfHeader.SeqNo <> rawlog.BeginLsn.LSN_1 + 1) then
        begin
          Loger.Add('LogPicker.getTransBlock:Cross vlf data read fail!%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
          Exit;
        end;
      end else begin
        Loger.Add('LogPicker.getTransBlock:Cross vlf data read fail! no more data !%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
        Exit;
      end;
    end;
   
    rawlog.BeginLsn.LSN_1 := rawlog.BeginLsn.LSN_1 + 1;
    //�ҵ�Vlf�еĵ�һ����
    LogBlockPosi := Fpxvlf.VLFOffset + $2000;
    if (FLogReader.FdataProvider[Fpxvlf.fileId].Read_Bytes(logBlock^, LogBlockPosi, SizeOf(TlogBlock)) <> SizeOf(TlogBlock)) then
    begin
      Loger.Add('LogPicker.getTransBlock:vlf first logBlock Read fail! no more data !%s', [LSN2Str(rawlog.BeginLsn)], LOG_ERROR);
      Exit;
    end;
    rawlog.BeginLsn.LSN_2 := logBlock.BeginLSN.LSN_2;
    rawlog.BeginLsn.LSN_3 := logBlock.BeginLSN.LSN_3;
  end;

ExitLabel:
  Dispose(vlfHeader);
  Dispose(logBlock);
end;


end.
