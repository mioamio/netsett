<# : 2>nul
@echo off
chcp 65001 >nul
title netsett++

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

:: Предохранитель от закрытия окна при сбое
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Скрипт завершил работу с системной ошибкой
    pause
)
exit /b
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
$ProfilePath = "$env:USERPROFILE\.netman_profiles.json"

$FontSize = 22

try {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class ConsoleHelper {
        [StructLayout(LayoutKind.Sequential)]
        public struct CONSOLE_FONT_INFO_EX {
            public uint cbSize;
            public uint nFont;
            public short dwFontSizeX;
            public short dwFontSizeY;
            public int FontFamily;
            public int FontWeight;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
            public string FaceName;
        }
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr GetStdHandle(int nStdHandle);
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
        
        public static void SetFontSize(short y) {
            IntPtr hnd = GetStdHandle(-11);
            CONSOLE_FONT_INFO_EX info = new CONSOLE_FONT_INFO_EX();
            info.cbSize = (uint)Marshal.SizeOf(info);
            if(GetCurrentConsoleFontEx(hnd, false, ref info)) {
                info.dwFontSizeY = y;
                SetCurrentConsoleFontEx(hnd, false, ref info);
            }
        }
    }
"@ -ErrorAction SilentlyContinue
    [ConsoleHelper]::SetFontSize($FontSize)
} catch {}

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

# --- Словарь ---
$global:Lang = "EN"
if ((Get-UICulture).TwoLetterISOLanguageName -eq "ru" -or (Get-Culture).TwoLetterISOLanguageName -eq "ru") {
    $global:Lang = "RU"
}

$global:EnDict = @{
    "netsett++" = "netsett++"
    "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Войти | [ВЛЕВО] Назад" = "[UP/DOWN] Select | [RIGHT] Enter | [LEFT] Back"
    "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Включить | [ВЛЕВО] Отключить | [ESC] Назад" = "[UP/DOWN] Select | [RIGHT] Enable | [LEFT] Disable | [ESC] Back"
    "[ВЛЕВО] Назад" = "[LEFT] Go Back"
    "Назад" = "Back"
    "Да" = "Yes"
    "Нет" = "No"
    "Выход" = "Exit"
    "Показать текущие настройки сети" = "Show current network settings"
    "Замена основного IP-адреса" = "Change primary IP address"
    "Оставить старый IP и добавить еще один" = "Add secondary IP address"
    "Управление DHCP (Включить / Отключить / Обновить)" = "Manage DHCP (Enable / Disable / Renew)"
    "Полный сброс адаптера" = "Full adapter reset"
    "Сохраненные профили" = "Saved profiles"
    "Включение / Отключение сетевых адаптеров" = "Enable / Disable network adapters"
    "Управление Wi-Fi (Поиск и подключение)" = "Wi-Fi Management (Search & Connect)"
    "Подмена MAC-адреса адаптера (Spoofing)" = "MAC Address Spoofing"
    "LAN Сканер (Поиск устройств в сети)" = "LAN Scanner (Network discovery)"
    "ОТКЛЮЧЕН" = "DISABLED"
    "НЕТ КАБЕЛЯ" = "NO CABLE"
    "РАБОТАЕТ" = "WORKING"
    "Автоматически (DHCP)" = "Automatic (DHCP)"
    "Вручную (Статика)" = "Manual (Static)"
    "Шлюз" = "Default Gateway"
    "Отсутствует" = "None"
    "Текущий IP-адрес" = "Current IP Address"
    "Сетевой адаптер" = "Network Adapter"
    "Устройство" = "Device Hardware"
    "Режим работы" = "Operating Mode"
    "Сетевых адаптеров в системе не найдено" = "No network adapters found in the system"
    "Выбери адаптер:" = "Select an adapter:"
    "Включаем адаптер" = "Enabling adapter"
    "Отключаем адаптер" = "Disabling adapter"
    "Введи IP-адрес (например 192.168.1.50)" = "Enter IP address (e.g. 192.168.1.50)"
    "Введи маску подсети" = "Enter subnet mask (e.g. 24)"
    "Введи IP-адрес роутера/шлюза (Enter - пропустить)" = "Enter Gateway IP (Enter to skip)"
    "Сохранить эти настройки как профиль?" = "Save these settings as a profile?"
    "Придумай название для профиля" = "Enter a name for the profile"
    "Устанавливаем новый IP-адрес" = "Setting new IP address"
    "Настройки успешно применены" = "Settings successfully applied"
    "Адаптер полностью очищен" = "Adapter settings cleared successfully"
    "Ты УВЕРЕН, что хочешь удалить все настройки?" = "Are you SURE you want to clear all settings?"
    "Включить DHCP" = "Enable DHCP"
    "Отключить DHCP" = "Disable DHCP"
    "Перезапустить DHCP" = "Renew DHCP"
    "Показать доступные сети вокруг" = "Show available networks"
    "Подключиться к сохраненной сети" = "Connect to saved network"
    "Введи пароль от сети (или нажми Enter, если без пароля)" = "Enter network password (or press Enter if open)"
    "Создаем новый профиль сети..." = "Creating new network profile..."
    "Успешно!" = "Success!"
    "Ввести новый MAC вручную" = "Enter new MAC manually"
    "Сгенерировать случайный MAC" = "Generate random MAC"
    "Вернуть родной заводской MAC" = "Restore original hardware MAC"
    "Сканируем локальную сеть: " = "Scanning local network: "
    "Определение имен устройств..." = "Resolving hostnames..."
    "Пожалуйста, подожди пару секунд..." = "Please wait a few seconds..."
    "=== Найденные устройства ===" = "=== Found Devices ==="
    "=== Активные подключения ===" = "=== Active Connections ==="
    "=== Неактивные сети ===" = "=== Inactive Networks ==="
    "Отключено" = "Disabled"
    "Кабель не подключен" = "Cable disconnected"
    "Состояние" = "Status"
    "Нет отключенных адаптеров" = "No disabled adapters found"
    "IP-адрес" = "IP Address"
    "MAC-адрес" = "MAC Address"
    "Имя в сети" = "Hostname"
    "Тип/Инфо" = "Device Type/Info"
    "Этот компьютер" = "This PC"
    "Роутер / Точка доступа" = "Router / Access Point"
    "Смартфон / Планшет (Случайный MAC)" = "Smartphone / Tablet (Private MAC)"
    "Принтер" = "Printer"
    "Неизвестное устройство" = "Unknown Device"
    "Адаптер не имеет действительного IP-адреса для сканирования." = "Adapter does not have a valid IP for scanning."
    "Загрузить и применить профиль" = "Load and apply a profile"
    "Эта сеть уже сохранена, подключаемся..." = "This network is already saved, connecting..."
}

