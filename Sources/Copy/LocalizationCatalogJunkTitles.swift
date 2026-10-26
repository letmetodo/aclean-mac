import Foundation

// MARK: - 清理规则友好名
//
// SQL 的 `cm_junk_rule.title_key` 里存的是 `junk.cache.user` 这类点分键，
// 之前加载器从未读取，界面上只能显示 `com.google.Chrome`、`Code Cache` 这类技术名。
// 这里把 61 个标题键映射成各语言的人话名称。
//
// 只做「名称」，不做「解释」——解释由 `ReasonCode.localizedExplanation` 负责，两者互补。

func populateJunkTitles(_ map: inout [L10nKey: MultiLangEntry]) {
    func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
             _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
        map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                  fr: fr, de: de, es: es, it: it, ptBR: ptBR)
    }

    add(.junkTitleAiGeminiTmp, "Gemini 临时文件", "Gemini 暫存檔", "Gemini temporary files", "Gemini の一時ファイル", "Gemini 임시 파일",
        "Fichiers temporaires Gemini", "Gemini-Temporärdateien", "Archivos temporales de Gemini", "File temporanei di Gemini", "Arquivos temporários do Gemini")
    add(.junkTitleAiHfModel, "Hugging Face 模型缓存", "Hugging Face 模型快取", "Hugging Face model cache", "Hugging Face モデルキャッシュ", "Hugging Face 모델 캐시",
        "Cache de modèles Hugging Face", "Hugging-Face-Modellcache", "Caché de modelos de Hugging Face", "Cache modelli Hugging Face", "Cache de modelos do Hugging Face")
    add(.junkTitleAiIdeCache, "AI 编程工具缓存", "AI 程式開發工具快取", "AI coding tool cache", "AI コーディングツールのキャッシュ", "AI 코딩 도구 캐시",
        "Cache des outils de code IA", "Cache der KI-Coding-Tools", "Caché de herramientas de código con IA", "Cache degli strumenti di coding IA", "Cache de ferramentas de código com IA")
    add(.junkTitleAiLmstudio, "LM Studio 模型", "LM Studio 模型", "LM Studio models", "LM Studio モデル", "LM Studio 모델",
        "Modèles LM Studio", "LM-Studio-Modelle", "Modelos de LM Studio", "Modelli LM Studio", "Modelos do LM Studio")
    add(.junkTitleAiOllamaModel, "Ollama 模型文件", "Ollama 模型檔案", "Ollama model files", "Ollama モデルファイル", "Ollama 모델 파일",
        "Fichiers de modèles Ollama", "Ollama-Modelldateien", "Archivos de modelos de Ollama", "File dei modelli Ollama", "Arquivos de modelos do Ollama")
    add(.junkTitleAiOllamaOrphan, "Ollama 残留模型", "Ollama 殘留模型", "Ollama orphaned models", "Ollama の孤立モデル", "Ollama 잔여 모델",
        "Modèles Ollama orphelins", "Verwaiste Ollama-Modelle", "Modelos huérfanos de Ollama", "Modelli Ollama orfani", "Modelos órfãos do Ollama")
    add(.junkTitleAiToolCache, "AI 工具缓存", "AI 工具快取", "AI tool cache", "AI ツールのキャッシュ", "AI 도구 캐시",
        "Cache des outils IA", "Cache der KI-Tools", "Caché de herramientas de IA", "Cache degli strumenti IA", "Cache de ferramentas de IA")
    add(.junkTitleAiWorktree, "AI 工作区副本", "AI 工作區副本", "AI workspace copies", "AI ワークスペースのコピー", "AI 작업 공간 사본",
        "Copies d’espaces de travail IA", "KI-Arbeitsbereichskopien", "Copias de espacios de trabajo de IA", "Copie di aree di lavoro IA", "Cópias de áreas de trabalho de IA")
    add(.junkTitleAppCache, "应用缓存", "應用程式快取", "App cache", "アプリのキャッシュ", "앱 캐시",
        "Cache des applications", "App-Cache", "Caché de aplicaciones", "Cache delle app", "Cache de aplicativos")
    add(.junkTitleBrowserArcCache, "Arc 浏览器缓存", "Arc 瀏覽器快取", "Arc browser cache", "Arc ブラウザのキャッシュ", "Arc 브라우저 캐시",
        "Cache du navigateur Arc", "Arc-Browser-Cache", "Caché del navegador Arc", "Cache del browser Arc", "Cache do navegador Arc")
    add(.junkTitleBrowserChromiumCache, "Chromium 系浏览器缓存", "Chromium 系瀏覽器快取", "Chromium-based browser cache", "Chromium 系ブラウザのキャッシュ", "Chromium 계열 브라우저 캐시",
        "Cache des navigateurs Chromium", "Cache der Chromium-Browser", "Caché de navegadores Chromium", "Cache dei browser Chromium", "Cache de navegadores Chromium")
    add(.junkTitleBrowserChromiumServiceWorker, "Chromium 系 Service Worker", "Chromium 系 Service Worker", "Chromium-based Service Worker", "Chromium 系 Service Worker", "Chromium 계열 Service Worker",
        "Service Worker des navigateurs Chromium", "Service Worker der Chromium-Browser", "Service Worker de navegadores Chromium", "Service Worker dei browser Chromium", "Service Worker de navegadores Chromium")
    add(.junkTitleBrowserFirefoxCache, "Firefox 缓存", "Firefox 快取", "Firefox cache", "Firefox のキャッシュ", "Firefox 캐시",
        "Cache de Firefox", "Firefox-Cache", "Caché de Firefox", "Cache di Firefox", "Cache do Firefox")
    add(.junkTitleBrowserSafari, "Safari 数据", "Safari 資料", "Safari data", "Safari のデータ", "Safari 데이터",
        "Données Safari", "Safari-Daten", "Datos de Safari", "Dati di Safari", "Dados do Safari")
    add(.junkTitleBrowserSafariCache, "Safari 缓存", "Safari 快取", "Safari cache", "Safari のキャッシュ", "Safari 캐시",
        "Cache de Safari", "Safari-Cache", "Caché de Safari", "Cache di Safari", "Cache do Safari")
    add(.junkTitleCacheContainer, "沙盒容器缓存", "沙盒容器快取", "Sandbox container cache", "サンドボックスコンテナのキャッシュ", "샌드박스 컨테이너 캐시",
        "Cache des conteneurs sandbox", "Sandbox-Container-Cache", "Caché de contenedores sandbox", "Cache dei container sandbox", "Cache de contêineres sandbox")
    add(.junkTitleCacheUser, "用户缓存", "使用者快取", "User cache", "ユーザーキャッシュ", "사용자 캐시",
        "Cache utilisateur", "Benutzercache", "Caché del usuario", "Cache utente", "Cache do usuário")
    add(.junkTitleDesignAdobeCache, "Adobe 缓存", "Adobe 快取", "Adobe cache", "Adobe のキャッシュ", "Adobe 캐시",
        "Cache Adobe", "Adobe-Cache", "Caché de Adobe", "Cache di Adobe", "Cache da Adobe")
    add(.junkTitleDesignAdobeMediaCache, "Adobe 媒体缓存", "Adobe 媒體快取", "Adobe media cache", "Adobe のメディアキャッシュ", "Adobe 미디어 캐시",
        "Cache multimédia Adobe", "Adobe-Mediencache", "Caché multimedia de Adobe", "Cache multimediale Adobe", "Cache de mídia da Adobe")
    add(.junkTitleDesignFcp, "Final Cut Pro 数据", "Final Cut Pro 資料", "Final Cut Pro data", "Final Cut Pro のデータ", "Final Cut Pro 데이터",
        "Données Final Cut Pro", "Final-Cut-Pro-Daten", "Datos de Final Cut Pro", "Dati di Final Cut Pro", "Dados do Final Cut Pro")
    add(.junkTitleDesignJianyingCache, "剪映缓存", "剪映快取", "CapCut cache", "CapCut のキャッシュ", "CapCut 캐시",
        "Cache de CapCut", "CapCut-Cache", "Caché de CapCut", "Cache di CapCut", "Cache do CapCut")
    add(.junkTitleDevBrewCache, "Homebrew 缓存", "Homebrew 快取", "Homebrew cache", "Homebrew のキャッシュ", "Homebrew 캐시",
        "Cache Homebrew", "Homebrew-Cache", "Caché de Homebrew", "Cache di Homebrew", "Cache do Homebrew")
    add(.junkTitleDevBrewDownloads, "Homebrew 下载包", "Homebrew 下載檔", "Homebrew downloads", "Homebrew のダウンロード", "Homebrew 다운로드",
        "Téléchargements Homebrew", "Homebrew-Downloads", "Descargas de Homebrew", "Download di Homebrew", "Downloads do Homebrew")
    add(.junkTitleDevGradleDaemon, "Gradle 守护进程日志", "Gradle 常駐程序日誌", "Gradle daemon logs", "Gradle デーモンのログ", "Gradle 데몬 로그",
        "Journaux du démon Gradle", "Gradle-Daemon-Protokolle", "Registros del daemon de Gradle", "Log del daemon Gradle", "Logs do daemon do Gradle")
    add(.junkTitleDevNpmCacache, "npm 缓存", "npm 快取", "npm cache", "npm のキャッシュ", "npm 캐시",
        "Cache npm", "npm-Cache", "Caché de npm", "Cache di npm", "Cache do npm")
    add(.junkTitleDevNpmLogs, "npm 日志", "npm 日誌", "npm logs", "npm のログ", "npm 로그",
        "Journaux npm", "npm-Protokolle", "Registros de npm", "Log di npm", "Logs do npm")
    add(.junkTitleDevPkg, "包管理器缓存", "套件管理器快取", "Package manager cache", "パッケージマネージャのキャッシュ", "패키지 관리자 캐시",
        "Cache du gestionnaire de paquets", "Paketmanager-Cache", "Caché del gestor de paquetes", "Cache del gestore pacchetti", "Cache do gerenciador de pacotes")
    add(.junkTitleDevPkgSafe, "包管理器缓存（安全）", "套件管理器快取（安全）", "Package manager cache (safe)", "パッケージマネージャのキャッシュ（安全）", "패키지 관리자 캐시(안전)",
        "Cache du gestionnaire de paquets (sûr)", "Paketmanager-Cache (sicher)", "Caché del gestor de paquetes (seguro)", "Cache del gestore pacchetti (sicura)", "Cache do gerenciador de pacotes (seguro)")
    add(.junkTitleDevPkgUnverified, "包管理器缓存（未校验）", "套件管理器快取（未驗證）", "Package manager cache (unverified)", "パッケージマネージャのキャッシュ（未検証）", "패키지 관리자 캐시(미검증)",
        "Cache du gestionnaire de paquets (non vérifié)", "Paketmanager-Cache (ungeprüft)", "Caché del gestor de paquetes (sin verificar)", "Cache del gestore pacchetti (non verificata)", "Cache do gerenciador de pacotes (não verificado)")
    add(.junkTitleDevProject, "项目构建产物", "專案建置產物", "Project build artifacts", "プロジェクトのビルド生成物", "프로젝트 빌드 산출물",
        "Artefacts de compilation", "Build-Artefakte", "Artefactos de compilación", "Artefatti di build", "Artefatos de build")
    add(.junkTitleElectronCache, "Electron 应用缓存", "Electron 應用程式快取", "Electron app cache", "Electron アプリのキャッシュ", "Electron 앱 캐시",
        "Cache des applications Electron", "Electron-App-Cache", "Caché de aplicaciones Electron", "Cache delle app Electron", "Cache de aplicativos Electron")
    add(.junkTitleElectronServiceWorker, "Electron Service Worker", "Electron Service Worker", "Electron Service Worker", "Electron Service Worker", "Electron Service Worker",
        "Service Worker Electron", "Electron-Service-Worker", "Service Worker de Electron", "Service Worker Electron", "Service Worker do Electron")
    add(.junkTitleImMeet, "腾讯会议缓存", "騰訊會議快取", "Tencent Meeting cache", "Tencent Meeting のキャッシュ", "Tencent Meeting 캐시",
        "Cache de Tencent Meeting", "Tencent-Meeting-Cache", "Caché de Tencent Meeting", "Cache di Tencent Meeting", "Cache do Tencent Meeting")
    add(.junkTitleImQq, "QQ 缓存", "QQ 快取", "QQ cache", "QQ のキャッシュ", "QQ 캐시",
        "Cache QQ", "QQ-Cache", "Caché de QQ", "Cache di QQ", "Cache do QQ")
    add(.junkTitleImTelegramMedia, "Telegram 媒体缓存", "Telegram 媒體快取", "Telegram media cache", "Telegram のメディアキャッシュ", "Telegram 미디어 캐시",
        "Cache multimédia Telegram", "Telegram-Mediencache", "Caché multimedia de Telegram", "Cache multimediale Telegram", "Cache de mídia do Telegram")
    add(.junkTitleImWechatCache, "微信缓存", "微信快取", "WeChat cache", "WeChat のキャッシュ", "WeChat 캐시",
        "Cache WeChat", "WeChat-Cache", "Caché de WeChat", "Cache di WeChat", "Cache do WeChat")
    add(.junkTitleImWechatMedia, "微信媒体文件", "微信媒體檔案", "WeChat media files", "WeChat のメディアファイル", "WeChat 미디어 파일",
        "Fichiers multimédias WeChat", "WeChat-Mediendateien", "Archivos multimedia de WeChat", "File multimediali WeChat", "Arquivos de mídia do WeChat")
    add(.junkTitleImWecom, "企业微信缓存", "企業微信快取", "WeCom cache", "WeCom のキャッシュ", "WeCom 캐시",
        "Cache WeCom", "WeCom-Cache", "Caché de WeCom", "Cache di WeCom", "Cache do WeCom")
    add(.junkTitleLeftoverOrphan, "已卸载应用残留", "已解除安裝應用程式殘留", "Leftovers from uninstalled apps", "削除済みアプリの残存ファイル", "삭제된 앱의 잔여 파일",
        "Résidus d’applications désinstallées", "Reste deinstallierter Apps", "Restos de apps desinstaladas", "Residui di app disinstallate", "Sobras de apps desinstalados")
    add(.junkTitleLogDiagUser, "诊断日志", "診斷日誌", "Diagnostic logs", "診断ログ", "진단 로그",
        "Journaux de diagnostic", "Diagnoseprotokolle", "Registros de diagnóstico", "Log di diagnostica", "Logs de diagnóstico")
    add(.junkTitleLogUser, "用户日志", "使用者日誌", "User logs", "ユーザーログ", "사용자 로그",
        "Journaux utilisateur", "Benutzerprotokolle", "Registros del usuario", "Log utente", "Logs do usuário")
    add(.junkTitleMediaSpotify, "Spotify 缓存", "Spotify 快取", "Spotify cache", "Spotify のキャッシュ", "Spotify 캐시",
        "Cache Spotify", "Spotify-Cache", "Caché de Spotify", "Cache di Spotify", "Cache do Spotify")
    add(.junkTitleSystemDarwinCache, "系统缓存", "系統快取", "System cache", "システムキャッシュ", "시스템 캐시",
        "Cache système", "Systemcache", "Caché del sistema", "Cache di sistema", "Cache do sistema")
    add(.junkTitleSystemDarwinTemp, "系统临时文件", "系統暫存檔", "System temporary files", "システムの一時ファイル", "시스템 임시 파일",
        "Fichiers temporaires système", "System-Temporärdateien", "Archivos temporales del sistema", "File temporanei di sistema", "Arquivos temporários do sistema")
    add(.junkTitleSystemDiskImageInstalled, "已安装磁盘映像", "已安裝磁碟映像", "Mounted disk images", "マウント済みディスクイメージ", "마운트된 디스크 이미지",
        "Images disque montées", "Eingebundene Disk-Images", "Imágenes de disco montadas", "Immagini disco montate", "Imagens de disco montadas")
    add(.junkTitleSystemDiskImageOther, "其他磁盘映像", "其他磁碟映像", "Other disk images", "その他のディスクイメージ", "기타 디스크 이미지",
        "Autres images disque", "Weitere Disk-Images", "Otras imágenes de disco", "Altre immagini disco", "Outras imagens de disco")
    add(.junkTitleSystemIosBackup, "iOS 设备备份", "iOS 裝置備份", "iOS device backups", "iOS デバイスのバックアップ", "iOS 기기 백업",
        "Sauvegardes d’appareils iOS", "iOS-Gerätesicherungen", "Copias de seguridad de dispositivos iOS", "Backup di dispositivi iOS", "Backups de dispositivos iOS")
    add(.junkTitleSystemIpsw, "iOS 固件包", "iOS 韌體檔", "iOS firmware files", "iOS ファームウェア", "iOS 펌웨어 파일",
        "Fichiers firmware iOS", "iOS-Firmware-Dateien", "Archivos de firmware de iOS", "File firmware iOS", "Arquivos de firmware do iOS")
    add(.junkTitleSystemMail, "邮件附件", "郵件附件", "Mail attachments", "メールの添付ファイル", "메일 첨부 파일",
        "Pièces jointes Mail", "Mail-Anhänge", "Adjuntos de Mail", "Allegati di Mail", "Anexos do Mail")
    add(.junkTitleSystemPlist, "偏好设置残留", "偏好設定殘留", "Leftover preference files", "環境設定の残存ファイル", "환경설정 잔여 파일",
        "Fichiers de préférences résiduels", "Verwaiste Einstellungsdateien", "Archivos de preferencias residuales", "File di preferenze residui", "Arquivos de preferências residuais")
    add(.junkTitleSystemQuarantine, "隔离区记录", "隔離區記錄", "Quarantine records", "隔離記録", "격리 기록",
        "Enregistrements de quarantaine", "Quarantäne-Einträge", "Registros de cuarentena", "Record di quarantena", "Registros de quarentena")
    add(.junkTitleSystemSavedState, "应用窗口状态", "應用程式視窗狀態", "Saved app window state", "アプリのウインドウ状態", "앱 윈도우 상태",
        "État des fenêtres enregistré", "Gespeicherter Fensterzustand", "Estado de ventanas guardado", "Stato delle finestre salvato", "Estado de janelas salvo")
    add(.junkTitleSystemVarlog, "系统日志", "系統日誌", "System logs", "システムログ", "시스템 로그",
        "Journaux système", "Systemprotokolle", "Registros del sistema", "Log di sistema", "Logs do sistema")
    add(.junkTitleXcodeArchives, "Xcode 归档", "Xcode 封存檔", "Xcode archives", "Xcode アーカイブ", "Xcode 아카이브",
        "Archives Xcode", "Xcode-Archive", "Archivos de Xcode", "Archivi Xcode", "Arquivos do Xcode")
    add(.junkTitleXcodeCache, "Xcode 缓存", "Xcode 快取", "Xcode cache", "Xcode のキャッシュ", "Xcode 캐시",
        "Cache Xcode", "Xcode-Cache", "Caché de Xcode", "Cache di Xcode", "Cache do Xcode")
    add(.junkTitleXcodeDerivedLive, "Xcode 派生数据", "Xcode 衍生資料", "Xcode derived data", "Xcode の派生データ", "Xcode 파생 데이터",
        "Données dérivées Xcode", "Xcode-DerivedData", "Datos derivados de Xcode", "Dati derivati di Xcode", "Dados derivados do Xcode")
    add(.junkTitleXcodeDerivedOrphan, "Xcode 残留派生数据", "Xcode 殘留衍生資料", "Xcode orphaned derived data", "Xcode の孤立した派生データ", "Xcode 잔여 파생 데이터",
        "Données dérivées orphelines Xcode", "Verwaiste Xcode-DerivedData", "Datos derivados huérfanos de Xcode", "Dati derivati orfani di Xcode", "Dados derivados órfãos do Xcode")
    add(.junkTitleXcodeDeviceSupport, "Xcode 设备支持文件", "Xcode 裝置支援檔案", "Xcode device support files", "Xcode のデバイスサポート", "Xcode 기기 지원 파일",
        "Fichiers de support d’appareils Xcode", "Xcode-Geräteunterstützung", "Archivos de soporte de dispositivos de Xcode", "File di supporto dispositivi Xcode", "Arquivos de suporte a dispositivos do Xcode")
    add(.junkTitleXcodeDeviceSupportLatest, "Xcode 最新设备支持", "Xcode 最新裝置支援", "Xcode latest device support", "Xcode の最新デバイスサポート", "Xcode 최신 기기 지원",
        "Support d’appareil Xcode le plus récent", "Neueste Xcode-Geräteunterstützung", "Soporte de dispositivo más reciente de Xcode", "Supporto dispositivo più recente di Xcode", "Suporte a dispositivo mais recente do Xcode")
    add(.junkTitleXcodeSimctl, "模拟器缓存", "模擬器快取", "Simulator cache", "シミュレータのキャッシュ", "시뮬레이터 캐시",
        "Cache du simulateur", "Simulator-Cache", "Caché del simulador", "Cache del simulatore", "Cache do simulador")
    add(.junkTitleXcodeSimulator, "模拟器运行时", "模擬器執行環境", "Simulator runtimes", "シミュレータのランタイム", "시뮬레이터 런타임",
        "Runtimes du simulateur", "Simulator-Runtimes", "Entornos de ejecución del simulador", "Runtime del simulatore", "Runtimes do simulador")
}

