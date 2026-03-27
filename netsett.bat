<# : 2>nul
@echo off
chcp 65001 >nul
title Network Manager

cd /d "%~dp0"
set "BAT_FILE_PATH=%~f0"

:: Проверка прав администратора
net session >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%BAT_FILE_PATH%' -Verb RunAs"
    exit /b
)

:: Запуск основного кода
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([ScriptBlock]::Create((Get-Content -LiteralPath $env:BAT_FILE_PATH -Raw -Encoding UTF8)))"

:: Предохранитель от закрытия окна при критическом сбое
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Скрипт завершил работу с системной ошибкой.
    pause
)
exit /b
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
$ProfilePath = "$env:USERPROFILE\.netman_profiles.json"

# Настройка окна без прокрутки
try {
    $ui = $Host.UI.RawUI
    $bufSize = $ui.BufferSize
    $winSize = $ui.WindowSize
    $newWidth = 110
    $newHeight = 35
    $winSize.Width = $newWidth
    $winSize.Height = $newHeight
    $bufSize.Width = $newWidth
    if ($ui.BufferSize.Width -lt $newWidth) {
        $tmp = $ui.BufferSize; $tmp.Width = $newWidth; $ui.BufferSize = $tmp
    }
    $ui.WindowSize = $winSize
    $ui.BufferSize = $bufSize
} catch {}

# --- Автоматическое определение языка системы ---
$global:Lang = "EN"
if ((Get-UICulture).TwoLetterISOLanguageName -eq "ru" -or (Get-Culture).TwoLetterISOLanguageName -eq "ru") {
    $global:Lang = "RU"
}

