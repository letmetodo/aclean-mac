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


## 🌟 O que diferencia o AClean

- **O próprio app nativo é open source.** O app SwiftUI do AClean é publicado sob Apache-2.0 e pode ser inspecionado, modificado e redistribuído.
- **Várias tarefas em um único app nativo.** Revise itens de limpeza, explore o disco em um mapa de árvore visual, confira arquivos relacionados antes de desinstalar apps, veja o estado geral do sistema e consulte rapidamente o status pela barra de menus.
- **Revise antes de limpar.** O AClean mostra os itens compatíveis e seus caminhos antes de você confirmar a seleção.
- **Dez idiomas.** A interface do app e o README estão disponíveis em dez idiomas.
- **Transparência no uso da rede.** Atualizações opcionais de regras, clima e localização por IP usam a rede. Consulte “Limpeza e privacidade” e o código-fonte para detalhes.

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

## 🔐 Privacidade, escopo da verificação e exclusão

- **Escopo:** conforme o módulo, o AClean verifica caminhos locais compatíveis com as regras: caches e registros de apps, navegadores e sistema; dados de desenvolvimento como Xcode DerivedData/CoreSimulator; caches de gerenciadores de pacotes; apps instalados e arquivos relacionados identificados. O Space Lens exibe o uso do disco local em modo somente leitura. Alguns locais protegidos exigem Acesso Total ao Disco; sem essa permissão, os resultados podem ficar incompletos.
- **Antes de agir:** as prévias de limpeza e desinstalação mostram nome, caminho e tamanho dos itens para você revisar a seleção antes de confirmar.
- **Restauração:** arquivos de limpeza comum e arquivos relacionados a apps são movidos para o Lixo do macOS e, em geral, podem ser restaurados enquanto permanecerem lá. Esvaziar o Lixo, excluir dados de simuladores Xcode, executar Docker/OrbStack prune e algumas operações com snapshots APFS podem ser permanentes. Confira o tipo de ação e o recibo antes de confirmar.
- **Rede:** atualizações automáticas de regras vêm ativadas por padrão e baixam um manifesto e o banco de regras por HTTPS; o servidor vê o IP da solicitação e metadados de rede comuns. Clima e localização por IP vêm desativados por padrão. Quando ativados, provedores de localização veem o IP; a busca de cidade envia o texto digitado e o idioma da interface ao Open-Meteo, e a previsão envia latitude e longitude. As solicitações atuais não incluem caminhos verificados, nomes de arquivos nem resultados da limpeza. Métricas do sistema são exibidas localmente.

## ⚠️ Problemas conhecidos e limitações

- O download atual é exclusivo para Apple Silicon (arm64) e requer macOS 13 ou posterior.
- O app v1.0.0 não tem assinatura Apple Developer ID nem notarização. O Gatekeeper pode bloquear a primeira abertura; consulte as notas da versão e o [guia da Apple para abrir apps com segurança](https://support.apple.com/en-us/102445).
- Sem Acesso Total ao Disco, alguns locais protegidos podem não ser verificados por completo. Bugs atualmente acompanhados estão em [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues).
## 🛡️ Relatórios de segurança e feedback

- **Vulnerabilidades:** informe-as em privado por [GitHub Security Advisories](https://github.com/letmetodo/aclean-mac/security/advisories/new). Não publique detalhes em uma issue pública. Consulte [SECURITY.md](SECURITY.md).
- **Bugs e sugestões:** use [GitHub Issues](https://github.com/letmetodo/aclean-mac/issues/new). Inclua versões do AClean e macOS, módulo afetado, passos para reproduzir, resultado esperado e observado, e logs ou capturas sem caminhos pessoais ou dados privados.
## 📜 License

Licensed under the [Apache License 2.0](LICENSE).

## 🧭 Project references

A pesquisa de recursos e segurança consultou Clean-Me, Harbofly, MacSai, Mole, Pearcleaner, PureMac, ClearDisk, Tencent Lemon Cleaner, Lume, mac-cleaner-cli, mac-cleanup-py, mac-cleanup-sh, Purge, Xcode DevCleaner, MacSweep e Privacy Guides. São projetos independentes; a lista não implica endosso ou afiliação. A implementação, as regras de limpeza e o ícone do AClean são mantidos separadamente. Qualquer contribuição futura com código ou recursos de terceiros deve registrar a origem e a licença.
