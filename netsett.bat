<# : 2>nul
@echo off
chcp 65001 >nul
title Настройки сети

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
exit /b
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
$ProfilePath = "$env:USERPROFILE\.netman_profiles.json"

# Настройка размера окна без горизонтальной прокрутки
try {
    $ui = $Host.UI.RawUI
    $bufSize = $ui.BufferSize
    $winSize = $ui.WindowSize

    $newWidth = 110
    $newHeight = 35

    $winSize.Width = $newWidth
    $winSize.Height = $newHeight
    $bufSize.Width = $newWidth

    # Безопасное применение размеров (чтобы буфер всегда совпадал с окном)
    if ($ui.BufferSize.Width -lt $newWidth) {
        $tmp = $ui.BufferSize
        $tmp.Width = $newWidth
        $ui.BufferSize = $tmp
    }
    $ui.WindowSize = $winSize
    $ui.BufferSize = $bufSize
} catch {}

function Ensure-AdapterEnabled {
    param([string]$Alias)
    $ad = Get-NetAdapter -Name $Alias -ErrorAction SilentlyContinue
    if ($ad -and $ad.Status -eq 'Disabled') {
        Write-Host "Адаптер '$Alias' был отключен, включаем его" -ForegroundColor Cyan
        Enable-NetAdapter -Name $Alias -Confirm:$false
        Start-Sleep 2
    }
}

function Show-Status {
    Clear-Host
    Write-Host "=== Активные подключения ===" -ForegroundColor Cyan
    Write-Host "------------------------------------"
    $found = $false
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
        $found = $true
        
        $ifaceAlias = $_.InterfaceAlias
        $ad = Get-NetAdapter -Name $ifaceAlias -ErrorAction SilentlyContinue
        
        $dhcpInfo = Get-NetIPInterface -InterfaceAlias $ifaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $dhcpStr = if ($dhcpInfo.Dhcp -eq 'Enabled') { "Автоматически (DHCP)" } else { "Вручную (Статика)" }

        Write-Host "Сетевой адаптер  : $ifaceAlias" -ForegroundColor Cyan
        Write-Host "Устройство       : $($ad.InterfaceDescription)" -ForegroundColor DarkGray
        Write-Host "MAC-адрес        : $($ad.MacAddress)" -ForegroundColor DarkGray
        Write-Host "Режим работы     : $dhcpStr" -ForegroundColor Yellow
        Write-Host "Текущий IP-адрес : $($_.IPv4Address.IPAddress)" -ForegroundColor Green
        if ($_.IPv4DefaultGateway) {
            Write-Host "Шлюз         : $($_.IPv4DefaultGateway.NextHop)" -ForegroundColor Green
        } else {
            Write-Host "Шлюз         : Отсутствует" -ForegroundColor Red
        }
        Write-Host "------------------------------------"
    }
    if (-not $found) { Write-Host "Подключенных и настроенных сетей не найдено" -ForegroundColor Red }
    
    Write-Host ""
    Write-Host "=== Неактивные сети ===" -ForegroundColor Cyan
    $inactive = Get-NetAdapter | Where-Object { $_.Status -ne 'Up' -and $_.InterfaceDescription -notlike '*Loopback*' }
    if ($inactive) {
        foreach ($a in $inactive) {
            $reason = if ($a.Status -eq 'Disabled') { "Отключено" } elseif ($a.Status -eq 'Disconnected') { "Кабель не подключен" } else { $a.Status }
            Write-Host " [$($a.InterfaceAlias)] — $($a.InterfaceDescription)" -ForegroundColor DarkGray
            Write-Host "    Состояние: $reason" -ForegroundColor Red
        }
    } else {
        Write-Host " Нет отключенных адаптеров" -ForegroundColor DarkGray
    }

    Write-Host ""
    Read-Host "Нажми Enter, чтобы вернуться в меню"
}