function L([string]$text) {
    if ($global:Lang -eq "EN" -and $global:EnDict.ContainsKey($text)) { return $global:EnDict[$text] }
    return $text
}

# --- Ядро: Умное Интерактивное Меню ---
function Show-Menu {
    param(
        [string]$Title, 
        [array]$Items, 
        [switch]$IsToggleMenu,
        [int]$DefaultIndex = 0
    )
    $selected = $DefaultIndex
    if ($selected -ge $Items.Count -or $selected -lt 0) { $selected = 0 }

    try { [Console]::CursorVisible = $false } catch {}
    
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   $Title" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    if ($IsToggleMenu) {
        Write-Host " $(L '[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Включить | [ВЛЕВО] Отключить | [ESC] Назад')" -ForegroundColor DarkGray
    } else {
        Write-Host " $(L '[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Войти | [ВЛЕВО] Назад')" -ForegroundColor DarkGray
    }
    Write-Host ""

    $startY = [Console]::CursorTop
    $maxWidth = 80

    while ($true) {
        [Console]::SetCursorPosition(0, $startY)
        
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $isBackAction = ($Items[$i].Value -eq 'BACK' -or $Items[$i].Value -eq 0)
            
            $prefix = "    "
            $fg = "Gray"
            $bg = "Black"
            
            if ($i -eq $selected) {
                # Стрелка влево для кнопок возврата/выхода
                if ($isBackAction) { $prefix = "  < " } else { $prefix = "  > " }
                $fg = "Black"
                $bg = "Cyan"
            }
            
            $text = "$prefix$($Items[$i].Name) "
            
            # Печатаем выделенную строчку
            Write-Host $text -ForegroundColor $fg -BackgroundColor $bg -NoNewline
            
            # Закрашиваем остаток строки черным (убираем хвосты)
            $padLen = $maxWidth - $text.Length
            if ($padLen -gt 0) {
                Write-Host (" " * $padLen) -ForegroundColor Black -BackgroundColor Black
            } else {
                Write-Host ""
            }
        }
        
        $keyInfo = [System.Console]::ReadKey($true)
        $key = $keyInfo.Key
        
        if ($key -eq 'UpArrow') {
            $selected = ($selected - 1 + $Items.Count) % $Items.Count
        } elseif ($key -eq 'DownArrow') {
            $selected = ($selected + 1) % $Items.Count
        } elseif ($key -eq 'RightArrow' -or $key -eq 'Enter') {
            $val = $Items[$selected].Value
            if ($val -eq 'BACK' -or $val -eq 0) { 
                return @{ Action = 'Back'; Value = $val; Index = $selected } 
            }
            if ($IsToggleMenu) { 
                return @{ Action = 'Enable'; Value = $val; Index = $selected } 
            } 
            return @{ Action = 'Enter'; Value = $val; Index = $selected }
            
        } elseif ($key -eq 'LeftArrow' -or $key -eq 'Escape' -or $key -eq 'Backspace') {
            $val = $Items[$selected].Value
            if ($IsToggleMenu -and $key -eq 'LeftArrow' -and $val -ne 'BACK' -and $val -ne 0) { 
                return @{ Action = 'Disable'; Value = $val; Index = $selected } 
            } 
            # Во всех остальных случаях левая стрелка / Esc работает как Назад
            return @{ Action = 'Back'; Value = $null; Index = $selected }
        }
    }
}

