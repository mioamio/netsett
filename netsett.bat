<# : 2>nul
@echo off
chcp 65001 >nul
title netsett++ (Dev Mode)

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

:: Если PowerShell вернул код 99 (нажата F5 или Ctrl+L), мгновенно перезапускаем
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
$LangCacheFile = "$env:TEMP\netsett_lang.txt"

# --- ГЛОБАЛЬНЫЙ КЭШ ---
$global:AdCache = $null
$global:AdCacheTime = [DateTime]::MinValue

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

# Подгонка размера окна
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

# --- СИСТЕМА ЛОКАЛИЗАЦИИ ---
if (Test-Path $LangCacheFile) {
    $global:SysLang = (Get-Content $LangCacheFile -Raw).Trim()
} else {
    $l1 = (Get-UICulture).TwoLetterISOLanguageName
    $l2 = (Get-Culture).TwoLetterISOLanguageName
    if ($l1 -eq 'ru' -or $l2 -eq 'ru') { $global:SysLang = "ru" } else { $global:SysLang = "en" }
}

$global:RuDict = @{
    "[UP/DOWN] Select | [RIGHT] Enter | [LEFT] Back | [Ctrl+L] Lang" = "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Войти | [ВЛЕВО] Назад | [Ctrl+L] Язык"
    "[UP/DOWN] Select | [RIGHT] Enable | [LEFT] Disable | [ESC] Back | [Ctrl+L] Lang" = "[ВВЕРХ/ВНИЗ] Выбор | [ВПРАВО] Вкл | [ВЛЕВО] Выкл | [ESC] Назад | [Ctrl+L] Язык"
    "[LEFT] Go Back | [Ctrl+L] Lang" = "[ВЛЕВО] Назад | [Ctrl+L] Язык"
    "Back" = "Назад"
    "Yes" = "Да"
    "No" = "Нет"
    "Exit" = "Выход"
    "Error" = "Ошибка"
    
    "Show current network settings" = "Показать текущие настройки адаптеров"
    "Change primary IP address" = "Замена основного IP-адреса"
    "Add secondary IP address" = "Оставить старый IP и добавить еще один"
    "Manage DHCP (Enable / Disable / Renew)" = "Управление DHCP (Включить / Отключить / Обновить)"
    "Quick DNS Setup (Cloudflare, Google, etc.)" = "Быстрая смена DNS (Cloudflare, Google и др.)"
    "Network Resets & Troubleshooting" = "Сброс сети и устранение неполадок"
    "Manage Saved Profiles" = "Управление сохраненными профилями"
    "Enable / Disable network adapters" = "Включение / Отключение адаптеров"
    "Wi-Fi Management (Search, Connect, Passwords)" = "Управление Wi-Fi (Радар, Пароли, Каналы, Приоритет)"
    "MAC Address Spoofing" = "Подмена MAC-адреса (Spoofing)"
    "LAN Scanner" = "LAN Сканер (Поиск устройств в сети)"
    
    "Optimize MTU (Find perfect packet size)" = "Оптимизация MTU (Поиск идеального пакета)"
    "Wi-Fi Channel Analyzer & Optimizer" = "Анализатор зашумленности каналов Wi-Fi"
    "Manage Wi-Fi Network Priorities" = "Менеджер приоритетов сетей Wi-Fi"
    
    "=== MTU Optimizer ===" = "=== Оптимизатор MTU ==="
    "This tool will ping a reliable server to find your perfect packet size." = "Этот инструмент найдет максимальный размер пакета для вашей сети."
    "Using the correct MTU avoids fragmentation, reduces ping, and fixes loading bugs." = "Правильный MTU устраняет фрагментацию, снижает пинг и ускоряет загрузку."
    "Press [ENTER] to Start Test or [ESC] to Cancel" = "Нажми [ENTER] для запуска теста или [ESC] для отмены"
    
    "Testing packet size" = "Тестируем размер пакета"
    "Fragmented. Lowering size..." = "Фрагментирован. Уменьшаем размер..."
    "Success. Refining..." = "Успешно. Уточняем..."
    "Perfect MTU Found!" = "Идеальный MTU найден!"
    "Press [Y] to Apply, or any other key to Cancel..." = "Нажми [Y] для применения, или любую другую кнопку для отмены..."
    "Applying optimal settings to Wi-Fi adapter..." = "Применяем оптимальные настройки к Wi-Fi адаптеру..."
    "Move this network to TOP Priority?" = "Поднять эту сеть на 1-е место (Высший приоритет)?"
    "Network moved to priority 1." = "Сеть перемещена на 1-е место."
    
    "Randomized (Private) MAC" = "Случайный (Приватный) MAC"
    "(This PC)" = "(Этот ПК)"
    "(Gateway)" = "(Шлюз / Роутер)"
    
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
    
    "No network adapters found in the system" = "Сетевых адаптеров в системе не найдено"
    "Select an adapter:" = "Выбери адаптер:"
    "Enabling adapter" = "Включаем адаптер"
    "Disabling adapter" = "Отключаем адаптер"
    
    "Enter IP address (e.g. 192.168.1.50)" = "Введи IP-адрес (например 192.168.1.50)"
    "Enter subnet mask (e.g. 24)" = "Введи маску подсети (например 24)"
    "Enter Gateway IP (Enter to skip)" = "Введи IP-адрес шлюза (Enter - пропустить)"
    "Save these settings as a profile?" = "Сохранить эти настройки как профиль?"
    "Enter a name for the profile" = "Придумай название для профиля"
    "Settings successfully applied" = "Настройки успешно применены"
    "Error applying settings." = "Ошибка применения настроек."
    
    "Clear adapter IP/Routing settings" = "Полная очистка IP и маршрутов адаптера"
    "Full Windows Network Reset (Winsock & Flush DNS)" = "Глубокий сброс стека сети Windows (Winsock / DNS)"
    "Are you SURE you want to clear adapter settings?" = "УВЕРЕН, что хочешь удалить настройки адаптера?"
    "Adapter settings cleared successfully" = "Адаптер полностью очищен"
    "Resetting Windows network stack..." = "Сброс сетевого стека Windows..."
    "A computer restart is recommended after this reset." = "Рекомендуется перезагрузить компьютер."
    
    "Enable DHCP" = "Включить DHCP"
    "Disable DHCP" = "Отключить DHCP"
    "Renew DHCP" = "Перезапустить DHCP"
    "Success!" = "Успешно!"
    
    "Set DNS to Automatic (DHCP)" = "Установить DNS автоматически (DHCP)"
    
    "Show available networks (Live Radar)" = "Показать доступные сети вокруг (Live-Радар)"
    "Connect to saved network" = "Подключиться к сохраненной сети"
    "Show saved Wi-Fi passwords" = "Показать сохраненные пароли Wi-Fi"
    "Optimize Wi-Fi Power (Boost Signal)" = "Оптимизировать мощность Wi-Fi (Усилить сигнал)"
    "Enable Wi-Fi Boost (Max Performance)" = "Включить усиление Wi-Fi (Макс. производительность)"
    "Disable Wi-Fi Boost (Balanced/Default)" = "Отключить усиление Wi-Fi (По умолчанию)"
    "Applying Max Performance Power Plan to Wi-Fi adapter..." = "Применяем профиль Максимальной Производительности..."
    "Wi-Fi transmission power boosted successfully!" = "Мощность передачи Wi-Fi успешно увеличена!"
    "Restoring default Power Plan for Wi-Fi adapter..." = "Возвращаем стандартные настройки питания Wi-Fi..."
    "Wi-Fi power settings restored to default." = "Настройки питания Wi-Fi возвращены по умолчанию."
    
    "This network is already saved, connecting..." = "Эта сеть уже сохранена, подключаемся..."
    "Enter network password (Press Enter to abort)" = "Введи пароль от сети (Нажми Enter для отмены)"
    "Action canceled by user." = "Действие отменено пользователем."
    "Creating new network profile..." = "Создаем новый профиль сети..."
    "=== Saved Wi-Fi Passwords ===" = "=== Сохраненные пароли Wi-Fi ==="
    "Network" = "Сеть"
    "Password" = "Пароль"
    "No password (Open)" = "Без пароля (Открытая)"
    
    "Enter new MAC manually" = "Ввести новый MAC вручную"
    "Generate random MAC" = "Сгенерировать случайный MAC"
    "Restore original hardware MAC" = "Вернуть родной заводской MAC"
    "Enter new MAC (no dashes, e.g. 001122334455)" = "Введи новый MAC (без тире, напр. 001122334455)"
    "Applying settings..." = "Применяем настройки..."
    
    "=== Found Devices (Scanning in background...) ===" = "=== Найденные устройства (Фоновое сканирование...) ==="
    "=== Active Local Adapters (This PC) ===" = "=== Активные локальные адаптеры (Этот ПК) ==="
    "=== Disconnected / Disabled Adapters ===" = "=== Отключенные / Неактивные адаптеры ==="
    "No connected and configured networks found" = "Подключенных и настроенных сетей не найдено"
    "Disabled" = "Отключено"
    "Cable disconnected" = "Кабель не подключен"
    "Status" = "Состояние"
    "No disabled adapters found" = "Нет отключенных адаптеров"
    
    "IP Address" = "IP-адрес"
    "MAC Address" = "MAC-адрес"
    "Hostname" = "Имя в сети"
    "Unknown Device" = "Неизвестное устройство"
    "Adapter does not have a valid IP for scanning." = "Адаптер не имеет действительного IP-адреса для сканирования."
    
    "Apply Profile" = "Применить профиль"
    "Rename Profile" = "Переименовать профиль"
    "Delete Profile" = "Удалить профиль"
    "Cancel" = "Отмена"
    "Profile deleted." = "Профиль удален."
    "Enter new name for the profile" = "Введи новое имя для профиля"
    "Profile renamed." = "Профиль переименован."
    "You don't have any saved profiles yet." = "У тебя пока нет сохраненных профилей."
    "They will appear here when you save settings while applying a new IP." = "Они появятся здесь при сохранении настроек."
}

