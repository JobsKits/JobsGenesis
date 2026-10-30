#requires -Version 5.1
# Jobs Windows 转发入口回归；假 CMD 验证路径，两个真实 -Check 入口只查询加载状态。
[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$roots = @(
    @{ Path = 'JobsCommand@Flutter/WindowsOS'; Count = 46 },
    @{ Path = 'JobsCommand@Gits/WindowsOS'; Count = 21 },
    @{ Path = 'JobsCommand@Others/WindowsOS'; Count = 17 },
    @{ Path = 'JobsSh.sh/WindowsOS'; Count = 15 },
    @{ Path = 'SourceTree.command/WindowsOS'; Count = 29 },
    @{ Path = 'OS@Extension/WindowsOS@Extension'; Count = 45 }
)
$excludedSegments = @('.git', 'node_modules', 'Pods', 'work', 'dist', 'build', 'DerivedData', '.dart_tool', 'vendor', 'third_party', 'ThirdParty')
$powershellPattern = '(?im)^(?:powershell\.exe|"%SystemRoot%\\System32\\WindowsPowerShell\\v1\.0\\powershell\.exe")(?=\s)'
$wscriptPattern = '(?im)^"%SystemRoot%\\System32\\wscript\.exe"(?=\s)'
$approvedWscriptLaunchers = @{}
foreach ($folder in @(
    'Infrastructure',
    'JobsAndroidSimulatorCreator',
    'JobsAndroidSimulatorRepairer',
    'JobsAndroidStudioOpener',
    'JobsBuildArtifactCleaner',
    'JobsCodeGraphUpdater',
    'JobsFileContentViewer',
    'JobsFileVolumes',
    'JobsFlutterCodegen',
    'JobsFlutterDependencyExtractor',
    'JobsFlutterDoctor',
    'JobsFlutterPackager',
    'JobsFlutterPubGet',
    'JobsFlutterRunner',
    'JobsFlutterSdkInspector',
    'JobsFlutterTools',
    'JobsFlutterVersionMgr',
    'JobsGitEmptyCommitPusher',
    'JobsGitProxyConfigurator',
    'JobsGitPuller',
    'JobsGitRemoteCopier',
    'JobsGitRemoteOpener',
    'JobsGitRollback',
    'JobsHarmonySimulatorCreator',
    'JobsHarmonySimulatorRepairer',
    'JobsHiddenFilesToggler',
    'JobsPathCopier',
    'JobsRunAuthorizationRevoker',
    'JobsRunAuthorizer',
    'JobsSourcetreeOpener',
    'JobsTerminalOpener',
    'JobsVSCodeOpener',
    'JobsVisualStudioOpener'
)) {
    $approvedWscriptLaunchers['OS@Extension/WindowsOS@Extension/' + $folder + '/Manage.cmd'] = @{
        ScriptPath = '%~dp0Manage.vbs'; FixedArguments = ''
    }
}
$approvedWscriptLaunchers['OS@Extension/WindowsOS@Extension/【Windows】🧩管理资源管理器扩展.cmd'] = @{
    ScriptPath = '%~dpn0.vbs'; FixedArguments = ''
}
foreach ($mode in @('Install', 'Uninstall')) {
    $approvedWscriptLaunchers['OS@Extension/WindowsOS@Extension/JobsFlutterDependencyExtractor/' + $mode + '.cmd'] = @{
        ScriptPath = '%~dp0Manage.vbs'; FixedArguments = '-Mode ' + $mode
    }
}
# 只允许已审阅的相对管理脚本、参数门禁及隐藏 STA 启动；不得夹带其它 VBS 业务。
$approvedWscriptBody = @'
Option Explicit
' Created by Jobs on 2026-10-28. WScript launches the management GUI without a console.
Dim shell, files, folder, script, host, command, argument, index
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
folder = files.GetParentFolderName(WScript.ScriptFullName)
script = files.BuildPath(folder, "Scripts\Manage.ps1")
host = shell.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
If Not files.FileExists(script) Then
    MsgBox "Missing Scripts\Manage.ps1. Please copy the complete package.", vbCritical, "Jobs Management"
    WScript.Quit 1
End If
command = Quote(host) & " -NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File " & Quote(script)
For index = 0 To WScript.Arguments.Count - 1
    argument = WScript.Arguments(index)
    If InStr(argument, Chr(34)) > 0 Or InStr(argument, vbCr) > 0 Or InStr(argument, vbLf) > 0 Then
        MsgBox "Invalid argument.", vbCritical, "Jobs Management"
        WScript.Quit 1
    End If
    command = command & " " & Quote(argument)
Next
On Error Resume Next
shell.Run command, 0, False
If Err.Number <> 0 Then
    MsgBox Err.Description, vbCritical, "Jobs Management"
    WScript.Quit 1
End If
Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
'@
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
        $isWscript = [regex]::IsMatch($text, $wscriptPattern)
        $isLegacy = $text.Contains('rem Legacy entry delegates to the unified Flutter menu owner.')
        $kindCount = [int]$isPowerShell + [int]$isWscript + [int]$isLegacy
        $fixedArguments = ''
        Assert-JobsLauncher ($kindCount -eq 1) ('出现未经审查的业务 CMD，请单独确认边界：' + $launcher.FullName)
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
        } elseif ($isWscript) {
            $relative = $launcher.FullName.Substring($repository.Length).TrimStart('\', '/').Replace('\', '/')
            Assert-JobsLauncher ($approvedWscriptLaunchers.ContainsKey($relative)) ('未经登记的 WScript 入口：' + $launcher.FullName)
            $approval = $approvedWscriptLaunchers[$relative]
            $scriptPath = $approval.ScriptPath
            $fixedArguments = $approval.FixedArguments
            $tail = ' %*'; if ($fixedArguments) { $tail = ' ' + $fixedArguments + $tail }
            $command = '"%SystemRoot%\System32\wscript.exe" //nologo "' + $scriptPath + '"' + $tail
            $approvedCmd = @(
                '@echo off', 'setlocal DisableDelayedExpansion',
                'rem GUI startup: WScript hosts Scripts/Manage.ps1 in a hidden PowerShell process.',
                $command, 'exit /b %errorlevel%'
            ) -join "`n"
            Assert-JobsLauncher ($text.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n") -ceq $approvedCmd) ('WScript CMD 只能转发已登记 VBS 与参数：' + $launcher.FullName)
            $vbsPath = Join-Path $launcher.DirectoryName 'Manage.vbs'
            if ($scriptPath -eq '%~dpn0.vbs') { $vbsPath = [IO.Path]::ChangeExtension($launcher.FullName, '.vbs') }
            Assert-JobsLauncher (Test-Path -LiteralPath $vbsPath -PathType Leaf) ('缺少相邻 VBS：' + $launcher.FullName)
            $vbsItem = Get-Item -LiteralPath $vbsPath -Force
            Assert-JobsLauncher (($vbsItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('拒绝链接 VBS：' + $vbsPath)
            $vbsText = [IO.File]::ReadAllText($vbsPath).Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
            Assert-JobsLauncher ($vbsText -ceq $approvedWscriptBody) ('VBS 超出相对定位、参数校验与隐藏 STA 启动边界：' + $vbsPath)
            $template = $relative -eq 'OS@Extension/WindowsOS@Extension/Infrastructure/Manage.cmd'
            if (-not $template) {
                Assert-JobsLauncher (Test-Path -LiteralPath (Join-Path $launcher.DirectoryName 'Scripts/Manage.ps1') -PathType Leaf) ('VBS 管理目标不存在：' + $vbsPath)
            }
            $forwardArguments = $true
            $style = 'manage-vbs'; if ($scriptPath -eq '%~dpn0.vbs') { $style = 'dpn0-vbs' }
            $shape = 'wscript-system-root/' + $style + '/' + $fixedArguments
        } else {
            Assert-JobsLauncher ($text.Contains('if not exist "%~dp0..\JobsFlutterTools\Install.cmd" (') -and $text.Contains('call "%~dp0..\JobsFlutterTools\Install.cmd"')) ('Legacy 委托门禁变化：' + $launcher.FullName)
            $scriptPath = ''; $forwardArguments = $false; $shape = 'legacy-delegate'
        }
        $entries.Add([pscustomobject]@{ Path = $launcher.FullName; Text = $text; PowerShell = $isPowerShell; WScript = $isWscript; Legacy = $isLegacy; ScriptPath = $scriptPath; FixedArguments = $fixedArguments; ForwardArguments = $forwardArguments; Shape = $shape })
    }
    Write-Host ('清单：' + $root.Path + '，' + $launchers.Count + ' 个 CMD。')
}
Assert-JobsLauncher ($entries.Count -eq 173) '六根转发入口必须为 173 个。'
Assert-JobsLauncher (@($entries | Where-Object PowerShell).Count -eq 137) 'PowerShell 转发入口必须为 137 个。'
Assert-JobsLauncher (@($entries | Where-Object WScript).Count -eq 36) 'WScript 转发入口必须为 36 个。'
Assert-JobsLauncher (@($entries | Where-Object Legacy).Count -eq 0) '当前清单不应包含旧 Legacy 委托入口。'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    Write-Host ('PASS：' + $script:assertions + ' 项静态断言。')
    Write-Host 'SKIP：真实 CMD /v:on 路径与退出码验证只在 Windows 执行。'
    return
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('JobsWindowsLaunchers-' + [guid]::NewGuid().ToString('N'))
Assert-JobsLauncher (-not $fixture.Contains('!')) 'TEMP 本身含 !，无法隔离 fake CMD 地址；请使用普通 TEMP。'
$fakeBody = "@echo off`r`nsetlocal DisableDelayedExpansion`r`nchcp 65001 >nul`r`n>`"%JOBS_LAUNCH_CAPTURE%`" echo(%*`r`n>>`"%JOBS_LAUNCH_CAPTURE%`" echo(__JOBS_FAKE_SCRIPT__=%~f0`r`nexit /b 7`r`n"
# 使用真实 cmd.exe，仅把 PowerShell / WScript 可执行名替换为假 CMD，绝不启动管理 GUI。
function Invoke-JobsLauncherProbe($Entry, [string]$CaseName, [switch]$MissingDelegate) {
    $work = Join-Path (Join-Path (Join-Path $fixture $CaseName) '中文! bang [x]') 'entry'
    [void][IO.Directory]::CreateDirectory($work)
    $entryPath = Join-Path $work 'entry.cmd'
    $text = $Entry.Text
    $expectedPath = ''
    if ($Entry.PowerShell -or $Entry.WScript) {
        $pattern = $powershellPattern; if ($Entry.WScript) { $pattern = $wscriptPattern }
        $text = [regex]::Replace($text, $pattern, 'call "%JOBS_LAUNCH_FAKE%"')
        if ($Entry.ScriptPath -eq '%~dpn0.ps1') { $expectedPath = Join-Path $work 'entry.ps1' }
        elseif ($Entry.ScriptPath -eq '%~dpn0.vbs') { $expectedPath = Join-Path $work 'entry.vbs' }
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
            if ($Entry.PowerShell -or $Entry.WScript) { Assert-JobsLauncher ($raw.Contains('"' + $expectedPath + '"')) ('含 ! 的 PS1 / VBS 宏路径损坏：' + $Entry.Path + '；实际=' + $raw) }
            else { Assert-JobsLauncher ($raw.Contains('__JOBS_FAKE_SCRIPT__=' + $expectedPath)) ('含 ! 的 Legacy 委托路径损坏：' + $Entry.Path) }
            if ($Entry.ForwardArguments) { Assert-JobsLauncher ($raw.Contains('"' + $target + '"')) ('含 ! 的透传参数损坏：' + $Entry.Path + '；实际=' + $raw) }
            if ($Entry.FixedArguments) { Assert-JobsLauncher ($raw.Contains($Entry.FixedArguments)) ('VBS 固定模式参数未保留：' + $Entry.Path) }
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
        if ($representative.Legacy) { Invoke-JobsLauncherProbe $representative $caseName -MissingDelegate }
    }
    $machinePolicy = Get-ExecutionPolicy -Scope MachinePolicy
    $userPolicy = Get-ExecutionPolicy -Scope UserPolicy
    if ($machinePolicy -ne 'Undefined' -or $userPolicy -ne 'Undefined') {
        Write-Host ('SKIP：企业策略优先，真实 -Check 代表不运行；MachinePolicy=' + $machinePolicy + '，UserPolicy=' + $userPolicy + '。')
    } else {
        Invoke-JobsLauncherReadOnlyCheck 'JobsSh.sh/WindowsOS/【WindowsOS】GoProject.cmd' 'JobsSh.GoProject'
        Invoke-JobsLauncherReadOnlyCheck 'JobsCommand@Others/WindowsOS/【WindowsOS】MD5/【WindowsOS】MD5.cmd' 'Others.MD5'
    }
    Write-Host ('PASS：' + $script:assertions + ' 项断言；173 个静态入口（137 PS / 36 VBS），' + $caseIndex + ' 种真实 CMD 形态；GUI 未启动。')
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
