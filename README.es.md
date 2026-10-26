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

## 🔐 Cleanup and privacy

AClean muestra los elementos encontrados antes de limpiar. Revisa la selección y sus ubicaciones antes de confirmar. Consulta el código y las notas de la versión para conocer el comportamiento de cada versión. Hay funciones de red opcionales, como actualizar reglas, consultar el tiempo y la ubicación por IP. No todas las funciones son necesariamente sin conexión.

## 🤝 Contributing

Se aceptan issues y pull requests. Incluye las versiones de macOS y AClean, pasos para reproducir el problema y registros sin datos personales.

## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

La investigación de funciones y seguridad consultó Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep y Privacy Guides. Son proyectos independientes; la lista no implica respaldo ni afiliación. La implementación, las reglas de limpieza y el icono de AClean se mantienen por separado. Toda contribución futura que añada código o recursos de terceros debe documentar su origen y licencia.
