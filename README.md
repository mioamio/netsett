![20240502141438f68bcd713d](https://github.com/user-attachments/assets/4a7c70ca-2fcb-4896-afb9-3bb90bf25f33)

[![Windows](https://badgen.net/badge/icon/windows?icon=windows&label)](https://microsoft.com/windows/)
![Terminal](https://badgen.net/badge/icon/terminal?icon=terminal&label)
![Views](https://komarev.com/ghpvc/?username=mioamio&repo=netsett&style=flat-square&label=Views)
[![License: MIT](https://img.shields.io/github/license/mioamio/netsett?style=flat-square)](https://github.com/mioamio/netsett/blob/main/LICENSE)
[![Telegram](https://badgen.net/badge/Telegram/me/2CA5E0)](https://t.me/topvselennaya)

**Удобный портативный скрипт (Bat + PowerShell) для быстрого управления сетевыми адаптерами и IP-адресами в Windows. Отлично подходит для сисадминов, инженеров и пользователей, которым часто приходится менять сетевые настройки (например, при настройке роутеров, серверов или частой смене рабочих сетей).**

## Основные возможности

- **Просмотр состояния сетей:** Отображение текущего IP, шлюза, MAC-адреса и аппаратного названия сетевой карты
- **Управление IP-адресами:** Быстрая смена статического IP-адреса, маски и шлюза
- **Дополнительные IP:** Возможность добавить второй (и более) IP-адрес на один сетевой адаптер
- **Управление DHCP:** Включение, отключение и принудительное обновление (Release/Renew) динамического IP
- **Аппаратное управление:** Включение и отключение сетевых адаптеров напрямую из меню
- **Система профилей:** Сохранение удачных настроек в профили (например "Дом", "Работа", "Настройка коммутатора") для переключения в пару кликов
- **Сброс настроек:** Полная очистка адаптера от зависших статических маршрутов и IP-адресов

## Особенности

- **Не требует установки:** Работает как единый `.bat` файл
- **Авто-эскалация прав:** Скрипт сам запрашивает права Администратора при запуске (необходимы для изменения параметров сети)
- **Умное определение железа:** Выводит понятные названия чипов, например *Realtek PCIe GbE*



## Main Features

- **Network status view:** Displays current IP, gateway, MAC address, and hardware name of the network adapter
- **IP address management:** Quickly change static IP address, subnet mask, and gateway
- **Additional IPs:** Ability to add a second (or more) IP address to a single network adapter
- **DHCP management:** Enable, disable, and force release/renew of dynamic IP
- **Hardware control:** Enable and disable network adapters directly from the menu
- **Profile system:** Save successful configurations as profiles (e.g., "Home", "Work", "Switch Setup") for one‑click switching
- **Reset settings:** Completely clear the adapter of stuck static routes and IP addresses

## Special Features

- **No installation required:** Works as a single .bat file
- **Auto‑elevation:** The script automatically requests Administrator privileges when launched (required for changing network settings)
- **Smart hardware detection:** Displays understandable chip names, e.g., Realtek PCIe GbE
