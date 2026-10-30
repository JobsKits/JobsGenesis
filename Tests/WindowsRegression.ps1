#requires -Version 5.1
# WindowsRegression.ps1 | JobsGenesis
# Created by Jobs on 2026年10月25日，星期日.
# 在 Windows PowerShell 5.1 中编排已有隔离回归，报告和日志写入独立目录。
[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [ValidateRange(1, 86400)][int]$TimeoutSeconds = 300,
    [hashtable]$SuiteTimeoutSeconds = @{},
    [string[]]$SuiteIds = @()
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-JobsWindowsTestSuites {
    $suites = @(
        @{ Id = 'Launchers.CMD'; Path = 'Tests/WindowsLaunchers.Tests.ps1' },
        @{ Id = 'Gits.Regression'; Path = 'JobsCommand@Gits/WindowsOS/Tests/Regression.ps1' },
        @{ Id = 'Gits.GitProxyConfigurator'; Path = 'JobsCommand@Gits/WindowsOS/Tests/GitProxyConfigurator.Tests.ps1' },
        @{ Id = 'SourceTree.Safety'; Path = 'SourceTree.command/WindowsOS/Tests/Safety.Tests.ps1' },
        @{ Id = 'SourceTree.SourceTree'; Path = 'SourceTree.command/WindowsOS/Tests/SourceTree.Tests.ps1' },
        @{ Id = 'JobsSh.Regression'; Path = 'JobsSh.sh/WindowsOS/Tests/Regression.ps1' },
        @{ Id = 'Others.Regression'; Path = 'JobsCommand@Others/WindowsOS/Tests/Regression.ps1' },
        @{ Id = 'Flutter.Portable'; Path = 'JobsCommand@Flutter/WindowsOS/Tests/Portable.Tests.ps1' },
        @{ Id = 'Doctor.Build'; Path = 'Tests/DoctorBuild.Tests.ps1' },
        @{ Id = 'Python.BAT'; Path = 'Tests/PythonBat.Tests.ps1' },
        @{ Id = 'Others.FileVolumes'; Path = 'JobsCommand@Others/WindowsOS/Tests/FileVolumes.Tests.ps1' },
        @{ Id = 'Flutter.HarmonyBuild'; Path = 'JobsCommand@Flutter/WindowsOS/Tests/HarmonyBuild.Tests.ps1' },
        @{ Id = 'Flutter.Bootstrap'; Path = 'JobsCommand@Flutter/WindowsOS/Tests/Bootstrap.Tests.ps1' },
        @{ Id = 'Flutter.SimulatorEntries'; Path = 'JobsCommand@Flutter/WindowsOS/Tests/SimulatorEntries.Tests.ps1' },
        @{ Id = 'SourceTree.Remote'; Path = 'SourceTree.command/WindowsOS/Tests/Remote.Tests.ps1' },
        @{ Id = 'SourceTree.FlutterRunner'; Path = 'SourceTree.command/WindowsOS/Tests/FlutterRunner.Tests.ps1' },
        @{ Id = 'SourceTree.HarmonyBuild'; Path = 'SourceTree.command/WindowsOS/Tests/HarmonyBuild.Tests.ps1' }
    )
    foreach ($name in @(
        'Core', 'Catalog', 'Architecture', 'Installer', 'PackageInstaller',
        'SelectionPanel', 'FlutterFeatureSelection', 'ActionModules', 'Worker',
        'RunPermissions', 'FlutterTools', 'FlutterSdkInspector', 'FlutterVersionMgr',
        'HarmonyFlutterSdk', 'GitPuller', 'FlutterDependencyExtractor', 'FlutterRunner',
        'FlutterPackager', 'FlutterDoctorCodegen', 'BuildArtifactCleaner',
        'AndroidSimulatorCreator', 'AndroidSimulatorRepair', 'AndroidSimulatorRepairer',
        'AndroidSimulatorBootstrap', 'GitProxyConfigurator', 'HarmonySimulatorCreator',
        'HarmonySimulatorRepairer', 'HarmonySimulatorBootstrap', 'HarmonySimulatorImages',
        'FileContentViewer', 'FileVolumes', 'FlutterDependencyArchiveEndToEnd',
        'FlutterDependencyArchiveShell', 'FlutterDependencyImporter', 'FlutterDependencyIntros',
        'FlutterHarmonyPackage', 'FlutterProjectDependencies', 'FlutterProjectSetup',
        'FlutterProjectSetupDashboard', 'FlutterProjectSetupLogTail', 'FlutterProjectSetupVersion',
        'FlutterRunnerAndroid', 'GitRollback', 'HiddenFiles', 'IDEProject',
        'ManagementExecution', 'ManagementLogTerminal', 'SourcetreeOpener'
    )) {
        $suites += @{ Id = 'Extension.' + $name; Path = 'OS@Extension/WindowsOS@Extension/Tests/' + $name + '.Tests.ps1' }
    }
    foreach ($suite in $suites) { [pscustomobject]$suite }
}

# 只扫描六个自有 Windows 源码根，跳过依赖、供应商、产物和链接。
function Get-JobsWindowsPowerShellFiles {
    param([string]$Directory)
    foreach ($item in Get-ChildItem -LiteralPath $Directory -Force) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
        if ($item.PSIsContainer) {
            if ($item.Name -in @('.git', 'node_modules', 'Pods', 'PodsManual', '.dart_tool', 'build', '.build', 'dist', '.venv', 'DerivedData', 'vendor', 'third_party', 'third-party', 'thirdparty') -or $item.Name -like 'ManualBy*Pods@Pods') { continue }
            Get-JobsWindowsPowerShellFiles -Directory $item.FullName
        } elseif ($item.Extension -in @('.ps1', '.psm1', '.psd1')) { $item.FullName }
    }
}