function Get-InterfaceMenu {
    param([string]$Message)
    $adapters = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
    if ($adapters.Count -eq 0) { 
        Write-Host "Сетевых адаптеров в системе не найдено" -ForegroundColor Red
        Start-Sleep 2
        return $null 
    }
    Write-Host $Message -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $adapters.Count; $i++) { 
        $alias = $adapters[$i].InterfaceAlias
        $desc = $adapters[$i].InterfaceDescription
        $mac = $adapters[$i].MacAddress
        $status = $adapters[$i].Status
        
        $ipInfo = Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1
        $ipStr = if ($ipInfo) { $ipInfo.IPAddress } else { "Нет IP" }
        
        $dhcpInfo = Get-NetIPInterface -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $dhcpStatus = if ($dhcpInfo.Dhcp -eq 'Enabled') { "DHCP" } else { "Статика" }
        
        Write-Host "[$($i+1)] $alias " -NoNewline -ForegroundColor Cyan
        
        if ($status -eq 'Disabled') {
            Write-Host "[ОТКЛЮЧЕН]" -ForegroundColor DarkGray
            Write-Host "    Устройство : $desc" -ForegroundColor DarkGray
            Write-Host "    MAC        : $mac" -ForegroundColor DarkGray
        } elseif ($status -eq 'Disconnected') {
            Write-Host "[НЕТ КАБЕЛЯ]" -ForegroundColor Red
            Write-Host "    Устройство : $desc" -ForegroundColor DarkGray
            Write-Host "    MAC        : $mac" -ForegroundColor DarkGray
            Write-Host "    Текущий: IP: $ipStr | Режим: $dhcpStatus" -ForegroundColor DarkGray
        } else {
            Write-Host "[РАБОТАЕТ]" -ForegroundColor Green
            Write-Host "    Устройство : $desc" -ForegroundColor White
            Write-Host "    MAC        : $mac" -ForegroundColor DarkGray
            Write-Host "    Текущий: IP: $ipStr | Режим: $dhcpStatus" -ForegroundColor Yellow
        }
        Write-Host "------------------------------------------------------" -ForegroundColor DarkCyan
    }
    
    $choice = Read-Host "Введи цифру нужного адаптера (или 0 для отмены)"
    if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $adapters.Count) { 
        return $adapters[$choice-1].InterfaceAlias 
    }
    return $null
}

function Test-IPAddress { param([string]$IP); return [System.Net.IPAddress]::TryParse($IP, [ref]0) }

function Manage-Adapters {
    while ($true) {
        Clear-Host
        Write-Host "=== Включение и отключение адаптеров ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "------------------------------------------------------" -ForegroundColor DarkCyan
        
        $adapters = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            $a = $adapters[$i]
            $alias = $a.InterfaceAlias
            $desc = $a.InterfaceDescription
            $mac = $a.MacAddress
            
            Write-Host "[$($i+1)] $alias " -NoNewline -ForegroundColor Cyan
            
            if ($a.Status -eq 'Disabled') {
                Write-Host "[СЕЙЧАС ОТКЛЮЧЕН]" -ForegroundColor DarkGray
                Write-Host "    Устройство: $desc ($mac)" -ForegroundColor DarkGray
            } elseif ($a.Status -eq 'Disconnected') {
                Write-Host "[ВКЛЮЧЕН, НО НЕТ КАБЕЛЯ/СЕТИ]" -ForegroundColor Yellow
                Write-Host "    Устройство: $desc ($mac)" -ForegroundColor White
            } else {
                Write-Host "[ВКЛЮЧЕН И РАБОТАЕТ]" -ForegroundColor Green
                Write-Host "    Устройство: $desc ($mac)" -ForegroundColor White
            }
            Write-Host "------------------------------------------------------" -ForegroundColor DarkCyan
        }
        Write-Host " 0 - Вернуться назад"
        Write-Host ""
        
        $choice = Read-Host "Введи номер адаптера"
        if ($choice -eq "0") { break }
        if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $adapters.Count) {
            $target = $adapters[$choice-1]
            if ($target.Status -eq 'Disabled') {
                Write-Host "Включаем '$($target.InterfaceAlias)'" -ForegroundColor Cyan
                Enable-NetAdapter -Name $target.InterfaceAlias -Confirm:$false
            } else {
                Write-Host "Отключаем '$($target.InterfaceAlias)'" -ForegroundColor Cyan
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
            Write-Host "Удаляем старые настройки IP-адреса"
            Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        }
        Write-Host "Устанавливаем новый IP-адрес: $IPAddress (Маска: $PrefixLength)"
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -AddressFamily IPv4 -ErrorAction Stop | Out-Null
        if ($DefaultGateway -and $DefaultGateway -ne "0.0.0.0") {
            Write-Host "Устанавливаем шлюз: $DefaultGateway"
            Remove-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue
            New-NetRoute -InterfaceAlias $InterfaceAlias -DestinationPrefix "0.0.0.0/0" -NextHop $DefaultGateway -ErrorAction Stop | Out-Null
        }
        Write-Host ""
        Write-Host "Настройки успешно применены" -ForegroundColor Green
    } catch { 
        Write-Host "Произошла ошибка при настройке: $_" -ForegroundColor Red 
    }
    Write-Host ""
    Read-Host "Нажми Enter для продолжения"
}

