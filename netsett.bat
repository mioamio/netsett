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
    echo [ERROR] Скрипт завершил работу с системной ошибкой.
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
    using System.Net;
    
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

    public class NetAPI {
        [DllImport("iphlpapi.dll", ExactSpelling=true)]
        public static extern int SendARP(uint destIP, uint srcIP, byte[] macAddr, ref uint physicalAddrLen);
    }
"@ -ErrorAction SilentlyContinue
    [ConsoleHelper]::SetFontSize($FontSize)
} catch {}

# Настройка размера окна
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

# --- Система Локализации (Base language is English) ---
$global:SysLang = (Get-UICulture).TwoLetterISOLanguageName
if (-not $global:SysLang) { $global:SysLang = (Get-Culture).TwoLetterISOLanguageName }

$global:RuDict = @{
    "[UP/DOWN] Select | [RIGHT] Enter | [LEFT] Back" = "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Войти | [ВЛЕВО] Назад"
    "[UP/DOWN] Select | [RIGHT] Enable | [LEFT] Disable | [ESC] Back" = "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Включить | [ВЛЕВО] Отключить | [ESC] Назад"
    "[LEFT] Go Back" = "[ВЛЕВО] Назад"
    "Back" = "Назад"
    "Yes" = "Да"
    "No" = "Нет"
    "Exit" = "Выход"
    
    "Show current network settings (Live)" = "Показать текущие настройки сети (Live)"
    "Change primary IP address" = "Замена основного IP-адреса"
    "Add secondary IP address" = "Оставить старый IP и добавить еще один"
    "Manage DHCP (Enable / Disable / Renew)" = "Управление DHCP (Включить / Отключить / Обновить)"
    "Full adapter reset" = "Полный сброс адаптера"
    "Saved profiles" = "Сохраненные профили"
    "Enable / Disable network adapters" = "Включение / Отключение сетевых адаптеров"
    "Wi-Fi Management (Search & Connect)" = "Управление Wi-Fi (Поиск и подключение)"
    "MAC Address Spoofing" = "Подмена MAC-адреса адаптера (Spoofing)"
    "LAN Scanner (Real-Time)" = "LAN Сканер (В реальном времени)"
    
    "ADAPT_DISABLED" = "ОТКЛЮЧЕН"
    "ADAPT_NO_CABLE" = "НЕТ КАБЕЛЯ"
    "ADAPT_WORKING"  = "РАБОТАЕТ"
    
    "Automatic (DHCP)" = "Автоматически (DHCP)"
    "Manual (Static)" = "Вручную (Статика)"
    "Default Gateway" = "Шлюз"
    "None" = "Отсутствует"
    "Current IP Address" = "Текущий IP-адрес"
    "Network Adapter" = "Сетевой адаптер"
    "Device Hardware" = "Устройство"
    "Operating Mode" = "Режим работы"
    
    "No network adapters found in the system" = "Сетевых адаптеров в системе не найдено"
    "Select an adapter:" = "Выбери адаптер:"
    "Enabling adapter" = "Включаем адаптер"
    "Disabling adapter" = "Отключаем адаптер"
    
    "Enter IP address (e.g. 192.168.1.50)" = "Введи IP-адрес (например 192.168.1.50)"
    "Enter subnet mask (e.g. 24)" = "Введи маску подсети (например 24)"
    "Enter Gateway IP (Enter to skip)" = "Введи IP-адрес роутера/шлюза (Enter - пропустить)"
    "Save these settings as a profile?" = "Сохранить эти настройки как профиль?"
    "Enter a name for the profile" = "Придумай название для профиля"
    "Settings successfully applied" = "Настройки успешно применены"
    "Are you SURE you want to clear all settings?" = "Ты УВЕРЕН, что хочешь удалить все настройки?"
    "Adapter settings cleared successfully" = "Адаптер полностью очищен"
    
    "Enable DHCP" = "Включить DHCP"
    "Disable DHCP" = "Отключить DHCP"
    "Renew DHCP" = "Перезапустить DHCP"
    "Success!" = "Успешно!"
    
    "Show available networks" = "Показать доступные сети вокруг"
    "Connect to saved network" = "Подключиться к сохраненной сети"
    "This network is already saved, connecting..." = "Эта сеть уже сохранена, подключаемся..."
    "Enter network password (or press Enter if open)" = "Введи пароль от сети (или нажми Enter, если без пароля)"
    "Creating new network profile..." = "Создаем новый профиль сети..."
    
    "Enter new MAC manually" = "Ввести новый MAC вручную"
    "Generate random MAC" = "Сгенерировать случайный MAC"
    "Restore original hardware MAC" = "Вернуть родной заводской MAC"
    "Enter new MAC (no dashes, e.g. 001122334455)" = "Введи новый MAC (без тире, например 001122334455)"
    "Applying settings..." = "Применяем настройки..."
    
    "Scanning local network: " = "Сканируем локальную сеть: "
    "Performing fast sweep (1-2 sec)..." = "Выполняется быстрый опрос (1-2 сек)..."
    "=== Found Devices ===" = "=== Найденные устройства ==="
    " Real-time update... Press [LEFT] to exit" = " Обновление в реальном времени... Нажми [ВЛЕВО] для выхода"
    "=== Active Connections ===" = "=== Активные подключения ==="
    "=== Inactive Networks ===" = "=== Неактивные сети ==="
    "No connected and configured networks found" = "Подключенных и настроенных сетей не найдено"
    "Disabled" = "Отключено"
    "Cable disconnected" = "Кабель не подключен"
    "Status" = "Состояние"
    "No disabled adapters found" = "Нет отключенных адаптеров"
    
    "IP Address" = "IP-адрес"
    "MAC Address" = "MAC-адрес"
    "Hostname" = "Имя в сети"
    "Device Type/Info" = "Тип/Инфо"
    
    "This PC" = "Этот компьютер"
    "Router / Access Point" = "Роутер / Точка доступа"
    "Smartphone / Tablet (Private MAC)" = "Смартфон / Планшет (Случайный MAC)"
    "Printer" = "Принтер"
    "Unknown Device" = "Неизвестное устройство"
    "Adapter does not have a valid IP for scanning." = "Адаптер не имеет действительного IP-адреса для сканирования."
    
    "Load and apply a profile" = "Загрузить и применить профиль"
    "You don't have any saved profiles yet." = "У тебя пока нет сохраненных профилей."
    "They will appear here when you save settings while applying a new IP." = "Они появятся здесь, когда ты сохранишь настройки при установке нового IP-адреса."
}

