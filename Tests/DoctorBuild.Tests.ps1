#requires -Version 5.1
# Jobs 体检工具构建回归：只调用假 Python，不安装依赖或运行 PyInstaller。
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$builder = Join-Path (Split-Path -Parent $PSScriptRoot) 'JobsPythonTools.py/JobsReverseIPA.py/JobsReverseIPA/doctor/windows/build_doctor_exe.ps1'
$temporaryRoot = [IO.Path]::GetTempPath()
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { $temporaryRoot = '/private/tmp' }
$fixture = Join-Path $temporaryRoot ('JobsDoctorBuildTest-' + [guid]::NewGuid().ToString('N'))
$previousLocation = (Get-Location).Path
$script:assertions = 0
# 失败时报告触发分支和实际结果。
function Assert-JobsEqual($Actual, $Expected, [string]$Label) {
    if ($Actual -cne $Expected) { throw "$Label；实际=$Actual；预期=$Expected" }
    $script:assertions++
}
try {
    foreach ($scenario in @('fail-1', 'fail-2', 'fail-3', 'missing', 'empty', 'success')) {
        $project = Join-Path $fixture ($scenario + '/中文 project')
        [void][IO.Directory]::CreateDirectory($project)
        & {
            param($BuildScript, $ProjectPath, $Scenario)
            $state = @{ Calls = 0; Artifact = $null; Scenario = $Scenario }
            $messages = New-Object 'Collections.Generic.List[string]'
            $failure = $null
            # 模拟三次原生命令，产物只写入本次临时目录。
            function python {
                $state.Calls++
                $global:LASTEXITCODE = 0
                if ($state.Scenario -eq ('fail-' + $state.Calls)) {
                    $global:LASTEXITCODE = 37
                    return
                }
                if ($state.Calls -eq 3 -and $state.Scenario -in @('empty', 'success')) {
                    $outputIndex = [Array]::IndexOf($args, '--distpath')
                    if ($outputIndex -lt 0) { throw 'PyInstaller 未传入输出目录。' }
                    $outputDirectory = $args[$outputIndex + 1]
                    [void][IO.Directory]::CreateDirectory($outputDirectory)
                    $state.Artifact = Join-Path $outputDirectory 'IPA环境体检.exe'
                    $bytes = [byte[]]@()
                    if ($state.Scenario -eq 'success') { $bytes = [byte[]]@(77, 90, 1) }
                    [IO.File]::WriteAllBytes($state.Artifact, $bytes)
                }
            }
            try { & $BuildScript -ProjectRoot $ProjectPath 6>&1 | ForEach-Object { $messages.Add([string]$_) } }
            catch { $failure = $_ }
            $successMessages = @($messages | Where-Object { $_ -like '构建完成：*' }).Count
            if ($Scenario -eq 'success') {
                Assert-JobsEqual ($null -eq $failure) $true '有效产物成功返回'
                Assert-JobsEqual $state.Calls 3 '成功执行完整三个步骤'
                Assert-JobsEqual $successMessages 1 '验证产物后报告成功'
                Assert-JobsEqual ([IO.File]::Exists($state.Artifact)) $true '成功产物存在'
            } else {
                Assert-JobsEqual ($null -ne $failure) $true ($Scenario + ' 必须失败')
                Assert-JobsEqual $successMessages 0 ($Scenario + ' 不报告成功')
                $expectedCalls = 3
                if ($Scenario -like 'fail-*') {
                    $expectedCalls = [int]$Scenario.Substring(5)
                    Assert-JobsEqual ($failure.Exception.Message -match '37') $true ($Scenario + ' 保留退出码')
                }
                Assert-JobsEqual $state.Calls $expectedCalls ($Scenario + ' 停止后续步骤')
            }
        } $builder $project $scenario
    }
    Write-Host "PASS：$script:assertions 项断言；仅使用假 Python 与临时产物。"
} finally {
    Set-Location -LiteralPath $previousLocation
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
