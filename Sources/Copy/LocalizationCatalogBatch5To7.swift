import Foundation

extension LocalizationCatalog {
    static func populateBatch5(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.favoriteAdded, "已收藏", "已加入常用", "Favorited", "お気に入り追加済み", "즐겨찾기 추가됨",
            "Ajouté aux favoris", "Favorisiert", "En favoritos", "Nei preferiti", "Favoritado")
        add(.fdaWarningProtectedDirsIncomplete, "未授予「完全磁盘访问权限」，Safari 缓存、系统日志与废纸篓等受保护目录可能无法完整扫描。", "未授予「完全磁盤訪問權限」，Safari 緩存、系統日誌與廢紙簍等受保護目錄可能無法完整掃描。", "Full Disk Access not granted. Protected directories like Safari cache, system logs, and Trash may not be scanned completely.", "「フルディスクアクセス」が許可されていません。Safari キャッシュ、ログ、ゴミ箱などのスキャンが不完全になる可能性があります。", "'전체 디스크 접근 권한'이 부여되지 않았습니다. Safari 캐시, 시스템 로그, 휴지통 등 보호된 디렉터리의 검사가 완전하지 않을 수 있습니다.",
            "Accès complet au disque non accordé. Les dossiers protégés (caches Safari, journaux, Corbeille) peuvent ne pas être analysés.", "Festplattenvollzugriff nicht gewährt. Geschützte Ordner wie Safari-Cache, Systemprotokolle und Papierkorb werden evtl. nicht gescannt.", "Acceso total al disco no concedido. Las carpetas protegidas como caché de Safari, registros y Papelera no se escanearán por completo.", "Accesso completo al disco non concesso. Cartelle protette come cache di Safari, registri e Cestino potrebbero non essere scansionate.", "Acesso Total ao Disco não concedido. Diretórios protegidos como cache do Safari, logs e Lixo podem não ser verificados por completo.")
        add(.featureCleanUninstall, "彻底卸载", "徹底解除安裝", "Complete Uninstall", "完全アンインストール", "완전 삭제",
            "Désinstallation complète", "Vollständig deinstallieren", "Desinstalación completa", "Disinstallazione completa", "Desinstalação Completa")
        add(.featureStartupComponents, "自启组件", "自啟組件", "Startup Items & Extensions", "自動起動コンポーネント", "자동 실행 구성 요소",
            "Éléments et extensions de démarrage", "Autostart-Objekte & Erweiterungen", "Elementos y extensiones de inicio", "Elementi di avvio ed estensioni", "Itens de Inicialização e Extensões")
        add(.featureUnusedApps, "闲置应用", "閒置應用", "Unused Applications", "未使用のアプリ", "미사용 응용 프로그램",
            "Applications inutilisées", "Ungenutzte Programme", "Aplicaciones sin usar", "Applicazioni inutilizzate", "Aplicativos Não Usados")
        add(.fileType, "文件类型", "檔案類型", "File Type", "ファイルの種類", "파일 유형",
            "Type de fichier", "Dateityp", "Tipo de archivo", "Tipo di file", "Tipo de arquivo")
        add(.fileTypeFile, "文件", "檔案", "File", "ファイル", "파일",
            "Fichier", "Datei", "Archivo", "File", "Arquivo")
        add(.fileTypeFolder, "文件夹", "資料夾", "Folder", "フォルダ", "폴더",
            "Dossier", "Ordner", "Carpeta", "Cartella", "Pasta")
        add(.filter32Bit, "32 位", "32 位元", "32-bit", "32ビット", "32비트",
            "32 bits", "32-Bit", "32 bits", "32 bit", "32 bits")
        add(.filterAll, "全部", "全部", "All", "すべて", "전체",
            "Tout", "Alle", "Todo", "Tutto", "Todos")
        add(.filterAllApplications, "所有应用程序", "所有應用程式", "All Applications", "すべてのアプリケーション", "모든 응용 프로그램",
            "Toutes les applications", "Alle Anwendungen", "Todas las aplicaciones", "Tutte le applicazioni", "Todos os Aplicativos")
        add(.filterAllJunk, "全部垃圾", "全部垃圾", "All Junk", "すべての不要ファイル", "모든 정크",
            "Tous les fichiers inutiles", "Gesamter Müll", "Toda la basura", "Tutti i file inutili", "Todo o Lixo")
        add(.filterAppLeftovers, "程序残留", "程式殘留", "Leftovers", "残りファイル", "잔여 파일",
            "Résidus", "Reste", "Restos", "Residui", "Resíduos")
        add(.filterAppStore, "App Store", "App Store", "App Store", "App Store", "App Store",
            "App Store", "App Store", "App Store", "App Store", "App Store")
        add(.filterAppUpdates, "更新通道", "更新通道", "Update Channels", "アップデートチャネル", "업데이트 채널",
            "Canaux de mise à jour", "Update-Kanäle", "Canales de actualización", "Canali di aggiornamento", "Canais de Atualização")
        add(.filterNeverOpened, "从未打开", "從未打開", "Never Opened", "一度も開いていない", "한 번도 열지 않음",
            "Jamais ouvertes", "Nie geöffnet", "Nunca abiertas", "Mai aperte", "Nunca Abertos")
        add(.filterSelected, "勾选的", "勾選的", "Selected", "選択済み", "선택됨",
            "Sélectionnées", "Ausgewählt", "Seleccionadas", "Selezionate", "Selecionados")
        add(.filterSuspicious, "可疑项", "可疑項", "Suspicious", "不審な項目", "의심스러운 항목",
            "Suspectes", "Verdächtig", "Sospechosas", "Sospette", "Suspeitos")
        add(.filterUnused, "未使用", "未使用", "Unused", "未使用", "사용 안 함",
            "Inutilisées", "Ungenutzt", "Sin usar", "Inutilizzate", "Não Utilizados")
        add(.findBackgroundLaunchagentsAndHelperToolsBundledWithAppsToKeepMacosFast, "检索随应用常驻后台的 LaunchAgent 与 Helper，防止拖慢系统", "檢索隨應用常駐後台的 LaunchAgent 與 Helper，防止拖慢系統", "Find background LaunchAgents and helper tools bundled with apps to keep macOS fast", "アプリに付随してバックグラウンドで動作する常駐プロセスを検出", "앱과 함께 백그라운드에 상주하는 LaunchAgent 및 헬퍼를 검색하여 성능을 유지합니다",
            "Trouvez les LaunchAgents et assistants d’arrière-plan pour éviter de ralentir le système", "Findet LaunchAgents und Hilfsprogramme im Hintergrund, um das System schnell zu halten", "Localiza LaunchAgents y asistentes en segundo plano para no ralentizar el sistema", "Trova LaunchAgent e strumenti di supporto in background per mantenere il sistema scattante", "Localize LaunchAgents e utilitários em segundo plano para evitar lentidão")
        add(.findHiddenLargeFilesAndLeftovers, "找出平时被系统隐藏的大文件与残留", "找出平時被系統隱藏的大檔案與殘留", "Find large files and leftovers hidden by the system", "通常隠されている大容量ファイルや残骸を検出", "시스템에 숨겨진 대용량 파일과 잔여물 찾기",
            "Trouvez les fichiers volumineux et résidus cachés par le système", "Vom System ausgeblendete große Dateien und Reste finden", "Encuentra archivos grandes y restos ocultos por el sistema", "Trova file grandi e residui nascosti dal sistema", "Encontre arquivos grandes e resíduos ocultos pelo sistema")
        add(.findLargeAndOldFilesDesc, "查找体积较大或长期未使用的文件", "尋找體積較大或長期未使用的檔案", "Find large or long-unused files", "大容量ファイルや長期間未使用のファイルを検出", "용량이 크거나 오래 사용하지 않은 파일 찾기",
            "Trouver les fichiers volumineux ou inutilisés depuis longtemps", "Große oder lange nicht verwendete Dateien finden", "Buscar archivos grandes o sin usar hace tiempo", "Trova file grandi o non utilizzati da tempo", "Encontrar arquivos grandes ou não utilizados há muito tempo")
        add(.findLargeOrLongUnusedFiles, "查找体积较大或长期未使用的文件", "尋找體積較大或長期未使用的檔案", "Locate large or long-forgotten files", "大容量または長期間使われていないファイルを検出", "용량이 크거나 오랫동안 사용하지 않은 파일 찾기",
            "Localisez les fichiers volumineux ou inutilisés depuis longtemps", "Finden Sie große oder längst vergessene Dateien", "Localice archivos grandes o sin usar desde hace tiempo", "Trova file di grandi dimensioni o non usati da molto tempo", "Localize arquivos grandes ou não utilizados há muito tempo")
        add(.findSimilarPhotosDesc, "查找内容相近的照片，保留最好的一张", "尋找內容相近的照片，保留最好的一張", "Find similar photos and keep the best shot", "類似した写真を検出し、最適な1枚を保持", "유사한 사진을 찾고 최고의 사진 유지",
            "Trouver des photos similaires et garder la meilleure", "Ähnliche Fotos finden und die beste Aufnahme behalten", "Buscar fotos similares y conservar la mejor toma", "Trova foto simili e conserva lo scatto migliore", "Encontrar fotos semelhantes e manter a melhor foto")
        add(.findSimilarPhotosKeepBestDesc, "查找内容相近的照片,保留最好的一张", "尋找內容相近的照片,保留最好的一張", "Review similar shots and keep only the best one", "似た構図の写真を検索し、ベストショットだけを保管", "비슷한 사진을 찾아 가장 잘 나온 한 장만 유지하세요",
            "Passez en revue les photos similaires et gardez le meilleur cliché", "Überprüfen Sie ähnliche Aufnahmen und behalten Sie nur die beste", "Revise fotos similares y guarde solo la mejor toma", "Esamina gli scatti simili e mantieni solo lo scatto migliore", "Examine fotos semelhantes e mantenha apenas a melhor imagem")
        add(.finderAndDesktopPreview, "访达与桌面预览", "Finder 與桌面預覽", "Finder & QuickLook", "Finder・クイックルック", "Finder 및 훑어보기",
            "Finder et Coup d’œil", "Finder & Übersicht", "Finder y Vista rápida", "Finder e Visualizzazione rapida", "Finder e Visualização Rápida")
        add(.finderDockRefresh, "访达与程序坞假死刷新", "Finder與程序塢假死刷新", "Restart Finder & Dock", "Finder と Dock の応答停止を解除", "Finder 및 Dock 멈춤 현상 새로고침",
            "Redémarrer le Finder et le Dock", "Finder & Dock neu starten", "Reiniciar Finder y Dock", "Riavvia Finder e Dock", "Reiniciar Finder e Dock")
        add(.findingLargeAndOldFilesPrompt, "查找 Mac 电脑上体积较大且长期未使用的文件…", "尋找 Mac 電腦上體積較大且長期未使用的檔案…", "Finding large and long-unused files on your Mac…", "Mac 上の大容量または長期間未使用のファイルを検出中…", "Mac에서 대용량 및 오래 사용하지 않은 파일 찾는 중…",
            "Recherche des fichiers volumineux et anciens sur votre Mac…", "Suche nach großen und lange unbenutzten Dateien auf Ihrem Mac…", "Buscando archivos grandes y antiguos en el Mac…", "Ricerca di file grandi e vecchi sul Mac…", "Procurando arquivos grandes e antigos no seu Mac…")
        add(.findingObsoleteInstallersPrompt, "查找已废弃的应用程序安装包…", "尋找已廢棄的應用程式安裝套件…", "Finding obsolete application installers…", "不要なインストーラパッケージを検索中…", "불필요한 응용 프로그램 설치 패키지 찾는 중…",
            "Recherche des programmes d'installation obsolètes…", "Suche nach veralteten Installationspaketen…", "Buscando instaladores de aplicaciones obsoletos…", "Ricerca installer di applicazioni obsoleti…", "Procurando instaladores de aplicativos obsoletos…")
        add(.flowAppsFoundSummaryFormat, "我们在您的 Mac 电脑上找到了 %d 个 App。", "我們在您的 Mac 電腦上找到了 %d 個 App。", "We found %d apps on your Mac.", "お使いの Mac で %d 個のアプリが見つかりました。", "Mac에서 %d개의 앱을 찾았습니다.",
            "Nous avons trouvé %d apps sur votre Mac.", "Wir haben %d Apps auf Ihrem Mac gefunden.", "Encontramos %d apps en tu Mac.", "Abbiamo trovato %d app sul tuo Mac.", "Encontramos %d apps no seu Mac.")
        add(.flowCategoryTotalSizeSummaryFormat, "您的 Mac 上有 %@ 的 %@ 项目。", "您的 Mac 上有 %@ 的 %@ 項目。", "You have %@ of %@ items on your Mac.", "お使いの Mac に %@ の %@ 項目があります。", "Mac에 %@의 %@ 항목이 있습니다.",
            "Vous avez %@ d'éléments de %@ sur votre Mac.", "Auf Ihrem Mac befinden sich %@ an %@-Objekten.", "Tienes %@ de elementos de %@ en tu Mac.", "Hai %@ di elementi di %@ sul tuo Mac.", "Você tem %@ de itens de %@ no seu Mac.")
        add(.flowCleaningModuleFormat, "正在清理 %@…", "正在清理 %@…", "Cleaning %@…", "%@ をクリーニング中…", "%@ 청소 중…",
            "Nettoyage de %@…", "%@ wird bereinigt…", "Limpiando %@…", "Pulizia di %@ in corso…", "Limpando %@…")
        add(.flowFreedSpaceSummaryFormat, "已释放 %@ 存储空间", "已釋放 %@ 儲存空間", "Freed %@ of storage space", "%@ の空き領域を解放しました", "%@의 저장 공간을 확보했습니다",
            "%@ d'espace de stockage libéré", "%@ Speicherplatz freigegeben", "Se liberaron %@ de espacio de almacenamiento", "Liberati %@ di spazio di archiviazione", "Liberados %@ de espaço de armazenamento")
        add(.flowModuleBelongingLabel, "所属模块", "所屬模組", "Module", "所属モジュール", "소속 모듈",
            "Module", "Modul", "Módulo", "Modulo", "Módulo")
        add(.flowRunTasksCountFormat, "运行任务 (%d)", "執行任務 (%d)", "Run Tasks (%d)", "タスクを実行 (%d)", "작업 실행 (%d)",
            "Exécuter les tâches (%d)", "Aufgaben ausführen (%d)", "Ejecutar tareas (%d)", "Esegui attività (%d)", "Executar Tarefas (%d)")
        add(.flowRunningModuleFormat, "正在运行 %@…", "正在執行 %@…", "Running %@…", "%@ を実行中…", "%@ 실행 중…",
            "Exécution de %@…", "%@ wird ausgeführt…", "Ejecutando %@…", "Esecuzione di %@ in corso…", "Executando %@…")
        add(.flowSelectedSummaryFormat, "共 %d 项 · %@", "共 %d 項 · %@", "Total %d items · %@", "合計 %d 項目 · %@", "총 %d개 항목 · %@",
            "Total %d éléments · %@", "Insgesamt %d Objekte · %@", "Total %d elementos · %@", "Totale %d elementi · %@", "Total de %d itens · %@")
        add(.flowViewAllFilesButtonFormat, "查看所有 %@ 文件", "檢視所有 %@ 檔案", "View all %@ files", "すべての %@ ファイルを表示", "모든 %@ 파일 보기",
            "Afficher tous les fichiers de %@", "Alle %@-Dateien anzeigen", "Ver todos los archivos de %@", "Visualizza tutti i file di %@", "Ver todos os arquivos de %@")
        add(.flushDNSCache, "刷新 DNS 缓存", "重新整理 DNS 快取", "Flush DNS Cache", "DNSキャッシュをフラッシュ", "DNS 캐시 초기화",
            "Vider le cache DNS", "DNS-Cache leeren", "Vaciar caché DNS", "Svuota cache DNS", "Limpar Cache DNS")
        add(.followSystem, "跟随系统", "跟隨系統", "System", "システム設定に従う", "시스템 설정",
            "Système", "System", "Sistema", "Sistema", "Sistema")
        add(.foundAppsCountOnMacFormat, "我们在您的 Mac 电脑上找到了 %d 个 App。", "我們在您的 Mac 電腦上找到了 %d 個 App。", "Found %d apps on your Mac.", "お使いの Mac で %d 個のアプリが見つかりました。", "Mac에서 %d개의 앱을 찾았습니다.",
            "%d applications trouvées sur votre Mac.", "%d Apps auf Ihrem Mac gefunden.", "Se encontraron %d apps en su Mac.", "Trovate %d app sul tuo Mac.", "%d apps encontrados no seu Mac.")
        add(.foundFilteredCountFormat, "找到 %d 项", "找到 %d 項", "Found %d items", "%d 件を発見", "%d개 항목 발견",
            "%d éléments trouvés", "%d Elemente gefunden", "Se encontraron %d elementos", "Trovati %d elementi", "%d itens encontrados")
        add(.foundItemsCountFormat, "找到 %d 项", "找到 %d 項", "Found %d items", "%d 項目が見つかりました", "%d개 항목 발견",
            "%d éléments trouvés", "%d Objekte gefunden", "%d elementos encontrados", "%d elementi trovati", "%d itens encontrados")
        add(.foundLargeAndOldFilesSizeFormat, "已找到 %@ 的大型和旧文件", "已找到 %@ 的大型和舊檔案", "Found %@ of large & old files", "%@ の大容量・古いファイルを検出", "%@의 대용량 및 오래된 파일 발견",
            "%@ de fichiers volumineux et anciens trouvés", "%@ an großen & alten Dateien gefunden", "Se encontraron %@ de archivos grandes y antiguos", "Trovati %@ di file grandi e vecchi", "Encontrados %@ de arquivos grandes e antigos")
        add(.freeCapacityPurgeable, "可用容量 (含可自动回收)", "可用容量 (含可自動回收)", "Available Space (incl. Purgeable)", "空き容量 (パージ可能領域を含む)", "사용 가능 공간 (확보 가능 공간 포함)",
            "Espace disponible (purgeable incl.)", "Verfügbarer Speicherplatz (inkl. freigebbar)", "Espacio disponible (incl. purgable)", "Spazio disponibile (incluso eliminabile)", "Espaço Disponível (incl. purgável)")
        add(.freeInactiveMemoryNow, "立即释放非活跃内存缓存", "立即釋放非活躍記憶體快取", "Purge Inactive Memory Cache", "非アクティブメモリを即座に解放", "비활성 메모리 캐시 즉시 확보",
            "Libérer la mémoire inactive", "Inaktiven Speicher jetzt freigeben", "Liberar memoria inactiva ahora", "Libera memoria inattiva adesso", "Liberar Memória Inativa Agora")
        add(.freePhysicalMemory, "可用物理内存", "可用實體記憶體", "Available Memory", "空き物理メモリ", "사용 가능한 실제 메모리",
            "Mémoire physique disponible", "Verfügbarer Arbeitsspeicher", "Memoria física disponible", "Memoria fisica disponibile", "Memória Física Disponível")
        add(.freePurgeableSpace, "释放可清理空间", "釋放可清除空間", "Free Up Purgeable Space", "パージ可能領域を解放", "퍼지 가능 공간 확보",
            "Libérer l’espace purgeable", "Löschbaren Speicher freigeben", "Liberar espacio purgable", "Libera spazio spurgo", "Liberar Espaço Purgável")
        add(.freeRAM, "释放 RAM", "釋放 RAM 記憶體", "Free Up RAM", "メモリ（RAM）を解放", "RAM 메모리 확보",
            "Libérer la RAM", "RAM freigeben", "Liberar memoria RAM", "Libera memoria RAM", "Liberar Memória RAM")
        add(.freeSpace, "可用空间", "可用空間", "Free Space", "空き容量", "사용 가능 공간",
            "Espace libre", "Freier Speicher", "Espacio libre", "Spazio libero", "Espaço Livre")
        add(.freeUpInactiveMemoryDesc, "您的 Mac 的内存经常被占满。这会让您的应用和打开的文件反应很慢。ACleaner 可以帮助您的系统将所有不使用的数据从内存中清理出去，从而为当前需要的应用腾出空间。", "您的 Mac 的內存經常被佔滿。這會讓您的應用和打開的文件反應很慢。ACleaner 可以幫助您的系統將所有不使用的數據從內存中清理出去，從而為當前需要的應用騰出空間。", "Free up inactive memory pages so active applications can respond faster without paging.", "お使いの Mac のメモリが頻繁に不足すると、アプリの動作が遅くなります。ACleaner は不要なデータをメモリから解放し、必要なアプリのための領域を確保します。", "Mac의 메모리가 자주 꽉 차면 앱과 파일의 반응이 느려집니다. ACleaner은 사용하지 않는 데이터를 정리하여 필요한 앱을 위한 공간을 확보합니다.",
            "Libérez les pages de mémoire inactives pour que les applications actives répondent plus rapidement.", "Gibt inaktiven Arbeitsspeicher frei, damit aktive Apps schneller reagieren können.", "Libere memoria inactiva para que las aplicaciones activas respondan más rápido.", "Libera la memoria inattiva in modo che le app attive possano rispondere più velocemente.", "Libere memória inativa para que os aplicativos ativos respondam mais rapidamente sem paginação.")
        add(.freeUpPurgeableRam, "释放可清除内存", "釋放可清除記憶體", "Free Up Purgeable RAM", "パージ可能メモリを解放", "확보 가능 메모리 정리",
            "Libérer la mémoire RAM purgeable", "Bereinigbaren RAM freigeben", "Liberar memoria RAM purgable", "Libera memoria RAM eliminabile", "Liberar Memória RAM Purgável")
        add(.freedStorageSpaceSummaryFormat, "已释放 %@ 存储空间", "已釋放 %@ 儲存空間", "Freed %@ of storage space", "%@ のストレージ領域を解放しました", "%@의 저장 공간을 확보했습니다",
            "%@ d'espace de stockage libéré", "%@ an Speicherplatz freigegeben", "Se liberaron %@ de espacio de almacenamiento", "Liberati %@ di spazio di archiviazione", "%@ de espaço de armazenamento liberados")
        add(.fullDiskAccessGrantedSafeDeepScanningOfSystemCachesAndContainersEnabled, "系统安全防护已解除限制，可深度扫描系统缓存与沙盒容器", "系統安全防護已解除限制，可深度掃描系統快取與沙盒容器", "Full Disk Access granted. Safe deep scanning of system caches and containers enabled.", "フルディスクアクセスが許可されました。システムキャッシュとサンドボックスの完全なスキャンが可能です。", "전체 디스크 접근 권한이 부여되었습니다. 시스템 캐시와 샌드박스를 안전하게 정밀 스캔할 수 있습니다.",
            "Accès complet au disque accordé. Analyse approfondie activée.", "Festplattenvollzugriff gewährt. Tiefenscan für System-Caches aktiviert.", "Acceso total al disco concedido. Análisis profundo activado.", "Accesso completo al disco concesso. Scansione approfondita attiva.", "Acesso Total ao Disco concedido. Verificação profunda ativada.")
        add(.gateway, "网关", "網關", "Gateway", "ゲートウェイ", "게이트웨이",
            "Passerelle", "Gateway", "Puerta de enlace", "Gateway", "Gateway")
        add(.generatingMaintenanceTasksPrompt, "为您的 Mac 电脑生成推荐的系统维护任务…", "為您的 Mac 電腦產生推薦的系統維護任務…", "Generating recommended system maintenance tasks…", "推奨されるメンテナンススクリプトを生成中…", "권장 시스템 유지 관리 작업 생성 중…",
            "Génération des tâches de maintenance recommandées…", "Empfohlene Systemwartungsaufgaben erstellen…", "Generando tareas de mantenimiento recomendadas…", "Generazione attività di manutenzione consigliate…", "Gerando tarefas de manutenção recomendadas…")
        add(.globalAgent, "全局代理", "全域代理", "Global Agent", "グローバルエージェント", "글로벌 에이전트",
            "Agent global", "Globaler Agent", "Agente global", "Agente globale", "Agente Global")
        add(.globalAgents, "全局代理", "全域代理", "Global Agents", "グローバルエージェント", "전역 에이전트",
            "Agents globaux", "Globale Agenten", "Agentes globales", "Agenti globali", "Agentes globais")
        add(.globalAgentsDesc, "所有用户登录时运行的代理程序。", "所有使用者登入時執行的代理程式。", "Agents that run when any user logs in.", "すべてのユーザーのログイン時に実行されるエージェント。", "모든 사용자가 로그인할 때 실행되는 에이전트 프로그램입니다.",
            "Agents exécutés lors de la connexion de tout utilisateur.", "Agenten, die bei der Anmeldung aller Benutzer ausgeführt werden.", "Agentes que se ejecutan cuando cualquier usuario inicia sesión.", "Agenti eseguiti all'accesso di qualsiasi utente.", "Agentes executados quando qualquer usuário inicia sessão.")
        add(.gpuCoreSpecs, "显卡核心规格", "顯示卡核心規格", "GPU Core Configuration", "GPU コア仕様", "GPU 코어 사양",
            "Spécifications des cœurs GPU", "GPU-Kerne-Spezifikation", "Especificaciones de núcleos GPU", "Specifiche core GPU", "Configuração dos Núcleos da GPU")
        add(.gpuCoreTemp, "GPU 核心温度", "GPU 核心溫度", "GPU Temperature", "GPU 温度", "GPU 코어 온도",
            "Température du GPU", "GPU-Temperatur", "Temperatura de la GPU", "Temperatura GPU", "Temperatura da GPU")
        add(.gpuCoresCountFormat, "%d核", "%d核", "%d Cores", "%dコア", "%d코어",
            "%d cœurs", "%d Kerne", "%d núcleos", "%d core", "%d núcleos")
        add(.gpuRealtimePower, "GPU 实时功率", "GPU 即時功率", "GPU Power Draw", "GPU 消費電力", "GPU 실시간 전력",
            "Puissance du GPU", "GPU-Leistungsaufnahme", "Consumo de GPU", "Potenza assorbita GPU", "Consumo da GPU")
        add(.gpuRenderDetails, "GPU 渲染详情", "GPU 渲染詳情", "GPU Render Details", "GPU レンダリング詳細", "GPU 렌더링 상세 정보",
            "Détails de la carte graphique (GPU)", "GPU-Details", "Detalles gráficos (GPU)", "Dettagli GPU", "Detalhes da GPU")
        add(.grantFullDiskAccess, "开启磁盘访问权限", "開啟完全磁碟取用權限", "Grant Full Disk Access", "フルディスクアクセスを許可", "전체 디스크 접근 권한 허용",
            "Autoriser l’accès complet au disque", "Festplattenvollzugriff erlauben", "Permitir acceso total al disco", "Consenti accesso completo al disco", "Permitir Acesso Total ao Disco")
        add(.groupCoreClean, "核心清理", "核心清理", "Core Cleaning", "コアクリーン", "핵심 정리",
            "Nettoyage principal", "Hauptbereinigung", "Limpieza principal", "Pulizia principale", "Limpeza Principal")
        add(.groupInsightTools, "洞察与工具", "洞察與工具", "Insights & Tools", "インサイトとツール", "인사이트 및 도구",
            "Outils et analyses", "Analysen & Tools", "Herramientas y análisis", "Strumenti e analisi", "Informações e Ferramentas")
        add(.groupOverview, "全盘概览", "全盤概覽", "Overview", "概要", "전체 개요",
            "Vue d’ensemble", "Übersicht", "Visión general", "Panoramica", "Visão Geral")
        add(.groupSystemManage, "系统管理", "系統管理", "System Control", "システム管理", "시스템 관리",
            "Contrôle système", "Systemverwaltung", "Control del sistema", "Controllo sistema", "Controle do Sistema")
        add(.healthExcellent, "优秀", "極佳", "Excellent", "優良", "아주 좋음",
            "Excellent", "Ausgezeichnet", "Excelente", "Eccellente", "Excelente")
        add(.healthFair, "一般", "普通", "Fair", "普通", "보통",
            "Moyen", "Mäßig", "Regular", "Discreto", "Regular")
        add(.healthGood, "良好", "良好", "Good", "良好", "좋음",
            "Bon", "Gut", "Bueno", "Buono", "Bom")
        add(.healthNeedsAttention, "需要注意", "需要注意", "Needs Attention", "要確認", "주의 필요",
            "Attention requise", "Aufmerksamkeit erforderlich", "Requiere atención", "Richiede attenzione", "Requer Atenção")
        add(.healthPrefix, "健康", "健康", "Health", "健全性", "건강",
            "Santé", "Zustand", "Salud", "Salute", "Saúde")
        add(.healthScore, "健康度", "健康度", "Health", "ヘルス", "상태 점수",
            "Santé", "Zustand", "Salud", "Salute", "Saúde")
        add(.hiddenFilesAutomaticallyIncluded, "已自动将系统与用户隐藏文件纳入可视化。", "已自動將系統與使用者隱藏檔案納入視覺化。", "System and user hidden files are automatically visualized.", "システムとユーザーの隠しファイルが自動的に可視化されました。", "시스템 및 사용자 숨김 파일이 시각화에 자동 포함되었습니다.",
            "Les fichiers cachés système et utilisateur sont automatiquement visualisés.", "Ausgeblendete System- und Benutzerdateien werden visualisiert.", "Los archivos ocultos del sistema y del usuario se visualizan automáticamente.", "I file nascosti di sistema e utente sono visualizzati automaticamente.", "Arquivos ocultos do sistema e do usuário são visualizados automaticamente.")
        add(.highRiskCleanupConfirm, "高危清理确认", "高危清理確認", "High-Risk Confirm", "高リスク削除の確認", "위험 정리 확인",
            "Confirmation de risque", "Bestätigung riskanter Löschungen", "Confirmación de riesgo", "Conferma alto rischio", "Confirmação de risco")
        add(.highRiskCleanupConfirmSubtitle, "高危清理前二次确认", "高危清理前二次確認", "High-Risk Cleanup Confirmation", "高リスク項目の削除前確認", "고위험 항목 삭제 전 재확인",
            "Confirmation avant suppression à risque", "Bestätigung vor riskantem Löschen", "Confirmar antes de limpieza crítica", "Conferma prima di eliminazione critica", "Confirmação Antes de Limpeza de Risco")
        add(.howDoYouKeepItSoClean, "您是怎么保持得这么整洁的？", "您是怎麼保持得這麼整潔的？", "How do you keep it so clean?", "どうやってこんなに整頓しているのですか？", "어떻게 이렇게 깔끔하게 유지하시나요?",
            "Comment faites-vous pour garder tout si ordonné ?", "Wie halten Sie alles so aufgeräumt?", "¿Cómo lo mantienes tan limpio?", "Come fai a mantenerlo così pulito?", "Como você mantém tudo tão organizado?")
        add(.icloudDriveBackgroundSyncDaemon, "iCloud 云盘后台同步守护进程", "iCloud 雲盤後台同步守護處理程序", "iCloud Drive background sync daemon", "iCloud Drive バックグラウンド同期デーモン", "iCloud Drive 백그라운드 동기화 데몬",
            "Démon de synchronisation en arrière-plan d’iCloud Drive", "iCloud Drive Hintergrund-Synchronisationsdaemon", "Demonio de sincronización en segundo plano de iCloud Drive", "Daemon di sincronizzazione in background di iCloud Drive", "Daemon de sincronização em segundo plano do iCloud Drive")
        add(.identicalFileDuplicatesWithMatchingContentHashes, "内容哈希完全一致的多份文件副本", "內容哈希完全一致的多份檔案副本", "Identical file duplicates with matching content hashes", "コンテンツハッシュが完全に一致する重複ファイル", "콘텐츠 해시가 완전히 일치하는 중복 파일 사본",
            "Copies de fichiers identiques aux sommes de contrôle concordantes", "Identische Dateiduplikate mit übereinstimmendem Content-Hash", "Copias de archivos idénticas con hashes de contenido coincidentes", "Copie di file identiche con hash del contenuto corrispondente", "Cópias idênticas de arquivos com hashes de conteúdo coincidentes")
        add(.identifySoftwareUnopenedForMonthsBasedOnActivityTimeToReclaimStorage, "根据最后活跃时间识别数月未曾打开的陈旧软件，释放宝贵存储", "根據最後活躍時間識別數月未曾開啟的陳舊軟體，釋放寶貴儲存", "Identify software unopened for months based on activity time to reclaim storage", "最終使用日時に基づき数ヶ月開かれていないソフトを検出し、容量を節約", "마지막 실행 시간을 기준으로 수개월간 열지 않은 오래된 소프트웨어를 식별합니다",
            "Détecte les logiciels non ouverts depuis des mois pour récupérer de l’espace précieux", "Erkennt seit Monaten ungeöffnete Software, um wertvollen Speicherplatz freizugeben", "Detecta software que no has abierto en meses para recuperar espacio valioso", "Individua il software inutilizzato da mesi per liberare spazio prezioso", "Identifique softwares sem uso há meses para recuperar espaço precioso")
        add(.idlePrefix, "空闲", "閒置", "Idle", "アイドル", "유휴",
            "Inactif", "Leerlauf", "Inactivo", "Inattivo", "Ocioso")
        add(.inputMethodLagFix, "输入法卡顿修复", "輸入法卡頓修復", "Fix Input Method Lag", "入力切替の不具合修復", "입력기 지연 및 버벅임 해결",
            "Corriger la lenteur de la méthode de saisie", "Eingabemethoden-Verzögerung beheben", "Corregir retraso del método de entrada", "Risolvi ritardo metodo di inserimento", "Corrigir Atraso do Método de Entrada")
        add(.inputMethodSwitching, "输入法切换", "輸入法切換", "Input Switching", "入力ソース切替", "입력기 전환",
            "Changement de saisie", "Eingabequellenwechsel", "Cambio de teclado", "Cambio metodo di input", "Alternância de Teclado")
        add(.installedAppsHeader, "已安装 App", "已安裝 App", "Installed Apps", "インストール済みアプリ", "설치된 앱",
            "Applications installées", "Installierte Programme", "Aplicaciones instaladas", "Applicazioni installate", "Aplicativos Instalados")
        add(.installersInDownloadsAndOldArchivesConfirmationRequested, "下载目录安装包、长期未用归档，提示确认", "下載目錄安裝檔、長期未用歸檔，提示確認", "Installers in Downloads & old archives; confirmation requested", "ダウンロード内のインストーラや長期未使用アーカイブ。確認を促します", "다운로드 폴더의 설치 패키지 및 장기 미사용 압축파일. 확인 메시지 표시",
            "Installateurs du dossier Téléchargements et vieilles archives ; confirmation demandée", "Installationspakete im Download-Ordner & alte Archive; Bestätigung erforderlich", "Instaladores en Descargas y archivos antiguos; confirmación requerida", "Installatori in Download e vecchi archivi; richiesta di conferma", "Instaladores em Downloads e arquivos antigos; confirmação solicitada")
        add(.interfaceLanguage, "界面语言", "介面語言", "Language", "言語", "언어",
            "Langue", "Sprache", "Idioma", "Lingua", "Idioma")
        add(.intervalAvgPeak, "区间均值 / 峰值", "區間平均 / 峰值", "Average / Peak", "平均 / ピーク", "구간 평균 / 최고치",
            "Moyenne / Pic", "Mittelwert / Spitze", "Media / Pico", "Media / Picco", "Média / Pico")
        add(.invalidProgramMissing, "无效（程序不存在）", "無效（程式不存在）", "Invalid (Program does not exist)", "無効（プログラムが存在しません）", "유효하지 않음 (프로그램 없음)",
            "Invalide (programme inexistant)", "Ungültig (Programm existiert nicht)", "No válido (el programa no existe)", "Non valido (il programma non esiste)", "Inválido (o programa não existe)")
        add(.ispAndRegion, "归属地 / ISP", "歸屬地 / ISP", "ISP / Region", "ISP / 地域", "통신사(ISP) / 지역",
            "FAI / Région", "ISP / Region", "ISP / Región", "ISP / Regione", "Provedor / Região")
        add(.itemsCountAndSizeFormat, "%d 项 · %@", "%d 項 · %@", "%d items · %@", "%d 項目 · %@", "%d개 항목 · %@",
            "%d éléments · %@", "%d Objekte · %@", "%d elementos · %@", "%d elementi · %@", "%d itens · %@")
        add(.itemsPendingActionFormat, "%d 项待处理", "%d 項待處理", "%d items pending", "%d 項目が処理待ち", "%d개 처리 대기",
            "%d éléments à traiter", "%d Objekte ausstehend", "%d elementos pendientes", "%d elementi da elaborare", "%d itens pendentes")
        add(.itemsToProcess, "项待处理", "項待處理", "items to process", "件の処理待ち", "개 항목 대기 중",
            "éléments à traiter", "Elemente ausstehend", "elementos por procesar", "elementi da elaborare", "itens para processar")
        add(.junkAiTools, "AI 工具", "AI 工具", "AI Tools", "AI ツール", "AI 도구",
            "Outils IA", "KI-Tools", "Herramientas de IA", "Strumenti IA", "Ferramentas de IA")
        add(.junkAppCachesAndLogs, "App 缓存与日志", "App 快取與日誌", "App Caches & Logs", "App キャッシュとログ", "앱 캐시 및 로그",
            "Caches et journaux d’apps", "App-Caches & Protokolle", "Cachés y registros de apps", "Cache e log delle app", "Caches e registros de apps")
        add(.junkAppStoreCacheTitle, "App Store 缓存", "App Store 快取", "App Store Cache", "App Store キャッシュ", "App Store 캐시",
            "Cache de l’App Store", "App Store-Cache", "Caché de App Store", "Cache di App Store", "Cache da App Store")
        add(.junkCacheAllocatedSize, "磁盘分配大小", "磁碟配置大小", "Allocated disk size", "ディスク割り当てサイズ", "디스크 할당 크기",
            "Taille disque allouée", "Zugewiesene Festplattengröße", "Tamaño asignado en disco", "Dimensione allocata su disco", "Tamanho alocado em disco")
        add(.junkCacheEffectFirstLaunch, "清理后首次打开可能变慢，但不会删除账号或核心业务数据", "清理後首次開啟可能變慢，但不會刪除帳號或核心業務資料", "First launch may be slower after cleaning; accounts and core user data are kept", "削除後の初回起動は遅くなる場合がありますが、アカウントや主要データは保持されます", "정리 후 첫 실행이 느려질 수 있으나 계정과 핵심 데이터는 유지됩니다",
            "Le premier lancement peut être plus lent après nettoyage ; comptes et données principales sont conservés", "Der erste Start kann nach dem Bereinigen langsamer sein; Konten und Kerndaten bleiben erhalten", "El primer inicio puede ser más lento tras limpiar; las cuentas y datos principales se conservan", "Il primo avvio potrebbe essere più lento dopo la pulizia; account e dati principali restano intatti", "A primeira abertura pode ficar mais lenta após a limpeza; contas e dados principais são mantidos")
        add(.junkCacheEffectRecompile, "清理后下次构建或打开工程会重新索引或重编译", "清理後下次建置或開啟專案會重新索引或重新編譯", "Cleaning will cause reindexing or recompilation on next build/open", "削除すると次回ビルドまたは起動時に再インデックス・再コンパイルが発生します", "정리하면 다음 빌드 또는 프로젝트 열기 시 다시 인덱싱하거나 컴파일합니다",
            "Le nettoyage provoquera une réindexation ou recompilation au prochain build/ouverture", "Nach dem Bereinigen erfolgt beim nächsten Build/Öffnen eine Neuindizierung oder Neukompilierung", "Al limpiar se reindexará o recompilará en la próxima compilación o apertura", "La pulizia causerà reindicizzazione o ricompilazione alla prossima apertura/build", "A limpeza causará reindexação ou recompilação na próxima abertura/compilação")
        add(.junkCacheEffectRedownload, "清理后将重新下载缓存或离线资源", "清理後將重新下載快取或離線資源", "Cleaning will trigger cache or offline asset redownloads", "削除するとキャッシュやオフライン資源が再ダウンロードされます", "정리하면 캐시 또는 오프라인 리소스를 다시 다운로드합니다",
            "Le nettoyage entraînera le retéléchargement du cache ou des ressources hors ligne", "Nach dem Bereinigen werden Cache- oder Offline-Ressourcen neu geladen", "Al limpiar se volverán a descargar el caché o los recursos sin conexión", "La pulizia comporterà il nuovo download della cache o delle risorse offline", "A limpeza fará o download novamente do cache ou dos recursos offline")
        add(.junkCacheEffectUnknown, "该缓存未纳入自动规则，请确认用途后再手动处理", "此快取未納入自動規則，請確認用途後再手動處理", "This cache is not covered by automatic rules; review its purpose before manual action", "このキャッシュは自動ルール対象外です。用途を確認してから手動で処理してください", "이 캐시는 자동 규칙에 포함되지 않습니다. 용도를 확인한 뒤 수동으로 처리하세요",
            "Ce cache n’est pas couvert par les règles automatiques ; vérifiez son rôle avant toute action manuelle", "Dieser Cache fällt nicht unter automatische Regeln; prüfen Sie seinen Zweck vor manuellen Aktionen", "Este caché no está cubierto por reglas automáticas; revise su propósito antes de actuar manualmente", "Questa cache non è coperta da regole automatiche; verificane lo scopo prima di agire manualmente", "Este cache não está coberto por regras automáticas; revise sua finalidade antes de agir manualmente")
        add(.junkCacheLargeSuggestion, "大缓存（建议手动确认）", "大型快取（建議手動確認）", "Large cache (manual confirmation recommended)", "大容量キャッシュ（手動確認を推奨）", "대용량 캐시(수동 확인 권장)",
            "Cache volumineux (confirmation manuelle recommandée)", "Großer Cache (manuelle Bestätigung empfohlen)", "Caché grande (se recomienda confirmación manual)", "Cache di grandi dimensioni (conferma manuale consigliata)", "Cache grande (confirmação manual recomendada)")
        add(.junkCommTools, "通讯工具", "通訊工具", "Communication Apps", "コミュニケーションツール", "메신저 및 커뮤니케이션",
            "Messagerie et communication", "Kommunikation", "Apps de comunicación", "App di comunicazione", "Apps de comunicação")
        add(.junkDesignCaches, "设计缓存", "設計快取", "Design Caches", "デザインキャッシュ", "디자인 캐시",
            "Caches de design", "Design-Caches", "Cachés de diseño", "Cache di design", "Caches de design")
        add(.junkDevTools, "开发工具", "開發工具", "Developer Tools", "開発ツール", "개발자 도구",
            "Outils de développement", "Entwickler-Tools", "Herramientas de desarrollo", "Strumenti di sviluppo", "Ferramentas de desenvolvimento")
        add(.junkInventoryOnly, "仅盘点，不自动清理", "僅盤點，不自動清理", "Inventory only; not cleaned automatically", "一覧表示のみ（自動削除しない）", "목록만 표시하며 자동 정리하지 않음",
            "Inventaire uniquement, sans nettoyage automatique", "Nur Inventar, keine automatische Bereinigung", "Solo inventario; no se limpia automáticamente", "Solo inventario, senza pulizia automatica", "Apenas inventário; sem limpeza automática")
        add(.junkJetBrainsCacheTitle, "JetBrains IDE 缓存", "JetBrains IDE 快取", "JetBrains IDE Cache", "JetBrains IDE キャッシュ", "JetBrains IDE 캐시",
            "Cache JetBrains IDE", "JetBrains IDE-Cache", "Caché de JetBrains IDE", "Cache di JetBrains IDE", "Cache do JetBrains IDE")
        add(.junkManualManagement, "手动管理", "手動管理", "Manual Management", "手動管理", "수동 관리",
            "Gestion manuelle", "Manuelle Verwaltung", "Gestión manual", "Gestione manuale", "Gerenciamento manual")
        add(.junkProtectedPubCacheTitle, "Dart/Flutter Pub 缓存（只读）", "Dart/Flutter Pub 快取（唯讀）", "Dart/Flutter Pub Cache (Read-Only)", "Dart/Flutter Pub キャッシュ（読み取り専用）", "Dart/Flutter Pub 캐시(읽기 전용)",
            "Cache Pub Dart/Flutter (lecture seule)", "Dart/Flutter Pub-Cache (schreibgeschützt)", "Caché Pub de Dart/Flutter (solo lectura)", "Cache Pub Dart/Flutter (sola lettura)", "Cache Pub do Dart/Flutter (somente leitura)")
        add(.junkProtectedSpotifyCacheTitle, "Spotify 缓存与离线存储（只读）", "Spotify 快取與離線儲存（唯讀）", "Spotify Cache & Offline Storage (Read-Only)", "Spotify キャッシュとオフライン保存（読み取り専用）", "Spotify 캐시 및 오프라인 저장소(읽기 전용)",
            "Cache et stockage hors ligne Spotify (lecture seule)", "Spotify-Cache & Offline-Speicher (schreibgeschützt)", "Caché y almacenamiento sin conexión de Spotify (solo lectura)", "Cache e archiviazione offline di Spotify (sola lettura)", "Cache e armazenamento offline do Spotify (somente leitura)")
        add(.junkProtectedUserAssets, "包含用户历史、离线或草稿数据，受安全策略保护", "包含使用者歷史、離線或草稿資料，受安全策略保護", "Contains user history, offline content, or drafts protected by safety policy", "ユーザー履歴・オフラインデータ・下書きを含むため保護されています", "사용자 기록, 오프라인 콘텐츠 또는 초안이 포함되어 안전 정책으로 보호됨",
            "Contient l’historique, le contenu hors ligne ou les brouillons protégés", "Enthält geschützten Verlauf, Offline-Inhalte oder Entwürfe", "Contiene historial, contenido sin conexión o borradores protegidos", "Contiene cronologia, contenuti offline o bozze protetti", "Contém histórico, conteúdo offline ou rascunhos protegidos")
        add(.junkRuleCoverageUnavailable, "缺少扫描入口或规则覆盖，已转为只读锁定", "缺少掃描入口或規則覆蓋，已轉為唯讀鎖定", "Missing scanner coverage or rule binding; locked as read-only", "スキャン対象またはルール定義が不足しているため読み取り専用でロック", "스캔 항목 또는 규칙 매핑이 없어 읽기 전용으로 잠금",
            "Entrée d’analyse ou couverture de règle manquante ; verrouillé en lecture seule", "Fehlende Scanner-Abdeckung oder Regelbindung; schreibgeschützt gesperrt", "Falta cobertura de escaneo o regla; bloqueado en solo lectura", "Copertura di scansione o regola mancante; bloccato in sola lettura", "Cobertura de verificação ou regra ausente; bloqueado como somente leitura")
        add(.junkSystemData, "系统数据", "系統資料", "System Data", "システムデータ", "시스템 데이터",
            "Données système", "Systemdaten", "Datos del sistema", "Dati di sistema", "Dados do sistema")
        add(.junkUninstallerLeftovers, "卸载残留", "卸載殘留", "Leftovers", "アンインストール残骸", "삭제된 앱 잔여물",
            "Résidus de désinstallation", "Deinstallationsreste", "Restos de apps", "Residui di disinstallazione", "Resíduos de desinstalação")
        add(.junkUnsupportedDirectoryName, "目录名不满足受限格式，已跳过自动清理", "目錄名不滿足受限格式，已跳過自動清理", "Directory name does not match restricted format; automatic cleanup skipped", "ディレクトリ名が制限形式に一致しないため自動削除をスキップ", "디렉터리 이름이 제한된 형식과 일치하지 않아 자동 정리를 건너뜀",
            "Nom de dossier non conforme au format restreint ; nettoyage ignoré", "Verzeichnisname entspricht nicht dem eingeschränkten Format; übersprungen", "El nombre del directorio no cumple el formato restringido; omitido", "Nome cartella non conforme al formato ristretto; pulizia ignorata", "Nome do diretório fora do formato restrito; limpeza ignorada")
        add(.keep, "保留", "保留", "Keep", "保持", "유지",
            "Conserver", "Behalten", "Conservar", "Conserva", "Manter")
        add(.keepNewestPhotoDeleteOthersDesc, "每组保留最新的一张，其余副本可删除。", "每組保留最新的一張，其餘副本可刪除。", "Keep the newest shot in each group and delete duplicate takes.", "各グループで最新の1枚を残し、残りのコピーを削除できます。", "각 그룹에서 최신 사진 한 장을 남기고 나머지 복사본을 삭제할 수 있습니다.",
            "Conservez le cliché le plus récent de chaque groupe et supprimez les autres.", "Behalten Sie das neueste Foto jedes Satzes und löschen Sie den Rest.", "Conserve la toma más reciente de cada grupo y elimine el resto.", "Conserva lo scatto più recente di ogni gruppo ed elimina gli altri.", "Mantenha a foto mais recente de cada grupo e descarte as demais.")
        add(.keepOriginal, "原件保留", "保留原件", "Keep Original", "オリジナルを保持", "원본 유지",
            "Original conservé", "Original behalten", "Conservar original", "Mantieni originale", "Manter Original")
        add(.keepYourMacRunningLikeNew, "让你的 Mac 焕然一新", "讓你的 Mac 煥然一新", "Keep Your Mac Running Like New", "あなたの Mac を新品のようにリフレッシュ", "사용자의 Mac을 새것처럼 쾌적하게",
            "Gardez votre Mac rapide et comme neuf", "Bringen Sie Ihren Mac wieder in Bestform", "Mantén tu Mac como nuevo", "Mantieni il tuo Mac come nuovo", "Mantenha seu Mac Rápido como Novo")
        add(.labelActiveApps, "活跃应用", "活躍應用", "Active Apps", "アクティブアプリ", "활성 앱",
            "Apps actives", "Aktive Apps", "Apps activas", "App attive", "Apps ativos")
        add(.labelAndMore, "另有", "另有", "and ", "他 ", "추가로 ",
            "et ", "sowie ", "y otros ", "e altri ", "e mais ")
        add(.labelArchitecture, "架构", "架構", "Architecture", "アーキテクチャ", "아키텍처",
            "Architecture", "Architektur", "Arquitectura", "Architettura", "Arquitetura")
        add(.labelBatteryBusCurrent, "电池母线电流", "電池母線電流", "Battery Current", "バッテリー母線電流", "배터리 버스 전류",
            "Courant de la batterie", "Batteriestrom", "Corriente de la batería", "Corrente della batteria", "Corrente da bateria")
        add(.labelBatteryCycleCount, "循环计数 (Cycle Count)", "循環計數 (Cycle Count)", "Cycle Count", "充電サイクル数", "배터리 사이클 수 (Cycle Count)",
            "Cycles de batterie", "Ladezyklen", "Ciclos de carga", "Cicli di carica", "Ciclos de carga")
        add(.labelBatteryPowerRateWatts, "充放电功率", "充放電功率", "Charge / Discharge Rate", "充放電電力", "충방전 소비 전력",
            "Puissance de charge / décharge", "Lade- / Entladeleistung", "Tasa de carga / descarga", "Potenza di carica / scarica", "Taxa de carga / descarga")
        add(.labelBatteryRemainingEstimate, "预估剩余", "預估剩餘", "Estimated Remaining", "推定残り時間", "예상 남은 시간",
            "Estimation restante", "Geschätzte Restzeit", "Estimado restante", "Stima rimanente", "Tempo restante estimado")
        add(.labelBatteryRemainingTimeEstimate, "剩余电量续航预估", "剩餘電量續航預估", "Battery Time Remaining", "バッテリー残り時間予測", "배터리 잔여 예상 사용 시간",
            "Temps de batterie restant estimé", "Verbleibende Akkulaufzeit", "Tiempo de batería restante estimado", "Tempo di batteria rimanente stimato", "Tempo de bateria restante estimado")
        add(.labelBatteryTemperature, "电池温度", "電池溫度", "Battery Temperature", "バッテリー温度", "배터리 온도",
            "Température de la batterie", "Batterietemperatur", "Temperatura de la batería", "Temperatura della batteria", "Temperatura da bateria")
        add(.labelBiometricAuth, "生物认证", "生物認證", "Authentication", "認証", "생체 인증",
            "Authentification", "Authentifizierung", "Autenticación", "Autenticazione", "Autenticação")
        add(.labelBrokenOrInvalid, "已失效", "已失效", "Invalid", "無効", "유효하지 않음",
            "Invalide", "Ungültig", "Inválido", "Non valido", "Inválido")
        add(.labelBundleIdentifier, "标识", "識別碼", "Bundle Identifier", "バンドル識別子", "번들 식별자",
            "Identifiant de lot", "Bundle-ID", "Identificador de paquete", "Identificatore bundle", "Identificador do Pacote")
        add(.labelChargeDischargeWatts, "充放电功率", "充放電功率", "Charge/Discharge Power", "充放電電力", "충방전 전력",
            "Puissance de charge/décharge", "Lade-/Entladeleistung", "Potencia de carga/descarga", "Potenza di carica/scarica", "Potência de carga/descarga")
        add(.labelChargerSpecs, "电源适配器", "電源轉接器", "Power Adapter", "電源アダプタ", "전원 어댑터",
            "Adaptateur d'alimentation", "Netzteil", "Adaptador de corriente", "Alimentatore", "Adaptador de energia")
    }

    static func populateBatch6(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.labelCompressed, "已压缩", "已壓縮", "Compressed", "圧縮済み", "압축됨",
            "Compressée", "Komprimiert", "Comprimida", "Compressa", "Compactada")
        add(.labelConfigFile, "配置文件", "設定檔案", "Configuration File", "設定ファイル", "구성 파일",
            "Fichier de configuration", "Konfigurationsdatei", "Archivo de configuración", "File di configurazione", "Arquivo de Configuração")
        add(.labelConfigure, "配置", "配置", "Configure", "設定", "구성",
            "Configurer", "Konfigurieren", "Configurar", "Configura", "Configurar")
        add(.labelConnectionStatus, "连接状态", "連接狀態", "Connection Status", "接続状態", "연결 상태",
            "État de la connexion", "Verbindungsstatus", "Estado de conexión", "Stato connessione", "Status da conexão")
        add(.labelData, "数据", "數據", "Data", "データ", "데이터",
            "Données", "Daten", "Datos", "Dati", "Dados")
        add(.labelDescription, "说明", "說明", "Description", "説明", "설명",
            "Description", "Beschreibung", "Descripción", "Descrizione", "Descrição")
        add(.labelDisplayDataFormat, "显示数据格式：", "顯示資料格式：", "Data Format:", "表示形式：", "표시 형식:",
            "Format d'affichage :", "Datenformat:", "Formato de datos:", "Formato dati:", "Formato de Exibição:")
        add(.labelEmpty, "空", "空", "Empty", "空", "비어 있음",
            "Vide", "Leer", "Vacío", "Vuoto", "Vazio")
        add(.labelFileCache, "文件缓存", "文件緩存", "File Cache", "ファイルキャッシュ", "파일 캐시",
            "Cache de fichiers", "Dateicache", "Caché de archivos", "Cache di file", "Cache de arquivos")
        add(.labelFreeAvailable, "可用", "可用", "Available", "空き", "사용 가능",
            "Disponible", "Verfügbar", "Disponible", "Disponibile", "Disponível")
        add(.labelFreeMemoryAvailable, "空闲可用", "空閒可用", "Free / Available", "空き / 利用可能", "여유 / 사용 가능",
            "Libre / Disponible", "Frei / Verfügbar", "Libre / Disponible", "Libera / Disponibile", "Livre / Disponível")
        add(.labelGeographicEgress, "地理出口", "地理出口", "Geographic Egress", "地理的出口", "지리적 출구 위치",
            "Sortie géographique", "Geografischer Ausgang", "Salida geográfica", "Uscita geografica", "Saída geográfica")
        add(.labelInstallDate, "安装日期", "安裝日期", "Install Date", "インストール日", "설치 날짜",
            "Date d'installation", "Installationsdatum", "Fecha de instalación", "Data di installazione", "Data de Instalação")
        add(.labelInternetServiceProvider, "网络运营商 (ISP)", "網絡運營商 (ISP)", "ISP", "インターネットプロバイダ (ISP)", "인터넷 서비스 제공자 (ISP)",
            "Fournisseur d'accès (FAI)", "Internetanbieter (ISP)", "Proveedor de Internet (ISP)", "Provider di servizi Internet (ISP)", "Provedor de Internet (ISP)")
        add(.labelIpGeolocation, "IP定位", "IP定位", "IP Geolocation", "IP 位置情報", "IP 위치 확인",
            "Géolocalisation IP", "IP-Standort", "Geolocalización por IP", "Geolocalizzazione IP", "Geolocalização por IP")
        add(.labelKeepAwakeAntiSleep, "常亮防休眠", "常亮防休眠", "Keep Awake", "常時覚醒（スリープ防止）", "항상 켜짐 (잠자기 방지)",
            "Maintenir éveillé", "Wachhalten", "Mantener encendido", "Mantieni attivo", "Manter acordado")
        add(.labelKeepOriginalRecommended, "建议保留原件", "建議保留原件", "Keep Original Recommended", "オリジナルの保持を推奨", "원본 유지 권장",
            "Conservation de l'original recommandée", "Original behalten empfohlen", "Se recomienda conservar el original", "Conserva l'originale consigliato", "Recomenda-se manter o original")
        add(.labelLastOpened, "最后使用", "最後使用", "Last Opened", "最終使用日", "마지막 사용",
            "Dernière ouverture", "Zuletzt geöffnet", "Abierto por última vez", "Ultima apertura", "Última Utilização")
        add(.labelLeftFan, "左侧风扇 (Left)", "左側風扇 (Left)", "Left Fan", "左側ファン", "왼쪽 팬",
            "Ventilateur gauche", "Linker Lüfter", "Ventilador izquierdo", "Ventola sinistra", "Ventoinha esquerda")
        add(.labelLinked, "联动", "聯動", "Linked", "連動", "연동",
            "Lié", "Verknüpft", "Vinculado", "Collegato", "Vinculado")
        add(.labelLocalHostIpv4, "本机 IPv4", "本機 IPv4", "Local IPv4", "ローカル IPv4", "로컬 IPv4",
            "IPv4 locale", "Lokale IPv4", "IPv4 local", "IPv4 locale", "IPv4 local")
        add(.labelLocalHostIpv6, "局域网 IPv6", "局域網 IPv6", "Local IPv6", "ローカル IPv6", "로컬 IPv6",
            "IPv6 locale", "Lokale IPv6", "IPv6 local", "IPv6 locale", "IPv6 local")
        add(.labelLocalModels, "本地模型", "本地模型", "Local Models", "ローカルモデル", "로컬 모델",
            "Modèles locaux", "Lokale Modelle", "Modelos locales", "Modelli locali", "Modelos locais")
        add(.labelName, "名称", "名稱", "Name", "名前", "이름",
            "Nom", "Name", "Nombre", "Nome", "Nome")
        add(.labelNetworkDownloadRx, "下行下载 (RX)", "下行下載 (RX)", "Download (RX)", "ダウンロード (RX)", "다운로드 (RX)",
            "Téléchargement (RX)", "Download (RX)", "Descarga (RX)", "Download (RX)", "Download (RX)")
        add(.labelNetworkUploadTx, "上行上传 (TX)", "上行上傳 (TX)", "Upload (TX)", "アップロード (TX)", "업로드 (TX)",
            "Téléversement (TX)", "Upload (TX)", "Subida (TX)", "Upload (TX)", "Upload (TX)")
        add(.labelPageIns, "换入 (Page Ins):", "換入 (Page Ins):", "Page Ins:", "ページイン:", "페이지 인 (Page Ins):",
            "Entrées de pages :", "Page Ins:", "Entradas de página:", "Pagine in entrata:", "Entradas de página:")
        add(.labelPageOuts, "换出 (Page Outs):", "換出 (Page Outs):", "Page Outs:", "ページアウト:", "페이지 아웃 (Page Outs):",
            "Sorties de pages :", "Page Outs:", "Salidas de página:", "Pagine in uscita:", "Saídas de página:")
        add(.labelPermission, "权限", "權限", "Permission", "権限", "권한",
            "Autorisation", "Berechtigung", "Permiso", "Permesso", "Permissão")
        add(.labelPhysicalMemory, "物理内存", "實體記憶體", "Physical Memory", "物理メモリ", "물리적 메모리",
            "Mémoire physique", "Physischer Speicher", "Memoria física", "Memoria fisica", "Memória física")
        add(.labelPowerAdapterRating, "充电器规格", "充電器規格", "Adapter Rating", "充電器の定格", "충전기 사양",
            "Adaptateur secteur", "Netzteil-Spezifikation", "Especificación del adaptador", "Specifiche alimentatore", "Especificação do adaptador")
        add(.labelPowerBusVoltage, "电源总线电压", "電源總線電壓", "Bus Voltage", "電源バス電圧", "전원 버스 전압",
            "Tension du bus", "Bus-Spannung", "Voltaje del bus", "Tensione del bus", "Tensão do barramento")
        add(.labelPressure, "压力", "壓力", "Pressure", "プレッシャー", "압박도",
            "Pression", "Druck", "Presión", "Pressione", "Pressão")
        add(.labelPreventSleep, "防休眠", "防休眠", "Prevent Sleep", "スリープ防止", "잠자기 방지",
            "Empêcher la mise en veille", "Ruhezustand verhindern", "Evitar reposo", "Impedisci stop", "Impedir repouso")
        add(.labelPreventSleepTooltipDesc, "防止系统在锁屏或长时间待机时自动休眠", "防止系統在鎖屏或長時間待機時自動休眠", "Prevent Mac from going to sleep on lock screen or idle", "ロック画面や待機中の自動スリープを防止", "화면 잠금 또는 대기 시 시스템이 자동 잠자기에 들어가는 것을 방지",
            "Empêcher le Mac de se mettre en veille en cas d'inactivité", "Verhindert den automatischen Ruhezustand bei Inaktivität", "Evita que el Mac entre en reposo por inactividad", "Impedisce al Mac di andare in stop durante l'inattività", "Impede que o Mac entre em repouso durante a inatividade")
        add(.labelProcessorCoreTemperature, "核心温度", "核心溫度", "Core Temperature", "コア温度", "코어 온도",
            "Température des cœurs", "Kerntemperatur", "Temperatura del núcleo", "Temperatura dei core", "Temperatura dos núcleos")
        add(.labelProgram, "程序", "程式", "Program", "プログラム", "프로그램",
            "Programme", "Programm", "Programa", "Programma", "Programa")
        add(.labelPublicIpAddress, "公网 IP 地址", "公網 IP 地址", "Public IP Address", "パブリック IP アドレス", "공인 IP 주소",
            "Adresse IP publique", "Öffentliche IP-Adresse", "Dirección IP pública", "Indirizzo IP pubblico", "Endereço IP público")
        add(.labelRequiresAdminPrivileges, "需管理员权限", "需管理員權限", "Admin Privileges Required", "管理者権限が必要", "관리자 권한 필요",
            "Privilèges administrateur requis", "Administratorrechte erforderlich", "Se requieren privilegios de administrador", "Richiesti privilegi di amministratore", "Requer privilégios de administrador")
        add(.labelRightFan, "右侧风扇 (Right)", "右側風扇 (Right)", "Right Fan", "右側ファン", "오른쪽 팬",
            "Ventilateur droit", "Rechter Lüfter", "Ventilador derecho", "Ventola destra", "Ventoinha direita")
        add(.labelScanResults, "扫描结果", "掃描結果", "Scan Results", "スキャン結果", "검사 결과",
            "Résultats de l'analyse", "Scanergebnisse", "Resultados del escaneo", "Risultati della scansione", "Resultados da verificação")
        add(.labelScope, "作用域", "作用域", "Scope", "スコープ", "범위",
            "Portée", "Bereich", "Ámbito", "Ambito", "Escopo")
        add(.labelSeamlessContinue, "无感继续", "無感繼續", "Seamless Continue", "自動継続", "자동 계속",
            "Continuer automatiquement", "Nahtlos fortsetzen", "Continuar automáticamente", "Continua automaticamente", "Continuar automaticamente")
        add(.labelSelected, "已选", "已選", "Selected", "選択済み", "선택됨",
            "Sélectionné", "Ausgewählt", "Seleccionado", "Selezionato", "Selecionado")
        add(.labelSelectionPrefix, "选择:", "選擇:", "Select:", "選択:", "선택:",
            "Sélectionner :", "Auswählen:", "Seleccionar:", "Seleziona:", "Selecionar:")
        add(.labelSize, "大小", "大小", "Size", "サイズ", "크기",
            "Taille", "Größe", "Tamaño", "Dimensione", "Tamanho")
        add(.labelSource, "来源", "來源", "Source", "入手元", "출처",
            "Source", "Quelle", "Fuente", "Origine", "Origem")
        add(.labelStatus, "状态", "狀態", "Status", "状態", "상태",
            "État", "Status", "Estado", "Stato", "Status")
        add(.labelSwapPartition, "Swap 交换分区:", "Swap 交換分區:", "Swap Used:", "スワップ使用量:", "스왑 파티션:",
            "Swap utilisé :", "Swap belegt:", "Swap usado:", "Swap usato:", "Swap usado:")
        add(.labelSystemNetworkProxy, "系统代理", "系統代理", "System Proxy", "システムプロキシ", "시스템 프록시",
            "Proxy système", "System-Proxy", "Proxy del sistema", "Proxy di sistema", "Proxy do sistema")
        add(.labelThermalControl, "温控", "溫控", "Thermals", "温度管理", "온도 제어",
            "Thermique", "Kühlung", "Térmico", "Termica", "Térmico")
        add(.labelThreshold, "阈值", "閾值", "Threshold", "しきい値", "기준 임계값",
            "Seuil", "Schwellenwert", "Umbral", "Soglia", "Limite")
        add(.labelTopEnergyUsage, "耗电最多", "耗電最多", "Top Energy Usage", "最大エネルギー消費", "최대 전력 소모",
            "Consommation d'énergie la plus élevée", "Höchster Energieverbrauch", "Mayor consumo de energía", "Consumo energetico maggiore", "Maior consumo de energia")
        add(.labelTotalSystemPower, "整机功耗", "整機功耗", "System Power", "システム総消費電力", "전체 시스템 소비 전력",
            "Puissance du système", "Gesamtsystemleistung", "Potencia total del sistema", "Potenza totale del sistema", "Potência total do sistema")
        add(.labelUpdateChannel, "更新通道", "更新通道", "Update Channel", "アップデートチャネル", "업데이트 채널",
            "Canal de mise à jour", "Update-Kanal", "Canal de actualización", "Canale di aggiornamento", "Canal de Atualização")
        add(.labelUptimePrefix, "已运行", "已運行", "Uptime", "稼働時間", "가동 시간",
            "Temps de fonctionnement", "Betriebszeit", "Tiempo activo", "Tempo di attività", "Tempo de atividade")
        add(.labelUsed, "已用", "已用", "Used", "使用済み", "사용됨",
            "Utilisé", "Verwendet", "Usado", "Usato", "Usado")
        add(.labelVendor, "经销商", "經銷商", "Developer / Vendor", "開発元 / 販売元", "개발사 / 공급업체",
            "Développeur", "Entwickler", "Desarrollador / Proveedor", "Sviluppatore / Fornitore", "Desenvolvedor / Fornecedor")
        add(.labelVersion, "版本", "版本", "Version", "バージョン", "버전",
            "Version", "Version", "Versión", "Versione", "Versão")
        add(.lanPrefix, "局域网", "區域網路", "LAN", "LAN", "LAN",
            "Réseau local", "Lokales Netzwerk", "Red local", "Rete locale", "Rede local")
        add(.largeAndOldFilesDesc, "体积较大或超过一年未使用的文件。", "體積較大或超過一年未使用的檔案。", "Large files or files unused for over a year.", "大容量ファイル、または1年以上開かれていないファイル。", "용량이 크거나 1년 이상 사용하지 않은 파일입니다.",
            "Fichiers volumineux ou inutilisés depuis plus d'un an.", "Große Dateien oder Dateien, die seit über einem Jahr unbenutzt sind.", "Archivos grandes o sin usar durante más de un año.", "File di grandi dimensioni o non utilizzati da oltre un anno.", "Arquivos grandes ou não usados há mais de um ano.")
        add(.largeOrLongUnopenedFilesConfirmTheyAreNoLongerNeededBeforeCleaning, "占用空间较大或长期未打开的个人文件，请确认不再需要后再清理", "佔用空間較大或長期未打開的個人檔案，請確認不再需要後再清理", "Large or long-unopened files; confirm they are no longer needed before cleaning", "大容量または長期間開かれていないファイル。不要であることを確認の上で削除してください", "용량이 크거나 장기간 열지 않은 파일. 더 이상 필요하지 않은지 확인 후 정리하세요",
            "Fichiers volumineux ou non ouverts depuis longtemps ; confirmez avant nettoyage", "Große oder lange ungeöffnete Dateien; vor dem Löschen prüfen", "Archivos grandes o sin abrir durante mucho tiempo; revisa antes de borrarlos", "File grandi o non aperti da molto tempo; verifica che non siano più necessari prima di pulire", "Arquivos grandes ou sem uso há muito tempo; confirme se não são mais necessários antes de limpar")
        add(.largeOrYearUnusedFilesDesc, "体积较大或超过一年未使用的文件。", "體積較大或超過一年未使用的檔案。", "Large files or items unused for more than a year.", "大容量または1年以上開かれていないファイル。", "용량이 크거나 1년 이상 사용되지 않은 파일입니다.",
            "Fichiers volumineux ou inutilisés depuis plus d'un an.", "Große Dateien oder Dateien, die seit über einem Jahr nicht genutzt wurden.", "Archivos grandes o sin abrir durante más de un año.", "File grandi o non utilizzati da oltre un anno.", "Arquivos grandes ou não utilizados há mais de um ano.")
        add(.latencyPrefix, "延迟", "延遲", "Latency", "レイテンシ", "지연 시간",
            "Latence", "Latenz", "Latencia", "Latenza", "Latência")
        add(.launchDaemonsAndBackgroundAutoUpdateConfigurations, "开机自启守护进程与后台更新驻留配置", "開機自啓守護處理程序與後台更新駐留配置", "Launch daemons and background auto-update configurations", "起動時自動実行デーモンおよびバックグラウンド更新設定", "시작 시 자동 실행 데몬 및 백그라운드 업데이트 설정",
            "Démons d’arrière-plan au démarrage et réglages de mise à jour automatique", "Autostart-Daemons und Hintergrund-Update-Konfigurationen", "Demonios de inicio automático y ajustes de actualización en segundo plano", "Daemon di avvio automatico e impostazioni di aggiornamento in background", "Daemons de inicialização automática e configurações de atualização em segundo plano")
        add(.leftoverDmgAndPkgInstallersAfterSetupCleaningDoesNotAffectInstalledApps, "应用安装完成后遗留的 .dmg、.pkg 镜像与安装包，清理不影响已装 App", "應用安裝完成後遺留的 .dmg、.pkg 鏡像與安裝檔，清理不影響已裝 App", "Leftover .dmg and .pkg installers after setup; cleaning does not affect installed apps", "インストール完了後の .dmg / .pkg イメージ。削除しても導入済みアプリには影響しません", "설치 완료 후 남겨진 .dmg, .pkg 이미지 및 설치 파일. 정리해도 설치된 앱에 영향 없음",
            "Images .dmg et .pkg résiduelles après installation ; la suppression n’affecte pas les apps installées", "Nach der Installation verbliebene .dmg- und .pkg-Images; Löschen berührt installierte Apps nicht", "Instaladores .dmg y .pkg residuales; borrarlos no afecta a las apps instaladas", "Immagini .dmg e .pkg rimaste dopo l’installazione; la pulizia non influisce sulle app installate", "Imagens .dmg e .pkg residuais após a instalação; a limpeza não afeta os apps instalados")
        add(.levelDangerous, "高危级 (Dangerous)", "高危級 (Dangerous)", "High-Risk Level (Dangerous)", "高リスクレベル (Dangerous)", "고위험 등급 (Dangerous)",
            "Niveau risque élevé (Dangerous)", "Hochrisikostufe (Dangerous)", "Nivel de alto riesgo (Dangerous)", "Livello ad alto rischio (Dangerous)", "Nível de alto risco (Dangerous)")
        add(.levelPrompt, "提示级 (Prompt)", "提示級 (Prompt)", "Prompt Level (Prompt)", "確認レベル (Prompt)", "확인 필요 등급 (Prompt)",
            "Niveau confirmation (Prompt)", "Bestätigungsstufe (Prompt)", "Nivel de confirmación (Prompt)", "Livello di conferma (Prompt)", "Nível de confirmação (Prompt)")
        add(.levelSafe, "安全级 (Safe)", "安全級 (Safe)", "Safe Level (Safe)", "安全レベル (Safe)", "안전 등급 (Safe)",
            "Niveau sûr (Safe)", "Sicherheitsstufe (Safe)", "Nivel seguro (Safe)", "Livello sicuro (Safe)", "Nível seguro (Safe)")
        add(.light, "浅色", "淺色", "Light", "ライト", "라이트",
            "Clair", "Hell", "Claro", "Chiaro", "Claro")
        add(.lightMode, "浅色模式", "淺色模式", "Light Mode", "ライトモード", "라이트 모드",
            "Mode clair", "Hellmodus", "Modo claro", "Modalità chiara", "Modo Claro")
        add(.liveMonitorHeroSubtitle, "实时监控 CPU、GPU、内存、电池、磁盘 I/O、网络与活跃进程", "實時監控 CPU、GPU、內存、電池、磁盤 I/O、網絡與活躍進程", "Real-time monitoring of CPU, GPU, memory, battery, disk I/O, network, and active processes", "CPU、GPU、メモリ、バッテリー、ディスク I/O、ネットワーク、アクティブプロセスのリアルタイム監視", "CPU, GPU, 메모리, 배터리, 디스크 I/O, 네트워크 및 실행 중인 프로세스 실시간 모니터링",
            "Surveillance en temps réel du CPU, GPU, mémoire, batterie, E/S disque, réseau et processus", "Echtzeit-Überwachung von CPU, GPU, Speicher, Batterie, Festplatten-I/O, Netzwerk und Prozessen", "Monitoreo en tiempo real de CPU, GPU, memoria, batería, E/S de disco, red y procesos activos", "Monitoraggio in tempo reale di CPU, GPU, memoria, batteria, I/O disco, rete e processi attivi", "Monitoramento em tempo real de CPU, GPU, memória, bateria, E/S de disco, rede e processos ativos")
        add(.liveMonitorModuleDesc, "查看 CPU、内存、磁盘 I/O、网络流量与 Top 进程", "查看 CPU、內存、磁盤 I/O、網絡流量與 Top 進程", "Inspect CPU, memory, disk I/O, network traffic, and top processes", "CPU、メモリ、ディスク I/O、ネットワークトラフィック、高負荷プロセスを確認", "CPU, 메모리, 디스크 I/O, 네트워크 트래픽 및 상위 프로세스 확인",
            "Inspectez le CPU, la mémoire, les E/S disque, le trafic réseau et les processus clés", "Prüfen Sie CPU, RAM, Festplatten-I/O, Netzwerkverkehr und Top-Prozesse", "Inspeccione CPU, memoria, E/S de disco, tráfico de red y procesos principales", "Controlla CPU, memoria, I/O disco, traffico di rete e processi principali", "Inspecione CPU, memória, E/S de disco, tráfego de rede e processos principais")
        add(.liveMonitorModuleSummary, "CPU / 内存 / 磁盘 / 网络 / 进程监控", "CPU / 內存 / 磁盤 / 網絡 / 進程監控", "CPU / Memory / Disk / Network / Process Monitoring", "CPU / メモリ / ディスク / ネットワーク / プロセス監視", "CPU / 메모리 / 디스크 / 네트워크 / 프로세스 모니터링",
            "Surveillance CPU / Mémoire / Disque / Réseau / Processus", "CPU / Arbeitsspeicher / Festplatte / Netzwerk / Prozess-Monitoring", "Monitoreo de CPU / Memoria / Disco / Red / Procesos", "Monitoraggio CPU / Memoria / Disco / Rete / Processi", "Monitoramento de CPU / Memória / Disco / Rede / Processos")
        add(.livePowerFormat, "实时功率 %.1f W", "即時功率 %.1f W", "Real-time Power: %.1f W", "リアルタイム電力: %.1f W", "실시간 전력: %.1f W",
            "Puissance en temps réel : %.1f W", "Echtzeitleistung: %.1f W", "Potencia en tiempo real: %.1f W", "Potenza in tempo reale: %.1f W", "Potência em tempo real: %.1f W")
        add(.liveThroughputRate, "实时吞吐率", "即時輸送量", "Throughput Rate", "リアルタイム通信レート", "실시간 전송률",
            "Débit en temps réel", "Echtzeit-Durchsatz", "Tasa de rendimiento", "Velocità effettiva", "Taxa de transferência")
        add(.localIPv4, "局域网 IPv4", "局域網 IPv4", "Local IPv4", "ローカル IPv4", "로컬 IPv4",
            "IPv4 locale", "Lokale IPv4", "IPv4 local", "IPv4 locale", "IPv4 local")
        add(.localIp, "局域网 IP", "局域網 IP", "Local IP", "ローカル IP", "로컬 IP",
            "IP locale", "Lokale IP", "IP local", "IP locale", "IP Local")
        add(.locating, "定位中…", "定位中…", "Locating…", "測位中…", "위치 확인 중…",
            "Localisation en cours…", "Standort wird ermittelt…", "Localizando…", "Localizzazione in corso…", "Localizando…")
        add(.loginHelperItem, "登录辅助项", "登入輔助項", "Login Helper", "ログイン補助項目", "로그인 도우미",
            "Assistant d’ouverture", "Anmelde-Helper", "Auxiliar de inicio", "Helper di login", "Auxiliar de login")
        add(.loginItem, "登录项", "登入項目", "Login Item", "ログイン項目", "로그인 항목",
            "Ouverture", "Anmeldeobjekt", "Ítem de inicio", "Elemento login", "Item de Início")
        add(.loginItems, "开机启动项", "開機啟動項", "Login Items", "ログイン項目", "로그인 항목",
            "Ouverture au démarrage", "Anmeldeobjekte", "Ítems de inicio", "Elementi login", "Itens de Início")
        add(.loginItemsAndBackgroundDaemons, "登录项与后台守护进程", "登錄項與後台守護處理程序", "Login Items & Background Daemons", "ログイン項目と常駐デーモン", "로그인 항목 및 백그라운드 데몬",
            "Ouverture de session et démons d’arrière-plan", "Anmeldeobjekte & Hintergrund-Daemons", "Elementos de inicio y demonios en segundo plano", "Elementi di avvio e daemon in background", "Itens de Inicialização e Daemons em Segundo Plano")
        add(.lookingForJunkFiles, "正在查找垃圾文件……", "正在尋找垃圾檔案……", "Looking for junk files…", "不要ファイルを検索中…", "정크 파일 찾는 중…",
            "Recherche des fichiers inutiles…", "Suche nach Systemmüll…", "Buscando archivos basura…", "Ricerca file inutili in corso…", "Procurando arquivos desnecessários…")
        add(.lowLatency, "低延迟", "低延遲", "Low Latency", "低遅延", "저지연",
            "Faible latence", "Niedrige Latenz", "Baja latencia", "Bassa latenza", "Baixa Latência")
        add(.lowLatencyOn, "低延迟已开", "低延遲已開啟", "Low Latency On", "低遅延オン", "저지연 켜짐",
            "Faible latence activée", "Niedrige Latenz ein", "Baja latencia activa", "Bassa latenza attiva", "Baixa Latência Ativa")
        add(.macInGoodConditionPrompt, "您的 Mac 电脑状态良好，没有需要处理的项目。", "您的 Mac 電腦狀態良好，沒有需要處理的項目。", "Your Mac is in good shape. No items need attention.", "お使いの Mac は良好な状態です。対処が必要な項目はありません。", "Mac이 양호한 상태입니다. 처리할 항목이 없습니다.",
            "Votre Mac est en parfait état. Aucun élément à traiter.", "Ihr Mac ist in hervorragendem Zustand. Keine Aktionen erforderlich.", "Su Mac está en buen estado. No hay elementos que requieran atención.", "Il tuo Mac è in buone condizioni. Nessun elemento richiede attenzione.", "Seu Mac está em ótimo estado. Nenhum item precisa de atenção.")
        add(.macosBackgroundSilentHealthCheckAndAutoMaintenance, "macOS 后台静默健康巡检与自动维护", "macOS 後台靜默健康巡檢與自動維護", "macOS background silent health check and auto maintenance", "macOS バックグラウンド自動ヘルスチェックと保守", "macOS 백그라운드 무소음 상태 점검 및 자동 유지보수",
            "Vérification silencieuse de l’état et maintenance automatique de macOS", "macOS automatische Hintergrund-Wartung und Integritätsprüfung", "Comprobación silenciosa de estado y mantenimiento automático de macOS", "Controllo silenzioso dello stato e manutenzione automatica di macOS", "Verificação silenciosa de integridade e manutenção automática do macOS")
        add(.macosCoreAudioDriverServiceCoreaudiod, "macOS 系统核心音频驱动服务", "macOS 系統核心音訊驅動服務", "macOS core audio driver service (coreaudiod)", "macOS コアオーディオドライバサービス (coreaudiod)", "macOS 핵심 오디오 드라이버 서비스 (coreaudiod)",
            "Service de pilote audio principal de macOS (coreaudiod)", "macOS Core-Audio-Treiberdienst (coreaudiod)", "Servicio del controlador de audio central de macOS (coreaudiod)", "Servizio driver audio principale di macOS (coreaudiod)", "Serviço de driver de áudio principal do macOS (coreaudiod)")
        add(.macosDarwinPerUserTemporaryAndShaderorcompilationCachesSafeToRemove, "macOS Darwin 系统级应用临时缓存与着色器/编译缓存（可安全清理）", "macOS Darwin 系統級應用暫存快取與著色器/編譯快取（可安全清理）", "macOS Darwin per-user temporary and shader/compilation caches (safe to remove)", "macOS Darwinシステム一時キャッシュ・シェーダーキャッシュ（安全に削除可能）", "macOS Darwin 시스템 임시 및 셰이더/컴파일 캐시 (안전하게 삭제 가능)",
            "Caches temporaires Darwin et shaders (suppression sûre)", "macOS Darwin temporäre & Shader-Caches (sicher löschbar)", "Cachés temporales Darwin y de sombreadores (seguro de eliminar)", "Cache temporanee Darwin e shader (rimozione sicura)", "Caches temporários Darwin e de shaders (seguro remover)")
        add(.macosKeepsALocalCacheOfResolvedDnsQueriesForAWhileButSometimesYouNeedToResetItImmediatelySuchAsAfterServerChangesOrNewDomainRecords, "macOS 会将解析的 DNS（域名系统）查询的本地缓存保留一段时间，但是有时候可能需要立即重置缓存。例如，服务器上的某个项目发生了更改或者添加了新项目后您可能需要进行重置。", "macOS 會將解析的 DNS（域名系統）查詢的本地快取保留一段時間，但是有時候可能需要立即重置快取。例如，服務器上的某個項目發生了更改或者添加了新項目後您可能需要進行重置。", "macOS keeps a local cache of resolved DNS queries for a while, but sometimes you need to reset it immediately, such as after server changes or new domain records.", "macOS は名前解決した DNS クエリのローカルキャッシュを一定期間保持しますが、サーバー側の変更などでキャッシュの即時リセットが必要になることがあります。", "macOS는 확인된 DNS 쿼리의 로컬 캐시를 일정 시간 유지하지만, 서버 변경이나 새 항목 추가 시 즉시 캐시를 초기화해야 할 수 있습니다.",
            "macOS conserve le cache local des requêtes DNS résolues pendant un certain temps, mais une réinitialisation immédiate est parfois nécessaire.", "macOS speichert aufgelöste DNS-Abfragen vorübergehend lokal, manchmal muss dieser Cache jedoch sofort zurückgesetzt werden.", "macOS guarda una caché local de consultas DNS resueltas, pero a veces es necesario restablecerla de inmediato tras cambios en servidores.", "macOS mantiene una cache locale delle query DNS risolte, ma a volte è necessario reimpostarla subito dopo modifiche ai server.", "O macOS mantém um cache local de consultas DNS resolvidas, mas às vezes é necessário redefini-lo imediatamente após alterações no servidor.")
        add(.macosKernelAndThermalManagementTasks, "macOS 系统内核与温控调度任务", "macOS 系統內核與溫控調度任務", "macOS kernel and thermal management tasks", "macOS カーネルおよび熱管理タスク", "macOS 시스템 커널 및 온도 제어 스케줄링 작업",
            "Tâches du noyau macOS et de régulation thermique", "macOS Kernel- und Temperatursteuerungsaufgaben", "Tareas del kernel y gestión térmica de macOS", "Attività del kernel macOS e gestione termica", "Tarefas do kernel do macOS e gerenciamento térmico")
        add(.macosMarksSpaceAsPurgeableWhenItCanBeSafelyReclaimedIfMoreStorageIsNeededThisIncludesTemporaryCachesAndFilesThatCanBeRedownloadedOrRecreatedWithoutAffectingCriticalData, "macOS 将可清理空间识别为在需要更多存储空间时可以安全移除的数据。这通常包括缓存文件、临时文件以及可以重新下载或重新创建的文件。删除这些文件不会影响关键文件或应用程序的正常运行。", "macOS 將可清理空間識別為在需要更多存儲空間時可以安全移除的資料。這通常包括快取檔案、暫存檔案以及可以重新下載或重新創建的檔案。刪除這些檔案不會影響關鍵檔案或應用程式的正常執行。", "macOS marks space as purgeable when it can be safely reclaimed if more storage is needed. This includes temporary caches and files that can be redownloaded or recreated without affecting critical data.", "macOS は、容量が必要な際に安全に削除できるデータをパージ可能領域として扱います。これには再ダウンロード可能な一時キャッシュなどが含まれ、通常動作に影響はありません。", "macOS는 더 많은 저장 공간이 필요할 때 안전하게 삭제할 수 있는 데이터를 확보 가능 공간으로 식별합니다. 캐시 및 재생성 가능한 파일이 포함되며 중요 파일에는 영향을 주지 않습니다.",
            "macOS considère comme purgeable les données pouvant être supprimées en toute sécurité si plus d’espace est requis, sans impacter vos applications.", "macOS kennzeichnet Daten als freigebbar, die bei Speicherbedarf sicher entfernt und später automatisch neu erstellt werden können.", "macOS marca como purgable el espacio que puede eliminarse de forma segura si se necesita almacenamiento, sin afectar al funcionamiento del sistema.", "macOS contrassegna lo spazio come eliminabile quando può essere recuperato in sicurezza in caso di necessità, senza intaccare i file critici.", "O macOS identifica como purgável o espaço que pode ser recuperado com segurança quando necessário, sem afetar arquivos essenciais ou apps.")
        add(.macosSandboxContainerIncludesSettingsCachesAndPrivateData, "macOS 沙盒隔离容器（含沙盒内应用配置、缓存与私有数据）", "macOS 沙盒隔離容器（含沙盒內應用配置、快取與私有資料）", "macOS sandbox container (includes settings, caches, and private data)", "macOS サンドボックス隔離コンテナ（設定、キャッシュ、プライベートデータを含む）", "macOS 샌드박스 격리 컨테이너 (앱 설정, 캐시 및 비공개 데이터 포함)",
            "Conteneur sandbox isolé de macOS (inclut réglages, caches et données privées)", "macOS Sandbox-Container (enthält Einstellungen, Caches und private Daten)", "Contenedor de sandbox aislado de macOS (incluye ajustes, cachés y datos privados)", "Container sandbox isolato di macOS (include impostazioni, cache e dati privati)", "Contêiner sandbox isolado do macOS (inclui configurações, caches e dados privados)")
        add(.macosSystemCrashReportsDiagnosticsAndTemporaryFiles, "macOS 系统崩溃日志、分析上报与系统级临时文件", "macOS 系統當機日誌、分析上報與系統級暫存檔案", "macOS system crash reports, diagnostics, and temporary files", "macOS クラッシュログ、診断レポート、システム一時ファイル", "macOS 시스템 충돌 로그, 분석 보고서 및 시스템 수준 임시 파일",
            "Rapports de plantage système macOS, diagnostics et fichiers temporaires", "macOS System-Absturzberichte, Diagnosen und temporäre Systemdateien", "Informes de fallos del sistema macOS, diagnósticos y archivos temporales", "Rapporti di arresto anomalo di sistema macOS, diagnostica e file temporanei", "Relatórios de falhas do sistema macOS, diagnósticos e arquivos temporários")
        add(.macosSystemLevelBackgroundDaemonService, "macOS 系统级后台守护服务", "macOS 系統級後台守護服務", "macOS system-level background daemon service", "macOS システムレベルの常駐デーモンサービス", "macOS 시스템 수준 백그라운드 데몬 서비스",
            "Service démon système en arrière-plan de macOS", "macOS systemweiter Hintergrund-Daemondienst", "Servicio demonio de segundo plano a nivel de sistema macOS", "Servizio daemon di sistema in background di macOS", "Serviço daemon em segundo plano no nível do sistema macOS")
        add(.macosSystemRuntimeTemporaryCachesAndShaderBuffers, "macOS 系统级运行时临时缓存与着色器缓冲", "macOS 系統級執行時暫存快取與著色器緩衝", "macOS system runtime temporary caches and shader buffers", "macOS システム実行時の一時キャッシュおよびシェーダーバッファ", "macOS 시스템 런타임 임시 캐시 및 셰이더 버퍼",
            "Caches temporaires et tampons de shaders du système macOS", "macOS System-Laufzeit-Temporärcaches und Shader-Puffer", "Cachés temporales y búferes de sombreadores del sistema macOS", "Cache temporanee e buffer shader a livello di sistema macOS", "Caches temporários e buffers de sombreadores do sistema macOS")
        add(.macosSystemSecurityAndPermissionChecks, "macOS 系统安全与访问权限检测", "macOS 系統安全與訪問權限檢測", "macOS system security and permission checks", "macOS システムセキュリティおよびアクセス権限チェック", "macOS 시스템 보안 및 접근 권한 점검",
            "Vérification de sécurité et des autorisations de macOS", "macOS Systemsicherheit und Zugriffsrechteprüfung", "Comprobación de seguridad y permisos de acceso de macOS", "Controllo di sicurezza e permessi di accesso di macOS", "Verificação de segurança e permissões de acesso do macOS")
        add(.macosTopMenuBarAndCompanionDropdownConsole, "macOS 顶部状态栏与下拉控制台伴侣", "macOS 頂部狀態欄與下拉控制台伴侶", "macOS top menu bar & companion dropdown console", "macOS メニューバー常駐およびドロップダウンコンソール", "macOS 상단 메뉴 막대 및 드롭다운 콘솔 동반자",
            "Barre des menus supérieure macOS et console compagnon", "macOS Menüleiste & Begleiter-Dropdown-Konsole", "Barra de menús superior de macOS y panel desplegable", "Barra dei menu superiore di macOS e console a comparsa", "Barra de menus superior do macOS e console suspenso")
        add(.macosWindowserverCompositorCoreDisplayProcess, "macOS 图形窗口合成服务（核心显示进程）", "macOS 圖形窗口合成服務（核心顯示處理程序）", "macOS WindowServer compositor (core display process)", "macOS WindowServer ウィンドウ合成サービス（画面表示コアプロセス）", "macOS WindowServer 그래픽 창 합성 서비스 (핵심 디스플레이 프로세스)",
            "Service de composition de fenêtres macOS WindowServer (processus d’affichage principal)", "macOS WindowServer Fenstermanager (Kern-Grafikprozess)", "Servicio de composición de ventanas macOS WindowServer (proceso de pantalla principal)", "Servizio di composizione delle finestre macOS WindowServer (processo display principale)", "Serviço de composição de janelas macOS WindowServer (processo gráfico principal)")
        add(.mainApplicationBundleAppExecutableFrameworksAndBundledResources, "应用程序主程序包（.app 可执行文件、框架与内置资源）", "應用程式主程式包（.app 執行檔、框架與內建資源）", "Main application bundle (.app executable, frameworks, and bundled resources)", "アプリケーション本体（.app実行ファイル、フレームワーク、内蔵リソース）", "애플리케이션 메인 번들 (.app 실행 파일, 프레임워크 및 내장 리소스)",
            "Paquet principal de l’application (exécutable .app, frameworks et ressources)", "Hauptprogramm-Bundle (.app-Programmdatei, Frameworks und Ressourcen)", "Paquete principal de la aplicación (ejecutable .app, frameworks y recursos)", "Pacchetto principale dell’app (eseguibile .app, framework e risorse)", "Pacote principal do aplicativo (executável .app, frameworks e recursos)")
        add(.maintenanceCompletedRatioFormat, "维护完成：已成功运行 %d/%d 项任务", "維護完成：已成功運行 %d/%d 項任務", "Maintenance complete: %d/%d tasks succeeded", "メンテナンス完了：%d/%d 件のタスクが成功しました", "유지보수 완료: %d/%d개 작업 성공",
            "Maintenance terminée : %d/%d tâches réussies", "Wartung abgeschlossen: %d/%d Aufgaben erfolgreich", "Mantenimiento completado: %d/%d tareas realizadas con éxito", "Manutenzione completata: %d/%d attività riuscite", "Manutenção concluída: %d/%d tarefas concluídas com sucesso")
        add(.maintenanceTaskNamePrefixFormat, "维护任务: %@", "維護任務: %@", "Maintenance task: %@", "メンテナンスタスク：%@ ", "유지보수 작업: %@",
            "Tâche de maintenance : %@", "Wartungsaufgabe: %@", "Tarea de mantenimiento: %@", "Attività di manutenzione: %@", "Tarefa de manutenção: %@")
        add(.maintenanceTaskNotFound, "未找到对应的维护任务", "未找到對應的維護任務", "Maintenance task not found", "対応するメンテナンスタスクが見つかりません", "해당 유지보수 작업을 찾을 수 없습니다",
            "Tâche de maintenance introuvable", "Wartungsaufgabe nicht gefunden", "No se encontró la tarea de mantenimiento", "Attività di manutenzione non trovata", "Tarefa de manutenção não encontrada")
        add(.maintenanceTasks, "系统维护任务", "系統維護任務", "Maintenance Tasks", "メンテナンスタスク", "유지보수 작업",
            "Tâches de maintenance", "Wartungsaufgaben", "Tareas de mantenimiento", "Attività di manutenzione", "Tarefas de Manutenção")
        add(.manageBackgroundServicesDesc, "管理在后台运行的守护进程、Brew 服务与系统伴随服务。您可以在这里方便地停用或启用它们。", "管理在後台運行的守護進程、Brew 服務與系統伴隨服務。您可以在這裡方便地停用或啟用它們。", "Manage background daemons, Homebrew services, and companion agents. Easily enable or disable them here.", "バックグラウンドで動作するデーモン、Brew サービス、およびシステムサービスを管理します。ここで簡単に有効化または無効化できます。", "백그라운드에서 실행되는 데몬, Brew 서비스 및 시스템 도우미 서비스를 관리합니다. 손쉽게 활성화하거나 비활성화할 수 있습니다.",
            "Gérez les démons d'arrière-plan, les services Brew et les agents. Activez ou désactivez-les facilement ici.", "Verwalten Sie Hintergrund-Daemons, Brew-Dienste und Begleitdienste. Aktivieren oder deaktivieren Sie sie hier problemlos.", "Administre demonios en segundo plano, servicios Brew y agentes. Actívelos o desactívelos fácilmente aquí.", "Gestisci i daemon in background, i servizi Brew e gli agenti. Abilitali o disabilitali facilmente qui.", "Gerencie daemons em segundo plano, serviços do Brew e agentes. Ative ou desative-os facilmente aqui.")
        add(.manageLoginAndLaunchAgentsDesc, "管理在开机时可以自动启动的应用程序与登录代理", "管理在開機時可以自動啟動的應用程式與登入代理", "Manage apps and launch agents that start automatically at login", "ログイン時に自動起動するアプリやエージェントを管理", "로그인 시 자동으로 시작되는 앱 및 실행 에이전트 관리",
            "Gérer les apps et agents de lancement lancés automatiquement", "Apps und Launch Agents verwalten, die automatisch starten", "Administrar apps y agentes de inicio que arrancan al iniciar sesión", "Gestisci app e agenti di avvio eseguiti automaticamente al login", "Gerenciar aplicativos e agentes de inicialização automáticos")
        add(.manager, "管理器", "管理器", "Manager", "マネージャー", "관리자",
            "Gestionnaire", "Manager", "Gestor", "Gestore", "Gerenciador")
        add(.mayAffectDataOrRequireReLoginReviewEachItemCarefully, "可能影响数据或需要重新获取,请逐项确认", "可能影響資料或需要重新獲取,請逐項確認", "May affect data or require re-login; review each item carefully", "データや再取得に影響する可能性があります。個別に確認してください", "데이터에 영향을 주거나 재획득이 필요할 수 있으므로 개별 확인 바랍니다",
            "Peut affecter des données ou exiger une reconnexion ; vérifiez chaque élément", "Kann Daten betreffen; bitte jeden Eintrag sorgfältig prüfen", "Puede afectar a datos o requerir inicio de sesión; revisa cada elemento", "Potrebbe influire sui dati o richiedere un nuovo accesso; verifica ogni voce", "Pode afetar dados ou exigir novo login; revise cada item cuidadosamente")
        add(.mediaGalleryComparison, "媒体画廊对比", "媒體畫廊對比", "Media Gallery Comparison", "メディアギャラリー比較", "미디어 갤러리 비교",
            "Comparaison de la galerie média", "Mediengalerie-Vergleich", "Comparación de galería multimedia", "Confronto galleria multimediale", "Comparação de Galeria de Mídia")
        add(.mediaGalleryComparisonTitle, "媒体画廊对比", "媒體圖庫對比", "Media Gallery Comparison", "メディアギャラリー比較", "미디어 갤러리 비교",
            "Comparaison de galerie média", "Mediengalerie-Vergleich", "Comparación de galería de medios", "Confronto galleria multimediale", "Comparação da Galeria de Mídia")
        add(.mediaGalleryTapPreviewHint, "轻点预览 · 勾选选择", "點按預覽 · 勾選選擇", "Tap to preview · Check to select", "タップしてプレビュー · チェックして選択", "탭하여 미리보기 · 선택하려면 체크",
            "Touchez pour prévisualiser · Cochez pour sélectionner", "Tippen zur Vorschau · Auswählen per Häkchen", "Toca para previsualizar · Marca para seleccionar", "Tocca per l'anteprima · Spunta per selezionare", "Toque para visualizar · Marque para selecionar")
        add(.memory, "内存", "記憶體", "Memory", "メモリ", "메모리",
            "Mémoire", "Speicher", "Memoria", "Memoria", "Memória")
        add(.memoryMonitor, "内存监控", "記憶體監控", "Memory Monitor", "メモリ監視", "메모리 모니터링",
            "Surveillance mémoire", "Speicherüberwachung", "Monitor de memoria", "Monitoraggio memoria", "Monitor de memória")
        add(.memoryPressureDistribution, "内存压力与分布", "記憶體壓力與分佈", "Memory Pressure & Composition", "メモリ圧力と内訳", "메모리 압력 및 분포",
            "Pression et répartition de la mémoire", "Speicherdruck & Belegung", "Presión y distribución de memoria", "Pressione e composizione memoria", "Pressão e Composição da Memória")
        add(.menuBarAcPowerDirectLabel, "直接供电", "直接供電", "AC Power", "AC電源", "AC 전원",
            "Alimentation secteur", "Netzbetrieb", "Alimentación de CA", "Alimentazione CA", "Alimentação CA")
        add(.menuBarAcPowerDirectSupply, "交流电源直供 (AC Power)", "交流電源直供 (AC Power)", "Connected to AC Power", "AC 電源接続中", "AC 전원 공급 중",
            "Alimentation secteur (CA)", "Netzteilbetrieb (AC Power)", "Alimentación de CA conectada", "Alimentazione CA collegata", "Alimentação CA conectada")
        add(.menuBarApfsPurgeableSpaceFormat, "APFS 可清除容量: %@", "APFS 可清除容量: %@", "APFS Purgeable: %@", "APFS 消去可能領域: %@", "APFS 정리 가능 용량: %@",
            "Purgeable APFS : %@", "APFS freigebbar: %@", "APFS purgable: %@", "APFS eliminabile: %@", "APFS purgável: %@")
        add(.menuBarAvgPeakUsageFormat, "均值 %.1f%% · 峰值 %.1f%%", "均值 %.1f%% · 峰值 %.1f%%", "Avg %.1f%% · Peak %.1f%%", "平均 %.1f%% · ピーク %.1f%%", "평균 %.1f%% · 피크 %.1f%%",
            "Moy. %.1f %% · Pic %.1f %%", "Ø %.1f %% · Spitze %.1f %%", "Media %.1f%% · Pico %.1f%%", "Media %.1f%% · Picco %.1f%%", "Média %.1f%% · Pico %.1f%%")
        add(.menuBarBatteryBusAmperesLabel, "总线电流", "匯流排電流", "Bus Current", "バス電流", "버스 전류",
            "Courant du bus", "Bus-Stromstärke", "Corriente del bus", "Corrente del bus", "Corrente do barramento")
    }

    static func populateBatch7(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.menuBarBatteryHealthHeader, "电池健康与充放电", "電池健康與充放電", "Battery Health & Power", "バッテリーの状態と充放電", "배터리 성능 상태 및 충방전",
            "Santé de la batterie et alimentation", "Batteriezustand & Stromversorgung", "Salud de la batería y energía", "Stato batteria e alimentazione", "Saúde da bateria e energia")
        add(.menuBarBatteryHealthPercentFormat, "健康度 %d%%", "健康度 %d%%", "Health %d%%", "健全性 %d%%", "성능 최대치 %d%%",
            "Santé %d%%", "Zustand %d%%", "Salud %d%%", "Stato %d%%", "Saúde %d%%")
        add(.menuBarBatteryHealthTitle, "电池健康与充放电管理", "電池健康與充放電管理", "Battery Health & Power Management", "バッテリーの健康度と充放電管理", "배터리 수명 및 충방전 관리",
            "Santé de la batterie et alimentation", "Batteriezustand & Energieverwaltung", "Salud de la batería y gestión de energía", "Stato della batteria e gestione dell'alimentazione", "Saúde da bateria e gerenciamento de energia")
        add(.menuBarBluetoothPeripheralsHeader, "BLUETOOTH PERIPHERALS · 蓝牙外设电量", "BLUETOOTH PERIPHERALS · 藍牙外設電量", "BLUETOOTH PERIPHERALS · Battery Levels", "Bluetooth 周辺機器 · バッテリー残量", "Bluetooth 주변기기 · 배터리 잔량",
            "PÉRIPHÉRIQUES BLUETOOTH · Niveaux de batterie", "BLUETOOTH-GERÄTE · Batteriestände", "PERIFÉRICOS BLUETOOTH · Nivel de batería", "PERIFERICHE BLUETOOTH · Livelli batteria", "PERIFÉRICOS BLUETOOTH · Níveis de bateria")
        add(.menuBarCatBattery, "电池与电源", "電池與電源", "Battery & Power", "バッテリーと電源", "배터리 및 전원",
            "Batterie et alimentation", "Batterie & Strom", "Batería y energía", "Batteria e alimentazione", "Bateria e Energia")
        add(.menuBarCatCombined, "组合主面板", "組合主面板", "Combined Panel", "複合パネル", "복합 패널",
            "Panneau combiné", "Kombi-Panel", "Panel combinado", "Pannello combinato", "Painel Combinado")
        add(.menuBarCatCpuGpu, "处理器与显卡", "處理器與顯卡", "CPU & GPU", "CPU と GPU", "CPU 및 GPU",
            "CPU et GPU", "CPU & GPU", "CPU y GPU", "CPU e GPU", "CPU e GPU")
        add(.menuBarCatDisks, "磁盘", "磁碟", "Disks", "ディスク", "디스크",
            "Disques", "Festplatten", "Discos", "Dischi", "Discos")
        add(.menuBarCatMemory, "内存", "記憶體", "Memory", "メモリ", "메모리",
            "Mémoire", "Speicher", "Memoria", "Memoria", "Memória")
        add(.menuBarCatNetwork, "网络", "網路", "Network", "ネットワーク", "네트워크",
            "Réseau", "Netzwerk", "Red", "Rete", "Rede")
        add(.menuBarCatSensors, "传感器与风扇", "感測器與風扇", "Sensors & Fans", "センサーとファン", "센서 및 팬",
            "Capteurs et ventilateurs", "Sensoren & Lüfter", "Sensores y ventiladores", "Sensori e ventole", "Sensores e Ventoinhas")
        add(.menuBarCatTime, "时间", "時間", "Time", "時刻", "시간",
            "Heure", "Uhrzeit", "Hora", "Ora", "Hora")
        add(.menuBarCatWeather, "天气", "天氣", "Weather", "天気", "날씨",
            "Météo", "Wetter", "Clima", "Meteo", "Clima")
        add(.menuBarChipPowerWattsFormat, "芯片功耗 %.1f W", "芯片功耗 %.1f W", "Chip Power %.1f W", "SoC 消費電力 %.1f W", "칩 소비 전력 %.1f W",
            "Puissance de la puce %.1f W", "Chip-Leistung %.1f W", "Potencia del chip %.1f W", "Potenza del chip %.1f W", "Potência do chip %.1f W")
        add(.menuBarConfig, "菜单栏配置", "選單列配置", "Menu Bar", "メニューバー設定", "메뉴 막대 설정",
            "Barre des menus", "Menüleiste", "Barra de menús", "Barra dei menu", "Barra de Menus")
        add(.menuBarConfigCustomizationHelp, "配置菜单栏监控与弹出卡片", "設定選單列監控與彈出卡片", "Configure Menu Bar & Companion Cards", "メニューバー監視とポップアップカードを設定", "메뉴 막대 모니터링 및 팝업 카드 구성",
            "Configurer la barre des menus et les cartes satellites", "Menüleistenüberwachung & Begleitkarten anpassen", "Configurar barra de menús y tarjetas complementarias", "Configura barra dei menu e schede contestuali", "Configurar barra de menus e cartões assistentes")
        add(.menuBarConfiguratorHeaderSubtitle, "自定义顶部菜单栏实时监控指标与下拉控制台展示的模块及顺序，使用复选与拖动灵活重排", "自定義頂部菜單欄實時監控指標與下拉控製台展示的模塊及順序，使用複選與拖動靈活重排", "Customize menu bar monitor tokens and dropdown console sections with checkboxes and drag-and-drop", "メニューバーの監視指標やドロップダウンの表示モジュールと順序をチェックボックスとドラッグでカスタマイズ", "체크박스와 드래그 앤 드롭으로 상단 메뉴 막대 모니터링 항목 및 드롭다운 콘솔 순서를 사용자 지정하세요",
            "Personnalisez les indicateurs de la barre des menus et les sections déroulantes par glisser-déposer", "Passen Sie Menüleisten-Indikatoren und Dropdown-Module flexibel per Checkbox und Drag & Drop an", "Personalice los indicadores de la barra de menús y secciones desplegables arrastrando y marcando", "Personalizza gli indicatori della barra dei menu e i moduli a discesa con trascinamento", "Personalize os indicadores da barra de menus e seções suspensas com caixas de seleção e arrastar e soltar")
        add(.menuBarConfiguratorHeaderTitle, "组合主面板配置", "組合主面板配置", "Combined Panel Configuration", "統合パネル設定", "통합 메인 패널 구성",
            "Configuration du panneau combiné", "Kombinierte Hauptpanel-Konfiguration", "Configuración del panel combinado", "Configurazione del pannello combinato", "Configuração do painel combinado")
        add(.menuBarConfiguratorWindowTitle, "ACleaner 菜单栏与下拉模块配置", "ACleaner 選單列與下拉模組設定", "ACleaner Menu Bar & Dropdown Configurator", "ACleaner メニューバーとドロップダウン設定", "ACleaner 메뉴 막대 및 드롭다운 설정",
            "Configuration de la barre de menus et du volet déroulant ACleaner", "ACleaner Menüleisten- & Dropdown-Konfiguration", "Configuración de barra de menús y panel desplegable de ACleaner", "Configurazione barra dei menu e tendina di ACleaner", "Configuração da Barra de Menus e Painel Suspenso do ACleaner")
        add(.menuBarCoreTemperatureTab, "核心温度", "核心溫度", "Core Temp", "コア温度", "코어 온도",
            "Temp. des cœurs", "Kerntemperatur", "Temp. de núcleos", "Temp. dei core", "Temp. dos núcleos")
        add(.menuBarCpuHistoryTrendFormat, "CPU 处理器 · %@ 走势", "CPU 處理器 · %@ 走勢", "CPU Processor · %@ Trend", "CPU プロセッサ · %@ 推移", "CPU 프로세서 · %@ 추이",
            "Processeur CPU · Tendance %@", "CPU-Prozessor · %@-Verlauf", "Procesador CPU · Tendencia %@", "Processore CPU · Tendenza %@", "Processador CPU · Tendência %@")
        add(.menuBarDesktopAcPowerPrompt, "桌面 Mac 电脑使用交流电源供电，无内置电池。", "桌上型 Mac 電腦使用交流電源供電，無內建電池。", "Desktop Macs run on AC power and do not have an internal battery.", "デスクトップMacはAC電源で動作し、内蔵バッテリーはありません。", "데스크탑 Mac은 AC 전원으로 작동하며 내장 배터리가 없습니다.",
            "Les Mac de bureau fonctionnent sur secteur et ne possèdent pas de batterie interne.", "Desktop-Macs werden über Netzstrom betrieben und haben keine interne Batterie.", "Los Mac de sobremesa funcionan con corriente alterna y no tienen batería interna.", "I Mac desktop funzionano con alimentazione CA e non hanno una batteria interna.", "Macs desktop funcionam com energia CA e não possuem bateria interna.")
        add(.menuBarDesktopNoBatteryPrompt, "当前设备为台式机架构或交流电源直供，无独立内置电池。", "當前設備為台式機架構或交流電源直供，無獨立內置電池。", "This desktop architecture operates directly on AC power without an internal battery.", "このデバイスはデスクトップ構成または AC 電源直供のため、内蔵バッテリーはありません。", "이 기기는 데스크탑 아키텍처로 AC 전원으로 직접 구동되며 내장 배터리가 없습니다.",
            "Cet appareil de bureau fonctionne sur secteur sans batterie intégrée.", "Dieses Desktop-Gerät wird direkt über das Netzteil betrieben und hat keinen Akku.", "Este equipo de sobremesa funciona con alimentación de CA sin batería interna.", "Questo dispositivo desktop funziona direttamente a corrente CA senza batteria interna.", "Este computador de mesa opera diretamente com alimentação CA sem bateria interna.")
        add(.menuBarDiskIoHeader, "DISK I/O · 实时读写速率与走势", "DISK I/O · 實時讀寫速率與走勢", "DISK I/O · Real-Time Speed & Trend", "ディスク I/O · リアルタイム速度と推移", "디스크 I/O · 실시간 읽기/쓰기 속도 및 추이",
            "E/S DISQUE · Vitesse et tendance en temps réel", "FESTPLATTEN-I/O · Echtzeit-Geschwindigkeit & Trend", "E/S DE DISCO · Velocidad en tiempo real y tendencia", "I/O DISCO · Velocità in tempo reale e tendenza", "E/S DE DISCO · Velocidade em tempo real e tendência")
        add(.menuBarDisplayItemsSubtitle, "所见即所得：勾选启用并在顶部预览条中实时观察排列效果", "所見即所得：勾選啟用並在頂部預覽列中即時觀察排列效果", "WYSIWYG: Toggle items and preview the arrangement in real time above", "リアルタイム確認：項目を選択して上部のプレビューで配置を確認", "실시간 확인: 항목을 선택하여 상단 미리보기에서 배치 효과 확인",
            "Aperçu instantané : activez les éléments et vérifiez la disposition en haut", "Echtzeit-Vorschau: Elemente aktivieren und Anordnung oben prüfen", "Vista previa en tiempo real: activa elementos y observa el diseño", "Anteprima istantanea: seleziona gli elementi per visualizzare l’ordine", "Visualização em tempo real: marque os itens e confira a disposição acima")
        add(.menuBarDisplayItemsTitle, "顶部菜单栏显示项与顺序", "頂部選單列顯示項與順序", "Menu Bar Items & Order", "メニューバー表示項目と順序", "메뉴 막대 표시 항목 및 순서",
            "Éléments et ordre de la barre des menus", "Menüleistenelemente & Reihenfolge", "Elementos y orden de barra de menús", "Elementi e ordine della barra dei menu", "Itens da Barra de Menus e Ordem")
        add(.menuBarDownloadRxLabel, "下行接收", "下行接收", "Download (RX)", "受信 (RX)", "다운로드 (RX)",
            "Réception (RX)", "Empfang (RX)", "Descarga (RX)", "Download (RX)", "Download (RX)")
        add(.menuBarEfficiencyCoresAvgUsageFormat, "能效核均载: %d%%", "能效核均載: %d%%", "E-Cores Avg: %d%%", "高効率コア平均: %d%%", "고효율 코어 평균: %d%%",
            "Cœurs E moy. : %d %%", "E-Kerne Ø: %d %%", "Núcleos E media: %d%%", "Core E medi: %d%%", "Núcleos E média: %d%%")
        add(.menuBarElectricalPowerBusHeader, "ELECTRICAL POWER BUS · 功耗与电源总线", "ELECTRICAL POWER BUS · 功耗與電源總線", "ELECTRICAL POWER BUS · Power & System Rail", "電力バス · 消費電力と電源レール", "전원 버스 · 소비 전력 및 시스템 전원 레일",
            "BUS D'ALIMENTATION ÉLECTRIQUE · Puissance et rails", "STROMVERSORGUNGSBUS · Leistung & Schienen", "BUS DE ALIMENTACIÓN ELÉCTRICA · Potencia y rieles", "BUS DI ALIMENTAZIONE · Potenza e linee di alimentazione", "BARRAMENTO DE ENERGIA ELÉTRICA · Potência e linhas")
        add(.menuBarExternalVolumesHeader, "EXTERNAL VOLUMES · 外置挂载卷", "EXTERNAL VOLUMES · 外置掛載卷", "EXTERNAL VOLUMES · Mounted Drives", "外部ボリューム · マウント済みドライブ", "외장 볼륨 · 마운트된 외부 드라이브",
            "VOLUMES EXTERNES · Disques montés", "EXTERNE VOLUMES · Gemountete Laufwerke", "VOLÚMENES EXTERNOS · Unidades montadas", "VOLUMI ESTERNI · Unità montate", "VOLUMES EXTERNOS · Unidades montadas")
        add(.menuBarFanControlTitle, "风扇转速监控与智能调速", "風扇轉速監控與智能調速", "Fan Speed Monitoring & Smart Control", "ファン回転数監視とスマート制御", "팬 회전수 모니터링 및 스마트 제어",
            "Surveillance de la vitesse du ventilateur et contrôle", "Lüfterdrehzahl-Überwachung & intelligente Steuerung", "Monitoreo y control inteligente de ventiladores", "Monitoraggio e controllo intelligente delle ventole", "Monitoramento e controle inteligente de ventoinhas")
        add(.menuBarFanCountFormat, "%d 具风扇", "%d 座風扇", "%d Fans", "%d 基のファン", "%d개 팬",
            "%d ventilateurs", "%d Lüfter", "%d ventiladores", "%d ventole", "%d Ventoinhas")
        add(.menuBarFanDutyCycleSuffixFormat, ") · %d%% 占空比", ") · %d%% 佔空比", ") · %d%% Duty Cycle", ") · %d%% デューティ比", ") · %d%% 듀티 사이클",
            ") · %d %% cycle de service", ") · %d %% Auslastung", ") · %d%% ciclo de trabajo", ") · %d%% ciclo di lavoro", ") · %d%% ciclo de trabalho")
        add(.menuBarFanModeCooling50, "降温 50%", "降溫 50%", "Cool 50%", "冷却 50%", "냉각 50%",
            "Refroidissement 50%", "Kühlung 50%", "Enfriamiento 50%", "Raffreddamento 50%", "Resfriamento 50%")
        add(.menuBarFanModeMax100, "强冷 100%", "強冷 100%", "Max 100%", "最大 100%", "최대 100%",
            "Max 100%", "Max 100%", "Máx 100%", "Max 100%", "Máx 100%")
        add(.menuBarFanModeSystemAuto, "系统自动", "系統自動", "System Auto", "システム自動", "시스템 자동",
            "Automatique", "System-Auto", "Automático", "Automatico", "Automático")
        add(.menuBarFanlessArchitecturePill, "无风扇静音架构", "無風扇靜音架構", "Fanless Silent Architecture", "ファンレス静音設計", "팬리스 무소음 설계",
            "Architecture silencieuse sans ventilateur", "Lüfterlose lautlose Architektur", "Arquitectura silenciosa sin ventilador", "Architettura silenziosa senza ventole", "Arquitetura silenciosa sem ventoinhas")
        add(.menuBarFanlessArchitecturePrompt, "当前机型采用 Apple Silicon 无风扇被动静音散热架构，完全零转速噪音。", "當前機型採用 Apple Silicon 無風扇被動靜音散熱架構，完全零轉速噪音。", "This model features a fanless passive cooling architecture with zero acoustic noise.", "このモデルはファンレスの静音パッシブ冷却構造を採用しており、動作音は完全にゼロです。", "이 기종은 무팬 패시브 무소음 방열 설계를 채택하여 팬 소음이 전혀 없습니다.",
            "Ce modèle intègre un refroidissement passif sans ventilateur avec zéro bruit sonore.", "Dieses Modell verfügt über eine lüfterlose passive Kühlung ohne Betriebsgeräusche.", "Este modelo cuenta con arquitectura de refrigeración pasiva sin ventilador y sin ruido.", "Questo modello è dotato di raffreddamento passivo senza ventole con zero rumore acustico.", "Este modelo possui arquitetura de resfriamento passivo sem ventoinhas e com ruído zero.")
        add(.menuBarGeographicEgressLabel, "地理出口", "地理出口", "Location", "地理的位置", "위치",
            "Sortie géographique", "Geografischer Standort", "Ubicación geográfica", "Posizione geografica", "Saída geográfica")
        add(.menuBarGpuCoresSuffixFormat, ") · %d 渲染核", ") · %d 渲染核", ") · %d GPU Cores", ") · %d GPU コア", ") · %d GPU 코어",
            ") · %d cœurs GPU", ") · %d GPU-Kerne", ") · %d núcleos de GPU", ") · %d core GPU", ") · %d núcleos de GPU")
        add(.menuBarGpuEngineHeader, "GPU ENGINE · 显卡与图形引擎", "GPU ENGINE · 顯卡與圖形引擎", "GPU ENGINE · Graphics Engine", "GPU エンジン · グラフィックス", "GPU 엔진 · 그래픽스 엔진",
            "MOTEUR GPU · Moteur graphique", "GPU-ENGINE · Grafikbeschleuniger", "MOTOR GPU · Motor de gráficos", "MOTORE GPU · Motore grafico", "MOTOR GPU · Mecanismo gráfico")
        add(.menuBarIspLabel, "运营商", "電信業者", "ISP", "プロバイダ", "통신사",
            "Fournisseur", "Internetanbieter", "Proveedor", "Provider", "Operadora")
        add(.menuBarLatencySuffixFormat, ") · 延迟: %@", ") · 延遲: %@", ") · Latency: %@", ") · 遅延: %@", ") · 지연 시간: %@",
            ") · Latence : %@", ") · Latenz: %@", ") · Latencia: %@", ") · Latenza: %@", ") · Latência: %@")
        add(.menuBarLayoutSpanHelpFormat, "排版拼装：%@", "排版拼裝：%@", "Layout Assembly: %@", "グリッド配置：%@", "레이아웃 배치: %@",
            "Agencement de mise en page : %@", "Layout-Anordnung: %@", "Diseño de cuadrícula: %@", "Disposizione griglia: %@", "Layout de Grade: %@")
        add(.menuBarLegendActive, "活跃", "作用中", "App Memory", "アクティブ", "활성",
            "Mémoire de l’application", "App-Speicher", "Memoria de la app", "Memoria app", "Memória de app")
        add(.menuBarLegendCache, "缓存", "快取", "Cached", "キャッシュ", "캐시됨",
            "En cache", "Zwischengespeichert", "En caché", "In cache", "Em cache")
        add(.menuBarLegendCompressed, "已压缩", "已壓縮", "Compressed", "圧縮済み", "압축됨",
            "Compressée", "Komprimiert", "Comprimida", "Compressa", "Compactada")
        add(.menuBarLegendFree, "空闲", "閒置", "Free", "空き", "여유",
            "Disponible", "Frei", "Libre", "Libera", "Livre")
        add(.menuBarLegendWired, "联动", "聯動", "Wired", "確保中", "고정됨",
            "Réservée", "Fest belegt", "Fija", "Vincolata", "Fixa")
        add(.menuBarLivePreviewHeader, "macOS 菜单栏实时预览（所见即所得）：", "macOS 菜單欄實時預覽（所見即所得）：", "macOS Menu Bar Live Preview (WYSIWYG):", "macOS メニューバーのリアルタイムプレビュー：", "macOS 메뉴 막대 실시간 미리보기 (WYSIWYG):",
            "Aperçu en direct de la barre des menus macOS :", "Echtzeit-Vorschau der macOS-Menüleiste (WYSIWYG):", "Vista previa en directo de la barra de menús de macOS:", "Anteprima dal vivo della barra dei menu di macOS:", "Pré-visualização em tempo real da barra de menus do macOS:")
        add(.menuBarLivePreviewTitle, "macOS 菜单栏实时预览条（所见即所得）：", "macOS 選單列即時預覽列（所見即所得）：", "macOS Menu Bar Live Preview:", "macOS メニューバー ライブプレビュー:", "macOS 메뉴 막대 실시간 미리보기:",
            "Aperçu de la barre des menus macOS :", "macOS Menüleisten-Vorschau:", "Vista previa de la barra de menús:", "Anteprima barra dei menu macOS:", "Pré-visualização da Barra de Menus do macOS:")
        add(.menuBarLoadAverageHeader, "LOAD AVERAGE · 系统平均负载与开机运行", "LOAD AVERAGE · 系統平均負載與開機運行", "LOAD AVERAGE · System Load & Uptime", "ロードアベレージ · システム平均負荷と稼働時間", "평균 부하 · 시스템 평균 로드 및 가동 시간",
            "CHARGE MOYENNE · Charge du système et disponibilité", "DURCHSCHNITTSLAST · Systemlast & Betriebszeit", "CARGA MEDIA · Carga del sistema y tiempo activo", "CARICO MEDIO · Carico del sistema e tempo di attività", "CARGA MÉDIA · Carga do sistema e tempo de atividade")
        add(.menuBarLocalIpv4Label, "内网 IPv4", "內部 IPv4", "Local IPv4", "ローカル IPv4", "로컬 IPv4",
            "IPv4 locale", "Lokale IPv4", "IPv4 local", "IPv4 locale", "IPv4 local")
        add(.menuBarLocalIpv4PrefixFormat, "局域网: %@", "區域網路: %@", "LAN: %@", "LAN: %@", "로컬망: %@",
            "Réseau local : %@", "LAN: %@", "LAN: %@", "LAN: %@", "LAN: %@")
        add(.menuBarLocalIpv6Label, "内网 IPv6", "內部 IPv6", "Local IPv6", "ローカル IPv6", "로컬 IPv6",
            "IPv6 locale", "Lokale IPv6", "IPv6 local", "IPv6 locale", "IPv6 local")
        add(.menuBarMacintoshHdLocalTitle, "Macintosh HD 本地主卷", "Macintosh HD 本地主卷", "Macintosh HD Local Volume", "Macintosh HD ローカルボリューム", "Macintosh HD 로컬 볼륨",
            "Volume local Macintosh HD", "Lokales Macintosh HD-Volume", "Volumen local de Macintosh HD", "Volume locale Macintosh HD", "Volume local do Macintosh HD")
        add(.menuBarMacintoshHdTitle, "Macintosh HD · 本地主存储", "Macintosh HD · 本地主存儲", "Macintosh HD · Primary Storage", "Macintosh HD · プライマリストレージ", "Macintosh HD · 기본 로컬 스토리지",
            "Macintosh HD · Stockage principal", "Macintosh HD · Hauptspeicher", "Macintosh HD · Almacenamiento principal", "Macintosh HD · Archiviazione principale", "Macintosh HD · Armazenamento principal")
        add(.menuBarMemoryCompositionHeader, "MEMORY COMPOSITION · 内存精细化分层", "MEMORY COMPOSITION · 內存精細化分層", "MEMORY COMPOSITION · Memory Breakdown", "メモリ構成 · メモリ詳細内訳", "메모리 구성 · 상세 메모리 계층 분석",
            "COMPOSITION DE LA MÉMOIRE · Répartition détaillée", "SPEICHERZUSAMMENSETZUNG · Detaillierte Aufschlüsselung", "COMPOSICIÓN DE LA MEMORIA · Desglose detallado", "COMPOSIZIONE DELLA MEMORIA · Ripartizione dettagliata", "COMPOSIÇÃO DA MEMÓRIA · Divisão detalhada")
        add(.menuBarMemoryPressurePrefixFormat, "压力 %@", "壓力 %@", "Pressure %@", "プレッシャー %@", "압박도 %@",
            "Pression %@", "Druck %@", "Presión %@", "Pressione %@", "Pressão %@")
        add(.menuBarMemoryTrendFormat, "内存监控 · %@ 走势", "記憶體監控 · %@ 走勢", "Memory Monitor · %@ Trend", "メモリ監視 · %@ 推移", "메모리 모니터링 · %@ 추이",
            "Moniteur de mémoire · Tendance %@", "Speicher-Monitor · %@-Verlauf", "Monitor de memoria · Tendencia %@", "Monitoraggio memoria · Tendenza %@", "Monitor de memória · Tendência %@")
        add(.menuBarMonitorDisabledSubtitle, "开启后即可在上方自定义常驻指标、下拉卡片与硬件图表", "開啟後即可在上方自訂常駐指標、下拉卡片與硬體圖表", "Turn it on to customize menu bar items, dropdown cards, and hardware graphs", "有効にすると、常駐項目、詳細カード、グラフを自由に設定できます", "켜시면 상주 지표, 드롭다운 카드 및 하드웨어 차트를 맞춤 설정할 수 있습니다",
            "Activez-le pour personnaliser les indicateurs, cartes et graphiques matériels", "Aktivieren Sie es, um Menüleistensymbole, Popover-Karten und Graphen anzupassen", "Actívalo para personalizar iconos fijos, tarjetas y gráficas de hardware", "Attivalo per personalizzare indicatori, schede e grafici hardware", "Ative para personalizar indicadores, cartões e gráficos de hardware")
        add(.menuBarMonitorDisabledTitle, "状态栏实时监控已关闭", "狀態列即時監控已關閉", "Menu Bar Companion is Disabled", "メニューバー監視は無効です", "메뉴 막대 모니터링이 꺼져 있습니다",
            "Le compagnon de la barre des menus est désactivé", "Menüleisten-Begleiter ist deaktiviert", "El monitor de barra de menús está desactivado", "Il monitor nella barra dei menu è disattivato", "O Monitor na Barra de Menus está Desativado")
        add(.menuBarNetworkThroughputTitle, "网络吞吐", "網絡吞吐", "Network Throughput", "ネットワークスループット", "네트워크 처리량",
            "Débit réseau", "Netzwerkdurchsatz", "Rendimiento de red", "Throughput di rete", "Taxa de transferência de rede")
        add(.menuBarNetworkThroughputTrendFormat, "实时吞吐率 · %@ 走势", "即時吞吐率 · %@ 走勢", "Real-time Throughput · %@ Trend", "リアルタイムスループット · %@ 推移", "실시간 처리율 · %@ 추이",
            "Débit en temps réel · Tendance %@", "Echtzeitdurchsatz · %@-Verlauf", "Rendimiento en tiempo real · Tendencia %@", "Throughput in tempo reale · Tendenza %@", "Taxa de transferência em tempo real · Tendência %@")
        add(.menuBarNoAbnormalBandwidthAppsPrompt, "当前无异常高带宽占用进程", "當前無異常高帶寬佔用進程", "No unusually high bandwidth processes currently", "異常に高い帯域幅を消費しているプロセスはありません", "현재 비정상적으로 대역폭을 많이 사용하는 프로세스가 없습니다",
            "Aucun processus à bande passante anormalement élevée", "Derzeit keine Prozesse mit ungewöhnlich hoher Bandbreitennutzung", "Actualmente no hay procesos con uso inusual de ancho de banda", "Al momento nessun processo con consumo di banda anomalo", "Nenhum processo com consumo incomum de largura de banda no momento")
        add(.menuBarNoBluetoothAccessoriesPrompt, "当前未连接支持电量上报的蓝牙无线键盘或鼠标", "當前未連接支持電量上報的藍牙無線鍵盤或鼠標", "No wireless Bluetooth keyboard or mouse with battery reporting connected", "バッテリー残量通知に対応した Bluetooth 周辺機器は接続されていません", "배터리 잔량 보고를 지원하는 무선 Bluetooth 키보드나 마우스가 연결되어 있지 않습니다",
            "Aucun clavier ou souris Bluetooth sans fil avec rapport de batterie connecté", "Keine drahtlose Tastatur oder Maus mit Akkustandsanzeige verbunden", "No hay teclado o ratón Bluetooth con indicador de batería conectado", "Nessuna tastiera o mouse wireless Bluetooth con indicatore di batteria collegato", "Nenhum teclado ou mouse sem fio Bluetooth com relatório de bateria conectado")
        add(.menuBarNoBluetoothPeripheralsPrompt, "未连接低功耗蓝牙外设", "未連接低功耗藍牙周邊", "No Bluetooth peripherals connected", "Bluetoothデバイスは接続されていません", "연결된 블루투스 기기가 없습니다",
            "Aucun périphérique Bluetooth connecté", "Keine Bluetooth-Geräte verbunden", "No hay periféricos Bluetooth conectados", "Nessun dispositivo Bluetooth connesso", "Nenhum periférico Bluetooth conectado")
        add(.menuBarNoExternalVolumesPrompt, "当前未连接外置移动硬盘或磁盘映像", "當前未連接外置移動硬盤或磁盤映像", "No external drives or disk images currently connected", "現在、外付けハードディスクやディスクイメージは接続されていません", "현재 연결된 외장 하드 드라이브 또는 디스크 이미지가 없습니다",
            "Aucun disque externe ou image disque connecté actuellement", "Derzeit sind keine externen Laufwerke oder Disk-Images angeschlossen", "No hay discos externos o imágenes de disco conectados actualmente", "Nessuna unità esterna o immagine disco attualmente collegata", "Nenhum disco externo ou imagem de disco conectado no momento")
        add(.menuBarNoHighBandwidthAppsPrompt, "暂无高带宽占用应用", "暫無高頻寬佔用應用", "No high-bandwidth applications", "高帯域幅のアプリはありません", "고대역폭 응용 프로그램 없음",
            "Aucune application à large bande passante", "Keine Apps mit hoher Bandbreite", "Sin aplicaciones de gran ancho de banda", "Nessuna app ad alta larghezza di banda", "Nenhum app de alta largura de banda")
        add(.menuBarNoItemsSelectedPrompt, "未勾选任何菜单栏指标，请在下方勾选", "未勾選任何選單列指標，請在下方勾選", "No items selected. Choose metrics below.", "項目が選択されていません。下から選択してください。", "선택된 지표가 없습니다. 아래에서 선택하세요.",
            "Aucun indicateur sélectionné. Veuillez en choisir ci-dessous.", "Keine Elemente gewählt. Bitte unten auswählen.", "Ningún indicador seleccionado. Elige abajo.", "Nessun indicatore selezionato. Selezionane uno sotto.", "Nenhum item selecionado. Escolha métricas abaixo.")
        add(.menuBarNoTokensSelectedPrompt, "未启用任何菜单栏指标，请在下方勾选", "未啟用任何菜單欄指標，請在下方勾選", "No menu bar items enabled. Please check items below", "メニューバー指標が有効になっていません。下部で項目を選択してください", "선택된 메뉴 막대 항목이 없습니다. 아래에서 항목을 선택하세요",
            "Aucun indicateur activé. Veuillez cocher des éléments ci-dessous", "Keine Indikatoren aktiviert. Bitte wählen Sie unten Elemente aus", "Ningún indicador activado. Marque los elementos abajo", "Nessun indicatore abilitato. Seleziona gli elementi sotto", "Nenhum item ativado na barra de menus. Marque os itens abaixo")
        add(.menuBarNotConnectedAdapterHeader, "NOT CONNECTED · 未连接/备用硬件适配器", "NOT CONNECTED · 未連接/備用硬件適配器", "NOT CONNECTED · Inactive / Standby Adapter", "未接続 · 非アクティブ／待機中アダプター", "연결되지 않음 · 비활성 / 대기 하드웨어 어댑터",
            "NON CONNECTÉ · Adaptateur inactif / en veille", "NICHT VERBUNDEN · Inaktiver / Standby-Adapter", "NO CONECTADO · Adaptador inactivo / en espera", "NON CONNESSO · Scheda inattiva / in standby", "NÃO CONECTADO · Adaptador inativo / em espera")
        add(.menuBarNotConnectedAdaptersHeader, "未连接网络适配器", "未連接網路卡", "Inactive Adapters", "未接続のネットワークアダプタ", "연결되지 않은 네트워크 어댑터",
            "Adaptateurs réseau inactifs", "Inaktive Netzwerkadapter", "Adaptadores no conectados", "Adattatori non connessi", "Adaptadores desconectados")
        add(.menuBarPageInsLabel, "页面换入", "分頁換入", "Page Ins", "ページイン", "페이지 입력",
            "Entrées de pages", "Page-Ins", "Entradas de página", "Pagine lette", "Entradas de página")
        add(.menuBarPageOutsLabel, "页面换出", "分頁換出", "Page Outs", "ページアウト", "페이지 출력",
            "Sorties de pages", "Page-Outs", "Salidas de página", "Pagine scritte", "Saídas de página")
        add(.menuBarPeakDownloadSpeedFormat, "峰值: %@", "峰值: %@", "Peak: %@", "ピーク: %@", "최고 속도: %@",
            "Pic : %@", "Spitze: %@", "Pico: %@", "Picco: %@", "Pico: %@")
        add(.menuBarPeakIoSpeedPrefixFormat, "峰值: %@", "峰值: %@", "Peak: %@", "ピーク: %@", "최고 속도: %@",
            "Pic : %@", "Spitze: %@", "Pico: %@", "Picco: %@", "Pico: %@")
        add(.menuBarPeakUploadSpeedFormat, "峰值: %@", "峰值: %@", "Peak: %@", "ピーク: %@", "최고 속도: %@",
            "Pic : %@", "Spitze: %@", "Pico: %@", "Picco: %@", "Pico: %@")
        add(.menuBarPerCoreEqualizerHeader, "核心负载均衡器", "核心負載均衡器", "Per-Core Load Equalizer", "コア別ロードイコライザー", "코어별 부하 균등화",
            "Égaliseur de charge par cœur", "Lastverteilung pro Kern", "Ecualizador de carga por núcleo", "Bilanciamento del carico per core", "Equalizador de carga por núcleo")
        add(.menuBarPerCoreLoadMatrixHeader, "PER-CORE EQUALIZER · 核心负载矩阵", "PER-CORE EQUALIZER · 核心負載矩陣", "PER-CORE EQUALIZER · Core Load Matrix", "コア別負荷イコライザー · 負荷マトリクス", "코어별 로드 이퀄라이저 · 코어 부하 매트릭스",
            "ÉGALISEUR PAR CŒUR · Matrice de charge des cœurs", "KERN-EQUALIZER · Kern-Lastmatrix", "ECUALIZADOR POR NÚCLEO · Matriz de carga", "EQUALIZZATORE PER CORE · Matrice di carico dei core", "EQUALIZADOR POR NÚCLEO · Matriz de carga dos núcleos")
        add(.menuBarPerformanceCoresAvgUsageFormat, "性能核均载: %d%%", "性能核均載: %d%%", "P-Cores Avg: %d%%", "高性能コア平均: %d%%", "고성능 코어 평균: %d%%",
            "Cœurs P moy. : %d %%", "P-Kerne Ø: %d %%", "Núcleos P media: %d%%", "Core P medi: %d%%", "Núcleos P média: %d%%")
        add(.menuBarPhysicalMemoryTitle, "物理内存", "物理內存", "Physical Memory", "物理メモリ", "실제 메모리",
            "Mémoire physique", "Physischer Arbeitsspeicher", "Memoria física", "Memoria fisica", "Memória física")
        add(.menuBarPowerBusHeader, "系统供电总线", "系統供電匯流排", "Power Bus Telemetry", "電源バステレメトリ", "전원 버스 원격 측정",
            "Télémétrie du bus d’alimentation", "Strombus-Telemetrie", "Telemetría del bus de energía", "Telemetria bus di alimentazione", "Telemetria do barramento de energia")
        add(.menuBarPowerBusVoltageLabel, "总线电压", "匯流排電壓", "Bus Voltage", "バス電圧", "버스 전압",
            "Tension du bus", "Bus-Spannung", "Voltaje del bus", "Tensione del bus", "Tensão do barramento")
        add(.menuBarPublicIpAddressLabel, "公网 IP", "公用 IP", "Public IP", "パブリック IP", "공인 IP",
            "IP publique", "Öffentliche IP", "IP pública", "IP pubblico", "IP público")
        add(.menuBarPublicIpAndEgressTitle, "公网 IP 与出口网络", "公網 IP 與出口網絡", "Public IP & Egress Network", "パブリック IP と出口ネットワーク", "공인 IP 및 아웃바운드 네트워크",
            "IP publique et réseau de sortie", "Öffentliche IP & Egress-Netzwerk", "IP pública y red de salida", "IP pubblico e rete di uscita", "IP público e rede de saída")
        add(.menuBarPublicIpFormat, "公网 IP: %@", "公網 IP: %@", "Public IP: %@", "パブリック IP: %@", "공인 IP: %@",
            "IP publique : %@", "Öffentliche IP: %@", "IP pública: %@", "IP pubblico: %@", "IP público: %@")
        add(.menuBarReadSpeedPrefixFormat, "读取: %@", "讀取: %@", "Read: %@", "読み込み: %@", "읽기: %@",
            "Lecture : %@", "Lesen: %@", "Lectura: %@", "Lettura: %@", "Leitura: %@")
        add(.menuBarRealtimePowerWattsFormat, "实时功率 %.1f W", "實時功率 %.1f W", "Real-time Power %.1f W", "リアルタイム電力 %.1f W", "실시간 소비 전력 %.1f W",
            "Puissance instantanée %.1f W", "Echtzeitleistung %.1f W", "Potencia en tiempo real %.1f W", "Potenza in tempo reale %.1f W", "Potência em tempo real %.1f W")
        add(.menuBarSensorsAndFansTitle, "传感器与风扇", "傳感器與風扇", "Sensors & Fans", "センサーとファン", "센서 및 팬",
            "Capteurs et ventilateurs", "Sensoren & Lüfter", "Sensores y ventiladores", "Sensori e ventole", "Sensores e ventoinhas")
        add(.menuBarSensorsCountSuffixFormat, "共 %d 探头", "共 %d 探頭", "%d Sensors", "計 %d センサー", "총 %d개 센서",
            "%d capteurs au total", "%d Sensoren", "%d sensores en total", "%d sensori totali", "%d sensores no total")
        add(.menuBarStoragePowerTab, "存储与电源", "儲存與電源", "Storage & Power", "ストレージと電源", "저장 장치 및 전원",
            "Stockage et alimentation", "Speicher & Strom", "Almacenamiento y energía", "Archiviazione e alimentazione", "Armazenamento e energia")
        add(.menuBarStoragePressurePrefixFormat, "状态: %@", "狀態: %@", "Status: %@", "ステータス: %@", "상태: %@",
            "État : %@", "Status: %@", "Estado: %@", "Stato: %@", "Status: %@")
        add(.menuBarStorageUsedPercentFormat, "已用 %@ (%d%%)", "已用 %@ (%d%%)", "Used %@ (%d%%)", "使用済み %@ (%d%%)", "사용됨 %@ (%d%%)",
            "Utilisé %@ (%d %%)", "Belegt %@ (%d %%)", "Usado %@ (%d%%)", "Usato %@ (%d%%)", "Usado %@ (%d%%)")
        add(.menuBarStorageUsedSummaryFormat, "已用 %@ · %d%%", "已用 %@ · %d%%", "Used %@ · %d%%", "使用済み %@ · %d%%", "사용됨 %@ · %d%%",
            "Utilisé %@ · %d%%", "Belegt %@ · %d%%", "Usado %@ · %d%%", "Usato %@ · %d%%", "Usado %@ · %d%%")
        add(.menuBarSwapAndPagesHeader, "SWAP & PAGES · 交换分区与磁盘换页活动", "SWAP & PAGES · 交換分區與磁盤換頁活動", "SWAP & PAGES · Swap & Disk Paging Activity", "スワップとページ · スワップ領域とページング活動", "스왑 및 페이징 · 스왑 파티션 및 디스크 페이징 활동",
            "SWAP ET PAGES · Fichier d'échange et pagination", "SWAP & SEITEN · Auslagerungsdatei & Paging-Aktivität", "SWAP Y PÁGINAS · Intercambio y actividad de paginación", "SWAP E PAGINE · File di swap e attività di paging", "SWAP E PÁGINAS · Arquivo de troca e paginação em disco")
        add(.menuBarSwapPartitionLabel, "交换分区", "交換分割區", "Swap Usage", "スワップ使用量", "스왑 공간",
            "Espace d’échange", "Swap-Speicher", "Memoria swap", "Memoria swap", "Memória swap")
        add(.menuBarSystemPeripheralTab, "系统与外围", "系統與周邊", "System & Peripherals", "システムと周辺機器", "시스템 및 주변 장치",
            "Système et périphériques", "System & Peripherie", "Sistema y periféricos", "Sistema e periferiche", "Sistema e periféricos")
        add(.menuBarTemperatureSensorsHeader, "TEMPERATURE SENSORS · 硬件微观传感器矩阵", "TEMPERATURE SENSORS · 硬件微觀傳感器矩陣", "TEMPERATURE SENSORS · Micro-Sensor Matrix", "温度センサー · マイクロセンサーマトリクス", "온도 센서 · 하드웨어 미세 센서 매트릭스",
            "CAPTEURS DE TEMPÉRATURE · Matrice de micro-capteurs", "TEMPERATURSENSOREN · Hardware-Mikrosensoren", "SENSORES DE TEMPERATURA · Matriz de micro-sensores", "SENSORI DI TEMPERATURA · Matrice di micro-sensori", "SENSORES DE TEMPERATURA · Matriz de micro-sensores")
        add(.menuBarTemperatureSensorsMatrixHeader, "温度传感器阵列", "溫度感測器陣列", "Thermal Sensors Matrix", "温度センサーマトリックス", "온도 센서 매트릭스",
            "Matrice des capteurs thermiques", "Temperatursensoren-Matrix", "Matriz de sensores térmicos", "Matrice sensori termici", "Matriz de sensores térmicos")
        add(.menuBarTokenBatteryStacked, "电池电量与实时功率", "電池電量與即時功率", "Battery & Live Power", "バッテリー残量と消費電力", "배터리 및 실시간 전력",
            "Batterie et puissance actuelle", "Akkustand & Leistung", "Batería y consumo en directo", "Batteria e potenza in tempo reale", "Bateria e Potência em Tempo Real")
        add(.menuBarTokenClockStacked, "日期与数字时钟", "日期與數字時鐘", "Date & Digital Clock", "日付とデジタル時計", "날짜 및 디지털 시계",
            "Date et horloge numérique", "Datum & Digitaluhr", "Fecha y reloj digital", "Data e orologio digitale", "Data e Relógio Digital")
        add(.menuBarTokenCpuStacked, "CPU 负载 + 历史微图", "CPU 負載 + 歷史微圖", "CPU Load + Sparkline", "CPU 負荷 + グラフ", "CPU 부하 + 그래프",
            "Charge CPU + mini graphique", "CPU-Last + Verlauf", "Carga de CPU + gráfico", "Carico CPU + grafico", "Carga de CPU + Minigráfico")
        add(.menuBarTokenDiskFreeStacked, "磁盘可用空间", "磁碟可用空間", "Disk Free Space", "空きディスク容量", "디스크 여유 공간",
            "Espace disque disponible", "Freier Festplattenspeicher", "Espacio libre en disco", "Spazio libero su disco", "Espaço Livre em Disco")
        add(.menuBarTokenGpuStacked, "GPU 占用率", "GPU 佔用率", "GPU Usage", "GPU 使用率", "GPU 사용량",
            "Utilisation du GPU", "GPU-Auslastung", "Uso de GPU", "Utilizzo GPU", "Uso da GPU")
        add(.menuBarTokenMemoryStacked, "内存使用率", "記憶體使用率", "Memory Usage", "メモリ使用率", "메모리 사용량",
            "Utilisation de la mémoire", "Speicherauslastung", "Uso de memoria", "Utilizzo memoria", "Uso de Memória")
        add(.menuBarTokenNetworkStacked, "实时上下行网速", "即時上下行網速", "Live Network Speed", "リアルタイム通信速度", "실시간 네트워크 속도",
            "Débit réseau en direct", "Echtzeit-Netzwerkrate", "Velocidad de red en directo", "Velocità di rete live", "Velocidade de Rede em Tempo Real")
        add(.menuBarTokenSensorTempStacked, "芯片温度与风扇转速", "晶片溫度與風扇轉速", "Chip Temp & Fan Speed", "チップ温度とファン速度", "칩셋 온도 및 팬 속도",
            "Température puce et ventilateur", "Chiptemperatur & Lüfterdrehzahl", "Temp. del chip y ventilador", "Temp. chip e velocità ventola", "Temperatura do Chip e Ventoinha")
        add(.menuBarTokenWeatherIconTemp, "天气与实况温度", "天氣與即時溫度", "Weather & Live Temp", "天気と現在温度", "날씨 및 실시간 온도",
            "Météo et température actuelle", "Wetter & Live-Temp", "Clima y temperatura actual", "Meteo e temperatura in tempo reale", "Clima e Temperatura Atual")
        add(.menuBarTokensConfigHint, "勾选复选框决定是否显示在顶部菜单栏，拖拽手柄或列表项即可调整从左到右的展示顺序", "勾選複選框決定是否顯示在頂部菜單欄，拖拽手柄或列表項即可調整從左到右的展示順序", "Select checkboxes to show in menu bar. Drag handle or row to reorder items from left to right", "チェックボックスで表示を切り替え、ドラッグして左から右の表示順序を調整できます", "체크박스를 선택하여 메뉴 막대에 표시하고, 드래그하여 좌우 표시 순서를 조정하세요",
            "Cochez pour afficher dans la barre des menus. Glissez pour réorganiser de gauche à droite", "Checkbox aktivieren, um in der Menüleiste anzuzeigen. Per Drag & Drop von links nach rechts anordnen", "Marque las casillas para mostrar en la barra. Arrastre para reordenar de izquierda a derecha", "Seleziona per mostrare nella barra dei menu. Trascina per riordinare da sinistra a destra", "Marque as caixas para exibir na barra de menus. Arraste para reordenar da esquerda para a direita")
        add(.menuBarTokensCountSuffixFormat, "/ %d 项", "/ %d 項", "/ %d items", "/ %d 項目", "/ %d개 항목",
            "/ %d éléments", "/ %d Elemente", "/ %d elementos", "/ %d elementi", "/ %d itens")
        add(.menuBarTopActiveAppsTitle, "活跃高占用应用", "活躍高佔用應用", "Top Active Applications", "高負荷アクティブアプリ", "상위 활성 애플리케이션",
            "Applications actives principales", "Aktive ressourcenintensive Apps", "Aplicaciones activas principales", "Principali app attive", "Principais aplicativos ativos")
        add(.menuBarTopBandwidthAppsHeader, "TOP BANDWIDTH APPS · 活跃网络进程", "TOP BANDWIDTH APPS · 活躍網絡進程", "TOP BANDWIDTH APPS · Active Network Processes", "帯域幅上位アプリ · アクティブネットワークプロセス", "상위 대역폭 앱 · 활성 네트워크 프로세스",
            "APPLICATIONS À BANDE PASSANTE ÉLEVÉE · Processus actifs", "TOP BANDBREITEN-APPS · Aktive Netzwerkprozesse", "APPS PRINCIPALES DE ANCHO DE BANDA · Procesos activos", "PRINCIPALI APP PER LARGHEZZA DI BANDA · Processi di rete attivi", "PRINCIPAIS APPS DE LARGURA DE BANDA · Processos ativos")
        add(.menuBarTopCpuProcessesHeader, "TOP CPU PROCESSES · 处理器高占用应用", "TOP CPU PROCESSES · 處理器高佔用應用", "TOP CPU PROCESSES · High Processor Usage", "CPU 高負荷プロセス · プロセッサ使用率上位", "상위 CPU 프로세스 · 프로세서 점유율 상위",
            "PROCESSUS CPU PRINCIPAUX · Utilisation processeur élevée", "TOP CPU-PROZESSE · Hohe Prozessorauslastung", "PROCESOS PRINCIPALES DE CPU · Alto uso del procesador", "PRINCIPALI PROCESSI CPU · Elevato uso del processore", "PRINCIPAIS PROCESSOS DA CPU · Alto uso do processador")
        add(.menuBarTopMemoryAppsHeader, "TOP MEMORY APPLICATIONS · 高内存占用应用", "TOP MEMORY APPLICATIONS · 高內存佔用應用", "TOP MEMORY APPLICATIONS · High Memory Usage", "メモリ消費量上位アプリ · 高メモリ使用", "상위 메모리 애플리케이션 · 고메모리 사용",
            "APPLICATIONS PRINCIPALES EN MÉMOIRE · Utilisation élevée", "TOP SPEICHER-APPS · Hohe RAM-Auslastung", "APLICACIONES PRINCIPALES DE MEMORIA · Alto uso de memoria", "PRINCIPALI APPLICAZIONI IN MEMORIA · Elevato utilizzo", "PRINCIPAIS APLICATIVOS DE MEMÓRIA · Alto uso de memória")
        add(.menuBarTotalItemsCountFormat, "%d 项", "%d 項", "%d items", "%d 項目", "%d개 항목",
            "%d éléments", "%d Objekte", "%d elementos", "%d elementi", "%d itens")
        add(.menuBarTotalSystemWattsLabel, "整机功耗", "整機功耗", "Total System Power", "システム総消費電力", "전체 시스템 소비 전력",
            "Puissance totale du système", "Gesamte Systemleistung", "Potencia total del sistema", "Potenza totale del sistema", "Potência total do sistema")
        add(.menuBarUploadSpeedPrefixFormat, "上传 %@", "上傳 %@", "Upload %@", "アップロード %@", "업로드 %@",
            "Téléversement %@", "Upload %@", "Subida %@", "Upload %@", "Upload %@")
        add(.menuBarUploadTxLabel, "上行发送", "上行發送", "Upload (TX)", "送信 (TX)", "업로드 (TX)",
            "Transmission (TX)", "Senden (TX)", "Subida (TX)", "Upload (TX)", "Upload (TX)")
        add(.menuBarVolumeFreeTotalFormat, "可用 %@ / %@", "可用 %@ / %@", "Free %@ / %@", "空き %@ / %@", "여유 공간 %@ / %@",
            "Libre %@ / %@", "Frei %@ / %@", "Libre %@ / %@", "Disponibile %@ / %@", "Livre %@ / %@")
    }

}