function L([string]$text) {
    if ($global:SysLang -eq "ru" -and $global:RuDict.ContainsKey($text)) {
        return $global:RuDict[$text]
    }
    return $text
}

# --- Функция для Real-Time отрисовки без мерцания ---
function Write-LineClear([string]$Text, [string]$FgColor, [string]$BgColor="Black") {
    $padLen = $Host.UI.WindowSize.Width - 1 - $Text.Length
    if ($padLen -lt 0) { $padLen = 0 }
    Write-Host "$Text$(' ' * $padLen)" -ForegroundColor $FgColor -BackgroundColor $BgColor
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
        Write-Host " $(L '[UP/DOWN] Select | [RIGHT] Enable | [LEFT] Disable | [ESC] Back')" -ForegroundColor DarkGray
    } else {
        Write-Host " $(L '[UP/DOWN] Select | [RIGHT] Enter | [LEFT] Back')" -ForegroundColor DarkGray
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
                if ($isBackAction) { $prefix = "  < " } else { $prefix = "  > " }
                $fg = "Black"
                $bg = "Cyan"
            }
            
            $text = "$prefix$($Items[$i].Name) "
            Write-Host $text -ForegroundColor $fg -BackgroundColor $bg -NoNewline
            
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
            if ($val -eq 'BACK' -or $val -eq 0) { return @{ Action = 'Back'; Value = $val; Index = $selected } }
            if ($IsToggleMenu) { return @{ Action = 'Enable'; Value = $val; Index = $selected } } 
            return @{ Action = 'Enter'; Value = $val; Index = $selected }
        } elseif ($key -eq 'LeftArrow' -or $key -eq 'Escape' -or $key -eq 'Backspace') {
            $val = $Items[$selected].Value
            if ($IsToggleMenu -and $key -eq 'LeftArrow' -and $val -ne 'BACK' -and $val -ne 0) { 
                return @{ Action = 'Disable'; Value = $val; Index = $selected } 
            } 
            return @{ Action = 'Back'; Value = $null; Index = $selected }
        }
    }
}

