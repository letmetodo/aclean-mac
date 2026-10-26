<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean es una utilidad nativa para macOS que limpia, analiza el disco, desinstala apps y supervisa el sistema.**

Revisa los resultados antes de actuar, explora visualmente el uso del disco e inspecciona archivos relacionados al desinstalar apps.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ Limpieza inteligente · Space Lens · Gestor de apps · Monitor en vivo

- **Limpieza inteligente** — Analiza cachés compatibles de apps, herramientas de desarrollo y del sistema, y muestra los elementos antes de limpiarlos.
- **Space Lens** — Explora el uso del disco con un mapa de árbol visual.
- **Gestor de apps** — Inspecciona las apps instaladas y sus archivos relacionados antes de eliminarlas.
- **Monitor en vivo** — Consulta la actividad del sistema y configura widgets en la barra de menús.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.


## 🌟 Qué distingue a AClean

- **La propia app nativa es de código abierto.** La app SwiftUI de AClean se publica con Apache-2.0 y puede revisarse, modificarse y redistribuirse.
- **Varias tareas en una sola app nativa.** Revisa elementos de limpieza, explora el disco con un mapa de árbol visual, consulta archivos relacionados antes de desinstalar apps, revisa el estado general del sistema y accede rápidamente al estado desde la barra de menús.
- **Revisa antes de limpiar.** AClean muestra los elementos compatibles y sus ubicaciones antes de confirmar la selección.
- **Diez idiomas.** La interfaz de la app y el README están disponibles en diez idiomas.
- **Transparencia sobre la red.** Las actualizaciones opcionales de reglas, el tiempo y la ubicación basada en IP usan la red. Consulta «Limpieza y privacidad» y el código fuente para más detalles.

## 📸 Capturas reales de la app

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean Salud del sistema module" width="500" /><br /><sub>Salud del sistema</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean Limpieza module" width="500" /><br /><sub>Limpieza</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean Optimización module" width="500" /><br /><sub>Optimización</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean Aplicaciones module" width="500" /><br /><sub>Aplicaciones</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean Organización module" width="500" /><br /><sub>Organización</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean Estado del sistema module" width="500" /><br /><sub>Estado del sistema</sub></td></tr>
</table>


## 🧰 Requirements

- macOS 13 o posterior
- Xcode Command Line Tools con Swift 6.0 o posterior (o Xcode 16 o posterior)

## Compilar desde el código fuente

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean está escrito en Swift y usa el SDK de macOS. La compilación local está dirigida a Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## 🔐 Privacidad, alcance del análisis y eliminación

- **Alcance:** según el módulo, AClean revisa rutas locales compatibles con sus reglas: cachés y registros de apps, navegadores y sistema; datos de desarrollo como Xcode DerivedData/CoreSimulator; cachés de gestores de paquetes; y apps instaladas con archivos relacionados identificados. Space Lens muestra el uso del disco local en modo de solo lectura. Algunas ubicaciones protegidas requieren Acceso total al disco; sin él, los resultados pueden ser incompletos.
- **Antes de actuar:** las vistas previas de limpieza y desinstalación muestran nombre, ruta y tamaño de los elementos para revisar la selección antes de confirmar.
- **Recuperación:** los archivos de limpieza normal y los archivos relacionados con apps se mueven a la Papelera de macOS y, por lo general, pueden restaurarse mientras sigan allí. Vaciar la Papelera, eliminar datos de simuladores de Xcode, ejecutar Docker/OrbStack prune y algunas recuperaciones de instantáneas APFS pueden ser irreversibles. Revisa el tipo de acción y el recibo antes de confirmar.
- **Red:** las actualizaciones automáticas de reglas están activadas de forma predeterminada y descargan un manifiesto y una base de reglas por HTTPS; el servidor ve la IP de la solicitud y metadatos de red habituales. El tiempo y la ubicación por IP están desactivados de forma predeterminada. Si se activan, los proveedores de ubicación ven la IP; la búsqueda de ciudad envía el texto y el idioma de la interfaz a Open-Meteo, y el pronóstico envía latitud y longitud. Las solicitudes actuales no incluyen rutas analizadas, nombres de archivos ni resultados de limpieza. Las métricas del sistema se muestran localmente.

## ⚠️ Problemas conocidos y limitaciones

- La descarga actual es solo para Apple Silicon (arm64) y requiere macOS 13 o posterior.
- La app v1.0.0 no tiene firma Apple Developer ID ni notarización. Gatekeeper puede bloquear el primer inicio; consulta las notas de la versión y la [guía de Apple para abrir apps de forma segura](https://support.apple.com/en-us/102445).
- Sin Acceso total al disco, algunas ubicaciones protegidas pueden no analizarse por completo. Los errores actualmente registrados están en [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues).
## 🛡️ Informes de seguridad y comentarios

- **Vulnerabilidades:** repórtalas de forma privada en [GitHub Security Advisories](https://github.com/letmetodo/aclean-mac/security/advisories/new). No publiques detalles en una issue pública. Consulta [SECURITY.md](SECURITY.md).
- **Errores y sugerencias:** usa [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new). Incluye las versiones de AClean y macOS, el módulo afectado, pasos para reproducir, resultado esperado y real, y registros o capturas sin rutas personales ni datos privados.
## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

La investigación de funciones y seguridad consultó Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep y Privacy Guides. Son proyectos independientes; la lista no implica respaldo ni afiliación. La implementación, las reglas de limpieza y el icono de AClean se mantienen por separado. Toda contribución futura que añada código o recursos de terceros debe documentar su origen y licencia.