function Get-JobsWindowsPowerShellIssues {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 239 -or $bytes[1] -ne 187 -or $bytes[2] -ne 191) {
        [pscustomobject]@{ Path = $Path; Line = 1; Message = '缺少 UTF-8 BOM，Windows PowerShell 5.1 可能按系统代码页误读中文。' }
    }
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors)
    foreach ($parseError in @($parseErrors)) {
        if ($null -ne $parseError) { [pscustomobject]@{ Path = $Path; Line = $parseError.Extent.StartLineNumber; Message = $parseError.Message } }
    }
}

function Get-JobsWindowsGitVersion {
    param([string]$Path)
    $process = New-Object Diagnostics.Process
    $started = $false
    try {
        $process.StartInfo.FileName = $Path
        $process.StartInfo.Arguments = '--version'
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        [void]$process.Start()
        $started = $true
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(10000)) { throw 'git.exe --version 超时。' }
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdout, $stderr), 5000)) { throw 'git.exe --version 输出管道未关闭。' }
        if ($process.ExitCode -ne 0) { throw ('git.exe --version 失败，退出码：' + $process.ExitCode) }
        $version = $stdout.GetAwaiter().GetResult().Trim()
        if ($version -notmatch '^git version \S+') { throw 'git.exe --version 没有返回有效版本信息。' }
        return $version
    } finally {
        if ($started -and -not $process.HasExited) { Stop-JobsWindowsTestProcess -Process $process }
        $process.Dispose()
    }
}