function Wait-Back {
    Write-Host "`n$(L '[LEFT] Go Back')" -ForegroundColor DarkGray
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
        Write-Host (L "No network adapters found in the system") -ForegroundColor Red
        Start-Sleep 2; return $null 
    }
    $items = @()
    foreach ($a in $adapters) {
        $status = if ($a.Status -eq 'Disabled') { L "ADAPT_DISABLED" } elseif ($a.Status -eq 'Disconnected') { L "ADAPT_NO_CABLE" } else { L "ADAPT_WORKING" }
        $items += @{ Name = "$($a.InterfaceAlias) [$status]"; Value = $a.InterfaceAlias }
    }
    $items += @{ Name = L "Back"; Value = 'BACK' }
    
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

# --- Модули (Real-Time engine) ---
function Show-Status {
    Clear-Host
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Write-LineClear (L "=== Active Connections ===") "Cyan"
        Write-LineClear "------------------------------------" "DarkCyan"
        $found = $false
        Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
            $found = $true
            $ifaceAlias = $_.InterfaceAlias
            $ad = Get-NetAdapter -Name $ifaceAlias -ErrorAction SilentlyContinue
            $dhcpInfo = Get-NetIPInterface -InterfaceAlias $ifaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $dhcpStr = if ($dhcpInfo.Dhcp -eq 'Enabled') { L "Automatic (DHCP)" } else { L "Manual (Static)" }

            Write-LineClear "$(L 'Network Adapter')  : $ifaceAlias" "Cyan"
            Write-LineClear "$(L 'Device Hardware')  : $($ad.InterfaceDescription)" "DarkGray"
            Write-LineClear "$(L 'MAC Address')      : $($ad.MacAddress)" "DarkGray"
            Write-LineClear "$(L 'Operating Mode')   : $dhcpStr" "Yellow"
            Write-LineClear "$(L 'Current IP Address') : $($_.IPv4Address.IPAddress)" "Green"
            if ($_.IPv4DefaultGateway) { Write-LineClear "$(L 'Default Gateway')  : $($_.IPv4DefaultGateway.NextHop)" "Green" } 
            else { Write-LineClear "$(L 'Default Gateway')  : $(L 'None')" "Red" }
            Write-LineClear "------------------------------------" "DarkCyan"
        }
        if (-not $found) { Write-LineClear (L "No connected and configured networks found") "Red" }
        
        Write-LineClear "" "Black"
        Write-LineClear (L "=== Inactive Networks ===") "Cyan"
        Write-LineClear "------------------------------------" "DarkCyan"
        $inactive = Get-NetAdapter | Where-Object { $_.Status -ne 'Up' -and $_.InterfaceDescription -notlike '*Loopback*' }
        if ($inactive) {
            foreach ($a in $inactive) {
                $reason = if ($a.Status -eq 'Disabled') { L "Disabled" } elseif ($a.Status -eq 'Disconnected') { L "Cable disconnected" } else { $a.Status }
                Write-LineClear " $($a.InterfaceAlias)" "Gray"
                Write-LineClear "    $(L 'Device Hardware'): $($a.InterfaceDescription)" "DarkGray"
                Write-LineClear "    $(L 'Status')         : $reason" "Red"
                Write-LineClear "------------------------------------" "DarkCyan"
            }
        } else {
            Write-LineClear " $(L 'No disabled adapters found')" "DarkGray"
            Write-LineClear "------------------------------------" "DarkCyan"
        }

        Write-LineClear "" "Black"
        Write-LineClear "$(L '[LEFT] Go Back')" "DarkGray"

        # Зачищаем остаток экрана
        $currentTop = [Console]::CursorTop
        while ($currentTop -lt $Host.UI.WindowSize.Height - 1) {
            Write-LineClear "" "Black"
            $currentTop++
        }

        $breakLoop = $false
        for ($i=0; $i -lt 10; $i++) {
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true).Key
                if ($k -match 'LeftArrow|Escape|Backspace') { $breakLoop = $true; break }
            }
            Start-Sleep -Milliseconds 100
        }
        if ($breakLoop) { break }
    }
}