function Wait-Back {
    Write-Host "`n$(L '[ВЛЕВО] Назад')" -ForegroundColor DarkGray
    while ($true) {
        $key = [System.Console]::ReadKey($true).Key
        if ($key -match 'LeftArrow|Escape|Enter|RightArrow') { break }
    }
}

function Get-TextInput([string]$PromptMsg) {
    try { [Console]::CursorVisible = $true } catch {}
    Write-Host "`n$($PromptMsg): " -NoNewline -ForegroundColor Cyan
    $val = Read-Host
    try { [Console]::CursorVisible = $false } catch {}
    return $val
}

function Get-AdapterMenu {
    param([string]$Title)
    $adapters = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
    if ($adapters.Count -eq 0) { 
        Clear-Host
        Write-Host (L "Сетевых адаптеров в системе не найдено") -ForegroundColor Red
        Start-Sleep 2; return $null 
    }
    $items = @()
    foreach ($a in $adapters) {
        $status = if ($a.Status -eq 'Disabled') { L "ОТКЛЮЧЕН" } elseif ($a.Status -eq 'Disconnected') { L "НЕТ КАБЕЛЯ" } else { L "РАБОТАЕТ" }
        $items += @{ Name = "$($a.InterfaceAlias) [$status]"; Value = $a.InterfaceAlias }
    }
    $items += @{ Name = L "Назад"; Value = 'BACK' }
    
    $res = Show-Menu -Title $Title -Items $items
    if ($res.Action -eq 'Back') { return $null }
    return $res.Value
}

function Test-IPAddress { param([string]$IP); return [System.Net.IPAddress]::TryParse($IP, [ref]0) }

function Ensure-AdapterEnabled {
    param([string]$Alias)
    $ad = Get-NetAdapter -Name $Alias -ErrorAction SilentlyContinue
    if ($ad -and $ad.Status -eq 'Disabled') {
        Enable-NetAdapter -Name $Alias -Confirm:$false
        Start-Sleep 2
    }
}

