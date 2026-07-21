# Monitor de precios

> Utilidad local de macOS para consultar precios y existencias de tiendas seleccionadas, además del saldo y uso reciente de la API de WOYAO en la barra de menús.

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Español**

## Funciones

- Agrupa productos comparables y los ordena de menor a mayor precio.
- Revisa las tiendas cada minuto y anuncia por voz los nuevos artículos o reposiciones.
- Muestra el saldo actual de WOYAO directamente en la barra de menús.
- Actualiza el uso cada hora y anuncia saldo, cuota usada y coste diario.
- Lista las diez llamadas más recientes con modelo, coste, tokens y hora.

## Inicio rápido

1. Descarga `PriceMonitor-v1.4-macOS-arm64.zip` desde [Releases](../../releases/latest), descomprímelo y mueve la app a Aplicaciones.
2. Abre la app una vez. Para iniciarla al iniciar sesión, instala la plantilla de usuario `LaunchAgent.plist`.
3. Abre **Uso de WOYAO**, pega tu API Key y elige **Guardar en Documentos y leer**.

## Privacidad

Los datos de tiendas se leen de API públicas. La clave de WOYAO solo se guarda en `Documents/价格监控/woyao-api-key.txt`; no se escribe en Git, registros normales ni datos del navegador. No sincronices ese archivo de texto plano con almacenamiento público.

## Compilación y licencia

Se requieren macOS, Xcode Command Line Tools y Swift 6. Ejecuta `./build_app.sh` para crear `价格监控.app`.

Este proyecto se publica bajo [MIT License](../LICENSE). Autor y contacto: Jacksun（孙秦吉）· [qinji@jack-sun.com](mailto:qinji@jack-sun.com).