function Get-MacByIP([string]$IP) {
    try {
        $ipAddr = [System.Net.IPAddress]::Parse($IP)
        $ipBytes = $ipAddr.GetAddressBytes()
        $destIP = [BitConverter]::ToUInt32($ipBytes, 0)
        
        $macAddr = New-Object byte[] 6
        $macLen = [uint32]6
        
        $res = [NetAPI]::SendARP($destIP, 0, $macAddr, [ref]$macLen)
        if ($res -eq 0) {
            $hex = $macAddr | ForEach-Object { $_.ToString("X2") }
            return $hex -join "-"
        }
    } catch {}
    return "00-00-00-00-00-00"
}

function Get-VendorByMac([string]$Mac) {
    $prefix = ($Mac.Replace("-", "").Substring(0,6)).ToUpper()
    $vendors = @{
        "001CB3"="Apple"; "002500"="Apple"; "28CFE9"="Apple"; "8C8590"="Apple"; "F8FFC2"="Apple"
        "B4F1CB"="Apple"; "C8B5B7"="Apple"; "3C0754"="Apple"; "4098AD"="Apple"; "0010FA"="Apple"
        "001451"="Apple"; "0016CB"="Apple"; "CCB8A8"="Apple"; "D4619D"="Apple"; "E0B52D"="Apple"
        "001A11"="Google"; "F88A5E"="Google"; "3C5AB4"="Google"
        "001E10"="Cisco"; "0014F2"="Cisco"; "001A6C"="Cisco"; "00259C"="Cisco"
        "001999"="Fujitsu"; "000B5D"="Fujitsu"
        "0017C4"="Asus"; "001A92"="Asus"; "001E8C"="Asus"; "14DDA9"="Asus"; "04D4C4"="Asus"
        "000D3A"="Microsoft"; "00125A"="Microsoft"; "0017FA"="Microsoft"; "281878"="Microsoft"; "C8F650"="Microsoft"
        "001132"="Synology"; "00A0C6"="Qualcomm"
        "E48D8C"="MikroTik"; "000C42"="MikroTik"; "D4CA6D"="MikroTik"
        "C04A00"="TP-Link"; "E848B8"="TP-Link"; "F81A67"="TP-Link"; "D807B6"="TP-Link"; "503EAA"="TP-Link"; "B0BE76"="TP-Link"
        "080027"="VirtualBox"; "000569"="VMware"; "000C29"="VMware"; "005056"="VMware"
        "001BDC"="Samsung"; "00215D"="Samsung"; "0023D6"="Samsung"; "CCB11A"="Samsung"; "D022BE"="Samsung"
        "002268"="Xiaomi"; "009ECA"="Xiaomi"; "286C07"="Xiaomi"; "38A4ED"="Xiaomi"; "7C49EB"="Xiaomi"
        "001A4B"="HP"; "001E0B"="HP"; "002264"="HP"
    }
    if ($vendors.ContainsKey($prefix)) { return $vendors[$prefix] }
    return ""
}