# --- Модули ---
function Show-Status {
    Clear-Host
    Write-Host (L "=== Активные подключения ===") -ForegroundColor Cyan
    Write-Host "------------------------------------" -ForegroundColor DarkCyan
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
        if ($_.IPv4DefaultGateway) { Write-Host "$(L 'Шлюз')             : $($_.IPv4DefaultGateway.NextHop)" -ForegroundColor Green } 
        else { Write-Host "$(L 'Шлюз')             : $(L 'Отсутствует')" -ForegroundColor Red }
        Write-Host "------------------------------------" -ForegroundColor DarkCyan
    }
    if (-not $found) { Write-Host (L "Подключенных и настроенных сетей не найдено") -ForegroundColor Red }
    
    # ВОЗВРАЩЕН БЛОК НЕАКТИВНЫХ СЕТЕЙ
    Write-Host ""
    Write-Host (L "=== Неактивные сети ===") -ForegroundColor Cyan
    Write-Host "------------------------------------" -ForegroundColor DarkCyan
    $inactive = Get-NetAdapter | Where-Object { $_.Status -ne 'Up' -and $_.InterfaceDescription -notlike '*Loopback*' }
    if ($inactive) {
        foreach ($a in $inactive) {
            $reason = if ($a.Status -eq 'Disabled') { L "Отключено" } elseif ($a.Status -eq 'Disconnected') { L "Кабель не подключен" } else { $a.Status }
            Write-Host " $($a.InterfaceAlias)" -ForegroundColor Gray
            Write-Host "    $(L 'Устройство')   : $($a.InterfaceDescription)" -ForegroundColor DarkGray
            Write-Host "    $(L 'Состояние')    : $reason" -ForegroundColor Red
            Write-Host "------------------------------------" -ForegroundColor DarkCyan
        }
    } else {
        Write-Host " $(L 'Нет отключенных адаптеров')" -ForegroundColor DarkGray
        Write-Host "------------------------------------" -ForegroundColor DarkCyan
    }

    Wait-Back
}

function Scan-LAN {
    $iface = Get-AdapterMenu (L "Выбери адаптер:")
    if (-not $iface) { return }
    Ensure-AdapterEnabled $iface

    $ipInfo = Get-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1
    $gwInfo = Get-NetIPConfiguration -InterfaceAlias $iface | Select-Object -ExpandProperty IPv4DefaultGateway -ErrorAction SilentlyContinue
    $gwIP = if ($gwInfo) { $gwInfo.NextHop } else { "" }

    if (-not $ipInfo) {
        Clear-Host
        Write-Host (L "Адаптер не имеет действительного IP-адреса для сканирования") -ForegroundColor Red
        Wait-Back
        return
    }

    $ipStr = $ipInfo.IPAddress
    $baseIP = $ipStr.Substring(0, $ipStr.LastIndexOf('.'))
    
    Clear-Host
    Write-Host "$(L 'Сканируем локальную сеть: ') $baseIP.1 - $baseIP.254" -ForegroundColor Cyan
    Write-Host (L "Пожалуйста, подожди пару секунд...") -ForegroundColor Yellow

    # Асинхронный быстрый пинг
    $pingers = @()
    $tasks = @()
    foreach ($i in 1..254) {
        $target = "$baseIP.$i"
        $ping = New-Object System.Net.NetworkInformation.Ping
        $pingers += $ping
        $tasks += $ping.SendPingAsync($target, 800)
    }
    [System.Threading.Tasks.Task]::WaitAll($tasks) | Out-Null
    
    $activeIPs = @()
    for ($i=0; $i -lt $tasks.Count; $i++) {
        if ($tasks[$i].Result.Status -eq 'Success') { $activeIPs += $tasks[$i].Result.Address.ToString() }
        $pingers[$i].Dispose()
    }

    # Асинхронный резолв имен (DNS/NetBIOS)
    Write-Host (L "Определение имен устройств...") -ForegroundColor DarkGray
    $dnsTasks = @{}
    foreach ($a_ip in $activeIPs) {
        $dnsTasks[$a_ip] = [System.Net.Dns]::GetHostEntryAsync($a_ip)
    }
    try { [System.Threading.Tasks.Task]::WaitAll([array]$dnsTasks.Values, 2000) | Out-Null } catch {}

    $arpTable = arp -a
    
    Clear-Host
    Write-Host (L "=== Найденные устройства ===") -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkCyan
    
    foreach ($a_ip in $activeIPs) {
        # Поиск MAC-адреса
        $mac = "00-00-00-00-00-00"
        $arpMatch = $arpTable | Select-String "\s+$([regex]::Escape($a_ip))\s+([0-9a-fA-F-]{17})\s+"
        if ($arpMatch) {
            $mac = $arpMatch.Matches[0].Groups[2].Value.ToUpper().Replace(':', '-')
        } elseif ($a_ip -eq $ipStr) {
            $mac = (Get-NetAdapter -InterfaceAlias $iface).MacAddress.Replace(':', '-')
        }

        # Получение имени
        $hostName = ""
        if ($dnsTasks[$a_ip].IsCompleted -and -not $dnsTasks[$a_ip].IsFaulted) {
            $hostName = $dnsTasks[$a_ip].Result.HostName
        }
        if (-not $hostName) { $hostName = L "Неизвестное устройство" }

        # Эвристика устройства (Умный анализ)
        $devType = "PC / IoT / Гаджет"
        if ($a_ip -eq $ipStr) { 
            $devType = L "Этот компьютер" 
        } elseif ($a_ip -eq $gwIP) { 
            $devType = L "Роутер / Точка доступа" 
        } else {
            # 1. Проверка на случайный (Private) MAC от iOS/Android
            try {
                $firstOctet = [convert]::ToInt32($mac.Substring(0,2), 16)
                if (($firstOctet -band 2) -eq 2) {
                    $devType = L "Смартфон / Планшет (Случайный MAC)"
                }
            } catch {}
            
            # 2. Анализ по имени
            if ($hostName -match "(?i)iphone|ipad|macbook|apple") { $devType = "Apple Device" }
            elseif ($hostName -match "(?i)android|galaxy|samsung|xiaomi|redmi") { $devType = "Android Device" }
            elseif ($hostName -match "(?i)tv|kdl|bravia|webos|tizen") { $devType = "Smart TV" }
            elseif ($hostName -match "(?i)printer|hp-|epson|canon|brother") { $devType = L "Принтер" }
        }

        Write-Host "$(L 'IP-адрес')       : $a_ip" -ForegroundColor Green
        Write-Host "$(L 'MAC-адрес')      : $mac" -ForegroundColor Gray
        Write-Host "$(L 'Имя в сети')     : $hostName" -ForegroundColor White
        Write-Host "$(L 'Тип/Инфо')       : $devType" -ForegroundColor Yellow
        Write-Host "----------------------------------------" -ForegroundColor DarkCyan
    }
    Wait-Back
}

