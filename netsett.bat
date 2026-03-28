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

:RELOAD_SCRIPT
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([ScriptBlock]::Create((Get-Content -LiteralPath $env:BAT_FILE_PATH -Raw -Encoding UTF8)))"

:: Если PowerShell вернул код 99 (нажата F5), мгновенно перезапускаем его в этом же окне
if %errorlevel% equ 99 (
    goto RELOAD_SCRIPT
)

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

# === УВЕЛИЧЕННЫЙ ШРИФТ И НАСТРОЙКА ОКНА ===
$FontSize = 28

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

# Подгонка размера под крупный шрифт
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
    "[UP/DOWN] Select | [RIGHT] Enter | [LEFT] Back | [F5] Reload" = "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Войти | [ВЛЕВО] Назад | [F5] Обновить"
    "[UP/DOWN] Select | [RIGHT] Enable | [LEFT] Disable | [ESC] Back | [F5] Reload" = "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Вкл | [ВЛЕВО] Выкл | [ESC] Назад | [F5] Обновить"
    "[LEFT] Go Back" = "[ВЛЕВО] Назад"
    "Back" = "Назад"
    "Yes" = "Да"
    "No" = "Нет"
    "Exit" = "Выход"
    
    "Show current network settings" = "Показать текущие настройки сети"
    "Change primary IP address" = "Замена основного IP-адреса"
    "Add secondary IP address" = "Оставить старый IP и добавить еще один"
    "Manage DHCP (Enable / Disable / Renew)" = "Управление DHCP (Включить / Отключить / Обновить)"
    "Quick DNS Setup (Cloudflare, Google, etc.)" = "Быстрая смена DNS (Cloudflare, Google и др.)"
    "Network Resets & Troubleshooting" = "Сброс сети и устранение неполадок"
    "Saved profiles" = "Сохраненные профили"
    "Enable / Disable network adapters" = "Включение / Отключение сетевых адаптеров"
    "Wi-Fi Management (Search, Connect, Passwords)" = "Управление Wi-Fi (Поиск, Подключение, Пароли)"
    "MAC Address Spoofing" = "Подмена MAC-адреса адаптера (Spoofing)"
    "LAN Scanner" = "LAN Сканер (Поиск устройств в сети)"
    
    "ADAPT_DISABLED" = "ОТКЛЮЧЕН"
    "ADAPT_NO_CABLE" = "НЕТ КАБЕЛЯ"
    "ADAPT_WORKING"  = "РАБОТАЕТ"
    
    "Automatic (DHCP)" = "Автоматически (DHCP)"
    "Manual (Static)" = "Вручную (Статика)"
    "Default Gateway" = "Шлюз"
    "DNS Servers" = "DNS Серверы"
    "None" = "Отсутствует"
    "Current IP Address" = "Текущий IP-адрес"
    "Network Adapter" = "Сетевой адаптер"
    "Device Hardware" = "Устройство (Адаптер)"
    "Operating Mode" = "Режим работы"
    
    "Device Type" = "Тип устройства"
    "Virtual Machine" = "Виртуальная машина"
    "Laptop / Tablet" = "Ноутбук / Планшет"
    "Desktop PC" = "Настольный ПК"
    "Unknown Windows Device" = "Неизвестное Windows-устройство"
    
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
    
    "Clear adapter IP/Routing settings" = "Полная очистка IP и маршрутов адаптера"
    "Full Windows Network Reset (Winsock & Flush DNS)" = "Глубокий сброс стека сети Windows (Winsock / DNS)"
    "Are you SURE you want to clear adapter settings?" = "Ты УВЕРЕН, что хочешь удалить настройки IP адаптера?"
    "Adapter settings cleared successfully" = "Адаптер полностью очищен"
    "Resetting Windows network stack..." = "Выполняется сброс сетевого стека Windows..."
    "A computer restart is recommended after this reset." = "После этого сброса рекомендуется перезагрузить компьютер."
    
    "Enable DHCP" = "Включить DHCP"
    "Disable DHCP" = "Отключить DHCP"
    "Renew DHCP" = "Перезапустить DHCP"
    "Success!" = "Успешно!"
    
    "Set DNS to Automatic (DHCP)" = "Установить DNS автоматически (DHCP)"
    
    "Show available networks" = "Показать доступные сети вокруг"
    "Connect to saved network" = "Подключиться к сохраненной сети"
    "Show saved Wi-Fi passwords" = "Показать сохраненные пароли Wi-Fi"
    "This network is already saved, connecting..." = "Эта сеть уже сохранена, подключаемся..."
    "Enter network password (or press Enter if open)" = "Введи пароль от сети (или нажми Enter, если без пароля)"
    "Creating new network profile..." = "Создаем новый профиль сети..."
    "=== Saved Wi-Fi Passwords ===" = "=== Сохраненные пароли Wi-Fi ==="
    "Network" = "Сеть"
    "Password" = "Пароль"
    "No password (Open)" = "Без пароля (Открытая)"
    
    "Enter new MAC manually" = "Ввести новый MAC вручную"
    "Generate random MAC" = "Сгенерировать случайный MAC"
    "Restore original hardware MAC" = "Вернуть родной заводской MAC"
    "Enter new MAC (no dashes, e.g. 001122334455)" = "Введи новый MAC (без тире, например 001122334455)"
    "Applying settings..." = "Применяем настройки..."
    
    "Scanning local network: " = "Сканируем локальную сеть: "
    "Scanning..." = "Сканируем устройства, пожалуйста подожди..."
    "=== Found Devices ===" = "=== Найденные устройства ==="
    "=== Active Connections ===" = "=== Активные подключения ==="
    "=== System Information ===" = "=== Информация о системе ==="
    "=== Inactive Networks ===" = "=== Неактивные сети ==="
    "No connected and configured networks found" = "Подключенных и настроенных сетей не найдено"
    "Disabled" = "Отключено"
    "Cable disconnected" = "Кабель не подключен"
    "Status" = "Состояние"
    "No disabled adapters found" = "Нет отключенных адаптеров"
    
    "IP Address" = "IP-адрес"
    "MAC Address" = "MAC-адрес"
    "Hostname" = "Имя в сети"
    "Device Type/Info" = "Точный тип устройства"
    
    "This PC (Windows)" = "Этот компьютер (Windows)"
    "Router / Access Point" = "Роутер / Точка доступа"
    "Smartphone / Tablet (Private MAC)" = "Смартфон / Планшет (Случайный MAC)"
    "Network Printer" = "Сетевой принтер"
    "Unknown Device" = "Неизвестное устройство"
    "Adapter does not have a valid IP for scanning." = "Адаптер не имеет действительного IP-адреса для сканирования."
    
    "Load and apply a profile" = "Загрузить и применить профиль"
    "You don't have any saved profiles yet." = "У тебя пока нет сохраненных профилей."
    "They will appear here when you save settings while applying a new IP." = "Они появятся здесь, когда ты сохранишь настройки при установке нового IP-адреса."
}