$global:EnDict = @{
    "Настройка сети" = "Network Configuration"
    "=== Активные подключения ===" = "=== Active Connections ==="
    "Автоматически (DHCP)" = "Automatic (DHCP)"
    "Вручную (Статика)" = "Manual (Static)"
    "Сетевой адаптер" = "Network Adapter"
    "Устройство" = "Device Hardware"
    "MAC-адрес" = "MAC Address"
    "Режим работы" = "Operating Mode"
    "Текущий IP-адрес" = "Current IP Address"
    "Шлюз" = "Default Gateway"
    "Отсутствует" = "None"
    "Подключенных и настроенных сетей не найдено" = "No connected and configured networks found"
    "=== Неактивные сети ===" = "=== Inactive Networks ==="
    "Отключено" = "Disabled"
    "Кабель не подключен" = "Cable disconnected"
    "Состояние" = "Status"
    "Нет отключенных адаптеров" = "No disabled adapters found"
    "Нажми любую клавишу, чтобы вернуться в меню" = "Press any key to return to the menu"
    "Сетевых адаптеров в системе не найдено" = "No network adapters found in the system"
    "Нет IP" = "No IP"
    "Статика" = "Static"
    "ОТКЛЮЧЕН" = "DISABLED"
    "НЕТ КАБЕЛЯ" = "NO CABLE"
    "РАБОТАЕТ" = "WORKING"
    "Введи цифру нужного адаптера (1-9, или 0 для отмены)" = "Press adapter number (1-9, or 0 to cancel)"
    "=== Включение и отключение адаптеров ===" = "=== Enable and Disable Adapters ==="
    "СЕЙЧАС ОТКЛЮЧЕН" = "CURRENTLY DISABLED"
    "ВКЛЮЧЕН, НО НЕТ КАБЕЛЯ/СЕТИ" = "ENABLED BUT NO CABLE/NETWORK"
    "ВКЛЮЧЕН И РАБОТАЕТ" = "ENABLED AND WORKING"
    "0 - Вернуться назад" = "0 - Go back"
    "Введи номер адаптера (1-9, или 0 для выхода)" = "Press adapter number (1-9, or 0 to go back)"
    "Включаем адаптер" = "Enabling adapter"
    "Отключаем адаптер" = "Disabling adapter"
    "Удаляем старые настройки IP-адреса" = "Removing old IP address settings"
    "Устанавливаем новый IP-адрес" = "Setting new IP address"
    "Маска" = "Mask"
    "Устанавливаем шлюз" = "Setting gateway"
    "Настройки успешно применены" = "Settings successfully applied"
    "Произошла ошибка при настройке" = "An error occurred during configuration"
    "Нажми любую клавишу для продолжения" = "Press any key to continue"
    "=== Управление DHCP ===" = "=== Manage DHCP ==="
    "1 - Включить DHCP" = "1 - Enable DHCP"
    "2 - Отключить DHCP" = "2 - Disable DHCP"
    "3 - Перезапустить DHCP" = "3 - Renew DHCP"
    "0 - Вернуться в главное меню" = "0 - Return to main menu"
    "Выбери действие" = "Choose an action"
    "Выбери адаптер для настройки DHCP:" = "Select adapter for DHCP configuration:"
    "Включаем автоматическое получение IP на" = "Enabling automatic IP retrieval on"
    "DHCP успешно включен" = "DHCP successfully enabled"
    "Отключаем DHCP на" = "Disabling DHCP on"
    "DHCP отключен, IP-адрес зафиксирован вручную" = "DHCP disabled, IP address is now static"
    "Освобождаем старый IP" = "Releasing old IP"
    "Запрашиваем новый IP" = "Renewing IP address"
    "Обновление завершено" = "Renewal complete"
    "Неверный выбор" = "Invalid choice"
    "Профиль успешно сохранен" = "Profile successfully saved"
    "У тебя пока нет сохраненных профилей" = "You don't have any saved profiles yet"
    "Они появятся здесь, если ты сохранишь настройки при установке нового IP-адреса" = "They will appear here if you save settings when applying a new IP"
    "=== Твои сохраненные профили ===" = "=== Your Saved Profiles ==="
    "Сохраненный адаптер" = "Saved adapter"
    "Не указан" = "Not specified"
    "Введи номер профиля (1-9, или 0 для отмены)" = "Press profile number (1-9, or 0 to cancel)"
    "Ты выбрал профиль" = "You selected profile"
    "Применить настройки к адаптеру" = "Apply settings to adapter"
    "Д - Да / Н - Выбрать другой адаптер вручную" = "Y - Yes / N - Select another adapter manually"
    "Выбери адаптер, к которому хочешь применить этот профиль:" = "Select the adapter to apply this profile to:"
    "Применить эти настройки сейчас? (Д - Да / Н - Нет)" = "Apply these settings now? (Y - Yes / N - No)"
    "1 - Показать текущие настройки сети" = "1 - Show current network settings"
    "2 - Замена основного IP-адреса" = "2 - Change primary IP address"
    "3 - Оставить старый IP и добавить еще один" = "3 - Add secondary IP address"
    "4 - Управление DHCP (Включить / Отключить / Обновить)" = "4 - Manage DHCP (Enable / Disable / Renew)"
    "5 - Полный сброс адаптера" = "5 - Full adapter reset"
    "6 - Сохраненные профили" = "6 - Saved profiles"
    "7 - Включение / Отключение сетевых адаптеров" = "7 - Enable / Disable network adapters"
    "0 - Выход" = "0 - Exit"
    "Введи номер нужного действия" = "Press the number of the desired action"
    "=== Установка нового IP-адреса ===" = "=== Set New IP Address ==="
    "Выбери адаптер, который хочешь настроить:" = "Select the adapter you want to configure:"
    "Введи IP-адрес (например 192.168.1.50)" = "Enter IP address (e.g. 192.168.1.50)"
    "Введи дополнительный IP-адрес" = "Enter secondary IP address"
    "Неверный формат IP-адреса" = "Invalid IP address format"
    "Введи маску подсети" = "Enter subnet mask (e.g. 24)"
    "Введи IP-адрес роутера/шлюза (или просто нажми Enter, если не нужно)" = "Enter Gateway IP (or press Enter to skip)"
    "Сохранить эти настройки как профиль для быстрого запуска потом? (Д - Да / Н - Нет)" = "Save these settings as a profile? (Y - Yes / N - No)"
    "Придумай название для профиля (например 'BMC Сервер 1' или 'Прошивка UserGate')" = "Enter a name for the profile (e.g. 'Office' or 'Router config')"
    "=== Добавление дополнительного IP-адреса ===" = "=== Add Secondary IP Address ==="
    "Выбери адаптер, к которому добавим второй IP:" = "Select adapter to add secondary IP:"
    "Дополнительный IP-адрес успешно добавлен" = "Secondary IP address successfully added"
    "=== Сброс сетевого адаптера ===" = "=== Reset Network Adapter ==="
    "Выбери адаптер для полного удаления с него всех IP-адресов:" = "Select adapter to remove all IP settings:"
    "Ты УВЕРЕН, что хочешь удалить все настройки с" = "Are you SURE you want to clear all settings from"
    "Адаптер полностью очищен" = "Adapter settings cleared successfully"
    "=== Управление профилями ===" = "=== Manage Profiles ==="
    "1 - Загрузить и применить профиль" = "1 - Load and apply a profile"
    "Неверный выбор, попробуй снова" = "Invalid choice, try again"
    "Адаптер был отключен, включаем его" = "Adapter was disabled, enabling it"
}

