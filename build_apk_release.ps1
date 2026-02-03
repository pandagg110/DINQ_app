# Release APK 构建脚本 - 包含正确的环境变量配置
# 使用方法: .\build_apk_release.ps1

param(
    [string]$gatewayUrl = "https://api.dinq.me",
    [string]$appUrl = "https://dinq.me",
    [switch]$splitPerAbi = $false
)

Write-Host "=== 构建 Release APK ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "配置信息:" -ForegroundColor Green
Write-Host "  Gateway URL: $gatewayUrl" -ForegroundColor Gray
Write-Host "  App URL: $appUrl" -ForegroundColor Gray
Write-Host ""

# 构建命令
$buildCmd = "flutter build apk --release"
$buildCmd += " --dart-define=GATEWAY_URL=$gatewayUrl"
$buildCmd += " --dart-define=APP_URL=$appUrl"

if ($splitPerAbi) {
    $buildCmd += " --split-per-abi"
    Write-Host "构建模式: 分架构 APK（文件更小）" -ForegroundColor Yellow
} else {
    Write-Host "构建模式: 完整 APK" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "执行构建命令..." -ForegroundColor Green
Write-Host "命令: $buildCmd" -ForegroundColor Gray
Write-Host ""

# 执行构建
Invoke-Expression $buildCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ 构建成功!" -ForegroundColor Green
    Write-Host ""
    
    if ($splitPerAbi) {
        Write-Host "APK 文件位置:" -ForegroundColor Cyan
        Write-Host "  - build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk" -ForegroundColor White
        Write-Host "  - build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" -ForegroundColor White
        Write-Host "  - build\app\outputs\flutter-apk\app-x86_64-release.apk" -ForegroundColor White
    } else {
        Write-Host "APK 文件位置:" -ForegroundColor Cyan
        Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "下一步:" -ForegroundColor Yellow
    Write-Host "  安装: .\install_apk.ps1" -ForegroundColor White
    Write-Host "  调试: .\debug_apk.ps1" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "✗ 构建失败!" -ForegroundColor Red
    exit 1
}