function L([string]$text) {
    if ($global:SysLang -eq "ru" -and $global:RuDict.ContainsKey($text)) { return $global:RuDict[$text] }
    return $text
}

function Draw-Logo {
    Write-Host '                       _   _      _   _____      _   _     _     _ ' -ForegroundColor Cyan
    Write-Host '                      | \ | |    | | / ____|    | | | |  _| |_ _| |_ ' -ForegroundColor Cyan
    Write-Host '                      |  \| | ___| | | (___  ___| |_| |_|_   _|_   _|' -ForegroundColor DarkCyan
    Write-Host '                      | . ` |/ _ \ __|\___ \/ _ \ __| __| |_|   |_| ' -ForegroundColor DarkCyan
    Write-Host '                      | |\  |  __/ |_ ____) |  __/ |_| |_           ' -ForegroundColor Blue
    Write-Host '                      |_| \_|\___|\__|_____/\___|\__|\__|           ' -ForegroundColor Blue
    Write-Host '                      ===================================' -ForegroundColor Magenta
}

function Show-Menu {
    param([string]$Title, [array]$Items, [switch]$IsToggleMenu, [int]$DefaultIndex = 0, [switch]$ShowLogo)
    $selected = $DefaultIndex
    if ($selected -ge $Items.Count -or $selected -lt 0) { $selected = 0 }

    try { [Console]::CursorVisible = $false } catch {}
    Clear-Host
    
    if ($ShowLogo) { Draw-Logo; Write-Host "" }
    
    Write-Host "--- $Title ---" -ForegroundColor White
    if ($IsToggleMenu) {
        Write-Host " $(L '[UP/DOWN] Select | [RIGHT] Enable | [LEFT] Disable | [ESC] Back | [F5] Reload')" -ForegroundColor DarkGray
    } else {
        Write-Host " $(L '[UP/DOWN] Select | [RIGHT] Enter | [LEFT] Back | [F5] Reload')" -ForegroundColor DarkGray
    }
    Write-Host ""

    $startY = [Console]::CursorTop
    $maxWidth = 85

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
            if ($padLen -gt 0) { Write-Host (" " * $padLen) -ForegroundColor Black -BackgroundColor Black } else { Write-Host "" }
        }
        
        $keyInfo = [System.Console]::ReadKey($true)
        $key = $keyInfo.Key
        
        if ($key -eq 'F5') {
            Clear-Host
            Write-Host "`n   [ DEV MODE ] Reloading code from disk..." -ForegroundColor Magenta
            Start-Sleep -Milliseconds 300
            [Environment]::Exit(99)
        }

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
    Write-Host "`n$(L '[LEFT] Go Back') | [F5] Reload" -ForegroundColor DarkGray
    while ($true) {
        $key = [System.Console]::ReadKey($true).Key
        if ($key -eq 'F5') { [Environment]::Exit(99) }
        if ($key -match 'LeftArrow|Escape|Enter|RightArrow|Backspace') { break }
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

# --- Точное определение типа устройства (Для Пункта 1) ---
function Show-Status {
    Clear-Host
    
    # 1. Получаем общие данные о самом ПК (Железо) без мусора
    $pcInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    
    $vendor = if ($pcInfo.Manufacturer) { $pcInfo.Manufacturer.Trim() } else { "" }
    $model = if ($pcInfo.Model) { $pcInfo.Model.Trim() } else { "" }
    
    $hwString = L "Unknown Windows Device"
    if ($model -match "(?i)VirtualBox|VMware|Virtual Machine|KVM|Hyper-V") {
        $hwString = L "Virtual Machine"
        if ($vendor -and $vendor -notmatch "(?i)innotek|Microsoft|QEMU") { $hwString = "$vendor " + (L "Virtual Machine") }
    } else {
        $chassis = (Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
        $isLaptop = $false
        if ($chassis) {
            foreach ($c in $chassis) {
                if (@(8,9,10,11,12,14,31,32) -contains $c) { $isLaptop = $true; break }
            }
        }
        if ($isLaptop) { $hwString = L "Laptop / Tablet" } else { $hwString = L "Desktop PC" }
        # Убираем дефолтный мусор от китайских материнских плат
        if ($vendor -and $vendor -notmatch "(?i)System manufacturer|To be filled|Default string|O.E.M.") { 
            $hwString = "$vendor $hwString" 
        }
    }
    
    Write-Host (L "=== System Information ===") -ForegroundColor Cyan
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "$(L 'Device Type')      : $hwString" -ForegroundColor Yellow
    Write-Host "OS Version         : $($osInfo.Caption)" -ForegroundColor Gray
    Write-Host "Computer Name      : $($pcInfo.Name)" -ForegroundColor Gray
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
    
    Write-Host (L "=== Active Connections ===") -ForegroundColor Cyan
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    $found = $false
    Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
        $found = $true
        $ifaceAlias = $_.InterfaceAlias
        $ad = Get-NetAdapter -Name $ifaceAlias -ErrorAction SilentlyContinue
        $dhcpInfo = Get-NetIPInterface -InterfaceAlias $ifaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $dhcpStr = if ($dhcpInfo.Dhcp -eq 'Enabled') { L "Automatic (DHCP)" } else { L "Manual (Static)" }
        $dns = ($_.DNSServer | Where-Object AddressFamily -eq 2 | Select-Object -ExpandProperty ServerAddresses) -join ", "
        if (-not $dns) { $dns = L "None" }

        Write-Host "$(L 'Network Adapter')  : $ifaceAlias" -ForegroundColor Cyan
        Write-Host "$(L 'Device Hardware')  : $($ad.InterfaceDescription)" -ForegroundColor DarkGray
        Write-Host "$(L 'MAC Address')      : $($ad.MacAddress)" -ForegroundColor DarkGray
        Write-Host "$(L 'Operating Mode')   : $dhcpStr" -ForegroundColor Yellow
        Write-Host "$(L 'Current IP Address') : $($_.IPv4Address.IPAddress)" -ForegroundColor Green
        if ($_.IPv4DefaultGateway) { Write-Host "$(L 'Default Gateway')  : $($_.IPv4DefaultGateway.NextHop)" -ForegroundColor Green } 
        else { Write-Host "$(L 'Default Gateway')  : $(L 'None')" -ForegroundColor Red }
        Write-Host "$(L 'DNS Servers')      : $dns" -ForegroundColor Magenta
        Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    }
    if (-not $found) { Write-Host (L "No connected and configured networks found") -ForegroundColor Red }
    
    Write-Host ""
    Write-Host (L "=== Inactive Networks ===") -ForegroundColor Cyan
    Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    $inactive = Get-NetAdapter | Where-Object { $_.Status -ne 'Up' -and $_.InterfaceDescription -notlike '*Loopback*' }
    if ($inactive) {
        foreach ($a in $inactive) {
            $reason = if ($a.Status -eq 'Disabled') { L "Disabled" } elseif ($a.Status -eq 'Disconnected') { L "Cable disconnected" } else { $a.Status }
            Write-Host " $($a.InterfaceAlias)" -ForegroundColor Gray
            Write-Host "    $(L 'Device Hardware'): $($a.InterfaceDescription)" -ForegroundColor DarkGray
            Write-Host "    $(L 'Status')         : $reason" -ForegroundColor Red
            Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
        }
    } else {
        Write-Host " $(L 'No disabled adapters found')" -ForegroundColor DarkGray
        Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
    }

    Wait-Back
}

# --- Точное сканирование LAN ---
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

# Расширенная база вендоров для супер-точного определения типа
function Get-VendorByMac([string]$Mac) {
    $prefix = ($Mac.Replace("-", "").Substring(0,6)).ToUpper()
    $vendors = @{
        "001CB3"="Apple"; "002500"="Apple"; "28CFE9"="Apple"; "8C8590"="Apple"; "F8FFC2"="Apple"
        "B4F1CB"="Apple"; "C8B5B7"="Apple"; "3C0754"="Apple"; "4098AD"="Apple"; "0010FA"="Apple"
        "001451"="Apple"; "0016CB"="Apple"; "CCB8A8"="Apple"; "D4619D"="Apple"; "E0B52D"="Apple"
        "001A11"="Google"; "F88A5E"="Google"; "3C5AB4"="Google"
        "001E10"="Cisco"; "0014F2"="Cisco"; "001A6C"="Cisco"; "00259C"="Cisco"
        "001999"="Fujitsu"; "000B5D"="Fujitsu"
        "0017C4"="ASUS"; "001A92"="ASUS"; "001E8C"="ASUS"; "14DDA9"="ASUS"; "04D4C4"="ASUS"
        "000D3A"="Microsoft"; "00125A"="Microsoft"; "0017FA"="Microsoft"; "281878"="Microsoft"; "C8F650"="Microsoft"
        "001132"="Synology"; "00089B"="QNAP"; "245EBE"="QNAP"
        "E48D8C"="MikroTik"; "000C42"="MikroTik"; "D4CA6D"="MikroTik"
        "C04A00"="TP-Link"; "E848B8"="TP-Link"; "F81A67"="TP-Link"; "D807B6"="TP-Link"; "503EAA"="TP-Link"; "B0BE76"="TP-Link"
        "080027"="VirtualBox"; "000569"="VMware"; "000C29"="VMware"; "005056"="VMware"
        "001BDC"="Samsung"; "00215D"="Samsung"; "0023D6"="Samsung"; "CCB11A"="Samsung"; "D022BE"="Samsung"
        "002268"="Xiaomi"; "009ECA"="Xiaomi"; "286C07"="Xiaomi"; "38A4ED"="Xiaomi"; "7C49EB"="Xiaomi"
        "001A4B"="HP"; "001E0B"="HP"; "002264"="HP"; "0025B3"="HP"; "002655"="HP"
        "000000"="Xerox"; "000039"="Toshiba"; "000048"="Seiko"; "000074"="Ricoh"
        "000086"="Megahertz"; "0000C1"="Olicom"; "0000F8"="Digital"; "000102"="BBN"
        "F0B429"="Ubiquiti"; "0418D6"="Ubiquiti"; "44D9E7"="Ubiquiti"; "802AA8"="Ubiquiti"; "B4FBE4"="Ubiquiti"
        "0001E3"="Siemens"; "0001E6"="HP"; "0002B3"="Intel"; "0002B4"="Cisco"; "0003FF"="Microsoft"
        "00045A"="Linksys"; "0005CD"="D-Link"; "00095B"="Netgear"; "000FB5"="Netgear"; "00146C"="Netgear"
        "0018E7"="Camara / IP WebCam"; "001A79"="Oki"
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
    Write-Host (L "Scanning...") -ForegroundColor Yellow

    # Async Ping + Захват TTL
    $pingers = @(); $tasks = @()
    foreach ($i in 1..254) {
        $target = "$baseIP.$i"; $ping = New-Object System.Net.NetworkInformation.Ping
        $pingers += $ping; $tasks += $ping.SendPingAsync($target, 800)
    }
    [System.Threading.Tasks.Task]::WaitAll($tasks) | Out-Null
    
    $activeDevices = @()
    for ($i=0; $i -lt $tasks.Count; $i++) {
        if ($tasks[$i].Result.Status -eq 'Success') { 
            $activeDevices += @{
                IP = $tasks[$i].Result.Address.ToString()
                TTL = $tasks[$i].Result.Options.Ttl
            }
        }
        $pingers[$i].Dispose()
    }

    $dnsTasks = @{}
    foreach ($dev in $activeDevices) { $dnsTasks[$dev.IP] = [System.Net.Dns]::GetHostEntryAsync($dev.IP) }
    
    Clear-Host
    Write-Host (L "=== Found Devices ===") -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------" -ForegroundColor DarkCyan
    
    foreach ($dev in $activeDevices) {
        $a_ip = $dev.IP
        $ttl = $dev.TTL
        
        $mac = "00-00-00-00-00-00"
        if ($a_ip -eq $ipStr) { $mac = $localMac } else { $mac = Get-MacByIP $a_ip }

        $hostName = ""
        if ($dnsTasks[$a_ip].IsCompleted -and -not $dnsTasks[$a_ip].IsFaulted) { $hostName = $dnsTasks[$a_ip].Result.HostName }
        if (-not $hostName) { $hostName = L "Unknown Device" }

        # --- СВЕРХТОЧНАЯ ЭВРИСТИКА ТИПА УСТРОЙСТВА ---
        $devType = "PC / IoT Device"
        $osHint = "Linux/IoT"
        $vendor = Get-VendorByMac $mac

        # 1. Анализ ОС по TTL Пинга
        if ($ttl -gt 100 -and $ttl -le 130) { $osHint = "Windows" }
        elseif ($ttl -gt 200 -and $ttl -le 255) { $osHint = "Cisco / Core Network" }
        elseif ($ttl -gt 40 -and $ttl -le 65) { $osHint = "Linux / Android / iOS / macOS" }

        # 2. Интеллектуальный анализ
        if ($a_ip -eq $ipStr) { 
            $devType = L "This PC (Windows)" 
        } 
        elseif ($a_ip -eq $gwIP) { 
            $devType = if ($vendor) { "$vendor $((L 'Router / Access Point'))" } else { L "Router / Access Point" }
        } 
        else {
            $hostLow = $hostName.ToLower()
            
            if ($hostLow -match "iphone|ipad|macbook|apple|imac") { $devType = "Apple Device ($osHint)" }
            elseif ($hostLow -match "android|galaxy|sm-|pixel") { $devType = "Android Smartphone/Tablet" }
            elseif ($hostLow -match "tv|kdl-|bravia|webos|tizen|roku|chromecast") { $devType = "Smart TV / Media Player" }
            elseif ($hostLow -match "printer|hp-|epson|canon|brother|lexmark") { $devType = L "Network Printer" }
            elseif ($hostLow -match "desktop|laptop|pc-|win-") { $devType = "Windows PC / Laptop" }
            elseif ($hostLow -match "ds[0-9]|diskstation|qnap|nas") { $devType = "NAS Storage Server" }
            elseif ($vendor) {
                if ($vendor -eq "Apple") { $devType = "Apple iPhone / Mac" }
                elseif ($vendor -match "Samsung|Xiaomi|Huawei|Oppo|OnePlus") { $devType = "$vendor Smartphone / Smart Device" }
                elseif ($vendor -match "Sony|LG") { $devType = "$vendor Smart TV / Console" }
                elseif ($vendor -match "TP-Link|ASUS|D-Link|Netgear|MikroTik|Ubiquiti|Keenetic|Zyxel|Cisco|Linksys") { $devType = "$vendor Network / Router" }
                elseif ($vendor -match "HP|Canon|Epson|Brother|Oki|Xerox|Ricoh") { $devType = "$vendor $((L 'Network Printer'))" }
                elseif ($vendor -match "Synology|QNAP") { $devType = "$vendor NAS Storage" }
                elseif ($vendor -match "Microsoft") { $devType = "Microsoft Xbox / Surface" }
                elseif ($vendor -match "Nintendo") { $devType = "Nintendo Switch" }
                else { $devType = "$vendor Device ($osHint)" }
            }
            else {
                try {
                    $firstOctet = [convert]::ToInt32($mac.Substring(0,2), 16)
                    if (($firstOctet -band 2) -eq 2) { $devType = L "Smartphone / Tablet (Private MAC)" }
                    elseif ($osHint -eq "Windows") { $devType = "Windows PC" }
                } catch {}
            }
        }

        Write-Host "$(L 'IP Address')       : $a_ip" -ForegroundColor Green
        Write-Host "$(L 'MAC Address')      : $mac" -ForegroundColor Gray
        Write-Host "$(L 'Hostname')         : $hostName" -ForegroundColor White
        Write-Host "$(L 'Device Type/Info') : $devType" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------------" -ForegroundColor DarkCyan
    }
    
    Wait-Back
}

function Manage-DNS {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = "Cloudflare (1.1.1.1, 1.0.0.1)"; Value = "1.1.1.1,1.0.0.1"}
            @{Name = "Google Public DNS (8.8.8.8, 8.8.4.4)"; Value = "8.8.8.8,8.8.4.4"}
            @{Name = "AdGuard DNS - AdBlock (94.140.14.14, 94.140.15.15)"; Value = "94.140.14.14,94.140.15.15"}
            @{Name = "Yandex DNS (77.88.8.8, 77.88.8.1)"; Value = "77.88.8.8,77.88.8.1"}
            @{Name = L "Set DNS to Automatic (DHCP)"; Value = "AUTO"}
            @{Name = L "Back"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Quick DNS Setup (Cloudflare, Google, etc.)") -Items $items -DefaultIndex $idx
        $idx = $actRes.Index
        if ($actRes.Action -eq 'Back') { break }
        
        $iface = Get-AdapterMenu (L "Select an adapter:")
        if (-not $iface) { continue }
        Ensure-AdapterEnabled $iface
        Clear-Host
        
        if ($actRes.Value -eq "AUTO") {
            Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue | Out-Null
        } else {
            $servers = $actRes.Value -split ","
            Set-DnsClientServerAddress -InterfaceAlias $iface -ServerAddresses $servers -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Host "`n$(L 'Success!')" -ForegroundColor Green
        Wait-Back
    }
}

function Manage-Resets {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = L "Clear adapter IP/Routing settings"; Value = "1"}
            @{Name = L "Full Windows Network Reset (Winsock & Flush DNS)"; Value = "2"}
            @{Name = L "Back"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Network Resets & Troubleshooting") -Items $items -DefaultIndex $idx
        $idx = $actRes.Index
        if ($actRes.Action -eq 'Back') { break }
        
        if ($actRes.Value -eq "1") {
            $iface = Get-AdapterMenu (L "Select an adapter:")
            if ($iface) {
                $svMenu = @( @{Name=L "Yes"; Value=$true}, @{Name=L "No"; Value=$false} )
                $confirmRes = Show-Menu -Title (L "Are you SURE you want to clear adapter settings?") -Items $svMenu
                if ($confirmRes.Action -ne 'Back' -and $confirmRes.Value -eq $true) {
                    Clear-Host
                    Remove-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                    Remove-NetRoute -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                    Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue
                    Write-Host "`n$(L 'Adapter settings cleared successfully')" -ForegroundColor Green
                    Wait-Back
                }
            }
        } elseif ($actRes.Value -eq "2") {
            Clear-Host
            Write-Host (L "Resetting Windows network stack...") -ForegroundColor Cyan
            Write-Host "----------------------------------------" -ForegroundColor DarkCyan
            ipconfig /flushdns | Out-Host
            netsh winsock reset | Out-Host
            netsh int ip reset | Out-Host
            Write-Host "----------------------------------------" -ForegroundColor DarkCyan
            Write-Host "`n$(L 'Success!')" -ForegroundColor Green
            Write-Host (L "A computer restart is recommended after this reset.") -ForegroundColor Yellow
            Wait-Back
        }
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

function Manage-WiFi {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = L "Show available networks"; Value = "1"}
            @{Name = L "Connect to saved network"; Value = "2"}
            @{Name = L "Show saved Wi-Fi passwords"; Value = "3"}
            @{Name = L "Back"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Wi-Fi Management (Search, Connect, Passwords)") -Items $items -DefaultIndex $idx
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
                Clear-Host
                netsh wlan connect name="$($targetRes.Value)" | Out-Null
                Write-Host "`n$(L 'Success!')" -ForegroundColor Green
                Wait-Back
            }
        } elseif ($act -eq "3") {
            Clear-Host
            Write-Host (L "=== Saved Wi-Fi Passwords ===") -ForegroundColor Cyan
            Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
            
            $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
            if ($profiles.Count -eq 0) {
                Write-Host "No Wi-Fi profiles found." -ForegroundColor DarkGray
            } else {
                foreach ($p in $profiles) {
                    $keyLine = netsh wlan show profile name="$p" key=clear | Select-String "Key Content"
                    $pwd = if ($keyLine) { ($keyLine.Line -split ':', 2)[1].Trim() } else { L "No password (Open)" }
                    Write-Host "$(L 'Network')  : $p" -ForegroundColor Green
                    Write-Host "$(L 'Password') : $pwd" -ForegroundColor Yellow
                    Write-Host "------------------------------------------------" -ForegroundColor DarkCyan
                }
            }
            Wait-Back
        }
    }
}