function Manage-Adapters {
    $idx = 0
    while ($true) {
        $adapters = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
        $items = @()
        foreach ($a in $adapters) {
            $status = if ($a.Status -eq 'Disabled') { L 'ОТКЛЮЧЕН' } elseif ($a.Status -eq 'Disconnected') { L 'НЕТ КАБЕЛЯ' } else { L 'РАБОТАЕТ' }
            $items += @{ Name = "$($a.InterfaceAlias) [$status]"; Value = $a.InterfaceAlias }
        }
        $items += @{ Name = L "Назад"; Value = 'BACK' }
        
        $res = Show-Menu -Title (L "Включение / Отключение сетевых адаптеров") -Items $items -IsToggleMenu -DefaultIndex $idx
        $idx = $res.Index
        if ($res.Action -eq 'Back') { break }
        
        Clear-Host
        if ($res.Action -eq 'Enable') {
            Write-Host "`n$(L 'Включаем адаптер') '$($res.Value)'..." -ForegroundColor Cyan
            Enable-NetAdapter -Name $res.Value -Confirm:$false
            Start-Sleep 2
        } elseif ($res.Action -eq 'Disable') {
            Write-Host "`n$(L 'Отключаем адаптер') '$($res.Value)'..." -ForegroundColor Cyan
            Disable-NetAdapter -Name $res.Value -Confirm:$false
            Start-Sleep 2
        }
    }
}

function Set-StaticIP {
    param([string]$InterfaceAlias, [string]$IPAddress, [string]$PrefixLength, [string]$DefaultGateway, [string]$Mode)
    Ensure-AdapterEnabled $InterfaceAlias
    try {
        if ($Mode -eq 'Replace') {
            Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        }
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $PrefixLength -AddressFamily IPv4 -ErrorAction Stop | Out-Null
        if ($DefaultGateway -and $DefaultGateway -ne "0.0.0.0") {
            Remove-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue
            New-NetRoute -InterfaceAlias $InterfaceAlias -DestinationPrefix "0.0.0.0/0" -NextHop $DefaultGateway -ErrorAction Stop | Out-Null
        }
        Write-Host "`n$(L 'Настройки успешно применены')" -ForegroundColor Green
    } catch { Write-Host "`nОшибка: $_" -ForegroundColor Red }
    Wait-Back
}