function L([string]$text) {
    if ($global:Lang -eq "EN" -and $global:EnDict.ContainsKey($text)) { return $global:EnDict[$text] }
    return $text
}

# БЕЗОПАСНАЯ функция для мгновенного чтения одной клавиши (без Enter)
function Get-SingleKey([string]$PromptMsg) {
    Write-Host "$($PromptMsg): " -NoNewline -ForegroundColor Cyan
    try {
        $char = [System.Console]::ReadKey($true).KeyChar
        Write-Host $char -ForegroundColor Yellow
        return [string]$char
    } catch {
        $val = Read-Host
        return $val
    }
}

# БЕЗОПАСНАЯ функция для ожидания любой кнопки
function Wait-AnyKey([string]$PromptMsg) {
    Write-Host "`n$($PromptMsg)" -ForegroundColor Cyan
    try {
        [System.Console]::ReadKey($true) | Out-Null
    } catch {
        Read-Host | Out-Null
    }
}

function Ensure-AdapterEnabled {
    param([string]$Alias)
    $ad = Get-NetAdapter -Name $Alias -ErrorAction SilentlyContinue
    if ($ad -and $ad.Status -eq 'Disabled') {
        Write-Host "$(L 'Адаптер был отключен, включаем его'): '$Alias'" -ForegroundColor Cyan
        Enable-NetAdapter -Name $Alias -Confirm:$false
        Start-Sleep 2
    }
}

function Show-Status {
    Clear-Host
    Write-Host (L "=== Активные подключения ===") -ForegroundColor Cyan
    Write-Host "------------------------------------"
    $found = $false
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
        $found = $true
        
        $ifaceAlias = $_.InterfaceAlias
        $ad = Get-NetAdapter -Name $ifaceAlias -ErrorAction SilentlyContinue
        
        $dhcpInfo = Get-NetIPInterface -InterfaceAlias $ifaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $dhcpStr = if ($dhcpInfo.Dhcp -eq 'Enabled') { L "Автоматически (DHCP)" } else { L "Вручную (Статика)" }

        Write-Host "$(L 'Сетевой адаптер')  : $ifaceAlias" -ForegroundColor Cyan
        Write-Host "$(L 'Устройство')       : $($ad.InterfaceDescription)" -ForegroundColor DarkGray
        Write-Host "$(L 'MAC-адрес')        : $($ad.MacAddress)" -ForegroundColor DarkGray
        Write-Host "$(L 'Режим работы')     : $dhcpStr" -ForegroundColor Yellow
        Write-Host "$(L 'Текущий IP-адрес') : $($_.IPv4Address.IPAddress)" -ForegroundColor Green
        if ($_.IPv4DefaultGateway) {
            Write-Host "$(L 'Шлюз')             : $($_.IPv4DefaultGateway.NextHop)" -ForegroundColor Green
        } else {
            Write-Host "$(L 'Шлюз')             : $(L 'Отсутствует')" -ForegroundColor Red
        }
        Write-Host "------------------------------------"
    }
    if (-not $found) { Write-Host (L "Подключенных и настроенных сетей не найдено") -ForegroundColor Red }
    
    Write-Host ""
    Write-Host (L "=== Неактивные сети ===") -ForegroundColor Cyan
    $inactive = Get-NetAdapter | Where-Object { $_.Status -ne 'Up' -and $_.InterfaceDescription -notlike '*Loopback*' }
    if ($inactive) {
        foreach ($a in $inactive) {
            $reason = if ($a.Status -eq 'Disabled') { L "Отключено" } elseif ($a.Status -eq 'Disconnected') { L "Кабель не подключен" } else { $a.Status }
            Write-Host " [$($a.InterfaceAlias)] — $($a.InterfaceDescription)" -ForegroundColor DarkGray
            Write-Host "    $(L 'Состояние'): $reason" -ForegroundColor Red
        }
    } else {
        Write-Host " $(L 'Нет отключенных адаптеров')" -ForegroundColor DarkGray
    }

    Wait-AnyKey (L "Нажми любую клавишу, чтобы вернуться в меню")
}