function L([string]$text) {
    if ($global:SysLang -eq "ru" -and $global:RuDict.ContainsKey($text)) { return $global:RuDict[$text] }
    return $text
}

function Reset-Line {
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition(0, $y)
    $w = $Host.UI.WindowSize.Width - 1
    if ($w -lt 0) { $w = 110 }
    Write-Host (" " * $w) -NoNewline -BackgroundColor Black
    [Console]::SetCursorPosition(0, $y)
}

function Clear-Tail {
    $y = [Console]::CursorTop
    $max = $Host.UI.WindowSize.Height - 1
    while ($y -lt $max) {
        Reset-Line
        Write-Host ""
        $y++
    }
}

function Write-Centered([string]$Text, [string]$FgColor="White") {
    Reset-Line
    $w = $Host.UI.WindowSize.Width
    if ($w -lt 20) { $w = 110 }
    $x = [math]::Max(0, [math]::Floor(($w - $Text.Length) / 2))
    [Console]::SetCursorPosition($x, [Console]::CursorTop)
    Write-Host $Text -ForegroundColor $FgColor
}

function Draw-Logo {
    $logo = @(
        '   _   _      _    _____     _   _     _     _ ',
        '  | \ | |    | |  / ____|   | | | |  _| |_ _| |_ ',
        '  |  \| | ___| |_(  (__  ___| |_| |_|_   _|_   _|',
        '  | . ` |/ _ \ __|\___ \/ _ \ __| __| |_|   |_|  ',
        '  | |\  |  __/ |_ ____) | __/  |_| |_            ',
        '  |_| \_|\___|\__|_____/\___|\__|\__|            ',
        '  ==================================='
    )
    $colors = @("Cyan","Cyan","DarkCyan","DarkCyan","Blue","Blue","Magenta")
    
    $w = $Host.UI.WindowSize.Width
    if ($w -lt 20) { $w = 110 }
    $startX = [math]::Max(0, [math]::Floor(($w - 49) / 2))

    for ($i = 0; $i -lt $logo.Count; $i++) {
        Reset-Line
        [Console]::SetCursorPosition($startX, [Console]::CursorTop)
        Write-Host $logo[$i] -ForegroundColor $colors[$i]
    }
}

function Get-AdaptersCached {
    if ($global:AdCache -eq $null -or ([DateTime]::Now - $global:AdCacheTime).TotalSeconds -gt 3) {
        $global:AdCache = @(Get-NetAdapter | Where-Object { $_.InterfaceDescription -notlike '*Loopback*' })
        $global:AdCacheTime = [DateTime]::Now
    }
    return $global:AdCache
}
function Flush-AdapterCache { $global:AdCache = $null }

# --- ЧИСТАЯ БАЗА IEEE (Только 100% официальные вендоры) + API ---
$global:MacDB = @{}
$rawMacData = "Apple=000393,000A27,001124,001451,001C42,001E52,0023DF,0025BC,28CFE9,8C8590,F8FFC2,5CAFA7|Intel=0002B3,001175,0013E8,001517,001B21,001CC0,001E67,001F3B,00215C,0022FB,0024D2,0026C7,7CC2C6|Cisco=00000C,000142,000143,000E04,001011,001E10|Microsoft=00155D,000D3A,281878|VMware=005056,000569,000C29|VirtualBox=080027|Synology=001132|Google=001A11,3C5AB4,F88FCA|Sony=000E08,001315,0015C1,0019C5,001A8A,40B0FA|Nintendo=000E8E,001656,0017AB,0009BF"

foreach ($group in $rawMacData.Split('|')) {
    $parts = $group.Split('=')
    if ($parts.Count -eq 2) {
        $vendor = $parts[0].Replace("_", " ")
        foreach ($prefix in $parts[1].Split(',')) { $global:MacDB[$prefix] = $vendor }
    }
}

function Get-VendorByMac([string]$Mac) {
    $cleanMac = $Mac.Replace("-", "").Replace(":", "").ToUpper()
    if ($cleanMac.Length -ge 6) {
        $prefix = $cleanMac.Substring(0, 6)
        
        # 1. Проверка на приватный (рандомизированный) MAC
        try {
            $firstOctet = [convert]::ToInt32($cleanMac.Substring(0,2), 16)
            if (($firstOctet -band 2) -eq 2) { return (L "Randomized (Private) MAC") }
        } catch {}

        # 2. Проверка строгой локальной базы
        if ($global:MacDB.ContainsKey($prefix)) { return $global:MacDB[$prefix] }
        
        # 3. Онлайн поиск через API (Fail-safe)
        try {
            $url = "https://api.macvendors.com/$prefix"
            $apiVendor = Invoke-RestMethod -Uri $url -TimeoutSec 2 -ErrorAction Stop
            # Убираем скучные суффиксы компаний для красоты
            $cleanVendor = $apiVendor -replace '(?i)(,?\s*(Inc\.|Ltd\.|Co\.|Corporation|GmbH|LLC|Corp\.?)).*$', ''
            $global:MacDB[$prefix] = $cleanVendor # Кэшируем результат
            return $cleanVendor
        } catch {}
    }
    return ""
}