function Manage-DHCP {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = L "Включить DHCP"; Value = "1"}
            @{Name = L "Отключить DHCP"; Value = "2"}
            @{Name = L "Перезапустить DHCP"; Value = "3"}
            @{Name = L "Назад"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Управление DHCP (Включить / Отключить / Обновить)") -Items $items -DefaultIndex $idx
        $idx = $actRes.Index
        if ($actRes.Action -eq 'Back') { break }
        
        $act = $actRes.Value
        $iface = Get-AdapterMenu (L "Выбери адаптер:")
        if (-not $iface) { continue }
        Ensure-AdapterEnabled $iface
        Clear-Host
        
        if ($act -eq "1") {
            Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Enabled -ErrorAction SilentlyContinue | Out-Null
            Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue | Out-Null
            Write-Host "`n$(L 'Успешно!')" -ForegroundColor Green
        } elseif ($act -eq "2") {
            Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Disabled -ErrorAction SilentlyContinue | Out-Null
            Write-Host "`n$(L 'Успешно!')" -ForegroundColor Green
        } elseif ($act -eq "3") {
            ipconfig /release "$iface" | Out-Null
            ipconfig /renew "$iface" | Out-Null
            Write-Host "`n$(L 'Успешно!')" -ForegroundColor Green
        }
        Wait-Back
    }
}

function Manage-WiFi {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = L "Показать доступные сети вокруг"; Value = "1"}
            @{Name = L "Подключиться к сохраненной сети"; Value = "2"}
            @{Name = L "Назад"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Управление Wi-Fi (Поиск и подключение)") -Items $items -DefaultIndex $idx
        $idx = $actRes.Index
        if ($actRes.Action -eq 'Back') { break }
        
        $act = $actRes.Value
        if ($act -eq "1") {
            $nets = @(netsh wlan show networks | Select-String "SSID" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() } | Where-Object { $_ -ne "" } | Select-Object -Unique)
            $nItems = @()
            foreach ($n in $nets) { $nItems += @{Name = $n; Value = $n} }
            $nItems += @{Name = L "Назад"; Value = 'BACK'}
            
            $targetRes = Show-Menu -Title (L "Показать доступные сети вокруг") -Items $nItems
            if ($targetRes.Action -ne 'Back') {
                $target = $targetRes.Value
                Clear-Host
                $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
                if ($profiles -contains $target) {
                    Write-Host "$(L 'Эта сеть уже сохранена, подключаемся...') '$target'" -ForegroundColor Yellow
                    netsh wlan connect name="$target" | Out-Null
                } else {
                    $pwd = Get-TextInput (L "Введи пароль от сети (или нажми Enter, если без пароля)")
                    Write-Host "`n$(L 'Создаем новый профиль сети...')" -ForegroundColor Cyan
                    if ($pwd -eq "") {
                        $xml = @"
<?xml version="1.0"?><WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"><name>$target</name><SSIDConfig><SSID><name>$target</name></SSID></SSIDConfig><connectionType>ESS</connectionType><connectionMode>auto</connectionMode><MSM><security><authEncryption><authentication>open</authentication><encryption>none</encryption><useOneX>false</useOneX></authEncryption></security></MSM></WLANProfile>
"@
                    } else {
                        $xml = @"
<?xml version="1.0"?><WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"><name>$target</name><SSIDConfig><SSID><name>$target</name></SSID></SSIDConfig><connectionType>ESS</connectionType><connectionMode>auto</connectionMode><MSM><security><authEncryption><authentication>WPA2PSK</authentication><encryption>AES</encryption><useOneX>false</useOneX></authEncryption><sharedKey><keyType>passPhrase</keyType><protected>false</protected><keyMaterial>$pwd</keyMaterial></sharedKey></security></MSM></WLANProfile>
"@
                    }
                    $xmlPath = "$env:TEMP\nwifi.xml"
                    $xml | Out-File -FilePath $xmlPath -Encoding utf8
                    netsh wlan add profile filename="$xmlPath" | Out-Null
                    Remove-Item $xmlPath -ErrorAction SilentlyContinue
                    netsh wlan connect name="$target" | Out-Null
                }
                Write-Host "`n$(L 'Успешно!')" -ForegroundColor Green
                Wait-Back
            }
        } elseif ($act -eq "2") {
            $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
            $pItems = @()
            foreach ($p in $profiles) { $pItems += @{Name = $p; Value = $p} }
            $pItems += @{Name = L "Назад"; Value = 'BACK'}
            
            $targetRes = Show-Menu -Title (L "Подключиться к сохраненной сети") -Items $pItems
            if ($targetRes.Action -ne 'Back') {
                $target = $targetRes.Value
                Clear-Host
                netsh wlan connect name="$target" | Out-Null
                Write-Host "`n$(L 'Успешно')" -ForegroundColor Green
                Wait-Back
            }
        }
    }
}