function Get-InterfaceMenu {
    param([string]$Message)
    $adapters = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
    if ($adapters.Count -eq 0) { 
        Write-Host (L "Сетевых адаптеров в системе не найдено") -ForegroundColor Red
        Start-Sleep 2
        return $null 
    }
    Write-Host (L $Message) -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $adapters.Count; $i++) { 
        if ($i -ge 9) { break } # Ограничение до 9 пунктов для моментального выбора
        $alias = $adapters[$i].InterfaceAlias
        $desc = $adapters[$i].InterfaceDescription
        $mac = $adapters[$i].MacAddress
        $status = $adapters[$i].Status
        
        $ipInfo = Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1
        $ipStr = if ($ipInfo) { $ipInfo.IPAddress } else { L "Нет IP" }
        
        $dhcpInfo = Get-NetIPInterface -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $dhcpStatus = if ($dhcpInfo.Dhcp -eq 'Enabled') { "DHCP" } else { L "Статика" }
        
        Write-Host "[$($i+1)] $alias " -NoNewline -ForegroundColor Cyan
        
        if ($status -eq 'Disabled') {
            Write-Host "[$(L 'ОТКЛЮЧЕН')]" -ForegroundColor DarkGray
            Write-Host "    $(L 'Устройство') : $desc" -ForegroundColor DarkGray
            Write-Host "    MAC        : $mac" -ForegroundColor DarkGray
        } elseif ($status -eq 'Disconnected') {
            Write-Host "[$(L 'НЕТ КАБЕЛЯ')]" -ForegroundColor Red
            Write-Host "    $(L 'Устройство') : $desc" -ForegroundColor DarkGray
            Write-Host "    MAC        : $mac" -ForegroundColor DarkGray
            Write-Host "    IP: $ipStr | Mode: $dhcpStatus" -ForegroundColor DarkGray
        } else {
            Write-Host "[$(L 'РАБОТАЕТ')]" -ForegroundColor Green
            Write-Host "    $(L 'Устройство') : $desc" -ForegroundColor White
            Write-Host "    MAC        : $mac" -ForegroundColor DarkGray
            Write-Host "    IP: $ipStr | Mode: $dhcpStatus" -ForegroundColor Yellow
        }
        Write-Host "------------------------------------------------------" -ForegroundColor DarkCyan
    }
    
    Write-Host ""
    $choice = Get-SingleKey (L "Введи цифру нужного адаптера (1-9, или 0 для отмены)")
    Write-Host ""
    if ($choice -eq "0") { return $null }
    if ($choice -match '^[1-9]$' -and [int]$choice -le $adapters.Count) { 
        return $adapters[[int]$choice-1].InterfaceAlias 
    }
    return $null
}

function Test-IPAddress { param([string]$IP); return [System.Net.IPAddress]::TryParse($IP, [ref]0) }

