unit main;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
	Buttons, Menus, CheckBoxThemed, PythonEngine, PythonGUIInputOutput, BGRABitmap,
	BitmapToPython, PythonModel, VarPyth;

const
    TargetImageWidth = 28;
    TargetImageHeight = 28;

type

	{ TFrmMain }

    TFrmMain = class(TForm)
		CbxInvert: TCheckBoxThemed;
		DlgOpen: TOpenDialog;
		ImsIcons: TImageList;
		LblResult: TLabel;
		PbxMain: TPaintBox;
		PyeMain: TPythonEngine;
		SpbRefresh: TSpeedButton;
		SpbOpen: TSpeedButton;
		procedure FormCreate(Sender: TObject);
        procedure PbxMainMouseDown(Sender: TObject; Button: TMouseButton;
			Shift: TShiftState; X, Y: Integer);
		procedure PbxMainMouseMove(Sender: TObject; Shift: TShiftState; X,
			Y: Integer);
		procedure PbxMainMouseUp(Sender: TObject; Button: TMouseButton;
			Shift: TShiftState; X, Y: Integer);
		procedure PbxMainPaint(Sender: TObject);
		procedure SpbOpenClick(Sender: TObject);
		procedure SpbRefreshClick(Sender: TObject);
    private
        FIsMouseHold: Boolean;
        FBuffer: TBitmap;
        FBigBuffer: TBGRABitmap;
        FBinWidth, FBinHeight: Integer;
        FBitmapShipper: TBitmapToPythonShipper;
        FDigitPredictor: TMnistModel;
        procedure ResetBuffer;
        procedure Spot(Const X, Y: Integer);
        procedure PredictImage;
        procedure ExecutePythonFile(constref ADir:String);
    public

    end;

var
    FrmMain: TFrmMain;

implementation

const
    CExternalPythonFileConfirmation =
        'If your model relies on any external code, it could not be used directly.' +
        'You have to import that external code first.' + LineEnding +
        'Does your model rely on external code?';

{$R *.lfm}

{ TFrmMain }

procedure TFrmMain.PbxMainMouseDown(Sender: TObject; Button: TMouseButton;
	Shift: TShiftState; X, Y: Integer);
begin
    if FIsMouseHold = False then
    begin
        FIsMouseHold := True;
        FBinWidth := PbxMain.Width div TargetImageWidth;
        FBinHeight := PbxMain.Height div TargetImageHeight;
        Spot(X, Y);
	end;
end;

procedure TFrmMain.PbxMainMouseMove(Sender: TObject; Shift: TShiftState; X,
	Y: Integer);
begin
    if FIsMouseHold then Spot(X, Y);
end;

procedure TFrmMain.PbxMainMouseUp(Sender: TObject; Button: TMouseButton;
	Shift: TShiftState; X, Y: Integer);
begin
    if FIsMouseHold then
    begin
        FIsMouseHold:=False;
        PredictImage;
	end;
end;

procedure TFrmMain.PbxMainPaint(Sender: TObject);
begin
    FBuffer.Canvas.CopyRect(FBuffer.Canvas.ClipRect, FBigBuffer.Canvas, FBigBuffer.Canvas.ClipRect);
    PbxMain.Canvas.CopyRect(PbxMain.Canvas.ClipRect, FBuffer.Canvas, FBuffer.Canvas.ClipRect);
end;

procedure TFrmMain.SpbOpenClick(Sender: TObject);
var FileDir: String;
    ExternalDir: String;
begin
    if DlgOpen.Execute then FileDir := DlgOpen.FileName;

    // Model specified
	if not FileDir.IsEmpty then
    begin
        // Load external code
        if MessageDlg(CExternalPythonFileConfirmation, mtConfirmation, [mbYes, mbNo], 0 ) = mrYes then
	    begin
		    if DlgOpen.Execute then ExternalDir := DlgOpen.FileName;
		end;

        // Execute Python code and
        Screen.Cursor := crHourGlass;
        try
		    if not ExternalDir.IsEmpty then ExecutePythonFile(ExternalDir);
	        FDigitPredictor.Load(FileDir);
        finally
    		Screen.Cursor := crDefault;
		end;
	end;
end;

procedure TFrmMain.SpbRefreshClick(Sender: TObject);
begin
    ResetBuffer;
    Self.PbxMainPaint(SpbRefresh);
end;

procedure TFrmMain.ResetBuffer;
begin
    FBigBuffer.Canvas.Brush.Color:=clWhite;
    FBigBuffer.Canvas.FillRect(FBigBuffer.Canvas.ClipRect);
end;

procedure TFrmMain.Spot(const X, Y: Integer);
begin
    FBigBuffer.CanvasBGRA.Brush.Color:=clBlack;
    FBigBuffer.CanvasBGRA.Ellipse(X-FBinWidth, Y-FBinHeight, X+FBinWidth, Y+FBinHeight);
    Self.PbxMainPaint(Self);
end;

procedure TFrmMain.PredictImage;
var NpImage: Variant;
begin
    NpImage := FBitmapShipper.Ship(FBuffer, CbxInvert.Checked);
    if FDigitPredictor.IsLoaded then
	    LblResult.Caption:=IntToStr(FDigitPredictor.Predict(NpImage));
end;

procedure TFrmMain.ExecutePythonFile(constref ADir: String);
var FileStream: TFileStream;
    Bytes: TBytes;
    Code: String;
begin
    FileStream:= TFileStream.Create(ADir, fmOpenRead or fmShareDenyWrite);
	try
	    if FileStream.Size>0 then
        begin
	        SetLength(Bytes, FileStream.Size);
	        FileStream.Read(Bytes[0], FileStream.Size);
	    end;
	    Code := TEncoding.ASCII.GetString(Bytes);
	finally
	    FileStream.Free;
	end;

    PyeMain.ExecString(Code);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
    // Init buffer
    FBuffer := TBitmap.Create;
    FBigBuffer := TBGRABitmap.Create;
    FBuffer.SetSize(TargetImageWidth, TargetImageHeight);
    FBigBuffer.SetSize(PbxMain.Width, PbxMain.Height);
    FBuffer.PixelFormat:= pf8bit;
    ResetBuffer;
    PbxMainPaint(Self);
    FIsMouseHold := False;
    // Init Python side
    // Remember 8087 Control Word setting is different between Pascal and Python
    MaskFPUExceptions(True);
    FBitmapShipper := TBitmapToPythonShipper.Create;
    FDigitPredictor := TMnistModel.Create;
end;



end.

