#requires -Version 5.1
# Jobs Python BAT 隔离回归：只执行受审查的实际片段，构建和安装命令全部替换为假 CMD。
[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$script:assertions = 0
# 失败时保留所验证的输入、退出码或门禁说明。
function Assert-JobsBat($Condition, [string]$Label) {
    if (-not $Condition) { throw $Label }
    $script:assertions++
}
# 从实际源码提取指定子程序，不执行完整打包入口。
function Get-JobsBatLabel([string]$Text, [string]$Label) {
    $pattern = '(?ms)^:' + [regex]::Escape($Label) + '[^\r\n]*\r?\n.*?(?=^:[A-Za-z_][A-Za-z_0-9]*[^\r\n]*(?:\r?\n|$)|\z)'
    $match = [regex]::Match($Text, $pattern)
    Assert-JobsBat $match.Success ('缺少实际 BAT 子程序：' + $Label)
    return $match.Value
}
$paths = @{
    Remote = 'JobsPythonTools.py/JobsRemoteHost.py/【Windows】📦生成exe.bat'
    Traffic = 'JobsPythonTools.py/JobsAppTrafficMonitor.py/【Windows】📦生成exe.bat'
    Mock = 'JobsPythonTools.py/JobsMockTool.py/build_windows.bat'
    Reverse = 'JobsPythonTools.py/JobsReverseIPA.py/【Windows】📦生成exe.bat'
    MockDelegate = 'JobsPythonTools.py/JobsMockTool.py/【Windows】📦生成exe.bat'
    LanDelegate = 'JobsPythonTools.py/LANFileServer.py/【Windows】📦生成exe.bat'
    Lan = 'JobsPythonTools.py/LANFileServer.py/LANFileServer/启动LANFileServer.bat'
    Account = 'JobsPythonTools.py/JobsCodexAccountSwitcher.py/【Windows】📦生成exe.bat'
    Token = 'JobsPythonTools.py/JobsCodexTokenMonitor.py/【Windows】📦生成exe.bat'
    System = 'JobsPythonTools.py/JobsSystemMonitor.py/【Windows】📦生成exe.bat'
}
$sources = @{}
foreach ($key in $paths.Keys) {
    $path = Join-Path $repository $paths[$key]
    Assert-JobsBat (Test-Path -LiteralPath $path -PathType Leaf) ('缺少 BAT 源码：' + $paths[$key])
    $sources[$key] = [IO.File]::ReadAllText($path)
    Assert-JobsBat ($sources[$key].Contains("`r`n") -and $sources[$key] -notmatch '(?<!\r)\n|\r(?!\n)') ($key + ' BAT 必须使用 CRLF，避免中文子程序跳转解析损坏')
}
$initializers = New-Object 'Collections.Generic.List[object]'
foreach ($key in $paths.Keys) {
    $text = $sources[$key]
    $local = [regex]::Match($text, '(?m)^setlocal(?: EnableExtensions)? DisableDelayedExpansion\r?$')
    Assert-JobsBat ($local.Success -and $text -notmatch '(?im)^setlocal[^\r\n]*\bEnableDelayedExpansion\b') ($key + ' 必须局部关闭父 CMD 的延迟展开')
    $beforeLocal = @($text.Substring(0, $local.Index) -split '\r?\n' | Where-Object { $_ -notmatch '^(?:@echo off|rem(?: .*)?|chcp 65001 >nul)?$' })
    Assert-JobsBat ($beforeLocal.Count -eq 0) ($key + ' 必须在任何路径 / 参数展开前关闭延迟展开')
    $body = ''; $kind = 'directory'; $suffix = ''
    $directoryLine = [regex]::Match($text, '(?m)^set "SCRIPT_DIR=%~dp0"\r?$')
    if ($directoryLine.Success) {
        $body = $directoryLine.Value.TrimEnd("`r") + "`r`necho __JOBS_PATH__=%SCRIPT_DIR%`r`nexit /b 0`r`n"
    } elseif ($key -eq 'Mock') {
        $cd = [regex]::Match($text, '(?m)^cd /d "%~dp0"\r?$')
        $body = $cd.Value.TrimEnd("`r") + "`r`necho __JOBS_PATH__=%CD%\`r`nexit /b 0`r`n"
        Assert-JobsBat $cd.Success 'MockTool 只抽取实际安全 cd 片段'
    } elseif ($key -eq 'MockDelegate') {
        $call = [regex]::Match($text, '(?m)^call "%~dp0build_windows\.bat" %\*\r?$')
        $body = $call.Value.TrimEnd("`r") + "`r`nexit /b %ERRORLEVEL%`r`n"
        $kind = 'delegate'
        Assert-JobsBat $call.Success 'MockTool 外层只抽取实际委托调用'
    } else {
        $call = [regex]::Match($text, '(?m)^"%JOBS_[A-Z_]+_PYTHON%"[^\r\n]+')
        $scriptPath = [regex]::Match($call.Value, '"%~dp0([^"]+)"')
        Assert-JobsBat ($call.Success -and $scriptPath.Success) ($key + ' 只抽取实际带路径参数的构建器调用')
        $body = [regex]::Replace($call.Value, '^"[^"]+"', 'call "%JOBS_BAT_ARGUMENT_FAKE%"') + "`r`nexit /b %ERRORLEVEL%`r`n"
        $kind = 'arguments'; $suffix = $scriptPath.Groups[1].Value
    }
    Assert-JobsBat ($body -ne '') ($key + ' 安全初始化片段存在')
    $initializers.Add([pscustomobject]@{Name=$key;Local=$local.Value.TrimEnd("`r");Body=$body;Kind=$kind;Suffix=$suffix})
}
$remoteSet = [regex]::Match($sources.Remote, '(?m)^setlocal EnableExtensions [^\r\n]+').Value
$remoteDirectory = [regex]::Match($sources.Remote, '(?m)^set "SCRIPT_DIR=%~dp0"').Value
Assert-JobsBat ($remoteSet -eq 'setlocal EnableExtensions DisableDelayedExpansion') 'RemoteHost 必须关闭继承的延迟展开'
Assert-JobsBat ($remoteDirectory -ne '') 'RemoteHost 目录片段存在'
$remoteBlocks = @{}
$remoteDispatch = @{}
foreach ($mode in @('run-app', 'self-test')) {
    $label = 'run_app_mode'
    if ($mode -eq 'self-test') { $label = 'self_test_mode' }
    $pattern = '(?m)^if /I "%MODE%"=="' + [regex]::Escape($mode) + '" goto ' + $label + '\r?$'
    $dispatch = [regex]::Match($sources.Remote, $pattern)
    Assert-JobsBat $dispatch.Success ('缺少 RemoteHost 实际模式分派：' + $mode)
    $remoteDispatch[$mode] = $dispatch.Value.TrimEnd("`r")
    $block = Get-JobsBatLabel $sources.Remote $label
    Assert-JobsBat ($block -notmatch '!ERRORLEVEL!') ('RemoteHost 退出码仍依赖延迟展开：' + $mode)
    if ($mode -eq 'run-app') {
        Assert-JobsBat ([regex]::Matches($block, '(?m)^\s*"%PYTHON_BIN%"[^\r\n]*').Count -eq 1) 'run-app 只有一个待替换的业务调用'
        $block = [regex]::Replace($block, '(?m)^\s*"%PYTHON_BIN%"[^\r\n]*', '  call "%JOBS_BAT_FAKE%"')
    } else {
        Assert-JobsBat ([regex]::Matches($block, '(?m)^\s*call :run_self_test[^\r\n]*').Count -eq 1) 'self-test 只有一个待替换的业务调用'
        $block = [regex]::Replace($block, '(?m)^\s*call :run_self_test[^\r\n]*', '  call "%JOBS_BAT_FAKE%"')
    }
    $remoteBlocks[$mode] = $block
}
$venvMatch = [regex]::Match($sources.Traffic, '(?ms)^if not exist "%BUILD_VENV%\\Scripts\\python\.exe" \(\r?\n.*?^\)')
Assert-JobsBat $venvMatch.Success '缺少 AppTraffic 实际 venv 分支'
Assert-JobsBat ([regex]::Matches($venvMatch.Value, '(?m)^\s*call %PYTHON_LAUNCHER% -m venv[^\r\n]*').Count -eq 1) 'venv 分支只有一个待替换的环境创建调用'
$venvBlock = [regex]::Replace($venvMatch.Value, '(?m)^\s*call %PYTHON_LAUNCHER% -m venv[^\r\n]*', '  call "%JOBS_BAT_FAKE%" -m venv "%BUILD_VENV%"')
$notices = @{}
$noticeCalls = @{}
foreach ($key in @('Mock', 'Reverse')) {
    $notices[$key] = Get-JobsBatLabel $sources[$key] 'show_notice'
    $noticeCalls[$key] = [regex]::Match($sources[$key], '(?m)^call :show_notice[^\r\n]*').Value
    Assert-JobsBat ($noticeCalls[$key] -match '\|\| goto :error') ($key + ' 初始确认失败必须阻止主流程')
    Assert-JobsBat ($notices[$key].Contains('[Console]::In.ReadLine()')) ($key + ' 初始确认须区分空行和 EOF')
}
$cleanGatePattern = '(?m)^set "__clean_confirm="\r?\nset /p [^\r\n]+\r?\nif(?: /i)? not "%__clean_confirm%"=="YES" \(\r?\n(?:[ \t]+echo[^\r\n]*\r?\n)*[ \t]+exit /b 1\r?\n\)'
$cleanGateMatch = [regex]::Match($sources.Reverse, $cleanGatePattern)
Assert-JobsBat $cleanGateMatch.Success 'ReverseIPA 只抽取清理确认读取和条件门禁，不含清理命令'
$cleanGate = $cleanGateMatch.Value
Assert-JobsBat ($cleanGate -match '(?m)^if not "%__clean_confirm%"=="YES" \(\r?$') '清理门禁必须区分大小写，精确大写 YES 才放行'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    Write-Host ('PASS：' + $script:assertions + ' 项源码片段检查。')
    Write-Host 'SKIP：实际 CMD 片段、空行 / EOF 和退出码验证只在 Windows 执行。'
    return
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('JobsPythonBatTests-' + [guid]::NewGuid().ToString('N'))
Assert-JobsBat (-not $fixture.Contains('!')) 'TEMP 本身含 !，请使用普通 TEMP 隔离假命令。'
# 测试进程只执行生成的片段，输入可以是 EOF、空行或普通文本。
function Invoke-JobsBatFragment([string]$Name, [string]$Body, $InputLine, [int]$FakeExit = 0, [string]$Mode = '', [switch]$MockDelegate) {
    $work = Join-Path (Join-Path $fixture $Name) '中文! space [x]'
    [void][IO.Directory]::CreateDirectory($work)
    $path = Join-Path $work 'fragment.cmd'
    [IO.File]::WriteAllText($path, ($Body -replace '\r?\n', "`r`n"), (New-Object Text.UTF8Encoding($false)))
    if ($MockDelegate) {
        [IO.File]::WriteAllText((Join-Path $work 'build_windows.bat'), "@echo off`r`nsetlocal DisableDelayedExpansion`r`nchcp 65001 >nul`r`necho __JOBS_PATH__=%~dp0`r`nexit /b 0`r`n", [Text.Encoding]::ASCII)
    }
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $env:ComSpec
    $info.Arguments = '/d /v:on /c fragment.cmd'
    $info.WorkingDirectory = $work
    $info.UseShellExecute = $false
    # CMD 需要真实控制台设置 UTF-8 代码页；隐藏窗口保留控制台语义。
    $info.CreateNoWindow = $false
    $info.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
    $info.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
    $info.EnvironmentVariables['JOBS_BAT_FAKE'] = Join-Path $fixture 'fake.cmd'
    $info.EnvironmentVariables['JOBS_BAT_ARGUMENT_FAKE'] = Join-Path $fixture 'argument-fake.cmd'
    $info.EnvironmentVariables['JOBS_BAT_FAKE_EXIT'] = [string]$FakeExit
    $info.EnvironmentVariables['BUILD_VENV'] = Join-Path $work 'missing-venv'
    $info.EnvironmentVariables['MODE'] = $Mode
    foreach ($argumentVariable in @($info.EnvironmentVariables.Keys | Where-Object { $_ -match '^JOBS_.*_PYTHON_ARGS$' })) { $info.EnvironmentVariables.Remove($argumentVariable) }
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        if ($null -ne $InputLine) { $process.StandardInput.WriteLine($InputLine) }
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $finished = $process.WaitForExit(5000)
        if (-not $finished) { $process.Kill(); [void]$process.WaitForExit(1000) }
        $captured = [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdout, $stderr), 1000)
        Assert-JobsBat ($finished -and $captured) ('片段等待输入或超时：' + $Name)
        $outText = $stdout.Result; $errorText = $stderr.Result
        Write-Host ('片段：' + $Name + '；退出码=' + $process.ExitCode)
        if ($errorText) { Write-Host $errorText }
        Assert-JobsBat ([string]::IsNullOrWhiteSpace($errorText)) ('片段存在非预期 stderr，不能按退出码记通过：' + $Name)
        Assert-JobsBat (($outText + "`n" + $errorText) -notmatch 'is not recognized as an internal or external command|不是内部或外部命令') ('片段发生 CMD 命令解析错误：' + $Name)
        return [pscustomobject]@{Name=$Name;Code=$process.ExitCode;Stdout=$outText;Stderr=$errorText;ExpectedPath=($work+'\');WorkPath=$work}
    } finally { $process.Dispose() }
}
try {
    [void][IO.Directory]::CreateDirectory($fixture)
    [IO.File]::WriteAllText((Join-Path $fixture 'fake.cmd'), "@echo off`r`nexit /b %JOBS_BAT_FAKE_EXIT%`r`n", [Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $fixture 'argument-fake.cmd'), "@echo off`r`nsetlocal DisableDelayedExpansion`r`nchcp 65001 >nul`r`necho __JOBS_ARGUMENTS__=%*`r`nexit /b 0`r`n", [Text.Encoding]::ASCII)
    foreach ($initial in $initializers) {
        $body = "@echo off`r`nchcp 65001 >nul`r`n" + $initial.Local + "`r`n" + $initial.Body
        $result = Invoke-JobsBatFragment ('path-' + $initial.Name) $body $null -MockDelegate:($initial.Kind -eq 'delegate')
        $pathPreserved = $result.Stdout.Contains('__JOBS_PATH__=' + $result.ExpectedPath)
        if ($initial.Kind -eq 'arguments') { $pathPreserved = $result.Stdout.Contains('"' + (Join-Path $result.WorkPath $initial.Suffix) + '"') }
        Assert-JobsBat ($result.Code -eq 0 -and $pathPreserved) ($initial.Name + ' 实际初始化 / 委托片段未保留 ! / 中文 / 空格路径')
    }
    foreach ($mode in @('run-app', 'self-test')) {
        foreach ($code in @(0, 7)) {
            $body = "@echo off`r`n" + $remoteSet + "`r`n" + $remoteDispatch[$mode] + "`r`nexit /b 99`r`n" + $remoteBlocks[$mode] + "`r`n:prepare_python_environment`r`nexit /b 0`r`n"
            $result = Invoke-JobsBatFragment ('remote-' + $mode + '-' + $code) $body $null -FakeExit $code -Mode $mode
            Assert-JobsBat ($result.Code -eq $code) ('RemoteHost 实际分支退出码丢失：' + $mode + '，预期=' + $code)
        }
    }
    foreach ($code in @(0, 7)) {
        $body = "@echo off`r`nsetlocal DisableDelayedExpansion`r`ncmd /d /c exit 0`r`n" + $venvBlock + "`r`necho __JOBS_CONTINUED__`r`nexit /b 0`r`n:build_failed`r`nexit /b 7`r`n"
        $result = Invoke-JobsBatFragment ('venv-' + $code) $body $null -FakeExit $code
        Assert-JobsBat ($result.Code -eq $code) ('AppTraffic 实际 venv 片段未传播退出码 ' + $code)
        Assert-JobsBat ($result.Stdout.Contains('__JOBS_CONTINUED__') -eq ($code -eq 0)) 'venv 失败后仍进入后续阶段'
    }
    foreach ($key in @('Mock', 'Reverse')) {
        foreach ($inputCase in @(@{Name='eof';Value=$null;Code=1}, @{Name='enter';Value='';Code=0}, @{Name='text';Value='ordinary input';Code=0})) {
            $body = "@echo off`r`nsetlocal DisableDelayedExpansion`r`nchcp 65001 >nul`r`n" + $noticeCalls[$key] + "`r`necho __JOBS_CONTINUED__`r`nexit /b 0`r`n" + $notices[$key] + "`r`n:error`r`nexit /b 1`r`n"
            $result = Invoke-JobsBatFragment ($key + '-' + $inputCase.Name) $body $inputCase.Value
            Assert-JobsBat ($result.Code -eq $inputCase.Code) ($key + ' 初始确认输入结果错误：' + $inputCase.Name)
            Assert-JobsBat ($result.Stdout.Contains('__JOBS_CONTINUED__') -eq ($inputCase.Code -eq 0)) ($key + ' EOF 进入后续阶段或空行被误取消')
        }
    }
    foreach ($inputCase in @(@{Name='YES';Value='YES';Code=0}, @{Name='lowercase';Value='yes';Code=1}, @{Name='mixed';Value='Yes';Code=1}, @{Name='space';Value=' ';Code=1}, @{Name='enter';Value='';Code=1}, @{Name='eof';Value=$null;Code=1})) {
        $body = "@echo off`r`nsetlocal DisableDelayedExpansion`r`nchcp 65001 >nul`r`n" + $cleanGate + "`r`necho __JOBS_CLEAN_ALLOWED__`r`nexit /b 0`r`n"
        $result = Invoke-JobsBatFragment ('reverse-clean-' + $inputCase.Name) $body $inputCase.Value
        Assert-JobsBat ($result.Code -eq $inputCase.Code) ('清理确认退出码错误：' + $inputCase.Name)
        Assert-JobsBat ($result.Stdout.Contains('__JOBS_CLEAN_ALLOWED__') -eq ($inputCase.Code -eq 0)) ('清理确认放行范围错误：' + $inputCase.Name)
    }
    Write-Host ('PASS：' + $script:assertions + ' 项断言；仅实际 BAT 片段与假 CMD，没有安装或构建。')
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