function Manage-DHCP {
    while ($true) {
        Clear-Host
        Write-Host "=== Управление DHCP ===" -ForegroundColor Cyan
        Write-Host "1 - Включить DHCP"
        Write-Host "2 - Отключить DHCP"
        Write-Host "3 - Перезапустить DHCP"
        Write-Host ""
        Write-Host "0 - Вернуться в главное меню"
        Write-Host ""
        
        $dhcpChoice = Read-Host "Выбери действие"
        if ($dhcpChoice -eq "0") { break }
        
        if ($dhcpChoice -match '^[123]$') {
            Clear-Host
            $iface = Get-InterfaceMenu "Выбери адаптер для настройки DHCP:"
            if (-not $iface) { continue }
            
            Ensure-AdapterEnabled $iface
            Write-Host ""
            if ($dhcpChoice -eq "1") {
                Write-Host "Включаем автоматическое получение IP на '$iface'"
                Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Enabled -ErrorAction SilentlyContinue | Out-Null
                Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue | Out-Null
                Write-Host "DHCP успешно включен" -ForegroundColor Green
            }
            elseif ($dhcpChoice -eq "2") {
                Write-Host "Отключаем DHCP на '$iface'"
                Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Disabled -ErrorAction SilentlyContinue | Out-Null
                Write-Host "DHCP отключен, IP-адрес зафиксирован вручную" -ForegroundColor Green
            }
            elseif ($dhcpChoice -eq "3") {
                Write-Host "Освобождаем старый IP"
                ipconfig /release "$iface" | Out-Null
                Write-Host "Запрашиваем новый IP"
                ipconfig /renew "$iface" | Out-Null
                Write-Host "Обновление завершено" -ForegroundColor Green
            }
            
            Write-Host ""
            Read-Host "Нажми Enter для продолжения"
        } else {
            Write-Host "Неверный выбор" -ForegroundColor Red
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
    Write-Host "Профиль '$Name' успешно сохранен" -ForegroundColor Green
}

function Load-Profiles {
    if (-not (Test-Path $ProfilePath)) { 
        Write-Host "У тебя пока нет сохраненных профилей"
        Write-Host "Они появятся здесь, если ты сохранишь настройки при установке нового IP-адреса"
        Read-Host "Нажми Enter для продолжения"; return 
    }
    $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    Clear-Host
    Write-Host "=== Твои сохраненные профили ===" -ForegroundColor Cyan
    Write-Host "--------------------------------"
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        $p = $profiles[$i]
        Write-Host "[$($i+1)] $($p.Name)" -ForegroundColor Yellow
        Write-Host "    Сохраненный адаптер: $($p.Interface)"
        Write-Host "    IP-адрес: $($p.IP) (Маска: $($p.Mask))"
        if ($p.Gateway) { Write-Host "    Шлюз: $($p.Gateway)" } else { Write-Host "    Шлюз: Не указан" }
        Write-Host ""
    }
    Write-Host "--------------------------------"
    $choice = Read-Host "Введи номер профиля для применения (или 0 для отмены)"
    if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $profiles.Count) {
        $p = $profiles[$choice-1]
        Write-Host ""
        Write-Host "Ты выбрал профиль: $($p.Name)"
        $useSaved = Read-Host "Применить настройки к адаптеру '$($p.Interface)'? (Д - Да / Н - Выбрать другой адаптер вручную)"
        $targetIface = $p.Interface
        if ($useSaved -notmatch '^[YyДд]') {
            $targetIface = Get-InterfaceMenu "Выбери адаптер, к которому хочешь применить этот профиль:"
            if (-not $targetIface) { return }
        }
        $confirm = Read-Host "Применить эти настройки сейчас? (Д - Да / Н - Нет)"
        if ($confirm -match '^[YyДд]') {
            Set-StaticIP -InterfaceAlias $targetIface -IPAddress $p.IP -PrefixLength $p.Mask -DefaultGateway $p.Gateway -Mode 'Replace'
        }
    }
}