function Show-Menu {
    param([string]$Title, [array]$Items, [switch]$IsToggleMenu, [int]$DefaultIndex = 0, [switch]$ShowLogo, [switch]$DynamicWiFi)
    $selected = $DefaultIndex
    if ($selected -ge $Items.Count -or $selected -lt 0) { $selected = 0 }

    try { [Console]::CursorVisible = $false } catch {}
    Clear-Host
    
    $forceRedraw = $true
    $lastWiFiScan = [DateTime]::MinValue
    $lastWinWidth = $Host.UI.WindowSize.Width
    $lastWinHeight = $Host.UI.WindowSize.Height

    while ($true) {
        if ($Host.UI.WindowSize.Width -ne $lastWinWidth -or $Host.UI.WindowSize.Height -ne $lastWinHeight) {
            $lastWinWidth = $Host.UI.WindowSize.Width
            $lastWinHeight = $Host.UI.WindowSize.Height
            Clear-Host
            $forceRedraw = $true
        }

        if ($DynamicWiFi -and ([DateTime]::Now - $lastWiFiScan).TotalSeconds -gt 3) {
            $lastWiFiScan = [DateTime]::Now
            $nets = @(netsh wlan show networks | Where-Object { $_ -match "SSID" } | ForEach-Object { ($_ -split ':', 2)[1].Trim() } | Where-Object { $_ -ne "" } | Select-Object -Unique)
            $newItems = @()
            foreach ($n in $nets) { $newItems += @{Name = $n; Value = $n} }
            $newItems += @{Name = L "Back"; Value = 'BACK'}
            
            $changed = $false
            if ($newItems.Count -ne $Items.Count) {
                $changed = $true
            } else {
                for ($i = 0; $i -lt $Items.Count; $i++) {
                    if ($Items[$i].Value -ne $newItems[$i].Value) { $changed = $true; break }
                }
            }
            
            if ($changed -or $Items.Count -le 1) {
                $selectedVal = if ($Items.Count -gt 0) { $Items[$selected].Value } else { $null }
                $Items = $newItems
                $newIdx = 0
                for ($i=0; $i -lt $Items.Count; $i++) {
                    if ($Items[$i].Value -eq $selectedVal) { $newIdx = $i; break }
                }
                $selected = $newIdx
                $forceRedraw = $true
            }
        }

        if ($forceRedraw) {
            [Console]::SetCursorPosition(0, 0)
            if ($ShowLogo) { 
                Draw-Logo
                Write-Host "" 
            }
            
            Write-Centered "--- $Title ---" "White"
            if ($IsToggleMenu) {
                Write-Centered (L '[UP/DOWN] Select | [RIGHT] Enable | [LEFT] Disable | [ESC] Back | [Ctrl+L] Lang') "DarkGray"
            } else {
                Write-Centered (L '[UP/DOWN] Select | [RIGHT] Enter | [LEFT] Back | [Ctrl+L] Lang') "DarkGray"
            }
            Write-Host ""
            
            $maxLen = 0
            foreach ($item in $Items) { if ($item.Name.Length -gt $maxLen) { $maxLen = $item.Name.Length } }
            $menuBlockW = $maxLen + 4 
            
            $w = $Host.UI.WindowSize.Width
            if ($w -lt 20) { $w = 110 }
            $startX = [math]::Max(0, [math]::Floor(($w - $menuBlockW) / 2))
            
            for ($i = 0; $i -lt $Items.Count; $i++) {
                Reset-Line
                [Console]::SetCursorPosition($startX, [Console]::CursorTop)
                
                $isBackAction = ($Items[$i].Value -eq 'BACK' -or $Items[$i].Value -eq 0)
                
                if ($i -eq $selected) {
                    $prefix = if ($isBackAction) { "  < " } else { "  > " }
                    $fg = "Black"
                    $bg = "Cyan"
                } else {
                    $prefix = "    "
                    $fg = "Gray"
                    $bg = "Black"
                }
                
                $paddedName = $Items[$i].Name.PadRight($maxLen, ' ')
                Write-Host "$prefix$paddedName" -ForegroundColor $fg -BackgroundColor $bg
            }
            
            Clear-Tail
            $forceRedraw = $false
        }
        
        $key = $null
        for ($k = 0; $k -lt 5; $k++) {
            if ([Console]::KeyAvailable) {
                $keyInfo = [System.Console]::ReadKey($true)
                $key = $keyInfo.Key
                break
            }
            Start-Sleep -Milliseconds 20
        }

        if ($key) {
            if (($keyInfo.Modifiers -band [ConsoleModifiers]::Control) -and ($key -eq [ConsoleKey]::L)) {
                $global:SysLang = if ($global:SysLang -eq 'ru') { 'en' } else { 'ru' }
                Set-Content -Path $LangCacheFile -Value $global:SysLang -Encoding UTF8
                return @{ Action = 'LangChange'; Value = $null; Index = $selected }
            }

            if ($key -eq 'F5') { [Environment]::Exit(99) }

            $forceRedraw = $true
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
}

function Wait-Back {
    Write-Host ""
    Write-Centered (L '[LEFT] Go Back | [Ctrl+L] Lang') "DarkGray"
    while ($true) {
        if ([Console]::KeyAvailable) {
            $keyInfo = [System.Console]::ReadKey($true)
            $key = $keyInfo.Key
            
            if (($keyInfo.Modifiers -band [ConsoleModifiers]::Control) -and ($key -eq [ConsoleKey]::L)) {
                $global:SysLang = if ($global:SysLang -eq 'ru') { 'en' } else { 'ru' }
                Set-Content -Path $LangCacheFile -Value $global:SysLang -Encoding UTF8
                return "LANG_CHANGED"
            }

            if ($key -eq 'F5') { [Environment]::Exit(99) }
            if ($key -match 'LeftArrow|Escape|Enter|RightArrow|Backspace') { break }
        }
        Start-Sleep -Milliseconds 50
    }
    return "BACK"
}

function Show-Message {
    param([array]$Lines, [array]$Colors)
    while ($true) {
        Clear-Host
        Write-Host ""
        for ($i=0; $i -lt $Lines.Count; $i++) {
            $c = if ($i -lt $Colors.Count) { $Colors[$i] } else { "White" }
            Write-Centered (L $Lines[$i]) $c
        }
        if ((Wait-Back) -eq "LANG_CHANGED") { continue }
        break
    }
}

function Get-TextInput([string]$PromptMsg) {
    try { [Console]::CursorVisible = $true } catch {}
    Clear-Host
    Write-Host ""
    Write-Centered $PromptMsg "Cyan"
    
    $w = $Host.UI.WindowSize.Width
    if ($w -lt 20) { $w = 110 }
    $startX = [math]::Max(0, [math]::Floor(($w - 30) / 2))
    
    [Console]::SetCursorPosition($startX, [Console]::CursorTop)
    Write-Host " > " -NoNewline -ForegroundColor Yellow
    $val = Read-Host
    try { [Console]::CursorVisible = $false } catch {}
    return $val
}

function Get-AdapterMenu {
    param([string]$TitleKey)
    $idx = 0
    while ($true) {
        $adapters = Get-AdaptersCached
        if ($adapters.Count -eq 0) { 
            Show-Message @("No network adapters found in the system") @("Red")
            return $null 
        }
        $items = @()
        foreach ($a in $adapters) {
            if ($a.Status -eq 'Up') { $st = L "ADAPT_WORKING" }
            elseif ($a.Status -eq 'Disabled') { $st = L "ADAPT_DISABLED" }
            elseif ($a.Status -eq 'Disconnected') { $st = L "ADAPT_NO_CABLE" }
            else { $st = $a.Status }
            
            $items += @{ Name = "$($a.InterfaceAlias) [$st]"; Value = $a.InterfaceAlias }
        }
        $items += @{ Name = L "Back"; Value = 'BACK' }
        
        $res = Show-Menu -Title (L $TitleKey) -Items $items -DefaultIndex $idx
        if ($res.Action -eq 'LangChange') { $idx = $res.Index; continue }
        if ($res.Action -eq 'Back') { return $null }
        return $res.Value
    }
}

function Test-IPAddress { param([string]$IP); return [System.Net.IPAddress]::TryParse($IP, [ref]0) }

function Ensure-AdapterEnabled {
    param([string]$Alias)
    $ad = Get-AdaptersCached | Where-Object { $_.InterfaceAlias -eq $Alias }
    if ($ad -and $ad.Status -eq 'Disabled') {
        Enable-NetAdapter -Name $Alias -Confirm:$false
        Flush-AdapterCache
        Start-Sleep 1
    }
}

function Show-Status {
    $blockW = 85
    while ($true) {
        Clear-Host
        [Console]::SetCursorPosition(0, 0)
        Write-Host ""
        Write-Centered (L "=== Active Local Adapters (This PC) ===") "Cyan"
        Write-Centered "--------------------------------------------------------" "DarkCyan"
        Write-Host ""
        
        $w = $Host.UI.WindowSize.Width
        if ($w -lt 20) { $w = 110 }
        $startX = [math]::Max(0, [math]::Floor(($w - $blockW) / 2))

        $found = $false
        $adapters = Get-AdaptersCached
        
        foreach ($ad in $adapters) {
            if ($ad.Status -eq 'Up') {
                $ipObj = Get-NetIPAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($ipObj) {
                    $found = $true
                    $dhcpInfo = Get-NetIPInterface -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                    $dhcpStr = if ($dhcpInfo.Dhcp -eq 'Enabled') { L "Automatic (DHCP)" } else { L "Manual (Static)" }
                    
                    $route = Get-NetRoute -InterfaceIndex $ad.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
                    $gw = if ($route) { $route.NextHop } else { $null }

                    $dnsObj = Get-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ErrorAction SilentlyContinue
                    $dns = ($dnsObj.ServerAddresses) -join ", "
                    if (-not $dns) { $dns = L "None" }

                    $vendor = Get-VendorByMac $ad.MacAddress
                    $macDisp = if ($vendor) { "$($ad.MacAddress) [$vendor]" } else { $($ad.MacAddress) }

                    Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Network Adapter').PadRight(22)) : $($ad.InterfaceAlias)" -ForegroundColor Cyan
                    Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Device Hardware').PadRight(22)) : $($ad.InterfaceDescription)" -ForegroundColor DarkGray
                    Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'MAC Address').PadRight(22)) : $macDisp" -ForegroundColor DarkGray
                    Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Operating Mode').PadRight(22)) : $dhcpStr" -ForegroundColor Yellow
                    Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Current IP Address').PadRight(22)) : $($ipObj.IPAddress)" -ForegroundColor Green
                    
                    if ($gw) { 
                        Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Default Gateway').PadRight(22)) : $gw" -ForegroundColor Green 
                    } else { 
                        Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Default Gateway').PadRight(22)) : $(L 'None')" -ForegroundColor Red 
                    }
                    Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'DNS Servers').PadRight(22)) : $dns" -ForegroundColor Magenta
                    Write-Host ""
                }
            }
        }
        
        if (-not $found) { Write-Centered (L "No connected and configured networks found") "Red" }
        
        Write-Host ""
        Write-Centered (L "=== Disconnected / Disabled Adapters ===") "Cyan"
        Write-Centered "--------------------------------------------------------" "DarkCyan"
        Write-Host ""
        
        $inactiveFound = $false
        foreach ($a in $adapters) {
            if ($a.Status -ne 'Up') {
                $inactiveFound = $true
                $reason = if ($a.Status -eq 'Disabled') { L "Disabled" } elseif ($a.Status -eq 'Disconnected') { L "Cable disconnected" } else { $a.Status }
                Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$($a.InterfaceAlias)" -ForegroundColor Gray
                Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "  $((L 'Device Hardware').PadRight(20)) : $($a.InterfaceDescription)" -ForegroundColor DarkGray
                Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "  $((L 'Status').PadRight(20)) : $reason" -ForegroundColor Red
                Write-Host ""
            }
        }
        
        if (-not $inactiveFound) {
            Write-Centered (L "No disabled adapters found") "DarkGray"
        }

        Clear-Tail
        if ((Wait-Back) -eq "LANG_CHANGED") { continue }
        break
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
        if ($res -eq 0) { return ($macAddr | ForEach-Object { $_.ToString("X2") }) -join "-" }
    } catch {}
    return "00-00-00-00-00-00"
}