function Scan-LAN {
    $iface = Get-AdapterMenu (L "Select an adapter:")
    if (-not $iface) { return }
    Ensure-AdapterEnabled $iface

    $ipInfo = Get-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1
    $gwInfo = Get-NetIPConfiguration -InterfaceAlias $iface | Select-Object -ExpandProperty IPv4DefaultGateway -ErrorAction SilentlyContinue
    $gwIP = if ($gwInfo) { $gwInfo.NextHop } else { "" }

    if (-not $ipInfo) {
        Clear-Host
        Write-Host (L "Adapter does not have a valid IP for scanning.") -ForegroundColor Red
        Wait-Back
        return
    }

    $ipStr = $ipInfo.IPAddress
    $baseIP = $ipStr.Substring(0, $ipStr.LastIndexOf('.'))
    $localMac = (Get-NetAdapter -InterfaceAlias $iface).MacAddress.Replace(':', '-')
    
    Clear-Host
    Write-Host "$(L 'Scanning local network: ') $baseIP.1 - $baseIP.254" -ForegroundColor Cyan
    Write-Host (L "Performing fast sweep (1-2 sec)...") -ForegroundColor Yellow

    # Быстрый пинг Sweep
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

    # Запускаем Async DNS
    $dnsTasks = @{}
    foreach ($a_ip in $activeIPs) {
        $dnsTasks[$a_ip] = [System.Net.Dns]::GetHostEntryAsync($a_ip)
    }
    
    # Real-Time цикл отрисовки сканера
    Clear-Host
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        Write-LineClear (L "=== Found Devices ===") "Cyan"
        Write-LineClear (L " Real-time update... Press [LEFT] to exit") "DarkGray"
        Write-LineClear "--------------------------------------------------------" "DarkCyan"
        
        foreach ($a_ip in $activeIPs) {
            # 1. Точный MAC через API
            $mac = "00-00-00-00-00-00"
            if ($a_ip -eq $ipStr) { $mac = $localMac }
            else { $mac = Get-MacByIP $a_ip }

            # 2. Имя из DNS
            $hostName = ""
            if ($dnsTasks[$a_ip].IsCompleted -and -not $dnsTasks[$a_ip].IsFaulted) {
                $hostName = $dnsTasks[$a_ip].Result.HostName
            }
            if (-not $hostName) { $hostName = L "Unknown Device" }

            # 3. Эвристика устройства
            $devType = "PC / IoT"
            if ($a_ip -eq $ipStr) { 
                $devType = L "This PC" 
            } elseif ($a_ip -eq $gwIP) { 
                $devType = L "Router / Access Point" 
            } else {
                try {
                    $firstOctet = [convert]::ToInt32($mac.Substring(0,2), 16)
                    if (($firstOctet -band 2) -eq 2) {
                        $devType = L "Smartphone / Tablet (Private MAC)"
                    } else {
                        $vendor = Get-VendorByMac $mac
                        if ($vendor) { $devType = "$vendor Device" }
                    }
                } catch {}
                
                if ($hostName -match "(?i)iphone|ipad|macbook|apple") { $devType = "Apple Device" }
                elseif ($hostName -match "(?i)android|galaxy|samsung|xiaomi|redmi") { $devType = "Android Device" }
                elseif ($hostName -match "(?i)tv|kdl|bravia|webos|tizen") { $devType = "Smart TV" }
                elseif ($hostName -match "(?i)printer|hp-|epson|canon|brother") { $devType = L "Printer" }
            }

            Write-LineClear "$(L 'IP Address')       : $a_ip" "Green"
            Write-LineClear "$(L 'MAC Address')      : $mac" "Gray"
            Write-LineClear "$(L 'Hostname')         : $hostName" "White"
            Write-LineClear "$(L 'Device Type/Info') : $devType" "Yellow"
            Write-LineClear "--------------------------------------------------------" "DarkCyan"
        }
        
        # Очистка хвоста экрана
        $currentTop = [Console]::CursorTop
        while ($currentTop -lt $Host.UI.WindowSize.Height - 1) {
            Write-LineClear "" "Black"
            $currentTop++
        }

        # Ждем и слушаем кнопки
        $breakLoop = $false
        for ($i=0; $i -lt 15; $i++) {
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true).Key
                if ($k -match 'LeftArrow|Escape|Backspace') { $breakLoop = $true; break }
            }
            Start-Sleep -Milliseconds 100
        }
        if ($breakLoop) { break }
    }
}