function Manage-Adapters {
    while ($true) {
        Clear-Host
        Write-Host (L "=== Включение и отключение адаптеров ===") -ForegroundColor Cyan
        Write-Host ""
        Write-Host "------------------------------------------------------" -ForegroundColor DarkCyan
        
        $adapters = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            if ($i -ge 9) { break }
            $a = $adapters[$i]
            $alias = $a.InterfaceAlias
            $desc = $a.InterfaceDescription
            $mac = $a.MacAddress
            
            Write-Host "[$($i+1)] $alias " -NoNewline -ForegroundColor Cyan
            
            if ($a.Status -eq 'Disabled') {
                Write-Host "[$(L 'СЕЙЧАС ОТКЛЮЧЕН')]" -ForegroundColor DarkGray
                Write-Host "    $(L 'Устройство'): $desc ($mac)" -ForegroundColor DarkGray
            } elseif ($a.Status -eq 'Disconnected') {
                Write-Host "[$(L 'ВКЛЮЧЕН, НО НЕТ КАБЕЛЯ/СЕТИ')]" -ForegroundColor Yellow
                Write-Host "    $(L 'Устройство'): $desc ($mac)" -ForegroundColor White
            } else {
                Write-Host "[$(L 'ВКЛЮЧЕН И РАБОТАЕТ')]" -ForegroundColor Green
                Write-Host "    $(L 'Устройство'): $desc ($mac)" -ForegroundColor White
            }
            Write-Host "------------------------------------------------------" -ForegroundColor DarkCyan
        }
        Write-Host (" " + (L "0 - Вернуться назад"))
        Write-Host ""
        
        $choice = Get-SingleKey (L "Введи номер адаптера (1-9, или 0 для выхода)")
        Write-Host ""
        if ($choice -eq "0") { break }
        if ($choice -match '^[1-9]$' -and [int]$choice -le $adapters.Count) {
            $target = $adapters[[int]$choice-1]
            if ($target.Status -eq 'Disabled') {
                Write-Host "$(L 'Включаем адаптер') '$($target.InterfaceAlias)'" -ForegroundColor Cyan
                Enable-NetAdapter -Name $target.InterfaceAlias -Confirm:$false
            } else {
                Write-Host "$(L 'Отключаем адаптер') '$($target.InterfaceAlias)'" -ForegroundColor Cyan
                Disable-NetAdapter -Name $target.InterfaceAlias -Confirm:$false
            }
            Start-Sleep 2
        }
    }
}

function Set-StaticIP {
    param([string]$InterfaceAlias, [string]$IPAddress, [string]$PrefixLength, [string]$DefaultGateway, [string]$Mode)
    Ensure-AdapterEnabled $InterfaceAlias
    try {
        if ($Mode -eq 'Replace') {
            Write-Host (L "Удаляем старые настройки IP-адреса")
            Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        }
        Write-Host "$(L 'Устанавливаем новый IP-адрес'): $IPAddress ($(L 'Маска'): $PrefixLength)"
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -AddressFamily IPv4 -ErrorAction Stop | Out-Null
        if ($DefaultGateway -and $DefaultGateway -ne "0.0.0.0") {
            Write-Host "$(L 'Устанавливаем шлюз'): $DefaultGateway"
            Remove-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue
            New-NetRoute -InterfaceAlias $InterfaceAlias -DestinationPrefix "0.0.0.0/0" -NextHop $DefaultGateway -ErrorAction Stop | Out-Null
        }
        Write-Host ""
        Write-Host (L "Настройки успешно применены") -ForegroundColor Green
    } catch { 
        Write-Host "$(L 'Произошла ошибка при настройке'): $_" -ForegroundColor Red 
    }
    Wait-AnyKey (L "Нажми любую клавишу для продолжения")
}

function Manage-DHCP {
    while ($true) {
        Clear-Host
        Write-Host (L "=== Управление DHCP ===") -ForegroundColor Cyan
        Write-Host (L "1 - Включить DHCP")
        Write-Host (L "2 - Отключить DHCP")
        Write-Host (L "3 - Перезапустить DHCP")
        Write-Host ""
        Write-Host (L "0 - Вернуться в главное меню")
        Write-Host ""
        
        $dhcpChoice = Get-SingleKey (L "Выбери действие")
        Write-Host ""
        if ($dhcpChoice -eq "0") { break }
        
        if ($dhcpChoice -match '^[123]$') {
            Clear-Host
            $iface = Get-InterfaceMenu "Выбери адаптер для настройки DHCP:"
            if (-not $iface) { continue }
            
            Ensure-AdapterEnabled $iface
            Write-Host ""
            if ($dhcpChoice -eq "1") {
                Write-Host "$(L 'Включаем автоматическое получение IP на') '$iface'"
                Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Enabled -ErrorAction SilentlyContinue | Out-Null
                Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue | Out-Null
                Write-Host (L "DHCP успешно включен") -ForegroundColor Green
            }
            elseif ($dhcpChoice -eq "2") {
                Write-Host "$(L 'Отключаем DHCP на') '$iface'"
                Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Disabled -ErrorAction SilentlyContinue | Out-Null
                Write-Host (L "DHCP отключен, IP-адрес зафиксирован вручную") -ForegroundColor Green
            }
            elseif ($dhcpChoice -eq "3") {
                Write-Host (L "Освобождаем старый IP")
                ipconfig /release "$iface" | Out-Null
                Write-Host (L "Запрашиваем новый IP")
                ipconfig /renew "$iface" | Out-Null
                Write-Host (L "Обновление завершено") -ForegroundColor Green
            }
            
            Wait-AnyKey (L "Нажми любую клавишу для продолжения")
        } else {
            Write-Host (L "Неверный выбор") -ForegroundColor Red
            Start-Sleep 1
        }
    }
}

