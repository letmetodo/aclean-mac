import Foundation

extension LocalizationCatalog {
    static func populateBatch8(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.menuBarWeatherHoverForecastFormat, "实况 %.1f°C · 悬停查看周预报", "實況 %.1f°C · 懸停查看周預報", "Current %.1f°C · Hover for weekly forecast", "現在 %.1f°C · ホバーで週間予報を表示", "현재 %.1f°C · 주간 예보 보기",
            "Actuel %.1f °C · Survoler pour la météo hebdomadaire", "Aktuell %.1f °C · Für Wochenbericht bewegen", "Actual %.1f°C · Pase el ratón para ver el pronóstico", "Attuale %.1f°C · Passa sopra per il meteo settimanale", "Atual %.1f°C · Passe o cursor para ver a previsão semanal")
        add(.menuBarWriteSpeedPrefixFormat, "写入: %@", "寫入: %@", "Write: %@", "書き込み: %@", "쓰기: %@",
            "Écriture : %@", "Schreiben: %@", "Escritura: %@", "Scrittura: %@", "Gravação: %@")
        add(.metaAdminRequired, "需要管理员授权", "需要管理員授權", "Admin authorization required", "管理者権限が必要", "관리자 권한 필요",
            "Autorisation administrateur requise", "Admin-Berechtigung erforderlich", "Se requiere autorización de administrador", "Autorizzazione amministratore richiesta", "Autorização de administrador necessária")
        add(.metaArchitecture, "架构", "架構", "Architecture", "アーキテクチャ", "아키텍처",
            "Architecture", "Architektur", "Arquitectura", "Architettura", "Arquitetura")
        add(.metaConfigFiles, "配置文件", "設定檔案", "Configuration Files", "設定ファイル", "설정 파일",
            "Fichiers de configuration", "Konfigurationsdateien", "Archivos de configuración", "File di configurazione", "Arquivos de configuração")
        add(.metaCrash, "崩溃", "當機", "Crash", "クラッシュ", "충돌",
            "Plantage", "Absturz", "Bloqueo", "Blocco", "Falha")
        add(.metaDescription, "说明", "說明", "Description", "説明", "설명",
            "Description", "Beschreibung", "Descripción", "Descrizione", "Descrição")
        add(.metaDirectoryPurpose, "目录用途", "目錄用途", "Directory Purpose", "ディレクトリ用途", "디렉터리 용도",
            "Rôle du dossier", "Verzeichniszweck", "Propósito de la carpeta", "Scopo della cartella", "Finalidade da Pasta")
        add(.metaIdentifier, "标识", "識別碼", "Identifier", "識別子", "식별자",
            "Identifiant", "Kennung", "Identificador", "Identificatore", "Identificador")
        add(.metaImages, "映像", "映像檔", "Disk Images", "ディスクイメージ", "디스크 이미지",
            "Images disque", "Images", "Imágenes", "Immagini", "Imagens")
        add(.metaLastUsed, "最后使用", "上次使用", "Last Used", "最終使用日", "마지막 사용",
            "Dernière utilisation", "Zuletzt verwendet", "Último uso", "Ultimo utilizzo", "Último uso")
        add(.metaLaunch, "启动", "啟動", "Launch", "起動", "시동",
            "Lancement", "Start", "Inicio", "Avvio", "Inicialização")
        add(.metaOnly32Bit, "仅 32 位", "僅 32 位元", "32-bit Only", "32ビットのみ", "32비트 전용",
            "32 bits uniquement", "Nur 32-Bit", "Solo 32 bits", "Solo 32 bit", "Apenas 32 bits")
        add(.metaPath, "路径", "路徑", "Path", "パス", "경로",
            "Chemin", "Pfad", "Ruta", "Percorso", "Caminho")
        add(.metaPermissions, "权限", "權限", "Permissions", "アクセス権", "권한",
            "Autorisations", "Berechtigungen", "Permisos", "Permessi", "Permissões")
        add(.metaPlugins, "插件", "外掛模組", "Plugins", "プラグイン", "플러그인",
            "Modules", "Plug-ins", "Complementos", "Plug-in", "Plug-ins")
        add(.metaPreferences, "偏好", "偏好設定", "Preferences", "環境設定", "환경설정",
            "Préférences", "Einstellungen", "Preferencias", "Preferenze", "Preferências")
        add(.metaProgram, "程序", "程式", "Program", "プログラム", "프로그램",
            "Programme", "Programm", "Programa", "Programma", "Programa")
        add(.metaPurposeCategory, "用途分类", "用途分類", "Purpose Category", "カテゴリ", "용도 분류",
            "Catégorie", "Kategorie", "Categoría", "Categoria", "Categoria de Uso")
        add(.metaReceipts, "收据", "收據", "Receipts", "レシート", "영수증",
            "Reçus", "Quittungen", "Recibos", "Ricevute", "Recibos")
        add(.metaScope, "作用域", "作用域", "Scope", "スコープ", "범위",
            "Portée", "Geltungsbereich", "Ámbito", "Ambito", "Escopo")
        add(.metaSource, "来源", "來源", "Source", "ソース", "출처",
            "Source", "Quelle", "Fuente", "Origine", "Origem")
        add(.metaUpdateChannel, "更新通道", "更新通道", "Update Channel", "アップデートチャンネル", "업데이트 채널",
            "Canal de mise à jour", "Update-Kanal", "Canal de actualización", "Canale di aggiornamento", "Canal de atualização")
        add(.metaVendor, "经销商", "經銷商", "Developer", "開発元", "개발사",
            "Développeur", "Entwickler", "Desarrollador", "Sviluppatore", "Desenvolvedor")
        add(.metaVersion, "版本", "版本", "Version", "バージョン", "버전",
            "Version", "Version", "Versión", "Versione", "Versão")
        add(.microphoneInUse, "麦克风使用中", "麥克風使用中", "Microphone in Use", "マイクを使用中", "마이크 사용 중",
            "Microphone en cours d’utilisation", "Mikrofon aktiv", "Micrófono en uso", "Microfono in uso", "Microfone em Uso")
        add(.modificationDate, "修改日期", "修改日期", "Date Modified", "変更日", "수정된 날짜",
            "Date de modification", "Änderungsdatum", "Fecha de modificación", "Data di modifica", "Data de modificação")
        add(.modified, "修改时间", "修改時間", "Modified", "変更日", "수정일",
            "Modifié", "Geändert", "Modificado", "Modificato", "Modificado")
        add(.moduleApplications, "应用程序", "應用程式", "Applications", "アプリ", "앱",
            "Applications", "Apps", "Aplicaciones", "Applicazioni", "Aplicativos")
        add(.moduleApplicationsDesc, "全面掌控你的应用程序：彻底卸载或清除旧应用残留。", "全面掌控你的應用程式：徹底卸載或清除舊應用殘留。", "Take full control of your applications: clean uninstall or remove orphaned leftovers.", "アプリケーションを完全管理：アプリの完全削除や古い残りファイルをクリーンアップ。", "애플리케이션을 완벽하게 제어하세요: 깔끔한 앱 삭제 및 오래된 잔여 파일 제거.",
            "Prenez le contrôle total de vos applications : désinstallation propre ou suppression des résidus.", "Behalten Sie die volle Kontrolle über Ihre Apps: Saubere Deinstallation oder Bereinigung von Überresten.", "Tome el control total de sus aplicaciones: desinstalación limpia o eliminación de restos.", "Assumi il pieno controllo delle tue applicazioni: disinstallazione completa o rimozione dei residui.", "Assuma o controle total de seus aplicativos: desinstalação limpa ou remoção de resíduos órfãos.")
        add(.moduleApplicationsSubtitle, "卸载与清除残留", "卸載與清除殘留", "Uninstall and Clean Leftovers", "アンインストールと残りファイルの削除", "제거 및 잔여 파일 정리",
            "Désinstaller et nettoyer les résidus", "Deinstallieren und Überreste bereinigen", "Desinstalar y limpiar restos", "Disinstalla e pulisci residui", "Desinstalar e Limpar Resíduos")
        add(.moduleAppsUninstallDesc, "全面掌控你的应用程序：彻底卸载或清除旧应用残留。", "全面掌控你的應用程序：徹底卸載或清除舊應用殘留。", "Full control over your apps: completely uninstall or clean old app leftovers.", "アプリケーションを完全管理：アプリの徹底削除や不要な残留データの消去を行います。", "앱을 완벽히 제어: 오래된 앱을 완전히 삭제하거나 잔여 파일을 깨끗이 정리합니다.",
            "Contrôle total de vos applications : désinstallez complètement ou nettoyez les résidus.", "Volle Kontrolle über Ihre Apps: Vollständig deinstallieren oder alte Reste bereinigen.", "Control total de sus aplicaciones: desinstale por completo o limpie restos antiguos.", "Controllo completo delle app: disinstalla completamente o pulisci i vecchi residui.", "Controle total sobre seus aplicativos: desinstale completamente ou limpe resíduos antigos.")
        add(.moduleAppsUninstallTitle, "卸载与清除残留", "卸載與清除殘留", "Uninstall & Leftovers Cleanup", "アンインストールと残留消去", "삭제 및 잔여물 정리",
            "Désinstallation et nettoyage des résidus", "Deinstallation & Reste bereinigen", "Desinstalación y limpieza de residuos", "Disinstallazione e pulizia residui", "Desinstalação e limpeza de resíduos")
        add(.moduleAssistant, "智能助手", "智慧助手", "Assistant", "アシスタント", "어시스턴트",
            "Assistant", "Assistent", "Asistente", "Assistente", "Assistente")
        add(.moduleAssistantDesc, "健康分与个性化建议", "健康分與個性化建議", "Health Score & Tailored Suggestions", "健康スコアと個別最適化された提案", "상태 점수 및 맞춤형 최적화 권장사항",
            "Score de santé et conseils personnalisés", "Integritäts-Score & Individuelle Vorschläge", "Puntuación de estado y recomendaciones", "Punteggio di salute e suggerimenti personalizzati", "Pontuação de integridade e sugestões personalizadas")
        add(.moduleAssistantSubtitle, "健康分与个性化建议", "健康分與個性化建議", "Health Score & Recommendations", "ヘルススコアと個別アドバイス", "건강 점수 및 맞춤 권장 사항",
            "Score de santé et conseils personnalisés", "Zustandsbewertung & Empfehlungen", "Puntuación de estado y recomendaciones", "Punteggio di salute e suggerimenti personalizzati", "Pontuação de Saúde e Recomendações")
        add(.moduleAssistantTitle, "助手", "助手", "Assistant", "アシスタント", "어시스턴트",
            "Assistant", "Assistent", "Asistente", "Assistente", "Assistente")
        add(.moduleDeclutter, "整理杂乱", "整理雜亂", "Declutter", "ファイル整理", "파일 정리",
            "Désencombrer", "Aufräumen", "Organizar", "Riordina", "Organizar")
        add(.moduleDeclutterAlt, "整理归档", "整理歸檔", "Declutter", "ファイル整理", "파일 정리",
            "Désencombrer", "Aufräumen", "Organizar", "Riordina", "Organizar")
        add(.moduleDeclutterDesc, "对存储空间进行整理，删除不需要的文件，并将杂乱程度降至最低。", "對存儲空間進行整理，刪除不需要的文件，並將雜亂程度降至最低。", "Declutter your storage, remove unneeded files, and keep things tidy.", "ストレージを整理し、不要なファイルを削除して常にクリーンな状態を保ちます。", "저장 공간을 정리하고 불필요한 파일을 제거하여 깔끔한 상태를 유지합니다.",
            "Organisez votre stockage, supprimez les fichiers inutiles et restez ordonné.", "Speicherplatz aufräumen, Unnötiges entfernen und Ordnung halten.", "Organice el almacenamiento, elimine archivos innecesarios y mantenga el orden.", "Riorganizza lo spazio di archiviazione, rimuovi i file non necessari e mantieni l'ordine.", "Organize o armazenamento, remova arquivos desnecessários e mantenha tudo em ordem.")
        add(.moduleDeclutterTitle, "大文件、重复文件与下载项", "大文件、重複文件與下載項", "Large Files, Duplicates & Downloads", "大容量ファイル、重複ファイル、ダウンロード", "대용량 파일, 중복 파일 및 다운로드",
            "Gros fichiers, doublons et téléchargements", "Große Dateien, Duplikate & Downloads", "Archivos grandes, duplicados y descargas", "File grandi, duplicati e download", "Arquivos grandes, duplicatas e downloads")
        add(.moduleJunk, "清理", "清理", "System Junk", "システムジャンク", "시스템 정크",
            "Fichiers inutiles", "Systemmüll", "Basura del sistema", "File inutili", "Lixo do Sistema")
        add(.moduleJunkAlt, "垃圾清理", "垃圾清理", "Clean", "クリーン", "정리",
            "Nettoyer", "Bereinigen", "Limpiar", "Pulizia", "Limpar")
        add(.moduleLiveMonitor, "系统监控", "系統監控", "Status", "ステータス", "상태 모니터",
            "État du système", "Systemstatus", "Estado", "Stato sistema", "Status do Sistema")
        add(.moduleLiveMonitorAlt, "实时监控", "即時監控", "Live Monitor", "リアルタイム監視", "실시간 모니터",
            "Moniteur en direct", "Live-Monitor", "Monitor en vivo", "Monitoraggio", "Monitor ao Vivo")
        add(.moduleOrganizeDesc, "对存储空间进行整理，删除不需要的文件，并将杂乱程度降至最低。", "對儲存空間進行整理，刪除不需要的檔案，並將雜亂程度降至最低。", "Declutter your storage, eliminate unneeded files, and minimize clutter.", "ストレージを整理し、不要なファイルを削除して快適な作業環境を維持します。", "저장 공간을 정리하고, 불필요한 파일을 제거하여 복잡성을 최소화하세요.",
            "Désencombrez votre espace de stockage et éliminez les fichiers superflus.", "Befreien Sie Ihren Speicher von unnötigem Datenmüll und sorgen Sie für Ordnung.", "Ordene su almacenamiento, elimine archivos innecesarios y reduzca el desorden.", "Fai ordine nel tuo spazio di archiviazione eliminando i file superflui.", "Organize seu armazenamento, remova arquivos desnecessários e elimine a desordem.")
        add(.moduleOrganizeSubtitle, "大文件、重复文件与下载项", "大檔案、重複檔案與下載項", "Large Files, Duplicates, and Downloads", "大容量ファイル、重複ファイル、ダウンロード項目", "대용량 파일, 중복 파일 및 다운로드",
            "Gros fichiers, doublons et téléchargements", "Große Dateien, Duplikate und Downloads", "Archivos grandes, duplicados y descargas", "Grandi file, duplicati e download", "Arquivos Grandes, Duplicatas e Downloads")
        add(.modulePerformance, "性能优化", "效能最佳化", "Optimize", "最適化", "최적화",
            "Optimiser", "Optimieren", "Optimizar", "Ottimizza", "Otimizar")
        add(.modulePerformanceAlt, "性能", "效能", "Performance", "パフォーマンス", "성능",
            "Performances", "Leistung", "Rendimiento", "Prestazioni", "Desempenho")
        add(.modulePerformanceDesc, "运行建议的维护任务，以优化您的 Mac 性能。", "運行建議的維護任務，以優化您的 Mac 性能。", "Run recommended maintenance tasks to optimize your Mac's performance.", "推奨されるメンテナンスタスクを実行して、Mac のパフォーマンスを最適化します。", "권장 유지보수 작업을 실행하여 Mac의 성능을 최적화하세요.",
            "Exécutez les tâches de maintenance recommandées pour optimiser les performances de votre Mac.", "Führen Sie empfohlene Wartungsaufgaben aus, um die Leistung Ihres Mac zu optimieren.", "Ejecute tareas de mantenimiento recomendadas para optimizar el rendimiento del Mac.", "Esegui attività di manutenzione consigliate per ottimizzare le prestazioni del Mac.", "Execute tarefas de manutenção recomendadas para otimizar o desempenho do Mac.")
        add(.modulePerformanceMaintenanceTasks, "系统维护任务", "系統維護任務", "System Maintenance Tasks", "システムメンテナンスタスク", "시스템 유지보수 작업",
            "Tâches de maintenance système", "Systemwartungsaufgaben", "Tareas de mantenimiento del sistema", "Attività di manutenzione del sistema", "Tarefas de manutenção do sistema")
        add(.modulePerformanceTitle, "启动项与系统维护", "啟動項與系統維護", "Startup Items & Maintenance", "スタートアップ項目と保守", "시작 프로그램 및 시스템 유지보수",
            "Éléments au démarrage et maintenance", "Startobjekte & Systemwartung", "Elementos de inicio y mantenimiento", "Elementi di avvio e manutenzione", "Itens de inicialização e manutenção")
        add(.moduleSmartCare, "智能扫描", "智慧掃描", "Smart Care", "スマートケア", "스마트 케어",
            "Analyse intelligente", "Smart Care", "Cuidado inteligente", "Smart Care", "Cuidado Inteligente")
        add(.moduleSmartCareAlt, "智能呵护", "智慧呵護", "Smart Care", "スマートケア", "스마트 케어",
            "Smart Care", "Smart Care", "Smart Care", "Smart Care", "Smart Care")
        add(.moduleSmartCareDesc, "作为开始，给 Mac 进行一次快速而全面的扫描吧。", "作為開始，給 Mac 進行一次快速而全面的掃描吧。", "To get started, run a quick and comprehensive scan of your Mac.", "まずは、お使いの Mac をすばやく包括的にスキャンしてみましょう。", "시작하기 위해 Mac의 빠르고 포괄적인 전체 스캔을 실행하세요.",
            "Pour commencer, lancez une analyse rapide et complète de votre Mac.", "Führen Sie zu Beginn einen schnellen und gründlichen Scan Ihres Mac durch.", "Para empezar, realice un análisis rápido y exhaustivo de su Mac.", "Per iniziare, esegui una scansione rapida e completa del tuo Mac.", "Para começar, faça uma verificação rápida e completa no seu Mac.")
        add(.moduleSmartCareSubtitle, "一键扫描与清理", "一鍵掃描與清理", "One-Click Scan & Clean", "ワンクリックスキャン＆クリーン", "원클릭 스캔 및 정리",
            "Analyse et nettoyage en un clic", "Ein-Klick-Scan & Bereinigung", "Análisis y limpieza en un clic", "Scansione e pulizia in un clic", "Verificação e Limpeza em Um Clique")
        add(.moduleSpaceLens, "空间透视", "空間透視", "Analyze", "ディスク分析", "디스크 분석",
            "Analyser", "Speicheranalyse", "Analizar", "Analizza spazio", "Analisar Espaço")
        add(.moduleSpaceLensAlt, "磁盘透视", "磁碟透視", "Space Lens", "スペースレンズ", "공간 렌즈",
            "Aperçu disque", "Speicher-Linse", "Lente de espacio", "Lente spazio", "Lente de Espaço")
        add(.moduleSpaceLensDesc, "直观地查看磁盘空间占用详情，快速清理存储。", "直觀地查看磁盤空間佔用詳情，快速清理存儲。", "Visually inspect disk space details and quickly reclaim storage.", "ディスク容量の占有状況を直感的に把握し、素早くストレージを解放します。", "디스크 공간 사용 내역을 직관적으로 확인하고 저장 공간을 빠르게 정리합니다.",
            "Visualisez les détails de l'espace disque et libérez rapidement du stockage.", "Speicherbelegung intuitiv analysieren und schnell Platz schaffen.", "Inspeccione visualmente el espacio de almacenamiento y libere memoria rápidamente.", "Visualizza i dettagli dello spazio su disco e libera rapidamente spazio.", "Inspecione visualmente o espaço em disco e libere armazenamento rapidamente.")
        add(.moduleSpaceLensSubtitle, "可视化磁盘占用", "可視化磁盤佔用", "Visual Storage Usage", "ストレージ使用量を視覚化", "시각적 디스크 사용량",
            "Visualisation du stockage", "Speicherbelegung visualisieren", "Visualización del almacenamiento", "Visualizzazione dello spazio", "Visualização do armazenamento")
        add(.moduleSpaceLensTitle, "空间透镜", "空間透鏡", "Space Lens", "スペースレンズ", "스페이스 렌즈",
            "Lentille d'espace", "Speicherlinse", "Lente espacial", "Lente dello spazio", "Lente de espaço")
        add(.moduleToolbox, "百宝箱", "百寶箱", "Toolbox", "ツールボックス", "도구 상자",
            "Boîte à outils", "Werkzeuge", "Herramientas", "Strumenti", "Caixa de Ferramentas")
        add(.moduleToolboxDesc, "专注于高效的快捷工具，轻点几下，即可完成 Mac 电脑的清理与系统维护。", "專注於高效的快捷工具，輕點幾下，即可完成 Mac 電腦的清理與系統維護。", "A focused set of powerful utilities to clean and maintain your Mac with just a few clicks.", "数回のクリックで Mac のクリーンアップと保守を完結できる、高効率なツール集です。", "몇 번의 클릭만으로 Mac의 정리 및 유지 관리를 손쉽게 완료할 수 있는 유용한 도구들입니다.",
            "Une suite d'outils efficaces pour nettoyer et entretenir votre Mac en quelques clics.", "Leistungsstarke Werkzeuge, um Ihren Mac mit wenigen Klicks zu bereinigen und zu warten.", "Un conjunto enfocado de utilidades para limpiar y mantener su Mac en pocos clics.", "Un insieme mirato di strumenti potenti per pulire e mantenere il tuo Mac con pochi clic.", "Um conjunto poderoso de utilitários para limpar e manter seu Mac com poucos cliques.")
        add(.moduleToolboxSubtitle, "快捷工具集合", "快捷工具集合", "Shortcut Utilities Collection", "便利なショートカットツール集", "바로가기 유틸리티 모음",
            "Collection d'outils rapides", "Sammlung praktischer Schnellwerkzeuge", "Colección de herramientas de acceso rápido", "Raccolta di strumenti rapidi", "Coleção de Ferramentas Rápidas")
        add(.moduleToolboxTitle, "我的工具", "我的工具", "My Tools", "マイツール", "내 도구",
            "Mes outils", "Meine Werkzeuge", "Mis herramientas", "I miei strumenti", "Minhas Ferramentas")
        add(.smartCleanHeroSubtitle, "清理应用缓存、系统与诊断日志、通讯媒体及开发冗余", "清理應用緩存、系統與診斷日誌、通訊媒體及開發冗餘", "Clean application caches, system logs, messaging media, and development artifacts", "アプリキャッシュ、システムログ、メッセージメディア、開発環境の不要データをクリーンアップ", "앱 캐시, 시스템 및 진단 로그, 메신저 미디어 및 개발 찌꺼기 정리",
            "Nettoyez les caches d'applications, journaux système, médias et résidus de développement", "Bereinigt App-Caches, Systemprotokolle, Messaging-Medien und Entwicklungsreste", "Limpie cachés de aplicaciones, registros del sistema, medios y restos de desarrollo", "Pulisci cache delle app, log di sistema, file multimediali e residui di sviluppo", "Limpe caches de aplicativos, logs do sistema, mídia de mensagens e resíduos de desenvolvimento")
        add(.monthly, "每月", "每月", "Monthly", "毎月", "매월",
            "Tous les mois", "Monatlich", "Mensualmente", "Ogni mese", "Mensalmente")
        add(.monthsAgo, "个月前", "個月前", "months ago", "か月前", "개월 전",
            "mois plus tôt", "Monate her", "meses atrás", "mesi fa", "meses atrás")
        add(.moveToArchiveFolder, "移动至归档目录", "移動至歸檔目錄", "Move to Archive Folder", "アーカイブフォルダへ移動", "보관 디렉토리로 이동",
            "Déplacer vers le dossier d’archive", "In Archivordner verschieben", "Mover a carpeta de archivo", "Sposta nella cartella archivio", "Mover para Pasta de Arquivo")
        add(.nativeMacosLaunchdBackgroundScheduler, "macOS launchd 原生后台调度", "macOS launchd 原生後台調度", "Native macOS launchd background scheduler", "macOS launchd ネイティブバックグラウンドスケジューラ", "macOS launchd 기본 백그라운드 스케줄러",
            "Planificateur d’arrière-plan natif launchd de macOS", "Nativer macOS launchd-Hintergrund-Scheduler", "Programador nativo de segundo plano launchd de macOS", "Pianificatore nativo in background launchd di macOS", "Agendador nativo em segundo plano launchd do macOS")
        add(.needsAdminPermission, "需要管理员授权", "需要管理員授權", "Requires Administrator Privileges", "管理者権限が必要です", "관리자 권한 필요",
            "Autorisation administrateur requise", "Administratorrechte erforderlich", "Requiere privilegios de administrador", "Richiede autorizzazione amministratore", "Requer privilégios de administrador")
        add(.needsConfirmationTag, "需要确认", "需要確認", "Needs Confirmation", "確認が必要", "확인 필요",
            "Confirmation requise", "Bestätigung erforderlich", "Requiere confirmación", "Richiede conferma", "Requer confirmação")
        add(.network, "网络", "網路", "Network", "ネットワーク", "네트워크",
            "Réseau", "Netzwerk", "Red", "Rete", "Rede")
        add(.networkInterfacesAndPublicIpDiagnostics, "网络接口与公网 IP 诊断", "網絡接口與公網 IP 診斷", "Network Interface & Public IP Diagnostics", "ネットワークインターフェースとパブリック IP の診断", "네트워크 인터페이스 및 공인 IP 진단",
            "Diagnostic d'interface réseau et IP publique", "Netzwerkschnittstellen- und Public-IP-Diagnose", "Diagnóstico de interfaz de red e IP pública", "Diagnostica interfaccia di rete e IP pubblico", "Diagnóstico de interface de rede e IP público")
        add(.networkLatency, "网络延迟", "網路延遲", "Network Latency", "ネットワーク遅延", "네트워크 지연 시간",
            "Latence réseau", "Netzlatenz", "Latencia de red", "Latenza di rete", "Latência de Rede")
        add(.networkRequestCacheHstsPoliciesAndSessionCookieStorage, "网络请求缓存、HSTS 策略与会话 Cookie 存储", "網路請求快取、HSTS 策略與工作階段 Cookie 儲存", "Network request cache, HSTS policies, and session cookie storage", "通信キャッシュ、HSTSポリシー、セッションCookieストレージ", "네트워크 요청 캐시, HSTS 정책 및 세션 쿠키 저장소",
            "Cache réseau, politiques HSTS et cookies de session", "Netzwerk-Cache, HSTS-Richtlinien und Sitzungs-Cookies", "Caché de red, políticas HSTS y almacenamiento de cookies", "Cache di rete, criteri HSTS e cookie di sessione", "Cache de rede, políticas HSTS e cookies de sessão")
        add(.networkRequestSessionCachesAndLocalCookieDatabases, "网络请求会话缓存与本地 Cookie 数据库", "網路請求會話快取與本地 Cookie 資料庫", "Network request session caches and local Cookie databases", "ネットワークセッションキャッシュおよびローカル Cookie データベース", "네트워크 세션 캐시 및 로컬 쿠키 데이터베이스",
            "Caches de session de requêtes réseau et bases de données locales de cookies", "Netzwerkanfrage-Sitzungscaches und lokale Cookie-Datenbanken", "Cachés de sesión de red y bases de datos locales de cookies", "Cache di sessione delle richieste di rete e database locali dei cookie", "Caches de sessão de requisições de rede e bancos de dados locais de cookies")
        add(.networkThroughputDiagnostics, "网络吞吐与连接诊断", "網路吞吐與連線診斷", "Network Throughput & Diagnostics", "ネットワーク速度と診断", "네트워크 처리량 및 진단",
            "Débit réseau et diagnostic", "Netzwerkdurchsatz & Diagnose", "Rendimiento y diagnóstico de red", "Velocità e diagnostica di rete", "Taxa de Rede e Diagnóstico")
        add(.neverOpened, "从未打开", "從未打開", "Never Opened", "一度も開かれていません", "한 번도 열지 않음",
            "Jamais ouvert", "Nie geöffnet", "Nunca abierto", "Mai aperto", "Nunca Aberto")
        add(.neverRun, "从未执行", "從未執行", "Never Run", "実行履歴なし", "실행한 적 없음",
            "Jamais exécuté", "Noch nie ausgeführt", "Nunca ejecutado", "Mai eseguito", "Nunca Executado")
        add(.noAdminNeeded, "无需授权", "無需授權", "No Admin Needed", "権限不要", "권한 불필요",
            "Sans admin", "Ohne Admin", "Sin admin", "Senza admin", "Sem Admin")
        add(.noAppUpdatesNeeded, "无需更新", "無需更新", "Up to Date", "最新の状態です", "최신 상태입니다",
            "À jour", "Auf dem neuesten Stand", "Actualizado", "Aggiornato", "Atualizado")
        add(.noApplicationsFoundOnMac, "在这台 Mac 电脑上找不到任何应用程序。", "在這台 Mac 電腦上找不到任何應用程式。", "No applications found on this Mac.", "この Mac でアプリケーションが見つかりませんでした。", "이 Mac에서 응용 프로그램을 찾을 수 없습니다.",
            "Aucune application trouvée sur ce Mac.", "Keine Anwendungen auf diesem Mac gefunden.", "No se encontraron aplicaciones en este Mac.", "Nessuna applicazione trovata su questo Mac.", "Nenhum aplicativo encontrado neste Mac.")
        add(.noApplicationsToManage, "没有需要管理的应用程序。", "沒有需要管理的應用程式。", "No applications to manage.", "管理するアプリケーションはありません。", "관리할 응용 프로그램이 없습니다.",
            "Aucune application à gérer.", "Keine Anwendungen zu verwalten.", "No hay aplicaciones para administrar.", "Nessuna applicazione da gestire.", "Nenhum aplicativo para gerenciar.")
        add(.noAppsFoundOnMac, "在这台 Mac 电脑上找不到任何应用程序。", "在這台 Mac 電腦上找不到任何應用程式。", "No applications found on this Mac.", "この Mac 上でアプリケーションが見つかりませんでした。", "이 Mac에서 애플리케이션을 찾을 수 없습니다.",
            "Aucune application trouvée sur ce Mac.", "Keine Anwendungen auf diesem Mac gefunden.", "No se encontraron aplicaciones en este Mac.", "Nessuna applicazione trovata su questo Mac.", "Nenhum aplicativo encontrado neste Mac.")
        add(.noAppsInstalledOnMac, "您的 Mac 电脑中未安装有应用程序。", "您的 Mac 電腦中未安裝有應用程式。", "There are no installed applications on your Mac.", "お使いの Mac にインストールされているアプリはありません。", "Mac에 설치된 애플리케이션이 없습니다.",
            "Aucune application n'est installée sur votre Mac.", "Es sind keine Anwendungen auf Ihrem Mac installiert.", "No hay aplicaciones instaladas en su Mac.", "Nessuna applicazione installata sul tuo Mac.", "Não há aplicativos instalados no seu Mac.")
        add(.noAppsInstalledPrompt, "您的 Mac 电脑中未安装有应用程序。", "您的 Mac 電腦中未安裝有應用程序。", "No applications are installed on your Mac.", "Mac にアプリケーションがインストールされていません。", "Mac에 설치된 애플리케이션이 없습니다.",
            "Aucune application installée sur votre Mac.", "Auf Ihrem Mac sind keine Anwendungen installiert.", "No hay aplicaciones instaladas en su Mac.", "Nessuna applicazione installata sul Mac.", "Nenhum aplicativo instalado no seu Mac.")
        add(.noBackgroundServicesDetected, "未检测到后台服务", "未偵測到背景服務", "No Background Services Detected", "バックグラウンドサービスは検出されませんでした", "백그라운드 서비스가 감지되지 않았습니다",
            "Aucun service d’arrière-plan détecté", "Keine Hintergrunddienste erkannt", "No se detectaron servicios en segundo plano", "Nessun servizio in background rilevato", "Nenhum serviço em segundo plano detectado")
        add(.noCleanableItemsDiscovered, "未发现可清理项目", "未發現可清理項目", "No cleanable items discovered", "クリーンアップ可能な項目は見つかりませんでした", "정리 가능한 항목이 발견되지 않았습니다",
            "Aucun élément à nettoyer détecté", "Keine bereinigbaren Objekte gefunden", "No se encontraron elementos para limpiar", "Nessun elemento da pulire trovato", "Nenhum item limpável encontrado")
        add(.noCleanupNeededNow, "当前无需清理", "目前無需清理", "No cleanup needed now", "現在クリーンアップの必要はありません", "현재 정리가 필요하지 않습니다",
            "Aucun nettoyage nécessaire actuellement", "Derzeit keine Bereinigung erforderlich", "No se necesita limpieza ahora", "Nessuna pulizia necessaria al momento", "Nenhuma limpeza necessária agora")
        add(.noClutterDiscoveredPrompt, "没有发现任何杂乱项目。", "沒有發現任何雜亂項目。", "No clutter found.", "不要な項目は見つかりませんでした。", "정리할 항목이 발견되지 않았습니다.",
            "Aucun encombrement détecté.", "Kein Datenmüll gefunden.", "No se encontraron elementos de desorden.", "Nessun elemento superfluo rilevato.", "Nenhum arquivo desnecessário encontrado.")
        add(.noClutterFoundPrompt, "没有发现任何杂乱项目。", "沒有發現任何雜亂項目。", "No clutter items found.", "不要な項目は見つかりませんでした。", "정리할 불필요 항목이 발견되지 않았습니다.",
            "Aucun élément encombrant trouvé.", "Keine überflüssigen Objekte gefunden.", "No se encontraron elementos desordenados.", "Nessun elemento disordinato trovato.", "Nenhum item desnecessário encontrado.")
        add(.noExternalVolumesMounted, "当前未挂载外置移动硬盘或镜像卷", "目前未掛載外接行動硬碟或映像卷", "No external drives or disk images mounted", "外付けドライブやイメージは接続されていません", "연결된 외장 드라이브 또는 디스크 이미지가 없습니다",
            "Aucun lecteur externe ou image disque connecté", "Keine externen Laufwerke oder Images verbunden", "No hay unidades externas o imágenes montadas", "Nessuna unità esterna o immagine montata", "Nenhum disco externo ou imagem montada")
        add(.noItemsFoundToCleanOrOptimize, "没有发现需要处理的项目。", "沒有發現需要處理的項目。", "No items found to clean or optimize.", "処理が必要な項目は見つかりませんでした。", "처리할 항목이 발견되지 않았습니다.",
            "Aucun élément à traiter n’a été trouvé.", "Keine zu bereinigenden Elemente gefunden.", "No se encontraron elementos que procesar.", "Nessun elemento da elaborare trovato.", "Nenhum item a ser processado foi encontrado.")
        add(.noItemsNeedOptimization, "未发现需要优化的项目。", "未發現需要最佳化的項目。", "No items need optimization.", "最適化が必要な項目は見つかりませんでした。", "최적화가 필요한 항목이 없습니다.",
            "Aucun élément à optimiser trouvé.", "Keine zu optimierenden Objekte gefunden.", "No se encontraron elementos para optimizar.", "Nessun elemento da ottimizzare trovato.", "Nenhum item precisa de otimização.")
        add(.noItemsNeedingAttentionInAreaPrompt, "该区域没有需要清理或修复的项目。", "該區域沒有需要清理或修複的項目。", "No items in this area require cleaning or repair.", "このエリアにはクリーンアップや修復が必要な項目はありません。", "이 영역에는 정리하거나 복구할 항목이 없습니다.",
            "Aucun élément de cette zone ne nécessite de nettoyage.", "In diesem Bereich sind keine Bereinigungen erforderlich.", "No hay elementos en esta área que requieran limpieza o reparación.", "Nessun elemento in quest'area richiede pulizia o riparazione.", "Nenhum item nesta área requer limpeza ou reparo.")
        add(.noItemsRequiringCleanupWereFoundOnYourSystem, "您的系统中没有任何需要清理的项目。", "您的系統中沒有任何需要清理的項目。", "No items requiring cleanup were found on your system.", "クリーンアップが必要な項目は見つかりませんでした。", "시스템에 정리할 항목이 없습니다.",
            "Votre système ne contient aucun élément à nettoyer.", "Auf Ihrem System wurden keine zu bereinigenden Elemente gefunden.", "No se encontraron elementos para limpiar en el sistema.", "Non ci sono elementi da pulire sul tuo sistema.", "Nenhum item que precise de limpeza foi encontrado.")
        add(.noItemsToCleanInCategoryPrompt, "该分类下暂无需要清理的项目", "該分類下暫無需要清理的項目", "No items requiring cleanup in this category", "このカテゴリにクリーンアップが必要な項目はありません", "이 범주에는 정리할 항목이 없습니다",
            "Aucun élément à nettoyer dans cette catégorie", "In dieser Kategorie gibt es keine zu bereinigenden Objekte", "No hay elementos para limpiar en esta categoría", "Nessun elemento da pulire in questa categoria", "Nenhum item para limpar nesta categoria")
        add(.noLeftoverFilesFound, "未发现残留文件", "未發現殘留檔案", "No Leftover Files Found", "残りファイルはありません", "잔여 파일 없음",
            "Aucun fichier résiduel", "Keine Restdateien gefunden", "No se encontraron restos", "Nessun file residuo trovato", "Nenhum resíduo encontrado")
        add(.noLeftoverFilesSelected, "尚未选择任何残留文件", "尚未選擇任何殘留文件", "No leftover items selected", "残留ファイルが選択されていません", "선택된 잔여 파일이 없습니다",
            "Aucun fichier résiduel sélectionné", "Keine verbleibenden Restdateien ausgewählt", "No se ha seleccionado ningún archivo residual", "Nessun file residuo selezionato", "Nenhum arquivo residual selecionado")
        add(.noLeftoversDetectedSubtitle, "您的应用残留目录非常干净", "您的應用殘留目錄非常乾淨", "Your leftover folders are completely clean", "アプリ残骸ディレクトリはとてもクリーンです", "앱 잔여물 디렉토리가 매우 깨끗합니다",
            "Vos répertoires de résidus d’apps sont impeccables", "Ihre Restdateien-Verzeichnisse sind absolut sauber", "Las carpetas de residuos están completamente limpias", "Le cartelle dei residui sono perfettamente pulite", "Suas pastas de arquivos residuais estão limpas")
        add(.noLeftoversDetectedTitle, "未检测到已卸载应用的遗留数据", "未檢測到已卸載應用的遺留資料", "No uninstalled app leftovers detected", "削除済みアプリの残骸は検出されませんでした", "제거된 응용 프로그램의 잔여 데이터가 감지되지 않았습니다",
            "Aucun résidu d’application désinstallée détecté", "Keine Reste deinstallierter Programme gefunden", "No se detectaron restos de apps desinstaladas", "Nessun residuo di app disinstallate rilevato", "Nenhum resíduo de aplicativo desinstalado detectado")
        add(.noPermissionNeeded, "无需授权", "無需授權", "No Authorization Needed", "権限不要", "권한 불필요",
            "Aucune autorisation requise", "Keine Berechtigung erforderlich", "No requiere autorización", "Nessuna autorizzazione richiesta", "Sem autorização necessária")
        add(.noRecommendedOptimizationTasks, "没有推荐的优化任务。", "沒有推薦的最佳化任務。", "No recommended optimization tasks.", "推奨される最適化タスクはありません。", "권장되는 최적화 작업이 없습니다.",
            "Aucune tâche d'optimisation recommandée.", "Keine empfohlenen Optimierungsaufgaben.", "No hay tareas de optimización recomendadas.", "Nessuna attività di ottimizzazione consigliata.", "Nenhuma tarefa de otimização recomendada.")
        add(.noRedundantCacheFilesFoundToClean, "没有发现需要清理的冗余缓存文件", "沒有發現需要清理的冗餘快取檔案", "No redundant cache files found to clean", "削除が必要なキャッシュファイルは見つかりませんでした", "정리할 불필요한 캐시 파일이 없습니다",
            "Aucun fichier cache inutile trouvé", "Keine überflüssigen Cache-Dateien gefunden", "No se encontraron archivos en caché innecesarios", "Nessun file cache superfluo trovato", "Nenhum arquivo de cache desnecessário encontrado")
        add(.noRelevantToolsFound, "未找到相关的工具。", "未找到相關的工具。", "No matching tools found.", "該当するツールが見つかりませんでした。", "일치하는 도구를 찾을 수 없습니다.",
            "Aucun outil correspondant trouvé.", "Keine passenden Werkzeuge gefunden.", "No se encontraron herramientas coincidentes.", "Nessuno strumento corrispondente trovato.", "Nenhuma ferramenta correspondente encontrada.")
        add(.noScanCardsSelected, "所有卡片都未勾选", "所有卡片都未勾選", "No scan cards selected", "スキャンカードが選択されていません", "선택된 검사 카드가 없습니다",
            "Aucune carte d'analyse sélectionnée", "Keine Scankarten ausgewählt", "No se ha seleccionado ninguna tarjeta de escaneo", "Nessuna scheda di scansione selezionata", "Nenhum cartão de verificação selecionado")
        add(.noStartupItemsDetected, "未检测到开机启动项", "未偵測到開機啟動項", "No Startup Items Detected", "ログイン項目は検出されませんでした", "시작 프로그램이 감지되지 않았습니다",
            "Aucun élément d’ouverture détecté", "Keine Startobjekte erkannt", "No se detectaron ítems de inicio", "Nessun elemento di avvio rilevato", "Nenhum item de inicialização detectado")
        add(.noUnsupportedAppsFound, "无不支持应用", "無不支援應用", "No Unsupported Apps Found", "非対応アプリはありません", "지원되지 않는 앱 없음",
            "Aucune application incompatible", "Keine inkompatiblen Apps", "Sin aplicaciones incompatibles", "Nessuna app non compatibile", "Nenhum app incompatível")
        add(.noUnusedAppsFound, "未发现闲置应用", "未發現閒置應用", "No Unused Apps Found", "未使用アプリはありません", "사용하지 않는 앱 없음",
            "Aucune application inutilisée", "Keine ungenutzten Apps gefunden", "No se encontraron apps sin usar", "Nessuna app inutilizzata trovata", "Nenhum app não utilizado")
        add(.noUpdatesNeeded, "未检测到更新通道", "未偵測到更新通道", "No Update Channels Detected", "アップデートチャネル未検出", "업데이트 채널이 감지되지 않음",
            "Aucun canal de mise à jour détecté", "Keine Update-Kanäle erkannt", "No se detectaron canales de actualización", "Nessun canale di aggiornamento rilevato", "Nenhum canal de atualização detectado")
        add(.notConfigured, "未设定", "未設定", "Not Configured", "未設定", "설정 안 됨",
            "Non configuré", "Nicht konfiguriert", "No configurado", "Non configurato", "Não configurado")
        add(.notEnoughContentToVisualize, "存储空间没有太多内容，无法可视化...", "儲存空間沒有太多內容，無法視覺化...", "Not enough content to visualize...", "可視化するコンテンツが十分にありません...", "시각화할 콘텐츠가 충분하지 않습니다...",
            "Pas assez de contenu à visualiser...", "Nicht genügend Inhalte zur Visualisierung...", "No hay suficiente contenido para visualizar...", "Contenuti insufficienti da visualizzare...", "Não há conteúdo suficiente para visualizar...")
        add(.notInUse, "未使用", "未使用", "Not in Use", "未使用", "사용 안 함",
            "Inutilisé", "Nicht in Verwendung", "Sin usar", "Non in uso", "Não Utilizado")
        add(.notScheduled, "未排期", "未排期", "Not Scheduled", "スケジュール未設定", "예정된 작업 없음",
            "Non programmé", "Nicht geplant", "No programado", "Non programmato", "Não Agendado")
        add(.noteDuplicateCopy, "重复副本", "重複副本", "Duplicate Copy", "重複コピー", "중복 사본",
            "Copie en double", "Duplikat-Kopie", "Copia duplicada", "Copia duplicata", "Cópia duplicada")
        add(.noteEarliestOriginalKeep, "最早的一份原始文件，强制保留", "最早的一份原始檔案，強制保留", "Earliest original copy, kept by default", "最古のオリジナルファイル、既定で保持", "가장 오래된 원본 파일, 기본 보존",
            "Copie originale la plus ancienne, conservée par défaut", "Älteste Originalkopie, standardmäßig behalten", "Copia original más antigua, conservada de forma predeterminada", "Copia originale più vecchia, conservata per impostazione predefinita", "Cópia original mais antiga, mantida por padrão")
        add(.noteNewestBackupKeep, "最新备份，默认保留", "最新備份，預設保留", "Newest backup, kept by default", "最新バックアップ、既定で保持", "최신 백업, 기본 보존",
            "Sauvegarde la plus récente, conservée par défaut", "Neuestes Backup, standardmäßig behalten", "Copia de seguridad más reciente, conservada de forma predeterminada", "Backup più recente, conservato per impostazione predefinita", "Backup mais recente, mantido por padrão")
        add(.nothingToCleanPleaseScanFirst, "没有可处理的项目，请先扫描", "沒有可處理的項目，請先掃描", "Nothing to clean, please scan first", "処理対象がありません。先にスキャンを実行してください", "처리할 항목이 없습니다. 먼저 검사를 실행하세요",
            "Rien à nettoyer, veuillez d'abord analyser", "Nichts zu bereinigen, bitte zuerst scannen", "Nada que limpiar, escanee primero", "Nessun elemento da pulire, eseguire prima la scansione", "Nada para limpar, execute a verificação primeiro")
        add(.nothingToCleanRightNowTitle, "当前没有可清理的缓存", "目前沒有可清理的快取", "Nothing to Clean Right Now", "現在クリーンアップできる項目はありません", "현재 정리할 캐시가 없습니다",
            "Rien à nettoyer pour le moment", "Derzeit nichts zu bereinigen", "Nada que limpiar ahora", "Nulla da pulire al momento", "Nada para limpar agora")
    }

    static func populateBatch9(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.notificationCenter, "通知中心", "通知中心", "Notification Center", "通知センター", "알림 센터",
            "Centre de notifications", "Mitteilungszentrale", "Centro de notificaciones", "Centro Notifiche", "Central de Notificações")
        add(.notificationCenterLagFix, "通知中心无响应修复", "通知中心無響應修復", "Fix Notification Center Freezes", "通知センターの応答停止を修復", "알림 센터 무응답 해결",
            "Réparer le centre de notifications bloqué", "Mitteilungszentrale-Blockaden beheben", "Corregir bloqueo del centro de notificaciones", "Risolvi blocco del Centro Notifiche", "Corrigir Travamento da Central de Notificações")
        add(.ofWhichDataFiles, "其中数据文件", "其中資料檔案", "of which data files", "内データファイル", "그 중 데이터 파일",
            "dont fichiers de données", "davon Datendateien", "de los cuales archivos de datos", "di cui file di dati", "dos quais arquivos de dados")
        add(.oldArchivesDocumentsAndTemporaryDownloadsInDownloadsFolder, "「下载」目录中的历史归档、文档与临时下载文件", "「下載」目錄中的歷史歸檔、文檔與暫存下載檔案", "Old archives, documents, and temporary downloads in Downloads folder", "「ダウンロード」フォルダ内の古いアーカイブ、文書、一時ファイル", "‘다운로드’ 폴더의 이전 압축파일, 문서 및 임시 다운로드 파일",
            "Archives, documents et téléchargements temporaires dans le dossier Téléchargements", "Alte Archive, Dokumente und temporäre Dateien im Download-Ordner", "Archivos antiguos, documentos y descargas temporales en Descargas", "Vecchi archivi, documenti e download temporanei nella cartella Download", "Arquivos antigos, documentos e downloads temporários na pasta Downloads")
        add(.oneClickScanAndClean, "一键扫描与清理", "一鍵掃描與清理", "One-Click Scan & Clean", "ワンクリックスキャン＆クリーン", "원클릭 스캔 및 정리",
            "Analyser et nettoyer en un clic", "Ein-Klick-Scan & Bereinigung", "Escanear y limpiar en un clic", "Scansiona e pulisci con un clic", "Escanear e Limpar em Um Clique")
        add(.oneScanCoversAllBenefitsDesc, "一次扫描覆盖清理、防护与性能", "一次掃描涵蓋清理、防護與效能", "One scan covers cleanup, protection, and performance", "1回のスキャンでクリーンアップ、保護、性能を網羅", "한 번의 스캔으로 정리, 보호 및 성능 최적화 완료",
            "Une seule analyse couvre le nettoyage, la protection et les performances", "Ein Scan deckt Bereinigung, Schutz und Leistung ab", "Un solo escaneo cubre limpieza, protección y rendimiento", "Una sola scansione copre pulizia, protezione e prestazioni", "Uma verificação cobre limpeza, proteção e desempenho")
        add(.openLayoutEditorWindow, "打开独立排版编辑器窗口…", "開啟獨立排版編輯器視窗…", "Open Layout Editor Window…", "レイアウト編集ウィンドウを開く…", "독립 레이아웃 편집기 열기…",
            "Ouvrir l’éditeur de disposition…", "Layout-Editor-Fenster öffnen…", "Abrir editor de diseño…", "Apri finestra editor layout…", "Abrir Janela do Editor de Layout…")
        add(.optimizeNow, "一键优化", "一鍵最佳化", "Optimize Now", "今すぐ最適化", "지금 최적화",
            "Optimiser maintenant", "Jetzt optimieren", "Optimizar ahora", "Ottimizza ora", "Otimizar Agora")
        add(.orphanedDataLeftOnDiskByAlreadyUninstalledApplications, "已删除 App 留在磁盘上的数据", "已刪除 App 留在磁碟上的資料", "Orphaned data left on disk by already uninstalled applications", "削除済み App がディスクに残したデータ", "이미 삭제된 앱이 디스크에 남긴 데이터",
            "Données laissées sur le disque par des apps supprimées", "Auf der Festplatte verbliebene Daten gelöschter Apps", "Datos dejados en el disco por aplicaciones ya eliminadas", "Dati rimasti sul disco da app già eliminate", "Dados deixados no disco por apps já removidos")
        add(.orphanedFileCleanup, "孤立遗留文件清理", "孤立遺留檔案清理", "Orphaned File Cleanup", "孤立ファイルのクリーンアップ", "고립된 잔여 파일 정리",
            "Nettoyage des fichiers orphelins", "Verwaiste Dateien bereinigen", "Limpieza de archivos huérfanos", "Pulizia dei file orfani", "Limpeza de Arquivos Órfãos")
        add(.orphanedResidualItemsCountSuffix, "个孤立残留项", "個孤立殘留項", " orphaned items", " 個の孤立残留項目", "개의 고립된 잔여 항목",
            " éléments orphelins résiduels", " verwaiste Restelemente", " elementos residuales huérfanos", " elementi residui orfani", " itens residuais órfãos")
        add(.other, "其他", "其他", "Other", "その他", "기타",
            "Autre", "Andere", "Otro", "Altro", "Outro")
        add(.otherFilesDirect, "其他文件", "其他檔案", "Other Files", "その他のファイル", "기타 파일",
            "Autres fichiers", "Andere Dateien", "Otros archivos", "Altri file", "Outros arquivos")
        add(.pCoreAvgLoadPrefix, "性能核均载", "效能核均載", "P-Core Avg Load", "Pコア平均負荷", "P코어 평균 부하",
            "Charge moy. cœurs P", "P-Kern Durchschn. Last", "Carga media núcleos P", "Carico medio core P", "Carga média núcleos P")
        add(.pCoreLoad, "性能核 (P-Cores) 负载", "效能核心 (P-Cores) 負載", "Performance Cores (P-Cores)", "高効率コア (Pコア) 負荷", "성능 코어 (P-Cores) 부하",
            "Cœurs hautes performances (P)", "Leistungskerne (P-Kerne)", "Núcleos de rendimiento (P)", "Core ad alte prestazioni (P)", "Núcleos de Desempenho (P)")
        add(.packageAndBuildCaches, "包管理器与构建缓存", "套件管理與建置快取", "Package & Build Caches", "パッケージ・ビルドキャッシュ", "패키지 및 빌드 캐시",
            "Caches de paquets et builds", "Paket- & Build-Caches", "Caché de paquetes y compilación", "Cache pacchetti e build", "Caches de Pacotes e Build")
        add(.particleEtc, "等", "等", "etc.", "など", "등",
            "etc.", "usw.", "etc.", "ecc.", "etc.")
        add(.particleOf, "的", "的", "of", "の", "의",
            "de", "von", "de", "di", "de")
        add(.peakLoadPrefix, "峰值负载", "峰值負載", "Peak Load", "ピーク負荷", "최대 부하",
            "Charge de crête", "Spitzenlast", "Carga máxima", "Carico di picco", "Carga máxima")
        add(.peakPrefix, "峰值", "峰值", "Peak", "ピーク", "최대",
            "Pic", "Spitze", "Pico", "Picco", "Pico")
        add(.peakReadRate, "区间峰值读取", "區間峰值讀取", "Peak Read Rate", "ピーク読込速度", "최대 읽기 속도",
            "Pic de lecture", "Spitzen-Leserate", "Pico de lectura", "Picco di lettura", "Pico de Leitura")
        add(.perfActionStartDiagnosis, "开始性能体检", "開始性能體檢", "Start Performance Diagnosis", "パフォーマンス診断を開始", "성능 진단 시작",
            "Démarrer le diagnostic de performance", "Leistungsdiagnose starten", "Iniciar diagnóstico de rendimiento", "Avvia diagnosi prestazioni", "Iniciar Diagnóstico de Desempenho")
        add(.perfDiagnosingSubtitle, "性能体检中", "性能體檢中", "Diagnosing Performance", "パフォーマンス診断中", "성능 진단 중",
            "Diagnostic de performance en cours", "Leistungsdiagnose läuft", "Diagnóstico de rendimiento en curso", "Diagnosi prestazioni in corso", "Diagnóstico de Desempenho em Andamento")
        add(.perfDirectManageLink, "直接管理维护任务与启动项 ›", "直接管理維護任務與啟動項 ›", "Manage maintenance tasks & startup items directly ›", "メンテナンス項目と起動項目を直接管理 ›", "유지보수 작업 및 시작 프로그램 직접 관리 ›",
            "Gérer directement les tâches et éléments au démarrage ›", "Wartungsaufgaben & Autostart direkt verwalten ›", "Gestionar tareas y elementos de inicio directamente ›", "Gestisci direttamente attività di manutenzione ed elementi di avvio ›", "Gerenciar tarefas de manutenção e inicialização diretamente ›")
        add(.perfHeroSubtitle, "加速系统响应、优化开机启动项、清理数据库碎片与运行系统维护", "加速系統響應、最佳化開機啟動項、清理資料庫碎片與執行系統維護", "Speed up responsiveness, optimize startup items, compact databases, and run maintenance", "動作を高速化し、起動項目を最適化、データベースの断片化を解消してメンテナンスを実行", "시스템 응답을 가속하고 시작 프로그램을 최적화하며 데이터베이스 파편화 정리 및 유지보수 실행",
            "Accélérez la réactivité, optimisez le démarrage, réduisez les bases et lancez la maintenance", "Reaktionszeit beschleunigen, Autostart optimieren, Datenbanken komprimieren und Wartung ausführen", "Acelera la respuesta, optimiza el inicio, compacta bases de datos y ejecuta mantenimiento", "Velocizza la reattività, ottimizza l’avvio, compatta i database ed esegui la manutenzione", "Acelere a resposta, otimize a inicialização, compacte bancos de dados e execute manutenção")
        add(.perfHeroTitle, "深度优化你的 Mac 性能", "深度最佳化你的 Mac 性能", "Optimize Your Mac’s Performance", "Mac のパフォーマンスを徹底最適化", "Mac의 성능을 깊이 있게 최적화",
            "Optimisez les performances de votre Mac", "Optimieren Sie die Leistung Ihres Mac", "Optimiza el rendimiento de tu Mac", "Ottimizza le prestazioni del tuo Mac", "Otimize o Desempenho do Seu Mac")
        add(.perfLaunchSpeed, "启动加速", "啟動加速", "Launch Speed", "起動の高速化", "시작 속도 향상",
            "Accélération du démarrage", "Startbeschleunigung", "Aceleración de inicio", " Velocità di avvio", "Aceleração de inicialização")
        add(.perfNetworkAndSearch, "网络与搜索", "網路與搜尋", "Network & Search", "ネットワークと検索", "네트워크 및 검색",
            "Réseau et recherche", "Netzwerk & Suche", "Red y búsqueda", "Rete e ricerca", "Rede e busca")
        add(.perfSafetyNote, "安全保障：系统级无损脚本维护，不修改个人数据，全面兼容 macOS", "安全保障：系統級無損腳本維護，不修改個人資料，全面兼容 macOS", "Safe: Non-destructive system maintenance without modifying personal files, 100% compatible with macOS", "安心の安全性：個人データを改変しない無害なシステム保守、macOS に完全対応", "안전 보장: 개인 데이터를 변경하지 않는 무손실 시스템 스크립트, macOS 완벽 호환",
            "Sécurité : maintenance système non destructive sans toucher aux données personnelles, compatible macOS", "Sicher: Zerstörungsfreie Systemwartung ohne Berührung persönlicher Daten, voll macOS-kompatibel", "Seguridad: mantenimiento no destructivo que no toca archivos personales, compatible con macOS", "Sicuro: manutenzione di sistema non distruttiva senza toccare i dati personali, compatibile con macOS", "Seguro: manutenção do sistema não destrutiva sem alterar arquivos pessoais, compatível com macOS")
        add(.perfScanningMaintenanceTasks, "正在检测系统维护项…", "正在檢測系統維護項…", "Checking system maintenance tasks…", "システムメンテナンス項目を確認中…", "시스템 유지보수 항목 점검 중…",
            "Vérification des tâches de maintenance système…", "Systemwartungsaufgaben werden überprüft…", "Comprobando tareas de mantenimiento del sistema…", "Controllo attività di manutenzione del sistema…", "Verificando tarefas de manutenção do sistema…")
        add(.perfScanningStartupServices, "正在检索开机启动项与系统服务状态…", "正在檢索開機啟動項與系統服務狀態…", "Checking status of startup items and daemons…", "起動項目とシステムサービスの状態を取得中…", "시작 프로그램 및 시스템 서비스 상태 조회 중…",
            "Recherche du statut des éléments de démarrage et services système…", "Überprüfe Status von Autostart-Einträgen und Diensten…", "Comprobando estado de elementos de inicio y servicios del sistema…", "Recupero stato elementi di avvio e servizi di sistema…", "Verificando status de itens de inicialização e serviços do sistema…")
        add(.perfSystemDatabases, "快照与存储", "快照與儲存", "Snapshots & Storage", "スナップショットと容量", "스냅샷 및 저장 공간",
            "Instantanés et stockage", "Schnappschüsse & Speicher", "Instantáneas y almacenamiento", "Istantanee e archiviazione", "Instantâneos e Armazenamento")
        add(.perfSystemMaintenance, "系统维护", "系統維護", "System Maintenance", "システムメンテナンス", "시스템 유지보수",
            "Maintenance système", "Systemwartung", "Mantenimiento del sistema", "Manutenzione di sistema", "Manutenção do sistema")
        add(.perfTagDnsSpotlight, "DNS & 聚焦重构", "DNS & 聚焦重構", "DNS & Spotlight Rebuild", "DNS と Spotlight 再構築", "DNS 및 Spotlight 재구축",
            "Reconstruction DNS et Spotlight", "DNS- & Spotlight-Neuaufbau", "Reconstrucción de DNS y Spotlight", "Ricostruzione DNS e Spotlight", "Reconstrução de DNS e Spotlight")
        add(.perfTagSpaceReclaimScripts, "可清除空间回收", "可清除空間回收", "Purgeable Space Reclaim", "パージ可能領域の解放", "제거 가능 공간 회수",
            "Récupération d’espace purgeable", "Freigebbaren Speicherplatz zurückgewinnen", "Recuperación de espacio purgable", "Recupero spazio eliminabile", "Recuperação de Espaço Purgável")
        add(.perfTagSqliteCompact, "时间机器快照精简", "時光機快照精簡", "Thin Time Machine Snapshots", "Time Machine スナップショット整理", "Time Machine 스냅샷 정리",
            "Alléger les instantanés Time Machine", "Time Machine-Schnappschüsse ausdünnen", "Reducir instantáneas de Time Machine", "Riduci istantanee di Time Machine", "Reduzir Instantâneos do Time Machine")
        add(.perfTagStartupPermissions, "缓存与访达优化", "快取與 Finder 最佳化", "QuickLook & Finder Optimization", "QuickLook と Finder 最適化", "QuickLook 및 Finder 최적화",
            "Optimisation QuickLook et Finder", "QuickLook- & Finder-Optimierung", "Optimización de QuickLook y Finder", "Ottimizzazione QuickLook e Finder", "Otimização do QuickLook e Finder")
        add(.performanceFreeRamDesc, "为您 Mac 电脑的 RAM 内存腾出更多活动空间。尽可能多地释放出可用 RAM。", "為您 Mac 電腦的 RAM 內存騰出更多活動空間。盡可能多地釋放出可用 RAM。", "Free up inactive RAM memory to give your active apps maximum responsiveness.", "Mac の RAM メモリの空き領域を広げ、アクティブなアプリの動作を快適にします。", "Mac의 RAM 메모리 여유 공간을 확보하여 실행 중인 앱의 반응 속도를 극대화합니다.",
            "Libérez de la mémoire RAM inactive pour donner un maximum de réactivité à vos applications.", "Schaffen Sie mehr freien RAM-Arbeitsspeicher für maximale Reaktionsfähigkeit Ihrer Apps.", "Libere memoria RAM inactiva para que las aplicaciones activas respondan con rapidez.", "Libera memoria RAM inattiva per offrire la massima reattività alle tue applicazioni attive.", "Libere memória RAM inativa para dar máxima capacidade de resposta aos seus aplicativos ativos.")
        add(.performanceMaintenanceDetailedIntro, "Mac 的性能维护包括常规任务和特定任务，可帮助您保持软件和硬件正常运行。您可以在这里便捷地运行各类维护任务。", "Mac 的性能維護包括常規任務和特定任務，可幫助您保持軟件和硬件正常運行。您可以在這裡便捷地運行各類維護任務。", "Mac maintenance includes routine and specialized tasks to ensure software and hardware run smoothly.", "Mac の保守には定期・個別タスクが含まれ、ハードとソフトを快適に維持します。ここで手軽に実行できます。", "Mac 성능 유지는 정기 작업과 특화 작업을 포함하여 하드웨어와 소프트웨어가 원활히 구동되도록 돕습니다.",
            "La maintenance du Mac comprend des tâches régulières pour que logiciels et matériels fonctionnent au mieux.", "Die Mac-Wartung umfasst Routine- und Spezialaufgaben für reibungslosen Betrieb von Hard- und Software.", "El mantenimiento del Mac incluye tareas rutinarias para garantizar el buen funcionamiento del software y hardware.", "La manutenzione del Mac include attività di routine e mirate per garantire il perfetto funzionamento del sistema.", "A manutenção do Mac inclui tarefas de rotina e especializadas para garantir que tudo funcione perfeitamente.")
        add(.performanceQuickFixesSubtitle, "无需重启 Mac，一键静默重启假死或卡顿的输入法、通知中心、通用剪贴板与访达", "無需重啟 Mac，一鍵靜默重啟假死或卡頓的輸入法、通知中心、通用剪貼板與訪達", "Restart frozen input methods, Notification Center, Universal Clipboard, and Finder without rebooting", "Mac を再起動せずに、フリーズした入力機能、通知センター、クリップボード、Finder を即時再起動", "Mac을 재부팅할 필요 없이 먹통이 된 입력기, 알림 센터, 공용 클립보드 및 Finder를 원클릭 재시작",
            "Redémarrez sans reboot les méthodes de saisie, le Centre de notifications, le Presse-papiers et le Finder", "Eingabemethoden, Mitteilungszentrale, Zwischenablage und Finder ohne Neustart schnell neustarten", "Reinicie sin reiniciar el Mac los métodos de entrada, Centro de notificaciones, Portapapeles y Finder", "Riavvia senza riavviare il Mac metodi di inserimento, Centro Notifiche, Appunti e Finder bloccati", "Reinicie sem reiniciar o Mac métodos de entrada, Central de Notificações, Área de Transferência e Finder")
        add(.performanceRecommendedTasksSubtitle, "让 macOS 保持最佳状态的推荐任务", "讓 macOS 保持最佳狀態的推薦任務", "Recommended maintenance tasks to keep macOS at peak performance", "macOS を最高の状態に保つための推奨タスク", "macOS를 최상의 상태로 유지하기 위한 권장 유지보수 작업",
            "Tâches recommandées pour maintenir macOS au sommet de ses performances", "Empfohlene Wartungsaufgaben, um macOS in Bestform zu halten", "Tareas recomendadas para mantener macOS en su mejor rendimiento", "Attività consigliate per mantenere macOS al massimo delle prestazioni", "Tarefas recomendadas para manter o macOS em seu melhor desempenho")
        add(.performanceThinTimeMachineDesc, "在不实际删除或禁用备份的情况下缩小 Mac 备份的大小。", "在不實際刪除或禁用備份的情況下縮小 Mac 備份的大小。", "Thin local Time Machine snapshots without deleting or disabling your backup history.", "バックアップを削除または無効化することなく、ローカル Time Machine スナップショットを最適化します。", "백업 기록을 삭제하거나 끄지 않고도 로컬 Time Machine 스냅샷 크기를 안전하게 축소합니다.",
            "Allégez les instantanés locaux de Time Machine sans supprimer votre historique de sauvegarde.", "Lokale Time Machine-Snapshots bereinigen, ohne Ihre Backups zu löschen oder zu deaktivieren.", "Reduzca el tamaño de las instantáneas de Time Machine sin eliminar el historial de copias.", "Riduci le istantanee locali di Time Machine senza eliminare o disattivare la cronologia di backup.", "Reduza o tamanho dos instantâneos locais do Time Machine sem apagar seu histórico de backup.")
        add(.permissionAndMoreFailedPathsFormat, "+ 另有 %d 项…", "+ 另有 %d 項…", "+ %d more items…", "+ 他 %d 項目…", "+ 추가로 %d개 항목…",
            "+ %d autres éléments…", "+ %d weitere Elemente…", "+ %d elementos más…", "+ altri %d elementi…", "+ mais %d itens…")
        add(.permissionAppNotInListPrompt, "列表中没有 ACleaner？", "列表中沒有 ACleaner？", "ACleaner not appearing in the list?", "リストに ACleaner が表示されませんか？", "목록에 ACleaner이 보이지 않나요?",
            "ACleaner n'apparaît pas dans la liste ?", "ACleaner wird nicht in der Liste angezeigt?", "¿No aparece ACleaner en la lista?", "ACleaner non compare nell'elenco?", "O ACleaner não aparece na lista?")
        add(.permissionAuthorizationSuccessTitle, "授权成功！", "授權成功！", "Authorization Successful!", "認証に成功しました！", "권한 승인 완료!",
            "Autorisation réussie !", "Autorisierung erfolgreich!", "¡Autorización concedida con éxito!", "Autorizzazione riuscita!", "Autorização bem-sucedida!")
        add(.permissionCleanupItemsNeedFdaFormat, "%d 个清理项目需要完全磁盘访问权限", "%d 個清理項目需要全磁碟取用權限", "%d cleanup items require Full Disk Access", "%d 個のクリーニング項目にフルディスクアクセスが必要です", "%d개의 청소 항목에 전체 디스크 접근 권한이 필요합니다",
            "%d éléments de nettoyage nécessitent l'accès complet au disque", "%d Bereinigungsobjekte erfordern Festplattenvollzugriff", "%d elementos de limpieza requieren acceso total al disco", "%d elementi da ripulire richiedono Accesso completo al disco", "%d itens de limpeza requerem Acesso Total ao Disco")
        add(.permissionConfig, "权限配置", "權限配置", "Permissions", "権限設定", "권한 설정",
            "Autorisations", "Berechtigungen", "Permisos", "Permessi", "Permissões")
        add(.permissionFdaGeneralExplanation, "ACleaner 需要完全磁盘访问权限以清理应用残留与受保护系统缓存。", "ACleaner 需要全磁碟取用權限以清理應用程式殘留與受保護系統快取。", "ACleaner requires Full Disk Access to clean application leftovers and protected system caches.", "ACleaner がアプリの関連ファイルや保護されたシステムキャッシュをクリーニングするにはフルディスクアクセスが必要です。", "ACleaner이 앱 잔여물 및 보호된 시스템 캐시를 청소하려면 전체 디스크 접근 권한이 필요합니다.",
            "ACleaner nécessite un accès complet au disque pour nettoyer les résidus d'applications et les caches système protégés.", "ACleaner benötigt Festplattenvollzugriff, um App-Reste und geschützte System-Caches zu bereinigen.", "ACleaner requiere acceso total al disco para limpiar restos de aplicaciones y cachés protegidas del sistema.", "ACleaner richiede l'Accesso completo al disco per rimuovere i residui di app e le cache di sistema protette.", "O ACleaner requer Acesso Total ao Disco para limpar sobras de aplicativos e caches protegidos do sistema.")
        add(.permissionFdaProtectedDirExplanation, "部分项目位于受保护目录，授权后将自动继续完成清理。", "部分項目位於受保護目錄，授權後將自動繼續完成清理。", "Some items are located in protected directories. Once granted, cleanup will automatically resume.", "一部の項目は保護されたディレクトリにあります。許可後、自動的にクリーニングが再開されます。", "일부 항목이 보호된 디렉토리에 있습니다. 권한을 부여하면 자동으로 청소가 재개됩니다.",
            "Certains éléments se trouvent dans des répertoires protégés. Une fois accordé, le nettoyage reprendra automatiquement.", "Einige Objekte befinden sich in geschützten Ordnern. Nach der Autorisierung wird die Bereinigung automatisch fortgesetzt.", "Algunos elementos están en directorios protegidos. Tras la autorización, la limpieza continuará automáticamente.", "Alcuni elementi si trovano in cartelle protette. Una volta concessa l'autorizzazione, la pulizia riprenderà automaticamente.", "Alguns itens estão em diretórios protegidos. Após a autorização, a limpeza continuará automaticamente.")
        add(.permissionFdaSandboxContainerExplanationFormat, "彻底清除 %@ 的深层沙盒容器需要完全磁盘访问权限。", "徹底清除 %@ 的深層沙盒容器需要全磁碟取用權限。", "Completely removing sandbox containers for %@ requires Full Disk Access.", "%@ の深層サンドボックスコンテナを完全に消去するにはフルディスクアクセスが必要です。", "%@의 심층 샌드박스 컨테이너를 완전히 삭제하려면 전체 디스크 접근 권한이 필요합니다.",
            "La suppression complète des conteneurs sandbox de %@ nécessite un accès complet au disque.", "Das vollständige Entfernen der Sandbox-Container von %@ erfordert Festplattenvollzugriff.", "Eliminar por completo los contenedores sandbox de %@ requiere acceso total al disco.", "L'eliminazione completa dei container sandbox di %@ richiede Accesso completo al disco.", "A remoção completa dos contêineres sandbox do %@ requer Acesso Total ao Disco.")
        add(.permissionGrantFullDiskAccessTitle, "授予完全磁盘访问权限", "授予全磁碟取用權限", "Grant Full Disk Access", "フルディスクアクセスを許可", "전체 디스크 접근 권한 부여",
            "Accorder l'accès complet au disque", "Festplattenvollzugriff gewähren", "Conceder acceso total al disco", "Concedi Accesso completo al disco", "Conceder Acesso Total ao Disco")
        add(.permissionGrantedRetryingPrompt, "已获取授权，正在自动重试…", "已獲取授權，正在自動重試…", "Permission granted! Automatically retrying…", "権限が許可されました。自動で再試行中…", "권한이 부여되었습니다! 자동으로 재시도 중…",
            "Autorisation accordée ! Nouvelle tentative automatique…", "Berechtigung erteilt! Automatischer Neuversuch…", "¡Permiso concedido! Reintentando automáticamente…", "Autorizzazione concessa! Nuovo tentativo automatico…", "Permissão concedida! Tentando novamente automaticamente…")
        add(.permissionListeningForAuthChangesPrompt, "正在实时监听系统设置授权变动 (1.0s 无感响应)…", "正在實時監聽系統設置授權變動 (1.0s 無感響應)…", "Monitoring authorization status changes in real-time…", "権限の変更をリアルタイムで監視中…", "시스템 설정 권한 변경 사항을 실시간으로 감지하는 중…",
            "Surveillance en temps réel des autorisations…", "Überwache Berechtigungsänderungen in Echtzeit…", "Monitoreando cambios de autorización en tiempo real…", "Monitoraggio in tempo reale delle modifiche di autorizzazione…", "Monitorando alterações de autorização em tempo real…")
        add(.permissionNotInListTroubleshootingHeader, "若系统设置列表未出现 ACleaner，可尝试以下操作：", "若系統設置列表未出現 ACleaner，可嘗試以下操作：", "If ACleaner is not listed in System Settings, try these steps:", "システム設定のリストに ACleaner がない場合は、以下をお試しください：", "시스템 설정 목록에 ACleaner이 나타나지 않으면 다음을 시도하세요:",
            "Si ACleaner n'apparaît pas dans les Réglages Système, essayez :", "Falls ACleaner nicht in den Einstellungen erscheint, versuchen Sie Folgendes:", "Si ACleaner no aparece en Ajustes del Sistema, pruebe esto:", "Se ACleaner non compare nelle Impostazioni di Sistema, prova:", "Se o ACleaner não aparecer nos Ajustes do Sistema, tente:")
        add(.permissionOpenSideBySideHint, "点击后将并排打开系统设置与访达，勾选列表中 ACleaner 或将其拖拽至列表。", "點擊後將並排打開系統設置與訪達，勾選列表中 ACleaner 或將其拖拽至列表。", "Click to open System Settings and Finder side-by-side. Check ACleaner in the list or drag it into the window.", "システム設定と Finder が並んで開きます。リストの ACleaner にチェックを入れるか、アプリをドラッグ＆ドロップしてください。", "클릭 시 시스템 설정과 Finder가 나란히 열립니다. 목록에서 ACleaner을 체크하거나 드래그하여 추가하세요.",
            "Cliquez pour ouvrir les Réglages Système et le Finder côte à côte. Cochez ACleaner ou glissez-le dans la liste.", "Klicken, um Einstellungen und Finder nebeneinander zu öffnen. ACleaner ankreuzen oder hineinziehen.", "Haga clic para abrir Ajustes del Sistema y Finder en paralelo. Marque ACleaner o arrástrelo a la lista.", "Fai clic per aprire Impostazioni di Sistema e Finder affiancati. Seleziona ACleaner o trascinalo nella lista.", "Clique para abrir Ajustes do Sistema e Finder lado a lado. Marque o ACleaner ou arraste-o para a lista.")
        add(.permissionReplayingActionPrompt, "ACleaner 已感知授权变更，正在自动重放继续操作…", "ACleaner 已感知授權變更，正在自動重放繼續操作…", "Permission detected. Resuming operation automatically…", "アクセス権限を検知しました。自動で処理を再開します…", "권한 변경이 감지되었습니다. 작업을 자동으로 재개합니다…",
            "Autorisation détectée. Reprise automatique de l'opération…", "Berechtigung erkannt. Vorgang wird automatisch fortgesetzt…", "Permiso detectado. Reanudando operación automáticamente…", "Autorizzazione rilevata. Ripresa automatica dell'operazione…", "Permissão detectada. Retomando a operação automaticamente…")
        add(.permissionRestrictedFilePathsFormat, "%d 个受限文件路径", "%d 個受限檔案路徑", "%d restricted file paths", "%d 個のアクセス制限パス", "%d개의 제한된 파일 경로",
            "%d chemins d'accès restreints", "%d eingeschränkte Dateipfade", "%d rutas de archivo restringidas", "%d percorsi di file limitati", "%d caminhos de arquivo restritos")
        add(.permissionSheetOneStepSubtitle, "一步授权，开启后系统将自动检测并继续", "一步授權，開啟後系統將自動檢測並繼續", "One-step authorization. ACleaner will automatically detect and continue once granted", "ワンステップ認証。許可されるとシステムが自動検知して処理を再開します", "간편 승인: 권한이 부여되면 자동으로 감지하여 작업을 계속 진행합니다",
            "Autorisation en une étape. Détection automatique dès l'accès accordé", "Ein-Schritt-Autorisierung. Nach Freigabe wird der Vorgang automatisch fortgesetzt", "Autorización en un paso. Se detectará automáticamente para continuar", "Autorizzazione in un solo passaggio. Verrà rilevata automaticamente per continuare", "Autorização em uma etapa. O app detectará automaticamente e continuará")
        add(.permissionStatus, "权限获取情况", "權限獲取情況", "Permission Status", "権限の取得状況", "권한 획득 현황",
            "État des autorisations", "Berechtigungsstatus", "Estado de permisos", "Stato dei permessi", "Status das permissões")
        add(.permissionStepAutoRetryDesc, "无需手动返回，自动重试", "無需手動返回，自動重試", "Automatically retries without returning manually", "手動で戻る必要なく、自動で再試行されます", "수동으로 돌아올 필요 없이 자동으로 재시도됩니다",
            "Nouvelle tentative automatique sans retour manuel", "Wiederholt automatisch ohne manuelles Zurückkehren", "Reintenta automáticamente sin volver manualmente", "Riprova automaticamente senza tornare manualmente", "Tenta novamente de forma automática sem precisar voltar manualmente")
        add(.permissionStepCheckApp, "勾选 ACleaner", "勾選 ACleaner", "Enable ACleaner", "ACleaner をオンにする", "ACleaner 체크",
            "Activer ACleaner", "ACleaner aktivieren", "Activar ACleaner", "Abilita ACleaner", "Ativar o ACleaner")
        add(.permissionStepEnableFdaDesc, "在完全磁盘访问权限中开启", "在完全磁盤訪問權限中開啟", "Toggle on in Full Disk Access", "フルディスクアクセスでトグルをオンにします", "전체 디스크 접근 권한에서 토글 켜기",
            "Activer dans Accès complet au disque", "In Festplattenvollzugriff aktivieren", "Activar en Acceso total al disco", "Attiva in Accesso completo al disco", "Ativar em Acesso Total ao Disco")
        add(.permissionStepTouchIdOrPassword, "触控 ID 或输入锁屏密码", "觸控 ID 或輸入鎖屏密碼", "Touch ID or enter password", "Touch ID またはパスワードを入力", "Touch ID 또는 암호 입력",
            "Touch ID ou mot de passe", "Touch ID oder Passwort eingeben", "Touch ID o introduzca la contraseña", "Touch ID o inserisci password", "Touch ID ou digite a senha")
        add(.permissionUninstallItemsNeedFdaFormat, "卸载 %@：%d 个文件需要完全磁盘访问权限", "解除安裝 %@：%d 個檔案需要全磁碟取用權限", "Uninstall %@: %d items require Full Disk Access", "%@ をアンインストール：%d 個の項目にフルディスクアクセスが必要です", "%@ 제거: %d개의 파일에 전체 디스크 접근 권한이 필요합니다",
            "Désinstaller %@ : %d éléments nécessitent l'accès complet au disque", "%@ deinstallieren: %d Objekte erfordern Festplattenvollzugriff", "Desinstalar %@: %d elementos requieren acceso total al disco", "Disinstalla %@: %d elementi richiedono Accesso completo al disco", "Desinstalar %@: %d itens requerem Acesso Total ao Disco")
        add(.preferencePropertyListPlistStoringWindowLayoutShortcutsAndFeatureFlags, "应用偏好设置文件（.plist，保存窗口布局、快捷键与功能开关配置）", "應用程式偏好設定檔（.plist，儲存視窗佈局、快速鍵與功能開關設定）", "Preference property list (.plist storing window layout, shortcuts, and feature flags)", "環境設定ファイル（.plist・ウィンドウ配置、ショートカット、機能設定を保存）", "앱 환경설정 파일 (.plist, 창 레이아웃, 단축키 및 기능 스위치 설정 저장)",
            "Fichier de préférences (.plist stockant disposition, raccourcis et options)", "Einstellungsdatei (.plist für Fensterlayout, Kurzbefehle und Optionen)", "Archivo de preferencias (.plist con diseño de ventana, atajos y opciones)", "File delle preferenze (.plist con layout finestre, scorciatoie e opzioni)", "Arquivo de preferências (.plist com layout de janela, atalhos e opções)")
        add(.preferencesEllipsis, "偏好设置…", "偏好設定…", "Settings…", "設定…", "설정…",
            "Réglages…", "Einstellungen…", "Ajustes…", "Impostazioni…", "Ajustes…")
        add(.preferencesTitle, "ACleaner 偏好设置", "ACleaner 偏好設定", "ACleaner Preferences", "ACleaner 環境設定", "ACleaner 환경설정",
            "Préférences ACleaner", "ACleaner Einstellungen", "Preferencias de ACleaner", "Preferenze ACleaner", "Preferências do ACleaner")
        add(.presetDesc_bat_percent_only, "电池剩余百分比", "電池剩餘百分比", "Remaining battery percentage", "バッテリー残量パーセント", "배터리 잔여 퍼센트",
            "Pourcentage de batterie restante", "Verbleibende Akkukapazität in Prozent", "Porcentaje de batería restante", "Percentuale di batteria residua", "Porcentagem restante da bateria")
        add(.presetDesc_bat_standard, "电量百分比与实时瓦数", "電量百分比與實時瓦數", "Battery percentage and live wattage", "バッテリー残量とリアルタイム消費電力", "배터리 잔량 및 실시간 전력 소모량",
            "Pourcentage de batterie et puissance en watts en direct", "Akkustand in Prozent und Wattzahl in Echtzeit", "Porcentaje de batería y vataje en vivo", "Percentuale di batteria e potenza in watt in tempo reale", "Porcentagem da bateria e potência em tempo real")
        add(.presetDesc_bat_time_estimate, "电池续航剩余可用倒计时", "電池續航剩餘可用倒計時", "Estimated remaining battery runtime", "バッテリー残量の推定残り稼働時間", "예상 잔여 배터리 사용 시간",
            "Compte à rebours de l'autonomie restante", "Geschätzte verbleibende Akkulaufzeit", "Tiempo estimado de duración de la batería", "Stima del tempo residuo della batteria", "Estimativa do tempo restante de bateria")
        add(.presetDesc_clock_time_only, "极简 24 小时制数字时钟", "極簡 24 小時制數字時鐘", "Minimal 24-hour digital clock", "極めてシンプルな 24時間制デジタル時計", "간결한 24시간 디지털 시계",
            "Horloge numérique 24 heures minimaliste", "Minimalistische digitale 24-Stunden-Uhr", "Reloj digital minimalista de 24 horas", "Orologio digitale minimalista a 24 ore", "Relógio digital minimalista de 24 horas")
        add(.presetDesc_clock_weekday_time, "经典双行星期与时间", "經典雙行星期與時間", "Classic two-line day of week and time", "クラシックな2行の曜日と時間表示", "클래식 2줄 요일 및 시각 표시",
            "Affichage classique sur deux lignes du jour et de l'heure", "Klassische zweizeilige Anzeige von Wochentag und Uhrzeit", "Visualización clásica de dos líneas de día y hora", "Classica visualizzazione su due righe di giorno e ora", "Exibição clássica de duas linhas com dia da semana e hora")
        add(.presetDesc_clock_with_seconds, "动态跳秒精确计时", "動態跳秒精確計時", "High-precision live ticking seconds", "高精度の秒刻みカウント", "초 단위 실시간 정밀 시계",
            "Chronométrage précis avec secondes en direct", "Hochpräzise Zeitanzeige mit Sekunden", "Cronometraje de precisión con segundos en vivo", "Cronometraggio preciso con secondi in tempo reale", "Cronometragem de alta precisão com segundos")
        add(.presetDesc_cpu_percent_only, "极简数字，节省空间", "極簡數字，節省空間", "Minimal numeric usage, saves space", "極めてシンプルな数字、省スペース", "간결한 숫자 표시, 공간 절약",
            "Chiffres minimalistes, gain de place", "Minimalistische Zahl, spart Platz", "Dígito minimalista, ahorra espacio", "Numero minimale, salva spazio", "Número minimalista, economiza espaço")
        add(.presetDesc_cpu_sparkline, "动态历史负载柱图", "動態歷史負載柱圖", "Dynamic historical load histogram", "動的な過去の負荷ヒストグラム", "동적 히스토리 부하 히스토그램",
            "Histogramme dynamique de charge historique", "Dynamisches Verlaufs-Balkendiagramm", "Histograma dinámico de carga histórica", "Istogramma dinamico dello storico del carico", "Histograma dinâmico de carga histórica")
        add(.presetDesc_cpu_standard, "百分比与 CPU 标签", "百分比與 CPU 標籤", "Usage percentage with CPU label", "使用率パーセントと CPU ラベル", "사용률 퍼센트 및 CPU 라벨",
            "Pourcentage d'utilisation et étiquette CPU", "Auslastung in Prozent mit CPU-Beschriftung", "Porcentaje de uso y etiqueta de CPU", "Percentuale di utilizzo con etichetta CPU", "Porcentagem de uso com rótulo de CPU")
        add(.presetDesc_cpu_user_sys, "用户应用与系统内核负载分布", "用戶應用與系統內核負載分佈", "User space and kernel system load breakdown", "ユーザーとシステムカーネルの負荷内訳", "사용자 및 시스템 커널 부하 분포",
            "Répartition de la charge utilisateur et système", "Aufteilung der Benutzer- und Systemlast", "Desglose de carga de usuario y sistema", "Ripartizione del carico utente e sistema", "Distribuição de carga de usuário e sistema")
        add(.presetDesc_cpu_with_temp, "CPU 占用与 SoC 核心温度", "CPU 佔用與 SoC 核心溫度", "CPU load and SoC core temperature", "CPU 負荷と SoC コア温度", "CPU 사용량 및 SoC 코어 온도",
            "Charge CPU et température du cœur SoC", "CPU-Auslastung und SoC-Kerntemperatur", "Carga de CPU y temperatura del núcleo SoC", "Carico CPU e temperatura del core SoC", "Carga da CPU e temperatura do núcleo SoC")
        add(.presetDesc_default, "默认展示", "預設展示", "Default display", "デフォルト表示", "기본 표시",
            "Affichage par défaut", "Standardanzeige", "Visualización predeterminada", "Visualizzazione predefinita", "Exibição padrão")
        add(.presetDesc_disk_free_ratio, "磁盘剩余可用空间与已用百分比", "磁碟剩餘可用空間與已用百分比", "Remaining disk space and usage percentage", "ディスクの空き容量と使用率パーセント", "디스크 여유 공간 및 사용률 퍼센트",
            "Espace disque disponible et pourcentage utilisé", "Freier Speicherplatz und prozentuale Belegung", "Espacio en disco restante y porcentaje de uso", "Spazio su disco residuo e percentuale utilizzata", "Espaço em disco restante e porcentagem de uso")
        add(.presetDesc_disk_free_size, "内置主卷剩余存储空间", "內建主卷剩餘儲存空間", "Remaining space on primary disk volume", "内蔵プライマリボリュームの空き領域", "내장 주 볼륨의 여유 저장 공간",
            "Espace restant sur le volume principal", "Verbleibender Speicherplatz auf dem Hauptvolume", "Espacio restante en el volumen principal", "Spazio residuo sul volume principale", "Espaço restante no volume principal")
        add(.presetDesc_disk_io_speed, "实时读写物理 I/O 速率", "實時讀寫物理 I/O 速率", "Real-time physical disk read and write speed", "リアルタイムの物理ディスク読み書き速度", "실시간 물리 디스크 읽기 및 쓰기 속도",
            "Vitesse d'E/S de lecture et écriture en direct", "Physische Lese- und Schreibgeschwindigkeit in Echtzeit", "Velocidad de lectura y escritura física en tiempo real", "Velocità di lettura e scrittura fisica in tempo reale", "Velocidade de leitura e gravação física em tempo real")
        add(.presetDesc_disk_percent, "存储池已使用百分比", "儲存池已使用百分比", "Percentage of disk space used", "ディスクストレージの使用済みパーセント", "디스크 저장 공간 사용률",
            "Pourcentage d'espace disque utilisé", "Prozentsatz des belegten Festplattenspeichers", "Porcentaje de espacio en disco utilizado", "Percentuale di spazio su disco utilizzato", "Porcentagem de espaço em disco usado")
        add(.presetDesc_gpu_percent_only, "极简纯数字占用", "極簡純數字佔用", "Minimal numeric GPU load", "極めてシンプルな純粋なGPU負荷表示", "간결한 숫자 표시의 GPU 사용량",
            "Charge GPU numérique pure et minimaliste", "Minimalistische rein numerische GPU-Auslastung", "Carga de GPU en números puros minimalistas", "Carico GPU in numeri puri minimalisti", "Carga de GPU numérica minimalista")
        add(.presetDesc_gpu_standard, "百分比与 GPU 标签", "百分比與 GPU 標籤", "Usage percentage with GPU label", "使用率パーセントと GPU ラベル", "사용률 퍼센트 및 GPU 라벨",
            "Pourcentage d'utilisation et étiquette GPU", "Auslastung in Prozent mit GPU-Beschriftung", "Porcentaje de uso y etiqueta de GPU", "Percentuale di utilizzo con etichetta GPU", "Porcentagem de uso com rótulo de GPU")
        add(.presetDesc_gpu_with_freq, "显卡负载与工作主频", "顯卡負載與工作主頻", "GPU load and operating frequency", "GPU 負荷と動作周波数", "그래픽 부하 및 작동 클럭",
            "Charge graphique et fréquence d'horloge", "GPU-Auslastung und Betriebsfrequenz", "Carga de tarjeta gráfica y frecuencia de reloj", "Carico della scheda grafica e frequenza operativa", "Carga gráfica e frequência de operação")
        add(.presetDesc_gpu_with_power, "GPU 核心利用率与实时图形功耗", "GPU 核心利用率與實時圖形功耗", "GPU utilization and real-time graphics power draw", "GPU 使用率とリアルタイム消費電力", "GPU 사용률 및 실시간 소비 전력",
            "Utilisation du GPU et puissance graphique en direct", "GPU-Auslastung und Echtzeit-Grafikleistung", "Uso de GPU y potencia gráfica en tiempo real", "Utilizzo GPU e potenza grafica in tempo reale", "Uso de GPU e consumo de energia gráfica em tempo real")
        add(.presetDesc_gpu_with_temp, "GPU 核心利用率与图形核心温度", "GPU 核心利用率與圖形核心溫度", "GPU load and graphics core temperature", "GPU 負荷とグラフィックスコア温度", "GPU 부하 및 그래픽 코어 온도",
            "Charge GPU et température du cœur graphique", "GPU-Auslastung und Grafikkerntemperatur", "Carga de GPU y temperatura del núcleo gráfico", "Carico GPU e temperatura del core grafico", "Carga da GPU e temperatura do núcleo gráfico")
        add(.presetDesc_mem_free_only, "当前空闲可用物理内存", "當前空閒可用物理記憶體", "Available free physical memory", "現在利用可能な空き物理メモリ", "현재 사용 가능한 여유 물리 메모리",
            "Mémoire physique libre et disponible", "Aktuell freier verfügbarer physischer Speicher", "Memoria física libre disponible actualmente", "Memoria fisica libera attualmente disponibile", "Memória física livre atualmente disponível")
        add(.presetDesc_mem_percent_only, "极简纯数字比例", "極簡純數字比例", "Minimal memory percentage", "極めてシンプルなメモリ割合", "간결한 메모리 비율 표시",
            "Ratio de mémoire pur et minimaliste", "Minimalistischer reiner Speicherprozentsatz", "Proporción pura de memoria minimalista", "Percentuale di memoria minimalista", "Proporção de memória pura e minimalista")
        add(.presetDesc_mem_percent_pressure, "内存占用百分比与内核内存压力", "記憶體佔用百分比與內核記憶體壓力", "Memory usage ratio and kernel memory pressure", "メモリ使用率とカーネルメモリ圧力", "메모리 사용률 및 커널 메모리 압력",
            "Ratio d'utilisation et pression de la mémoire du noyau", "Speicherauslastung und Kernel-Speicherdruck", "Proporción de uso y presión de memoria del kernel", "Rapporto di utilizzo e pressione della memoria del kernel", "Taxa de uso e pressão de memória do kernel")
        add(.presetDesc_mem_standard, "使用百分比与 MEM 标识", "使用百分比與 MEM 標識", "Usage percentage with MEM label", "使用パーセントと MEM ラベル", "사용 퍼센트 및 MEM 라벨",
            "Pourcentage d'utilisation et étiquette MEM", "Speichernutzung in Prozent mit MEM-Kennung", "Porcentaje de uso y etiqueta MEM", "Percentuale di memoria con etichetta MEM", "Porcentagem de uso com rótulo MEM")
        add(.presetDesc_mem_used_total, "真实物理内存使用量", "真實物理記憶體使用量", "Actual physical memory usage", "実際の物理メモリ使用量", "실제 물리 메모리 사용량",
            "Utilisation réelle de la mémoire physique", "Tatsächliche physische Speichernutzung", "Uso real de memoria física", "Utilizzo effettivo della memoria fisica", "Uso real da memória física")
        add(.presetDesc_net_down_only, "突出重点下行瞬时流量", "突出重點下行瞬時流量", "Highlights incoming network bandwidth", "下りトラフィックを強調表示", "다운로드 대역폭 집중 표시",
            "Met en valeur la bande passante descendante", "Hebt die Download-Bandbreite hervor", "Resalta el ancho de banda entrante", "Mette in risalto la banda di download", "Destaca a largura de banda de download")
        add(.presetDesc_net_dual, "实时上行与下行双向速率", "實時上行與下行雙向速率", "Real-time upload and download speeds", "リアルタイムの上り・下り双方向速度", "실시간 업로드 및 다운로드 속도",
            "Vitesses de téléversement et de téléchargement en direct", "Echtzeit-Up- und Download-Geschwindigkeit", "Velocidades de subida y bajada en tiempo real", "Velocità di upload e download in tempo reale", "Velocidades de upload e download em tempo real")
        add(.presetDesc_net_total, "上下行合并总流量", "上下行合併總流量", "Combined total network throughput", "上り・下りの合計転送速度", "업로드 및 다운로드 총 처리량",
            "Débit réseau total combiné", "Kombinierter Gesamtdurchsatz", "Rendimiento de red total combinado", "Velocità di rete totale combinata", "Largura de banda de rede total combinada")
        add(.presetDesc_net_up_only, "突出后台同步上行带宽", "突出後台同步上行頻寬", "Highlights outgoing network bandwidth", "バックグラウンド同期の上り速度を強調", "백그라운드 동기화 업로드 대역폭 표시",
            "Met en valeur la bande passante montante", "Hebt die Upload-Bandbreite hervor", "Resalta el ancho de banda saliente", "Mette in risalto la banda di upload", "Destaca a largura de banda de upload")
        add(.presetDesc_sensor_standard, "SoC 核心芯片摄氏温度", "SoC 核心晶片攝氏溫度", "SoC core chip temperature in Celsius", "SoC コアチップの摂氏温度", "SoC 코어 칩 섭씨 온도",
            "Température du cœur SoC en Celsius", "SoC-Kerntemperatur in Grad Celsius", "Temperatura del chip SoC en Celsius", "Temperatura del core SoC in gradi Celsius", "Temperatura do chip SoC em Celsius")
        add(.presetDesc_sensor_temp_only, "极简数字温度展示", "極簡數字溫度展示", "Minimal digital temperature display", "極めてシンプルなデジタル温度表示", "간결한 디지털 온도 표시",
            "Affichage numérique minimaliste de la température", "Minimalistische digitale Temperaturanzeige", "Visualización de temperatura digital minimalista", "Visualizzazione della temperatura digitale minimalista", "Exibição de temperatura digital minimalista")
        add(.presetDesc_sensor_with_fan, "芯片温度与风扇物理转速", "晶片溫度與風扇物理轉速", "Chip temperature and physical fan RPM", "チップ温度とファンの物理回転数", "칩 온도 및 물리적 팬 RPM",
            "Température de la puce et vitesse physique du ventilateur", "Chiptemperatur und physische Lüfterdrehzahl", "Temperatura del chip y RPM física del ventilador", "Temperatura del chip e velocità fisica della ventola", "Temperatura do chip e velocidade física do ventilador")
        add(.presetDesc_sensor_with_power, "芯片温度与整机封装散热功耗", "晶片溫度與整機封裝散熱功耗", "Chip temperature and package thermal power", "チップ温度とパッケージ消費電力", "칩 온도 및 패키지 소비 전력",
            "Température de la puce et puissance du boîtier", "Chiptemperatur und Gehäuse-Verlustleistung", "Temperatura del chip y potencia del encapsulado", "Temperatura del chip e potenza del package", "Temperatura do chip e potência do encapsulamento")
        add(.presetDesc_weather_icon_temp, "实时摄氏气温与天气现象", "實時攝氏氣溫與天氣現象", "Real-time temperature and weather conditions", "リアルタイムの気温と天気状況", "실시간 기온 및 날씨 상태",
            "Température en direct et conditions météo", "Echtzeittemperatur und Wetterlage", "Temperatura en vivo y condiciones meteorológicas", "Temperatura in tempo reale e condizioni meteo", "Temperatura em tempo real e condições do tempo")
        add(.presetDesc_weather_range, "今日最高温与最低温", "今日最高溫與最低溫", "Today's high and low temperatures", "本日の最高気温と最低気温", "오늘의 최고 및 최저 기온",
            "Températures maximales et minimales du jour", "Heutige Höchst- und Tiefsttemperatur", "Temperaturas máxima y mínima de hoy", "Temperature massima e minima di oggi", "Temperaturas máxima e mínima de hoje")
        add(.presetDesc_weather_temp_only, "极简实况数字气温", "極簡實況數字氣溫", "Minimal live digital temperature", "極めてシンプルな実況デジタル気温表示", "간결한 실시간 디지털 기온 표시",
            "Température numérique en direct minimaliste", "Minimalistische digitale Live-Temperatur", "Temperatura digital en vivo minimalista", "Temperatura digitale in tempo reale minimalista", "Temperatura digital ao vivo minimalista")
        add(.presetName_bat_percent_only, "仅百分比", "僅百分比", "Percentage Only", "パーセントのみ", "퍼센트만",
            "Pourcentage seul", "Nur Prozent", "Solo porcentaje", "Solo percentuale", "Apenas porcentagem")
        add(.presetName_bat_standard, "电量+功率", "電量+功率", "Battery + Power", "バッテリー+電力", "배터리+전력",
            "Batterie + Puissance", "Batterie + Leistung", "Batería + Potencia", "Batteria + Potenza", "Bateria + Potência")
        add(.presetName_bat_time_estimate, "续航预估", "續航預估", "Remaining Time", "残り時間予測", "배터리 시간 예측",
            "Temps restant estimé", "Restlaufzeit", "Tiempo restante", "Autonomia stimata", "Tempo restante")
        add(.presetName_clock_time_only, "紧凑时分", "緊湊時分", "Compact Time", "コンパクト時刻", "콤팩트 시간",
            "Heure compacte", "Kompakte Uhrzeit", "Hora compacta", "Ora compatta", "Hora compacta")
        add(.presetName_clock_weekday_time, "星期+时分", "星期+時分", "Weekday + Time", "曜日+時刻", "요일+시간",
            "Jour + Heure", "Wochentag + Uhrzeit", "Día + Hora", "Giorno + Ora", "Dia da semana + Hora")
        add(.presetName_clock_with_seconds, "高精带秒", "高精帶秒", "Time with Seconds", "秒付き高精度", "초 단위 정밀 시간",
            "Heure avec secondes", "Uhrzeit mit Sekunden", "Hora con segundos", "Ora con secondi", "Hora com segundos")
        add(.presetName_cpu_percent_only, "仅百分比", "僅百分比", "Percentage Only", "パーセントのみ", "퍼센트만",
            "Pourcentage seul", "Nur Prozent", "Solo porcentaje", "Solo percentuale", "Apenas porcentagem")
        add(.presetName_cpu_sparkline, "走势微图", "走勢微圖", "Trend Sparkline", "スパークライン", "추세 미니 차트",
            "Graphique miniature", "Trend-Miniaturdiagramm", "Micrográfico de tendencia", "Mini-grafico di andamento", "Minigráfico de tendência")
        add(.presetName_cpu_standard, "双行标准", "雙行標準", "Double Line Standard", "2行標準", "2줄 표준",
            "Standard 2 lignes", "Standard zweizeilig", "Estándar 2 líneas", "Standard a due righe", "Padrão de duas linhas")
        add(.presetName_cpu_user_sys, "用户+系统", "用戶+系統", "User + System", "ユーザー+システム", "사용자+시스템",
            "Utilisateur + Système", "Benutzer + System", "Usuario + Sistema", "Utente + Sistema", "Usuário + Sistema")
        add(.presetName_cpu_with_temp, "负载+温度", "負載+溫度", "Load + Temp", "負荷+温度", "부하+온도",
            "Charge + Température", "Last + Temperatur", "Carga + Temperatura", "Carico + Temperatura", "Carga + Temperatura")
        add(.presetName_default, "标准", "標準", "Standard", "標準", "표준",
            "Standard", "Standard", "Estándar", "Standard", "Padrão")
        add(.presetName_disk_free_ratio, "可用量+比例", "可用量+比例", "Free + Ratio", "空き容量+使用率", "여유 공간+비율",
            "Espace libre + Ratio", "Freier Speicher + Auslastung", "Espacio libre + Proporción", "Spazio libero + Rapporto", "Espaço livre + Taxa")
        add(.presetName_disk_free_size, "可用空间", "可用空間", "Free Storage", "空き容量", "여유 공간",
            "Espace libre", "Freier Speicher", "Espacio libre", "Spazio libero", "Espaço livre")
        add(.presetName_disk_io_speed, "读写吞吐", "讀寫吞吐", "Disk I/O Speed", "ディスク I/O 速度", "디스크 I/O 속도",
            "Débit E/S disque", "Festplatten-E/A-Rate", "Velocidad de E/S de disco", "Velocità I/O disco", "Velocidade de E/S do disco")
        add(.presetName_disk_percent, "使用比例", "使用比例", "Usage Ratio", "使用率", "사용 비율",
            "Ratio d'utilisation", "Auslastungsgrad", "Proporción de uso", "Rapporto di utilizzo", "Taxa de uso")
        add(.presetName_gpu_percent_only, "仅百分比", "僅百分比", "Percentage Only", "パーセントのみ", "퍼센트만",
            "Pourcentage seul", "Nur Prozent", "Solo porcentaje", "Solo percentuale", "Apenas porcentagem")
        add(.presetName_gpu_standard, "双行标准", "雙行標準", "Double Line Standard", "2行標準", "2줄 표준",
            "Standard 2 lignes", "Standard zweizeilig", "Estándar 2 líneas", "Standard a due righe", "Padrão de duas linhas")
        add(.presetName_gpu_with_freq, "频率与占用", "頻率與佔用", "Frequency + Load", "周波数と負荷", "주파수 및 부하",
            "Fréquence et charge", "Frequenz und Last", "Frecuencia y carga", "Frequenza e carico", "Frequência e carga")
        add(.presetName_gpu_with_power, "负载+功耗", "負載+功耗", "Load + Power", "負荷+電力", "부하+전력",
            "Charge + Puissance", "Last + Leistung", "Carga + Potencia", "Carico + Potenza", "Carga + Potência")
        add(.presetName_gpu_with_temp, "负载+温度", "負載+溫度", "Load + Temp", "負荷+温度", "부하+온도",
            "Charge + Température", "Last + Temperatur", "Carga + Temperatura", "Carico + Temperatura", "Carga + Temperatura")
        add(.presetName_mem_free_only, "可用容量", "可用容量", "Free Available", "空き容量", "여유 용량",
            "Espace libre", "Freier Speicher", "Espacio disponible", "Memoria libera", "Espaço disponível")
        add(.presetName_mem_percent_only, "仅百分比", "僅百分比", "Percentage Only", "パーセントのみ", "퍼센트만",
            "Pourcentage seul", "Nur Prozent", "Solo porcentaje", "Solo percentuale", "Apenas porcentagem")
        add(.presetName_mem_percent_pressure, "占用率+压力", "佔用率+壓力", "Usage + Pressure", "使用率+圧力", "사용률+압력",
            "Utilisation + Pression", "Auslastung + Druck", "Uso + Presión", "Utilizzo + Pressione", "Uso + Pressão")
        add(.presetName_mem_standard, "双行标准", "雙行標準", "Double Line Standard", "2行標準", "2줄 표준",
            "Standard 2 lignes", "Standard zweizeilig", "Estándar 2 líneas", "Standard a due righe", "Padrão de duas linhas")
        add(.presetName_mem_used_total, "已用/总量", "已用/總量", "Used / Total", "使用量 / 合計", "사용량 / 총량",
            "Utilisé / Total", "Belegt / Gesamt", "Usado / Total", "Usato / Totale", "Usado / Total")
        add(.presetName_net_down_only, "仅下载网速", "僅下載網速", "Download Only", "ダウンロードのみ", "다운로드만",
            "Téléchargement seul", "Nur Download", "Solo descarga", "Solo download", "Apenas download")
    }

    static func populateBatch10(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.presetName_net_dual, "双向吞吐", "雙向吞吐", "Dual Throughput", "双方向スループット", "양방향 처리량",
            "Débit bidirectionnel", "Bidirektionaler Durchsatz", "Rendimiento bidireccional", "Throughput bidirezionale", "Taxa bidirecional")
        add(.presetName_net_total, "合并总速率", "合併總速率", "Combined Rate", "合計速度", "통합 총 속도",
            "Débit combiné", "Kombinierte Rate", "Tasa combinada", "Velocità combinata", "Taxa combinada")
        add(.presetName_net_up_only, "仅上传网速", "僅上傳網速", "Upload Only", "アップロードのみ", "업로드만",
            "Téléversement seul", "Nur Upload", "Solo subida", "Solo upload", "Apenas upload")
        add(.presetName_sensor_standard, "温度与标识", "溫度與標識", "Temp + Label", "温度とラベル", "온도 및 라벨",
            "Température et étiquette", "Temperatur und Kennung", "Temperatura y etiqueta", "Temperatura ed etichetta", "Temperatura e rótulo")
        add(.presetName_sensor_temp_only, "仅温度", "僅溫度", "Temperature Only", "温度のみ", "온도만",
            "Température seule", "Nur Temperatur", "Solo temperatura", "Solo temperatura", "Apenas temperatura")
        add(.presetName_sensor_with_fan, "温度+转速", "溫度+轉速", "Temp + Fan RPM", "温度+ファン回転数", "온도+팬 회전수",
            "Température + Vitesse ventilateur", "Temperatur + Lüfter-RPM", "Temperatura + RPM del ventilador", "Temperatura + RPM ventola", "Temperatura + RPM do cooler")
        add(.presetName_sensor_with_power, "温度+功耗", "溫度+功耗", "Temp + Power", "温度+電力", "온도+전력",
            "Température + Puissance", "Temperatur + Leistung", "Temperatura + Potencia", "Temperatura + Potenza", "Temperatura + Potência")
        add(.presetName_weather_icon_temp, "气温+天气", "氣溫+天氣", "Temp + Weather", "気温+天気", "기온+날씨",
            "Température + Météo", "Temperatur + Wetter", "Temperatura + Clima", "Temperatura + Meteo", "Temperatura + Clima")
        add(.presetName_weather_range, "温差范围", "溫差範圍", "Temperature Range", "気温範囲", "기온 범위",
            "Écart de température", "Temperaturbereich", "Rango de temperatura", "Intervallo di temperatura", "Faixa de temperatura")
        add(.presetName_weather_temp_only, "仅气温", "僅氣溫", "Temperature Only", "気温のみ", "기온만",
            "Température seule", "Nur Temperatur", "Solo temperatura", "Solo temperatura", "Apenas temperatura")
        add(.presetTheme, "预设主题配色", "預設主題配色", "Theme Preset", "テーマプリセット", "테마 프리셋",
            "Thème prédéfini", "Design-Vorgabe", "Tema predeterminado", "Tema predefinito", "Tema Predefinido")
        add(.presetThemeAndLanguage, "预设主题配色与界面语言", "預設主題配色與介面語言", "Theme Preset & Interface Language", "テーマプリセットと言語設定", "테마 프리셋 및 언어 설정",
            "Thème et langue de l’interface", "Design-Vorgabe & Sprache", "Tema y preferencias de idioma", "Tema e lingua interfaccia", "Tema Predefinido e Idioma")
        add(.pressurePrefix, "压力", "壓力", "Pressure", "圧力", "압력",
            "Pression", "Druck", "Presión", "Pressione", "Pressão")
        add(.preventNetworkDsStoreFilesDesc, "防止 macOS 访达在网络共享文件夹（SMB/NFS）以及 USB 移动磁盘中散落隐藏的 .DS_Store 文件，保持多设备目录整洁。", "防止 macOS 訪達在網絡共享文件夾（SMB/NFS）以及 USB 移動磁盤中散落隱藏的 .DS_Store 文件，保持多設備目錄整潔。", "Prevent Finder from writing .DS_Store metadata files onto network shares and external USB drives.", "ネットワーク共有や USB メモリへの .DS_Store ファイルの生成を抑制し、環境をクリーンに保ちます。", "네트워크 공유 폴더 및 USB 드라이브에 숨겨진 .DS_Store 파일 생성을 방지하여 폴더를 깔끔하게 유지합니다.",
            "Empêche le Finder d'écrire des fichiers .DS_Store sur les partages réseau et les clés USB.", "Verhindert, dass der Finder .DS_Store-Dateien auf Netzwerkfreigaben und USB-Laufwerken erstellt.", "Evita que el Finder cree archivos .DS_Store en carpetas compartidas de red y unidades USB.", "Impedisce al Finder di scrivere file .DS_Store su condivisioni di rete e unità USB esterne.", "Impede que o Finder crie arquivos .DS_Store em compartilhamentos de rede e unidades USB externas.")
        add(.previewHealthScoreExcellent, "系统健康评分 · 优秀", "系統健康評分 · 優秀", "System Health Score · Excellent", "システム健全性スコア · 優秀", "시스템 건강 점수 · 우수",
            "Score de santé système · Excellent", "Systemgesundheitswert · Ausgezeichnet", "Puntuación de salud del sistema · Excelente", "Punteggio di salute del sistema · Eccellente", "Pontuação de Saúde do Sistema · Excelente")
        add(.previewQuickPurge, "一键极速释放", "一鍵極速釋放", "Instant Purge", "高速解放", "빠른 메모리 확보",
            "Purge rapide", "Sofortige Speicherfreigabe", "Liberación rápida", "Svuotamento rapido", "Liberação Rápida")
        add(.previewRunningNormally, "运行正常", "運作正常", "Running Normally", "正常に動作中", "정상 작동 중",
            "Fonctionne normalement", "Läuft normal", "Funcionando normalmente", "Funziona normalmente", "Operando Normalmente")
        add(.promptClickScanToInspect, "点击扫描开始检查", "點擊掃描開始檢查", "Click Scan to begin inspection", "スキャンをクリックして確認を開始", "검사를 클릭하여 상태 확인을 시작하세요",
            "Cliquez sur Analyser pour commencer", "Klicken Sie auf Scannen, um die Prüfung zu starten", "Haga clic en Escanear para iniciar la comprobación", "Fai clic su Scansiona per avviare il controllo", "Clique em Verificar para iniciar a inspeção")
        add(.protectedSystemComponentsAreSafeDetailedFileListsAreShownBeforeAnyDeletion, "安全保障：系统关键组件受保护，移除前展示详细关联文件供逐项确认", "安全保障：系統關鍵組件受保護，移除前展示詳細關聯檔案供逐項確認", "Protected: System components are safe. Detailed file lists are shown before any deletion.", "安全性確保：システム必須コンポーネントは保護され、削除前に関連ファイルを確認できます", "안전 보장: 시스템 핵심 파일은 보호되며, 삭제 전 상세 연관 파일을 확인합니다",
            "Sécurisé : les composants système sont protégés. La liste des fichiers est affichée avant validation.", "Sicherheit: Systemdateien sind geschützt. Vor dem Löschen wird eine genaue Dateiliste gezeigt.", "Seguridad: los componentes del sistema están protegidos. Se muestran listas de archivos antes de borrar.", "Sicuro: i file di sistema sono protetti. Viene mostrato l’elenco dettagliato prima di procedere.", "Seguro: componentes essenciais estão protegidos. Arquivos detalhados são exibidos antes da remoção.")
        add(.protectedSystemCoreDaemon, "受保护的系统核心守护进程", "受保護的系統核心守護進程", "Protected System Core Daemon", "保護されたシステムコアデーモン", "보호된 시스템 핵심 데몬",
            "Démon principal du système protégé", "Geschützter System-Core-Daemon", "Demonio central protegido del sistema", "Demone principale del sistema protetto", "Daemon central protegido do sistema")
        add(.proxyDisabled, "未开启代理", "未開啓代理", "Proxy Disabled", "プロキシ無効", "프록시 비활성화",
            "Proxy désactivé", "Kein Proxy aktiv", "Proxy desactivado", "Proxy disattivato", "Proxy Desativado")
        add(.proxyEnabled, "已开启代理", "已開啓代理", "Proxy Enabled", "プロキシ有効", "프록시 활성화",
            "Proxy activé", "Proxy aktiv", "Proxy activado", "Proxy attivato", "Proxy Ativado")
        add(.pruneDanglingImages, "清理悬挂镜像", "清理懸掛鏡像", "Prune Dangling Images", "不要なダングリングイメージを削除", "불필요한 댕글링 이미지 정리",
            "Nettoyer les images orphelines", "Verwaiste Docker-Images bereinigen", "Purgar imágenes huérfanas", "Pulisci immagini orfane", "Limpar Imagens Órfãs")
        add(.publicGatewayLatency, "公网节点延迟", "公網節點延遲", "Public Gateway Latency", "外部ノード遅延", "공인 게이트웨이 지연 시간",
            "Latence passerelle publique", "Öffentliche Gateway-Latenz", "Latencia de puerta de enlace pública", "Latenza gateway pubblico", "Latência do Gateway Público")
        add(.publicIp, "公网 IP", "公網 IP", "Public IP", "パブリック IP", "공인 IP",
            "IP publique", "Öffentliche IP", "IP pública", "IP pubblico", "IP Público")
        add(.publicIpPrefix, "公网 IP", "公用 IP", "Public IP", "パブリック IP", "공인 IP",
            "IP publique", "Öffentliche IP", "IP pública", "IP pubblico", "IP público")
        add(.purgeableSpaceDetailedIntro, "macOS 将可清理空间识别为在需要更多存储空间时可以安全移除的数据。删除这些文件不会影响关键文件或应用程序的正常运行。", "macOS 將可清理空間識別為在需要更多儲存空間時可以安全移除的資料。刪除這些檔案不會影響關鍵檔案或應用程式的正常運行。", "macOS identifies purgeable space as data that can be safely removed when more storage is required. Reclaiming it will not affect your critical files or apps.", "macOS は、空き容量が必要な場合に安全に削除できるデータをパージ可能領域として認識します。これらを削除しても重要なファイルやアプリには影響しません。", "macOS는 더 많은 저장 공간이 필요할 때 안전하게 제거할 수 있는 데이터를 '제거 가능 공간'으로 식별합니다. 이 데이터를 제거해도 필수 파일이나 앱에는 영향을 주지 않습니다.",
            "macOS identifie l'espace purgeable comme des données pouvant être supprimées en toute sécurité si nécessaire. La suppression n'affectera pas vos applications ou fichiers essentiels.", "macOS stuft Daten als bereinigbaren Speicherplatz ein, die bei Bedarf sicher entfernt werden können. Das Löschen dieser Dateien beeinträchtigt keine wichtigen Systemfunktionen.", "macOS identifica el espacio purgable como datos que se pueden eliminar de forma segura cuando se necesita espacio. Su eliminación no afectará sus archivos o aplicaciones críticas.", "macOS identifica lo spazio eliminabile come dati che possono essere rimossi in sicurezza se necessario. La rimozione non influirà sui file o app essenziali.", "O macOS identifica o espaço purgável como dados que podem ser removidos com segurança quando houver necessidade de espaço. Isso não afetará arquivos ou apps essenciais.")
        add(.purgeableSpaceTitle, "可清除空间", "可清除空間", "Purgeable Space", "消去可能スペース", "제거 가능 공간",
            "Espace purgeable", "Bereinigbarer Speicherplatz", "Espacio purgable", "Spazio eliminabile", "Espaço purgável")
        add(.quickGlitchFixes, "修复小毛病", "修復系統小問題", "Quick Glitch Fixes", "クイック修復", "빠른 오류 수정",
            "Corrections rapides", "Schnellreparaturen", "Correcciones rápidas", "Riparazioni rapide", "Correções Rápidas")
        add(.readPrefix, "读取", "讀取", "Read", "読み取り", "읽기",
            "Lecture", "Lesen", "Lectura", "Lettura", "Leitura")
        add(.readingChromeDownloadHistory, "读取 Chrome 下载记录", "讀取 Chrome 下載記錄", "Reading Chrome download history", "Chrome のダウンロード履歴を読み込み中", "Chrome 다운로드 기록 읽는 중",
            "Lecture de l'historique de téléchargement de Chrome", "Lese Chrome-Download-Verlauf", "Leyendo el historial de descargas de Chrome", "Lettura della cronologia dei download di Chrome", "Lendo histórico de downloads do Chrome")
        add(.readingInstalledApps, "读取已安装应用", "讀取已安裝應用程式", "Reading installed applications", "インストール済みアプリを読込中", "설치된 응용 프로그램 읽는 중",
            "Lecture des applications installées", "Installierte Anwendungen lesen", "Leyendo aplicaciones instaladas", "Lettura applicazioni installate", "Lendo aplicativos instalados")
        add(.readingSafariDownloadHistory, "读取 Safari 下载记录", "讀取 Safari 下載記錄", "Reading Safari download history", "Safari のダウンロード履歴を読み込み中", "Safari 다운로드 기록 읽는 중",
            "Lecture de l'historique de téléchargement de Safari", "Lese Safari-Download-Verlauf", "Leyendo el historial de descargas de Safari", "Lettura della cronologia dei download di Safari", "Lendo histórico de downloads do Safari")
        add(.readyToCleanTitle, "准备开始清理", "準備開始清理", "Ready to Clean", "クリーンアップの準備完了", "정리 준비 완료",
            "Prêt à nettoyer", "Bereit zum Bereinigen", "Listo para limpiar", "Pronto per la pulizia", "Pronto para limpar")
        add(.realtimeReadRate, "实时读取速率", "即時讀取速率", "Read Speed", "リアルタイム読込速度", "실시간 읽기 속도",
            "Vitesse de lecture", "Leserate", "Velocidad de lectura", "Velocità di lettura", "Velocidade de Leitura")
        add(.realtimeWriteRate, "实时写入速率", "即時寫入速率", "Write Speed", "リアルタイム書込速度", "실시간 쓰기 속도",
            "Vitesse d’écriture", "Schreibrate", "Velocidad de escritura", "Velocità di scrittura", "Velocidade de Escrita")
        add(.rebuildLaunchservicesDatabase, "重建 LaunchServices 数据库", "重建 LaunchServices 資料庫", "Rebuild LaunchServices Database", "LaunchServices データベースを再構築", "LaunchServices 데이터베이스 재구축",
            "Reconstruire la base LaunchServices", "LaunchServices-Datenbank neu aufbauen", "Reconstruir base de datos de LaunchServices", "Ricostruisci database LaunchServices", "Reconstruir Banco de Dados do LaunchServices")
        add(.rebuildSpotlightIndex, "重建 Spotlight 索引", "重建 Spotlight 索引", "Rebuild Spotlight Index", "Spotlight インデックスを再構築", "Spotlight 인덱스 재구축",
            "Reconstruire l’index Spotlight", "Spotlight-Index neu aufbauen", "Reconstruir índice de Spotlight", "Ricostruisci indice di Spotlight", "Reconstruir Índice do Spotlight")
        add(.rebuildSpotlightSearchIndexDesc, "此任务会对 Mac 的主搜索引擎完全进行重新索引，从而提高其性能和准确性。系统将在测速与稳定供电下执行重建。", "此任務會對 Mac 的主搜索引擎完全進行重新索引，從而提高其性能和準確性。系統將在測速與穩定供電下執行重建。", "Rebuild the macOS Spotlight index from scratch to fix search accuracy and responsiveness.", "Spotlight インデックスを完全に再構築し、検索の精度と応答性を向上させます。", "Spotlight 검색 색인을 완전히 재구성하여 검색 정확도와 성능을 대폭 개선합니다.",
            "Reconstruisez l'index Spotlight de macOS pour améliorer la précision et la rapidité des recherches.", "Baut den Spotlight-Suchindex neu auf, um Suchgenauigkeit und Leistung zu optimieren.", "Reconstruye el índice de Spotlight de macOS para mejorar la precisión y rapidez de búsqueda.", "Ricostruisce da zero l'indice di Spotlight per migliorare accuratezza e velocità di ricerca.", "Reconstrua o índice do Spotlight do macOS do zero para melhorar a precisão e a rapidez das buscas.")
        add(.refreshContinuityAndCrossDeviceClipboardSyncService, "刷新接力与跨设备剪贴板同步服务", "重新整理接力與跨裝置剪貼板同步服務", "Refresh Continuity and cross-device clipboard sync service", "Handoffとユニバーサルクリップボード同期を再起動します", "연속성 및 기기 간 클립보드 동기화를 새로 고칩니다",
            "Actualiser Continuité et le presse-papiers partagé", "Continuity & Zwischenablage-Sync aktualisieren", "Actualizar Continuidad y sincronización del portapapeles", "Aggiorna Continuity e sincronizzazione appunti", "Atualizar Continuidade e sincronização da área de transferência")
        add(.refreshFileThumbnailCacheAndQuicklookPreviewServer, "刷新文件缩略图缓存与快速查看预览服务", "重新整理檔案縮圖快取與快速查看預覽服務", "Refresh file thumbnail cache and QuickLook preview server", "サムネイルキャッシュとQuickLookサーバーを更新します", "파일 썸네일 캐시 및 훑어보기 서버를 새로 고칩니다",
            "Actualiser les vignettes et le serveur Coup d’œil", "Miniaturansichten und QuickLook-Server aktualisieren", "Actualizar miniaturas y servidor de Vista rápida", "Aggiorna miniature e server Visualizzazione rapida", "Atualizar miniaturas e servidor de Visualização Rápida")
        add(.refreshNotificationCenterToFixStuckBannersOrDelayedAlerts, "刷新通知中心服务以修复横幅卡死或提醒延迟", "重新整理通知中心服務以修復橫幅卡死或提醒延遲", "Refresh Notification Center to fix stuck banners or delayed alerts", "通知センターを再起動してバナー表示の不具合を修復します", "알림 센터를 새로 고쳐 배너 멈춤 문제를 해결합니다",
            "Actualiser le Centre de notifications", "Mitteilungszentrale neu starten", "Actualizar el Centro de notificaciones", "Aggiorna il Centro Notifiche", "Atualizar a Central de Notificações")
        add(.refreshed, "已刷新", "已重新整理", "Refreshed", "リフレッシュ完了", "새로 고침 완료",
            "Actualisé", "Aktualisiert", "Actualizado", "Aggiornato", "Atualizado")
        add(.reindexSpotlight, "重新索引“聚焦”", "重新建立 Spotlight 索引", "Reindex Spotlight", "Spotlightインデックスを再構築", "Spotlight 인덱스 재구성",
            "Réindexer Spotlight", "Spotlight neu indizieren", "Reindexar Spotlight", "Reindicizza Spotlight", "Reindexar o Spotlight")
        add(.remove, "移除", "移除", "Remove", "削除", "제거",
            "Supprimer", "Entfernen", "Eliminar", "Rimuovi", "Remover")
        add(.removeCheckedAppsCountFormat, "移除 %d 项", "移除 %d 項", "Remove %d apps", "%d 件のアプリを削除", "%d개 앱 제거",
            "Supprimer %d applications", "%d Apps entfernen", "Eliminar %d aplicaciones", "Rimuovi %d applicazioni", "Remover %d aplicativos")
        add(.removeLeftoversFromUninstalledAppsDesc, "删除已卸载应用程序在系统中留下的残余项目。", "刪除已解除安裝應用程式在系統中留下的殘餘項目。", "Remove leftover items left behind by uninstalled applications.", "削除済みアプリがシステムに残した不要項目をクリーンアップ。", "삭제된 응용 프로그램이 시스템에 남긴 잔여 항목을 제거합니다.",
            "Supprimer les éléments résiduels laissés par les applications désinstallées.", "Entfernen Sie Überreste deinstallierter Anwendungen.", "Eliminar elementos residuales de aplicaciones desinstaladas.", "Rimuovi gli elementi residui lasciati dalle app disinstallate.", "Remover itens residuais deixados por aplicativos desinstalados.")
        add(.removeRedundantFilesThatWasteSpaceAndSlowDownYourMac, "清理占用空间、影响性能的冗余文件。", "清理佔用空間、影響效能的冗餘檔案。", "Remove redundant files that waste space and slow down your Mac.", "容量を圧迫し動作を低下させる不要ファイルを削除します。", "공간을 차지하고 성능을 저하시키는 불필요한 파일을 정리합니다.",
            "Supprimez les fichiers encombrants qui ralentissent votre Mac.", "Beseitigen Sie überflüssige Dateien, die Speicherplatz und Leistung kosten.", "Elimina archivos innecesarios que ocupan espacio y reducen la velocidad.", "Rimuovi file ridondanti che occupano spazio e rallentano il Mac.", "Remova arquivos desnecessários que ocupam espaço e reduzem o desempenho.")
        add(.removeSafeCachesOnly, "仅移除安全缓存与主程序", "僅移除安全快取與主程序", "Remove safe caches & bundle only", "安全なキャッシュと本体のみ削除", "안전한 캐시 및 메인 프로그램만 제거",
            "Supprimer uniquement les caches sûrs et l’application", "Nur sichere Caches und Hauptprogramm entfernen", "Eliminar solo cachés seguros y la app", "Rimuovi solo le cache sicure e l’app", "Remover apenas caches seguros e o aplicativo")
        add(.removeSafeItemsOnlyKeepUserData, "仅移除安全项（保留用户数据）", "僅移除安全項（保留使用者資料）", "Safe items only (keep user data)", "安全な項目のみ削除（データを保持）", "안전 항목만 제거(데이터 유지)",
            "Éléments sûrs uniquement (garder les données)", "Nur sichere Elemente (Daten behalten)", "Solo elementos seguros (conservar datos)", "Solo elementi sicuri (mantieni dati)", "Apenas itens seguros (manter dados)")
        add(.removeSelectedItemsCountFormat, "移除 %d 项", "移除 %d 項", "Remove %d items", "%d 件の項目を削除", "%d개 항목 제거",
            "Supprimer %d éléments", "%d Elemente entfernen", "Eliminar %d elementos", "Rimuovi %d elementi", "Remover %d itens")
        add(.removeSimulatorRuntime, "安全移除 Runtime", "安全移除 Runtime", "Remove Simulator Runtime", "シミュレータランタイムを安全に削除", "시뮬레이터 런타임 안전 제거",
            "Supprimer le runtime du simulateur", "Simulator-Runtime sicher entfernen", "Eliminar runtime de simulador de forma segura", "Rimuovi runtime simulatore in sicurezza", "Remover Runtime do Simulador com Segurança")
        add(.renderCores, "渲染核", "渲染核", "Render Cores", "レンダリングコア", "렌더링 코어",
            "Cœurs de rendu", "Render-Kerne", "Núcleos de renderizado", "Core di rendering", "Núcleos de renderização")
        add(.repair, "修复", "修復", "Repair", "修復", "수리 / 복구",
            "Réparer", "Reparieren", "Reparar", "Ripara", "Reparar")
        add(.resetQuickLookIconCache, "刷新快速查看与图标缓存", "重新整理快速查看與圖示快取", "Reset QuickLook & Icon Cache", "QuickLookとアイコンキャッシュを再構築", "훑어보기 및 아이콘 캐시 재설정",
            "Réinitialiser Coup d’œil et les icônes", "QuickLook- & Icon-Cache zurücksetzen", "Restablecer Vista rápida y caché de iconos", "Ripristina cache QuickLook e icone", "Redefinir Cache do QuickLook e Ícones")
        add(.restartClipboardAndAirDropServiceDesc, "重启剪贴板服务 (pboard) 与隔空投送/接力守护进程 (sharingd)，恢复跨设备复制粘贴与 AirDrop。", "重啟剪貼板服務 (pboard) 與隔空投送/接力守護進程 (sharingd)，恢複跨設備複製粘貼與 AirDrop。", "Restart pboard and sharingd daemons to restore Universal Clipboard, Handoff, and AirDrop.", "クリップボード（pboard）と共有デーモン（sharingd）を再起動し、ユニバーサルクリップボードや AirDrop を復元します。", "클립보드 서비스(pboard) 및 공유 데몬(sharingd)을 재시작하여 공용 클립보드와 AirDrop 기능을 복구합니다.",
            "Redémarrez les démons pboard et sharingd pour restaurer le Presse-papiers universel et AirDrop.", "Startet pboard und sharingd neu, um die universelle Zwischenablage, Handoff und AirDrop wiederherzustellen.", "Reinicia pboard y sharingd para restaurar el Portapapeles universal, Handoff y AirDrop.", "Riavvia pboard e sharingd per ripristinare gli Appunti universali, Handoff e AirDrop.", "Reinicie os daemons pboard e sharingd para restaurar a Área de Transferência Universal, Handoff e AirDrop.")
        add(.restartInputMethodAgentToFixTypingLagOrStuckSwitching, "重启输入法代理以解决打字卡顿或切换无响应", "重啟輸入法代理以解決打字卡頓或切換無回應", "Restart input method agent to fix typing lag or stuck switching", "入力メソッドエージェントを再起動して入力遅延を解消します", "입력기 에이전트를 재시작하여 타이핑 지연을 해결합니다",
            "Redémarrer l’agent de saisie pour corriger les lenteurs", "Eingabemethoden-Agent bei Verzögerungen neu starten", "Reiniciar el agente de entrada para corregir retrasos", "Riavvia l’agente di input per risolvere rallentamenti", "Reiniciar agente de entrada para corrigir lentidão ao digitar")
        add(.restartInputMethodServiceDesc, "重启系统输入法引擎与候选词窗口服务，立即解决打字卡顿、候选框消失或中英切换失灵。", "重啟系統輸入法引擎與候選詞窗口服務，立即解決打字卡頓、候選框消失或中英切換失靈。", "Restart macOS input method engines and candidate services to fix typing lag or frozen candidate windows.", "入力システムと候補ウィンドウサービスを再起動し、入力遅延やフリーズを解消します。", "입력기 엔진과 후보 창 서비스를 재시작하여 타이핑 지연이나 전환 오류를 해결합니다.",
            "Redémarrez les méthodes de saisie macOS pour corriger la lenteur de frappe ou les fenêtres de candidats bloquées.", "Startet Eingabemethode-Dienste neu, um Tippverzögerungen oder hängende Vorschaufenster zu beheben.", "Reinicia los métodos de entrada de macOS para solucionar el retraso al escribir o ventanas bloqueadas.", "Riavvia i servizi del metodo di immissione di macOS per correggere il ritardo di digitazione.", "Reinicie o mecanismo de métodos de entrada do macOS para corrigir atrasos na digitação ou janelas congeladas.")
        add(.restartNotificationCenterServiceDesc, "重启 NotificationCenter 与通知守护进程，恢复卡住的右上角通知横幅与桌面小组件。", "重啟 NotificationCenter 與通知守護進程，恢複卡住的右上角通知橫幅與桌面小組件。", "Restart Notification Center and usernoted to fix stuck banners and desktop widgets.", "通知センターと関連デーモンを再起動し、表示が停止した通知バナーやウィジェットを復元します。", "알림 센터 및 관련 데몬을 재시작하여 멈춘 알림 배너와 데스크탑 위젯을 복구합니다.",
            "Redémarrez le Centre de notifications et usernoted pour débloquer les bannières et widgets.", "Startet die Mitteilungszentrale neu, um hängengebliebene Banner und Widgets zu reparieren.", "Reinicia el Centro de notificaciones y usernoted para arreglar banners y widgets bloqueados.", "Riavvia Centro Notifiche e usernoted per sbloccare banner e widget desktop bloccati.", "Reinicie a Central de Notificações e o usernoted para corrigir banners e widgets travados.")
        add(.restartQuickLookAndIconCachesDesc, "重启 macOS 快速查看预览服务器并刷新 Finder 缩略图图标缓存，解决文件图标发白、缩略图缺失或生成卡顿问题。", "重啟 macOS 快速查看預覽服務器並刷新 Finder 縮略圖圖標緩存，解決文件圖標發白、縮略圖缺失或生成卡頓問題。", "Restart QuickLook server and clear thumbnail caches to fix blank or stale Finder icons.", "QuickLook サーバを再起動し、Finder のサムネイルキャッシュを更新して、アイコンの表示不具合を解消します。", "QuickLook 서버를 재시작하고 Finder 축소판 캐시를 새로고침하여 빈 아이콘이나 멈춤 현상을 해결합니다.",
            "Redémarrez le serveur QuickLook et videz les caches de vignettes pour corriger les icônes Finder vides.", "Startet den QuickLook-Server neu und leert Vorschau-Caches, um fehlerhafte Finder-Symbole zu reparieren.", "Reinicia el servidor QuickLook y borra la caché de miniaturas para corregir iconos en blanco del Finder.", "Riavvia il server QuickLook e svuota le cache delle miniature per correggere le icone vuote del Finder.", "Reinicie o servidor QuickLook e limpe os caches de miniaturas para corrigir ícones em branco no Finder.")
        add(.restoreMenuBarDefaultLayout, "恢复菜单栏默认布局", "恢復選單列預設版面配置", "Reset to Default Layout", "デフォルト配置に戻す", "기본 레이아웃으로 초기화",
            "Rétablir la disposition par défaut", "Auf Standard-Layout zurücksetzen", "Restablecer diseño predeterminado", "Ripristina layout predefinito", "Redefinir para o Layout Padrão")
        add(.reviewAndCleanDownloadsDesc, "查看并整理下载文件夹中的项目", "檢視並整理下載資料夾中的項目", "Review and organize items in your Downloads folder", "ダウンロードフォルダ内の項目を確認・整理", "다운로드 폴더의 항목 검토 및 정리",
            "Examiner et organiser les éléments du dossier Téléchargements", "Objekte im Downloads-Ordner überprüfen und organisieren", "Revisar y organizar elementos en la carpeta Descargas", "Esamina e organizza gli elementi nella cartella Download", "Revisar e organizar itens na pasta Downloads")
        add(.reviewAndDeleteDownloadsDesc, "查看并删除不必要的下载文件", "查看並刪除不必要的下載檔案", "Review and delete unnecessary downloaded files", "不要になったダウンロードファイルを確認して削除", "불필요한 다운로드 파일을 검토하고 삭제합니다",
            "Examinez et supprimez les téléchargements inutiles", "Überprüfen und löschen Sie unnötige Downloads", "Revise y elimine descargas innecesarias", "Esamina ed elimina i download non necessari", "Revise e exclua arquivos desnecessários da pasta Downloads")
        add(.reviewAndDeleteDownloadsSaveSpaceDesc, "查看并删除不必要的下载文件，以节省大量空间。", "查看並刪除不必要的下載檔案，以節省大量空間。", "Review and remove unneeded downloads to reclaim substantial storage space.", "不要なダウンロードファイルを確認・削除して、空き容量を大幅に回復します。", "불필요한 다운로드 파일을 검토 및 삭제하여 여유 공간을 확보하세요.",
            "Passez en revue et supprimez les téléchargements inutiles pour libérer de l'espace.", "Überprüfen und löschen Sie unnötige Downloads, um viel Speicher zu sparen.", "Revise y elimine descargas innecesarias para recuperar un valioso espacio.", "Esamina e rimuovi i download superflui per recuperare molto spazio.", "Revise e remova downloads desnecessários para economizar bastante espaço.")
        add(.reviewAppsLaunchingAtLoginDesc, "查看在 Mac 开机时自动启动的应用程序。您可能希望禁用其中的一些自动启动。", "檢視在 Mac 開機時自動啟動的應用程式。您可能想要停用其中的某些自動啟動。", "Review apps that launch automatically when your Mac starts up. You might want to disable some of them.", "Mac の起動時に自動起動するアプリを確認します。不要な自動起動を無効化できます。", "Mac 시동 시 자동 실행되는 앱을 검토합니다. 불필요한 자동 실행을 비활성화할 수 있습니다.",
            "Examiner les applications lancées au démarrage de votre Mac pour en désactiver certaines.", "Überprüfen Sie Apps, die beim Start automatisch geöffnet werden, um sie ggf. zu deaktivieren.", "Revisar las aplicaciones que se inician automáticamente al arrancar el Mac.", "Esamina le applicazioni avviate automaticamente all'avvio del Mac.", "Revisar aplicativos iniciados automaticamente na inicialização do Mac.")
        add(.reviewBackgroundProcessesOnMacDesc, "查看允许在 Mac 电脑上运行的后台进程。", "檢視允許在 Mac 電腦上執行的背景處理程序。", "Review background processes allowed to run on your Mac.", "Mac で実行を許可されているバックグラウンドプロセスを確認します。", "Mac에서 실행이 허용된 백그라운드 프로세스를 검토합니다.",
            "Examiner les processus en arrière-plan autorisés sur votre Mac.", "Überprüfen Sie Hintergrundprozesse, die auf Ihrem Mac ausgeführt werden dürfen.", "Revisar los procesos en segundo plano autorizados en el Mac.", "Esamina i processi in background autorizzati sul Mac.", "Revisar processos em segundo plano permitidos no Mac.")
        add(.reviewBeforeDeletingUsuallyRegenerableOrDownloadable, "删除前请确认不再需要,通常可重新生成或重新下载", "刪除前請確認不再需要,通常可重新生成或重新下載", "Review before deleting; usually regenerable or downloadable", "削除前に確認してください。通常は再生成または再ダウンロード可能です", "삭제 전 확인 필요. 대개 다시 생성하거나 다운로드할 수 있습니다",
            "À vérifier avant suppression ; généralement téléchargeable à nouveau", "Vor dem Löschen prüfen; meist neu generierbar oder herunterladbar", "Revisa antes de borrar; normalmente se puede volver a descargar", "Verifica prima di eliminare; di solito riscaricabile o ricreabile", "Verifique antes de apagar; geralmente pode ser gerado ou baixado novamente")
        add(.reviewSimilarPhotosKeepBestDesc, "查看近乎相同的照片，并仅保留值得保存的最佳副本。", "查看近乎相同的照片，並僅保留值得保存的最佳副本。", "Inspect near-identical photos and keep only the best shot worth saving.", "ほぼ同一の写真を確認し、残す価値のあるベストショットのみを保管します。", "거의 동일한 사진들을 검토하고 보관할 가치가 있는 최상의 사진만 남기세요.",
            "Inspectez les photos quasi-identiques et ne gardez que le meilleur cliché.", "Prüfen Sie fast identische Aufnahmen und behalten Sie nur das beste Bild.", "Revise fotos casi idénticas y conserve únicamente la mejor toma.", "Esamina le foto quasi identiche e conserva solo lo scatto migliore.", "Analise fotos quase idênticas e guarde apenas a melhor imagem.")
        add(.rightClickToOpenOrMoveToTrash, "右键可打开或移到废纸篓", "右鍵可打開或移到垃圾桶", "Right-click to open or move to Trash", "右クリックで開く・ゴミ箱に入れる", "우클릭하여 열기 또는 휴지통으로 이동",
            "Clic droit pour ouvrir ou placer dans la corbeille", "Rechtsklick zum Öffnen oder in den Papierkorb legen", "Clic derecho para abrir o trasladar a la papelera", "Clic destro per aprire o spostare nel Cestino", "Clique direito para abrir ou mover para o Lixo")
        add(.ruleCautionReLoginOrRebuildDesc, "清理后可能需要重新登录或重新生成缓存", "清理後可能需要重新登錄或重新生成緩存", "May require re-login or automatic cache regeneration after cleaning", "クリーンアップ後に再ログインやキャッシュの再構築が必要になる場合があります", "정리 후 재로그인하거나 캐시를 다시 생성해야 할 수 있습니다",
            "Peut nécessiter une reconnexion ou une régénération automatique du cache", "Nach der Bereinigung kann eine erneute Anmeldung oder Cache-Neuerstellung erforderlich sein", "Puede requerir volver a iniciar sesión o regenerar la caché tras la limpieza", "Potrebbe richiedere un nuovo accesso o la rigenerazione della cache dopo la pulizia", "Pode exigir novo login ou regeneração automática de cache após a limpeza")
        add(.ruleRiskyContainsUserDataDesc, "高危项，可能包含个人配置或不可逆数据，请仔细确认", "高危項，可能包含個人配置或不可逆數據，請仔細確認", "High risk, may contain personal configurations or irreversible data, please verify carefully", "高リスク：個人設定や復元不能なデータを含む可能性があるため、慎重に確認してください", "고위험 항목: 개인 설정이나 되돌릴 수 없는 데이터가 포함될 수 있으므로 주의해서 확인하세요",
            "Risque élevé : peut contenir des configurations personnelles ou des données irréversibles", "Hohes Risiko: Enthält möglicherweise persönliche Konfigurationen oder irreversible Daten", "Alto riesgo: puede contener configuraciones personales o datos irreversibles, revise con cuidado", "Rischio elevato: potrebbe contenere configurazioni personali o dati irreversibili, verificare attentamente", "Alto risco: pode conter configurações pessoais ou dados irreversíveis, confirme com atenção")
        add(.ruleSafeToCleanDesc, "可安全清理，不影响应用正常运行", "可安全清理，不影響應用正常運行", "Safe to clean, does not affect normal application operations", "安全にクリーンアップ可能で、アプリの通常動作に影響しません", "안전하게 정리 가능하며 앱의 정상 작동에 영향을 주지 않습니다",
            "Nettoyage sûr, n'affecte pas le bon fonctionnement des applications", "Sicher zu bereinigen, beeinträchtigt die normale App-Nutzung nicht", "Seguro de limpiar, no afecta el funcionamiento normal de la aplicación", "Sicuro da pulire, non influisce sul normale funzionamento dell'applicazione", "Seguro para limpar, não afeta o funcionamento normal do aplicativo")
        add(.run, "运行", "執行", "Run", "実行", "실행",
            "Exécuter", "Ausführen", "Ejecutar", "Esegui", "Executar")
        add(.runMaintenance, "执行维护", "執行維護", "Run Maintenance", "メンテナンスを実行", "유지보수 실행",
            "Lancer la maintenance", "Wartung ausführen", "Ejecutar mantenimiento", "Esegui manutenzione", "Executar Manutenção")
        add(.running, "运行中…", "執行中…", "Running…", "実行中…", "실행 중…",
            "En cours…", "Wird ausgeführt…", "Ejecutando…", "In esecuzione…", "Executando…")
        add(.runningAssociatedAppsClickToQuitSuffix, "个关联应用运行中 · 点击退出", "個關聯應用運行中 · 點擊退出", " associated apps running · Click to quit", " 件の関連アプリが起動中 · クリックして終了", "개 관련 앱 실행 중 · 클릭하여 종료",
            " apps associées en cours d'exécution · Cliquer pour quitter", " zugehörige Apps laufen · Zum Beenden klicken", " apps asociadas en ejecución · Haga clic para salir", " app associate in esecuzione · Fai clic per uscire", " apps associados em execução · Clique para encerrar")
        add(.runningMaintenanceTasksInBackground, "正在后台执行系统维护任务…", "正在後台執行系統維護任務…", "Running system maintenance tasks in background…", "バックグラウンドでメンテナンスタスクを実行中…", "백그라운드에서 시스템 유지보수 작업 실행 중…",
            "Exécution des tâches de maintenance en arrière-plan…", "Wartungsaufgaben im Hintergrund werden ausgeführt…", "Ejecutando tareas de mantenimiento en segundo plano…", "Attività di manutenzione in esecuzione in background…", "Executando tarefas de manutenção em segundo plano…")
        add(.runningOrCleaningDynamicPrefixFormat, "正在%@…", "正在%@…", "%@ in progress…", "%@ を実行中…", "%@ 진행 중…",
            "%@ en cours…", "%@ läuft…", "%@ en curso…", "%@ in corso…", "%@ em andamento…")
        add(.runningOrEnabled, "运行或已启用", "執行或已啟用", "Running or Enabled", "実行中・有効", "실행 중 또는 활성화됨",
            "Actifs", "Aktiv", "Activos", "Attivi", "Ativos")
        add(.runtimeCachesAndThumbnailsSafeToRemoveRecreatedAutomatically, "应用运行期缓存与缩略图（可安全清理，重新打开会自动重建）", "應用程式執行期快取與縮圖（可安全清理，重新打開會自動重建）", "Runtime caches and thumbnails (safe to remove; recreated automatically)", "実行時キャッシュとサムネイル（安全に削除可能・再起動時に自動生成）", "런타임 캐시 및 썸네일 (안전하게 삭제 가능하며 재실행 시 자동 생성됨)",
            "Caches d’exécution et vignettes (suppression sûre, recréés automatiquement)", "Laufzeit-Caches und Miniaturen (sicher löschbar, werden neu erstellt)", "Cachés de ejecución y miniaturas (seguro de eliminar, se recrean solos)", "Cache di runtime e miniature (rimozione sicura, ricreate automaticamente)", "Caches de execução e miniaturas (seguro remover; recriados automaticamente)")
        add(.safeItemsOnly, "仅勾选安全清理项", "僅勾選安全清理項", "Safe items only", "安全なキャッシュのみ選択", "안전한 항목만 선택",
            "Caches sûrs uniquement", "Nur sichere Elemente", "Solo elementos seguros", "Solo elementi sicuri", "Apenas itens seguros")
        add(.safeToRemoveRecreatedAutomaticallyBySystemOrApp, "可安全删除,系统或应用会自动重建", "可安全刪除,系統或應用會自動重建", "Safe to remove; recreated automatically by system or app", "安全に削除可能。システムまたはアプリが自動再作成します", "안전하게 삭제 가능. 시스템이나 앱에서 자동 재생성됩니다",
            "Suppression sûre : recréé automatiquement par le système ou l’app", "Sicher zu löschen; wird vom System oder der App neu erstellt", "Seguro de borrar; el sistema o la app lo recreará automáticamente", "Sicuro da rimuovere; ricreato automaticamente dal sistema o dall’app", "Seguro para remover; recriado automaticamente pelo sistema ou app")
        add(.safeTrashPutBackGuaranteeNote, "安全保证：所有项目默认移入废纸篓，可随时放回原处", "安全保證：所有項目默認移入廢紙簍，可隨時放回原處", "Safety guarantee: Items are moved to Trash and can be restored anytime", "安全保証：すべての項目はゴミ箱に移動され、いつでも元の場所に戻せます", "안전 보장: 모든 항목은 기본적으로 휴지통으로 이동되며 언제든 제자리로 되돌릴 수 있습니다",
            "Garantie de sécurité : éléments mis à la Corbeille et restaurables", "Sicherheitsgarantie: Alle Elemente werden in den Papierkorb gelegt und sind wiederherstellbar", "Garantía de seguridad: los elementos se mueven a la Papelera y se pueden restaurar", "Garanzia di sicurezza: gli elementi vanno nel Cestino e sono sempre ripristinabili", "Garantia de segurança: os itens vão para o Lixo e podem ser restaurados a qualquer momento")
        add(.safelyRestartFinderAndDockDesc, "安全重启 Finder 与 Dock 进程，解决桌面窗口卡顿、Mission Control 掉帧或外接盘不显示。", "安全重啟 Finder 與 Dock 進程，解決桌面窗口卡頓、Mission Control 掉幀或外接盤不顯示。", "Safely restart Finder and Dock to fix unresponsive windows, desktop icons, or Mission Control lag.", "Finder と Dock を安全に再起動し、デスクトップの操作遅延や外部ディスクの非表示を解消します。", "Finder와 Dock 프로세스를 안전하게 재시작하여 데스크탑 멈춤이나 외장 드라이브 미인식 문제를 해결합니다.",
            "Redémarrez le Finder et le Dock en toute sécurité pour corriger les lenteurs de fenêtres et de Mission Control.", "Startet Finder und Dock sicher neu, um träge Fenster, Schreibtischsymbole oder Ruckeln zu beheben.", "Reinicie el Finder y el Dock de forma segura para solucionar bloqueos de ventanas o Mission Control.", "Riavvia in sicurezza Finder e Dock per risolvere finestre bloccate o lentezza di Mission Control.", "Reinicie o Finder e o Dock com segurança para corrigir janelas travadas ou lentidão no Mission Control.")
        add(.safetyCaution, "注意", "注意", "Caution", "確認推奨", "확인 필요",
            "À vérifier", "Prüfen", "Revisar", "Attenzione", "Atenção")
        add(.safetyProtected, "系统保护", "系統保護", "Protected", "保護済み", "보호됨",
            "Protégé", "Geschützt", "Protegido", "Protetto", "Protegido")
        add(.safetyReview, "需确认", "需確認", "Review", "要確認", "확인 필요",
            "À vérifier", "Prüfen", "Revisar", "Da verificare", "Revisar")
        add(.safetyRisky, "谨慎", "謹慎", "Careful", "慎重", "주의",
            "Prudence", "Vorsicht", "Precaución", "Cautela", "Cuidado")
        add(.safetySafe, "安全", "安全", "Safe", "安全", "안전",
            "Sûr", "Sicher", "Seguro", "Sicuro", "Seguro")
        add(.samplingHardwareStatusPrompt, "正在采样硬件状态…", "正在取樣硬體狀態…", "Sampling hardware telemetry…", "ハードウェア状態をサンプリング中…", "하드웨어 상태 샘플링 중…",
            "Échantillonnage de l'état matériel…", "Hardware-Telemetrie wird erfasst…", "Muestreando telemetría de hardware…", "Campionamento dello stato hardware…", "Amostrando telemetria de hardware…")
        add(.sandboxedAppContainerIncludesSandboxedDocumentsAndUserData, "沙盒应用独立数据目录（含沙盒内文档与用户数据）", "沙盒應用獨立資料目錄（含沙盒內文檔與使用者資料）", "Sandboxed app container (includes sandboxed documents and user data)", "サンドボックスアプリの個別データディレクトリ（書類とユーザーデータを含む）", "샌드박스 앱 독립 데이터 디렉토리 (샌드박스 내 문서 및 사용자 데이터 포함)",
            "Conteneur d’application sandboxée (inclut documents et données utilisateur)", "Isolierter Sandbox-App-Container (enthält Dokumente und Benutzerdaten)", "Contenedor de app aislada (incluye documentos y datos del usuario)", "Container dell’app in sandbox (include documenti e dati utente)", "Contêiner de app isolado (inclui documentos e dados do usuário)")
        add(.sandboxedAppContainerStoresSettingsPluginsWorkspaceDataAndLocalState, "沙盒应用独立容器（含应用配置、插件、工作区数据与本地状态）", "沙盒應用程式獨立容器（含應用設定、外掛、工作區資料與本機狀態）", "Sandboxed app container (stores settings, plugins, workspace data, and local state)", "サンドボックスコンテナ（設定、プラグイン、ワークスペースデータを保存）", "샌드박스 앱 컨테이너 (앱 설정, 플러그인, 작업 공간 데이터 및 로컬 상태 포함)",
            "Conteneur sandbox (réglages, extensions, données de travail et état local)", "Sandbox-Container (Einstellungen, Plug-ins, Arbeitsbereichsdaten)", "Contenedor sandbox (ajustes, plugins, datos de trabajo y estado local)", "Contenitore sandbox (impostazioni, plugin, dati spazio di lavoro)", "Contêiner sandbox (configurações, plugins, dados de trabalho e estado local)")
        add(.savedWindowDimensionsAndScrollPositionsFromLastExit, "上次退出时的窗口尺寸与滚动位置快照", "上次退出時的窗口尺寸與滾動位置快照", "Saved window dimensions and scroll positions from last exit", "前回終了時のウィンドウサイズとスクロール位置のスナップショット", "마지막 종료 시 창 크기 및 스크롤 위치 스냅샷",
            "Dimensions des fenêtres et positions de défilement lors de la dernière fermeture", "Gespeicherte Fenstermaße und Scrollpositionen vom letzten Schließen", "Dimensiones de ventana y posiciones de desplazamiento del último cierre", "Dimensioni delle finestre e posizioni di scorrimento dell’ultima chiusura", "Dimensões da janela e posições de rolagem do último fechamento")
        add(.savedWindowRestorationStateRecordsOpenWindowsAndScrollPositionsSafeToRemove, "窗口恢复状态快照（记录上次退出时的打开窗口与滚动位置，可安全清理）", "視窗恢復狀態快照（記錄上次結束時開啟的視窗與捲動位置，可安全清理）", "Saved window restoration state (records open windows and scroll positions; safe to remove)", "ウィンドウ復元スナップショット（前回終了時のウィンドウ位置を記録・安全に削除可能）", "창 복원 상태 스냅샷 (마지막 종료 시 열린 창 및 스크롤 위치 기록, 안전하게 삭제 가능)",
            "État de restauration des fenêtres (suppression sûre)", "Gespeicherter Fensterstatus beim Beenden (sicher löschbar)", "Estado guardado de restauración de ventanas (seguro de eliminar)", "Stato salvato di ripristino delle finestre (rimozione sicura)", "Estado salvo de restauração de janelas (seguro remover)")
        add(.scanConfig, "扫描配置", "掃描配置", "Scanning", "スキャン設定", "스캔 설정",
            "Analyse", "Scannen", "Escaneo", "Scansione", "Escaneamento")
        add(.scanExclusionWhitelistSubtitle, "前缀感知递归安全保护：加入白名单的目录及文件在全盘扫描与清理中均会被绝对跳过", "前綴感知遞迴安全保護：加入白名單的目錄及檔案在全盤掃描與清理中均會被絕對略過", "Prefix-aware recursive protection: folders and files in the whitelist will never be touched", "プレフィックス感知型保護：リスト内のフォルダやファイルはスキャンと削除から完全に除外されます", "접두사 인식 재귀 보호: 화이트리스트에 추가된 폴더와 파일은 스캔 및 정리 대상에서 완전히 제외됩니다",
            "Protection récursive sécurisée : les dossiers et fichiers de la liste blanche ne seront jamais touchés", "Präfix-basierter Schutz: Dateien und Ordner auf der Whitelist werden niemals gelöscht", "Protección recursiva segura: las carpetas y archivos de la lista blanca nunca se tocarán", "Protezione ricorsiva sicura: le cartelle e i file in whitelist non verranno mai toccati", "Proteção recursiva segura: pastas e arquivos na lista branca nunca serão modificados")
        add(.scanExclusionWhitelistTitle, "扫描排除白名单", "掃描排除白名單", "Scan Exclusion Whitelist", "スキャン除外ホワイトリスト", "스캔 제외 화이트리스트",
            "Liste blanche d’exclusion de scan", "Scan-Ausschluss-Whitelist", "Lista blanca de exclusión", "Whitelist di esclusione scansione", "Lista Branca de Exclusão de Escaneamento")
        add(.scanOrphanLeftoversPrompt, "扫描卸载残留", "掃描解除安裝殘留", "Scanning Uninstallation Leftovers", "アンインストール残骸をスキャン中", "삭제 잔여물 스캔 중",
            "Recherche des résidus de désinstallation", "Suche nach Deinstallationsüberresten", "Buscando restos de desinstalación", "Ricerca dei residui di disinstallazione", "Procurando resíduos de desinstalação")
        add(.scanner32BitApps, "32 位应用程序", "32 位應用程式", "32-Bit Applications", "32 ビットアプリケーション", "32비트 응용 프로그램",
            "Applications 32 bits", "32-Bit-Programme", "Aplicaciones de 32 bits", "Applicazioni a 32 bit", "Aplicativos de 32 Bits")
        add(.scannerAiClutterFiles, "AI 垃圾文件", "AI 暫存檔", "AI Tools & Caches", "AIツールキャッシュ", "AI 도구 캐시",
            "Caches d’outils IA", "KI-Tool-Caches", "Caché de herramientas IA", "Cache strumenti IA", "Caches de Ferramentas IA")
        add(.scannerApfsPurgeableSpace, "APFS 可清除空间", "APFS 可清除空間", "APFS Purgeable Space", "APFS パージ可能領域", "APFS 확보 가능 공간",
            "Espace purgeable APFS", "APFS Freigebbarer Speicherplatz", "Espacio purgable APFS", "Spazio eliminabile APFS", "Espaço Purgável APFS")
        add(.scannerAppLeftovers, "程序残留", "程式殘留", "Application Leftovers", "アプリケーションの残り物", "응용 프로그램 찌꺼기",
            "Restes d'applications", "Programmreste", "Restos de aplicaciones", "Residui di applicazioni", "Restos de aplicativos")
        add(.scannerAppStoreCache, "App Store 下载缓存", "App Store 下載快取", "App Store Download Cache", "App Store ダウンロードキャッシュ", "App Store 다운로드 캐시",
            "Cache de téléchargement App Store", "App Store Download-Cache", "Caché de descargas de App Store", "Cache download App Store", "Cache de Downloads da App Store")
        add(.scannerAppTargetedCache, "应用靶向缓存", "應用靶向快取", "Targeted App Caches", "特定アプリのキャッシュ", "타겟 앱 캐시",
            "Caches ciblés d’applications", "Gezielte App-Caches", "Cachés de apps dirigidas", "Cache mirata delle app", "Caches de Apps Direcionados")
        add(.scannerAppUpdaters, "应用更新器", "應用更新器", "App Updaters", "アプリ更新インストーラ", "앱 업데이트 파일",
            "Programmes de mise à jour", "App-Updater", "Actualizadores de apps", "Programmi di aggiornamento", "Atualizadores de Apps")
        add(.scannerBrokenLoginItems, "损坏的登录项", "損壞的登錄項", "Broken Login Items", "破損した起動項目", "손상된 시작 프로그램",
            "Éléments de démarrage corrompus", "Beschädigte Anmeldeobjekte", "Elementos de inicio dañados", "Elementi di avvio danneggiati", "Itens de Inicialização Corrompidos")
        add(.scannerBrokenPreferences, "损坏的偏好设置文件", "損壞的偏好設定檔案", "Broken Preferences", "破損した環境設定ファイル", "손상된 환경설정 파일",
            "Fichiers de préférences corrompus", "Beschädigte Einstellungsdateien", "Archivos de preferencias dañados", "File delle preferenze danneggiati", "Arquivos de Preferências Corrompidos")
        add(.scannerDeletedUsers, "已删除用户", "已刪除使用者", "Deleted Users", "削除済みユーザー", "삭제된 사용자",
            "Utilisateurs supprimés", "Gelöschte Benutzer", "Usuarios eliminados", "Utenti eliminati", "Usuários Excluídos")
        add(.scannerDockerCache, "Docker 与容器缓存", "Docker 與容器快取", "Docker & Container Cache", "Docker とコンテナキャッシュ", "Docker 및 컨테이너 캐시",
            "Caches Docker et conteneurs", "Docker- & Container-Cache", "Caché de Docker y contenedores", "Cache di Docker e container", "Cache do Docker e Contêineres")
        add(.scannerDocumentVersions, "文稿版本", "文稿版本", "Document Versions", "書類のバージョン履歴", "문서 버전",
            "Versions de documents", "Dokumentversionen", "Versiones de documentos", "Versioni dei documenti", "Versões de Documentos")
        add(.scannerElectronAppCache, "Electron 应用缓存", "Electron 應用快取", "Electron App Cache", "Electron アプリキャッシュ", "Electron 앱 캐시",
            "Caches d’apps Electron", "Electron-App-Caches", "Cachés de apps Electron", "Cache di app Electron", "Caches de Apps Electron")
        add(.scannerEmptyTrashBinsDesc, "清空各驱动器上的废纸篓文件以恢复磁盘可用空间。", "清空各驅動器上的廢紙簍文件以恢複磁盤可用空間。", "Empty Trash across all drives to reclaim available storage space.", "すべてのドライブのゴミ箱を空にして空き容量を回復します。", "모든 드라이브의 휴지통을 비워 디스크 여유 공간을 확보합니다.",
            "Videz la Corbeille de tous les disques pour récupérer de l'espace.", "Leeren Sie den Papierkorb aller Laufwerke, um Speicherplatz freizugeben.", "Vacíe la Papelera de todas las unidades para recuperar espacio libre.", "Svuota il Cestino di tutte le unità per recuperare spazio su disco.", "Esvazie a Lixeira de todas as unidades para recuperar espaço em disco.")
        add(.scannerGradleCache, "Gradle 缓存", "Gradle 快取", "Gradle Cache", "Gradle キャッシュ", "Gradle 캐시",
            "Cache Gradle", "Gradle-Cache", "Caché de Gradle", "Cache di Gradle", "Cache do Gradle")
        add(.scannerHomebrewCache, "Homebrew 缓存", "Homebrew 快取", "Homebrew Cache", "Homebrew キャッシュ", "Homebrew 캐시",
            "Cache Homebrew", "Homebrew-Cache", "Caché de Homebrew", "Cache di Homebrew", "Cache do Homebrew")
        add(.scannerIosDeviceBackups, "iOS 设备备份", "iOS 裝置備份", "iOS Device Backups", "iOSデバイスバックアップ", "iOS 기기 백업",
            "Sauvegardes iOS", "iOS-Geräte-Backups", "Copias de seguridad iOS", "Backup dispositivi iOS", "Backups de Dispositivos iOS")
        add(.scannerLanguageFiles, "语言文件", "語言檔案", "Language Files", "言語ファイル", "언어 파일",
            "Fichiers de langue", "Sprachdateien", "Archivos de idioma", "File di lingua", "Arquivos de idioma")
        add(.scannerLanguageFilesTitle, "语言文件", "語言文件", "Language Files", "言語ファイル", "언어 파일",
            "Fichiers de langue", "Sprachdateien", "Archivos de idioma", "File di lingua", "Arquivos de idioma")
        add(.scannerLocalAiModels, "本地模型", "本機模型", "Local Models", "ローカルモデル", "로컬 모델",
            "Modèles locaux", "Lokale Modelle", "Modelos locales", "Modelli locali", "Modelos locais")
        add(.scannerLocalTrashBins, "本机废纸篓", "本機垃圾桶", "Local Trash Bins", "ローカルゴミ箱", "로컬 휴지통",
            "Corbeille locale", "Lokaler Papierkorb", "Papelera local", "Cestino locale", "Lixeira Local")
        add(.scannerSymbolicationCache, "符号化缓存", "符號化快取", "Symbolication Cache", "シンボル化キャッシュ", "기호화 캐시",
            "Cache de symbolisation", "Symbolisierungs-Cache", "Caché de simbolización", "Cache di simbolizzazione", "Cache de Simbolização")
        add(.scannerSystemCacheFiles, "系统缓存文件", "系統快取檔案", "System Cache Files", "システムキャッシュファイル", "시스템 캐시 파일",
            "Fichiers cache système", "System-Cache-Dateien", "Archivos de caché del sistema", "File di cache di sistema", "Arquivos de cache do sistema")
    }

}