function Save-JobsWindowsTestReport {
    param($Report, [string]$Path)
    $Report.Summary = [ordered]@{
        Passed = @($Report.Suites | Where-Object { $_.Status -eq 'Passed' }).Count
        Partial = @($Report.Suites | Where-Object { $_.Status -eq 'Partial' }).Count
        Failed = @($Report.Suites | Where-Object { $_.Status -in @('Failed', 'Error') }).Count
        TimedOut = @($Report.Suites | Where-Object { $_.Status -eq 'TimedOut' }).Count
        Completed = @($Report.Suites).Count
        Planned = $Report.PlannedSuites
    }
    $temporary = $Path + '.tmp'
    [IO.File]::WriteAllText($temporary, ($Report | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($true)))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

# .NET Framework 没有 Kill(true)，仅对本次测试的 PID 树执行系统 taskkill。
function Stop-JobsWindowsTestProcess {
    param([Diagnostics.Process]$Process)
    if ($Process.HasExited) { return }
    $taskkill = Join-Path ([Environment]::GetFolderPath('System')) 'taskkill.exe'
    if ([IO.File]::Exists($taskkill)) {
        $stopper = New-Object Diagnostics.Process
        try {
            $stopper.StartInfo.FileName = $taskkill
            $stopper.StartInfo.Arguments = '/PID ' + $Process.Id + ' /T /F'
            $stopper.StartInfo.UseShellExecute = $false
            $stopper.StartInfo.CreateNoWindow = $true
            $stopper.StartInfo.RedirectStandardOutput = $true
            $stopper.StartInfo.RedirectStandardError = $true
            [void]$stopper.Start()
            $stopOutput = $stopper.StandardOutput.ReadToEndAsync()
            $stopError = $stopper.StandardError.ReadToEndAsync()
            if (-not $stopper.WaitForExit(5000)) { $stopper.Kill() }
        } finally { $stopper.Dispose() }
    }
    if (-not $Process.HasExited) { $Process.Kill() }
    [void]$Process.WaitForExit(5000)
}

function Invoke-JobsWindowsTestSuite {
    param($Suite, [string]$RepositoryRoot, [string]$PowerShellPath, [string]$LogDirectory, [int]$LimitSeconds)
    $suitePath = Join-Path $RepositoryRoot $Suite.Path
    $stdoutPath = Join-Path $LogDirectory ($Suite.Id + '.stdout.log')
    $stderrPath = Join-Path $LogDirectory ($Suite.Id + '.stderr.log')
    $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($suitePath))
    $wrapper = @'
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$OutputEncoding = New-Object Text.UTF8Encoding($false)
[Console]::OutputEncoding = $OutputEncoding
$suitePath = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__PAYLOAD__'))
try {
    $global:LASTEXITCODE = 0
    # 5.1 的重定向宿主会把 Write-Host 复制为 CLIXML；显式渲染信息流以保留可读日志与 SKIP。
    & $suitePath 6>&1 | ForEach-Object {
        if ($_ -is [Management.Automation.InformationRecord]) {
            [Console]::Out.WriteLine($_.ToString())
        } else { $_ }
    }
    if (-not $?) {
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        exit 1
    }
    exit 0
} catch {
    [Console]::Error.WriteLine(($_ | Out-String))
    exit 1
}
'@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wrapper.Replace('__PAYLOAD__', $payload)))
    $process = New-Object Diagnostics.Process
    $process.StartInfo.FileName = $PowerShellPath
    $process.StartInfo.Arguments = '-NoLogo -NoProfile -STA -NonInteractive -ExecutionPolicy Bypass -InputFormat Text -OutputFormat Text -EncodedCommand ' + $encoded
    $process.StartInfo.WorkingDirectory = Split-Path -Parent (Split-Path -Parent $suitePath)
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.RedirectStandardInput = $true
    $process.StartInfo.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
    $process.StartInfo.EnvironmentVariables['GIT_ALLOW_PROTOCOL'] = 'file'
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $stdoutFile = $null
    $stderrFile = $null
    $timedOut = $false
    $started = $false
    $exitCode = $null
    $captureError = ''
    try {
        $stdoutFile = [IO.File]::Open($stdoutPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        $stderrFile = [IO.File]::Open($stderrPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        [void]$process.Start()
        $started = $true
        # Console.ReadLine 也必须看到 EOF，不能继承桌面控制台等待输入。
        $process.StandardInput.Close()
        # 两条流直接异步落盘，失败和超时也保留已经产生的输出。
        $stdoutCopy = $process.StandardOutput.BaseStream.CopyToAsync($stdoutFile)
        $stderrCopy = $process.StandardError.BaseStream.CopyToAsync($stderrFile)
        if (-not $process.WaitForExit($LimitSeconds * 1000)) {
            $timedOut = $true
            Stop-JobsWindowsTestProcess -Process $process
        }
        if ($process.HasExited) { $exitCode = $process.ExitCode }
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdoutCopy, $stderrCopy), 5000)) {
            $captureError = '测试输出管道未在退出后关闭；已保留现有日志。'
        }
    } catch {
        $captureError = $_.Exception.Message
        try { Stop-JobsWindowsTestProcess -Process $process } catch { $captureError += '; ' + $_.Exception.Message }
    } finally {
        if ($started -and -not $process.HasExited) {
            try { Stop-JobsWindowsTestProcess -Process $process } catch { $captureError += '; ' + $_.Exception.Message }
        }
        $process.Dispose()
        if ($null -ne $stdoutFile) { $stdoutFile.Dispose() }
        if ($null -ne $stderrFile) { $stderrFile.Dispose() }
        $clock.Stop()
    }
    if ($captureError) { [IO.File]::AppendAllText($stderrPath, ([Environment]::NewLine + $captureError), (New-Object Text.UTF8Encoding($false))) }
    $combined = [IO.File]::ReadAllText($stdoutPath) + [Environment]::NewLine + [IO.File]::ReadAllText($stderrPath)
    $skips = @([regex]::Matches($combined, '(?im)^\s*SKIP\b[^\r\n]*') | ForEach-Object { $_.Value.Trim() })
    $status = if ($timedOut) { 'TimedOut' } elseif ($captureError) { 'Error' } elseif ($exitCode -ne 0) { 'Failed' } elseif ($skips.Count) { 'Partial' } else { 'Passed' }
    [pscustomobject]@{
        Id = $Suite.Id; Path = $Suite.Path; Status = $status; ExitCode = $exitCode
        TimeoutSeconds = $LimitSeconds; DurationSeconds = [Math]::Round($clock.Elapsed.TotalSeconds, 3)
        StdoutLog = $stdoutPath; StderrLog = $stderrPath; SkipEvidence = $skips; Error = $captureError
    }
}