function Manage-Adapters {
    $idx = 0
    while ($true) {
        $adapters = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
        $items = @()
        foreach ($a in $adapters) {
            $status = if ($a.Status -eq 'Disabled') { L 'ADAPT_DISABLED' } elseif ($a.Status -eq 'Disconnected') { L 'ADAPT_NO_CABLE' } else { L 'ADAPT_WORKING' }
            $items += @{ Name = "$($a.InterfaceAlias) [$status]"; Value = $a.InterfaceAlias }
        }
        $items += @{ Name = L "Back"; Value = 'BACK' }
        
        $res = Show-Menu -Title (L "Enable / Disable network adapters") -Items $items -IsToggleMenu -DefaultIndex $idx
        $idx = $res.Index
        if ($res.Action -eq 'Back') { break }
        
        Clear-Host
        if ($res.Action -eq 'Enable') {
            Write-Host "`n$(L 'Enabling adapter') '$($res.Value)'..." -ForegroundColor Cyan
            Enable-NetAdapter -Name $res.Value -Confirm:$false
            Start-Sleep 2
        } elseif ($res.Action -eq 'Disable') {
            Write-Host "`n$(L 'Disabling adapter') '$($res.Value)'..." -ForegroundColor Cyan
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
        Write-Host "`n$(L 'Settings successfully applied')" -ForegroundColor Green
    } catch { Write-Host "`nError: $_" -ForegroundColor Red }
    Wait-Back
}

function Manage-DHCP {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = L "Enable DHCP"; Value = "1"}
            @{Name = L "Disable DHCP"; Value = "2"}
            @{Name = L "Renew DHCP"; Value = "3"}
            @{Name = L "Back"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Manage DHCP (Enable / Disable / Renew)") -Items $items -DefaultIndex $idx
        $idx = $actRes.Index
        if ($actRes.Action -eq 'Back') { break }
        
        $act = $actRes.Value
        $iface = Get-AdapterMenu (L "Select an adapter:")
        if (-not $iface) { continue }
        Ensure-AdapterEnabled $iface
        Clear-Host
        
        if ($act -eq "1") {
            Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Enabled -ErrorAction SilentlyContinue | Out-Null
            Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue | Out-Null
            Write-Host "`n$(L 'Success!')" -ForegroundColor Green
        } elseif ($act -eq "2") {
            Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Disabled -ErrorAction SilentlyContinue | Out-Null
            Write-Host "`n$(L 'Success!')" -ForegroundColor Green
        } elseif ($act -eq "3") {
            ipconfig /release "$iface" | Out-Null
            ipconfig /renew "$iface" | Out-Null
            Write-Host "`n$(L 'Success!')" -ForegroundColor Green
        }
        Wait-Back
    }
}