// MARK: - 查询入口

/// 把规则的 `title_key` 解析成本地化友好名。
///
/// 刻意做成「UI 层查询」而不是在扫描时写进 `Node.name`：
/// `Node.name` 参与路径匹配、去重与搜索，改它会牵动整条扫描链路。
/// 这里只影响展示，扫描逻辑一行不动。
enum JunkRuleTitle {

    /// 用规则 ID（如 `JC.CACHE.USER`）取友好名；没有配置时返回 nil，调用方回退到路径名。
    static func friendlyName(forRuleID ruleID: String?) -> String? {
        guard let ruleID, !ruleID.isEmpty else { return nil }
        guard let rawTitleKey = KnowledgeBaseManager.shared.authored.junk[ruleID]?.titleKey,
              !rawTitleKey.isEmpty else { return nil }
        return localized(forTitleKey: rawTitleKey)
    }

    /// 用原始 `title_key`（如 `junk.cache.user`）取友好名。
    static func localized(forTitleKey rawTitleKey: String) -> String? {
        guard let key = map[rawTitleKey] else { return nil }
        return L10n.localized(key)
    }

    private static let map: [String: L10nKey] = [
        // 这 4 条规则的 `title_key` 历史遗留成了 L10nKey 的原名（不带 `junk.` 前缀），
        // 不是笔误、也不用改库：它们的译文早已在 LocalizationCatalogBatch5To7 里，
        // 这里补上映射即可，否则会静默回退成技术路径名。
        "junkAppStoreCacheTitle": .junkAppStoreCacheTitle,
        "junkJetBrainsCacheTitle": .junkJetBrainsCacheTitle,
        "junkProtectedPubCacheTitle": .junkProtectedPubCacheTitle,
        "junkProtectedSpotifyCacheTitle": .junkProtectedSpotifyCacheTitle,
        "junk.ai.gemini.tmp": .junkTitleAiGeminiTmp,
        "junk.ai.hf.model": .junkTitleAiHfModel,
        "junk.ai.ide.cache": .junkTitleAiIdeCache,
        "junk.ai.lmstudio": .junkTitleAiLmstudio,
        "junk.ai.ollama.model": .junkTitleAiOllamaModel,
        "junk.ai.ollama.orphan": .junkTitleAiOllamaOrphan,
        "junk.ai.tool.cache": .junkTitleAiToolCache,
        "junk.ai.worktree": .junkTitleAiWorktree,
        "junk.app.cache": .junkTitleAppCache,
        "junk.browser.arc.cache": .junkTitleBrowserArcCache,
        "junk.browser.chromium.cache": .junkTitleBrowserChromiumCache,
        "junk.browser.chromium.serviceWorker": .junkTitleBrowserChromiumServiceWorker,
        "junk.browser.firefox.cache": .junkTitleBrowserFirefoxCache,
        "junk.browser.safari": .junkTitleBrowserSafari,
        "junk.browser.safari.cache": .junkTitleBrowserSafariCache,
        "junk.cache.container": .junkTitleCacheContainer,
        "junk.cache.user": .junkTitleCacheUser,
        "junk.design.adobe.cache": .junkTitleDesignAdobeCache,
        "junk.design.adobe.mediaCache": .junkTitleDesignAdobeMediaCache,
        "junk.design.fcp": .junkTitleDesignFcp,
        "junk.design.jianying.cache": .junkTitleDesignJianyingCache,
        "junk.dev.brew.cache": .junkTitleDevBrewCache,
        "junk.dev.brew.downloads": .junkTitleDevBrewDownloads,
        "junk.dev.gradle.daemon": .junkTitleDevGradleDaemon,
        "junk.dev.npm.cacache": .junkTitleDevNpmCacache,
        "junk.dev.npm.logs": .junkTitleDevNpmLogs,
        "junk.dev.pkg": .junkTitleDevPkg,
        "junk.dev.pkg.safe": .junkTitleDevPkgSafe,
        "junk.dev.pkg.unverified": .junkTitleDevPkgUnverified,
        "junk.dev.project": .junkTitleDevProject,
        "junk.electron.cache": .junkTitleElectronCache,
        "junk.electron.serviceWorker": .junkTitleElectronServiceWorker,
        "junk.im.meet": .junkTitleImMeet,
        "junk.im.qq": .junkTitleImQq,
        "junk.im.telegram.media": .junkTitleImTelegramMedia,
        "junk.im.wechat.cache": .junkTitleImWechatCache,
        "junk.im.wechat.media": .junkTitleImWechatMedia,
        "junk.im.wecom": .junkTitleImWecom,
        "junk.leftover.orphan": .junkTitleLeftoverOrphan,
        "junk.log.diag.user": .junkTitleLogDiagUser,
        "junk.log.user": .junkTitleLogUser,
        "junk.media.spotify": .junkTitleMediaSpotify,
        "junk.system.darwinCache": .junkTitleSystemDarwinCache,
        "junk.system.darwinTemp": .junkTitleSystemDarwinTemp,
        "junk.system.diskImage.installed": .junkTitleSystemDiskImageInstalled,
        "junk.system.diskImage.other": .junkTitleSystemDiskImageOther,
        "junk.system.iosBackup": .junkTitleSystemIosBackup,
        "junk.system.ipsw": .junkTitleSystemIpsw,
        "junk.system.mail": .junkTitleSystemMail,
        "junk.system.plist": .junkTitleSystemPlist,
        "junk.system.quarantine": .junkTitleSystemQuarantine,
        "junk.system.savedState": .junkTitleSystemSavedState,
        "junk.system.varlog": .junkTitleSystemVarlog,
        "junk.xcode.archives": .junkTitleXcodeArchives,
        "junk.xcode.cache": .junkTitleXcodeCache,
        "junk.xcode.derived.live": .junkTitleXcodeDerivedLive,
        "junk.xcode.derived.orphan": .junkTitleXcodeDerivedOrphan,
        "junk.xcode.deviceSupport": .junkTitleXcodeDeviceSupport,
        "junk.xcode.deviceSupport.latest": .junkTitleXcodeDeviceSupportLatest,
        "junk.xcode.simctl": .junkTitleXcodeSimctl,
        "junk.xcode.simulator": .junkTitleXcodeSimulator,
    ]
}