function Scan-LAN {
    $iface = Get-AdapterMenu "Select an adapter:"
    if (-not $iface) { return }
    Ensure-AdapterEnabled $iface

    $ad = Get-NetAdapter -InterfaceAlias $iface -ErrorAction SilentlyContinue
    $ipInfo = Get-NetIPAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1
    $gwRoute = Get-NetRoute -InterfaceIndex $ad.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
    $gwIP = if ($gwRoute) { $gwRoute.NextHop } else { "" }

    if (-not $ipInfo) {
        Show-Message @("Adapter does not have a valid IP for scanning.") @("Red")
        return
    }

    $ipStr = $ipInfo.IPAddress
    $baseIP = $ipStr.Substring(0, $ipStr.LastIndexOf('.'))
    $localMac = $ad.MacAddress.Replace(':', '-')
    
    $dnsCache = @{}
    $deviceState = @{}
    $blockW = 95

    Clear-Host
    $lastWinWidth = $Host.UI.WindowSize.Width

    while ($true) {
        if ($Host.UI.WindowSize.Width -ne $lastWinWidth) {
            $lastWinWidth = $Host.UI.WindowSize.Width
            Clear-Host
        }

        # 1. Запуск асинхронного пинга
        $pingers = @(); $tasks = @()
        foreach ($i in 1..254) {
            $target = "$baseIP.$i"; $ping = New-Object System.Net.NetworkInformation.Ping
            $pingers += $ping; $tasks += $ping.SendPingAsync($target, 800)
        }
        [System.Threading.Tasks.Task]::WaitAll($tasks) | Out-Null
        
        $now = [DateTime]::Now
        for ($i=0; $i -lt $tasks.Count; $i++) {
            if ($tasks[$i].Result.Status -eq 'Success') { 
                $ip = $tasks[$i].Result.Address.ToString()
                $mac = if ($ip -eq $ipStr) { $localMac } else { Get-MacByIP $ip }
                
                $deviceState[$ip] = @{
                    TTL = $tasks[$i].Result.Options.Ttl
                    LastSeen = $now
                    MAC = $mac
                }
            }
            $pingers[$i].Dispose()
        }

        $ipsToRemove = @()
        foreach ($ip in $deviceState.Keys) {
            if (($now - $deviceState[$ip].LastSeen).TotalSeconds -gt 15) { $ipsToRemove += $ip }
        }
        foreach ($ip in $ipsToRemove) { $deviceState.Remove($ip) }

        # --- ФОНОВЫЙ ПОИСК ИМЕНИ (DNS + NetBIOS / LLMNR) ---
        foreach ($ip in $deviceState.Keys) {
            if (-not $dnsCache.ContainsKey($ip)) {
                $ps = [powershell]::Create().AddScript({
                    param($targetIp)
                    try {
                        $name = [System.Net.Dns]::GetHostEntry($targetIp).HostName
                        if ($name -and $name -ne $targetIp) { return $name }
                    } catch {}
                    
                    try {
                        $res = Resolve-DnsName -Name $targetIp -LlmnrNetbiosOnly -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($res.NameHost -and $res.NameHost -ne $targetIp) { return $res.NameHost }
                    } catch {}
                    
                    return ""
                }).AddArgument($ip)
                
                $asyncRes = $ps.BeginInvoke()
                $dnsCache[$ip] = @{ PS = $ps; AsyncResult = $asyncRes; Result = ""; IsDone = $false }
            }
        }

        $sortedIPs = $deviceState.Keys | Sort-Object { [Version]$_ }

        [Console]::SetCursorPosition(0, 0)
        Write-Host ""
        Write-Centered (L "=== Found Devices (Scanning in background...) ===") "Cyan"
        Write-Centered (L '[LEFT] Go Back | [Ctrl+L] Lang') "DarkGray"
        Write-Centered "----------------------------------------------------------------------" "DarkCyan"
        Write-Host ""
        
        $w = $Host.UI.WindowSize.Width
        if ($w -lt 20) { $w = 110 }
        $startX = [math]::Max(0, [math]::Floor(($w - $blockW) / 2))
        
        foreach ($ip in $sortedIPs) {
            $dev = $deviceState[$ip]
            $mac = $dev.MAC
            $vendor = Get-VendorByMac $mac

            $hostName = ""
            $cacheItem = $dnsCache[$ip]
            
            # Чтение результата из фона
            if (-not $cacheItem.IsDone) {
                if ($cacheItem.AsyncResult.IsCompleted) {
                    try {
                        $res = $cacheItem.PS.EndInvoke($cacheItem.AsyncResult)
                        if ($res) { $cacheItem.Result = ($res -join "").Trim() }
                    } catch {}
                    $cacheItem.PS.Dispose()
                    $cacheItem.IsDone = $true
                }
            }
            $hostName = $cacheItem.Result

            # --- УМНАЯ ЗАГЛУШКА И ФИЛЬТР БАНАЛЬНЫХ ИМЕН ---
            $deviceType = ""
            if ($vendor) {
                if ($vendor -match '(?i)Apple') { $deviceType = "Apple Device" }
                elseif ($vendor -match '(?i)Samsung|Xiaomi|Huawei|Oppo|Vivo|Realme|Motorola') { $deviceType = "Mobile Device" }
                elseif ($vendor -match '(?i)Hui Zhou|TCL|Hisense|LG|Sony|Roku|Nintendo|DEXP') { $deviceType = "Smart TV / Media Box" }
                elseif ($vendor -match '(?i)Tuya|Espressif|Sonoff|Shenzhen|Lexmark|Canon|Epson') { $deviceType = "IoT / Printer" }
                elseif ($vendor -match '(?i)Intel|AMD|Microsoft|Dell|HP|Lenovo|ASUS|Gigabyte') { $deviceType = "PC / Laptop" }
            }

            $cleanHost = $hostName -replace '(?i)\.lan$|\.local$|\.home$', ''

            # 1. Если устройство вообще промолчало
            if (-not $cleanHost -or $cleanHost -eq $ip) { 
                if ($deviceType) {
                    $cleanHost = "[$deviceType | $vendor]"
                } else {
                    $cleanHost = L "Unknown Device" 
                }
            } 
            # 2. Если устройство отдало слишком банальное имя (например, "Android", "localhost", "tv")
            elseif ($cleanHost -match '(?i)^android.*|^localhost$|^unknown$|^tv$') {
                if ($deviceType) {
                    $cleanHost = "$cleanHost [$deviceType]"
                }
            }

            $hostSuffix = ""
            if ($ip -eq $ipStr) { $hostSuffix = " $((L '(This PC)'))" }
            elseif ($ip -eq $gwIP) { $hostSuffix = " $((L '(Gateway)'))" }
            
            $hostDisp = "$cleanHost$hostSuffix"

            $ipColor = if (($now - $dev.LastSeen).TotalSeconds -lt 4) { "Green" } else { "DarkGray" }
            $macDisp = if ($vendor) { "$mac [$vendor]" } else { $mac }

            Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'IP Address').PadRight(22)) : $ip" -ForegroundColor $ipColor
            Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'MAC Address').PadRight(22)) : $macDisp" -ForegroundColor Gray
            Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Hostname').PadRight(22)) : $hostDisp" -ForegroundColor White
            Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "----------------------------------------------------------------------" -ForegroundColor DarkCyan
        }
        
        Clear-Tail

        $breakLoop = $false
        for ($i=0; $i -lt 15; $i++) {
            if ([Console]::KeyAvailable) {
                $keyInfo = [System.Console]::ReadKey($true)
                $k = $keyInfo.Key
                
                if (($keyInfo.Modifiers -band [ConsoleModifiers]::Control) -and ($k -eq [ConsoleKey]::L)) {
                    $global:SysLang = if ($global:SysLang -eq 'ru') { 'en' } else { 'ru' }
                    Set-Content -Path $LangCacheFile -Value $global:SysLang -Encoding UTF8
                    Clear-Host
                    break
                }
                if ($k -eq 'F5') { [Environment]::Exit(99) }
                if ($k -match 'LeftArrow|Escape|Backspace') { $breakLoop = $true; break }
            }
            Start-Sleep -Milliseconds 100
        }
        if ($breakLoop) { break }
    }
}
function Optimize-MTU {
    $iface = Get-AdapterMenu "Select an adapter:"
    if (-not $iface) { return }
    Ensure-AdapterEnabled $iface

    while($true) {
        Clear-Host
        Write-Host ""
        Write-Centered (L "=== MTU Optimizer ===") "Cyan"
        Write-Host ""
        Write-Centered (L "This tool will ping a reliable server to find your perfect packet size.") "White"
        Write-Centered (L "Using the correct MTU avoids fragmentation, reduces ping, and fixes loading bugs.") "Gray"
        Write-Host ""
        Write-Centered (L "Press [ENTER] to Start Test or [ESC] to Cancel") "Yellow"
        
        $k = [System.Console]::ReadKey($true)
        if (($k.Modifiers -band [ConsoleModifiers]::Control) -and ($k.Key -eq [ConsoleKey]::L)) {
            $global:SysLang = if ($global:SysLang -eq 'ru') { 'en' } else { 'ru' }
            Set-Content -Path $LangCacheFile -Value $global:SysLang -Encoding UTF8
            continue
        }
        if ($k.Key -eq 'Enter') { break }
        if ($k.Key -match 'Escape|LeftArrow|Backspace') { return }
    }

    $target = "8.8.8.8"
    $maxSize = 1472
    $minSize = 1300
    $current = $maxSize
    $found = $false
    
    Clear-Host
    Write-Host ""
    Write-Centered (L "Testing packet size") "Cyan"
    Write-Host ""
    
    $w = $Host.UI.WindowSize.Width
    $startX = [math]::Max(0, [math]::Floor(($w - 40) / 2))

    while ($current -ge $minSize) {
        Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop)
        Write-Host "Ping $target (Size: $current)... " -NoNewline -ForegroundColor White
        
        $res = ping $target -f -l $current -n 1
        if ($res -match "Требуется фрагментация|Packet needs to be fragmented") {
            Write-Host (L "Fragmented. Lowering size...") -ForegroundColor Yellow
            $current -= 10
        } else {
            Write-Host "OK!" -ForegroundColor Green
            $found = $true
            break
        }
    }

    if ($found) {
        Write-Host ""
        Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop)
        Write-Host (L "Success. Refining...") -ForegroundColor Cyan
        
        while ($current -le $maxSize) {
            $current++
            Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop)
            Write-Host "Ping $target (Size: $current)... " -NoNewline -ForegroundColor White
            $res = ping $target -f -l $current -n 1
            if ($res -match "Требуется фрагментация|Packet needs to be fragmented") {
                $current-- 
                Write-Host "LIMIT REACHED" -ForegroundColor Yellow
                break
            } else { 
                Write-Host "OK!" -ForegroundColor Green 
            }
        }
        
        $optimalMTU = $current + 28
        Write-Host ""
        Write-Centered "$(L 'Perfect MTU Found!'): $optimalMTU" "Green"
        Write-Host ""
        Write-Centered (L "Press [Y] to Apply, or any other key to Cancel...") "Yellow"
        
        $k = [System.Console]::ReadKey($true)
        if ($k.Key -eq 'Y') {
            Set-NetIPInterface -InterfaceAlias $iface -NlMtuBytes $optimalMTU -ErrorAction SilentlyContinue | Out-Null
            Show-Message @('Settings successfully applied', 'Success!') @('Cyan', 'Green')
        }
    } else { 
        Show-Message @('Error') @('Red') 
    }
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
        if ($actRes.Action -eq 'LangChange') { $idx = $actRes.Index; continue }
        if ($actRes.Action -eq 'Back') { break }
        
        $act = $actRes.Value
        $iface = Get-AdapterMenu "Select an adapter:"
        if (-not $iface) { continue }
        Ensure-AdapterEnabled $iface
        
        if ($act -eq "1") {
            Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Enabled -ErrorAction SilentlyContinue | Out-Null
            Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue | Out-Null
            Show-Message @('Success!') @('Green')
        } elseif ($act -eq "2") {
            Set-NetIPInterface -InterfaceAlias $iface -AddressFamily IPv4 -Dhcp Disabled -ErrorAction SilentlyContinue | Out-Null
            Show-Message @('Success!') @('Green')
        } elseif ($act -eq "3") {
            ipconfig /release "$iface" | Out-Null
            ipconfig /renew "$iface" | Out-Null
            Show-Message @('Success!') @('Green')
        }
    }
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
        if ($actRes.Action -eq 'LangChange') { $idx = $actRes.Index; continue }
        if ($actRes.Action -eq 'Back') { break }
        
        $iface = Get-AdapterMenu "Select an adapter:"
        if (-not $iface) { continue }
        Ensure-AdapterEnabled $iface
        
        if ($actRes.Value -eq "AUTO") {
            Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue | Out-Null
        } else {
            $servers = $actRes.Value -split ","
            Set-DnsClientServerAddress -InterfaceAlias $iface -ServerAddresses $servers -ErrorAction SilentlyContinue | Out-Null
        }
        Show-Message @('Success!') @('Green')
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
        if ($actRes.Action -eq 'LangChange') { $idx = $actRes.Index; continue }
        if ($actRes.Action -eq 'Back') { break }
        
        if ($actRes.Value -eq "1") {
            $iface = Get-AdapterMenu "Select an adapter:"
            if ($iface) {
                $confIdx = 0
                while ($true) {
                    $svMenu = @( @{Name=L "Yes"; Value=$true}, @{Name=L "No"; Value=$false} )
                    $confirmRes = Show-Menu -Title (L "Are you SURE you want to clear adapter settings?") -Items $svMenu -DefaultIndex $confIdx
                    if ($confirmRes.Action -eq 'LangChange') { $confIdx = $confirmRes.Index; continue }
                    if ($confirmRes.Action -ne 'Back' -and $confirmRes.Value -eq $true) {
                        Remove-NetIPAddress -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Remove-NetRoute -InterfaceAlias $iface -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
                        Set-DnsClientServerAddress -InterfaceAlias $iface -ResetServerAddresses -ErrorAction SilentlyContinue
                        Show-Message @('Adapter settings cleared successfully') @('Green')
                    }
                    break
                }
            }
        } elseif ($actRes.Value -eq "2") {
            while ($true) {
                Clear-Host
                Write-Host ""
                Write-Centered (L "Resetting Windows network stack...") "Cyan"
                Write-Centered "----------------------------------------" "DarkCyan"
                ipconfig /flushdns | Out-Null
                netsh winsock reset | Out-Null
                netsh int ip reset | Out-Null
                Write-Host ""
                Write-Centered (L 'Success!') "Green"
                Write-Centered (L "A computer restart is recommended after this reset.") "Yellow"
                if ((Wait-Back) -eq "LANG_CHANGED") { continue }
                break
            }
        }
    }
}