function Manage-WiFi {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = L "Show available networks"; Value = "1"}
            @{Name = L "Connect to saved network"; Value = "2"}
            @{Name = L "Back"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Wi-Fi Management (Search & Connect)") -Items $items -DefaultIndex $idx
        $idx = $actRes.Index
        if ($actRes.Action -eq 'Back') { break }
        
        $act = $actRes.Value
        if ($act -eq "1") {
            $nets = @(netsh wlan show networks | Select-String "SSID" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() } | Where-Object { $_ -ne "" } | Select-Object -Unique)
            $nItems = @()
            foreach ($n in $nets) { $nItems += @{Name = $n; Value = $n} }
            $nItems += @{Name = L "Back"; Value = 'BACK'}
            
            $targetRes = Show-Menu -Title (L "Show available networks") -Items $nItems
            if ($targetRes.Action -ne 'Back') {
                $target = $targetRes.Value
                Clear-Host
                $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
                if ($profiles -contains $target) {
                    Write-Host "$(L 'This network is already saved, connecting...') '$target'" -ForegroundColor Yellow
                    netsh wlan connect name="$target" | Out-Null
                } else {
                    $pwd = Get-TextInput (L "Enter network password (or press Enter if open)")
                    Write-Host "`n$(L 'Creating new network profile...')" -ForegroundColor Cyan
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
                Write-Host "`n$(L 'Success!')" -ForegroundColor Green
                Wait-Back
            }
        } elseif ($act -eq "2") {
            $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
            $pItems = @()
            foreach ($p in $profiles) { $pItems += @{Name = $p; Value = $p} }
            $pItems += @{Name = L "Back"; Value = 'BACK'}
            
            $targetRes = Show-Menu -Title (L "Connect to saved network") -Items $pItems
            if ($targetRes.Action -ne 'Back') {
                $target = $targetRes.Value
                Clear-Host
                netsh wlan connect name="$target" | Out-Null
                Write-Host "`n$(L 'Success!')" -ForegroundColor Green
                Wait-Back
            }
        }
    }
}

