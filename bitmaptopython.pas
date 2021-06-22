unit BitmapToPython;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Graphics, Variants, PythonEngine, VarPyth;

type

	{ TBitmapToPythonShipper }

    TBitmapToPythonShipper = class
    private
        FPillowImage: Variant;
        FNumpy: Variant;
        FPyIO: Variant;
        FTupleImageShape: Variant;
        function BitmapToVariant(constref ABmp : TBitmap): Variant;
    public
        constructor Create;
        destructor Destroy; override;
        function Ship(constref ABmp: TBitmap; const AInvert: Boolean = False): Variant;
    end;


implementation

{ TBitmapToPythonShipper }

function TBitmapToPythonShipper.BitmapToVariant(constref ABmp: TBitmap): Variant;
var
    Stream: TMemoryStream;
    Bytes: PPyObject;
begin
    Stream := TMemoryStream.Create;
    try
	    ABmp.SaveToStream(Stream);
	    Bytes := GetPythonEngine.PyBytes_FromStringAndSize(Stream.Memory, Stream.Size);
	    Result := VarPythonCreate(Bytes);
	    GetPythonEngine.Py_DECREF(Bytes);
	finally
      	FreeAndNil(Stream);
	end;
end;

constructor TBitmapToPythonShipper.Create;
var
	OldControlWord: Word;
begin
    FPillowImage := Import('PIL.Image');
    FPyIO := Import('io');
    FNumpy := Import('numpy');
    FTupleImageShape:=VarPythonCreate([1, 28, 28], stTuple);
end;

destructor TBitmapToPythonShipper.Destroy;
begin
    //FreeAndNil(FPillowImage);
    //FreeAndNil(FNumpy);
	inherited Destroy;
end;

function TBitmapToPythonShipper.Ship(constref ABmp: TBitmap; const AInvert: Boolean = False): Variant;
var Stream, Img: Variant;
begin
    Stream := FPyIO.BytesIO(BitmapToVariant(ABmp));
    Img := FPillowImage.open(Stream).convert(String('L'));
    Result := FNumpy.asarray(Img).reshape(FTupleImageShape);
    if AInvert then Result := FNumpy.subtract(255, Result);
end;

end.