function Manage-Adapters {
    $idx = 0
    while ($true) {
        $adapters = Get-AdaptersCached
        $items = @()
        foreach ($a in $adapters) {
            if ($a.Status -eq 'Up') { $st = L "ADAPT_WORKING" }
            elseif ($a.Status -eq 'Disabled') { $st = L "ADAPT_DISABLED" }
            elseif ($a.Status -eq 'Disconnected') { $st = L "ADAPT_NO_CABLE" }
            else { $st = $a.Status }
            $items += @{ Name = "$($a.InterfaceAlias) [$st]"; Value = $a.InterfaceAlias }
        }
        $items += @{ Name = L "Back"; Value = 'BACK' }
        
        $res = Show-Menu -Title (L "Enable / Disable network adapters") -Items $items -IsToggleMenu -DefaultIndex $idx
        if ($res.Action -eq 'LangChange') { $idx = $res.Index; continue }
        if ($res.Action -eq 'Back') { break }
        
        if ($res.Action -eq 'Enable') {
            Enable-NetAdapter -Name $res.Value -Confirm:$false
            Flush-AdapterCache
        } elseif ($res.Action -eq 'Disable') {
            Disable-NetAdapter -Name $res.Value -Confirm:$false
            Flush-AdapterCache
        }
    }
}

