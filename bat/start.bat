cd %~dp0..

start %~dp0..\hive\lua %~dp0..\hive\main.lua %~dp0..\etc\master.conf
start %~dp0..\hive\lua %~dp0..\hive\main.lua %~dp0..\etc\login.conf
start %~dp0..\hive\lua %~dp0..\hive\main.lua %~dp0..\etc\gate.conf
start %~dp0..\hive\lua %~dp0..\hive\main.lua %~dp0..\etc\game1.conf
start %~dp0..\hive\lua %~dp0..\hive\main.lua %~dp0..\etc\game2.conf
timeout /nobreak /t 3
start %~dp0..\hive\lua %~dp0..\hive\main.lua %~dp0..\etc\client.conf