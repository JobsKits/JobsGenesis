#requires -Version 5.1
# Jobs Windows 转发入口回归；假 CMD 验证路径，两个真实 -Check 入口只查询加载状态。
[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$roots = @(
    @{ Path = 'JobsCommand@Flutter/WindowsOS'; Count = 41 },
    @{ Path = 'JobsCommand@Gits/WindowsOS'; Count = 20 },
    @{ Path = 'JobsCommand@Others/WindowsOS'; Count = 17 },
    @{ Path = 'JobsSh.sh/WindowsOS'; Count = 15 },
    @{ Path = 'SourceTree.command/WindowsOS'; Count = 28 },
    @{ Path = 'OS@Extension/WindowsOS@Extension'; Count = 69 }
)
$excludedSegments = @('.git', 'node_modules', 'Pods', 'work', 'dist', 'build', 'DerivedData', '.dart_tool', 'vendor', 'third_party', 'ThirdParty')
$powershellPattern = '(?im)^(?:powershell\.exe|"%SystemRoot%\\System32\\WindowsPowerShell\\v1\.0\\powershell\.exe")(?=\s)'
$entries = New-Object 'Collections.Generic.List[object]'
$script:assertions = 0
# 任一策略或原生验证失败都保留具体路径。
function Assert-JobsLauncher($Condition, [string]$Label) {
    if (-not $Condition) { throw $Label }
    $script:assertions++
}
foreach ($root in $roots) {
    $directory = Join-Path $repository $root.Path
    Assert-JobsLauncher (Test-Path -LiteralPath $directory -PathType Container) ('缺少测试根目录：' + $root.Path)
    $launchers = @(Get-ChildItem -LiteralPath $directory -Recurse -File -Filter '*.cmd' | Where-Object {
        $segments = $_.FullName.Substring($directory.Length).TrimStart('\', '/') -split '[\\/]'
        @($segments | Where-Object { $_ -in $excludedSegments -or $_ -like 'ManualBy*Pods@Pods' }).Count -eq 0
    } | Sort-Object FullName)
    Assert-JobsLauncher ($launchers.Count -eq $root.Count) ('转发入口清单数量变化，请逐项审查：' + $root.Path)
    foreach ($launcher in $launchers) {
        Assert-JobsLauncher (($launcher.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('拒绝链接入口：' + $launcher.FullName)
        $text = [IO.File]::ReadAllText($launcher.FullName)
        $lines = $text -split '\r?\n'
        $disabled = @($lines | Where-Object { $_ -match '^setlocal DisableDelayedExpansion$' })
        Assert-JobsLauncher ($disabled.Count -eq 1 -and $text -notmatch '(?im)^setlocal.*EnableDelayedExpansion') ('必须局部关闭继承的延迟展开：' + $launcher.FullName)
        $disableIndex = [Array]::IndexOf($lines, $disabled[0])
        $beforeDisable = @($lines[0..($disableIndex - 1)] | Where-Object { $_ -notmatch '^(?:@echo off|rem(?: .*)?)?$' })
        Assert-JobsLauncher ($disableIndex -gt 0 -and $beforeDisable.Count -eq 0) ('必须在任何路径或参数展开前关闭延迟展开：' + $launcher.FullName)
        $isPowerShell = [regex]::IsMatch($text, $powershellPattern)
        $isLegacy = $text.Contains('rem Legacy entry delegates to the unified Flutter menu owner.')
        Assert-JobsLauncher ($isPowerShell -xor $isLegacy) ('出现未经审查的业务 CMD，请单独确认边界：' + $launcher.FullName)
        if ($isPowerShell) {
            Assert-JobsLauncher ([regex]::Matches($text, $powershellPattern).Count -eq 1) ('不是单次 PowerShell 转发：' + $launcher.FullName)
            Assert-JobsLauncher ($text -match '(?im)^.*powershell\.exe"?[^\r\n]* -ExecutionPolicy Bypass(?:\s|$)') ('缺少仅限本次 PowerShell 进程的执行策略参数：' + $launcher.FullName)
            $scriptMatch = [regex]::Match($text, '(?im)^.*powershell\.exe"?[^\r\n]* -File "([^"]+)"')
            Assert-JobsLauncher $scriptMatch.Success ('缺少明确的相对 PS1 路径：' + $launcher.FullName)
            $scriptPath = $scriptMatch.Groups[1].Value
            Assert-JobsLauncher ($scriptPath -match '^%~dp(?:0.+|n0\.ps1)$') ('PS1 路径未锚定入口：' + $launcher.FullName)
            $style = 'dp0-named'
            if ($scriptPath -eq '%~dpn0.ps1') { $style = 'dpn0' }
            elseif ($scriptPath -eq '%~dp0Run.ps1') { $style = 'dp0-run' }
            elseif ($scriptPath -eq '%~dp0Install-Menu.ps1') { $style = 'dp0-installer' }
            $executable = 'bare'
            if ($text -match '(?im)^"%SystemRoot%') { $executable = 'system-root' }
            $forwardArguments = $text -match '(?m)^.*powershell\.exe[^\r\n]*%\*'
            $shape = $executable + '/' + $style + '/' + [string]$forwardArguments
        } else {
            Assert-JobsLauncher ($text.Contains('if not exist "%~dp0..\JobsFlutterTools\Install.cmd" (') -and $text.Contains('call "%~dp0..\JobsFlutterTools\Install.cmd"')) ('Legacy 委托门禁变化：' + $launcher.FullName)
            $scriptPath = ''; $forwardArguments = $false; $shape = 'legacy-delegate'
        }
        $entries.Add([pscustomobject]@{ Path = $launcher.FullName; Text = $text; PowerShell = $isPowerShell; ScriptPath = $scriptPath; ForwardArguments = $forwardArguments; Shape = $shape })
    }
    Write-Host ('清单：' + $root.Path + '，' + $launchers.Count + ' 个 CMD。')
}
Assert-JobsLauncher ($entries.Count -eq 190) '六根转发入口必须为 190 个。'
Assert-JobsLauncher (@($entries | Where-Object PowerShell).Count -eq 182) 'PowerShell 转发入口必须为 182 个。'
Assert-JobsLauncher (@($entries | Where-Object { -not $_.PowerShell }).Count -eq 8) 'Legacy 委托入口必须为 8 个。'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    Write-Host ('PASS：' + $script:assertions + ' 项静态断言。')
    Write-Host 'SKIP：真实 CMD /v:on 路径与退出码验证只在 Windows 执行。'
    return
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('JobsWindowsLaunchers-' + [guid]::NewGuid().ToString('N'))
Assert-JobsLauncher (-not $fixture.Contains('!')) 'TEMP 本身含 !，无法隔离 fake CMD 地址；请使用普通 TEMP。'
$fakeBody = "@echo off`r`nsetlocal DisableDelayedExpansion`r`nchcp 65001 >nul`r`n>`"%JOBS_LAUNCH_CAPTURE%`" echo(%*`r`n>>`"%JOBS_LAUNCH_CAPTURE%`" echo(__JOBS_FAKE_SCRIPT__=%~f0`r`nexit /b 7`r`n"
# 使用真实 cmd.exe，但只替换其 PowerShell 可执行名为假 CMD；保留参数、宏路径和暂停策略。
function Invoke-JobsLauncherProbe($Entry, [string]$CaseName, [switch]$MissingDelegate) {
    $work = Join-Path (Join-Path (Join-Path $fixture $CaseName) '中文! bang [x]') 'entry'
    [void][IO.Directory]::CreateDirectory($work)
    $entryPath = Join-Path $work 'entry.cmd'
    $text = $Entry.Text
    $expectedPath = ''
    if ($Entry.PowerShell) {
        $text = [regex]::Replace($text, $powershellPattern, 'call "%JOBS_LAUNCH_FAKE%"')
        if ($Entry.ScriptPath -eq '%~dpn0.ps1') { $expectedPath = Join-Path $work 'entry.ps1' }
        else { $expectedPath = Join-Path $work $Entry.ScriptPath.Substring(5) }
    } else {
        $expectedPath = [IO.Path]::GetFullPath((Join-Path $work '..\JobsFlutterTools\Install.cmd'))
        if ($MissingDelegate) {
            if ([IO.File]::Exists($expectedPath)) { [IO.File]::Delete($expectedPath) }
        } else {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $expectedPath))
            [IO.File]::WriteAllText($expectedPath, $fakeBody, [Text.Encoding]::ASCII)
        }
    }
    $sourceBytes = [IO.File]::ReadAllBytes($Entry.Path)
    $bom = $sourceBytes.Length -ge 3 -and $sourceBytes[0] -eq 239 -and $sourceBytes[1] -eq 187 -and $sourceBytes[2] -eq 191
    [IO.File]::WriteAllText($entryPath, $text, (New-Object Text.UTF8Encoding($bom)))
    $suffix = ''; if ($MissingDelegate) { $suffix = '-missing' }
    $capture = Join-Path $fixture ($CaseName + $suffix + '.txt')
    $target = 'argument! bang [y]'
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $env:ComSpec
    $info.Arguments = '/d /v:on /c entry.cmd -SourceTree -Target "!JOBS_LAUNCH_TARGET!"'
    $info.WorkingDirectory = $work
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.EnvironmentVariables['JOBS_LAUNCH_FAKE'] = Join-Path $fixture 'fake.cmd'
    $info.EnvironmentVariables['JOBS_LAUNCH_CAPTURE'] = $capture
    $info.EnvironmentVariables['JOBS_LAUNCH_TARGET'] = $target
    $info.EnvironmentVariables['JOBS_NO_PAUSE'] = '1'
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $finished = $process.WaitForExit(5000)
        if (-not $finished) { $process.Kill(); [void]$process.WaitForExit(1000) }
        Assert-JobsLauncher $finished ('CMD 等待输入或超时：' + $Entry.Path)
        $expectedCode = 7; if ($MissingDelegate) { $expectedCode = 1 }
        Assert-JobsLauncher ($process.ExitCode -eq $expectedCode) ('真实 CMD 退出码未保留：' + $Entry.Path + '，实际=' + $process.ExitCode)
        if ($MissingDelegate) {
            Assert-JobsLauncher (-not [IO.File]::Exists($capture)) ('缺少 Legacy 目标时仍执行业务：' + $Entry.Path)
        } else {
            Assert-JobsLauncher ([IO.File]::Exists($capture)) ('假 CMD 未调用：' + $Entry.Path)
            $raw = [IO.File]::ReadAllText($capture, [Text.Encoding]::UTF8)
            if ($Entry.PowerShell) { Assert-JobsLauncher ($raw.Contains('"' + $expectedPath + '"')) ('含 ! 的 PS1 宏路径损坏：' + $Entry.Path + '；实际=' + $raw) }
            else { Assert-JobsLauncher ($raw.Contains('__JOBS_FAKE_SCRIPT__=' + $expectedPath)) ('含 ! 的 Legacy 委托路径损坏：' + $Entry.Path) }
            if ($Entry.ForwardArguments) { Assert-JobsLauncher ($raw.Contains('"' + $target + '"')) ('含 ! 的透传参数损坏：' + $Entry.Path + '；实际=' + $raw) }
        }
        Write-Host ('原生验证：' + $Entry.Shape + $suffix + '，源=' + $Entry.Path)
    } finally { $process.Dispose() }
}
# 仅执行已审查的 -Check，不继承测试宿主的进程策略，不修改用户或机器策略。
function Invoke-JobsLauncherReadOnlyCheck([string]$RelativePath, [string]$Label) {
    $path = Join-Path $repository $RelativePath
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $env:ComSpec
    $info.Arguments = '/d /v:on /s /c ""' + [IO.Path]::GetFileName($path) + '" -Check"'
    $info.WorkingDirectory = Split-Path -Parent $path
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
    $info.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
    $info.EnvironmentVariables.Remove('PSExecutionPolicyPreference')
    Assert-JobsLauncher (-not $info.EnvironmentVariables.ContainsKey('PSExecutionPolicyPreference')) ($Label + ' 子进程仍继承测试宿主执行策略')
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        [void]$process.Start()
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $finished = $process.WaitForExit(5000)
        if (-not $finished) { $process.Kill(); [void]$process.WaitForExit(1000) }
        $captured = [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdout, $stderr), 1000)
        $outText = ''; $errorText = ''
        if ($stdout.IsCompleted) { $outText = $stdout.Result }
        if ($stderr.IsCompleted) { $errorText = $stderr.Result }
        # 根回归器会将完整子输出保存到本套日志，无须在源码目录写报告。
        Write-Output ('真实 -Check｜' + $Label + '｜PSExecutionPolicyPreference 已从子环境移除。')
        Write-Output ('子 stdout｜' + $Label + "`n" + $outText)
        Write-Output ('子 stderr｜' + $Label + "`n" + $errorText)
        Assert-JobsLauncher ($finished -and $captured) ($Label + ' -Check 等待输入或输出管道超时')
        Assert-JobsLauncher ($process.ExitCode -eq 0) ($Label + ' 在独立子环境中 -Check 失败，退出码=' + $process.ExitCode)
        Assert-JobsLauncher ($outText.Contains('只读检查：')) ($Label + ' 未到达已审查的只读检查分支')
    } finally { $process.Dispose() }
}
try {
    [void][IO.Directory]::CreateDirectory($fixture)
    [IO.File]::WriteAllText((Join-Path $fixture 'fake.cmd'), $fakeBody, [Text.Encoding]::ASCII)
    $caseIndex = 0
    foreach ($group in $entries | Group-Object Shape | Sort-Object Name) {
        $caseIndex++
        $representative = $group.Group[0]
        $caseName = 'case-' + $caseIndex
        Invoke-JobsLauncherProbe $representative $caseName
        if (-not $representative.PowerShell) { Invoke-JobsLauncherProbe $representative $caseName -MissingDelegate }
    }
    $machinePolicy = Get-ExecutionPolicy -Scope MachinePolicy
    $userPolicy = Get-ExecutionPolicy -Scope UserPolicy
    if ($machinePolicy -ne 'Undefined' -or $userPolicy -ne 'Undefined') {
        Write-Host ('SKIP：企业策略优先，真实 -Check 代表不运行；MachinePolicy=' + $machinePolicy + '，UserPolicy=' + $userPolicy + '。')
    } else {
        Invoke-JobsLauncherReadOnlyCheck 'JobsSh.sh/WindowsOS/【WindowsOS】GoProject.cmd' 'JobsSh.GoProject'
        Invoke-JobsLauncherReadOnlyCheck 'JobsCommand@Others/WindowsOS/【WindowsOS】MD5.cmd' 'Others.MD5'
    }
    Write-Host ('PASS：' + $script:assertions + ' 项断言；190 个静态入口，' + $caseIndex + ' 种真实 CMD 形态及 Legacy 缺目标门禁。')
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