function Manage-Profiles {
    $pIdx = 0
    while ($true) {
        if (-not (Test-Path $ProfilePath)) { 
            Show-Message @("You don't have any saved profiles yet.", "They will appear here when you save settings while applying a new IP.") @("Yellow", "DarkGray")
            break
        }
        $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($profiles.Count -eq 0) {
            Show-Message @("You don't have any saved profiles yet.") @("Yellow")
            break
        }
        
        $pItems = @()
        foreach ($p in $profiles) { $pItems += @{Name = "$($p.Name) [$($p.IP)]"; Value = $p} }
        $pItems += @{Name = L "Back"; Value = 'BACK'}
        
        $pRes = Show-Menu -Title (L "Manage Saved Profiles") -Items $pItems -DefaultIndex $pIdx
        if ($pRes.Action -eq 'LangChange') { $pIdx = $pRes.Index; continue }
        if ($pRes.Action -eq 'Back') { break }
        
        $targetProf = $pRes.Value
        
        $actIdx = 0
        while ($true) {
            $actItems = @(
                @{Name = L "Apply Profile"; Value = "APPLY"}
                @{Name = L "Rename Profile"; Value = "RENAME"}
                @{Name = L "Delete Profile"; Value = "DELETE"}
                @{Name = L "Cancel"; Value = "BACK"}
            )
            $act = Show-Menu -Title "'$($targetProf.Name)' Options" -Items $actItems -DefaultIndex $actIdx
            if ($act.Action -eq 'LangChange') { $actIdx = $act.Index; continue }
            if ($act.Action -eq 'Back' -or $act.Value -eq 'BACK') { $act = $null; break }
            break
        }
        if (-not $act) { continue }
        
        if ($act.Value -eq "APPLY") {
            Set-StaticIP -InterfaceAlias $targetProf.Interface -IPAddress $targetProf.IP -PrefixLength $targetProf.Mask -DefaultGateway $targetProf.Gateway -Mode 'Replace'
        } elseif ($act.Value -eq "DELETE") {
            $profiles = $profiles | Where-Object { $_.Name -ne $targetProf.Name -or $_.IP -ne $targetProf.IP }
            $profiles | ConvertTo-Json | Set-Content $ProfilePath -Encoding UTF8
            Show-Message @('Profile deleted.') @('Green')
        } elseif ($act.Value -eq "RENAME") {
            $newName = Get-TextInput (L "Enter new name for the profile")
            if (-not [string]::IsNullOrWhiteSpace($newName)) {
                foreach ($p in $profiles) {
                    if ($p.Name -eq $targetProf.Name -and $p.IP -eq $targetProf.IP) { $p.Name = $newName; break }
                }
                $profiles | ConvertTo-Json | Set-Content $ProfilePath -Encoding UTF8
                Show-Message @('Profile renamed.') @('Green')
            }
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
        Show-Message @('Settings successfully applied') @('Green')
    } catch { 
        $err = "$(L 'Error'): $_"
        Show-Message @($err) @('Red') 
    }
}

function Analyze-WiFiChannels {
    while ($true) {
        Clear-Host; Write-Host ""; Write-Centered (L "Wi-Fi Channel Analyzer & Optimizer") "Cyan"
        Write-Centered "--------------------------------------------------------" "DarkCyan"; Write-Host ""
        
        Write-Centered "Scanning airwaves... Please wait" "Yellow"
        $raw = netsh wlan show networks mode=bssid
        
        $channels = @{}
        foreach ($line in $raw) {
            if ($line -match "Channel\s*:\s*(\d+)" -or $line -match "Канал\s*:\s*(\d+)") {
                $ch = [int]$matches[1]
                if (-not $channels.ContainsKey($ch)) { $channels[$ch] = 0 }
                $channels[$ch]++
            }
        }
        
        Clear-Host; Write-Host ""; Write-Centered (L "Wi-Fi Channel Analyzer & Optimizer") "Cyan"
        Write-Centered "--------------------------------------------------------" "DarkCyan"; Write-Host ""
        $w = $Host.UI.WindowSize.Width; $startX = [math]::Max(0, [math]::Floor(($w - 60) / 2))
        
        if ($channels.Count -eq 0) {
            Write-Centered "No networks found." "Red"
        } else {
            $sortedCh = $channels.Keys | Sort-Object
            foreach ($ch in $sortedCh) {
                $count = $channels[$ch]
                $color = if ($count -gt 5) { "Red" } elseif ($count -gt 2) { "Yellow" } else { "Green" }
                $bar = "█" * $count
                Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop)
                Write-Host "CH $ch".PadRight(8) -NoNewline -ForegroundColor White
                Write-Host "[$count net] " -NoNewline -ForegroundColor Gray
                Write-Host $bar -ForegroundColor $color
            }
        }
        
        Write-Host ""; Write-Centered "Router Channel should be set manually in router settings." "DarkGray"
        Write-Host ""; Write-Centered "Press [ENTER] to Apply Optimal Driver Settings (Prefer 5GHz/Roaming) or [ESC] to Exit" "Magenta"
        
        $key = [System.Console]::ReadKey($true).Key
        if ($key -eq 'Enter') {
            $wifiAdapters = Get-NetAdapter -Physical | Where-Object MediaType -match "802.11"
            foreach ($wa in $wifiAdapters) {
                Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Preferred Band" -DisplayValue "3. Prefer 5.2GHz band" -ErrorAction SilentlyContinue | Out-Null
                Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Предпочитаемая частота" -DisplayValue "3 - Предпочитать частоту 5.2 ГГц" -ErrorAction SilentlyContinue | Out-Null
                Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Roaming Aggressiveness" -DisplayValue "4. Medium-High" -ErrorAction SilentlyContinue | Out-Null
            }
            Show-Message @('Applying optimal settings to Wi-Fi adapter...', 'Success!') @('Cyan', 'Green')
            break
        } elseif ($key -eq 'Escape') { break }
    }
}