function Invoke-JobsWindowsRegression {
    Write-Host 'Jobs | Windows 脚本隔离回归'
    Write-Host '范围：六个 Windows 源码根及指定文件的语法 / BOM 检查，以及显式清单中的临时夹具测试。'
    Write-Host '测试逐套使用独立 PowerShell 5.1；Ctrl+C 停止。跳过项单独记为 Partial。'
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw '此编排器仅在 Windows 执行；请在虚拟机中使用 Windows PowerShell 5.1。' }
    if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) { throw '请使用系统 Windows PowerShell 5.1（powershell.exe），不能用 pwsh 代替目标运行时。' }
    $repositoryRoot = Split-Path -Parent $PSScriptRoot
    $suites = @(Get-JobsWindowsTestSuites)
    if ($SuiteIds.Count) {
        foreach ($id in $SuiteIds) {
            if ($id -notin @($suites.Id)) { throw ('未知测试套件：' + $id) }
        }
        $suites = @($suites | Where-Object { $_.Id -in $SuiteIds })
    }
    Write-Host ('本次计划：' + $suites.Count + ' 套；' + $(if ($SuiteIds.Count) { '指定套件回归' } else { '完整清单回归' }))
    foreach ($key in $SuiteTimeoutSeconds.Keys) {
        if ($key -notin @($suites.Id) -or [int]$SuiteTimeoutSeconds[$key] -lt 1 -or [int]$SuiteTimeoutSeconds[$key] -gt 86400) { throw ('无效套件超时配置：' + $key) }
    }
    $destination = $OutputDirectory
    if (-not $destination) { $destination = Join-Path ([IO.Path]::GetTempPath()) ('JobsWindowsRegression-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [guid]::NewGuid().ToString('N')) }
    $destination = [IO.Path]::GetFullPath($destination)
    if ((Test-Path -LiteralPath $destination) -and @((Get-ChildItem -LiteralPath $destination -Force)).Count) { throw '输出目录必须为空，避免覆盖既有报告和日志。' }
    [void][IO.Directory]::CreateDirectory($destination)
    $reportPath = Join-Path $destination 'results.json'
    $systemDirectory = 'System32'
    if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { $systemDirectory = 'Sysnative' }
    $powerShell = Join-Path $env:SystemRoot ($systemDirectory + '/WindowsPowerShell/v1.0/powershell.exe')
    $roots = @('JobsCommand@Gits/WindowsOS', 'SourceTree.command/WindowsOS', 'JobsSh.sh/WindowsOS', 'JobsCommand@Others/WindowsOS', 'JobsCommand@Flutter/WindowsOS', 'OS@Extension/WindowsOS@Extension')
    $extraFiles = @('Tests/WindowsRegression.ps1', 'Tests/WindowsLaunchers.Tests.ps1', 'Tests/DoctorBuild.Tests.ps1', 'Tests/PythonBat.Tests.ps1', 'JobsPythonTools.py/JobsReverseIPA.py/JobsReverseIPA/doctor/windows/build_doctor_exe.ps1')
    $report = [ordered]@{
        SchemaVersion = 1; StartedUtc = [DateTime]::UtcNow.ToString('o'); FinishedUtc = $null; Status = 'Running'
        RepositoryRoot = $repositoryRoot; PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OperatingSystem = [Environment]::OSVersion.VersionString; Architecture = $env:PROCESSOR_ARCHITECTURE
        PlannedSuites = $suites.Count; Preflight = [ordered]@{ PowerShellPath = $powerShell; GitPath = $null; GitVersion = $null; ParserRoots = $roots; ParserFiles = $extraFiles; ParsedFiles = 0; Issues = @() }
        Suites = @(); Summary = $null
    }
    Save-JobsWindowsTestReport $report $reportPath
    Write-Host ('报告目录：' + $destination)
    try {
        $issues = New-Object 'Collections.Generic.List[object]'
        $git = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $git) { $issues.Add('缺少已有 git.exe；请先准备 Git for Windows，再重新运行。') }
        else {
            $report.Preflight.GitPath = $git.Source
            try { $report.Preflight.GitVersion = Get-JobsWindowsGitVersion -Path $git.Source }
            catch { $issues.Add($_.Exception.Message) }
        }
        if (-not [IO.File]::Exists($powerShell)) { $issues.Add('找不到系统 Windows PowerShell 5.1：' + $powerShell) }
        $filesToParse = New-Object 'Collections.Generic.List[string]'
        foreach ($relativeRoot in $roots) {
            $path = Join-Path $repositoryRoot $relativeRoot
            if (-not (Test-Path -LiteralPath $path -PathType Container)) { $issues.Add('源码目录缺失：' + $relativeRoot); continue }
            if (((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { $issues.Add('源码根是链接，停止扫描：' + $relativeRoot); continue }
            foreach ($file in Get-JobsWindowsPowerShellFiles -Directory $path) { $filesToParse.Add($file) }
        }
        foreach ($relativeFile in $extraFiles) {
            $path = Join-Path $repositoryRoot $relativeFile
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { $issues.Add('指定脚本缺失：' + $relativeFile); continue }
            if (((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { $issues.Add('指定脚本是链接，停止扫描：' + $relativeFile); continue }
            $filesToParse.Add($path)
        }
        foreach ($file in $filesToParse) {
            foreach ($issue in Get-JobsWindowsPowerShellIssues -Path $file) { $issues.Add($issue) }
            $report.Preflight.ParsedFiles++
        }
        foreach ($suite in $suites) { if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot $suite.Path) -PathType Leaf)) { $issues.Add('测试缺失：' + $suite.Path) } }
        $report.Preflight.Issues = @($issues.ToArray())
        if ($issues.Count) {
            $report.Status = 'Blocked'
            foreach ($issue in $issues) { Write-Host ('预检失败：' + ($issue | Out-String).Trim()) }
            return 1
        }
        Save-JobsWindowsTestReport $report $reportPath
        $results = New-Object 'Collections.Generic.List[object]'
        foreach ($suite in $suites) {
            $limit = $TimeoutSeconds
            if ($SuiteTimeoutSeconds.ContainsKey($suite.Id)) { $limit = [int]$SuiteTimeoutSeconds[$suite.Id] }
            Write-Host ('RUN ' + $suite.Id + '（超时 ' + $limit + ' 秒）')
            $result = Invoke-JobsWindowsTestSuite -Suite $suite -RepositoryRoot $repositoryRoot -PowerShellPath $powerShell -LogDirectory $destination -LimitSeconds $limit
            $results.Add($result)
            $report.Suites = @($results.ToArray())
            Save-JobsWindowsTestReport $report $reportPath
            Write-Host ($result.Status + ' ' + $suite.Id + '；退出码=' + $result.ExitCode)
        }
        if (@($report.Suites | Where-Object { $_.Status -in @('Failed', 'Error', 'TimedOut') }).Count) { $report.Status = 'Failed'; return 1 }
        if (@($report.Suites | Where-Object { $_.Status -eq 'Partial' }).Count) { $report.Status = 'Partial'; return 2 }
        $report.Status = 'Passed'
        return 0
    } catch {
        $report.Status = 'Error'
        $report.Preflight.Issues += $_.Exception.Message
        Write-Host ('ERROR ' + $_.Exception.Message)
        return 1
    } finally {
        if ($report.Status -eq 'Running') { $report.Status = 'Interrupted' }
        $report.FinishedUtc = [DateTime]::UtcNow.ToString('o')
        Save-JobsWindowsTestReport $report $reportPath
        Write-Host ('结果：' + $report.Status + '；JSON：' + $reportPath)
    }
}

try { exit (Invoke-JobsWindowsRegression) }
catch { Write-Error $_ -ErrorAction Continue; exit 1 }
