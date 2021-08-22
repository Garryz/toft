mkdir %~dp0..\build

cmake --no-warn-unused-cli -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -H%~dp0..\hive -B%~dp0..\build -G "Visual Studio 16 2019" -T host=x64 -A x64

cmake --build %~dp0..\build --config Release --target ALL_BUILD --clean-first -j 14

pause