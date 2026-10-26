<p align="center"><img src="Resources/AppIcon.png" width="92" alt="AClean app icon" /></p>

<h1 align="center">AClean</h1>

<p align="center"><strong>A cleaner, clearer Mac.</strong></p>

<p align="center"><a href="https://github.com/letmetodo/aclean-mac/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/letmetodo/aclean-mac?style=flat-square&logo=github"></a> <img alt="macOS" src="https://img.shields.io/badge/platform-macOS-24292f?style=flat-square&logo=apple"> <a href="LICENSE"><img alt="Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-42a77b?style=flat-square"></a></p>

**AClean é um utilitário nativo para macOS que limpa, analisa o disco, remove apps e monitora o sistema.**

Revise os resultados antes de agir, explore visualmente o uso do disco e inspecione arquivos relacionados ao desinstalar apps.

Language: [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [English](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md)

## ✨ Limpeza inteligente · Space Lens · Gerenciador de apps · Monitoramento ao vivo

- **Limpeza inteligente** — Analisa caches compatíveis de apps, ferramentas de desenvolvimento e do sistema, mostrando os itens antes da limpeza.
- **Space Lens** — Explore o uso do disco com um mapa de árvore visual.
- **Gerenciador de apps** — Inspecione os apps instalados e arquivos relacionados antes da remoção.
- **Monitoramento ao vivo** — Veja a atividade do sistema e configure widgets na barra de menus.
- Interface languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, French, German, Spanish, Italian, and Brazilian Portuguese.

## 📸 Capturas reais do app

<table>
<tr><td align="center"><img src="assets/screenshots/health-check.png" alt="AClean Verificação de saúde module" width="500" /><br /><sub>Verificação de saúde</sub></td><td align="center"><img src="assets/screenshots/smart-cleanup.png" alt="AClean Limpeza module" width="500" /><br /><sub>Limpeza</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/performance-optimization.png" alt="AClean Otimização module" width="500" /><br /><sub>Otimização</sub></td><td align="center"><img src="assets/screenshots/applications.png" alt="AClean Aplicativos module" width="500" /><br /><sub>Aplicativos</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/space-lens.png" alt="AClean Space Lens module" width="500" /><br /><sub>Space Lens</sub></td><td align="center"><img src="assets/screenshots/declutter.png" alt="AClean Organização module" width="500" /><br /><sub>Organização</sub></td></tr>
<tr><td align="center"><img src="assets/screenshots/system-status.png" alt="AClean Status do sistema module" width="500" /><br /><sub>Status do sistema</sub></td></tr>
</table>


## 🧰 Requirements

- macOS 13 ou posterior
- Xcode Command Line Tools com Swift 6.0 ou posterior (ou Xcode 16 ou posterior)

## Compilar a partir do código-fonte

```bash
git clone https://github.com/letmetodo/aclean-mac.git
cd aclean-mac
./build.sh --local
```

AClean é escrito em Swift e usa o SDK do macOS. A compilação local tem como alvo Apple Silicon. Downloadable builds, when available, will be listed in [Releases](https://github.com/letmetodo/aclean-mac/releases). Run the test suite with `./Tests/run_tests.sh`.

## 🔐 Cleanup and privacy

AClean mostra os itens encontrados antes da limpeza. Revise a seleção e os locais antes de confirmar. Consulte o código e as notas da versão para entender o comportamento específico. Há recursos de rede opcionais, como atualização de regras, clima e localização por IP. Não presuma que todos os recursos funcionam offline.

## 🤝 Contributing

Issues e pull requests são bem-vindas. Informe as versões do macOS e do AClean, os passos para reproduzir e logs sem dados pessoais.

## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

A pesquisa de recursos e segurança consultou Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep e Privacy Guides. São projetos independentes; a lista não implica endosso ou afiliação. A implementação, as regras de limpeza e o ícone do AClean são mantidos separadamente. Qualquer contribuição futura com código ou recursos de terceiros deve registrar a origem e a licença.
