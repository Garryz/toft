for /f "delims=\" %%f in ('dir /b /a-d /o-d "%~dp0../proto/*.proto"') do (
    %~dp0../hive/luaclib/protoc.exe -o %~dp0../pb/%%~nf.pb %%~nf.proto -I %~dp0../proto/
)