function Save-Profile {
    param([string]$Name, [string]$Interface, [string]$IP, [string]$Mask, [string]$Gateway)
    $profile = @{Name=$Name; Interface=$Interface; IP=$IP; Mask=$Mask; Gateway=$Gateway}
    $profiles = @()
    if (Test-Path $ProfilePath) { $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json }
    $profiles += $profile
    $profiles | ConvertTo-Json | Set-Content $ProfilePath -Encoding UTF8
    Write-Host "$(L 'Профиль успешно сохранен'): $Name" -ForegroundColor Green
}

function Load-Profiles {
    if (-not (Test-Path $ProfilePath)) { 
        Write-Host (L "У тебя пока нет сохраненных профилей")
        Write-Host (L "Они появятся здесь, если ты сохранишь настройки при установке нового IP-адреса")
        Wait-AnyKey (L "Нажми любую клавишу для продолжения"); return 
    }
    $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    Clear-Host
    Write-Host (L "=== Твои сохраненные профили ===") -ForegroundColor Cyan
    Write-Host "--------------------------------"
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        if ($i -ge 9) { break }
        $p = $profiles[$i]
        Write-Host "[$($i+1)] $($p.Name)" -ForegroundColor Yellow
        Write-Host "    $(L 'Сохраненный адаптер'): $($p.Interface)"
        Write-Host "    IP: $($p.IP) ($(L 'Маска'): $($p.Mask))"
        if ($p.Gateway) { Write-Host "    $(L 'Шлюз'): $($p.Gateway)" } else { Write-Host "    $(L 'Шлюз'): $(L 'Не указан')" }
        Write-Host ""
    }
    Write-Host "--------------------------------"
    $choice = Get-SingleKey (L "Введи номер профиля (1-9, или 0 для отмены)")
    Write-Host ""
    if ($choice -eq "0") { return }
    if ($choice -match '^[1-9]$' -and [int]$choice -le $profiles.Count) {
        $p = $profiles[[int]$choice-1]
        Write-Host ""
        Write-Host "$(L 'Ты выбрал профиль'): $($p.Name)"
        $useSaved = Get-SingleKey "$(L 'Применить настройки к адаптеру') '$($p.Interface)'? ($(L 'Д - Да / Н - Выбрать другой адаптер вручную'))"
        Write-Host ""
        $targetIface = $p.Interface
        if ($useSaved -notmatch '^[YyДд]') {
            $targetIface = Get-InterfaceMenu "Выбери адаптер, к которому хочешь применить этот профиль:"
            if (-not $targetIface) { return }
        }
        $confirm = Get-SingleKey (L "Применить эти настройки сейчас? (Д - Да / Н - Нет)")
        Write-Host ""
        if ($confirm -match '^[YyДд]') {
            Set-StaticIP -InterfaceAlias $targetIface -IPAddress $p.IP -PrefixLength $p.Mask -DefaultGateway $p.Gateway -Mode 'Replace'
        }
    }
}