function Manage-WiFiPriority {
    $idx = 0
    while ($true) {
        $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
        if ($profiles.Count -eq 0) { Show-Message @("No Wi-Fi profiles found.") @("Red"); break }
        
        $items = @()
        foreach ($p in $profiles) { $items += @{Name = $p; Value = $p} }
        $items += @{Name = L "Back"; Value = "BACK"}
        
        $res = Show-Menu -Title (L "Manage Wi-Fi Network Priorities") -Items $items -DefaultIndex $idx
        if ($res.Action -eq 'LangChange') { $idx = $res.Index; continue }
        if ($res.Action -eq 'Back') { break }
        
        $target = $res.Value
        $cMenu = @( @{Name=L "Yes"; Value=$true}, @{Name=L "No"; Value=$false} )
        $cRes = Show-Menu -Title "$(L 'Move this network to TOP Priority?'): '$target'" -Items $cMenu -DefaultIndex 0
        if ($cRes.Value -eq $true) {
            netsh wlan set profileorder name="$target" interface="Wi-Fi" priority=1 | Out-Null
            Show-Message @('Network moved to priority 1.', 'Success!') @('Cyan', 'Green')
            $idx = 0 
        }
    }
}

function Manage-WiFi {
    $idx = 0
    while ($true) {
        $items = @(
            @{Name = L "Show available networks (Live Radar)"; Value = "1"}
            @{Name = L "Connect to saved network"; Value = "2"}
            @{Name = L "Show saved Wi-Fi passwords"; Value = "3"}
            @{Name = L "Optimize Wi-Fi Power (Boost Signal)"; Value = "4"}
            @{Name = L "Wi-Fi Channel Analyzer & Optimizer"; Value = "5"}
            @{Name = L "Manage Wi-Fi Network Priorities"; Value = "6"}
            @{Name = L "Back"; Value = "BACK"}
        )
        $actRes = Show-Menu -Title (L "Wi-Fi Management (Search, Connect, Passwords)") -Items $items -DefaultIndex $idx
        if ($actRes.Action -eq 'LangChange') { $idx = $actRes.Index; continue }
        if ($actRes.Action -eq 'Back') { break }
        
        $act = $actRes.Value
        if ($act -eq "1") {
            $radarIdx = 0
            while ($true) {
                $res = Show-Menu -Title (L "Show available networks (Live Radar)") -Items @() -DynamicWiFi -DefaultIndex $radarIdx
                if ($res.Action -eq 'LangChange') { $radarIdx = $res.Index; continue }
                break
            }
            if ($res.Action -ne 'Back') {
                $target = $res.Value
                $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
                if ($profiles -contains $target) {
                    while ($true) {
                        Clear-Host
                        Write-Host ""
                        Write-Centered "$(L 'This network is already saved, connecting...') '$target'" "Yellow"
                        netsh wlan connect name="$target" | Out-Null
                        if ((Wait-Back) -eq "LANG_CHANGED") { continue }
                        break
                    }
                } else {
                    $pwd = Get-TextInput (L "Enter network password (Press Enter to abort)")
                    if ([string]::IsNullOrWhiteSpace($pwd)) {
                        Show-Message @('Action canceled by user.') @('Red')
                        continue
                    }
                    while ($true) {
                        Clear-Host
                        Write-Host ""
                        Write-Centered (L 'Creating new network profile...') "Cyan"
                        $xml = @"
<?xml version="1.0"?><WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"><name>$target</name><SSIDConfig><SSID><name>$target</name></SSID></SSIDConfig><connectionType>ESS</connectionType><connectionMode>auto</connectionMode><MSM><security><authEncryption><authentication>WPA2PSK</authentication><encryption>AES</encryption><useOneX>false</useOneX></authEncryption><sharedKey><keyType>passPhrase</keyType><protected>false</protected><keyMaterial>$pwd</keyMaterial></sharedKey></security></MSM></WLANProfile>
"@
                        $xmlPath = "$env:TEMP\nwifi.xml"
                        $xml | Out-File -FilePath $xmlPath -Encoding utf8
                        netsh wlan add profile filename="$xmlPath" | Out-Null
                        Remove-Item $xmlPath -ErrorAction SilentlyContinue
                        netsh wlan connect name="$target" | Out-Null
                        if ((Wait-Back) -eq "LANG_CHANGED") { continue }
                        break
                    }
                }
                Show-Message @('Success!') @('Green')
            }
        } elseif ($act -eq "2") {
            $savedIdx = 0
            while ($true) {
                $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
                $pItems = @()
                foreach ($p in $profiles) { $pItems += @{Name = $p; Value = $p} }
                $pItems += @{Name = L "Back"; Value = 'BACK'}
                
                $targetRes = Show-Menu -Title (L "Connect to saved network") -Items $pItems -DefaultIndex $savedIdx
                if ($targetRes.Action -eq 'LangChange') { $savedIdx = $targetRes.Index; continue }
                break
            }
            if ($targetRes.Action -ne 'Back') {
                netsh wlan connect name="$($targetRes.Value)" | Out-Null
                Show-Message @('Success!') @('Green')
            }
        } elseif ($act -eq "3") {
            while ($true) {
                Clear-Host
                Write-Host ""
                Write-Centered (L "=== Saved Wi-Fi Passwords ===") "Cyan"
                Write-Centered "------------------------------------------------" "DarkCyan"
                Write-Host ""
                
                $w = $Host.UI.WindowSize.Width
                if ($w -lt 20) { $w = 110 }
                $startX = [math]::Max(0, [math]::Floor(($w - 65) / 2))

                $profiles = @(netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { ($_.Line -split ':', 2)[1].Trim() })
                if ($profiles.Count -eq 0) {
                    Write-Centered "No Wi-Fi profiles found." "DarkGray"
                } else {
                    foreach ($p in $profiles) {
                        $keyLine = netsh wlan show profile name="$p" key=clear | Select-String "Key Content"
                        $pwd = if ($keyLine) { ($keyLine.Line -split ':', 2)[1].Trim() } else { L "No password (Open)" }
                        
                        Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Network').PadRight(20)) : $p" -ForegroundColor Green
                        Reset-Line; [Console]::SetCursorPosition($startX, [Console]::CursorTop); Write-Host "$((L 'Password').PadRight(20)) : $pwd" -ForegroundColor Yellow
                        Write-Host ""
                    }
                }
                if ((Wait-Back) -eq "LANG_CHANGED") { continue }
                break
            }
        } elseif ($act -eq "4") {
            $pwrIdx = 0
            while ($true) {
                $pItems = @(
                    @{Name = L "Enable Wi-Fi Boost (Max Performance)"; Value = "ENABLE"}
                    @{Name = L "Disable Wi-Fi Boost (Balanced/Default)"; Value = "DISABLE"}
                    @{Name = L "Back"; Value = "BACK"}
                )
                $pRes = Show-Menu -Title (L "Optimize Wi-Fi Power (Boost Signal)") -Items $pItems -DefaultIndex $pwrIdx
                if ($pRes.Action -eq 'LangChange') { $pwrIdx = $pRes.Index; continue }
                break
            }
            if ($pRes.Action -eq 'Back' -or $pRes.Value -eq 'BACK') { continue }
            
            $guidSub = "19cbb8fa-5279-450e-9fac-8a3d5fedd0c1"
            $guidSetting = "12bbebe6-58d6-4636-95bb-3217ef867c1a"
            if ($pRes.Value -eq "ENABLE") {
                try {
                    powercfg /setacvalueindex SCHEME_CURRENT $guidSub $guidSetting 0
                    powercfg /setdcvalueindex SCHEME_CURRENT $guidSub $guidSetting 0
                    powercfg /setactive SCHEME_CURRENT
                    Show-Message @('Applying Max Performance Power Plan to Wi-Fi adapter...', 'Wi-Fi transmission power boosted successfully!') @('Cyan', 'Green')
                } catch { Show-Message @('Error applying settings.') @('Red') }
            } elseif ($pRes.Value -eq "DISABLE") {
                try {
                    powercfg /setacvalueindex SCHEME_CURRENT $guidSub $guidSetting 0
                    powercfg /setdcvalueindex SCHEME_CURRENT $guidSub $guidSetting 2
                    powercfg /setactive SCHEME_CURRENT
                    Show-Message @('Restoring default Power Plan for Wi-Fi adapter...', 'Wi-Fi power settings restored to default.') @('Cyan', 'Green')
                } catch { Show-Message @('Error applying settings.') @('Red') }
            }
        } elseif ($act -eq "5") {
            Analyze-WiFiChannels
        } elseif ($act -eq "6") {
            Manage-WiFiPriority
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
            @{Name = L "Manage Saved Profiles"; Value = 7}
            @{Name = L "Enable / Disable network adapters"; Value = 8}
            @{Name = L "Wi-Fi Management (Search, Connect, Passwords)"; Value = 9}
            @{Name = L "MAC Address Spoofing"; Value = 10}
            @{Name = L "LAN Scanner"; Value = 11}
            @{Name = L "Optimize MTU (Find perfect packet size)"; Value = 12}
            @{Name = L "Exit"; Value = 0}
        )
        
        $choice = Show-Menu -Title "netsett++ Main Menu" -Items $items -DefaultIndex $mainIndex -ShowLogo
        if ($choice.Action -eq 'LangChange') { $mainIndex = $choice.Index; continue }
        if ($choice.Action -eq 'Back') { break }
        
        switch ($choice.Value) {
            1 { Show-Status }
            2 {
                $iface = Get-AdapterMenu "Select an adapter:"
                if ($iface) {
                    $ip = Get-TextInput (L "Enter IP address (e.g. 192.168.1.50)")
                    if (-not (Test-IPAddress $ip)) { continue }
                    $mask = Get-TextInput (L "Enter subnet mask (e.g. 24)")
                    $gw = Get-TextInput (L "Enter Gateway IP (Enter to skip)")
                    
                    $confIdx = 0
                    while ($true) {
                        $svMenu = @( @{Name=L "Yes"; Value=$true}, @{Name=L "No"; Value=$false} )
                        $saveRes = Show-Menu -Title (L "Save these settings as a profile?") -Items $svMenu -DefaultIndex $confIdx
                        if ($saveRes.Action -eq 'LangChange') { $confIdx = $saveRes.Index; continue }
                        if ($saveRes.Action -ne 'Back' -and $saveRes.Value -eq $true) {
                            $pname = Get-TextInput (L "Enter a name for the profile")
                            $prof = @{Name=$pname; Interface=$iface; IP=$ip; Mask=$mask; Gateway=$gw}
                            $profiles = @()
                            if (Test-Path $ProfilePath) { $profiles = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json }
                            $profiles += $prof
                            $profiles | ConvertTo-Json | Set-Content $ProfilePath -Encoding UTF8
                        }
                        break
                    }
                    Set-StaticIP -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -DefaultGateway $gw -Mode 'Replace'
                }
            }
            3 {
                $iface = Get-AdapterMenu "Select an adapter:"
                if ($iface) {
                    $ip = Get-TextInput (L "Enter IP address (e.g. 192.168.1.50)")
                    if (-not (Test-IPAddress $ip)) { continue }
                    $mask = Get-TextInput (L "Enter subnet mask (e.g. 24)")
                    New-NetIPAddress -InterfaceAlias $iface -IPAddress $ip -PrefixLength $mask -AddressFamily IPv4 -ErrorAction SilentlyContinue | Out-Null
                    Show-Message @('Success!') @('Green')
                }
            }
            4 { Manage-DHCP }
            5 { Manage-DNS }
            6 { Manage-Resets }
            7 { Manage-Profiles }
            8 { Manage-Adapters }
            9 { Manage-WiFi }
            10 {
                $iface = Get-AdapterMenu "Select an adapter:"
                if ($iface) {
                    $mIdx = 0
                    while ($true) {
                        $mItems = @(
                            @{Name = L "Enter new MAC manually"; Value = "1"}
                            @{Name = L "Generate random MAC"; Value = "2"}
                            @{Name = L "Restore original hardware MAC"; Value = "3"}
                            @{Name = L "Back"; Value = "BACK"}
                        )
                        $actRes = Show-Menu -Title (L "MAC Address Spoofing") -Items $mItems -DefaultIndex $mIdx
                        if ($actRes.Action -eq 'LangChange') { $mIdx = $actRes.Index; continue }
                        break
                    }
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
                                $inputMac = Get-TextInput (L "Enter new MAC (no dashes, e.g. 001122334455)")
                                if ($inputMac -match '^[0-9A-Fa-f]{12}$') { $newMac = $inputMac } else { continue }
                            } elseif ($act -eq "2") {
                                $chars = "0123456789ABCDEF"; $valid = "2","6","A","E"
                                $newMac = $chars[(Get-Random -Max 16)].ToString() + $valid[(Get-Random -Max 4)]
                                for ($i=0; $i -lt 10; $i++) { $newMac += $chars[(Get-Random -Max 16)] }
                            }
                            
                            if ($act -eq "3") { Remove-ItemProperty -Path $regPath -Name "NetworkAddress" -ErrorAction SilentlyContinue } 
                            else { Set-ItemProperty -Path $regPath -Name "NetworkAddress" -Value $newMac }
                            
                            try {
                                Disable-NetAdapter -Name $iface -Confirm:$false
                                Start-Sleep 1
                                Enable-NetAdapter -Name $iface -Confirm:$false
                                Show-Message @('Applying settings...', 'Success!') @('Cyan', 'Green')
                            } catch { Show-Message @('Error applying settings.') @('Red') }
                        }
                    }
                }
            }
            11 { Scan-LAN }
            12 { Optimize-MTU }
        }
    }
}

try { Main-Menu } catch {
    Show-Message @("[КРИТИЧЕСКАЯ ОШИБКА / CRITICAL ERROR]", $_.Exception.Message) @("Red", "Red")
}
try { [Console]::CursorVisible = $true } catch {}