function Main-Menu {
    $mainIndex = 0
    while ($true) {
        $items = @(
            @{Name = L "Показать текущие настройки сети"; Value = 1}
            @{Name = L "Замена основного IP-адреса"; Value = 2}
            @{Name = L "Оставить старый IP и добавить еще один"; Value = 3}
            @{Name = L "Управление DHCP (Включить / Отключить / Обновить)"; Value = 4}
            @{Name = L "Полный сброс адаптера"; Value = 5}
            @{Name = L "Сохраненные профили"; Value = 6}
            @{Name = L "Включение / Отключение сетевых адаптеров"; Value = 7}
            @{Name = L "Управление Wi-Fi (Поиск и подключение)"; Value = 8}
            @{Name = L "Подмена MAC-адреса адаптера (Spoofing)"; Value = 9}
            @{Name = L "LAN Сканер (Поиск устройств в сети)"; Value = 10}
            @{Name = L "Выход"; Value = 0}
        )
        
        $choice = Show-Menu -Title (L "netsett++") -Items $items -DefaultIndex $mainIndex
        $mainIndex = $choice.Index
        
        if ($choice.Action -eq 'Back') { break }
        
        switch ($choice.Value) {
            1 { Show-Status }
            2 {
                $iface = Get-AdapterMenu (L "Выбери адаптер:")
                if ($iface) {
                    Clear-Host
                    $ip = Get-TextInput (L "Введи IP-адрес (например 192.168.1.50)")
                    if (-not (Test-IPAddress $ip)) { continue }
                    $mask = Get-TextInput (L "Введи маску подсети")
                    $gw = Get-TextInput (L "Введи IP-адрес роутера/шлюза (Enter - пропустить)")
                    
                    $svMenu = @( @{Name=L "Да"; Value=$true}, @{Name=L "Нет"; Value=$false} )
                    $saveRes = Show-Menu -Title (L "Сохранить эти настройки как профиль?") -Items $svMenu
                    if ($saveRes.Action -ne 'Back' -and $saveRes.Value -eq $true) {
                        Clear-Host
                        $pname = Get-TextInput (L "Придумай название для профиля")
                        $prof = @{Name=$pname; Interface=$iface; IP=$ip; Mask=$mask; Gateway=$gw}
                        $profiles = @()
                        if (Test-Path $ProfilePath) { $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json }
                        $profiles += $prof
                        $profiles | ConvertTo-Json | Set-Content $ProfilePath -Encoding UTF8
                    }
                    Clear-Host
                    Set-StaticIP -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -DefaultGateway $gw -Mode 'Replace'
                }
            }
            3 {
                $iface = Get-AdapterMenu (L "Выбери адаптер:")
                if ($iface) {
                    Clear-Host
                    $ip = Get-TextInput (L "Введи IP-адрес (например 192.168.1.50)")
                    if (-not (Test-IPAddress $ip)) { continue }
                    $mask = Get-TextInput (L "Введи маску подсети")
                    New-NetIPAddress -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -AddressFamily IPv4 -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "`n$(L 'Успешно!')" -ForegroundColor Green
                    Wait-Back
                }
            }
            4 { Manage-DHCP }
            5 {
                $iface = Get-AdapterMenu (L "Выбери адаптер:")
                if ($iface) {
                    $svMenu = @( @{Name=L "Да"; Value=$true}, @{Name=L "Нет"; Value=$false} )
                    $confirmRes = Show-Menu -Title (L "Ты УВЕРЕН, что хочешь удалить все настройки?") -Items $svMenu
                    if ($confirmRes.Action -ne 'Back' -and $confirmRes.Value -eq $true) {
                        Clear-Host
                        Remove-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Remove-NetRoute -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Write-Host "`n$(L 'Адаптер полностью очищен')" -ForegroundColor Green
                        Wait-Back
                    }
                }
            }
            6 {
                if (-not (Test-Path $ProfilePath)) { continue }
                $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json
                $pItems = @()
                foreach ($p in $profiles) { $pItems += @{Name = "$($p.Name) [$($p.IP)]"; Value = $p} }
                $pItems += @{Name = L "Назад"; Value = 'BACK'}
                
                $pRes = Show-Menu -Title (L "Загрузить и применить профиль") -Items $pItems
                if ($pRes.Action -ne 'Back') {
                    $p = $pRes.Value
                    $svMenu = @( @{Name=L "Да"; Value=$true}, @{Name=L "Нет"; Value=$false} )
                    $confirmRes = Show-Menu -Title ("Применить '$($p.Name)' к '$($p.Interface)'?") -Items $svMenu
                    if ($confirmRes.Action -ne 'Back' -and $confirmRes.Value -eq $true) {
                        Clear-Host
                        Set-StaticIP -InterfaceAlias $p.Interface -IPAddress $p.IP -PrefixLength $p.Mask -DefaultGateway $p.Gateway -Mode 'Replace'
                    }
                }
            }
            7 { Manage-Adapters }
            8 { Manage-WiFi }
            9 {
                $iface = Get-AdapterMenu (L "Выбери адаптер:")
                if ($iface) {
                    $mItems = @(
                        @{Name = L "Ввести новый MAC вручную"; Value = "1"}
                        @{Name = L "Сгенерировать случайный MAC"; Value = "2"}
                        @{Name = L "Вернуть родной заводской MAC"; Value = "3"}
                        @{Name = L "Назад"; Value = "BACK"}
                    )
                    $actRes = Show-Menu -Title (L "Подмена MAC-адреса адаптера (Spoofing)") -Items $mItems
                    if ($actRes.Action -ne 'Back') {
                        $act = $actRes.Value
                        $adapter = Get-NetAdapter -Name $iface
                        $guid = $adapter.InterfaceGuid
                        $regBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
                        $regPath = ""
                        foreach ($k in Get-ChildItem $regBase) {
                            $val = Get-ItemProperty $k.PSPath -Name "NetCfgInstanceId" -ErrorAction SilentlyContinue
                            if ($val.NetCfgInstanceId -eq $guid) { $regPath = $k.PSPath; break }
                        }
                        if ($regPath -ne "") {
                            $newMac = ""
                            if ($act -eq "1") {
                                Clear-Host
                                $inputMac = Get-TextInput "Введи новый MAC (без тире, например 001122334455)"
                                if ($inputMac -match '^[0-9A-Fa-f]{12}$') { $newMac = $inputMac } else { continue }
                            } elseif ($act -eq "2") {
                                $chars = "0123456789ABCDEF"; $valid = "2","6","A","E"
                                $newMac = $chars[(Get-Random -Max 16)].ToString() + $valid[(Get-Random -Max 4)]
                                for ($i=0; $i -lt 10; $i++) { $newMac += $chars[(Get-Random -Max 16)] }
                            }
                            
                            if ($act -eq "3") { Remove-ItemProperty -Path $regPath -Name "NetworkAddress" -ErrorAction SilentlyContinue } 
                            else { Set-ItemProperty -Path $regPath -Name "NetworkAddress" -Value $newMac }
                            
                            Clear-Host
                            Write-Host "`nПрименяем настройки..." -ForegroundColor Cyan
                            Disable-NetAdapter -Name $iface -Confirm:$false
                            Start-Sleep 1
                            Enable-NetAdapter -Name $iface -Confirm:$false
                            Clear-Host
                            Write-Host "`n$(L 'Успешно!')" -ForegroundColor Green
                            Wait-Back
                        }
                    }
                }
            }
            10 { Scan-LAN }
        }
    }
}

try {
    Main-Menu
} catch {
    Write-Host "`n[КРИТИЧЕСКАЯ ОШИБКА / CRITICAL ERROR]" -ForegroundColor White -BackgroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-Back
}
try { [Console]::CursorVisible = $true } catch {}