function Main-Menu {
    $mainIndex = 0
    while ($true) {
        $items = @(
            @{Name = L "Show current network settings (Live)"; Value = 1}
            @{Name = L "Change primary IP address"; Value = 2}
            @{Name = L "Add secondary IP address"; Value = 3}
            @{Name = L "Manage DHCP (Enable / Disable / Renew)"; Value = 4}
            @{Name = L "Full adapter reset"; Value = 5}
            @{Name = L "Saved profiles"; Value = 6}
            @{Name = L "Enable / Disable network adapters"; Value = 7}
            @{Name = L "Wi-Fi Management (Search & Connect)"; Value = 8}
            @{Name = L "MAC Address Spoofing"; Value = 9}
            @{Name = L "LAN Scanner (Real-Time)"; Value = 10}
            @{Name = L "Exit"; Value = 0}
        )
        
        $choice = Show-Menu -Title "netsett++" -Items $items -DefaultIndex $mainIndex
        $mainIndex = $choice.Index
        
        if ($choice.Action -eq 'Back') { break }
        
        switch ($choice.Value) {
            1 { Show-Status }
            2 {
                $iface = Get-AdapterMenu (L "Select an adapter:")
                if ($iface) {
                    Clear-Host
                    $ip = Get-TextInput (L "Enter IP address (e.g. 192.168.1.50)")
                    if (-not (Test-IPAddress $ip)) { continue }
                    $mask = Get-TextInput (L "Enter subnet mask (e.g. 24)")
                    $gw = Get-TextInput (L "Enter Gateway IP (Enter to skip)")
                    
                    $svMenu = @( @{Name=L "Yes"; Value=$true}, @{Name=L "No"; Value=$false} )
                    $saveRes = Show-Menu -Title (L "Save these settings as a profile?") -Items $svMenu
                    if ($saveRes.Action -ne 'Back' -and $saveRes.Value -eq $true) {
                        Clear-Host
                        $pname = Get-TextInput (L "Enter a name for the profile")
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
                $iface = Get-AdapterMenu (L "Select an adapter:")
                if ($iface) {
                    Clear-Host
                    $ip = Get-TextInput (L "Enter IP address (e.g. 192.168.1.50)")
                    if (-not (Test-IPAddress $ip)) { continue }
                    $mask = Get-TextInput (L "Enter subnet mask (e.g. 24)")
                    New-NetIPAddress -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -AddressFamily IPv4 -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "`n$(L 'Success!')" -ForegroundColor Green
                    Wait-Back
                }
            }
            4 { Manage-DHCP }
            5 {
                $iface = Get-AdapterMenu (L "Select an adapter:")
                if ($iface) {
                    $svMenu = @( @{Name=L "Yes"; Value=$true}, @{Name=L "No"; Value=$false} )
                    $confirmRes = Show-Menu -Title (L "Are you SURE you want to clear all settings?") -Items $svMenu
                    if ($confirmRes.Action -ne 'Back' -and $confirmRes.Value -eq $true) {
                        Clear-Host
                        Remove-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Remove-NetRoute -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Write-Host "`n$(L 'Adapter settings cleared successfully')" -ForegroundColor Green
                        Wait-Back
                    }
                }
            }
            6 {
                if (-not (Test-Path $ProfilePath)) { 
                    Clear-Host
                    Write-Host "`n$(L "You don't have any saved profiles yet.")" -ForegroundColor Yellow
                    Write-Host "$(L "They will appear here when you save settings while applying a new IP.")" -ForegroundColor DarkGray
                    Wait-Back
                    continue 
                }
                $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json
                $pItems = @()
                foreach ($p in $profiles) { $pItems += @{Name = "$($p.Name) [$($p.IP)]"; Value = $p} }
                $pItems += @{Name = L "Back"; Value = 'BACK'}
                
                $pRes = Show-Menu -Title (L "Load and apply a profile") -Items $pItems
                if ($pRes.Action -ne 'Back') {
                    $p = $pRes.Value
                    $svMenu = @( @{Name=L "Yes"; Value=$true}, @{Name=L "No"; Value=$false} )
                    # Названия профилей не переводим, склеиваем строку на лету
                    $confirmTitle = "Apply '$($p.Name)' to '$($p.Interface)'?"
                    if ($global:SysLang -eq "ru") { $confirmTitle = "Применить '$($p.Name)' к '$($p.Interface)'?" }
                    
                    $confirmRes = Show-Menu -Title $confirmTitle -Items $svMenu
                    if ($confirmRes.Action -ne 'Back' -and $confirmRes.Value -eq $true) {
                        Clear-Host
                        Set-StaticIP -InterfaceAlias $p.Interface -IPAddress $p.IP -PrefixLength $p.Mask -DefaultGateway $p.Gateway -Mode 'Replace'
                    }
                }
            }
            7 { Manage-Adapters }
            8 { Manage-WiFi }
            9 {
                $iface = Get-AdapterMenu (L "Select an adapter:")
                if ($iface) {
                    $mItems = @(
                        @{Name = L "Enter new MAC manually"; Value = "1"}
                        @{Name = L "Generate random MAC"; Value = "2"}
                        @{Name = L "Restore original hardware MAC"; Value = "3"}
                        @{Name = L "Back"; Value = "BACK"}
                    )
                    $actRes = Show-Menu -Title (L "MAC Address Spoofing") -Items $mItems
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
                                $inputMac = Get-TextInput (L "Enter new MAC (no dashes, e.g. 001122334455)")
                                if ($inputMac -match '^[0-9A-Fa-f]{12}$') { $newMac = $inputMac } else { continue }
                            } elseif ($act -eq "2") {
                                $chars = "0123456789ABCDEF"; $valid = "2","6","A","E"
                                $newMac = $chars[(Get-Random -Max 16)].ToString() + $valid[(Get-Random -Max 4)]
                                for ($i=0; $i -lt 10; $i++) { $newMac += $chars[(Get-Random -Max 16)] }
                            }
                            
                            if ($act -eq "3") { Remove-ItemProperty -Path $regPath -Name "NetworkAddress" -ErrorAction SilentlyContinue } 
                            else { Set-ItemProperty -Path $regPath -Name "NetworkAddress" -Value $newMac }
                            
                            Clear-Host
                            Write-Host "`n$(L 'Applying settings...')" -ForegroundColor Cyan
                            Disable-NetAdapter -Name $iface -Confirm:$false
                            Start-Sleep 1
                            Enable-NetAdapter -Name $iface -Confirm:$false
                            Clear-Host
                            Write-Host "`n$(L 'Success!')" -ForegroundColor Green
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
    Clear-Host
    Write-Host "`n[КРИТИЧЕСКАЯ ОШИБКА / CRITICAL ERROR]" -ForegroundColor White -BackgroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-Back
}
try { [Console]::CursorVisible = $true } catch {}
