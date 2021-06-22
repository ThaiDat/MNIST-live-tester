unit PythonModel;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, VarPyth, PythonEngine;

type

	{ TMnistModel }

    TMnistModel = class
      private
        FPickle: Variant;
        FModel: Variant;
        FIsLoaded: Boolean;
      public
        constructor Create;
        destructor Destroy; override;
        property IsLoaded: Boolean read FIsLoaded;
        procedure Load(constref ADir: String);
        function Predict(ANpImage: Variant): Integer;
	end;

implementation

{ TMnistModel }

constructor TMnistModel.Create;
begin
    FPickle := Import('pickle');
end;

destructor TMnistModel.Destroy;
begin
	inherited Destroy;
end;

procedure TMnistModel.Load(constref ADir: String);
var FileStream: Variant;
begin
    try
    FileStream := BuiltinModule.open(Adir, 'rb');
    FModel := FPickle.load(FileStream);
    FIsLoaded:=True;
	finally
        FileStream.close();
	end;
end;

function TMnistModel.Predict(ANpImage: Variant): Integer;
begin
    if FIsLoaded then
       result := VarPythonToVariant(FModel.predict(ANpImage).item(0))
    else
       result := -1;
end;

end.

