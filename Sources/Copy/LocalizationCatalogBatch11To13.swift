import Foundation

extension LocalizationCatalog {
    static func populateBatch11(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.scannerSystemCaches, "系统缓存文件", "系統快取檔案", "System Cache Files", "システムキャッシュファイル", "시스템 캐시 파일",
            "Fichiers de cache système", "System-Cachedateien", "Archivos de caché del sistema", "File di cache di sistema", "Arquivos de Cache do Sistema")
        add(.scannerSystemLogFiles, "系统日志文件", "系統記錄檔案", "System Log Files", "システムログファイル", "시스템 로그 파일",
            "Fichiers journaux système", "Systemprotokolldateien", "Archivos de registro del sistema", "File di log di sistema", "Arquivos de log do sistema")
        add(.scannerSystemLogs, "系统日志文件", "系統日誌檔案", "System Log Files", "システムログファイル", "시스템 로그 파일",
            "Fichiers journaux système", "System-Protokolldateien", "Archivos de registro del sistema", "File di log di sistema", "Arquivos de Log do Sistema")
        add(.scannerTrashBins, "废纸篓", "垃圾桶", "Trash Bins", "ゴミ箱", "휴지통",
            "Corbeille", "Papierkorb", "Papelera", "Cestino", "Lixo")
        add(.scannerUniversalBinariesTitle, "额外二进制文件", "額外二進製文件", "Universal Binaries", "余剰バイナリ", "불필요한 바이너리",
            "Binaires superflus", "Zusätzliche Binärdateien", "Binarios adicionales", "Binari aggiuntivi", "Binários adicionais")
        add(.scannerUnusedDiskImages, "未使用的磁盘映像", "未使用的磁碟映像", "Unused Disk Images", "未使用のディスクイメージ", "미사용 디스크 이미지",
            "Images disque inutilisées", "Ungenutzte Disk-Images", "Imágenes de disco sin usar", "Immagini disco inutilizzate", "Imagens de Disco Não Usadas")
        add(.scannerUserCacheFiles, "用户缓存文件", "使用者快取檔案", "User Cache Files", "ユーザーキャッシュファイル", "사용자 캐시 파일",
            "Fichiers de cache utilisateur", "Benutzer-Cachedateien", "Archivos de caché de usuario", "File di cache utente", "Arquivos de Cache do Usuário")
        add(.scannerUserLogFiles, "用户日志文件", "使用者記錄檔案", "User Log Files", "ユーザーログファイル", "사용자 로그 파일",
            "Fichiers journaux utilisateur", "Benutzerprotokolldateien", "Archivos de registro de usuario", "File di log utente", "Arquivos de log do usuário")
        add(.scannerUserLogs, "用户日志文件", "使用者日誌檔案", "User Log Files", "ユーザーログファイル", "사용자 로그 파일",
            "Fichiers journaux utilisateur", "Benutzer-Protokolldateien", "Archivos de registro de usuario", "File di log utente", "Arquivos de Log do Usuário")
        add(.scannerXcodeJunk, "Xcode 垃圾", "Xcode 垃圾", "Xcode Junk", "Xcode不要データ", "Xcode 정크",
            "Fichiers Xcode", "Xcode-Müll", "Basura de Xcode", "File inutili Xcode", "Lixo do Xcode")
        add(.scanning, "扫描中", "掃描中", "Scanning", "スキャン中", "스캔 중",
            "Analyse en cours", "Wird gescannt", "Escaneando", "Scansione in corso", "Escaneando")
        add(.scanningAppLeftovers, "扫描应用残留文件", "掃描應用程式殘留檔案", "Scanning application leftovers", "アプリの残骸ファイルをスキャン中", "응용 프로그램 잔여 파일 스캔 중",
            "Recherche des fichiers résiduels", "Anwendungsüberreste scannen", "Escaneando archivos residuales", "Scansione file residui", "Verificando arquivos residuais")
        add(.scanningCachesAndJunkTitle, "正在扫描缓存与垃圾…", "正在掃描快取與垃圾…", "Scanning caches and junk…", "キャッシュと不要ファイルをスキャン中…", "캐시 및 정크 스캔 중…",
            "Analyse des caches…", "Caches werden gescannt…", "Analizando cachés…", "Scansione cache in corso…", "Analisando caches…")
        add(.scanningEntireDiskEllipsis, "正在全盘扫描中…", "正在全盤掃描中…", "Scanning entire disk…", "ディスク全体をスキャン中…", "전체 디스크 검사 중…",
            "Analyse complète du disque…", "Scanne gesamte Festplatte…", "Escaneando el disco completo…", "Scansione dell'intero disco in corso…", "Escaneando todo o disco…")
        add(.scanningForCleanableCachesAndClutter, "正在查找可清理缓存与冗余文件…", "正在尋找可清理快取與冗餘檔案…", "Scanning for cleanable caches and clutter…", "クリーンアップ可能なキャッシュを検索中…", "정리 가능한 캐시 및 정크 파일 검색 중…",
            "Recherche des fichiers inutiles…", "Suche nach bereinigbaren Caches…", "Buscando caché y archivos innecesarios…", "Ricerca cache e file inutili…", "Procurando caches e arquivos desnecessários…")
        add(.scanningForSpaceWastingFilesOnYourStorage, "搜寻占用存储空间的冗余文件。", "搜尋佔用儲存空間的冗餘檔案。", "Scanning for space-wasting files on your storage.", "容量を浪費している不要ファイルを検索しています。", "저장 공간을 낭비하는 불필요한 파일을 검색합니다.",
            "Recherche de fichiers encombrant votre stockage.", "Scanne nach speicherfressenden redundanten Dateien.", "Buscando archivos que desperdician espacio.", "Scansione dei file che sprecano spazio sul disco.", "Procurando arquivos que ocupam espaço no armazenamento.")
        add(.scanningInstalledApplicationsAndAssociatedDirectories, "正在扫描已安装应用程序与关联目录…", "正在掃描已安裝應用程式與關聯目錄…", "Scanning installed applications and associated directories…", "導入済みアプリと関連フォルダをスキャン中…", "설치된 응용 프로그램 및 연관 디렉토리 스캔 중…",
            "Analyse des applications installées et des répertoires associés…", "Scanne installierte Programme und zugehörige Verzeichnisse…", "Escaneando aplicaciones instaladas y directorios asociados…", "Scansione applicazioni installate e cartelle associate…", "Escaneando aplicativos instalados e diretórios associados…")
        add(.scanningModuleTitleFormat, "正在扫描 %@…", "正在掃描 %@…", "Scanning %@…", "%@ をスキャン中…", "%@ 검사 중…",
            "Analyse de %@…", "Scanne %@…", "Escaneando %@…", "Scansione di %@ in corso…", "Escaneando %@…")
        add(.scanningSimilarPhotosPrompt, "扫描图库与磁盘中的相似照片…", "掃描圖庫與磁碟中的相似照片…", "Scanning for similar photos in library and storage…", "ライブラリとストレージ内の類似写真をスキャン中…", "사진 보관함 및 저장 공간의 유사 사진 스캔 중…",
            "Analyse des photos similaires dans la photothèque et le disque…", "Suche nach ähnlichen Fotos in Fotomediathek und Speicher…", "Buscando fotos similares en la fototeca y el disco…", "Scansione foto simili nella libreria e nel disco…", "Procurando fotos semelhantes na fototeca e no armazenamento…")
        add(.scanningStartupItemsAndBackgroundServices, "正在扫描开机启动项与后台服务…", "正在掃描開機啟動項與後台服務…", "Scanning startup items and background services…", "起動項目とバックグラウンドサービスをスキャン中…", "시작 프로그램 및 백그라운드 서비스 스캔 중…",
            "Analyse des éléments d’ouverture et services d’arrière-plan…", "Scanne Anmeldeobjekte und Hintergrunddienste…", "Escaneando elementos de inicio y servicios en segundo plano…", "Scansione elementi di avvio e servizi in background…", "Escaneando itens de inicialização e serviços em segundo plano…")
        add(.scanningSystemAppCaches, "正在检索系统与应用缓存目录…", "正在檢索系統與應用快取目錄…", "Searching system and app cache directories…", "システムおよびアプリのキャッシュを検索中…", "시스템 및 앱 캐시 디렉토리 검색 중…",
            "Recherche des répertoires de caches système et d’applications…", "Suche nach System- und App-Cache-Verzeichnissen…", "Buscando directorios de caché del sistema y de apps…", "Ricerca cartelle di cache di sistema e applicazioni…", "Buscando diretórios de cache do sistema e de aplicativos…")
        add(.scanningThresholds, "扫描阈值", "掃描門檻值", "Thresholds", "スキャン閾値", "스캔 임계값",
            "Seuils d’analyse", "Schwellenwerte", "Umbrales", "Soglie", "Limites")
        add(.scanningYourMac, "正在扫描您的 Mac…", "正在掃描您的 Mac…", "Scanning your Mac…", "Mac をスキャン中…", "Mac을 스캔하는 중…",
            "Analyse de votre Mac en cours…", "Ihr Mac wird gescannt…", "Escaneando tu Mac…", "Scansione del Mac in corso…", "Escaneando seu Mac…")
        add(.scheduleAndPermissions, "定时与权限", "排程與權限", "Schedule & Access", "スケジュールと権限", "예약 및 권한",
            "Planification et accès", "Zeitplan & Zugriff", "Horario y permisos", "Pianificazione e accesso", "Agendamento e Acesso")
        add(.scheduleConfig, "定时配置", "定時配置", "Schedule", "スケジュール設定", "예약 설정",
            "Planification", "Zeitplan", "Programación", "Pianificazione", "Agendamento")
        add(.scopeCurrentFolder, "当前目录", "目前目錄", "Current Folder", "現在のフォルダ", "현재 폴더",
            "Dossier actuel", "Aktueller Ordner", "Carpeta actual", "Cartella attuale", "Pasta Atual")
        add(.scopeGlobalAgentDesc, "所有用户登录时运行的代理程序。", "所有使用者登入時運行的代理程式。", "Launch agent executed when any user logs in.", "すべてのユーザーのログイン時に実行されるエージェント。", "모든 사용자 로그인 시 실행되는 전역 에이전트 프로그램입니다.",
            "Agent de lancement exécuté pour tous les utilisateurs.", "Startagent, der bei Anmeldung jedes Benutzers ausgeführt wird.", "Agente de inicio ejecutado para cualquier usuario.", "Agente avviato all'accesso di qualsiasi utente.", "Agente de inicialização executado para qualquer usuário.")
        add(.scopeLargestFiles, "最大文件", "最大檔案", "Largest Files", "最大ファイル", "가장 큰 파일",
            "Plus gros fichiers", "Größte Dateien", "Archivos más grandes", "File più grandi", "Maiores Arquivos")
        add(.scopeSystemDaemonDesc, "在后台常驻运行的系统服务。", "在後台常駐運行的系統服務。", "System daemon running persistently in the background.", "バックグラウンドで常駐実行されるシステムデーモン。", "백그라운드에서 상주 실행되는 시스템 데몬 서비스입니다.",
            "Démon système exécuté en arrière-plan en continu.", "System-Daemon, der dauerhaft im Hintergrund läuft.", "Demonio del sistema ejecutado continuamente en segundo plano.", "Daemon di sistema sempre in esecuzione in background.", "Daemon do sistema executado continuamente em segundo plano.")
        add(.scopeUserAgentDesc, "当前用户登录时运行的代理程序。", "目前使用者登入時運行的代理程式。", "Launch agent executed when the current user logs in.", "現在のユーザーがログインしたときに実行されるエージェント。", "현재 사용자가 로그인할 때 실행되는 에이전트 프로그램입니다.",
            "Agent de lancement exécuté à la connexion de l'utilisateur actuel.", "Startagent, der beim Anmelden des aktuellen Benutzers ausgeführt wird.", "Agente de inicio ejecutado al iniciar sesión el usuario actual.", "Agente avviato all'accesso dell'utente corrente.", "Agente de inicialização executado no login do usuário atual.")
        add(.scopeWholeDisk, "整个磁盘", "整個磁碟", "Entire Disk", "ディスク全体", "전체 디스크",
            "Disque entier", "Gesamte Festplatte", "Todo el disco", "Intero disco", "Disco inteiro")
        add(.screenPrefix, "屏幕", "螢幕", "Display", "画面", "화면",
            "Écran", "Bildschirm", "Pantalla", "Schermo", "Tela")
        add(.searchAppsOrPathPlaceholder, "搜索应用或路径…", "搜索應用或路徑…", "Search apps or paths…", "アプリまたはパスを検索…", "앱 또는 경로 검색…",
            "Rechercher des applications ou chemins…", "Programme oder Pfade suchen…", "Buscar apps o rutas…", "Cerca app o percorsi…", "Buscar apps ou caminhos…")
        add(.searchAppsPlaceholder, "搜索应用", "搜尋應用程式", "Search apps", "アプリを検索", "앱 검색",
            "Rechercher une app", "Apps suchen", "Buscar apps", "Cerca app", "Buscar apps")
        add(.searchCityNamePlaceholder, "输入城市名 (如 广州 / Beijing / Tokyo)…", "輸入城市名 (如 廣州 / Beijing / Tokyo)…", "Enter city name (e.g., Paris / Tokyo / New York)…", "都市名を入力（例：東京 / 大阪 / ロンドン）…", "도시 이름 입력 (예: 서울 / 도쿄 / 뉴욕)…",
            "Entrez le nom de la ville (ex. Paris / Tokyo)…", "Stadtname eingeben (z. B. Berlin / Zürich / Tokyo)…", "Introduzca el nombre de la ciudad (ej. Madrid / Tokio)…", "Inserisci il nome della città (es. Roma / Milano)…", "Digite o nome da cidade (ex: São Paulo / Lisboa)…")
        add(.searchLeftoversPlaceholder, "搜索残留项", "搜尋殘留檔案", "Search leftovers", "残存ファイルを検索", "잔여 파일 검색",
            "Rechercher des résidus", "Reste suchen", "Buscar residuos", "Cerca residui", "Buscar resíduos")
        add(.searchNoResultsRetryPrompt, "请更换关键词并重试。", "請更換關鍵詞並重試。", "Please try searching with different keywords.", "別のキーワードで再検索してください。", "다른 검색어로 다시 시도해 보세요.",
            "Veuillez essayer avec d'autres mots-clés.", "Bitte versuchen Sie es mit anderen Suchbegriffen.", "Intente buscar con palabras clave diferentes.", "Prova a cercare con parole chiave diverse.", "Tente pesquisar com palavras-chave diferentes.")
        add(.searchProcessNameOrPidPlaceholder, "搜索进程名称或 PID…", "搜索進程名稱或 PID…", "Search process name or PID…", "プロセス名または PID を検索…", "프로세스 이름 또는 PID 검색…",
            "Rechercher un processus ou un PID…", "Prozessname oder PID suchen…", "Buscar nombre de proceso o PID…", "Cerca nome processo o PID…", "Pesquisar nome do processo ou PID…")
        add(.searchProcessPlaceholder, "搜索进程名称或 PID…", "搜尋程序名稱或 PID…", "Search process name or PID…", "プロセス名またはPIDを検索…", "프로세스 이름 또는 PID 검색…",
            "Rechercher un processus ou un PID…", "Prozessname oder PID suchen…", "Buscar nombre de proceso o PID…", "Cerca nome processo o PID…", "Buscar nome do processo ou PID…")
        add(.searchStartupItemsPlaceholder, "搜索启动项或服务…", "搜尋啟動項或服務…", "Search startup items or services…", "起動項目またはサービスを検索…", "시작 프로그램 또는 서비스 검색…",
            "Rechercher des éléments d’ouverture ou services…", "Startobjekte oder Dienste suchen…", "Buscar ítems de inicio o servicios…", "Cerca elementi di avvio o servizi…", "Buscar itens de inicialização ou serviços…")
        add(.searchingAppsAndLeftoversPrompt, "正在查找应用程序和残留文件。", "正在查找應用程序和殘留文件。", "Searching for applications and leftover files.", "アプリケーションと残留ファイルを検索中。", "애플리케이션 및 잔여 파일을 찾는 중입니다.",
            "Recherche des applications et des fichiers résiduels.", "Suche nach Anwendungen und Restdateien.", "Buscando aplicaciones y archivos residuales.", "Ricerca di applicazioni e file residui in corso.", "Procurando aplicativos e arquivos residuais.")
        add(.searchingDuplicatesAndUnneededFilesPrompt, "正在查找重复文件以及可能不需要的文件…", "正在查找重複文件以及可能不需要的文件…", "Searching for duplicate files and unneeded clutter…", "重複ファイルや不要なファイルを検索中…", "중복 파일 및 불필요한 파일을 찾는 중…",
            "Recherche des doublons et des fichiers inutiles…", "Suche nach Duplikaten und unbenötigten Dateien…", "Buscando archivos duplicados e innecesarios…", "Ricerca di duplicati e file non necessari in corso…", "Procurando arquivos duplicados e desnecessários…")
        add(.sectionAppLeftoversCleanup, "应用残留清理", "應用殘留清理", "App Leftovers Cleanup", "アプリ残留物の削除", "앱 잔여물 정리",
            "Nettoyage des résidus d'applications", "App-Reste bereinigen", "Limpieza de residuos de apps", "Pulizia residui delle app", "Limpeza de resíduos de apps")
        add(.sectionAppUninstall, "应用程序卸载", "應用程序卸載", "App Uninstall", "アプリのアンインストール", "애플리케이션 제거",
            "Désinstallation d'applications", "App-Deinstallation", "Desinstalación de apps", "Disinstallazione app", "Desinstalação de apps")
        add(.sectionLargeFiles, "大型文件", "大型文件", "Large Files", "大容量ファイル", "대용량 파일",
            "Fichiers volumineux", "Große Dateien", "Archivos grandes", "File grandi", "Arquivos grandes")
        add(.sectionLargeFoldersOverview, "大文件夹概览", "大文件夾概覽", "Large Folders Overview", "大容量フォルダの概要", "대용량 폴더 개요",
            "Aperçu des gros dossiers", "Übersicht großer Ordner", "Resumen de carpetas grandes", "Panoramica delle cartelle grandi", "Visão geral de pastas grandes")
        add(.sectionStandaloneLargeFiles, "独立大文件", "獨立大文件", "Standalone Large Files", "個別の大型ファイル", "독립 대용량 파일",
            "Fichiers volumineux isolés", "Einzelne große Dateien", "Archivos grandes individuales", "Singoli file di grandi dimensioni", "Arquivos grandes individuais")
        add(.sectionStorageDistributionMap, "存储空间可视化分布图", "存儲空間可視化分布圖", "Storage Visual Distribution Map", "ストレージ空間の視覚的分布マップ", "저장 공간 시각적 분포도",
            "Carte visuelle de répartition du stockage", "Visuelle Speicherverteilungskarte", "Mapa de distribución visual del almacenamiento", "Mappa visiva di distribuzione dello spazio", "Mapa visual de distribuição de armazenamento")
        add(.securitySandboxProtectionNote, "安全保障：系统级沙盒保护，清理项默认移至废纸篓且可随时还原", "安全保障：系統級沙盒保護，清理項默認移至廢紙簍且可隨時還原", "Security guarantee: Sandbox protection, items moved to Trash by default and can be restored anytime", "安全保証：システム保護機能により、クリーンアップ対象はゴミ箱に移動され、いつでも復元可能です", "안전 보장: 시스템 보호를 준수하며 정리 항목은 휴지통으로 이동되어 언제든 복원할 수 있습니다",
            "Garantie de sécurité : Protection sandbox, éléments déplacés vers la Corbeille et restaurables à tout moment", "Sicherheitsgarantie: Sandbox-Schutz, Elemente werden in den Papierkorb verschoben und sind jederzeit wiederherstellbar", "Garantía de seguridad: Protección de sandbox, elementos movidos a la Papelera y restaurables en cualquier momento", "Garanzia di sicurezza: Protezione sandbox, elementi spostati nel Cestino e ripristinabili in qualsiasi momento", "Garantia de segurança: Proteção sandbox, itens movidos para o Lixo por padrão e restauráveis a qualquer momento")
        add(.seeFoldersConsumingMostDiskSpace, "查看占用磁盘空间最多的核心大文件夹", "檢視佔用磁碟空間最多的核心大資料夾", "Inspect top folders consuming the most storage", "最もディスク容量を消費しているフォルダを確認", "디스크 공간을 가장 많이 차지하는 핵심 폴더 확인",
            "Inspectez les dossiers qui occupent le plus d'espace", "Wichtigste Ordner mit dem größten Speicherverbrauch prüfen", "Inspecciona las carpetas principales que más espacio consumen", "Esamina le cartelle principali che occupano più spazio", "Inspecione as principais pastas que mais consomem espaço")
        add(.selected, "已选择", "已選擇", "Selected", "選択済み", "선택됨",
            "Sélectionné", "Ausgewählt", "Seleccionado", "Selezionato", "Selecionado")
        add(.selectedCountFormat, "已选择 %d 项", "已選擇 %d 項", "%d items selected", "%d 件を選択中", "%d개 항목 선택됨",
            "%d éléments sélectionnés", "%d Elemente ausgewählt", "%d elementos seleccionados", "%d elementi selezionati", "%d itens selecionados")
        add(.selectedLeftoversSizeSummaryFormat, "已选 %d 项残留 · %@", "已選 %d 項殘留 · %@", "%d leftovers selected · %@", "%d 件の残留項目を選択中 · %@", "%d개 잔여 항목 선택됨 · %@",
            "%d résidus sélectionnés · %@", "%d Reste ausgewählt · %@", "%d residuales seleccionados · %@", "%d residui selezionati · %@", "%d itens residuais selecionados · %@")
        add(.selectedMaintenanceTasksCountFormat, "已选择 %d 项维护任务", "已選擇 %d 項維護任務", "%d maintenance tasks selected", "%d 件のメンテナンスタスクを選択中", "%d개 유지보수 작업 선택됨",
            "%d tâches de maintenance sélectionnées", "%d Wartungsaufgaben ausgewählt", "%d tareas de mantenimiento seleccionadas", "%d attività di manutenzione selezionate", "%d tarefas de manutenção selecionadas")
        add(.sensors, "传感器", "感測器", "Sensors", "センサー", "센서",
            "Capteurs", "Sensoren", "Sensores", "Sensori", "Sensores")
        add(.settings, "设置", "設定", "Settings", "設定", "설정",
            "Réglages", "Einstellungen", "Ajustes", "Impostazioni", "Ajustes")
        add(.settingsAddExclusionPathHint, "点击右上角按钮添加隐私目录、工程源代码或不希望被扫描的路径", "點擊右上角按鈕添加隱私目錄、工程源代碼或不希望被掃描的路徑", "Click the top-right button to add privacy folders, source code, or paths you wish to exclude from scans", "右上のボタンをクリックして、プライベートフォルダやソースコードなどの除外対象を追加します", "오른쪽 상단 버튼을 클릭하여 개인 폴더, 소스 코드 등 검사에서 제외할 경로를 추가하세요",
            "Cliquez en haut à droite pour ajouter des dossiers privés ou du code source à exclure", "Klicken Sie oben rechts, um private Ordner oder Quellcode vom Scan auszuschließen", "Haga clic en la esquina superior derecha para añadir carpetas o código fuente que no desee escanear", "Fai clic sul pulsante in alto a destra per aggiungere cartelle private o codice sorgente da escludere", "Clique no botão superior direito para adicionar pastas privadas ou códigos-fonte que deseja excluir da verificação")
        add(.settingsDaemonNotEnabled, "未启用后台定时守护", "未啟用後台定時守護", "Background scheduled daemon not enabled", "バックグラウンドデーモンは有効になっていません", "백그라운드 예약 데몬이 활성화되지 않음",
            "Démon d'arrière-plan non activé", "Hintergrund-Daemon nicht aktiviert", "Demonio en segundo plano no activado", "Demone in background non abilitato", "Daemon em segundo plano não ativado")
        add(.settingsDaemonReadyLaunchdManaged, "后台定时守护进程就绪 (系统 launchd 托管)", "後台定時守護進程就緒 (系統 launchd 托管)", "Background scheduled daemon ready (managed by launchd)", "バックグラウンドデーモン準備完了（launchd 管理下）", "백그라운드 예약 데몬 준비 완료 (launchd 관리)",
            "Démon d'arrière-plan prêt (géré par launchd)", "Hintergrund-Daemon bereit (verwaltet von launchd)", "Demonio en segundo plano listo (administrado por launchd)", "Demone in background pronto (gestito da launchd)", "Daemon em segundo plano pronto (gerenciado pelo launchd)")
        add(.settingsEllipsis, "设置…", "設定…", "Settings…", "設定…", "설정…",
            "Réglages…", "Einstellungen…", "Ajustes…", "Impostazioni…", "Ajustes…")
        add(.settingsEnableScheduledInspectionToggle, "启用定时健康巡检与提醒", "啟用定時健康巡檢與提醒", "Enable Scheduled Health Inspection & Reminders", "定期ヘルスチェックと通知を有効にする", "정기 상태 점검 및 알림 활성화",
            "Activer l'inspection périodique et les rappels", "Geplante Integritätsprüfung und Erinnerungen aktivieren", "Activar inspección de estado programada y recordatorios", "Abilita controllo periodico dello stato e promemoria", "Ativar inspeção periódica de integridade e lembretes")
        add(.settingsFdaGrantedStatusDesc, "系统安全防护已解除限制，可深度扫描 Safari 缓存、系统日志与容器残留", "系統安全防護已解除限製，可深度掃描 Safari 緩存、系統日誌與容器殘留", "System protections unlocked: complete scans available for Safari cache, system logs, and app containers", "システム保護の制限が解除され、Safari キャッシュ、ログ、コンテナ残留を深度スキャンできます", "보호 제한이 해제되어 Safari 캐시, 시스템 로그 및 컨테이너 잔여 파일을 심층 검사할 수 있습니다",
            "Protections déverrouillées : analyse complète des caches Safari, journaux et conteneurs", "Schutzbeschränkungen aufgehoben: Vollständiger Scan von Safari-Cache, Protokollen und Containern möglich", "Protecciones desbloqueadas: escaneo completo de caché de Safari, registros y contenedores", "Protezioni sbloccate: scansione completa di cache Safari, registri e container di app", "Proteções desbloqueadas: verificação profunda disponível para cache do Safari, logs e contêineres")
        add(.settingsFdaGrantedStatusTitle, "已获得完全磁盘访问权限 (FDA)", "已獲得完全磁盤訪問權限 (FDA)", "Full Disk Access (FDA) Granted", "フルディスクアクセス (FDA) 許可済み", "전체 디스크 접근 권한 (FDA) 부여됨",
            "Accès complet au disque (FDA) accordé", "Festplattenvollzugriff (FDA) gewährt", "Acceso total al disco (FDA) concedido", "Accesso completo al disco (FDA) concesso", "Acesso Total ao Disco (FDA) concedido")
        add(.settingsFdaNotGrantedStatusDesc, "受 macOS TCC 保护，授予后可完整扫描 Safari 缓存、系统日志与容器残留", "受 macOS TCC 保護，授予後可完整掃描 Safari 緩存、系統日誌與容器殘留", "Protected by macOS TCC. Grant access to enable complete scanning of Safari cache, system logs, and containers", "macOS TCC で保護されています。許可すると Safari キャッシュ、ログ、コンテナの完全スキャンが可能になります", "macOS TCC로 보호받고 있습니다. 권한을 부여하면 Safari 캐시, 시스템 로그 및 컨테이너를 완전 검사할 수 있습니다",
            "Protégé par macOS TCC. Accordez l'accès pour analyser les caches Safari, journaux et conteneurs", "Geschützt durch macOS TCC. Gewähren Sie Zugriff für vollständigen Scan von Safari-Caches und Protokollen", "Protegido por macOS TCC. Conceda permiso para escanear cachés de Safari, registros y contenedores", "Protetto da macOS TCC. Concedi l'accesso per scansionare cache di Safari, log e container", "Protegido pelo macOS TCC. Conceda acesso para verificação completa de caches do Safari, logs e contêineres")
        add(.settingsFdaNotGrantedStatusTitle, "尚未授予完全磁盘访问权限 (FDA)", "尚未授予完全磁盤訪問權限 (FDA)", "Full Disk Access (FDA) Not Granted", "フルディスクアクセス (FDA) が許可されていません", "전체 디스크 접근 권한 (FDA)이 부여되지 않음",
            "Accès complet au disque (FDA) non accordé", "Festplattenvollzugriff (FDA) nicht erteilt", "Acceso total al disco (FDA) no concedido", "Accesso completo al disco (FDA) non concesso", "Acesso Total ao Disco (FDA) não concedido")
        add(.settingsGeneral, "通用设置", "一般設定", "General", "一般", "일반",
            "Général", "Allgemein", "General", "Generali", "Geral")
        add(.settingsInspectionIntervalLabel, "巡检周期", "巡檢週期", "Inspection Interval", "チェック間隔", "점검 주기",
            "Intervalle d'inspection", "Prüfintervall", "Intervalo de inspección", "Intervallo di controllo", "Intervalo de inspeção")
        add(.settingsLargeAndOldFilesCriteriaTitle, "大文件与旧文件判定标准", "大文件與舊文件判定標準", "Large & Old Files Criteria", "大容量・古いファイルの判定基準", "대용량 및 오래된 파일 판정 기준",
            "Critères des gros et anciens fichiers", "Kriterien für große und alte Dateien", "Criterios para archivos grandes y antiguos", "Criteri per file grandi e obsoleti", "Critérios para arquivos grandes e antigos")
        add(.maintenanceIrreversibleNotice, "此操作会通过系统工具释放快照，无法从废纸篓恢复。请确认备份和恢复需求后继续。", "此操作會透過系統工具釋放快照，無法從垃圾桶復原。請先確認備份與復原需求。", "This operation uses system tools to purge snapshots and cannot be restored from Trash. Review your backup and recovery needs before continuing.", "システムツールでスナップショットを消去します。ゴミ箱からは復元できません。バックアップと復元の必要性を確認してください。", "시스템 도구로 스냅샷을 삭제하며 휴지통에서 복원할 수 없습니다. 백업과 복구 필요성을 확인한 후 계속하세요.",
            "Cette opération supprime des instantanés via les outils système. La Corbeille ne permet pas de les restaurer. Vérifiez vos besoins de sauvegarde et de restauration.", "Diese Aktion löscht Snapshots mit Systemwerkzeugen. Eine Wiederherstellung aus dem Papierkorb ist unmöglich. Prüfen Sie vorher Ihren Sicherungsbedarf.", "Esta operación elimina instantáneas mediante herramientas del sistema y no se puede restaurar desde la Papelera. Revise sus necesidades de copia y recuperación.", "Questa operazione elimina istantanee tramite strumenti di sistema e non è ripristinabile dal Cestino. Verifica prima le esigenze di backup e ripristino.", "Esta operação remove instantâneos usando ferramentas do sistema e não pode ser restaurada pelo Lixo. Revise suas necessidades de backup e recuperação antes de continuar.")
        add(.helperTitle, "系统维护助手", "系統維護助手", "System Maintenance Helper", "システム保守ヘルパー", "시스템 유지보수 도우미",
            "Assistant de maintenance système", "Systemwartungshelfer", "Asistente de mantenimiento", "Assistente di manutenzione", "Assistente de manutenção")
        add(.helperDescription, "仅执行固定的系统维护任务。启用需发布团队签名及系统授权；普通清理无需启用。", "僅執行固定系統維護工作。啟用需發佈團隊簽章及系統授權；一般清理無需啟用。", "Runs only predefined maintenance tasks. Requires a release team signature and system approval; regular cleanup works without it.", "定義済みの保守のみ実行します。有効化にはリリースチーム署名とシステム承認が必要です。通常の整理には不要です。", "정해진 유지보수 작업만 실행합니다. 활성화에는 릴리스 팀 서명과 시스템 승인이 필요하며 일반 정리에는 필요하지 않습니다.",
            "Exécute uniquement des tâches prédéfinies. Nécessite une signature de distribution et une autorisation système ; inutile pour le nettoyage ordinaire.", "Führt nur festgelegte Wartungsaktionen aus. Erfordert eine Teamsignatur und Systemgenehmigung; normale Bereinigungen funktionieren ohne ihn.", "Solo ejecuta tareas predefinidas. Requiere firma del equipo y aprobación del sistema; la limpieza normal no lo necesita.", "Esegue solo operazioni predefinite. Richiede firma del team e approvazione di sistema; non serve per la pulizia ordinaria.", "Executa apenas tarefas predefinidas. Exige assinatura da equipe e aprovação do sistema; a limpeza comum não depende dele.")
        add(.helperEnable, "启用维护助手…", "啟用維護助手…", "Enable Helper…", "ヘルパーを有効化…", "도우미 활성화…",
            "Activer l’assistant…", "Helfer aktivieren…", "Activar asistente…", "Attiva assistente…", "Ativar assistente…")
        add(.helperRequested, "已提交注册，请在系统设置中检查并允许此助手。", "已提交註冊，請至系統設定檢查並允許此助手。", "Registration submitted. Review and approve the helper in System Settings.", "登録を申請しました。システム設定で確認し、承認してください。", "등록을 요청했습니다. 시스템 설정에서 도우미를 확인하고 승인하세요.",
            "Inscription demandée. Vérifiez et autorisez l’assistant dans Réglages Système.", "Registrierung beantragt. Prüfen und genehmigen Sie den Helfer in den Systemeinstellungen.", "Registro solicitado. Revise y autorice el asistente en Ajustes del Sistema.", "Registrazione richiesta. Controlla e autorizza l’assistente in Impostazioni di Sistema.", "Registro solicitado. Revise e autorize o assistente nos Ajustes do Sistema.")
        add(.helperFailed, "无法启用。请使用包含有效团队签名和维护助手的发布版本，并检查系统授权。", "無法啟用。請使用含有效團隊簽章及維護助手的發佈版本，並檢查系統授權。", "Could not enable. Use a release build with a valid team signature and embedded helper, and check system approval.", "有効化できません。有効なチーム署名とヘルパーを含むリリース版を使用し、システム承認を確認してください。", "활성화할 수 없습니다. 유효한 팀 서명과 도우미가 포함된 릴리스 빌드를 사용하고 시스템 승인을 확인하세요.",
            "Activation impossible. Utilisez une version signée par l’équipe avec l’assistant intégré et vérifiez l’autorisation système.", "Aktivierung fehlgeschlagen. Verwenden Sie eine Version mit gültiger Teamsignatur und integriertem Helfer und prüfen Sie die Systemgenehmigung.", "No se pudo activar. Use una versión con firma de equipo válida y asistente incluido y compruebe la aprobación del sistema.", "Attivazione non riuscita. Usa una versione con firma del team valida e assistente incluso e verifica l’approvazione di sistema.", "Não foi possível ativar. Use uma versão com assinatura válida da equipe e assistente integrado e verifique a aprovação do sistema.")
        add(.settingsLeastPrivilegeDesc, "扫描和普通清理使用标准用户权限。需要管理员权限的系统操作必须经过单独授权。", "掃描與一般清理使用標準使用者權限。需要管理員權限的系統操作必須另行授權。", "Scanning and regular cleanup use standard user permissions. System operations requiring administrator privileges need separate authorization.", "スキャンと通常の整理は標準ユーザー権限で実行します。管理者権限が必要なシステム操作は別途承認が必要です。", "검사와 일반 정리는 표준 사용자 권한을 사용합니다. 관리자 권한이 필요한 시스템 작업은 별도 승인이 필요합니다.",
            "L’analyse et le nettoyage ordinaire utilisent les droits utilisateur standard. Les opérations système privilégiées nécessitent une autorisation distincte.", "Scans und normale Bereinigungen verwenden Standardbenutzerrechte. Systemaktionen mit Administratorrechten erfordern eine separate Genehmigung.", "El análisis y la limpieza normal usan permisos estándar. Las operaciones del sistema con privilegios requieren autorización independiente.", "Scansione e pulizia ordinaria usano permessi standard. Le operazioni di sistema privilegiate richiedono un’autorizzazione separata.", "Verificações e limpeza comum usam permissões padrão. Operações do sistema com privilégios exigem autorização separada.")
        add(.settingsLeastPrivilegeTitle, "最小特权安全运行模型 (已就绪)", "最小特權安全運行模型 (已就緒)", "Principle of Least Privilege Model (Ready)", "最小特権セキュリティモデル（準備完了）", "최소 권한 보안 실행 모델 (준비 완료)",
            "Modèle de moindre privilège (prêt)", "Modell der geringsten Rechte (bereit)", "Modelo de privilegios mínimos (listo)", "Modello dei minimi privilegi (pronto)", "Modelo de privilégio mínimo (pronto)")
        add(.settingsMenuBarRealtimeMonitoringTitle, "菜单栏实时监控", "菜單欄實時監控", "Menu Bar Real-Time Monitoring", "メニューバーリアルタイム監視", "메뉴 막대 실시간 모니터링",
            "Surveillance en temps réel de la barre des menus", "Echtzeit-Überwachung der Menüleiste", "Monitoreo en tiempo real de la barra de menús", "Monitoraggio in tempo reale nella barra dei menu", "Monitoramento em tempo real na barra de menus")
        add(.settingsNoCustomExclusionPathsPrompt, "当前没有自定义排除路径", "當前沒有自定義排除路徑", "No custom exclusion paths currently", "カスタム除外パスは設定されていません", "현재 사용자 정의 제외 경로가 없습니다",
            "Aucun chemin d'exclusion personnalisé actuellement", "Derzeit keine benutzerdefinierten Ausschluss-Pfade", "No hay rutas de exclusión personalizadas actualmente", "Nessun percorso di esclusione personalizzato al momento", "Nenhum caminho de exclusão personalizado no momento")
        add(.settingsProtectedExclusionCountFormat, "已保护 %d 个排除路径", "已保護 %d 個排除路徑", "Protected %d exclusion paths", "%d 個の除外パスを保護中", "%d개의 제외 경로가 보호됨",
            "%d chemins d'exclusion protégés", "%d Ausschluss-Pfade geschützt", "%d rutas de exclusión protegidas", "%d percorsi di esclusione protetti", "%d caminhos de exclusão protegidos")
        add(.settingsRiskControlMatrixSectionSubtitle, "在将重要用户目录、开发工程产物、iOS 备份或高风险项目移入废纸篓前弹出安全确认对话框", "在將重要用戶目錄、開發工程產物、iOS 備份或高風險項目移入廢紙簍前彈出安全確認對話框", "Show safety confirmation dialog before moving critical folders, dev artifacts, iOS backups, or risky items to Trash", "重要なユーザーフォルダ、開発成果物、iOS バックアップ、高リスク項目をゴミ箱に移動する前に確認ダイアログを表示", "중요 사용자 폴더, 개발 빌드 파일, iOS 백업 또는 고위험 항목을 휴지통에 넣기 전 안전 확인 대화상자 표시",
            "Afficher un dialogue de confirmation avant de mettre à la Corbeille des dossiers critiques, sauvegardes ou éléments à risque", "Bestätigungsdialog anzeigen, bevor kritische Ordner, Entwicklungsreste, Backups oder risikoreiche Objekte gelöscht werden", "Muestra un cuadro de diálogo de confirmación antes de mover carpetas importantes, copias de seguridad o elementos de riesgo a la Papelera", "Mostra un dialogo di conferma prima di spostare nel Cestino cartelle critiche, backup iOS o elementi ad alto rischio", "Exibir diálogo de confirmação antes de mover pastas críticas, artefatos de desenvolvimento, backups ou itens de risco para o Lixo")
        add(.settingsRiskControlMatrixSectionTitle, "多重风控矩阵与二次确认保护机制", "多重風控矩陣與二次確認保護機製", "Multi-Layer Risk Control & Secondary Confirmation", "多層リスク管理マトリクスと再確認保護メカニズム", "다중 위험 관리 매트릭스 및 재확인 보호 메커니즘",
            "Matrice de contrôle des risques et confirmation secondaire", "Mehrstufige Risikomatrix & Bestätigungsmechanismus", "Matriz de control de riesgos y confirmación secundaria", "Matrice di controllo del rischio e conferma secondaria", "Matriz de controle de risco e confirmação secundária")
        add(.settingsRiskControlNotesHeader, "风控矩阵与保护机制说明：", "風控矩陣與保護機製說明：", "Risk matrix & protection notes:", "リスク管理マトリクスおよび保護に関する注意事項：", "위험 관리 매트릭스 및 보호 메커니즘 안내:",
            "Notes sur la matrice de risque et la protection :", "Hinweise zur Risikomatrix & zu Schutzfunktionen:", "Notas sobre la matriz de riesgos y protección:", "Note sulla matrice di rischio e protezione:", "Notas sobre a matriz de risco e mecanismos de proteção:")
        add(.settingsScanThresholdSubtitle, "扫描判定阈值", "掃描判定閾值", "Scan Thresholds", "スキャン判定しきい値", "검사 판정 임계값",
            "Seuils d'analyse", "Scan-Schwellenwerte", "Umbrales de escaneo", "Soglie di scansione", "Limites de verificação")
        add(.settingsScheduledInspectionDesc, "定期在后台通过 macOS LaunchAgent 进行静默健康扫描并在垃圾达到阈值时通知或处理", "定期在後台通過 macOS LaunchAgent 進行靜默健康掃描並在垃圾達到閾值時通知或處理", "Periodically perform silent health scans via macOS LaunchAgent in the background and notify or clean when junk exceeds threshold", "macOS LaunchAgent を介してバックグラウンドでサイレントスキャンを実行し、しきい値超過時に通知または処理します", "macOS LaunchAgent를 통해 백그라운드에서 정기 점검을 수행하고 불필요 파일이 임계값에 도달하면 알림 또는 처리합니다",
            "Effectuez régulièrement des analyses silencieuses en arrière-plan et soyez alerté lorsque le seuil est dépassé", "Führt regelmäßige Hintergrund-Scans per LaunchAgent durch und benachrichtigt bei Erreichen des Schwellenwerts", "Realice análisis silenciosos en segundo plano y reciba alertas cuando la basura supere el umbral", "Esegui controlli silenziosi in background tramite LaunchAgent e ricevi avvisi al superamento della soglia", "Execute verificações silenciosas em segundo plano via LaunchAgent e receba alertas quando o lixo exceder o limite")
        add(.settingsScheduledScanAndMaintenanceTitle, "定时扫描与自动维护", "定時掃描與自動維護", "Scheduled Scan & Auto Maintenance", "定期スキャンと自動メンテナンス", "정기 검사 및 자동 유지보수",
            "Analyse planifiée et maintenance automatique", "Geplante Scans & Automatische Wartung", "Escaneo programado y mantenimiento automático", "Scansione programmata e manutenzione automatica", "Verificação agendada e manutenção automática")
        add(.settingsSilentCleanSafeCachesDesc, "仅将安全级 (Safe) 临时缓存移入废纸篓，绝不自动触碰用户文稿与个人数据", "僅將安全級 (Safe) 臨時緩存移入廢紙簍，絕不自動觸碰用戶文稿與個人數據", "Only move Safe-level temporary caches to Trash, never touching user documents or personal files", "安全レベル（Safe）の一時キャッシュのみをゴミ箱に移動し、書類や個人データには一切触れません", "안전 등급(Safe)의 임시 캐시만 휴지통으로 이동하며, 사용자의 문서와 개인 데이터는 절대 건드리지 않습니다",
            "Déplace uniquement les caches sûrs vers la Corbeille, sans jamais toucher aux documents personnels", "Verschiebt nur sichere temporäre Caches in den Papierkorb, niemals Dokumente oder persönliche Daten", "Solo mueve cachés seguros a la Papelera, sin tocar nunca documentos ni datos personales", "Sposta solo le cache sicure nel Cestino, senza toccare mai documenti o dati personali dell'utente", "Move apenas caches de nível seguro para o Lixo, nunca tocando em documentos ou dados pessoais")
        add(.settingsSilentCleanSafeCachesToggle, "后台静默清理绝对安全缓存", "後台靜默清理絕對安全緩存", "Silently Clean Safe Caches in Background", "安全なキャッシュのみをバックグラウンドで自動消去", "백그라운드에서 안전한 캐시 자동 정리",
            "Nettoyer silencieusement les caches sûrs en arrière-plan", "Sichere Caches im Hintergrund geräuschlos bereinigen", "Limpiar silenciosamente cachés seguros en segundo plano", "Pulisci silenziosamente le cache sicure in background", "Limpar silenciosamente caches seguros em segundo plano")
        add(.settingsSupportedLanguagesList, "中文 · English · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português", "中文 · English · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português", "English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano · Português", "日本語 · 简体中文 · 繁體中文 · English · 한국어 · Français · Deutsch · Español · Italiano · Português", "한국어 · 简体中文 · 繁體中文 · English · 日本語 · Français · Deutsch · Español · Italiano · Português",
            "Français · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Deutsch · Español · Italiano · Português", "Deutsch · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Español · Italiano · Português", "Español · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Italiano · Português", "Italiano · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Português", "Português · English · 简体中文 · 繁體中文 · 日本語 · 한국어 · Français · Deutsch · Español · Italiano")
        add(.settingsSystemDaemonStatusTitle, "系统守护进程状态", "系統守護進程狀態", "System Daemon Status", "システムデーモンの状態", "시스템 데몬 상태",
            "État du démon système", "Status des System-Daemons", "Estado del demonio del sistema", "Stato del demone di sistema", "Status do daemon do sistema")
        add(.settingsTrashProtectionDesc, "普通文件移入废纸篓，保留期间可恢复。清空废纸篓和部分系统维护不可逆，执行前会明确确认。", "一般檔案移入垃圾桶，保留期間可復原。清空垃圾桶及部分系統維護無法復原，執行前會明確確認。", "Regular files move to Trash and can be restored while retained there. Emptying Trash and some maintenance actions are irreversible and require explicit confirmation.", "通常のファイルはゴミ箱に移動し、残っている間は復元できます。ゴミ箱を空にする操作と一部の保守は元に戻せず、実行前に確認します。", "일반 파일은 휴지통에 보관되는 동안 복원할 수 있습니다. 휴지통 비우기와 일부 유지보수는 되돌릴 수 없으며 실행 전에 확인합니다。",
            "Les fichiers ordinaires vont à la Corbeille et restent restaurables tant qu’ils y sont conservés. La vider et certaines opérations de maintenance sont irréversibles et nécessitent une confirmation.", "Normale Dateien werden im Papierkorb aufbewahrt und können währenddessen wiederhergestellt werden. Das Leeren und manche Wartungsaktionen sind unwiderruflich und erfordern eine Bestätigung.", "Los archivos normales van a la Papelera y se pueden restaurar mientras permanezcan allí. Vaciarla y algunas tareas de mantenimiento son irreversibles y requieren confirmación.", "I file ordinari vanno nel Cestino e sono ripristinabili finché vi rimangono. Lo svuotamento e alcune operazioni di manutenzione sono irreversibili e richiedono conferma.", "Arquivos comuns vão para o Lixo e podem ser restaurados enquanto estiverem lá. Esvaziá-lo e algumas ações de manutenção são irreversíveis e exigem confirmação.")
        add(.settingsTrashProtectionTitle, "系统级废纸篓安全保护机制 (已启用)", "系統級廢紙簍安全保護機製 (已啟用)", "System Trash Protection (Enabled)", "システムゴミ箱保護メカニズム（有効）", "시스템 휴지통 보호 메커니즘 (활성화됨)",
            "Protection de la Corbeille système (activée)", "Papierkorb-Sicherheitsmechanismus (aktiviert)", "Protección de la Papelera del sistema (activada)", "Protezione del Cestino di sistema (abilitata)", "Proteção do Lixo do sistema (ativada)")
        add(.sharedDatabasesAndAccountSettingsAcrossAppsFromTheSameDeveloper, "同开发者多应用间共享的数据库与账号配置", "同開發者多應用間共享的資料庫與賬號配置", "Shared databases and account settings across apps from the same developer", "同一開発者の複数アプリ間で共有されるデータベースとアカウント設定", "동일 개발자의 여러 앱 간에 공유되는 데이터베이스 및 계정 설정",
            "Bases de données et comptes partagés entre apps du même développeur", "Gemeinsam genutzte Datenbanken und Kontokonfigurationen zwischen Apps desselben Entwicklers", "Bases de datos y cuentas compartidas entre apps del mismo desarrollador", "Database e account condivisi tra app dello stesso sviluppatore", "Bancos de dados e contas compartilhadas entre apps do mesmo desenvolvedor")
        add(.sharedGroupContainerForAppExtensionsStoresSharedDatabasesAuthAndConfig, "应用与组件/扩展共享的群组容器（含共享数据库、登录态与核心配置）", "應用程式與組件/延伸功能共享的群組容器（含共享資料庫、登入狀態與核心設定）", "Shared group container for app extensions (stores shared databases, auth, and config)", "アプリ拡張機能と共有するグループコンテナ（共有DB、ログイン状態、設定を保存）", "앱 및 확장 프로그램 공유 그룹 컨테이너 (공유 DB, 로그인 상태 및 핵심 설정 포함)",
            "Conteneur partagé entre l’app et ses extensions (bases de données et session)", "Geteilter Gruppencontainer für App & Erweiterungen (Datenbanken, Login, Config)", "Contenedor compartido con extensiones (bases de datos, sesión y configuración)", "Contenitore condiviso con estensioni (database condivisi, accesso e config)", "Contêiner compartilhado com extensões (bancos de dados, sessão e configuração)")
        add(.showsDiskUsageOnlyAndIsNeverAutoCleanedManageInTheRespectiveAppOrSystemSettings, "仅显示占用，不参与清理，到对应 App 或系统设置里处理", "僅顯示佔用，不參與清理，到對應 App 或系統設定裡處理", "Shows disk usage only and is never auto-cleaned; manage in the respective app or System Settings", "使用量のみ表示（自動削除の対象外。各 App またはシステム設定で管理してください）", "용량만 표시하며 자동 정리에서 제외됩니다. 해당 앱이나 시스템 설정에서 관리하세요",
            "Affiche uniquement l’espace utilisé ; à gérer dans l’app ou les Réglages Système", "Zeigt nur die Belegung an; bitte in der jeweiligen App oder den Systemeinstellungen verwalten", "Solo muestra el espacio usado; gestiónalo en la app correspondiente o en Ajustes del Sistema", "Mostra solo lo spazio occupato; gestiscilo nell’app o nelle Impostazioni di Sistema", "Apenas mostra o espaço ocupado; gerencie no respectivo app ou nos Ajustes do Sistema")
        add(.similarImages, "相似图片", "相似圖片", "Similar Photos", "類似した写真", "유사한 사진",
            "Photos similaires", "Ähnliche Fotos", "Fotos similares", "Foto simili", "Fotos Semelhantes")
        add(.similarPhotosGroupTitleFormat, "相似图片组 %d(%d 张)", "相似圖片組 %d(%d 張", "Similar Photo Group %d (%d photos)", "類似写真グループ %d (%d 枚)", "유사 사진 그룹 %d (%d장)",
            "Groupe de photos similaires %d (%d photos)", "Ähnliche Fotos Gruppe %d (%d Fotos)", "Grupo de fotos similares %d (%d fotos)", "Gruppo di foto simili %d (%d foto)", "Grupo de fotos semelhantes %d (%d fotos)")
        add(.simulatedBatteryHealthCycleFormat, "健康度 94% · 循环 118 次", "健康度 94% · 循環 118 次", "Health 94% · 118 Cycles", "最大容量 94% · 充放電回数 118 回", "성능 상태 94% · 사이클 118회",
            "État 94 % · 118 cycles", "Zustand 94 % · 118 Zyklen", "Salud 94 % · 118 ciclos", "Stato 94% · 118 cicli", "Saúde 94% · 118 ciclos")
        add(.simulatedColProcessName, "进程名称", "處理程序名稱", "Process Name", "プロセス名", "프로세스 이름",
            "Nom du processus", "Prozessname", "Nombre del proceso", "Nome processo", "Nome do processo")
        add(.simulatedCpuBreakdownFormat, "系统 6% · 用户 12%", "系統 6% · 使用者 12%", "System 6% · User 12%", "システム 6% · ユーザー 12%", "시스템 6% · 사용자 12%",
            "Système 6 % · Utilisateur 12 %", "System 6 % · Benutzer 12 %", "Sistema 6 % · Usuario 12 %", "Sistema 6% · Utente 12%", "Sistema 6% · Usuário 12%")
        add(.simulatedDiskIoFormat, "已用 65% · 读: 18 MB/s · 写: 6 MB/s", "已用 65% · 讀: 18 MB/s · 寫: 6 MB/s", "Used 65% · R: 18 MB/s · W: 6 MB/s", "使用率 65% · 読込: 18 MB/s · 書込: 6 MB/s", "사용 65% · 읽기: 18 MB/s · 쓰기: 6 MB/s",
            "Utilisé 65 % · L : 18 Mo/s · É : 6 Mo/s", "Belegt 65 % · L: 18 MB/s · S: 6 MB/s", "Usado 65 % · L: 18 MB/s · E: 6 MB/s", "Usato 65% · L: 18 MB/s · S: 6 MB/s", "Usado 65% · L: 18 MB/s · G: 6 MB/s")
        add(.simulatedFanStatsFormat, "自动温控 · 左风扇 1320 / 右风扇 1280", "自動溫控 · 左風扇 1320 / 右風扇 1280", "Auto Cooling · Left Fan 1320 / Right Fan 1280", "自動制御 · 左ファン 1320 / 右ファン 1280", "자동 제어 · 좌측 팬 1320 / 우측 팬 1280",
            "Refroidissement auto · Ventilateur gauche 1320 / droit 1280", "Autom. Kühlung · Lüfter links 1320 / rechts 1280", "Refrigeración auto · Ventilador izq 1320 / der 1280", "Controllo autom. · Ventola sin. 1320 / des. 1280", "Controle autom. · Ventilador esq 1320 / dir 1280")
        add(.simulatedGatewayLatencyFormat, "网关延迟 14 ms", "閘道延遲 14 ms", "Gateway Latency 14 ms", "ゲートウェイ遅延 14 ms", "게이트웨이 지연 14 ms",
            "Latence passerelle 14 ms", "Gateway-Latenz 14 ms", "Latencia de puerta de enlace 14 ms", "Latenza gateway 14 ms", "Latência do gateway 14 ms")
        add(.simulatedGpuCoreRenderFormat, "38 核渲染", "38 覈算繪", "38 Cores Rendering", "38 コアレンダリング", "38 코어 렌더링",
            "38 cœurs de rendu", "38 Kerne Rendering", "38 núcleos de renderizado", "Rendering a 38 core", "Renderização em 38 núcleos")
        add(.simulatedGpuMemoryLoadFormat, "显存占用 1.8 GB · 低负载", "視訊記憶體佔用 1.8 GB · 低負載", "VRAM 1.8 GB · Low Load", "VRAM 1.8 GB · 低負荷", "VRAM 1.8 GB · 낮은 부하",
            "VRAM 1,8 Go · Charge faible", "VRAM 1,8 GB · Geringe Last", "VRAM 1.8 GB · Carga baja", "VRAM 1,8 GB · Basso carico", "VRAM 1,8 GB · Carga baixa")
        add(.simulatedHardwareSpecsFormat, "Apple M2 Max (12核 CPU · 38核 GPU) · 已运行 3天 14小时", "Apple M2 Max (12核 CPU · 38核 GPU) · 已運行 3天 14小時", "Apple M2 Max (12-core CPU · 38-core GPU) · Uptime 3d 14h", "Apple M2 Max (12コア CPU · 38コア GPU) · 稼働 3日 14時間", "Apple M2 Max (12코어 CPU · 38코어 GPU) · 가동 시간 3일 14시간",
            "Apple M2 Max (12 cœurs CPU · 38 cœurs GPU) · En service 3j 14h", "Apple M2 Max (12-Kern-CPU · 38-Kern-GPU) · Betriebszeit 3 T. 14 Std.", "Apple M2 Max (CPU de 12 núcleos · GPU de 38 núcleos) · Activo 3d 14h", "Apple M2 Max (CPU a 12 core · GPU a 38 core) · In attività 3g 14h", "Apple M2 Max (CPU de 12 núcleos · GPU de 38 núcleos) · Ativo 3d 14h")
        add(.simulatedKeepAwakeActive, "防休眠开启", "防止睡眠開啟", "Keep Awake Active", "スリープ防止 有効", "잠자기 방지 활성",
            "Anti-veille actif", "Wachhalten aktiv", "Mantener encendido", "Non sospendere attivo", "Manter ativo ligado")
        add(.simulatedLanIpFormat, "局域网 IP: 192.168.1.108", "區域網路 IP: 192.168.1.108", "LAN IP: 192.168.1.108", "LAN IP: 192.168.1.108", "로컬 IP: 192.168.1.108",
            "IP locale : 192.168.1.108", "Lokale IP: 192.168.1.108", "IP local: 192.168.1.108", "IP locale: 192.168.1.108", "IP local: 192.168.1.108")
        add(.simulatedPowerAdapterFormat, "电源适配器 · +18.5W", "電源轉接器 · +18.5W", "Power Adapter · +18.5W", "電源アダプタ · +18.5W", "전원 어댑터 · +18.5W",
            "Adaptateur secteur · +18,5 W", "Netzteil · +18,5 W", "Adaptador de corriente · +18.5 W", "Alimentatore · +18,5 W", "Adaptador de alimentação · +18,5 W")
        add(.simulatedPrivacyNotInUse, "隐私无占用", "隱私無佔用", "Privacy Idle", "プライバシー待機", "개인정보 미사용",
            "Confidentialité libre", "Privatsphäre frei", "Privacidad libre", "Privacy non occupata", "Privacidade livre")
        add(.simulatedPublicIpFormat, "公网 IP: 114.247.50.2 · 中国电信", "公開 IP: 114.247.50.2 · 中國電信", "Public IP: 114.247.50.2 · China Telecom", "パブリック IP: 114.247.50.2 · China Telecom", "공인 IP: 114.247.50.2 · China Telecom",
            "IP publique : 114.247.50.2 · China Telecom", "Öffentliche IP: 114.247.50.2 · China Telecom", "IP pública: 114.247.50.2 · China Telecom", "IP pubblico: 114.247.50.2 · China Telecom", "IP público: 114.247.50.2 · China Telecom")
        add(.simulatedPurgeMemory, "释放内存", "釋放記憶體", "Purge Memory", "メモリ解放", "메모리 정리",
            "Libérer la mémoire", "Speicher leeren", "Liberar memoria", "Libera memoria", "Liberar memória")
        add(.simulatedRamAppCompressedFormat, "应用 14.2G · 压缩 2.1G", "應用程式 14.2G · 壓縮 2.1G", "App 14.2G · Compressed 2.1G", "アプリ 14.2G · 圧縮 2.1G", "앱 14.2G · 압축 2.1G",
            "App 14,2 Go · Compressé 2,1 Go", "App 14,2 G · Komprimiert 2,1 G", "App 14,2 G · Comprimido 2,1 G", "App 14,2 G · Compresso 2,1 G", "App 14,2 G · Comprimido 2,1 G")
        add(.simulatedRamPressureNormal, "压力正常", "壓力正常", "Pressure Normal", "プレッシャー標準", "압력 정상",
            "Pression normale", "Druck normal", "Presión normal", "Pressione normale", "Pressão normal")
        add(.simulatedRamUsedTotalFormat, "已用 19.8 GB / 32 GB", "已用 19.8 GB / 32 GB", "Used 19.8 GB / 32 GB", "使用中 19.8 GB / 32 GB", "사용 중 19.8 GB / 32 GB",
            "Utilisé 19,8 Go / 32 Go", "Belegt 19,8 GB / 32 GB", "Usado 19,8 GB / 32 GB", "Usati 19,8 GB / 32 GB", "Usado 19,8 GB / 32 GB")
        add(.simulatedWeatherAqiFormat, "AQI 32 优", "AQI 32 優", "AQI 32 Good", "AQI 32 良好", "AQI 32 좋음",
            "AQI 32 Bon", "AQI 32 Gut", "AQI 32 Bueno", "AQI 32 Buono", "AQI 32 Bom")
        add(.simulatedWeatherConditionFormat, "24°C 多云转晴", "24°C 多雲轉晴", "24°C Partly Cloudy", "24°C 晴れ時々曇り", "24°C 구름 조금",
            "24 °C Partiellement nuageux", "24 °C Heiter bis wolkig", "24 °C Parcialmente nublado", "24 °C Parzialmente nuvoloso", "24 °C Parcialmente nublado")
        add(.simulatedWeatherForecastFormat, "最高 26° · 最低 18° · 湿度 54% · 东南风 2级", "最高 26° · 最低 18° · 濕度 54% · 東南風 2級", "High 26° · Low 18° · Humidity 54% · SE Wind 2", "最高 26° · 最低 18° · 湿度 54% · 南東の風 2", "최고 26° · 최저 18° · 습도 54% · 남동풍 2",
            "Max 26° · Min 18° · Humidité 54 % · Vent SE 2", "Max 26° · Min 18° · Feuchtigkeit 54 % · SO-Wind 2", "Máx 26° · Mín 18° · Humedad 54 % · Viento SE 2", "Max 26° · Min 18° · Umidità 54% · Vento SE 2", "Máx 26° · Mín 18° · Umidade 54% · Vento SE 2")
        add(.smartDetectionOfInstalledAppsUnusedSoftwareLeftoverFilesAndStartupItems, "智能检测已安装应用、闲置软件、关联残留与自启组件", "智慧檢測已安裝應用、閒置軟體、關聯殘留與自啟組件", "Smart detection of installed apps, unused software, leftover files, and startup items", "インストール済みアプリ、未使用ソフト、アンインストール残骸、起動項目を検知", "설치된 앱, 미사용 프로그램, 잔여 파일 및 시작 프로그램을 스마트하게 감지",
            "Détection intelligente des apps, logiciels inutilisés, résidus et éléments au démarrage", "Intelligente Erkennung von Apps, inaktiver Software, Resten und Autostart-Objekten", "Detección inteligente de apps, software sin usar, residuos y elementos de arranque", "Rilevamento intelligente di app, software inutilizzato, residui e componenti di avvio", "Detecção inteligente de apps, softwares inativos, arquivos residuais e inicialização")
        add(.smartScanAllJunkSubtitle, "智能扫描系统垃圾、应用缓存、通讯媒体与开发冗余", "智能掃描系統垃圾、應用緩存、通訊媒體與開發冗餘", "Smart scan for system junk, app caches, messaging media, and developer leftovers", "システムゴミ、アプリキャッシュ、メッセージメディア、開発残滓をスマートスキャン", "시스템 정크, 앱 캐시, 메신저 미디어 및 개발 잔여 파일 스마트 검사",
            "Analyse intelligente des fichiers système inutiles, caches, médias et résidus de développement", "Intelligenter Scan nach Systemmüll, App-Caches, Messaging-Medien und Entwicklungsresten", "Escaneo inteligente de basura del sistema, cachés de apps, medios y restos de desarrollo", "Scansione intelligente di file spazzatura, cache delle app, media e residui di sviluppo", "Verificação inteligente de lixo do sistema, caches de apps, mídia e resíduos de desenvolvimento")
        add(.smartSearchForLeftoverSupportFoldersAndOrphanedCachesFromAlreadyDeletedApps, "智能检索已删除应用遗留在磁盘深处的无主支持目录与缓存垃圾", "智慧檢索已刪除應用遺留在磁碟深處的無主支援目錄與快取垃圾", "Smart search for leftover support folders and orphaned caches from already deleted apps", "削除済みアプリが残したサポートフォルダや孤立キャッシュをスマートに検出", "이미 삭제된 앱이 디스크에 남긴 고립된 지원 폴더와 캐시 정크를 스마트하게 검색합니다",
            "Recherche intelligente des dossiers de support orphelins et caches d’apps supprimées", "Intelligente Suche nach verwaisten Support-Ordnern und Caches gelöschter Apps", "Búsqueda inteligente de carpetas huérfanas y cachés de apps eliminadas", "Ricerca intelligente di cartelle di supporto e cache orfane di app già rimosse", "Busca inteligente por pastas de suporte órfãs e caches de apps já apagados")
        add(.someProtectedCachesRequireFullDiskAccessToScan, "部分受保护缓存需要完全磁盘访问权限才能扫描", "部分受保護快取需要完全磁碟取用權限才能掃描", "Some protected caches require Full Disk Access to scan", "一部の保護されたキャッシュのスキャンにはフルディスクアクセスが必要です", "일부 보호된 캐시를 스캔하려면 전체 디스크 접근 권한이 필요합니다",
            "Certains caches protégés nécessitent un accès complet au disque", "Einige geschützte Caches erfordern Festplattenvollzugriff", "Algunas cachés protegidas requieren acceso total al disco", "Alcune cache protette richiedono l'accesso completo al disco", "Alguns caches protegidos exigem Acesso Total ao Disco")
        add(.sortAscending, "升序", "遞增", "Ascending", "昇順", "오름차순",
            "Croissant", "Aufsteigend", "Ascendente", "Crescente", "Crescente")
        add(.sortBy, "排序方式", "排序方式", "Sort By", "並び替え", "정렬 기준",
            "Trier par", "Sortierung", "Ordenar por", "Ordina per", "Ordenar por")
        add(.sortByColon, "排序方式:", "排序方式:", "Sort By:", "並び順:", "정렬 기준:",
            "Trier par :", "Sortieren nach:", "Ordenar por:", "Ordina per:", "Ordenar por:")
        add(.sortByDate, "日期", "日期", "Date", "日付", "날짜",
            "Date", "Datum", "Fecha", "Data", "Data")
        add(.sortByInstallDate, "安装日期", "安裝日期", "Install Date", "インストール日", "설치 날짜",
            "Date d’installation", "Installationsdatum", "Fecha de instalación", "Data installazione", "Data de Instalação")
    }

    static func populateBatch12(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.sortByLastUsed, "最近使用", "最近使用", "Last Used", "最終使用", "마지막 사용",
            "Dernière utilisation", "Zuletzt verwendet", "Último uso", "Ultimo uso", "Último Uso")
        add(.sortByName, "名称", "名稱", "Name", "名前", "이름",
            "Nom", "Name", "Nombre", "Nome", "Nome")
        add(.sortBySize, "大小", "大小", "Size", "サイズ", "크기",
            "Taille", "Größe", "Tamaño", "Dimensioni", "Tamanho")
        add(.sortBySizeAlt, "占用体积", "佔用體積", "Size", "サイズ", "크기",
            "Taille", "Größe", "Tamaño", "Dimensioni", "Tamanho")
        add(.sortDescending, "降序", "遞減", "Descending", "降順", "내림차순",
            "Décroissant", "Absteigend", "Descendente", "Decrescente", "Decrescente")
        add(.sortOptionBySize, "按大小", "按大小", "By Size", "サイズ順", "크기순",
            "Par taille", "Nach Größe", "Por tamaño", "Per dimensione", "Por tamanho")
        add(.sortedBySize, "按大小排序", "依大小排序", "Sorted by size", "サイズ順", "크기순 정렬",
            "Trié par taille", "Nach Größe sortiert", "Ordenado por tamaño", "Ordinato per dimensione", "Ordenado por tamanho")
        add(.soundEffectsToggleSubtitle, "当全盘扫描、空间释放或系统维护完成时播放原生提示音", "當全盤掃描、空間釋放或系統維護完成時播放原生提示音", "Play native sound effects when tasks, scans, or space releases complete", "スキャンやメンテナンスの完了時にシステム効果音を鳴らします", "스캔, 용량 확보 또는 시스템 유지보수가 완료되면 알림음을 재생합니다",
            "Émet un son système à la fin des analyses, nettoyages ou tâches de maintenance", "Spielt einen Hinweiston ab, wenn Scans, Speicherbereinigung oder Wartungen enden", "Reproducir un sonido cuando finalicen los análisis, limpiezas o mantenimientos", "Riproduci suono al termine delle scansioni, pulizie o manutenzioni", "Reproduzir efeito sonoro quando tarefas, escaneamentos ou limpezas terminarem")
        add(.soundEffectsToggleTitle, "扫描与清理完成提示音效", "掃描與清理完成提示音效", "Completion Sound Effects", "スキャン・クリーンアップ完了音", "스캔 및 정리 완료 알림음",
            "Effets sonores de fin d’opération", "Hinweistöne bei Fertigstellung", "Efectos de sonido al completar", "Effetti sonori di completamento", "Efeitos Sonoros de Conclusão")
        add(.spaceLensFeatureDrillDownDesc, "双击任意目录层层深入，支持智能折叠面包屑回溯", "雙擊任意目錄層層深入，支持智能折疊麵包屑回溯", "Double-click any folder to drill down with smart breadcrumb navigation", "任意のフォルダをダブルクリックして階層を掘り下げ、パンくずリストでスマートに戻れます", "폴더를 더블 클릭하여 심층 탐색하고 스마트 이동 경로(Breadcrumbs)로 손쉽게 돌아오세요",
            "Double-cliquez sur un dossier pour naviguer en profondeur avec fil d'Ariane intelligent", "Doppelklick auf Ordner zum Eintauchen, mit intelligenter Breadcrumb-Navigation", "Haga doble clic en una carpeta para profundizar con navegación inteligente por migas de pan", "Fai doppio clic su una cartella per esplorare a fondo con breadcrumb intelligenti", "Dê duplo clique em qualquer pasta para navegar a fundo com navegação inteligente")
        add(.spaceLensFeatureDrillDownSubtitle, "层层深入探索", "層層深入探索", "Explore Layer by Layer", "階層を深く探索", "단계별 심층 탐색",
            "Explorer couche par couche", "Schicht für Schicht erkunden", "Explorar capa por capa", "Esplora livello per livello", "Explorar camada por camada")
        add(.spaceLensFeatureDrillDownTitle, "无级下钻", "無級下鑽", "Seamless Drill-Down", "シームレスなドリルダウン", "무단계 심층 탐색",
            "Exploration approfondie sans palier", "Stufenloses Drill-Down", "Exploración en profundidad continua", "Navigazione dettagliata continua", "Navegação contínua em profundidade")
        add(.spaceLensFeatureOrbitDesc, "以天体行星引力动态模拟文件质量，视觉震撼", "以天體行星引力動態模擬文件質量，視覺震撼", "Dynamically simulate file mass through planetary gravity with stunning visuals", "惑星の引力シミュレーションでファイルサイズを動的に表現する圧巻のビジュアル", "행성 중력 시뮬레이션으로 파일 질량을 동적으로 표현하는 놀라운 시각 효과",
            "Simulez dynamiquement la masse des fichiers par gravité planétaire", "Dateigrößen dynamisch durch planetare Schwerkraft atemberaubend visualisieren", "Simule dinámicamente la masa de los archivos mediante gravedad planetaria", "Simula dinamicamente la massa dei file con gravità planetaria spettacolare", "Simule dinamicamente a massa dos arquivos através da gravidade planetária com visual incrível")
        add(.spaceLensFeatureOrbitTitle, "天体引力视觉", "天體引力視覺", "Celestial Gravitational Orbit", "天体引力シミュレーション", "천체 중력 궤도 비주얼",
            "Orbite gravitationnelle céleste", "Kosmische Gravitationsanzeige", "Órbita gravitacional celeste", "Orbita gravitazionale celeste", "Órbita gravitacional celeste")
        add(.spaceLensFeatureQuickLocateDesc, "空格快速预览，支持右键直接在访达中显示或移入废纸篓", "空格快速預覽，支持右鍵直接在訪達中顯示或移入廢紙簍", "Press spacebar for instant QuickLook preview, right-click to reveal in Finder or move to Trash", "スペースキーでクイックルック即時プレビュー、右クリックで Finder に表示またはゴミ箱へ移動", "스페이스바로 훑어보기(QuickLook), 우클릭으로 Finder에서 열거나 휴지통으로 이동",
            "Appuyez sur la barre d'espace pour Aperçu, clic droit pour afficher dans le Finder ou corbeille", "Leertaste für QuickLook-Vorschau drücken, Rechtsklick zum Anzeigen im Finder oder Löschen", "Pulse la barra espaciadora para vista previa, clic derecho para ver en Finder o tirar a la papelera", "Premi la barra spaziatrice per l'anteprima, clic destro per mostrare nel Finder o cestinare", "Pressione a barra de espaço para pré-visualizar, clique com botão direito para abrir no Finder ou lixo")
        add(.spaceLensFeatureQuickLocateSubtitle, "空格预览与清理", "空格預覽與清理", "Spacebar Preview & Cleanup", "スペースキーでプレビューと削除", "스페이스바로 미리보기 및 정리",
            "Aperçu avec la barre d'espace et nettoyage", "Leertaste-Vorschau & Bereinigung", "Vista previa con barra espaciadora y limpieza", "Anteprima con barra spaziatrice e pulizia", "Pré-visualização com barra de espaço e limpeza")
        add(.spaceLensFeatureQuickLocateTitle, "极速定位", "極速定位", "Instant Pinpoint", "素早く位置特定", "초고속 위치 확인",
            "Localisation instantanée", "Blitzschnell orten", "Localización instantánea", "Localizzazione istantanea", "Localização instantânea")
        add(.spaceLensFeatureTreemapDesc, "以面积占比直观呈现各目录体积，层级鲜明", "以面積佔比直觀呈現各目錄體積，層級鮮明", "Visually present directory sizes by area ratio with distinct hierarchy", "面積の比率で各ディレクトリのサイズを直感的に表現し、階層構造を明確に表示", "면적 비율로 각 디렉터리 크기를 직관적으로 표시하며 계층 구조가 뚜렷합니다",
            "Présentez la taille des répertoires par ratio de surface avec une hiérarchie claire", "Verzeichnisgrößen intuitiv durch Flächenanteile mit klarer Hierarchie darstellen", "Muestre el tamaño de los directorios por proporción de área con jerarquía clara", "Visualizza le dimensioni delle directory per proporzione dell'area con una gerarchia chiara", "Apresente o tamanho dos diretórios por proporção de área com hierarquia nítida")
        add(.spaceLensFeatureTreemapTitle, "面积比例色块", "面積比例色塊", "Area-Proportional Blocks", "面積比例ブロック", "면적 비율 블록",
            "Blocs proportionnels", "Flächenproportionale Blöcke", "Bloques proporcionales", "Blocchi proporzionali", "Blocos proporcionais à área")
        add(.spaceLensHeroMainDesc, "以可视化方式探索磁盘空间分布，轻松定位占用庞大的文件夹与隐秘大文件", "以可視化方式探索磁盤空間分布，輕松定位佔用龐大的文件夾與隱秘大文件", "Visually explore storage distribution to easily pinpoint giant folders and hidden large files", "ディスク空間の分布を視覚的に探索し、大容量フォルダや隠れた大ファイルを素早く特定", "시각적 방식으로 디스크 공간 분포를 탐색하여 거대한 폴더와 숨겨진 대용량 파일을 손쉽게 찾으세요",
            "Explorez visuellement la distribution du stockage pour localiser facilement les gros dossiers", "Speicherverteilung visuell erkunden, um riesige Ordner und versteckte große Dateien zu finden", "Explore visualmente la distribución para localizar fácilmente carpetas gigantes y archivos ocultos", "Esplora visivamente la distribuzione per individuare facilmente cartelle giganti e file nascosti", "Explore visualmente a distribuição para localizar facilmente pastas gigantes e arquivos ocultos")
        add(.spaceLensHeroMainTitle, "让磁盘空间一目了然", "讓磁盤空間一目瞭然", "Make Disk Space Crystal Clear", "ディスクスペースを一目で把握", "디스크 공간을 한눈에 파악",
            "Rendez l'espace disque limpide", "Festplattenspeicher auf einen Blick erfassen", "Visualice el espacio en disco con total claridad", "Rendi lo spazio su disco chiaro a colpo d'occhio", "Deixe o espaço em disco claro à primeira vista")
        add(.spaceLensHeroSubtitle, "可视化探索磁盘空间占用，支持矩形树图与行星透镜交互下钻", "可視化探索磁盤空間佔用，支持矩形樹圖與行星透鏡交互下鑽", "Visually explore disk usage with treemaps and interactive orbital lens drill-down", "ツリーマップとインタラクティブな惑星レンズでディスク使用量を視覚的に探索", "트리맵 및 행성 렌즈 상호작용으로 디스크 공간 사용량을 시각적으로 탐색",
            "Explorez visuellement l'utilisation du disque avec treemaps et lentille orbitale interactive", "Visuelles Erkunden des Festplattenspeichers mit Treemaps und interaktiver Planetenlinse", "Explore visualmente el espacio con mapas de árbol y lente orbital interactiva", "Esplora visivamente lo spazio su disco con treemap e lente orbitale interattiva", "Explore visualmente o uso do disco com mapas em árvore e lente orbital interativa")
        add(.spaceLensSecurityGuaranteeNote, "安全保障：文件索引仅用于本地只读可视化呈现，未授权绝不修改个人文件", "安全保障：文件索引僅用於本地只讀可視化呈現，未授權絕不修改個人文件", "Security guarantee: File index is read-only for visualization; personal files are never modified without authorization", "安全保証：ファイルインデックスはローカルの読み取り専用視覚化のみに使用され、許可なく変更されることはありません", "안전 보장: 파일 색인은 로컬 읽기 전용 시각화에만 사용되며 사용자 동의 없이 파일을 변경하지 않습니다",
            "Garantie de sécurité : Indexation locale en lecture seule ; vos fichiers personnels ne sont jamais modifiés sans accord", "Sicherheitsgarantie: Datei-Index nur für lokale schreibgeschützte Visualisierung; keine Änderung ohne Zustimmung", "Garantía de seguridad: El índice es solo de lectura local para visualización; nunca se modifican archivos sin permiso", "Garanzia di sicurezza: L'indice è in sola lettura locale per la visualizzazione; mai modifiche senza autorizzazione", "Garantia de segurança: O índice é apenas de leitura local para visualização; arquivos nunca são alterados sem permissão")
        add(.spaceLensUsageTip, "双击文件夹可下钻查看子目录，勾选后可一键移入废纸篓", "連按兩下資料夾可進入子目錄，勾選後可一鍵移到垃圾桶", "Double-click any folder to drill down; check items to move them to Trash", "フォルダをダブルクリックで階層移動、チェックしてゴミ箱へ移動できます", "폴더를 더블 클릭하여 하위 폴더로 이동하고, 체크하여 휴지통으로 이동하세요",
            "Double-cliquez sur un dossier pour l’explorer ; cochez pour mettre à la Corbeille", "Doppelklicken zum Öffnen von Ordnern; auswählen zum Bewegen in den Papierkorb", "Doble clic en una carpeta para abrirla; marca elementos para enviarlos a la Papelera", "Fai doppio clic su una cartella per esplorarla; seleziona per spostare nel Cestino", "Clique duas vezes em uma pasta para abrir; marque itens para mover para o Lixo")
        add(.spanOptionFull, "1/1 通栏", "1/1 全欄", "1/1 Full Width", "1/1 フル幅", "1/1 전체 너비",
            "1/1 Pleine largeur", "1/1 Volle Breite", "1/1 Ancho completo", "1/1 Larghezza intera", "1/1 Largura Total")
        add(.spanOptionHalf, "1/2 双列", "1/2 雙欄", "1/2 Half Width", "1/2 半幅", "1/2 절반 너비",
            "1/2 Demi-largeur", "1/2 Halbe Breite", "1/2 Mitad de ancho", "1/2 Mezza larghezza", "1/2 Meia Largura")
        add(.spanOptionThird, "1/3 九宫", "1/3 九宮", "1/3 Grid Width", "1/3 グリッド幅", "1/3 그리드 너비",
            "1/3 Largeur de grille", "1/3 Rasterbreite", "1/3 Ancho de cuadrícula", "1/3 Larghezza griglia", "1/3 Largura de Grade")
        add(.speedUpAndMaintainSystemDesc, "提升运行速度并进行系统维护", "提升運行速度並進行系統維護", "Boost speed and perform system maintenance", "動作速度を向上させ、システムメンテナンスを実行", "실행 속도 향상 및 시스템 유지 관리 수행",
            "Accélérer le fonctionnement et effectuer la maintenance", "Geschwindigkeit steigern und Systemwartung durchführen", "Mejorar la velocidad y realizar mantenimiento del sistema", "Aumenta la velocità ed esegui la manutenzione del sistema", "Aumentar a velocidade e realizar a manutenção do sistema")
        add(.spotlightSearchIndexingService, "聚焦 (Spotlight) 搜索索引服务", "聚焦 (Spotlight) 搜索索引服務", "Spotlight Search Indexing Service", "Spotlight 検索インデックス作成サービス", "Spotlight 검색 색인 서비스",
            "Service d'indexation de recherche Spotlight", "Spotlight-Suchindexierungsdienst", "Servicio de indexación de búsqueda Spotlight", "Servizio di indicizzazione della ricerca Spotlight", "Serviço de indexação de busca do Spotlight")
        add(.sqliteVacuumCompactDatabasesDesc, "对本地受支持应用的高频 SQLite 数据库执行 VACUUM 碎片整理与紧缩，释放无效空间，加速应用访问（严格遵循宪章，不触碰邮件、通讯录与钥匙串）。", "對本地受支持應用的高頻 SQLite 數據庫執行 VACUUM 碎片整理與緊縮，釋放無效空間，加速應用訪問（嚴格遵循憲章，不觸碰郵件、通訊錄與鑰匙串）。", "Run SQLite VACUUM on non-sensitive local application databases to defragment and speed up queries.", "ローカルアプリの SQLite データベースを最適化（VACUUM）し、不要領域を回収してアクセスを高速化します。", "지원되는 로컬 앱의 SQLite 데이터베이스를 조각 모음(VACUUM)하여 공간을 확보하고 접근 속도를 높입니다.",
            "Exécutez VACUUM sur les bases de données SQLite locales pour défragmenter et accélérer les requêtes.", "Führt SQLite VACUUM auf lokalen App-Datenbanken aus, um diese zu defragmentieren und zu beschleunigen.", "Ejecuta VACUUM en bases de datos SQLite locales para desfragmentar y acelerar el acceso a las aplicaciones.", "Esegui VACUUM sui database SQLite delle app locali per deframmentare e velocizzare le query.", "Execute SQLite VACUUM nos bancos de dados locais de aplicativos para desfragmentar e acelerar as consultas.")
        add(.startWithAFastAndComprehensiveScanForYourMac, "作为开始，给 Mac 进行一次快速而全面的扫描吧。", "作為開始，給 Mac 進行一次快速而全面的掃描吧。", "Start with a fast and comprehensive scan for your Mac.", "まずは Mac を素早く包括的にスキャンしましょう。", "시작으로 Mac을 빠르고 종합적으로 스캔해 보세요.",
            "Commencez par une analyse rapide et complète de votre Mac.", "Starten Sie mit einem schnellen und umfassenden Scan Ihres Mac.", "Comienza con un análisis rápido y exhaustivo de tu Mac.", "Inizia con una scansione rapida e completa del tuo Mac.", "Comece com uma verificação rápida e completa do seu Mac.")
        add(.startingMaintenanceTasksCountFormat, "开始运行 %d 项维护任务…", "開始運行 %d 項維護任務…", "Starting %d maintenance tasks…", "%d 件のメンテナンスタスクを開始中…", "%d개 유지보수 작업 실행 시작…",
            "Démarrage de %d tâches de maintenance…", "Starte %d Wartungsaufgaben…", "Iniciando %d tareas de mantenimiento…", "Avvio di %d attività di manutenzione…", "Iniciando %d tarefas de manutenção…")
        add(.startup, "启动项", "啟動項", "Startup", "起動項目", "시작 프로그램",
            "Démarrage", "Autostart", "Inicio", "Avvio", "Inicialização")
        add(.startupBackgroundDaemonsEmptyNote, "常驻系统守护进程、Brew 服务与后台伴随进程会显示在这里", "常駐系統守護進程、Brew 服務與後台伴隨進程會顯示在這裡", "Resident system daemons, Homebrew services, and background helper processes will appear here", "常駐システムデーモン、Homebrew サービス、バックグラウンドプロセスがここに表示されます", "상주 시스템 데몬, Homebrew 서비스 및 백그라운드 도우미 프로세스가 여기에 표시됩니다",
            "Les démons résidents, services Homebrew et processus d'arrière-plan apparaîtront ici", "Dauerhafte System-Daemons, Homebrew-Dienste und Hintergrundprozesse werden hier aufgeführt", "Los demonios del sistema, servicios de Brew y procesos en segundo plano se mostrarán aquí", "I demoni di sistema residenti, i servizi Brew e i processi di supporto appariranno qui", "Daemons residentes do sistema, serviços do Brew e processos em segundo plano aparecerão aqui")
        add(.startupDisableUnusedProcessesDesc, "停用不常使用的进程将释放应用内存。您可以随时根据需要启用或关闭它们。", "停用不常使用的進程將釋放應用內存。您可以隨時根據需要啟用或關閉它們。", "Disabling rarely used processes frees memory. You can enable or disable them anytime.", "使用頻度の低いプロセスを停止することでメモリを節約します。必要に応じていつでも有効化できます。", "자주 사용하지 않는 프로세스를 비활성화하면 메모리가 절약되며 언제든 다시 켤 수 있습니다.",
            "Désactiver les processus inutilisés libère de la mémoire. Réactivez-les à tout moment selon vos besoins.", "Deaktivieren seltener genutzter Prozesse spart RAM. Sie können sie jederzeit wieder aktivieren.", "Desactivar procesos que rara vez usa libera memoria. Puede activarlos o desactivarlos cuando quiera.", "Disattivare i processi usati raramente libera memoria. Puoi riattivarli in qualsiasi momento.", "Desativar processos raramente usados libera memória. Você pode ativá-los ou desativá-los a qualquer momento.")
        add(.startupDisk, "启动磁盘", "啟動磁碟", "Startup Disk", "起動ディスク", "시동 디스크",
            "Disque de démarrage", "Startvolume", "Disco de arranque", "Disco di avvio", "Disco de Inicialização")
        add(.startupItemConfigNotFound, "未找到对应的启动项配置", "未找到對應的啟動項配置", "Startup item configuration not found", "スタートアップ項目の設定が見つかりません", "시작 프로그램 설정을 찾을 수 없습니다",
            "Configuration de l'élément de démarrage introuvable", "Startobjekt-Konfiguration nicht gefunden", "No se encontró la configuración del elemento de inicio", "Configurazione elemento di avvio non trovata", "Configuração do item de inicialização não encontrada")
        add(.startupManageDaemonsDesc, "管理在后台运行的守护进程、Brew 服务与系统伴随服务。您可以在这里方便地停用或启用它们。", "管理在後台運行的守護進程、Brew 服務與系統伴隨服務。您可以在這裡方便地停用或啟用它們。", "Manage background daemons, Homebrew services, and system helpers. Easily enable or disable them here.", "常駐デーモン、Homebrew サービス、システムヘルパーを管理し、簡単にオン・オフを切り替えられます。", "백그라운드 데몬, Homebrew 서비스 및 보조 서비스를 관리하며 쉽게 활성화하거나 끌 수 있습니다.",
            "Gérez les démons, services Homebrew et processus système en arrière-plan. Activez-les ou désactivez-les facilement.", "Hintergrund-Daemons, Homebrew-Dienste und Systemhelfer bequem aktivieren oder deaktivieren.", "Gestione demonios en segundo plano, servicios de Brew y ayudantes del sistema fácilmente.", "Gestisci demoni in background, servizi Brew e helper di sistema. Abilitali o disabilitali facilmente.", "Gerencie daemons em segundo plano, serviços do Homebrew e auxiliares do sistema facilmente aqui.")
        add(.startupManageLoginItemsDesc, "管理在开机时可以自动启动的应用程序。不要让您的 Mac 将太多性能浪费在不需要的进程上。", "管理在開機時可以自動啟動的應用程序。不要讓您的 Mac 將太多性能浪費在不需要的進程上。", "Manage applications that start automatically at login to avoid wasting system resources.", "ログイン時に自動起動するアプリを管理し、不要なプロセスの消費を抑えます。", "로그인 시 자동 실행되는 앱을 관리하여 불필요한 시스템 리소스 낭비를 방지하세요.",
            "Gérez les applications lancées au démarrage pour éviter de gaspiller des ressources système.", "Verwalten Sie Autostart-Apps, um keine wertvolle Systemleistung zu verschwenden.", "Gestione las aplicaciones de inicio para no desperdiciar recursos del sistema.", "Gestisci le app che si avviano all'accesso per evitare sprechi di risorse di sistema.", "Gerencie os aplicativos que iniciam no login para não desperdiçar recursos do sistema.")
        add(.startupSystemDaemonsDesc, "在后台常驻运行的系统服务。", "在後台常駐運行的系統服務。", "System background services running residently in the background.", "バックグラウンドで常駐実行されているシステムサービスです。", "백그라운드에서 상주 실행되는 시스템 서비스입니다.",
            "Services système résidents fonctionnant en arrière-plan.", "Dauerhaft im Hintergrund ausgeführte Systemdienste.", "Servicios del sistema que se ejecutan de forma residente en segundo plano.", "Servizi di sistema residenti in esecuzione in background.", "Serviços de sistema residentes em execução em segundo plano.")
        add(.startupUserLoginItemsEmptyNote, "随用户登录自启的应用与登录代理会显示在这里", "隨用戶登錄自啟的應用與登錄代理會顯示在這裡", "Apps and login agents configured to launch at user login will appear here", "ユーザーログイン時に自動起動するアプリやエージェントがここに表示されます", "사용자 로그인 시 자동 실행되는 앱 및 로그인 에이전트가 여기에 표시됩니다",
            "Les applications et agents configurés pour s'ouvrir à l'ouverture de session apparaîtront ici", "Apps und Anmeldeobjekte, die beim Login automatisch starten, werden hier angezeigt", "Las aplicaciones y agentes configurados para abrirse al iniciar sesión aparecerán aquí", "Le app e gli agenti configurati per aprirsi all'accesso dell'utente appariranno qui", "Os aplicativos e agentes configurados para iniciar no login do usuário aparecerão aqui")
        add(.statusActive, "活跃中", "活躍中", "Active", "アクティブ", "활성 상태",
            "Actif", "Aktiv", "Activo", "Attivo", "Ativo")
        add(.statusAppScanning, "应用扫描中", "應用程式掃描中", "Scanning Apps", "アプリをスキャン中", "앱 스캔 중",
            "Analyse des applications", "Programme werden gescannt", "Escaneando aplicaciones", "Scansione applicazioni", "Escaneando Aplicativos")
        add(.statusAssessingEllipsis, "正在评估…", "正在評估…", "Assessing…", "評価中…", "평가 중…",
            "Évaluation en cours…", "Wird bewertet…", "Evaluando…", "Valutazione in corso…", "Avaliando…")
        add(.statusBuildingSpaceMapPrompt, "正在构建空间透视图…", "正在構建空間透視圖…", "Building Space Lens Map…", "スペースレンズマップを構築中…", "스페이스 렌즈 맵을 생성하는 중…",
            "Construction de la carte d'espace…", "Erstelle Speicherlinsen-Karte…", "Creando mapa espacial…", "Creazione della mappa dello spazio in corso…", "Criando mapa da lente de espaço…")
        add(.statusCalculating, "计算中", "計算中", "Calculating", "計算中", "계산 중",
            "Calcul en cours", "Berechnung läuft", "Calculando", "Calcolo in corso", "Calculando")
        add(.statusCheckingBackgroundAppsAndProcessesPrompt, "检查在后台运行的应用程序与进程…", "檢查在後台運行的應用程式與進程…", "Checking applications and processes running in the background…", "バックグラウンドで動作中のアプリとプロセスを確認中…", "백그라운드에서 실행 중인 앱 및 프로세스 확인 중…",
            "Vérification des applications et processus en arrière-plan…", "Überprüfung der im Hintergrund ausgeführten Apps und Prozesse…", "Comprobando aplicaciones y procesos en segundo plano…", "Verifica delle applicazioni e dei processi in background…", "Verificando aplicativos e processos em segundo plano…")
        add(.statusCheckingDownloadsPrompt, "检查可能不再需要的下载文件…", "檢查可能不再需要的下載檔案…", "Checking downloaded files that might no longer be needed…", "不要になった可能性のあるダウンロードファイルを確認中…", "더 이상 필요하지 않을 수 있는 다운로드 파일 확인 중…",
            "Vérification des téléchargements potentiellement obsolètes…", "Überprüfung möglicherweise nicht mehr benötigter Downloads…", "Comprobando descargas que quizá ya no necesite…", "Verifica dei download che potrebbero non servire più…", "Verificando downloads que podem não ser mais necessários…")
        add(.statusCheckingLocalSnapshotsAndMemoryPrompt, "检查本地快照与内存状态…", "檢查本機快照與記憶體狀態…", "Checking local snapshots and memory pressure…", "ローカルスナップショットとメモリ状態を確認中…", "로컬 스냅샷 및 메모리 상태 확인 중…",
            "Vérification des instantanés locaux et de la mémoire…", "Überprüfung lokaler Snapshots und des Speicherstatus…", "Comprobando instantáneas locales y estado de la memoria…", "Verifica delle snapshot locali e dello stato della memoria…", "Verificando instantâneos locais e estado da memória…")
        add(.statusCheckingLoginAppsPrompt, "检查开机自动启动的应用程序…", "檢查開機自動啟動的應用程式…", "Checking applications configured to launch on startup…", "ログイン時に自動起動するアプリを確認中…", "로그인 시 자동 시작되는 앱 확인 중…",
            "Vérification des applications lancées au démarrage…", "Überprüfung der beim Start automatisch startenden Apps…", "Comprobando aplicaciones configuradas para iniciarse al arrancar…", "Verifica delle applicazioni avviate all'avvio del sistema…", "Verificando aplicativos que iniciam com o sistema…")
        add(.statusCleanCompleted, "清理完成！", "清理完成！", "Cleanup Complete!", "クリーンアップ完了！", "정리 완료!",
            "Nettoyage terminé !", "Bereinigung abgeschlossen!", "¡Limpieza completada!", "Pulizia completata!", "Limpeza Concluída!")
        add(.statusComparingDuplicateFilesPrompt, "比对并查找内容完全相同的重复文件…", "比對並尋找內容完全相同的重複檔案…", "Comparing and locating exact duplicate files…", "完全に一致する重複ファイルを比較・検出中…", "완전히 동일한 중복 파일 비교 및 검색 중…",
            "Comparaison et localisation des fichiers en double…", "Vergleich und Suche nach identischen Duplikaten…", "Comparando y localizando archivos duplicados exactos…", "Confronto e individuazione dei file duplicati esatti…", "Comparando e localizando duplicatas exatas…")
        add(.statusConnected, "已连接", "已連線", "Connected", "接続済み", "연결됨",
            "Connecté", "Verbunden", "Conectado", "Connesso", "Conectado")
        add(.statusCritical, "紧急", "緊急", "Critical", "緊急", "긴급",
            "Critique", "Kritisch", "Crítico", "Critico", "Crítico")
        add(.statusDeepDiagnosing, "深度排查中", "深度排查中", "Deep Diagnosing", "詳細診断中", "정밀 진단 중",
            "Diagnostic approfondi", "Tiefendiagnose läuft", "Diagnóstico profundo", "Diagnostica approfondita", "Diagnóstico Profundo")
        add(.statusDeepScanning, "深度扫描中", "深度掃描中", "Deep Scanning", "詳細スキャン中", "정밀 스캔 중",
            "Analyse approfondie en cours", "Tiefenscan läuft", "Escaneo profundo en curso", "Scansione approfondita in corso", "Escaneamento Profundo em Andamento")
        add(.statusDisable, "停用", "停用", "Disable", "無効化", "비활성화",
            "Désactiver", "Deaktivieren", "Desactivar", "Disabilita", "Desativar")
        add(.statusDisabled, "已停用", "已停用", "Disabled", "無効", "비활성화됨",
            "Désactivé", "Deaktiviert", "Desactivado", "Disabilitato", "Desativado")
        add(.statusDisplayed, "已显示", "已顯示", "Visible", "表示中", "표시됨",
            "Affiché", "Angezeigt", "Visible", "Visibile", "Visível")
        add(.statusEnable, "启用", "啟用", "Enable", "有効化", "활성화",
            "Activer", "Aktivieren", "Activar", "Abilita", "Ativar")
        add(.statusEnabled, "已启用", "已啟用", "Enabled", "有効", "활성화됨",
            "Activé", "Aktiviert", "Activado", "Abilitato", "Ativado")
        add(.statusExecuted, "已执行", "已執行", "Executed", "実行済み", "실행됨",
            "Exécuté", "Ausgeführt", "Ejecutado", "Eseguito", "Executado")
        add(.statusFailed, "失败", "失敗", "Failed", "失敗", "실패",
            "Échoué", "Fehlgeschlagen", "Fallido", "Non riuscito", "Falhou")
        add(.statusFindingAbandonedInstallersPrompt, "查找已废弃的应用程序安装包…", "尋找已廢棄的應用程式安裝套件…", "Locating abandoned application installers…", "不要になったアプリケーションインストーラを検索中…", "방치된 응용 프로그램 설치 프로그램 검색 중…",
            "Localisation des installateurs d'applications abandonnés…", "Suche nach verwaisten Installationspaketen…", "Localizando instaladores de aplicaciones obsoletos…", "Individuazione dei pacchetti di installazione abbandonati…", "Localizando instaladores de aplicativos descartados…")
        add(.statusFindingLargeAndOldFilesPrompt, "查找 Mac 电脑上体积较大且长期未使用的文件…", "尋找 Mac 電腦上體積較大且長期未使用的檔案…", "Finding large and long-forgotten files on your Mac…", "Mac 上の大容量かつ長期間使用されていないファイルを検索中…", "Mac에서 대용량 및 오래된 파일 검색 중…",
            "Recherche des fichiers volumineux et anciens sur votre Mac…", "Suche nach großen und alten Dateien auf Ihrem Mac…", "Buscando archivos grandes y antiguos en el Mac…", "Ricerca di file grandi e vecchi sul tuo Mac…", "Localizando arquivos grandes e antigos no seu Mac…")
        add(.statusHidden, "已隐藏", "已隱藏", "Hidden", "非表示", "숨김",
            "Masqué", "Ausgeblendet", "Oculto", "Nascosto", "Oculto")
        add(.statusHigh, "偏高", "偏高", "High", "高め", "높음",
            "Élevé", "Hoch", "Alto", "Alto", "Alto")
        add(.statusHighLoad, "高负载", "高負載", "High Load", "高負荷", "높은 부하",
            "Charge élevée", "Hohe Last", "Carga alta", "Alto carico", "Carga Alta")
        add(.statusInvalid, "无效", "無效", "Invalid", "無効", "유효하지 않음",
            "Invalide", "Ungültig", "Inválido", "Non valido", "Inválido")
        add(.statusInvalidProgramMissing, "无效（程序不存在）", "無效（程式不存在）", "Invalid (program missing)", "無効（プログラムが存在しません）", "유효하지 않음(프로그램 없음)",
            "Invalide (programme introuvable)", "Ungültig (Programm fehlt)", "No válido (falta el programa)", "Non valido (programma mancante)", "Inválido (programa ausente)")
        add(.statusItemsCalculating, "项计算中", "項計算中", "items calculating", "項目計算中", "개 항목 계산 중",
            "éléments en cours de calcul", "Objekte in Berechnung", "elementos calculando", "elementi in calcolo", "itens calculando")
        add(.statusLatest, "最新", "最新", "Latest", "最新", "최신",
            "Le plus récent", "Neueste", "Más reciente", "Più recente", "Mais Recente")
        add(.statusLowLoad, "低负载", "低負載", "Low Load", "低負荷", "낮은 부하",
            "Faible charge", "Geringe Last", "Carga baja", "Basso carico", "Carga Baixa")
        add(.statusMediumLoad, "中负载", "中負載", "Medium Load", "中負荷", "중간 부하",
            "Charge moyenne", "Mittlere Last", "Carga media", "Carico medio", "Carga Média")
        add(.statusModerate, "中等", "中等", "Moderate", "普通", "보통",
            "Modéré", "Mittel", "Moderado", "Moderato", "Moderado")
        add(.statusNormal, "正常", "正常", "Normal", "正常", "정상",
            "Normal", "Normal", "Normal", "Normale", "Normal")
        add(.statusNotOpenedRecently, "近期未打开", "近期未打開", "Not Opened Recently", "最近開かれていません", "최근 열지 않음",
            "Non ouvert récemment", "Kürzlich nicht geöffnet", "No abierto recientemente", "Non aperto di recente", "Não aberto recentemente")
        add(.statusNotYetScanned, "尚未扫描", "尚未掃描", "Not Yet Scanned", "未スキャン", "아직 검사하지 않음",
            "Pas encore analysé", "Noch nicht gescannt", "Aún no escaneado", "Non ancora scansionato", "Ainda não verificado")
        add(.statusOperationCancelledOrFailed, "操作被取消或失败", "操作被取消或失敗", "Operation cancelled or failed", "操作がキャンセルされたか失敗しました", "작업이 취소되었거나 실패했습니다",
            "Opération annulée ou échouée", "Vorgang abgebrochen oder fehlgeschlagen", "Operación cancelada o fallida", "Operazione annullata o non riuscita", "Operação cancelada ou com falha")
        add(.statusPointedProgramMissing, "指向的程序不存在", "指向的程式不存在", "Target application does not exist", "対象のプログラムが存在しません", "대상 프로그램이 존재하지 않음",
            "L'application cible n'existe pas", "Zielprogramm existiert nicht", "El programa de destino no existe", "Il programma di destinazione non esiste", "O programa de destino não existe")
        add(.statusPrefix, "状态", "狀態", "Status", "状態", "상태",
            "État", "Status", "Estado", "Stato", "Status")
        add(.statusPreparingToolsPrompt, "正在准备工具…", "正在準備工具…", "Preparing utilities…", "ツールを準備中…", "도구 준비 중…",
            "Préparation des outils…", "Werkzeuge werden vorbereitet…", "Preparando herramientas…", "Preparazione degli strumenti…", "Preparando ferramentas…")
        add(.statusQuitRequested, "已请求退出", "已請求退出", "Quit Requested", "終了要求済み", "종료 요청됨",
            "Arrêt demandé", "Beenden angefordert", "Salida solicitada", "Chiusura richiesta", "Encerramento solicitado")
        add(.statusReadingInstalledApps, "读取已安装应用", "讀取已安裝應用", "Reading installed applications", "インストール済みアプリを読み込み中", "설치된 응용 프로그램 읽는 중",
            "Lecture des applications installées", "Installierte Anwendungen werden gelesen", "Leyendo aplicaciones instaladas", "Lettura delle applicazioni installate", "Lendo aplicativos instalados")
        add(.statusReady, "准备就绪", "準備就緒", "Ready", "準備完了", "준비 완료",
            "Prêt", "Bereit", "Listo", "Pronto", "Pronto")
        add(.statusRunning, "运行中", "運行中", "Running", "実行中", "실행 중",
            "En cours d'exécution", "Läuft", "En ejecución", "In esecuzione", "Em execução")
        add(.statusRunningEllipsis, "运行中…", "運行中…", "Running…", "実行中…", "실행 중…",
            "En cours…", "Wird ausgeführt…", "En ejecución…", "In esecuzione…", "Em execução…")
        add(.statusSafelySkipped, "安全跳过", "安全略過", "Safely Skipped", "安全にスキップ", "안전하게 건너뜀",
            "Ignoré en toute sécurité", "Sicher übersprungen", "Omitido de forma segura", "Saltato in sicurezza", "Ignorado com Segurança")
        add(.statusScanCompleted, "扫描完成", "掃描完成", "Scan Completed", "スキャン完了", "스캔 완료",
            "Analyse terminée", "Scan abgeschlossen", "Escaneo completado", "Scansione completata", "Escaneamento Concluído")
        add(.statusScanStoppedPartialResults, "扫描已停止,已保留部分结果", "掃描已停止，已保留部分結果", "Scan stopped. Partial results retained.", "スキャンを停止しました。一部の結果を保持しています。", "스캔이 중지되었습니다. 일부 결과가 유지되었습니다.",
            "Analyse arrêtée. Résultats partiels conservés.", "Scan gestoppt. Teilergebnisse beibehalten.", "Escaneo detenido. Se conservaron resultados parciales.", "Scansione interrotta. Risultati parziali mantenuti.", "Escaneamento parado. Resultados parciais mantidos.")
        add(.statusScanningAllDirsAndLargeFilesPrompt, "正在扫描全盘目录与大文件分布…", "正在掃描全盤目錄與大文件分布…", "Scanning all directories and large file distribution…", "すべてのディレクトリと大容量ファイルの分布をスキャン中…", "전체 디렉터리 및 대용량 파일 분포 검사 중…",
            "Analyse de tous les répertoires et gros fichiers…", "Scanne alle Verzeichnisse und Verteilung großer Dateien…", "Escaneando todos los directorios y archivos grandes…", "Scansione di tutte le directory e file grandi in corso…", "Escaneando todos os diretórios e distribuição de arquivos grandes…")
        add(.statusScanningAppLeftovers, "扫描应用残留文件", "掃描應用殘留檔案", "Scanning application leftovers", "アプリの残りファイルをスキャン中", "응용 프로그램 잔여 파일 스캔 중",
            "Analyse des résidus d'applications", "Suche nach App-Überresten", "Escaneando restos de aplicaciones", "Scansione residui delle app", "Verificando resíduos de aplicativos")
        add(.statusScanningAppsAndLeftoversPrompt, "正在查找应用程序和残留文件。", "正在尋找應用程式和殘留檔案。", "Searching for applications and leftover files.", "アプリケーションと残りファイルを検索中。", "애플리케이션 및 잔여 파일을 찾는 중입니다.",
            "Recherche des applications et des fichiers résiduels en cours.", "Suche nach Anwendungen und Restdateien.", "Buscando aplicaciones y archivos sobrantes.", "Ricerca di applicazioni e file residui in corso.", "Procurando aplicativos e arquivos residuais.")
        add(.statusScanningDuplicatesAndUnneededFilesPrompt, "正在查找重复文件以及可能不需要的文件…", "正在尋找重複檔案以及可能不需要的檔案…", "Searching for duplicates and potentially unneeded files…", "重複ファイルおよび不要な可能性のあるファイルを検索中…", "중복 파일 및 불필요할 수 있는 파일을 검색 중…",
            "Recherche de doublons et de fichiers superflus…", "Suche nach Duplikaten und potenziell unnötigen Dateien…", "Buscando archivos duplicados y prescindibles…", "Ricerca di duplicati e file potenzialmente non necessari…", "Procurando arquivos duplicados e dispensáveis…")
        add(.statusScanningEllipsis, "正在扫描…", "正在掃描…", "Scanning…", "スキャン中…", "검사 중…",
            "Analyse en cours…", "Scannen…", "Escaneando…", "Scansione in corso…", "Escaneando…")
        add(.statusScanningMacPrompt, "正在扫描您的 Mac…", "正在掃描您的 Mac…", "Scanning your Mac…", "Mac をスキャン中…", "Mac 스캔 중…",
            "Analyse de votre Mac en cours…", "Ihr Mac wird gescannt…", "Analizando su Mac…", "Scansione del tuo Mac in corso…", "Verificando seu Mac…")
        add(.statusScanningSimilarPhotosPrompt, "扫描图库与磁盘中的相似照片…", "掃描圖庫與磁碟中的相似照片…", "Scanning photos and disk for similar shots…", "フォトライブラリとディスク内の類似写真をスキャン中…", "사진 보관함 및 디스크에서 유사한 사진 스캔 중…",
            "Analyse des photos similaires dans la photothèque et le disque…", "Scannen der Fotomediathek und Festplatte nach ähnlichen Fotos…", "Escaneando la fototeca y el disco en busca de fotos similares…", "Scansione della libreria e del disco per foto simili…", "Verificando a fototeca e o disco em busca de fotos semelhantes…")
        add(.statusSpaceAnalyzingTitle, "空间分析中", "空間分析中", "Space Analysis in Progress", "スペース分析中", "공간 분석 중",
            "Analyse de l'espace en cours", "Speicheranalyse läuft", "Análisis de espacio en curso", "Analisi dello spazio in corso", "Análise de espaço em andamento")
        add(.statusStopping, "正在停止…", "正在停止…", "Stopping…", "停止中…", "중지 중…",
            "Arrêt en cours…", "Wird angehalten…", "Deteniendo…", "Arresto in corso…", "Parando…")
        add(.statusSuccessfullyCleaned, "成功清理", "成功清理", "Successfully Cleaned", "正常にクリーンアップ", "성공적으로 정리됨",
            "Nettoyé avec succès", "Erfolgreich bereinigt", "Limpieza correcta", "Pulito con successo", "Limpeza Concluída com Sucesso")
        add(.statusTargetBinaryMissing, "指向的程序不存在", "指向的程式不存在", "Target application is missing", "対象のアプリが存在しません", "대상 프로그램이 존재하지 않습니다",
            "L'application cible est introuvable", "Zielprogramm nicht vorhanden", "El programa de destino no existe", "Il programma di destinazione non esiste", "O aplicativo de destino não existe")
        add(.statusTight, "紧张", "緊張", "Tight", "逼迫", "부족",
            "Saturé", "Knapp", "Ajustado", "Critico", "Apertado")
        add(.statusUnknown, "未知", "未知", "Unknown", "不明", "알 수 없음",
            "Inconnu", "Unbekannt", "Desconocido", "Sconosciuto", "Desconhecido")
        add(.statusUnknownUnreadable, "状态未知（无法读取）", "狀態未知（無法讀取）", "State unknown (unreadable)", "状態不明（読み取り不可）", "상태 알 수 없음(읽을 수 없음)",
            "État inconnu (illisible)", "Status unbekannt (nicht lesbar)", "Estado desconocido (ilegible)", "Stato sconosciuto (illeggibile)", "Estado desconhecido (ilegível)")
        add(.statusWarning, "警告", "警告", "Warning", "警告", "경고",
            "Avertissement", "Warnung", "Advertencia", "Avviso", "Aviso")
        add(.stopDiagnosis, "停止体检", "停止體檢", "Stop Diagnosis", "診断を停止", "진단 중지",
            "Arrêter le diagnostic", "Diagnose stoppen", "Detener diagnóstico", "Interrompi diagnosi", "Parar Diagnóstico")
        add(.strategyLargest, "最大", "最大", "Largest", "最大", "가장 큼",
            "Plus grand", "Größte", "Más grande", "Più grande", "Maior")
        add(.strategyNewest, "最新", "最新", "Newest", "最新", "가장 최신",
            "Plus récent", "Neueste", "Más reciente", "Più recente", "Mais recente")
        add(.strategyOldest, "最旧", "最舊", "Oldest", "最も古い", "가장 오래됨",
            "Plus ancien", "Älteste", "Más antiguo", "Più vecchio", "Mais antigo")
        add(.subPanelNetworkTitle, "网络与 IP", "網路與 IP", "Network & IP", "ネットワークと IP", "네트워크 및 IP",
            "Réseau et IP", "Netzwerk & IP", "Red e IP", "Rete e IP", "Rede e IP")
        add(.subPanelProcessesTitle, "进程与传感器", "處理程序與感測器", "Processes & Sensors", "プロセスとセンサー", "프로세스 및 센서",
            "Processus et capteurs", "Prozesse & Sensoren", "Procesos y sensores", "Processi e sensori", "Processos e Sensores")
        add(.subPanelWeatherTitle, "实时天气", "即時天氣", "Live Weather", "リアルタイム天気", "실시간 날씨",
            "Météo en direct", "Echtzeit-Wetter", "Clima en directo", "Meteo in tempo reale", "Clima em Tempo Real")
        add(.swapSpace, "交换空间", "交換空間", "Swap Space", "スワップ領域", "스왑 공간",
            "Espace d’échange (Swap)", "Auslagerungsspeicher (Swap)", "Espacio de intercambio (Swap)", "Spazio di swap", "Espaço Swap")
        add(.swapUsedMemory, "交换内存 (Swap Used)", "交換記憶體 (Swap Used)", "Swap Used", "スワップ使用領域", "스왑 사용량 (Swap Used)",
            "Fichier d’échange utilisé (Swap)", "Auslagerungsdatei (Swap)", "Memoria swap utilizada", "Spazio di swap utilizzato", "Swap Utilizado")
        add(.switchToOrbitLens, "切换到行星透镜", "切換到行星透鏡", "Switch to Orbit Lens", "惑星レンズに切替", "행성 렌즈로 전환",
            "Passer à la vue Orbitale", "Zur Orbit-Linse wechseln", "Cambiar a lente orbital", "Passa alla vista Orbitale", "Alternar para Lente Orbital")
        add(.switchToTreemap, "切换到矩形树图", "切換到矩形樹圖", "Switch to Treemap", "ツリーマップに切替", "트리맵으로 전환",
            "Passer au Treemap", "Zur Treemap-Ansicht wechseln", "Cambiar a mapa de árbol", "Passa al Treemap", "Alternar para Treemap")
        add(.system, "系统", "系統", "System", "システム", "시스템",
            "Système", "System", "Sistema", "Sistema", "Sistema")
        add(.systemAndCrashLogs, "系统与诊断日志", "系統與診斷日誌", "System & Crash Logs", "システム・診断ログ", "시스템 및 진단 로그",
            "Journaux système et crash", "System- & Absturzprotokolle", "Registros del sistema", "Log di sistema e crash", "Logs do Sistema e Falhas")
        add(.systemCachesDiagnosticReportsAndLocalSnapshots, "系统缓存、诊断日志和本地快照", "系統快取、診斷日誌和本機快照", "System caches, diagnostic reports, and local snapshots", "システムキャッシュ、診断ログ、ローカルスナップショット", "시스템 캐시, 진단 로그 및 로컬 스냅샷",
            "Caches système, journaux de diagnostic et instantanés locaux", "System-Caches, Diagnoseprotokolle und lokale Schnappschüsse", "Cachés del sistema, registros de diagnóstico e instantáneas locales", "Cache di sistema, log diagnostici e snapshot locali", "Caches do sistema, logs de diagnóstico e snapshots locais")
        add(.systemDaemon, "守护进程", "系統守護程序", "System Daemon", "システムデーモン", "시스템 데몬",
            "Démon système", "System-Daemon", "Demonio del sistema", "Demone di sistema", "Daemon do Sistema")
    }

    static func populateBatch13(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.systemJunk, "系统垃圾", "系統垃圾", "System Junk", "システムキャッシュとログ", "시스템 캐시 및 로그",
            "Cache et journaux système", "System-Caches & Protokolle", "Caché y registros del sistema", "Cache e log di sistema", "Caches e Logs do Sistema")
        add(.systemOptimize, "系统优化", "系統最佳化", "System Optimize", "システム最適化", "시스템 최적화",
            "Optimisation système", "Systemoptimierung", "Optimización del sistema", "Ottimizzazione sistema", "Otimização do Sistema")
        add(.systemPowerWatts, "电源功率", "電源功率", "System Power", "システム電力", "시스템 전력",
            "Puissance système", "Systemleistung", "Potencia del sistema", "Potenza sistema", "Potência do Sistema")
        add(.systemPrefix, "系统", "系統", "System", "システム", "시스템",
            "Système", "System", "Sistema", "Sistema", "Sistema")
        add(.systemProxy, "系统代理", "系統代理", "System Proxy", "システムプロキシ", "시스템 프록시",
            "Proxy système", "System-Proxy", "Proxy del sistema", "Proxy di sistema", "Proxy do sistema")
        add(.systemProxyOrTun, "系统代理 / TUN", "系統代理 / TUN", "System Proxy / TUN", "システムプロキシ / TUN", "시스템 프록시 / TUN",
            "Proxy système / TUN", "System-Proxy / TUN", "Proxy del sistema / TUN", "Proxy di sistema / TUN", "Proxy do sistema / TUN")
        add(.systemScope, "系统", "系統", "System", "システム", "시스템",
            "Système", "System", "Sistema", "Sistema", "Sistema")
        add(.systemSessionTracing, "系统会话追踪", "系統會話追蹤", "System Session Tracing", "システムセッショントラッキング", "시스템 세션 추적",
            "Traçage de session système", "Systemsitzungs-Verfolgung", "Seguimiento de sesión del sistema", "Tracciamento sessione di sistema", "Rastreamento de sessão do sistema")
        add(.systemSpaceReclaim, "系统级安全回收", "系統級安全回收", "System Space Reclaim", "システム領域の安全回収", "시스템 수준 안전 회수",
            "Récupération sécurisée de l’espace système", "Sichere Systemspeicherplatz-Rückgewinnung", "Recuperación segura de espacio del sistema", "Recupero sicuro dello spazio di sistema", "Recuperação Segura de Espaço do Sistema")
        add(.systemUptimeLabel, "已开机", "已開機", "Uptime", "稼働時間", "가동 시간",
            "Temps de fonctionnement", "Betriebszeit", "Tiempo activo", "Tempo di attività", "Tempo de atividade")
        add(.systemWiredMemory, "系统联动内存 (Wired)", "系統連動記憶體 (Wired)", "Wired Memory", "固定メモリ (Wired)", "시스템 고정 메모리 (Wired)",
            "Mémoire résidente (Wired)", "Fester Speicher (Wired)", "Memoria fija (Wired)", "Memoria vincolata (Wired)", "Memória Bloqueada (Wired)")
        add(.tabAllCompleteView, "全部完整视图", "全部完整視圖", "Complete View", "全体表示", "전체 보기",
            "Vue complète", "Vollständige Ansicht", "Vista completa", "Visualizzazione completa", "Visão completa")
        add(.tabDropdownSections, "下拉弹窗卡片", "下拉彈窗卡片", "Dropdown Cards", "ドロップダウンカード", "드롭다운 카드",
            "Cartes déroulantes", "Dropdown-Karten", "Tarjetas desplegables", "Schede a comparsa", "Cartões suspensos")
        add(.tabLeftovers, "残留", "殘留檔案", "Leftovers", "残存ファイル", "잔여 파일",
            "Résidus", "Reste", "Residuos", "Residui", "Resíduos")
        add(.tabMenuBarDisplayItems, "顶部菜单栏显示项", "頂部菜單欄顯示項", "Menu Bar Items", "メニューバー表示項目", "메뉴 막대 표시 항목",
            "Éléments de la barre des menus", "Menüleisten-Elemente", "Elementos de barra de menús", "Elementi della barra dei menu", "Itens da barra de menus")
        add(.tabMenuBarTokens, "顶部菜单栏模块", "頂部菜單欄模塊", "Menu Bar Tokens", "メニューバー指標", "메뉴 막대 항목",
            "Indicateurs de la barre des menus", "Menüleisten-Elemente", "Indicadores de barra de menús", "Elementi barra dei menu", "Itens da barra de menus")
        add(.tabUninstall, "卸载", "解除安裝", "Uninstall", "アンインストール", "제거",
            "Désinstaller", "Deinstallieren", "Desinstalar", "Disinstalla", "Desinstalar")
        add(.tabUpdates, "更新", "更新", "Updates", "アップデート", "업데이트",
            "Mises à jour", "Updates", "Actualizaciones", "Aggiornamenti", "Atualizações")
        add(.tableHeaderStatus, "状态", "狀態", "Status", "状態", "상태",
            "État", "Status", "Estado", "Stato", "Status")
        add(.tagCleanUninstall, "连根拔起关联数据", "連根拔起關聯資料", "Eradicate Associated Data", "関連データを一括削除", "연관 데이터 완전 제거",
            "Suppression des données associées", "Zugehörige Daten restlos entfernen", "Eliminar datos asociados", "Rimuovi tutti i dati associati", "Eliminar Dados Associados")
        add(.tagDmgPkgImages, "DMG / PKG 镜像", "DMG / PKG 鏡像", "DMG / PKG Images", "DMG / PKG ディスクイメージ", "DMG / PKG 이미지",
            "Images disques DMG / PKG", "DMG- / PKG-Images", "Imágenes DMG / PKG", "Immagini disco DMG / PKG", "Imagens DMG / PKG")
        add(.tagHistoricalArchives, "历史未用归档", "歷史未用歸檔", "Historical Archives", "長期未使用アーカイブ", "이전 미사용 압축파일",
            "Archives historiques", "Alte Archive", "Archivos comprimidos antiguos", "Archivi storici inutilizzati", "Arquivos Compactados Antigos")
        add(.tagPerceptualHashMatch, "感知哈希比对", "感知哈希比對", "Perceptual Hash Match", "知覚ハッシュによる画像照合", "인식 해시 대조",
            "Correspondance par hachage perceptuel", "Perzeptiver Hash-Abgleich", "Coincidencia de hash perceptual", "Corrispondenza hash percettivo", "Correspondência de Hash Perceptual")
        add(.tagSha256Match, "SHA-256 比对", "SHA-256 比對", "SHA-256 Checksum", "SHA-256 ハッシュ照合", "SHA-256 대조",
            "Somme de contrôle SHA-256", "SHA-256-Prüfsummenabgleich", "Comparación SHA-256", "Verifica SHA-256", "Comparação SHA-256")
        add(.tagStartupComponents, "后台守护进程感知", "後台守護程序感知", "Background Daemons & Helpers", "バックグラウンド常駐デーモンを検知", "백그라운드 데몬 및 헬퍼 감지",
            "Détection des démons en arrière-plan", "Erkennung von Hintergrunddiensten", "Detección de demonios en segundo plano", "Rilevamento daemon in background", "Detecção de Daemons em Segundo Plano")
        add(.tagUnusedApps, "长期未运行识别", "長期未執行識別", "Identify Rarely Used Apps", "長期未起動アプリを識別", "장기 미실행 앱 식별",
            "Identifier les apps rarement ouvertes", "Lange ungenutzte Programme erkennen", "Identificar apps raramente usadas", "Identifica app usate raramente", "Identificar Apps Pouco Usados")
        add(.targetProtectedByWhitelistBlocked, "目标位于用户排除白名单保护范围内，已阻断清理", "目標位於用戶排除白名單保護範圍內，已阻斷清理", "Target is protected by user exclusion whitelist", "対象はホワイトリストにより保護されているため、処理がブロックされました", "대상이 사용자 제외 화이트리스트의 보호 범위 내에 있어 정리가 차단되었습니다",
            "La cible est protégée par la liste blanche d'exclusion, nettoyage bloqué", "Ziel ist durch die Ausschlussliste geschützt, Bereinigung blockiert", "El destino está protegido por la lista blanca de exclusión, limpieza bloqueada", "Il target è protetto dalla whitelist di esclusione, pulizia bloccata", "O destino está protegido pela lista branca de exclusão, limpeza bloqueada")
        add(.taskFlushDnsAndSpotlightDesc, "刷新 DNS 缓存并维护聚焦索引，解决网页解析异常与搜索不到文件", "刷新 DNS 緩存並維護聚焦索引，解決網頁解析異常與搜索不到文件", "Flush DNS cache and maintain Spotlight index to fix domain lookup and file search issues", "DNS キャッシュをフラッシュし、Spotlight インデックスを再構築して検索エラーを解消します", "DNS 캐시를 새로고침하고 Spotlight 색인을 정비하여 웹 접속 오류 및 검색 불량을 해결합니다",
            "Videz le cache DNS et entretenez l'index Spotlight pour corriger la résolution et la recherche", "DNS-Cache leeren und Spotlight-Index pflegen, um Domain- und Suchprobleme zu beheben", "Vacíe la caché DNS y mantenga Spotlight para corregir errores de resolución web y búsqueda", "Svuota la cache DNS e gestisci Spotlight per correggere la risoluzione dei domini e la ricerca", "Limpe o cache de DNS e mantenha o Spotlight para corrigir problemas de busca e de resolução web")
        add(.taskFreePurgeableAndRunMaintenanceDesc, "安全触发系统回收 APFS 可清除空间与本地临时快照占用", "安全觸發系統回收 APFS 可清除空間與本機臨時快照佔用", "Safely trigger macOS to reclaim APFS purgeable space and temporary local snapshots", "APFS パージ可能領域とローカル一時スナップショットの安全な解放を実行します", "APFS 제거 가능 공간 및 로컬 임시 스냅샷 점유 공간을 안전하게 회수합니다",
            "Récupérez en toute sécurité l'espace purgeable APFS et les instantanés locaux temporaires", "APFS-freigebbaren Speicherplatz und lokale Schnappschüsse sicher zurückgewinnen", "Recupere de forma segura el espacio purgable APFS y las instantáneas locales temporales", "Recupera in sicurezza lo spazio eliminabile APFS e le istantanee locali temporanee", "Recupere com segurança o espaço purgável APFS e os instantâneos locais temporários")
        add(.taskRebuildLaunchServicesDesc, "重置快速查看与图标缓存，并禁止在外置卷与网络共享目录生成 .DS_Store", "重置快速查看與圖示快取，並禁止在外置卷與網路共享目錄生成 .DS_Store", "Reset Quick Look and icon caches, and prevent .DS_Store creation on network and USB volumes", "クイックルックとアイコンキャッシュをリセットし、外部・ネットワーク巻での .DS_Store 生成を防止します", "훑어보기 및 아이콘 캐시를 재설정하고 네트워크·외장 볼륨에 .DS_Store 생성을 방지합니다",
            "Réinitialisez Quick Look et le cache d'icônes, et empêchez la création de .DS_Store sur les volumes réseau/USB", "Übersicht- und Symbol-Cache zurücksetzen sowie .DS_Store auf Netzwerk-/USB-Volumes verhindern", "Restablezca Vista Rápida y la caché de iconos, y evite archivos .DS_Store en volúmenes de red y USB", "Reimposta Visualizzazione Rapida e cache icone, impedendo la creazione di .DS_Store su volumi di rete e USB", "Redefina a Visualização Rápida e o cache de ícones, evitando arquivos .DS_Store em volumes USB e de rede")
        add(.taskVacuumSqliteDatabasesDesc, "按需精简本地时间机器快照，安全释放被历史快照占用的磁盘空间", "按需精簡本機時光機快照，安全釋放被歷史快照佔用的磁碟空間", "Thin local Time Machine snapshots on demand to safely reclaim disk space", "ローカルの Time Machine スナップショットを整理し、ディスク領域を安全に解放します", "로컬 Time Machine 스냅샷을 정리하여 디스크 공간을 안전하게 확보합니다",
            "Allégez les instantanés locaux Time Machine pour récupérer de l'espace disque en toute sécurité", "Lokale Time Machine-Schnappschüsse ausdünnen, um sicher Speicherplatz freizugeben", "Reduzca las instantáneas locales de Time Machine para recuperar espacio en disco de forma segura", "Riduci le istantanee locali di Time Machine per liberare spazio su disco in sicurezza", "Reduza os instantâneos locais do Time Machine para liberar espaço em disco com segurança")
        add(.tasksToRun, "项待执行", "項待執行", "tasks to run", "件のタスクが待機中", "개 작업 대기 중",
            "tâches à exécuter", "Aufgaben ausstehend", "tareas por ejecutar", "attività da eseguire", "tarefas para executar")
        add(.telemetryCategoryStoragePower, "存储与电源", "儲存與電源", "Storage & Power", "ストレージと電源", "저장 공간 및 전원",
            "Stockage et alimentation", "Speicher & Strom", "Almacenamiento y energía", "Archiviazione e alimentazione", "Armazenamento e Energia")
        add(.telemetryDiagAllNormal, "系统各项指标运行平稳", "系統各項指標運作平穩", "All system metrics are running smoothly", "すべてのシステム指標は安定して稼働しています", "모든 시스템 지표가 원활하게 작동하고 있습니다",
            "Toutes les métriques du système fonctionnent sans problème", "Alle Systemmetriken laufen reibungslos", "Todas las métricas del sistema funcionan sin problemas", "Tutte le metriche di sistema funzionano regolarmente", "Todas as métricas do sistema estão funcionando perfeitamente")
        add(.telemetryFanAutoCoolingDesc, "系统自动温控", "系統自動溫控", "Automatic Thermal Management", "システム自動温度制御", "시스템 자동 열 제어",
            "Gestion thermique automatique", "Automatische Temperaturregelung", "Gestión térmica automática", "Gestione termica automatica", "Gerenciamento Térmico Automático")
        add(.telemetryMemoryActiveLabel, "活跃应用 (Active)", "活躍應用 (Active)", "Active Memory", "アクティブメモリ (Active)", "활성 메모리 (Active)",
            "Mémoire active", "Aktiver Speicher", "Memoria activa", "Memoria attiva", "Memória Ativa")
        add(.telemetryMemoryCachedLabel, "文件缓存 (Cache)", "檔案快取 (Cache)", "Cached Files", "キャッシュファイル", "캐시 파일",
            "Fichiers en cache", "Dateicache", "Archivos en caché", "File in cache", "Arquivos em Cache")
        add(.telemetryMemoryCompressedLabel, "已压缩 (Compressed)", "已壓縮 (Compressed)", "Compressed Memory", "圧縮済みメモリ", "압축된 메모리",
            "Mémoire compressée", "Komprimierter Speicher", "Memoria comprimida", "Memoria compressa", "Memória Comprimida")
        add(.telemetryMemoryFreeLabel, "空闲物理内存 (Free)", "閒置實體記憶體 (Free)", "Free Memory", "空きメモリ", "여유 메모리",
            "Mémoire libre", "Freier Speicher", "Memoria libre", "Memoria libera", "Memória Livre")
        add(.telemetryMemoryWiredLabel, "联动内存 (Wired)", "連動記憶體 (Wired)", "Wired Memory", "固定メモリ (Wired)", "고정 메모리 (Wired)",
            "Mémoire résidente (Wired)", "Fest belegter Speicher (Wired)", "Memoria fija (Wired)", "Memoria wired", "Memória Residente (Wired)")
        add(.telemetryNoAbnormalPowerApps, "无异常高耗电进程", "無異常高耗電程序", "No abnormal high-power processes", "異常に電力を消費するプロセスはありません", "비정상적인 고전력 프로세스가 없습니다",
            "Aucun processus anormalement énergivore", "Keine ungewöhnlich stromhungrigen Prozesse", "Sin procesos anormales de alto consumo", "Nessun processo anomalo ad alto consumo", "Sem processos anormais de alto consumo")
        add(.telemetryNoAdapterConnected, "未接入适配器", "未連接充電器", "No Adapter Connected", "電源アダプタ未接続", "충전기 미연결",
            "Aucun adaptateur connecté", "Kein Netzteil angeschlossen", "Sin adaptador conectado", "Nessun alimentatore collegato", "Nenhum Adaptador Conectado")
        add(.telemetryTotalCapacityFormat, "总容量 %@", "總容量 %@", "Total Capacity %@", "合計容量 %@", "총 용량 %@",
            "Capacité totale %@", "Gesamtkapazität %@", "Capacidad total %@", "Capacità totale %@", "Capacidade Total %@")
        add(.temporaryWebPagesFaviconsAndScriptsDownloadedBySafariChromeEtc, "Safari、Chrome 等已下载的临时网页、图标与脚本", "Safari、Chrome 等已下載的暫存網頁、圖標與腳本", "Temporary web pages, favicons, and scripts downloaded by Safari, Chrome, etc.", "Safari、Chrome などによってダウンロードされた一時 Web ページ、アイコン、スクリプト", "Safari, Chrome 등에서 다운로드된 임시 웹페이지, 아이콘 및 스크립트",
            "Pages Web temporaires, favicônes et scripts téléchargés par Safari, Chrome, etc.", "Von Safari, Chrome usw. heruntergeladene temporäre Webseiten, Icons und Skripte", "Páginas web temporales, favicons y scripts descargados por Safari, Chrome, etc.", "Pagine web temporanee, favicon e script scaricati da Safari, Chrome, ecc.", "Páginas da web temporárias, favicons e scripts baixados pelo Safari, Chrome, etc.")
        add(.terminateProcess, "结束进程", "結束處理程序", "Terminate", "終了", "프로세스 종료",
            "Terminer", "Beenden", "Terminar", "Termina", "Encerrar")
        add(.terminateProcessConfirmMessageFormat, "确定要终止「%@」(PID: %d) 吗？未保存的数据可能会丢失。", "確定要強制結束「%@」(PID: %d) 嗎？未儲存的資料可能會遺失。", "Are you sure you want to terminate '%@' (PID: %d)? Unsaved data may be lost.", "「%@」(PID: %d) を終了してもよろしいですか？保存されていないデータは失われる可能性があります。", "'%@'(PID: %d) 프로세스를 종료하시겠습니까? 저장되지 않은 데이터가 손실될 수 있습니다.",
            "Voulez-vous vraiment terminer '%@' (PID : %d) ? Les données non enregistrées peuvent être perdues.", "Möchten Sie „%@“ (PID: %d) wirklich beenden? Ungespeicherte Daten gehen möglicherweise verloren.", "¿Seguro que deseas terminar '%@' (PID: %d)? Los datos no guardados podrían perderse.", "Sei sicuro di voler terminare '%@' (PID: %d)? I dati non salvati potrebbero andare persi.", "Tem certeza de que deseja encerrar '%@' (PID: %d)? Dados não salvos podem ser perdidos.")
        add(.terminateProcessConfirmationTitle, "结束进程确认", "結束進程確認", "Terminate Process Confirmation", "プロセスの終了確認", "프로세스 종료 확인",
            "Confirmation de fin de processus", "Prozessbeendigung bestätigen", "Confirmación de finalización de proceso", "Conferma chiusura processo", "Confirmação de encerramento de processo")
        add(.themeEmeraldForest, "森系翠绿", "森系翠綠", "Emerald Forest", "エメラルド", "에메랄드 포레스트",
            "Émeraude", "Smaragdgrün", "Verde esmeralda", "Verde smeraldo", "Floresta Esmeralda")
        add(.themeEmeraldForestShort, "翡翠森绿", "翡翠森綠", "Emerald", "エメラルド", "에메랄드",
            "Émeraude", "Smaragd", "Esmeralda", "Smeraldo", "Esmeralda")
        add(.themeGraphiteMono, "石墨极简", "石墨極簡", "Graphite Mono", "グラファイト", "그래파이트 모노",
            "Graphite minimal", "Graphit pur", "Grafito puro", "Grafite", "Grafite Mono")
        add(.themeGraphiteMonoShort, "极简石墨", "極簡石墨", "Graphite", "グラファイト", "그래파이트",
            "Graphite", "Graphit", "Grafito", "Grafite", "Grafite")
        add(.themeWarmAmber, "琥珀暖金", "琥珀暖金", "Warm Amber", "ウォームアンバー", "웜 앰버",
            "Ambre chaud", "Warmes Bernstein", "Ámbar cálido", "Ambra calda", "Âmbar Quente")
        add(.themeWarmAmberShort, "曜石暖金", "曜石暖金", "Warm Amber", "ウォームアンバー", "웜 앰버",
            "Ambre chaud", "Warmes Bernstein", "Ámbar cálido", "Ambra calda", "Âmbar Quente")
        add(.themeOceanBlue, "深海湛蓝", "深海湛藍", "Ocean Blue", "オーシャンブルー", "오션 블루",
            "Bleu océan", "Ozeanblau", "Azul océano", "Blu oceano", "Azul Oceano")
        add(.themeOceanBlueShort, "深海极光", "深海極光", "Ocean Blue", "オーシャンブルー", "오션 블루",
            "Bleu océan", "Ozeanblau", "Azul océano", "Blu oceano", "Azul Oceano")
        add(.themeRoseQuartz, "石英暖粉", "石英暖粉", "Rose Quartz", "ローズコーラル", "로즈 쿼츠",
            "Quartz rose", "Rosenquarz", "Cuarzo rosa", "Quarzo rosa", "Quartzo Rosa")
        add(.themeRoseQuartzShort, "赤霞珊瑚", "赤霞珊瑚", "Rose Coral", "ローズコーラル", "로즈 코랄",
            "Corail rose", "Korallenrot", "Coral rosa", "Corallo", "Coral Rosa")
        add(.themeVioletNebula, "星云流紫", "星雲流紫", "Violet Nebula", "バイオレット", "바이올렛 네뷸라",
            "Nébuleuse violette", "Nebelviolett", "Nebulosa violeta", "Nebulosa viola", "Nebulosa Violeta")
        add(.themeVioletNebulaShort, "星云紫罗兰", "星雲紫羅蘭", "Violet Nebula", "バイオレット", "바이올렛",
            "Nébuleuse violette", "Violett", "Violeta", "Viola", "Violeta")
        add(.thermalArchitecture, "散热架构", "散熱架構", "Thermal", "サーマル", "발열 관리",
            "Thermique", "Thermik", "Térmico", "Termico", "Térmico")
        add(.thinLocalTimeMachineSnapshots, "削减本地时间机器快照", "削減本地時間機器快照", "Thin Local Time Machine Snapshots", "ローカル Time Machine スナップショットを削減", "로컬 Time Machine 스냅샷 축소",
            "Réduire les instantanés locaux Time Machine", "Lokale Time Machine Schnappschüsse bereinigen", "Reducir instantáneas locales de Time Machine", "Riduci istantanee locali di Time Machine", "Reduzir Instantâneos Locais do Time Machine")
        add(.thinTimeMachineSnapshots, "精简“时间机器”快照", "精簡「時光機」本機快照", "Thin Time Machine Snapshots", "Time Machineローカルスナップショットを整理", "Time Machine 로컬 스냅샷 정리",
            "Alléger les instantanés Time Machine", "Time Machine-Schnappschüsse ausdünnen", "Reducir instantáneas de Time Machine", "Sfoltisci istantanee Time Machine", "Reduzir Capturas do Time Machine")
        add(.thresholdLargeFileMinSize, "大文件最小体积阈值", "大檔案最小體積閾值", "Large File Size Threshold", "大容量ファイルの最小サイズ基準", "대용량 파일 최소 크기 기준",
            "Taille minimale des gros fichiers", "Schwellenwert für große Dateien", "Umbral de tamaño de archivos grandes", "Soglia dimensione file grandi", "Limite de Tamanho de Arquivos Grandes")
        add(.thresholdOldFileMonths, "旧文件未访问月数阈值", "舊檔案未訪問月數閾值", "Old File Age Threshold (Months)", "古いファイルの未アクセス期間基準（月）", "오래된 파일 미사용 기간 기준 (개월)",
            "Ancienneté minimale des vieux fichiers (mois)", "Schwellenwert für alte Dateien (Monate)", "Umbral de inactividad de archivos antiguos (meses)", "Soglia inattività file vecchi (mesi)", "Limite de Inatividade de Arquivos Antigos (meses)")
        add(.tileJunkQuantifier, "的", "的", "of ", "の", "의 ",
            "de ", "an ", "de ", "di ", "de ")
        add(.tileNoteAiClutter, "清理 AI 工具的缓存、日志、残留文件以及不再使用的本地模型。", "清理 AI 工具的快取、記錄、殘留檔案以及不再使用的本機模型。", "Clean up AI tool caches, logs, remnants, and unused local models.", "AI ツールのキャッシュ、ログ、残余ファイル、不要なローカルモデルを消去します。", "AI 도구 캐시, 로그, 잔여 파일 및 사용하지 않는 로컬 모델을 정리합니다.",
            "Nettoyez le cache, les journaux et les modèles locaux inutilisés des outils IA.", "Bereinigen Sie Caches, Protokolle und ungenutzte lokale Modelle von KI-Tools.", "Limpie cachés, registros y modelos locales en desuso de herramientas de IA.", "Elimina cache, registri e modelli locali inutilizzati dagli strumenti di intelligenza artificiale.", "Limpe caches, logs e modelos locais não utilizados de ferramentas de IA.")
        add(.tileNoteDeletedUsers, "这台 Mac 仍然保留着已删除的用户账户数据。", "這台 Mac 仍然保留著已刪除的使用者帳號資料。", "This Mac still preserves data from previously deleted user accounts.", "この Mac には削除済みユーザーアカウントのデータが残っています。", "이 Mac에는 삭제된 사용자 계정의 데이터가 여전히 남아 있습니다.",
            "Ce Mac conserve encore des données de comptes utilisateurs supprimés.", "Dieser Mac enthält noch Daten von gelöschten Benutzerkonten.", "Este Mac todavía conserva datos de cuentas de usuario eliminadas.", "Questo Mac conserva ancora dati relativi ad account utente eliminati.", "Este Mac ainda mantém dados de contas de usuário excluídas.")
        add(.tileNoteDocumentVersions, "您的系统会保留您编辑过的文件的所有过时版本。清理它们，可以释放更多空间！", "您的系統會保留您編輯過的檔案的所有過時版本。清理它們，可以釋放更多空間！", "macOS stores outdated revisions of edited documents. Cleaning them reclaims storage.", "編集済みファイルの古いリビジョンを整理して、空き領域を増やします。", "편집한 파일의 오래된 이전 버전을 정리하여 저장 공간을 확보할 수 있습니다.",
            "Le système conserve les anciennes versions de documents. Les nettoyer libère de l'espace.", "macOS speichert alte Versionen bearbeiteter Dokumente. Bereinigen Sie diese für mehr Platz.", "macOS almacena versiones anteriores de documentos editados. Límpielas para liberar espacio.", "macOS conserva le versioni precedenti dei documenti modificati. Puliscile per liberare spazio.", "O macOS armazena versões antigas de documentos editados. Limpe-as para liberar espaço.")
        add(.tileNoteIosBackups, "可以考虑删除过时的 iOS 备份文件。它们不太可能再被使用，但却占用着存储空间。", "可以考慮刪除過時的 iOS 備份檔案。它們不太可能再被使用，但卻佔用著儲存空間。", "Consider deleting outdated iOS device backups that take up storage space.", "不要になった古い iOS バックアップの削除を検討してください。", "오래된 iOS 기기 백업 파일을 삭제하여 저장 공간을 확보할 수 있습니다.",
            "Supprimez les anciennes sauvegardes iOS qui occupent inutilement de l'espace.", "Erwägen Sie das Löschen alter iOS-Backups, um Speicherplatz zu sparen.", "Considere eliminar copias de seguridad de iOS obsoletas que ocupan espacio.", "Valuta di eliminare i backup iOS obsoleti per recuperare spazio prezioso.", "Considere excluir backups antigos do iOS para liberar armazenamento.")
        add(.tileNoteSystemJunk, "清理系统和应用程序生成的所有已不再有用的文件。", "清理系統和應用程式生成的所有已不再有用的檔案。", "Clean up all files generated by system and apps that are no longer needed.", "システムとアプリケーションが生成した不要なファイルをすべてクリーンアップします。", "시스템 및 앱에서 생성된 불필요한 파일을 모두 정리합니다.",
            "Nettoyez tous les fichiers devenus inutiles générés par le système et les applications.", "Bereinigen Sie alle vom System und Apps erstellten Dateien, die nicht mehr benötigt werden.", "Limpie todos los archivos generados por el sistema y las apps que ya no sean necesarios.", "Pulisci tutti i file generati dal sistema e dalle app che non sono più necessari.", "Limpe todos os arquivos gerados pelo sistema e aplicativos que não são mais necessários.")
        add(.tileNoteTrashBins, "别再浪费您存储驱动器的空间了。永久删除废纸篓中的内容吧。", "別再浪費您儲存驅動器的空間了。永久刪除廢紙簍中的內容吧。", "Reclaim drive space by permanently deleting items in your Trash bins.", "ゴミ箱の中身を完全に消去して、ストレージの空き領域を増やしましょう。", "휴지통의 항목을 영구 삭제하여 드라이브 공간을 확보하세요.",
            "Récupérez de l'espace disque en vidant définitivement les corbeilles.", "Geben Sie Speicherplatz frei, indem Sie den Papierkorb endgültig leeren.", "Recupere espacio en disco vaciando definitivamente las papeleras.", "Recupera spazio prezioso svuotando definitivamente il cestino.", "Recupere espaço em disco esvaziando a lixeira permanentemente.")
        add(.tileNoteUniversalBinaries, "从应用程序中删除未使用的代码版本。您的系统仅需保留适合的版本。", "從應用程式中刪除未使用的代碼版本。您的系統僅需保留適合的版本。", "Remove unused architecture code slices from apps. Only the matching architecture is needed.", "アプリケーションから不要なコードスライスを削除します。システムに必要なもののみを保持します。", "앱에서 사용하지 않는 아키텍처 코드를 삭제합니다. 시스템에 맞는 버전만 유지하면 됩니다.",
            "Supprimez les tranches de code d'architecture inutilisées des applications.", "Entfernen Sie ungenutzte Architekturscheiben aus Anwendungen.", "Elimine versiones de código de arquitectura no utilizadas de las aplicaciones.", "Rimuovi le fette di codice di architettura non utilizzate dalle applicazioni.", "Remova fatias de código de arquitetura não utilizadas dos aplicativos.")
        add(.tileNoteXcodeJunk, "您的 Xcode 已生成大量的派生数据。您可以将这些数据删除，以释放空间。", "您的 Xcode 已生成大量的衍生資料。您可以將這些資料刪除，以釋放空間。", "Xcode has accumulated large amounts of derived data. You can delete them to reclaim disk space.", "Xcode が大量の派生データを生成しています。これらを削除して空き容量を増やせます。", "Xcode에서 대량의 파생 데이터가 생성되었습니다. 공간을 확보하기 위해 삭제할 수 있습니다.",
            "Xcode a généré d'importantes données dérivées. Vous pouvez les supprimer pour libérer de l'espace.", "Xcode hat viele abgeleitete Daten generiert. Löschen Sie diese, um Speicherplatz freizugeben.", "Xcode ha generado gran cantidad de datos derivados. Puede eliminarlos para liberar espacio.", "Xcode ha accumulato molti dati derivati. Puoi eliminarli per liberare spazio su disco.", "O Xcode gerou muitos dados derivados. Você pode excluí-los para liberar espaço em disco.")
        add(.tileQuantifierDe, "的", "的", "of ", "の", "의 ",
            " de ", " an ", " de ", " di ", " de ")
        add(.tileQuantifierGe, "个", "個", " ", "個の", "개 ",
            " ", " ", " ", " ", " ")
        add(.tileVerbFound, "已发现", "已發現", "Found", "検出", "발견됨",
            "Détecté", "Gefunden", "Encontrado", "Rilevato", "Encontrado")
        add(.tileVerbLocated, "已找到", "已找到", "Located", "検出", "발견됨",
            "Localisé", "Lokalisiert", "Localizado", "Individuato", "Localizado")
        add(.timeFifteenMinutes, "15分钟", "15分鐘", "15 Min", "15分", "15분",
            "15 min", "15 Min.", "15 min", "15 min", "15 min")
        add(.timeFiveMinutes, "5分钟", "5分鐘", "5 Min", "5分", "5분",
            "5 min", "5 Min.", "5 min", "5 min", "5 min")
        add(.timeMachineIsIndispensableForDataRecoveryItsOnlyDownsideIsTheLargeAmountOfSpaceBackupsConsumeThinningTimeMachineLocalSnapshotsReclaimsSpaceWithoutLosingBackups, "“时间机器”是拯救数据不可或缺的工具。它唯一的缺点是，备份占用了大量空间。对“时间机器”快照进行精简，可以在不丢失备份的情况下释放更多空间。", "“時間機器”是拯救資料不可或缺的工具。它唯一的缺點是，備份佔用了大量空間。對“時間機器”快照進行精簡，可以在不丟失備份的情況下釋放更多空間。", "Time Machine is indispensable for data recovery. Its only downside is the large amount of space backups consume. Thinning Time Machine local snapshots reclaims space without losing backups.", "Time Machine はデータ復旧に欠かせないツールですが、スナップショットが大量の容量を消費することがあります。ローカルスナップショットを間引くことで、バックアップを失うことなく空き領域を増やせます。", "Time Machine은 데이터 복구에 필수적인 도구입니다. 유일한 단점은 백업이 많은 공간을 차지한다는 점입니다. Time Machine 로컬 스냅샷을 정리하면 백업 손실 없이 공간을 확보할 수 있습니다.",
            "Time Machine est un outil indispensable. Son seul inconvénient réside dans la place occupée par les instantanés. Les réduire libère de l’espace sans compromettre vos sauvegardes.", "Time Machine ist unverzichtbar zur Datenrettung, verbraucht aber viel Speicherplatz. Das Bereinigen lokaler Schnappschüsse schafft Platz, ohne Backups zu verlieren.", "Time Machine es imprescindible, pero sus instantáneas ocupan mucho espacio. Reducir las instantáneas locales libera espacio sin perder copias de seguridad.", "Time Machine è fondamentale per il recupero dati. L’unico svantaggio è lo spazio occupato. Ridurre le istantanee locali libera spazio senza perdere i backup.", "O Time Machine é essencial para recuperação de dados, mas seus instantâneos locais ocupam muito espaço. Reduzi-los libera espaço sem perder backups.")
        add(.timeNow, "现在", "現在", "Now", "現在", "지금",
            "Maintenant", "Jetzt", "Ahora", "Ora", "Agora")
        add(.timeOneHour, "1小时", "1小時", "1 Hour", "1時間", "1시간",
            "1 h", "1 Std.", "1 h", "1 ora", "1 h")
        add(.timeOneMinute, "1分钟", "1分鐘", "1 Min", "1分", "1분",
            "1 min", "1 Min.", "1 min", "1 min", "1 min")
        add(.timeRangeFifteenMinutes, "15 分钟", "15 分鐘", "15 Min", "15 分", "15분",
            "15 min", "15 Min.", "15 min", "15 min", "15 min")
        add(.timeRangeFiveMinutes, "5 分钟", "5 分鐘", "5 Min", "5 分", "5분",
            "5 min", "5 Min.", "5 min", "5 min", "5 min")
        add(.timeRangeOneMinute, "1 分钟", "1 分鐘", "1 Min", "1 分", "1분",
            "1 min", "1 Min.", "1 min", "1 min", "1 min")
        add(.toastConfigExportedSuccess, "配置已成功导出", "配置已成功導出", "Configuration exported successfully", "設定が正常にエクスポートされました", "설정이 성공적으로 내보내졌습니다",
            "Configuration exportée avec succès", "Konfiguration erfolgreich exportiert", "Configuración exportada con éxito", "Configurazione esportata con successo", "Configuração exportada com sucesso")
        add(.toastConfigImportedSuccess, "配置已成功导入并生效", "配置已成功導入並生效", "Configuration imported and applied successfully", "設定が正常にインポートされ、適用されました", "설정을 성공적으로 가져와 적용했습니다",
            "Configuration importée et appliquée avec succès", "Konfiguration erfolgreich importiert und angewendet", "Configuración importada y aplicada con éxito", "Configurazione importata e applicata con successo", "Configuração importada e aplicada com sucesso")
        add(.toastNoItemsSelected, "没有选中的项目", "沒有選取的項目", "No items selected", "項目が選択されていません", "선택된 항목이 없습니다",
            "Aucun élément sélectionné", "Keine Elemente ausgewählt", "No hay elementos seleccionados", "Nessun elemento selezionato", "Nenhum item selecionado")
        add(.toastResetDefaultSuccess, "已恢复默认配置（保留白名单）", "已恢復預設配置（保留白名單）", "Defaults restored (whitelist preserved)", "デフォルト設定に戻しました（ホワイトリストを保持）", "기본 설정으로 복원되었습니다 (화이트리스트 유지)",
            "Réglages par défaut rétablis (liste blanche conservée)", "Standardeinstellungen wiederhergestellt (Whitelist beibehalten)", "Ajustes predeterminados restaurados (lista blanca conservada)", "Impostazioni predefinite ripristinate (whitelist conservata)", "Padrões restaurados (lista branca preservada)")
        add(.toastScanStopped, "扫描已停止", "掃描已停止", "Scan Stopped", "スキャンを停止しました", "스캔이 중지되었습니다",
            "Analyse arrêtée", "Scan angehalten", "Escaneo detenido", "Scansione interrotta", "Escaneamento Interrompido")
        add(.toastSystemProtectedCannotRemove, "系统受保护目录不可移除", "系統受保護目錄不可移除", "Protected system directory cannot be removed", "保護されたシステムディレクトリは削除できません", "보호된 시스템 디렉토리는 제거할 수 없습니다",
            "Le répertoire système protégé ne peut pas être supprimé", "Geschütztes Systemverzeichnis kann nicht entfernt werden", "El directorio protegido del sistema no se puede eliminar", "La directory di sistema protetta non può essere rimossa", "O diretório do sistema protegido não pode ser removido")
        add(.today, "今天", "今天", "Today", "今日", "오늘",
            "Aujourd’hui", "Heute", "Hoy", "Oggi", "Hoje")
        add(.toggleShowHiddenFiles, "显示被隐藏的文件", "顯示被隱藏的文件", "Show Hidden Files", "隠しファイルを表示", "숨겨진 파일 표시",
            "Afficher les fichiers masqués", "Versteckte Dateien anzeigen", "Mostrar archivos ocultos", "Mostra file nascosti", "Mostrar arquivos ocultos")
        add(.toggleStartupItem, "切换启动项", "切換啟動項", "Toggle Startup Item", "起動項目の切替", "시작 프로그램 전환",
            "Basculer l’élément de démarrage", "Autostart-Objekt umschalten", "Alternar elemento de inicio", "Attiva/disattiva elemento di avvio", "Alternar Item de Inicialização")
        add(.toolboxAiClutterCardDesc, "清理 AI 工具的缓存与闲置本地模型", "清理 AI 工具的緩存與閒置本地模型", "Clean caches and idle local models from AI tools", "AI ツールのキャッシュや不要になったローカルモデルを消去", "AI 도구의 캐시 및 사용하지 않는 로컬 모델 정리",
            "Nettoyez les caches et modèles locaux inactifs des outils d'IA", "Caches und inaktive lokale Modelle von KI-Tools bereinigen", "Limpie cachés y modelos locales inactivos de herramientas de IA", "Pulisci cache e modelli locali inattivi dagli strumenti IA", "Limpe caches e modelos locais inativos de ferramentas de IA")
        add(.toolboxAppUninstallerCardDesc, "彻底卸载应用并清除全部关联残留", "徹底卸載應用並清除全部關聯殘留", "Thoroughly uninstall apps and completely remove all associated leftovers", "アプリケーションを徹底アンインストールし、すべての関連残留物を完全消去", "애플리케이션을 완전히 삭제하고 모든 관련 잔여 파일을 완벽 제거",
            "Désinstallez complètement les applications et supprimez tous les résidus", "Apps gründlich deinstallieren und alle zugehörigen Reste vollständig entfernen", "Desinstale completamente las aplicaciones y elimine todos los residuos asociados", "Disinstalla a fondo le applicazioni e rimuovi tutti i residui associati", "Desinstale completamente aplicativos e remova todos os resíduos associados")
        add(.toolboxAppUninstallerCardTitle, "卸载器", "卸載器", "Uninstaller", "アンインストーラ", "언인스톨러",
            "Désinstalleur", "Deinstallierer", "Desinstalador", "Disinstallatore", "Desinstalador")
        add(.toolboxCategoryCleanSubtitle, "卸载、垃圾、大文件与重复文件", "卸載、垃圾、大文件與重複文件", "Uninstall, Junk, Large Files & Duplicates", "アンインストール、ゴミ、大容量ファイル、重複ファイル", "앱 삭제, 정크 파일, 대용량 및 중복 파일",
            "Désinstallation, fichiers inutiles, gros fichiers et doublons", "Deinstallation, Müll, große Dateien & Duplikate", "Desinstalación, basura, archivos grandes y duplicados", "Disinstallazione, file inutili, file grandi e duplicati", "Desinstalação, lixo, arquivos grandes e duplicatas")
        add(.toolboxCategoryCleanTitle, "清理工具", "清理工具", "Cleaning Tools", "クリーンアップツール", "정리 도구",
            "Outils de nettoyage", "Bereinigungswerkzeuge", "Herramientas de limpieza", "Strumenti di pulizia", "Ferramentas de limpeza")
        add(.toolboxCategoryCleaningSubtitle, "卸载、垃圾、大文件与重复文件", "卸載、垃圾、大檔案與重複檔案", "Uninstaller, junk, large files, and duplicates", "アンインストーラ、ゴミ、大容量ファイル、重複ファイル", "앱 제거, 정크, 대용량 파일 및 중복 파일",
            "Désinstallation, résidus, gros fichiers et doublons", "Deinstallation, Datenmüll, große Dateien und Duplikate", "Desinstalador, basura, archivos grandes y duplicados", "Disinstallazione, file spazzatura, file grandi e duplicati", "Desinstalador, lixo, arquivos grandes e duplicatas")
        add(.toolboxCategoryCleaningTitle, "清理工具", "清理工具", "Cleanup Tools", "クリーンアップツール", "정리 도구",
            "Outils de nettoyage", "Bereinigungswerkzeuge", "Herramientas de limpieza", "Strumenti di pulizia", "Ferramentas de Limpeza")
        add(.toolboxCategoryOtherTools, "其他工具", "其他工具", "Other Tools", "その他のツール", "기타 도구",
            "Autres outils", "Weitere Werkzeuge", "Otras herramientas", "Altri strumenti", "Outras ferramentas")
        add(.toolboxCategoryPerformanceSubtitle, "维护脚本、启动项与后台项目", "維護腳本、啟動項與後台項目", "Maintenance Scripts, Startup Items & Background Daemons", "保守スクリプト、スタートアップ項目、バックグラウンド", "유지보수 스크립트, 시작 프로그램 및 백그라운드 항목",
            "Scripts de maintenance, éléments au démarrage et en arrière-plan", "Wartungsskripte, Startobjekte & Hintergrundprozesse", "Scripts de mantenimiento, inicio y segundo plano", "Script di manutenzione, elementi di avvio e background", "Scripts de manutenção, itens de inicialização e segundo plano")
        add(.toolboxCategoryPerformanceTitle, "性能工具", "性能工具", "Performance Tools", "パフォーマンスツール", "성능 도구",
            "Outils de performance", "Leistungswerkzeuge", "Herramientas de rendimiento", "Strumenti di prestazioni", "Ferramentas de desempenho")
        add(.toolboxDaemonsCardDesc, "查看并管理后台运行的代理与守护进程", "查看並管理後台運行的代理與守護進程", "Inspect and manage background launch agents and daemons", "バックグラウンドで動作するエージェントとデーモンを確認・管理", "백그라운드에서 실행 중인 에이전트 및 데몬 확인 및 관리",
            "Inspectez et gérez les agents et démons en arrière-plan", "Hintergrund-Agents und -Daemons prüfen und verwalten", "Inspeccione y gestione agentes y demonios en segundo plano", "Controlla e gestisci agenti e demoni in esecuzione in background", "Inspecione e gerencie agentes e daemons em execução em segundo plano")
        add(.toolboxDownloadsCardDesc, "查看并删除不必要的下载文件", "查看並刪除不必要的下載文件", "Review and remove unnecessary downloaded files", "不要になったダウンロードファイルを確認して削除", "불필요한 다운로드 파일을 검토하고 삭제",
            "Examinez et supprimez les fichiers téléchargés superflus", "Unnötige heruntergeladene Dateien anzeigen und löschen", "Revise y elimine descargas innecesarias", "Controlla ed elimina i file scaricati non necessari", "Revise e remova downloads desnecessários")
        add(.toolboxDownloadsCardTitle, "下载项清理", "下載項清理", "Downloads Cleanup", "ダウンロード項目の整理", "다운로드 항목 정리",
            "Nettoyage des téléchargements", "Downloads bereinigen", "Limpieza de descargas", "Pulizia download", "Limpeza de downloads")
        add(.toolboxDuplicatesCardDesc, "清理不同位置内容完全相同的文件", "清理不同位置內容完全相同的文件", "Clean files with identical content scattered across different locations", "異なる場所に存在する完全に同一の内容のファイルをクリーンアップ", "여러 위치에 흩어져 있는 내용이 동일한 중복 파일 정리",
            "Nettoyez les fichiers au contenu identique dispersés à divers endroits", "Inhaltlich identische Dateien an verschiedenen Speicherorten bereinigen", "Limpie archivos con contenido idéntico en diferentes ubicaciones", "Pulisci i file con contenuto identico sparsi in posizioni diverse", "Limpe arquivos com conteúdo idêntico espalhados em locais diferentes")
        add(.toolboxDuplicatesCardTitle, "重复文件查找器", "重複文件查找器", "Duplicate Finder", "重複ファイル検索", "중복 파일 검색기",
            "Détecteur de doublons", "Duplikat-Finder", "Buscador de duplicados", "Trova duplicati", "Localizador de duplicatas")
        add(.toolboxHeroDesc, "专注于高效的快捷工具，轻点几下，即可完成 Mac 电脑的清理与系统维护。", "專注於高效的快捷工具，輕點幾下，即可完成 Mac 電腦的清理與系統維護。", "Focused, efficient utilities to clean and maintain your Mac in just a few clicks.", "高効率なツール群により、わずか数クリックで Mac のクリーンアップと保守を完了できます。", "효율적인 도구 모음으로 몇 번의 클릭만으로 Mac의 정리와 시스템 유지보수를 완료하세요.",
            "Des utilitaires efficaces pour nettoyer et entretenir votre Mac en quelques clics.", "Fokussierte Werkzeuge zur einfachen Bereinigung und Wartung Ihres Mac mit wenigen Klicks.", "Herramientas eficientes para limpiar y mantener su Mac con solo unos clics.", "Utilità efficienti per pulire e mantenere il tuo Mac in pochi clic.", "Utilitários eficientes para limpar e manter seu Mac em poucos cliques.")
        add(.toolboxHeroSubtitle, "快捷工具集合", "快捷工具集合", "Quick Utilities Collection", "クイックツールコレクション", "빠른 도구 컬렉션",
            "Collection d'utilitaires rapides", "Sammlung praktischer Dienstprogramme", "Colección de utilidades rápidas", "Raccolta di utilità rapide", "Coleção de utilitários rápidos")
        add(.toolboxLargeFilesCardDesc, "找出体积最大或长期未使用的文件", "找出體積最大或長期未使用的文件", "Locate the largest or long-unopened files taking up space", "容量の大きいファイルや長期間使用されていないファイルを検出", "가장 큰 파일이나 오랫동안 사용하지 않은 파일을 검색",
            "Trouvez les fichiers les plus volumineux ou non ouverts depuis longtemps", "Größte oder lange unbenutzte Dateien schnell aufspüren", "Localice los archivos más grandes o no abiertos en mucho tiempo", "Individua i file più grandi o non aperti da molto tempo", "Encontre os maiores arquivos ou arquivos não abertos há muito tempo")
        add(.toolboxLargeFilesCardTitle, "大文件清理", "大文件清理", "Large Files Cleanup", "大容量ファイルのクリーンアップ", "대용량 파일 정리",
            "Nettoyage des gros fichiers", "Große Dateien bereinigen", "Limpieza de archivos grandes", "Pulizia file grandi", "Limpeza de arquivos grandes")
        add(.toolboxLiveMonitorCardDesc, "ACleaner 级实时 CPU、内存、磁盘 IO、网络与进程看板", "ACleaner 級實時 CPU、內存、磁盤 IO、網絡與進程看板", "Real-time dashboard for CPU, memory, disk I/O, network, and processes", "CPU、メモリ、ディスク I/O、ネットワーク、プロセスのリアルタイムダッシュボード", "실시간 CPU, 메모리, 디스크 I/O, 네트워크 및 프로세스 대시보드",
            "Tableau de bord en temps réel pour CPU, mémoire, disque, réseau et processus", "Echtzeit-Dashboard für CPU, RAM, Festplatten-I/O, Netzwerk und Prozesse", "Panel en tiempo real para CPU, memoria, E/S de disco, red y procesos", "Dashboard in tempo reale per CPU, memoria, I/O disco, rete e processi", "Painel em tempo real para CPU, memória, E/S de disco, rede e processos")
        add(.toolboxLiveMonitorCardTitle, "实时系统监控", "實時系統監控", "Live System Monitor", "リアルタイムシステム監視", "실시간 시스템 모니터링",
            "Surveillance système en direct", "Live-System-Monitor", "Monitor del sistema en vivo", "Monitor di sistema in tempo reale", "Monitor do sistema em tempo real")
        add(.toolboxMaintenanceScriptsCardDesc, "运行推荐的系统维护任务", "運行推薦的系統維護任務", "Run recommended macOS system maintenance tasks", "推奨される macOS システムメンテナンスタスクを実行", "권장되는 macOS 시스템 유지보수 작업을 실행",
            "Exécutez les tâches de maintenance recommandées pour macOS", "Empfohlene macOS-Systemwartungsaufgaben ausführen", "Ejecute tareas recomendadas de mantenimiento del sistema macOS", "Esegui attività consigliate di manutenzione del sistema macOS", "Execute tarefas de manutenção recomendadas do sistema macOS")
        add(.toolboxMaintenanceScriptsCardTitle, "系统维护脚本", "系統維護腳本", "Maintenance Scripts", "保守スクリプト", "유지보수 스크립트",
            "Scripts de maintenance", "Wartungsskripte", "Scripts de mantenimiento", "Script di manutenzione", "Scripts de manutenção")
        add(.toolboxNoMatchingToolsPrompt, "未找到相关的工具。", "未找到相關的工具。", "No matching utilities found.", "該当するツールが見つかりません。", "일치하는 도구를 찾을 수 없습니다.",
            "Aucun utilitaire correspondant trouvé.", "Keine passenden Werkzeuge gefunden.", "No se encontraron herramientas coincidentes.", "Nessuna utilità corrispondente trovata.", "Nenhum utilitário correspondente encontrado.")
        add(.toolboxPreparingPrompt, "正在准备工具…", "正在準備工具…", "Preparing utilities…", "ツールを準備中…", "도구를 준비하는 중…",
            "Préparation des outils…", "Werkzeuge werden vorbereitet…", "Preparando herramientas…", "Preparazione strumenti in corso…", "Preparando utilitários…")
    }

}