function Main-Menu {
    while ($true) {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "                       Настройка сети" -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1 - Показать текущие настройки сети"
        Write-Host "2 - Замена основного IP-адреса"
        Write-Host "3 - Оставить старый IP и добавить еще один"
        Write-Host "4 - Управление DHCP (Включить / Отключить / Обновить)"
        Write-Host "5 - Полный сброс адаптера"
        Write-Host "6 - Сохраненные профили"
        Write-Host "7 - Включение / Отключение сетевых адаптеров"
        Write-Host ""
        Write-Host "0 - Выход"
        Write-Host ""
        $choice = Read-Host "Введи номер нужного действия"
        
        switch ($choice) {
            "1" { Show-Status }
            "2" {
                Clear-Host
                Write-Host "=== Установка нового IP-адреса ===" -ForegroundColor Cyan
                $iface = Get-InterfaceMenu "Выбери адаптер, который хочешь настроить:"
                if ($iface) {
                    $ip = Read-Host "Введи IP-адрес (например 192.168.1.50)"
                    if (-not (Test-IPAddress $ip)) { Write-Host "Неверный формат IP-адреса" -ForegroundColor Red; Start-Sleep 2; continue }
                    
                    $mask = Read-Host "Введи маску подсети"
                    $gw = Read-Host "Введи IP-адрес роутера/шлюза (или просто нажми Enter, если не нужно)"
                    
                    $save = Read-Host "Сохранить эти настройки как профиль для быстрого запуска потом? (Д - Да / Н - Нет)"
                    if ($save -match '^[YyДд]') {
                        $pname = Read-Host "Придумай название для профиля (например 'BMC Сервер 1' или 'Прошивка UserGate')"
                        Save-Profile -Name $pname -Interface $iface -IP $ip -Mask $mask -Gateway $gw
                    }
                    Set-StaticIP -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -DefaultGateway $gw -Mode 'Replace'
                }
            }
            "3" {
                Clear-Host
                Write-Host "=== Добавление дополнительного IP-адреса ===" -ForegroundColor Cyan
                $iface = Get-InterfaceMenu "Выбери адаптер, к которому добавим второй IP:"
                if ($iface) {
                    Ensure-AdapterEnabled $iface
                    $ip = Read-Host "Введи дополнительный IP-адрес"
                    if (-not (Test-IPAddress $ip)) { Write-Host "Неверный формат IP-адреса" -ForegroundColor Red; Start-Sleep 2; continue }
                    
                    $mask = Read-Host "Введи маску подсети"
                    New-NetIPAddress -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -AddressFamily IPv4 -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "Дополнительный IP-адрес успешно добавлен" -ForegroundColor Green
                    Write-Host ""
                    Read-Host "Нажми Enter для продолжения"
                }
            }
            "4" { Manage-DHCP }
            "5" {
                Clear-Host
                Write-Host "=== Сброс сетевого адаптера ===" -ForegroundColor Cyan
                Write-Host ""
                $iface = Get-InterfaceMenu "Выбери адаптер для полного удаления с него всех IP-адресов:"
                if ($iface) {
                    Ensure-AdapterEnabled $iface
                    Write-Host ""
                    $confirm = Read-Host "Ты УВЕРЕН, что хочешь удалить все настройки с '$iface'? (Д - Да / Н - Нет)"
                    if ($confirm -match '^[YyДд]') {
                        Remove-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Remove-NetRoute -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Write-Host "Адаптер полностью очищен" -ForegroundColor Green
                        Write-Host ""
                        Read-Host "Нажми Enter для продолжения"
                    }
                }
            }
            "6" {
                while($true){
                    Clear-Host
                    Write-Host "=== Управление профилями ===" -ForegroundColor Cyan
                    Write-Host "1 - Загрузить и применить профиль"
                    Write-Host "0 - Вернуться в главное меню"
                    Write-Host ""
                    $sub = Read-Host "Сделай выбор"
                    if ($sub -eq "1") { Load-Profiles }
                    elseif ($sub -eq "0") { break }
                }
            }
            "7" { Manage-Adapters }
            "0" { exit }
            default { Write-Host "Неверный выбор, попробуй снова" -ForegroundColor Red; Start-Sleep 1 }
        }
    }
}

Main-Menu