function Main-Menu {
    while ($true) {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "                   $(L 'Настройка сети')" -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (L "1 - Показать текущие настройки сети")
        Write-Host (L "2 - Замена основного IP-адреса")
        Write-Host (L "3 - Оставить старый IP и добавить еще один")
        Write-Host (L "4 - Управление DHCP (Включить / Отключить / Обновить)")
        Write-Host (L "5 - Полный сброс адаптера")
        Write-Host (L "6 - Сохраненные профили")
        Write-Host (L "7 - Включение / Отключение сетевых адаптеров")
        Write-Host ""
        Write-Host (L "0 - Выход")
        Write-Host ""
        
        $choice = Get-SingleKey (L "Введи номер нужного действия")
        Write-Host ""
        
        switch ($choice) {
            "1" { Show-Status }
            "2" {
                Clear-Host
                Write-Host (L "=== Установка нового IP-адреса ===") -ForegroundColor Cyan
                $iface = Get-InterfaceMenu "Выбери адаптер, который хочешь настроить:"
                if ($iface) {
                    $ip = Read-Host (L "Введи IP-адрес (например 192.168.1.50)")
                    if (-not (Test-IPAddress $ip)) { Write-Host (L "Неверный формат IP-адреса") -ForegroundColor Red; Start-Sleep 2; continue }
                    
                    $mask = Read-Host (L "Введи маску подсети")
                    $gw = Read-Host (L "Введи IP-адрес роутера/шлюза (или просто нажми Enter, если не нужно)")
                    
                    $save = Get-SingleKey (L "Сохранить эти настройки как профиль для быстрого запуска потом? (Д - Да / Н - Нет)")
                    Write-Host ""
                    if ($save -match '^[YyДд]') {
                        $pname = Read-Host (L "Придумай название для профиля (например 'BMC Сервер 1' или 'Прошивка UserGate')")
                        Save-Profile -Name $pname -Interface $iface -IP $ip -Mask $mask -Gateway $gw
                    }
                    Set-StaticIP -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -DefaultGateway $gw -Mode 'Replace'
                }
            }
            "3" {
                Clear-Host
                Write-Host (L "=== Добавление дополнительного IP-адреса ===") -ForegroundColor Cyan
                $iface = Get-InterfaceMenu "Выбери адаптер, к которому добавим второй IP:"
                if ($iface) {
                    Ensure-AdapterEnabled $iface
                    $ip = Read-Host (L "Введи дополнительный IP-адрес")
                    if (-not (Test-IPAddress $ip)) { Write-Host (L "Неверный формат IP-адреса") -ForegroundColor Red; Start-Sleep 2; continue }
                    
                    $mask = Read-Host (L "Введи маску подсети")
                    New-NetIPAddress -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -AddressFamily IPv4 -ErrorAction SilentlyContinue | Out-Null
                    Write-Host (L "Дополнительный IP-адрес успешно добавлен") -ForegroundColor Green
                    Wait-AnyKey (L "Нажми любую клавишу для продолжения")
                }
            }
            "4" { Manage-DHCP }
            "5" {
                Clear-Host
                Write-Host (L "=== Сброс сетевого адаптера ===") -ForegroundColor Cyan
                Write-Host ""
                $iface = Get-InterfaceMenu "Выбери адаптер для полного удаления с него всех IP-адресов:"
                if ($iface) {
                    Ensure-AdapterEnabled $iface
                    Write-Host ""
                    $confirm = Get-SingleKey "$(L 'Ты УВЕРЕН, что хочешь удалить все настройки с') '$iface'? ($(L 'Д - Да / Н - Нет'))"
                    Write-Host ""
                    if ($confirm -match '^[YyДд]') {
                        Remove-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Remove-NetRoute -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Write-Host (L "Адаптер полностью очищен") -ForegroundColor Green
                        Wait-AnyKey (L "Нажми любую клавишу для продолжения")
                    }
                }
            }
            "6" {
                while($true){
                    Clear-Host
                    Write-Host (L "=== Управление профилями ===") -ForegroundColor Cyan
                    Write-Host (L "1 - Загрузить и применить профиль")
                    Write-Host (L "0 - Вернуться в главное меню")
                    Write-Host ""
                    $sub = Get-SingleKey (L "Выбери действие")
                    Write-Host ""
                    if ($sub -eq "1") { Load-Profiles }
                    elseif ($sub -eq "0") { break }
                }
            }
            "7" { Manage-Adapters }
            "0" { exit }
            default { Write-Host "" ; Write-Host (L "Неверный выбор, попробуй снова") -ForegroundColor Red; Start-Sleep 1 }
        }
    }
}

try {
    Main-Menu
} catch {
    Write-Host "`n[КРИТИЧЕСКАЯ ОШИБКА / CRITICAL ERROR]" -ForegroundColor White -BackgroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-AnyKey "Нажми любую клавишу для выхода / Press any key to exit"
}
