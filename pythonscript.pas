unit PythonScript;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils;

const
	//Patten for each new line: '    ' + LineEnding +

    ScriptModuleImport = 'from io import BytesIO' + LineEnding +
                         'from PIL import Image';
    ScriptPrintImg = 'def primg(im):' + LineEnding +
                     '    print(im)';

implementation

end.