function Main-Menu {
    $mainIndex = 0
    while ($true) {
        $items = @(
            @{Name = L "Show current network settings"; Value = 1}
            @{Name = L "Change primary IP address"; Value = 2}
            @{Name = L "Add secondary IP address"; Value = 3}
            @{Name = L "Manage DHCP (Enable / Disable / Renew)"; Value = 4}
            @{Name = L "Quick DNS Setup (Cloudflare, Google, etc.)"; Value = 5}
            @{Name = L "Network Resets & Troubleshooting"; Value = 6}
            @{Name = L "Saved profiles"; Value = 7}
            @{Name = L "Enable / Disable network adapters"; Value = 8}
            @{Name = L "Wi-Fi Management (Search, Connect, Passwords)"; Value = 9}
            @{Name = L "MAC Address Spoofing"; Value = 10}
            @{Name = L "LAN Scanner"; Value = 11}
            @{Name = L "Exit"; Value = 0}
        )
        
        $choice = Show-Menu -Title "netsett++ Main Menu" -Items $items -DefaultIndex $mainIndex -ShowLogo
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
            5 { Manage-DNS }
            6 { Manage-Resets }
            7 {
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
                    $confirmTitle = "Apply '$($p.Name)' to '$($p.Interface)'?"
                    if ($global:SysLang -eq "ru") { $confirmTitle = "Применить '$($p.Name)' к '$($p.Interface)'?" }
                    
                    $confirmRes = Show-Menu -Title $confirmTitle -Items $svMenu
                    if ($confirmRes.Action -ne 'Back' -and $confirmRes.Value -eq $true) {
                        Clear-Host
                        Set-StaticIP -InterfaceAlias $p.Interface -IPAddress $p.IP -PrefixLength $p.Mask -DefaultGateway $p.Gateway -Mode 'Replace'
                    }
                }
            }
            8 { Manage-Adapters }
            9 { Manage-WiFi }
            10 {
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
            11 { Scan-LAN }
        }
    }
}

try { Main-Menu } catch {
    Clear-Host
    Write-Host "`n[КРИТИЧЕСКАЯ ОШИБКА / CRITICAL ERROR]" -ForegroundColor White -BackgroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-Back
}
try { [Console]::CursorVisible = $true } catch {}
