import Foundation

extension LocalizationCatalog {
    static func populateBatch14(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.toolboxSpaceLensCardDesc, "可视化磁盘占用，找出空间去了哪里", "可視化磁盤佔用，找出空間去了哪裡", "Visualize disk space and see where your storage went", "ディスク容量を視覚化し、どこに容量が使われているかを発見", "디스크 용량을 시각화하여 공간을 차지하는 주범 확인",
            "Visualisez l'espace disque pour savoir ce qui occupe votre stockage", "Speicherbelegung visualisieren und Speicherfresser aufspüren", "Visualice el espacio en disco y descubra qué ocupa almacenamiento", "Visualizza lo spazio su disco e scopri cosa occupa lo spazio", "Visualize o espaço em disco e descubra onde seu armazenamento foi usado")
        add(.toolboxStartupItemsCardDesc, "管理开机自动启动的应用程序", "管理開機自動啟動的應用程序", "Manage apps configured to start automatically at login", "ログイン時に自動起動するアプリケーションを管理", "로그인 시 자동으로 실행되는 애플리케이션을 관리",
            "Gérez les applications qui s'ouvrent automatiquement à l'ouverture de session", "Verwalten Sie Apps, die beim Login automatisch starten", "Gestione aplicaciones que se abren automáticamente al iniciar sesión", "Gestisci le applicazioni configurate per aprirsi automaticamente all'accesso", "Gerencie aplicativos configurados para iniciar automaticamente no login")
        add(.toolboxStartupItemsCardTitle, "登录项管理", "登錄項管理", "Login Items", "ログイン項目", "로그인 항목 관리",
            "Éléments d'ouverture", "Anmeldeobjekte", "Elementos de inicio", "Elementi di avvio", "Itens de início de sessão")
        add(.toolboxSystemJunkCardDesc, "清理缓存、日志、语言包与废纸篓", "清理緩存、日誌、語言包與廢紙簍", "Clean caches, logs, localization files, and Trash", "キャッシュ、ログ、言語ファイル、ゴミ箱をクリーンアップ", "캐시, 로그, 다국어 리소스 및 휴지통 정리",
            "Nettoyez les caches, journaux, fichiers de langue et la Corbeille", "Caches, Protokolle, Sprachdateien und Papierkorb leeren", "Limpie cachés, registros, archivos de idioma y la Papelera", "Pulisci cache, log, file di lingua e il Cestino", "Limpe caches, logs, arquivos de idioma e o Lixo")
        add(.toolboxSystemJunkCardTitle, "系统垃圾清理", "系統垃圾清理", "System Junk Cleanup", "システムゴミの掃除", "시스템 정크 정리",
            "Nettoyage du système", "Systemmüll-Bereinigung", "Limpieza de basura del sistema", "Pulizia file spazzatura di sistema", "Limpeza de lixo do sistema")
        add(.toolboxTabAllTools, "全部工具", "全部工具", "All Tools", "すべてのツール", "모든 도구",
            "Tous les outils", "Alle Werkzeuge", "Todas las herramientas", "Tutti gli strumenti", "Todas as ferramentas")
        add(.toolboxTabFavorites, "收藏夹", "收藏夾", "Favorites", "お気に入り", "즐겨찾기",
            "Favoris", "Favoriten", "Favoritos", "Preferiti", "Favoritos")
        add(.toolboxTabMyTools, "我的工具", "我的工具", "My Tools", "マイツール", "내 도구",
            "Mes outils", "Meine Werkzeuge", "Mis herramientas", "I miei strumenti", "Minhas ferramentas")
        add(.tooltipCollapseSidebar, "收起边栏", "收起側邊欄", "Collapse Sidebar", "サイドバーを折りたたむ", "사이드바 접기",
            "Masquer la barre latérale", "Seitenleiste ausblenden", "Ocultar barra lateral", "Nascondi barra laterale", "Recolher Barra Lateral")
        add(.tooltipExpandSidebar, "展开边栏", "展開側邊欄", "Expand Sidebar", "サイドバーを展開", "사이드바 펼치기",
            "Afficher la barre latérale", "Seitenleiste einblenden", "Mostrar barra lateral", "Mostra barra laterale", "Expandir Barra Lateral")
        add(.topFolderConsumesSpaceFormat, "「%@」占用高达 %@ 空间。", "「%@」佔用高達 %@ 空間。", "\"%@\" consumes up to %@ of space.", "「%@」が %@ の容量を占有しています。", "'%@'이(가) 최대 %@의 공간을 차지합니다.",
            "« %@ » occupe jusqu'à %@ d'espace.", "„%@“ belegt bis zu %@ Speicherplatz.", "\"%@\" consume hasta %@ de espacio.", "\"%@\" occupa fino a %@ di spazio.", "\"%@\" consome até %@ de espaço.")
        add(.total, "共", "共", "Total", "合計", "총",
            "Total", "Gesamt", "Total", "Totale", "Total")
        add(.totalControlOverYourApplications, "全面掌控你的应用程序", "全面掌控你的應用程式", "Total Control Over Your Applications", "アプリケーションを自在に管理", "응용 프로그램을 완벽하게 관리",
            "Maîtrisez pleinement vos applications", "Volle Kontrolle über Ihre Programme", "Control total sobre tus aplicaciones", "Controllo completo delle tue applicazioni", "Controle Total sobre Seus Aplicativos")
        add(.totalLoad, "当前总负载", "目前總負載", "Current Total Load", "現在の合計負荷", "현재 총 부하",
            "Charge totale actuelle", "Gesamtauslastung aktuell", "Carga total actual", "Carico totale attuale", "Carga Total Atual")
        add(.totalSelectedCountAndSizeFormat, "共 %d 项 · %@", "共 %d 項 · %@", "%d items total · %@", "合計 %d 項目 · %@", "총 %d개 항목 · %@",
            "%d éléments au total · %@", "%d Elemente gesamt · %@", "%d elementos en total · %@", "%d elementi totali · %@", "%d itens no total · %@")
        add(.totalSizeOfCategoryOnMacFormat, "您的 Mac 上有 %@ 的%@项目。", "您的 Mac 上有 %@ 的%@項目。", "Your Mac has %@ of %@ items.", "お使いの Mac に %@ の %@ 項目があります。", "Mac에 %@의 %@ 항목이 있습니다.",
            "Votre Mac contient %@ d'éléments de %@.", "Auf Ihrem Mac befinden sich %@ an %@-Elementen.", "Su Mac tiene %@ de elementos de %@.", "Il tuo Mac contiene %@ di elementi di %@.", "Seu Mac tem %@ em itens de %@.")
        add(.totalSizeSlashFormat, "/ 共 %@", "/ 共 %@", "/ Total %@", "/ 合計 %@", "/ 총 %@",
            "/ Total %@", "/ Gesamt %@", "/ Total %@", "/ Totale %@", "/ Total %@")
        add(.trendLabel, "走势", "走勢", "Trend", "推移", "동향",
            "Tendance", "Trend", "Tendencia", "Tendenza", "Tendência")
        add(.triggerApfsPurgeableSpaceReclaim, "触发系统可清除空间回收", "觸發系統可清除空間回收", "Trigger APFS Purgeable Space Reclaim", "システムパージ可能領域の回収を実行", "시스템 확보 가능 공간 회수 트리거",
            "Déclencher la récupération d’espace purgeable APFS", "APFS-Speicherplatzbereinigung auslösen", "Activar recuperación de espacio purgable de APFS", "Attiva recupero spazio eliminabile APFS", "Disparar Recuperação de Espaço Purgável APFS")
        add(.tryDifferentKeywordsPrompt, "请更换关键词并重试。", "請更換關鍵詞並重試。", "Please try searching with different keywords.", "別のキーワードで検索をお試しください。", "다른 키워드로 다시 검색해 보세요.",
            "Veuillez essayer avec d'autres mots-clés.", "Bitte versuchen Sie es mit anderen Suchbegriffen.", "Intente realizar la búsqueda con otras palabras clave.", "Prova a effettuare la ricerca con parole chiave diverse.", "Tente pesquisar com palavras-chave diferentes.")
        add(.ubiquitousButtonOutOfTotalSizeFormat, "/ 共 %@", "/ 共 %@", "/ Total %@", "/ 合計 %@", "/ 총 %@",
            "/ Total %@", "/ Gesamt %@", "/ Total %@", "/ Totale %@", "/ Total %@")
        add(.unexpandedDirectSmallItemsFormat, "未单独展开的直属小文件与细碎项（%@）", "未單獨展開的直屬小檔案與零碎項目（%@）", "Direct small items not individually expanded (%@)", "個別に展開されていない小さな項目（%@）", "개별적으로 확장되지 않은 작은 항목 (%@)",
            "Petits éléments directs non développés individuellement (%@)", "Direkte kleine Objekte, nicht einzeln erweitert (%@)", "Elementos pequeños directos no expandidos (%@)", "Piccoli elementi diretti non espansi (%@)", "Pequenos itens diretos não expandidos (%@)")
        add(.unitApps, "个 App", "個 App", " Apps", " 個のアプリ", "개 앱",
            " apps", " Apps", " apps", " app", " apps")
        add(.unitCategories, "类", "類", "categories", "種類", "개 분류",
            "catégories", "Kategorien", "categorías", "categorie", "categorias")
        add(.unitCount, "个", "個", "items", "個", "개",
            "éléments", "Objekte", "elementos", "elementi", "itens")
        add(.unitDataFiles, "数据文件", "資料檔案", "Data Files", "データファイル", "데이터 파일",
            "Fichiers de données", "Datendateien", "Archivos de datos", "File di dati", "Arquivos de dados")
        add(.unitFiles, "文件", "檔案", "Files", "ファイル", "파일",
            "Fichiers", "Dateien", "Archivos", "File", "Arquivos")
        add(.unitItems, "项", "項", "items", "項目", "개 항목",
            "éléments", "Elemente", "elementos", "elementi", "itens")
        add(.unitMonths, "个月", "個月", " months", " か月", "개월",
            " mois", " Monate", " meses", " mesi", " meses")
        add(.unitTotalFiles, "文件合计", "檔案合計", "Total Files", "ファイル合計", "파일 합계",
            "Total des fichiers", "Dateien gesamt", "Total de archivos", "Totale file", "Total de arquivos")
        add(.universalClipboard, "通用剪贴板", "通用剪貼板", "Universal Clipboard", "ユニバーサルクリップボード", "공통 클립보드",
            "Presse-papiers universel", "Allgemeine Zwischenablage", "Portapapeles universal", "Appunti condivisi", "Área de Transferência Universal")
        add(.unsupported32BitAppsDesc, "旧的 32 位版本应用程序无法在您的操作系统上运行。卸载它们可以释放存储空间。", "舊的 32 位元版本應用程式無法在您的作業系統上運行。卸載它們可以釋放儲存空間。", "Older 32-bit apps cannot run on your macOS version. Uninstalling them reclaims storage.", "32ビットの旧式アプリケーションはお使いの macOS では起動できません。アンインストールして空き容量を確保できます。", "이전 32비트 앱은 최신 macOS에서 실행할 수 없습니다. 삭제하면 저장 공간을 확보할 수 있습니다.",
            "Les anciennes applications 32 bits ne fonctionnent pas sur votre macOS. Désinstallez-les pour libérer de l'espace.", "Ältere 32-Bit-Apps können nicht ausgeführt werden. Durch Deinstallation wird Speicherplatz frei.", "Las apps de 32 bits antiguas no funcionan en su macOS. Desinstálelas para ganar espacio.", "Le vecchie app a 32 bit non funzionano sul tuo macOS. Disinstallale per recuperare spazio.", "Aplicativos antigos de 32 bits não funcionam no seu macOS. Desinstale-os para liberar espaço.")
        add(.unusedAppsDesc, "这些应用程序您或许早已不再使用，却持续占用着 Mac 的存储空间。", "這些應用程式您或許早已不再使用，卻持續佔用著 Mac 的儲存空間。", "You might no longer need these applications, yet they continue to consume storage.", "長い間使われておらず、Mac のストレージを消費し続けているアプリケーションです。", "오랫동안 사용하지 않았지만 여전히 Mac의 저장 공간을 차지하고 있는 앱들입니다.",
            "Vous n'utilisez peut-être plus ces applications, mais elles occupent toujours de l'espace.", "Diese Anwendungen werden möglicherweise nicht mehr benötigt, belegen aber weiterhin Speicherplatz.", "Quizá ya no use estas aplicaciones, pero siguen ocupando espacio en el Mac.", "Forse non usi più queste applicazioni, eppure continuano a occupare spazio su disco.", "Você pode não usar mais esses aplicativos, mas eles continuam ocupando espaço valioso.")
        add(.updatableAppsDesc, "这些应用程序内置了更新通道。点按「检查」查看各自通过何种方式获取更新。", "這些應用程式內置了更新通道。點按「檢查」查看各自通過何種方式獲取更新。", "These applications have dedicated update channels. Click Inspect to review them.", "これらのアプリにはアップデートチャネルが備わっています。「詳細」をクリックして確認してください。", "해당 앱에는 업데이트 채널이 포함되어 있습니다. '확인'을 클릭하여 업데이트 방식을 확인하세요.",
            "Ces applications intègrent un canal de mise à jour. Cliquez sur Vérifier pour plus de détails.", "Diese Anwendungen bieten eigene Update-Kanäle. Klicken Sie auf Prüfen, um Details anzuzeigen.", "Estas apps tienen canales de actualización integrados. Haga clic en Revisar para ver los detalles.", "Queste applicazioni includono canali di aggiornamento. Fai clic su Esamina per i dettagli.", "Esses aplicativos possuem canais de atualização dedicados. Clique em Inspecionar para verificar.")
        add(.upload, "上传", "上傳", "Upload", "アップロード", "업로드",
            "Envoi", "Upload", "Subida", "Caricamento", "Envio")
        add(.uploadLabel, "上传", "上傳", "Upload", "アップロード", "업로드",
            "Envoi", "Upload", "Subida", "Caricamento", "Upload")
        add(.uptimeDaysHoursFormat, "已运行 %d天 %d小时 · %@", "已運行 %d天 %d小時 · %@", "Running %dd %dh · %@", "%d日 %d時間 稼働中 · %@", "%d일 %d시간 실행 중 · %@",
            "En service depuis %dj %dh · %@", "Läuft seit %d T. %d Std. · %@", "En ejecución: %d d %d h · %@", "In esecuzione da %dg %do · %@", "Em execução há %dd %dh · %@")
        add(.uptimeHoursMinsFormat, "已运行 %d小时 %d分 · %@", "已運行 %d小時 %d分 · %@", "Running %dh %dm · %@", "%d時間 %d分 稼働中 · %@", "%d시간 %d분 실행 중 · %@",
            "En service depuis %dh %dm · %@", "Läuft seit %d Std. %d Min. · %@", "En ejecución: %d h %d m · %@", "In esecuzione da %do %dm · %@", "Em execução há %dh %dm · %@")
        add(.usbDevice, "USB 设备", "USB 裝置", "USB Device", "USB デバイス", "USB 장치",
            "Appareil USB", "USB-Gerät", "Dispositivo USB", "Dispositivo USB", "Dispositivo USB")
        add(.usedCapacity, "已用容量", "已用容量", "Used Space", "使用済み容量", "사용된 용량",
            "Espace utilisé", "Belegter Speicherplatz", "Espacio usado", "Spazio occupato", "Espaço Usado")
        add(.usedLabel, "已用", "已用", "Used", "使用中", "사용됨",
            "Utilisé", "Belegt", "Usado", "Usato", "Usado")
        add(.userAgent, "用户代理", "使用者代理", "User Agent", "ユーザーエージェント", "사용자 에이전트",
            "Agent utilisateur", "Benutzer-Agent", "Agente de usuario", "Agente utente", "Agente do Usuário")
        add(.userAgents, "用户代理", "使用者代理", "User Agents", "ユーザーエージェント", "사용자 에이전트",
            "Agents utilisateur", "Benutzer-Agenten", "Agentes de usuario", "Agenti utente", "Agentes do usuário")
        add(.userAgentsDesc, "当前用户登录时运行的代理程序。", "目前使用者登入時執行的代理程式。", "Agents that run when the current user logs in.", "現在のユーザーのログイン時に実行されるエージェント。", "현재 사용자가 로그인할 때 실행되는 에이전트 프로그램입니다.",
            "Agents exécutés lors de la connexion de l'utilisateur actuel.", "Agenten, die bei der Anmeldung des aktuellen Benutzers ausgeführt werden.", "Agentes que se ejecutan cuando el usuario actual inicia sesión.", "Agenti eseguiti all'accesso dell'utente corrente.", "Agentes executados quando o usuário atual inicia sessão.")
        add(.userDataOrConfig, "含配置/用户数据", "含設定/使用者資料", "User Data / Config", "設定・ユーザーデータ", "설정/사용자 데이터",
            "Données utilisateur", "Benutzerdaten", "Datos de usuario", "Dati utente", "Dados do Usuário")
        add(.userPrefix, "用户", "使用者", "User", "ユーザー", "사용자",
            "Utilisateur", "Benutzer", "Usuario", "Utente", "Usuário")
        add(.userScope, "用户", "使用者", "User", "ユーザー", "사용자",
            "Utilisateur", "Benutzer", "Usuario", "Utente", "Usuário")
        add(.usingCacheTag, "占用缓存", "佔用快取", "using cache", "がキャッシュを使用中", "캐시 사용 중",
            "utilisent le cache", "nutzen Cache", "usando caché", "usano la cache", "usando cache")
        add(.verbCleaned, "已清理", "已清理", "Cleaned", "クリーンアップ済み", "정리됨",
            "Nettoyé", "Bereinigt", "Limpiado", "Pulito", "Limpo")
        add(.verbDiscovered, "已找到", "已找到", "Found", "検出済み", "발견됨",
            "Trouvé", "Gefunden", "Encontrado", "Trovato", "Encontrado")
        add(.verbFound, "已发现", "已發現", "Found", "検出済み", "발견됨",
            "Trouvé", "Gefunden", "Encontrado", "Trovato", "Encontrado")
        add(.verbFreed, "已释放", "已釋放", "Freed", "解放済み", "확보됨",
            "Libéré", "Freigegeben", "Liberado", "Liberato", "Liberado")
        add(.verifyAndRepairDiskPermissions, "磁盘权限校验与修复", "磁碟權限校驗與修復", "Verify & Repair Disk Permissions", "ディスクボリュームの検証と修復", "디스크 볼륨 검증 및 복구",
            "Vérifier et réparer les autorisations du disque", "Festplattenberechtigungen prüfen & reparieren", "Verificar y reparar permisos del disco", "Verifica e ripara permessi disco", "Verificar e Reparar Permissões do Disco")
        add(.viewAllCategoryFilesFormat, "查看所有%@文件", "查看所有%@檔案", "View all %@ files", "すべての %@ ファイルを表示", "모든 %@ 파일 보기",
            "Voir tous les fichiers de %@", "Alle %@-Dateien anzeigen", "Ver todos los archivos de %@", "Visualizza tutti i file di %@", "Ver todos os arquivos de %@")
        add(.viewAllowedBackgroundProcessesDesc, "查看允许在 Mac 电脑上运行的后台进程。", "查看允許在 Mac 電腦上運行的後台進程。", "Review background processes permitted to run on your Mac.", "お使いの Mac で実行が許可されているバックグラウンドプロセスを確認。", "Mac에서 실행이 허용된 백그라운드 프로세스를 검토합니다.",
            "Examinez les processus en arrière-plan autorisés sur votre Mac.", "Überprüfen Sie Hintergrundprozesse, die auf Ihrem Mac ausgeführt werden dürfen.", "Revise los procesos en segundo plano permitidos en su Mac.", "Esamina i processi in background autorizzati sul tuo Mac.", "Revise os processos em segundo plano permitidos no seu Mac.")
        add(.viewOnly, "仅查看", "僅檢視", "View Only", "閲覧のみ", "보기 전용",
            "Lecture seule", "Nur anzeigen", "Solo ver", "Sola lettura", "Somente Visualização")
        add(.viewStartupAppsDesc, "查看在 Mac 开机时自动启动的应用程序。您可能希望禁用其中的一些自动启动。", "查看在 Mac 開機時自動啟動的應用程式。您可能希望禁用其中的一些自動啟動。", "Review applications that launch automatically when your Mac starts up. You may want to disable some of them.", "Mac の起動時に自動実行されるアプリを確認します。不要な項目の自動起動を無効化できます。", "Mac 시작 시 자동으로 실행되는 애플리케이션을 검토합니다. 불필요한 자동 실행을 비활성화할 수 있습니다.",
            "Examinez les applications lancées au démarrage de votre Mac. Vous pouvez en désactiver certaines.", "Überprüfen Sie Anwendungen, die beim Start Ihres Mac automatisch starten. Einige können deaktiviert werden.", "Revise las aplicaciones que se inician al encender el Mac. Puede desactivar las que no necesite.", "Esamina le app che si avviano all'accensione del Mac. Puoi disabilitarne l'avvio automatico.", "Revise os aplicativos que iniciam com o Mac. Você pode desativar inicializações desnecessárias.")
        add(.visualizingStorageSpacePrompt, "正在可视化存储空间…", "正在可視化存儲空間…", "Visualizing storage space…", "ストレージ空間を視覚化中…", "저장 공간을 시각화하는 중…",
            "Visualisation de l'espace de stockage…", "Speicherplatz wird visualisiert…", "Visualizando el espacio de almacenamiento…", "Visualizzazione dello spazio di archiviazione in corso…", "Visualizando o espaço de armazenamento…")
        add(.weather, "天气", "天氣", "Weather", "天気", "날씨",
            "Météo", "Wetter", "Tiempo", "Meteo", "Tempo")
        add(.weatherCheckConnectionOrManualPrompt, "请检查网络连接，或点击上方城市栏手动输入城市名称。", "請檢查網絡連接，或點擊上方城市欄手動輸入城市名稱。", "Please check your network connection, or search for a city above.", "ネットワーク接続を確認するか、上部の検索バーから都市名を入力してください。", "네트워크 연결을 확인하거나 상단 도시 검색창에 도시명을 직접 입력해 보세요.",
            "Vérifiez votre connexion Internet ou recherchez une ville ci-dessus.", "Bitte Internetverbindung prüfen oder oben manuell eine Stadt eingeben.", "Compruebe la conexión de red o introduzca una ciudad arriba.", "Verifica la connessione o cerca manualmente una città in alto.", "Verifique sua conexão com a Internet ou digite uma cidade acima.")
        add(.weatherCheckNetworkOrManualPrompt, "请检查网络连接，或点击上方城市栏手动输入城市名称。", "請檢查網路連線，或點選上方城市列手動輸入城市名稱。", "Please check your network connection, or search for a city manually above.", "ネットワーク接続を確認するか、上のバーから都市名を入力してください。", "네트워크 연결을 확인하거나 상단 도시 검색창에 직접 입력하세요.",
            "Veuillez vérifier votre connexion réseau ou rechercher une ville ci-dessus.", "Bitte Netzwerkverbindung prüfen oder oben manuell eine Stadt eingeben.", "Comprueba tu conexión de red o busca manualmente una ciudad arriba.", "Controlla la connessione di rete o cerca manualmente una città in alto.", "Verifique sua conexão de rede ou pesquise uma cidade acima manualmente.")
        add(.weatherDataNotAvailablePrompt, "暂未获取到实时气象数据", "暫未獲取到實時氣象數據", "Live weather data not currently available", "気象データを取得できませんでした", "실시간 날씨 데이터를 아직 가져오지 못했습니다",
            "Données météo en direct non disponibles", "Derzeit keine Live-Wetterdaten verfügbar", "Datos meteorológicos no disponibles actualmente", "Dati meteo al momento non disponibili", "Dados meteorológicos em tempo real não disponíveis no momento")
        add(.weatherFetchingFromIpPrompt, "正在通过公网 IP 定位并拉取 Open-Meteo 实时气象数据…", "正在通過公網 IP 定位並拉取 Open-Meteo 實時氣象數據…", "Locating via IP and fetching live weather from Open-Meteo…", "IP アドレスから位置情報を特定し、気象データを取得中…", "공인 IP로 위치를 확인하고 실시간 기상 데이터를 수신하는 중…",
            "Localisation par IP et récupération de la météo en direct…", "Ermittle Standort per IP und lade Wetterdaten…", "Localizando por IP y obteniendo datos meteorológicos en directo…", "Localizzazione tramite IP e recupero del meteo in diretta…", "Localizando por IP e obtendo dados meteorológicos em tempo real…")
        add(.weatherFetchingFromNetworkPrompt, "正在通过公网 IP 定位并拉取 Open-Meteo 实时气象数据…", "正在透過公網 IP 定位並拉取 Open-Meteo 即時氣象資料…", "Locating via public IP and fetching Open-Meteo weather data…", "パブリック IP から位置を特定し、Open-Meteo 気象データを取得中…", "공인 IP로 위치를 파악하고 Open-Meteo 실시간 기상 데이터를 불러오는 중…",
            "Localisation via IP publique et récupération des données Open-Meteo…", "Standort wird per öffentlicher IP ermittelt und Open-Meteo-Wetterdaten geladen…", "Localizando por IP pública y obteniendo datos de Open-Meteo…", "Localizzazione tramite IP pubblico e download dei dati meteo Open-Meteo…", "Localizando via IP público e obtendo dados meteorológicos do Open-Meteo…")
        add(.weatherLiveTempFormat, "实况 %.1f°C · 悬停查看周预报", "即時 %.1f°C · 懸停查看週預報", "Live %.1f°C · Hover for forecast", "現在 %.1f°C · ホバーで週間予報", "현재 %.1f°C · 마우스를 올려 예보 보기",
            "En direct %.1f°C · Survoler pour la météo", "Live %.1f°C · Für Wetterbericht bewegen", "En vivo %.1f°C · Pase el ratón para pronóstico", "In tempo reale %.1f°C · Passa il mouse per previsioni", "Tempo real %.1f°C · Passe o mouse para previsão")
        add(.weatherLocatingEllipsis, "天气定位中…", "天氣定位中…", "Locating weather…", "気象位置を取得中…", "날씨 위치 확인 중…",
            "Localisation météo…", "Wetterstandort wird ermittelt…", "Localizando el tiempo…", "Localizzazione meteo…", "Localizando clima…")
        add(.weatherNoRealtimeDataPrompt, "暂未获取到实时气象数据", "暫未獲取到即時氣象資料", "No Real-Time Weather Data Available", "気象データを取得できませんでした", "실시간 기상 데이터를 가져오지 못했습니다",
            "Aucune donnée météo en temps réel", "Keine Echtzeit-Wetterdaten verfügbar", "No hay datos meteorológicos en tiempo real", "Nessun dato meteo in tempo reale disponibile", "Sem Dados Meteorológicos em Tempo Real")
        add(.weatherRefreshNowTooltip, "立即刷新实时天气", "立即重新整理即時天氣", "Refresh Real-time Weather", "天気を今すぐ更新", "실시간 날씨 새로고침",
            "Actualiser la météo en direct", "Echtzeit-Wetter jetzt aktualisieren", "Actualizar tiempo en tiempo real", "Aggiorna meteo in tempo reale", "Atualizar Clima em Tempo Real")
        add(.weatherRetryFetchPrompt, "立即重新联网获取", "立即重新聯網取得", "Retry Network Fetch", "再試行して取得", "네트워크에서 다시 가져오기",
            "Réessayer la récupération", "Erneut abrufen", "Reintentar conexión", "Riprova connessione", "Tentar Obter Novamente")
        add(.weatherSearchCityPlaceholder, "输入城市名 (如 广州 / Beijing / Tokyo)…", "輸入城市名 (如 台北 / Tokyo / London)…", "Enter city name (e.g. London / Tokyo / Paris)…", "都市名を入力 (例: Tokyo / London / Paris)…", "도시 이름 입력 (예: Seoul / Tokyo / London)…",
            "Nom de ville (ex. Paris / Londres / Tokyo)…", "Stadt eingeben (z. B. Berlin / Tokio / London)…", "Nombre de ciudad (ej. Madrid / Tokio / París)…", "Nome della città (es. Roma / Tokyo / Londra)…", "Digite a cidade (ex: São Paulo / Tóquio / Londres)…")
        add(.weatherSearchingCityCoordinatesPrompt, "搜索全球城市坐标中…", "搜索全球城市坐標中…", "Searching global city coordinates…", "世界の都市座標を検索中…", "전 세계 도시 좌표 검색 중…",
            "Recherche des coordonnées de la ville…", "Suche weltweite Stadtkoordinaten…", "Buscando coordenadas de ciudades globales…", "Ricerca coordinate delle città globali…", "Pesquisando coordenadas de cidades globais…")
        add(.weatherSearchingGlobalCoordsPrompt, "搜索全球城市坐标中…", "搜尋全球城市座標中…", "Searching global coordinates…", "都市の座標を検索中…", "전 세계 도시 좌표 검색 중…",
            "Recherche des coordonnées géographiques…", "Globale Koordinaten werden gesucht…", "Buscando coordenadas de ciudades…", "Ricerca coordinate geografiche…", "Buscando coordenadas globais…")
        add(.weatherWeeklyForecast, "最近一周天气预报", "最近一週天氣預報", "7-Day Weather Forecast", "週間天気予報", "주간 날씨 예보",
            "Prévisions météo 7 jours", "7-Tage-Wetterbericht", "Pronóstico de 7 días", "Previsioni meteo 7 giorni", "Previsão do Tempo de 7 Dias")
        add(.weekly, "每周", "每周", "Weekly", "毎週", "매주",
            "Toutes les semaines", "Wöchentlich", "Semanalmente", "Ogni settimana", "Semanalmente")
        add(.weeklyRecommendedMaintenanceTasksReadyDesc, "每周为您推荐的一组维护任务现已准备就绪！运行这些任务以让您的 Mac 保持状态良好。", "每週為您推薦的一組維護任務現已準備就緒！執行這些任務以讓您的 Mac 保持良好狀態。", "Your weekly set of recommended maintenance tasks is ready! Run them to keep your Mac in top condition.", "毎週おすすめのメンテナンスタスクが準備完了しました！実行して Mac を快適に保ちましょう。", "주간 권장 유지 관리 작업이 준비되었습니다! 작업을 실행하여 Mac을 최적의 상태로 유지하세요.",
            "Votre ensemble hebdomadaire de tâches de maintenance est prêt ! Exécutez-les pour garder votre Mac au top.", "Ihre wöchentlich empfohlenen Wartungsaufgaben sind bereit! Führen Sie sie aus, um Ihren Mac in Bestform zu halten.", "¡Tu conjunto semanal de tareas de mantenimiento está listo! Ejecútalas para mantener tu Mac en óptimas condiciones.", "Il set settimanale di attività di manutenzione è pronto! Eseguile per mantenere il Mac al meglio.", "Seu conjunto semanal de tarefas de manutenção está pronto! Execute-as para manter seu Mac em ótimo estado.")
        add(.writePrefix, "写入", "寫入", "Write", "書き込み", "쓰기",
            "Écriture", "Schreiben", "Escritura", "Scrittura", "Gravação")
        add(.xcodeBuildDataDockerImagesAndBackupsRequiresSecondaryConfirmation, "Xcode 编译缓存、Docker 镜像、备份，必须二次确认", "Xcode 編譯快取、Docker 鏡像、備份，必須二次確認", "Xcode build data, Docker images & backups; requires secondary confirmation", "Xcode ビルドキャッシュ、Docker イメージ、バックアップ。必ず再確認します", "Xcode 빌드 캐시, Docker 이미지, 백업 파일. 반드시 2차 확인 진행",
            "Données de compilation Xcode, images Docker et sauvegardes ; double confirmation requise", "Xcode-Build-Daten, Docker-Images & Backups; doppelte Bestätigung zwingend", "Cachés de compilación de Xcode, imágenes de Docker y copias de seguridad; doble confirmación requerida", "Cache di compilazione Xcode, immagini Docker e backup; conferma obbligatoria", "Dados de build do Xcode, imagens do Docker e backups; dupla confirmação obrigatória")
        add(.xcodeDeveloperData, "Xcode 开发者垃圾", "Xcode 開發者快取", "Xcode Developer Data", "Xcode開発キャッシュ", "Xcode 개발자 데이터",
            "Données Xcode", "Xcode-Entwicklerdaten", "Datos de Xcode", "Dati sviluppatore Xcode", "Dados do Xcode")
        add(.xcodeJunk, "Xcode 垃圾", "Xcode 垃圾", "Xcode Junk", "Xcodeジャンク", "Xcode 정크",
            "Fichiers inutiles Xcode", "Xcode-Datenreste", "Basura de Xcode", "File inutili di Xcode", "Lixo do Xcode")
        add(.xcodeSwiftpmNodeJsAndBuildCachesFirstBuildAfterCleaningMayBeSlightlySlower, "Xcode、SwiftPM、Node.js 等工具的缓存，清理后首次构建会稍慢", "Xcode、SwiftPM、Node.js 等工具的快取，清理後首次建置會稍慢", "Xcode, SwiftPM, Node.js, and build caches; first build after cleaning may be slightly slower", "Xcode、SwiftPM、Node.js などのキャッシュ（削除後の初回ビルドは少し時間がかかります）", "Xcode, SwiftPM, Node.js 등의 빌드 캐시 (정리 후 첫 빌드가 약간 느려질 수 있음)",
            "Caches Xcode, SwiftPM, Node.js ; la première compilation sera un peu plus lente", "Xcode-, SwiftPM- und Node.js-Caches; der erste Build danach dauert etwas länger", "Cachés de Xcode, SwiftPM y Node.js; la primera compilación será algo más lenta", "Cache di Xcode, SwiftPM e Node.js; la prima compilazione sarà leggermente più lenta", "Caches do Xcode, SwiftPM e Node.js; a primeira compilação será um pouco mais lenta")
        add(.yearsAgo, "年前", "年前", "years ago", "年前", "년 전",
            "ans plus tôt", "Jahre her", "años atrás", "anni fa", "anos atrás")
        add(.yesterday, "昨天", "昨天", "Yesterday", "昨日", "어제",
            "Hier", "Gestern", "Ayer", "Ieri", "Ontem")
        add(.yourMacIsAtPeakPerformance, "您的 Mac 电脑处于最佳状态！", "您的 Mac 電腦處於最佳狀態！", "Your Mac is in peak condition!", "お使いの Mac は最適な状態です！", "Mac이 최상의 상태입니다!",
            "Votre Mac est en parfait état !", "Ihr Mac ist in Bestform!", "¡Tu Mac está en óptimas condiciones!", "Il tuo Mac è in condizioni ottimali!", "Seu Mac está em ótimas condições!")
        add(.yourMacIsClean, "您的 Mac 非常干净", "您的 Mac 非常乾淨", "Your Mac is clean", "Macはクリーンな状態です", "Mac이 깨끗한 상태입니다",
            "Votre Mac est propre", "Ihr Mac ist sauber", "Tu Mac está limpio", "Il tuo Mac è pulito", "Seu Mac está limpo")
        add(.yourMacIsCrystalClean, "您的 Mac 电脑非常干净！", "您的 Mac 電腦非常乾淨！", "Your Mac is crystal clean!", "お使いの Mac はとてもクリーンです！", "Mac이 매우 깨끗합니다!",
            "Votre Mac est parfaitement propre !", "Ihr Mac ist blitzsauber!", "¡Tu Mac está impecable!", "Il tuo Mac è pulitissimo!", "Seu Mac está limpo e impecável!")
        add(.zeroAppsSelectedHint, "已勾选 0 个应用程序 · 点击任意应用可展开查看各关联文件夹的具体用途", "已勾選 0 個應用程序 · 點擊任意應用可展開查看各關聯文件夾的具體用途", "0 apps selected · Click any app to expand and inspect folder purposes", "0 個のアプリを選択中 · 任意のアプリをクリックすると関連フォルダの詳細を展開できます", "0개 앱 선택됨 · 앱을 클릭하여 관련 폴더의 용도를 펼쳐볼 수 있습니다",
            "0 application sélectionnée · Cliquez sur une application pour inspecter ses dossiers", "0 Apps ausgewählt · Klicken Sie auf eine App, um Verwendungszwecke anzuzeigen", "0 apps seleccionadas · Haga clic en una app para inspeccionar el propósito de las carpetas", "0 app selezionate · Fai clic su un'app per visualizzare lo scopo delle cartelle", "0 apps selecionados · Clique em qualquer app para ver o propósito das pastas")
        add(.cleanSkippedProtected, "已跳过（系统必需/受保护）", "已跳過（系統必需/受保護）", "Skipped (System Required / Protected)", "スキップ（システム必須・保護対象）", "건너뜀 (시스템 필수/보호됨)",
            "Ignoré (requis par le système / protégé)", "Übersprungen (Systemerforderlich / Geschützt)", "Omitido (requerido por el sistema / protegido)", "Ignorato (richiesto dal sistema / protetto)", "Ignorado (necessário para o sistema / protegido)")
        add(.errorRedlineBinaryModification, "安全架构红线：禁止在位修改应用二进制或精简架构", "安全架構紅線：禁止在位修改應用二進位或精簡架構", "Security redline: in-place binary modification or architecture thinning is prohibited", "セキュリティ制限：アプリバイナリのインプレース変更やアーキテクチャ削減は禁止されています", "보안 원칙: 앱 바이너리 직접 수정 및 아키텍처 축소는 금지되어 있습니다",
            "Sécurité : modification binaire sur place interdite", "Sicherheitsrichtlinie: In-Place-Binäränderung untersagt", "Seguridad: prohibida la modificación binaria in situ", "Sicurezza: modifica binaria sul posto vietata", "Segurança: modificação binária in-loco proibida")
        add(.failedToMoveToTrashPermissionNeeded, "移入废纸篓失败（可能需要完全磁盘访问权限或目标被锁定）", "移到垃圾桶失敗（可能需要完全磁碟取用權限或目標已鎖定）", "Failed to move to Trash (Full Disk Access may be required or item is locked)", "ゴミ箱への移動に失敗しました（フルディスクアクセス権限が必要か、ロックされています）", "휴지통으로 이동 실패 (전체 디스크 접근 권한이 필요하거나 잠겨 있음)",
            "Échec du déplacement vers la corbeille (Accès complet au disque requis)", "Verschieben in den Papierkorb fehlgeschlagen (Festplattenvollzugriff erforderlich)", "Error al mover a la papelera (se requiere acceso total al disco)", "Impossibile spostare nel Cestino (richiesto Accesso completo al disco)", "Falha ao mover para o Lixo (Acesso Total ao Disco necessário)")
        add(.noteKeepOriginal, "将保留", "將保留", "Keep Original", "保持", "유지됨",
            "Conserver l'original", "Original behalten", "Conservar original", "Mantieni originale", "Manter original")
        add(.statusDetecting, "定位中…", "定位中…", "Detecting...", "検出中…", "감지 중…",
            "Détection…", "Erkennung…", "Detectando…", "Rilevamento…", "Detectando…")
        add(.statusCompleted, "已完成", "已完成", "Completed", "完了", "완료됨",
            "Terminé", "Abgeschlossen", "Completado", "Completato", "Concluído")
        add(.cardHeightCompact, "紧凑 (矮)", "緊湊 (矮)", "Compact (Short)", "コンパクト", "컴팩트",
            "Compact", "Kompakt", "Compacto", "Compatto", "Compacto")
        add(.cardHeightStandard, "标准 (中)", "標準 (中)", "Standard (Medium)", "標準", "표준",
            "Standard", "Standard", "Estándar", "Standard", "Padrão")
        add(.cardHeightExpanded, "展开 (高)", "展開 (高)", "Expanded (Tall)", "詳細", "상세",
            "Étendu", "Erweitert", "Expandido", "Espanso", "Expandido")
        add(.cardHeightAlignAll, "卡片高度", "卡片高度", "Card Height", "カードの高さ", "카드 높이",
            "Hauteur des cartes", "Kartenhöhe", "Altura de tarjeta", "Altezza scheda", "Altura do Cartão")
        add(.cardHeightAlignPrompt, "统一卡片高度档位", "統一卡片高度檔位", "Align Card Heights", "カードの高さを揃える", "카드 높이 정렬",
            "Aligner la hauteur des cartes", "Kartenhöhen ausrichten", "Alinear alturas de tarjetas", "Allinea altezza schede", "Alinhar altura dos cartões")
        add(.visualMode, "可视化模式", "可視化模式", "Visual Mode", "可視化モード", "시각화 모드",
            "Mode visuel", "Visueller Modus", "Modo visual", "Modalità visiva", "Modo visual")
        add(.otherItemsCountFormat, "其他 %d 项", "其他 %d 項", "Other %d items", "その他 %d 項目", "기타 %d 개",
            "Autres %d éléments", "Weitere %d Elemente", "Otros %d elementos", "Altri %d elementi", "Outros %d itens")
        add(.folderAndFileSummaryFormat, "%d 文件夹 %d 文件 | 共 %@", "%d 資料夾 %d 檔案 | 共 %@", "%d Folders, %d Files | Total %@", "%d フォルダ %d ファイル | 合計 %@", "%d개 폴더 %d개 파일 | 총 %@",
            "%d dossiers, %d fichiers | Total %@", "%d Ordner, %d Dateien | Gesamt %@", "%d carpetas, %d archivos | Total %@", "%d cartelle, %d file | Totale %@", "%d pastas, %d arquivos | Total %@")
        add(.diskSpaceAnalysisHeader, "磁盘空间分析", "磁碟空間分析", "Disk Space Analysis", "ディスク容量分析", "디스크 공간 분석",
            "Analyse de l'espace disque", "Speicherplatzanalyse", "Análisis de espacio en disco", "Analisi spazio su disco", "Análise de Espaço em Disco")
        add(.labelTotal, "共", "共", "Total", "合計", "총",
            "Total", "Gesamt", "Total", "Totale", "Total")
        add(.actionEmptyTrash, "清空废纸篓", "清空垃圾桶", "Empty Trash", "ゴミ箱を空にする", "휴지통 비우기",
            "Vider la corbeille", "Papierkorb leeren", "Vaciar papelera", "Svuota cestino", "Esvaziar Lixeira")
        add(.systemSpotlessTitle, "系统处于极佳洁净状态", "系統處於極佳潔淨狀態", "Your Mac is Spotless", "Macは非常にクリーンな状態です", "Mac이 매우 깨끗한 상태입니다",
            "Votre Mac est parfaitement propre", "Ihr Mac ist blitzsauber", "Tu Mac está impecable", "Il tuo Mac è impeccabile", "Seu Mac está impecável")
        add(.systemSpotlessSubtitle, "未发现任何可清理系统垃圾，磁盘空间充裕", "未發現任何可清理系統垃圾，磁碟空間充裕", "No junk found. Disk space is clean and healthy.", "クリーンアップが必要なジャンクは見つかりませんでした。", "정리할 시스템 정크가 발견되지 않았습니다.",
            "Aucun fichier inutile trouvé. Espace disque propre et sain.", "Kein Datenmüll gefunden. Speicherplatz ist sauber und gesund.", "No se encontraron archivos basura. El espacio en disco está limpio.", "Nessun elemento superfluo trovato. Lo spazio su disco è pulito.", "Nenhum arquivo desnecessário encontrado. O espaço em disco está limpo.")
        add(.actionOpenTrashInFinder, "在访达中打开废纸篓", "在 Finder 中開啟垃圾桶", "Open Trash in Finder", "Finderでゴミ箱を開く", "Finder에서 휴지통 열기",
            "Ouvrir la corbeille dans le Finder", "Papierkorb im Finder öffnen", "Abrir papelera en el Finder", "Apri cestino nel Finder", "Abrir Lixeira no Finder")
        add(.statusCleaning, "清理中...", "清理中...", "Cleaning...", "クリーンアップ中...", "정리 중...",
            "Nettoyage en cours...", "Bereinigung läuft...", "Limpiando...", "Pulizia in corso...", "Limpando...")
    }

    static func populateBatch15(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        // 电池状态
        add(.batteryFullyCharged, "已充满", "已充飽", "Fully Charged", "フル充電完了", "완충됨",
            "Complètement chargée", "Vollständig geladen", "Carga completa", "Completamente carica", "Totalmente carregada")

        // 菜单栏配置器手势与上下文操作
        add(.configuratorDragToReorderPrompt, "按住上下拖动调整卡片位置", "按住上下拖動調整卡片位置", "Drag up/down to reorder cards", "上下にドラッグしてカードの順序を変更", "카드를 상하로 드래그하여 순서 변경",
            "Glisser vers le haut/bas pour réorganiser", "Nach oben/unten ziehen, um Karten neu anzuordnen", "Arrastrar arriba/abajo para reordenar", "Trascina su/giù per riordinare", "Arraste para cima/baixo para reordenar")
        add(.configuratorDropTargetPrompt, "落位于此", "放置於此", "Place here", "ここに配置", "여기에 배치",
            "Placer ici", "Hier platzieren", "Colocar aquí", "Posiziona qui", "Posicionar aqui")
        add(.configuratorMoveUp, "上移一位", "上移一位", "Move Up", "上に移動", "위로 이동",
            "Monter", "Nach oben verschieben", "Mover arriba", "Sposta in alto", "Mover para cima")
        add(.configuratorMoveDown, "下移一位", "下移一位", "Move Down", "下に移動", "아래로 이동",
            "Descendre", "Nach unten verschieben", "Mover abajo", "Sposta in basso", "Mover para baixo")
        add(.configuratorMoveToTop, "置于顶部", "置於頂部", "Move to Top", "先頭に移動", "맨 위로 이동",
            "Placer en haut", "Ganz nach oben", "Mover al principio", "Porta in cima", "Mover para o topo")
        add(.configuratorMoveToBottom, "置于底部", "置於底部", "Move to Bottom", "末尾に移動", "맨 아래로 이동",
            "Placer en bas", "Ganz nach unten", "Mover al final", "Porta in fondo", "Mover para o final")
        add(.configuratorAdjustSpan, "调整跨度", "調整跨度", "Adjust Width", "幅を調整", "너비 조정",
            "Ajuster la largeur", "Breite anpassen", "Ajustar ancho", "Regola larghezza", "Ajustar largura")
        add(.configuratorSpanTwoColumns, "双列并排 (1/2)", "雙列並排 (1/2)", "Two Columns (1/2)", "2列並列 (1/2)", "2열 나란히 (1/2)",
            "Deux colonnes (1/2)", "Zwei Spalten (1/2)", "Dos columnas (1/2)", "Due colonne (1/2)", "Duas colunas (1/2)")
        add(.configuratorSpanFullWidth, "通栏全宽 (1/1)", "通欄全寬 (1/1)", "Full Width (1/1)", "全幅 (1/1)", "전체 너비 (1/1)",
            "Pleine largeur (1/1)", "Volle Breite (1/1)", "Ancho completo (1/1)", "Intera larghezza (1/1)", "Largura total (1/1)")
        add(.configuratorSpanThreeColumns, "三列紧凑 (1/3)", "三列緊湊 (1/3)", "Three Columns (1/3)", "3列コンパクト (1/3)", "3열 콤팩트 (1/3)",
            "Trois colonnes (1/3)", "Drei Spalten (1/3)", "Tres columnas (1/3)", "Tre colonne (1/3)", "Três colunas (1/3)")
        add(.configuratorDisableSection, "停用该模块", "停用該模組", "Disable Module", "このモジュールを無効化", "이 모듈 비활성화",
            "Désactiver le module", "Modul deaktivieren", "Desactivar módulo", "Disattiva modulo", "Desativar módulo")
        add(.configuratorEnableSection, "启用该模块", "啟用該模組", "Enable Module", "このモジュールを有効化", "이 모듈 활성화",
            "Activer le module", "Modul aktivieren", "Activar módulo", "Attiva modulo", "Ativar módulo")
        add(.configuratorClickToDisableCard, "点击停用此卡片", "點選停用此卡片", "Click to disable card", "クリックしてカードを無効化", "클릭하여 카드 비활성화",
            "Cliquer pour désactiver la carte", "Klicken, um Karte zu deaktivieren", "Haz clic para desactivar tarjeta", "Clicca per disattivare la scheda", "Clique para desativar o cartão")
        add(.configuratorClickToEnableCard, "点击启用此卡片", "點選啟用此卡片", "Click to enable card", "クリックしてカードを有効化", "클릭하여 카드 활성화",
            "Cliquer pour activer la carte", "Klicken, um Karte zu aktivieren", "Haz clic para activar tarjeta", "Clicca per attivare la scheda", "Clique para ativar o cartão")

        // 卡片精简标题 (Half-span)
        add(.cardTitleCpuLoadShort, "CPU 负载", "CPU 負載", "CPU Load", "CPU負荷", "CPU 부하",
            "Charge CPU", "CPU-Auslastung", "Carga CPU", "Carico CPU", "Carga da CPU")
        add(.cardTitleGpuUsageShort, "GPU 占用", "GPU 佔用", "GPU Usage", "GPU使用率", "GPU 사용량",
            "Utilisation GPU", "GPU-Auslastung", "Uso de GPU", "Uso GPU", "Uso da GPU")
        add(.cardTitleRamUsageShort, "内存占用", "記憶體佔用", "Memory", "メモリ使用量", "메모리 사용량",
            "Mémoire", "Speicher", "Memoria", "Memoria", "Memória")
        add(.cardTitleDiskStorageShort, "磁盘存储", "磁碟儲存", "Storage", "ストレージ", "디스크 저장공간",
            "Stockage", "Festplatte", "Almacenamiento", "Spazio disco", "Armazenamento")
        add(.cardTitleNetworkThroughputShort, "网络吞吐", "網路輸送量", "Network", "ネットワーク", "네트워크 처리량",
            "Débit réseau", "Netzwerkdurchsatz", "Red", "Rete", "Rede")
        add(.cardTitleSensorsShort, "硬件传感器", "硬體感測器", "Sensors", "センサー", "하드웨어 센서",
            "Capteurs", "Sensoren", "Sensores", "Sensori", "Sensores")
        add(.cardTitleBatteryShort, "电池续航", "電池續航", "Battery", "バッテリー", "배터리",
            "Batterie", "Batterie", "Batería", "Batteria", "Bateria")
        add(.cardTitleWeatherShort, "实时天气", "即時天氣", "Weather", "天気", "실시간 날씨",
            "Météo", "Wetter", "Tiempo", "Meteo", "Clima")
        add(.cardTitleNetworkDetailShort, "网络详情", "網路詳情", "Net Details", "ネットワーク詳細", "네트워크 상세",
            "Détails réseau", "Netzwerkdetails", "Detalles de red", "Dettagli rete", "Detalhes de rede")
        add(.cardTitleTopProcessesShort, "进程排行", "處理程序排行", "Top Processes", "プロセス一覧", "프로세스 순위",
            "Top Processus", "Top-Prozesse", "Procesos principales", "Processi principali", "Principais Processos")
        add(.cardTitleHealthBannerShort, "系统健康度", "系統健康度", "System Health", "システム健康度", "시스템 건강도",
            "Santé système", "Systemzustand", "Salud del sistema", "Stato sistema", "Saúde do Sistema")
        add(.cardTitleFooterToolbarShort, "快捷工具", "快捷工具", "Quick Tools", "クイックツール", "빠른 도구",
            "Outils rapides", "Schnellwerkzeuge", "Herramientas rápidas", "Strumenti rapidi", "Ferramentas Rápidas")

        // 卡片完整标题 (Full-span)
        add(.cardTitleHealthBannerFull, "系统健康与规格", "系統健康與規格", "System Health & Specs", "システム健康度と仕様", "시스템 건강도 및 사양",
            "Santé et spécifications système", "Systemzustand & Spezifikationen", "Salud del sistema y especificaciones", "Stato e specifiche del sistema", "Saúde e Especificações do Sistema")
        add(.cardTitleCpuLoadFull, "CPU 负载走势", "CPU 負載走勢", "CPU Load Trend", "CPU負荷トレンド", "CPU 부하 추이",
            "Tendance de charge CPU", "CPU-Auslastungsverlauf", "Tendencia de carga CPU", "Andamento carico CPU", "Tendência de Carga da CPU")
        add(.cardTitleGpuUsageFull, "GPU 图形核心与显存", "GPU 圖形核心與顯存", "GPU Cores & VRAM", "GPUコアとVRAM", "GPU 그래픽 코어 및 VRAM",
            "Cœurs GPU et VRAM", "GPU-Kerne & VRAM", "Núcleos GPU y VRAM", "Core GPU e VRAM", "Núcleos de GPU e VRAM")
        add(.cardTitleRamUsageFull, "内存构成与分布", "記憶體構成與分佈", "Memory Breakdown", "メモリ構成と内訳", "메모리 구성 및 분포",
            "Répartition de la mémoire", "Speicheraufteilung", "Desglose de memoria", "Suddivisione memoria", "Distribuição da Memória")
        add(.cardTitleDiskStorageFull, "磁盘存储与读写速率", "磁碟儲存與讀寫速率", "Disk Storage & I/O Rate", "ストレージと読み書き速度", "디스크 저장공간 및 읽기/쓰기 속도",
            "Stockage disque et vitesse E/S", "Festplattenspeicher & E/A-Rate", "Almacenamiento de disco y velocidad E/S", "Spazio su disco e velocità I/O", "Armazenamento e Taxa de E/S")
        add(.cardTitleNetworkThroughputFull, "网络上下行实时吞吐", "網路上下行即時輸送量", "Network Upload/Download", "リアルタイム上下り通信量", "네트워크 실시간 업/다운로드",
            "Débit réseau montant/descendant", "Netzwerk-Durchsatz Up/Download", "Tráfico de red subida/bajada", "Velocità upload/download rete", "Taxa de Rede Upload/Download")
        add(.cardTitleSensorsFull, "硬件温度与风扇转速", "硬體溫度與風扇轉速", "Hardware Temp & Fans", "温度とファン速度", "하드웨어 온도 및 팬 속도",
            "Températures et ventilateurs", "Hardware-Temperatur & Lüfter", "Temperatura de hardware y ventilador", "Temperature hardware e ventole", "Temperatura do Hardware e Ventoinhas")
        add(.cardTitleBatteryFull, "电池健康与外设电量", "電池健康與外設電量", "Battery Health & Devices", "バッテリー健康度と周辺機器", "배터리 수명 및 주변기기 잔량",
            "Santé batterie et périphériques", "Batteriezustand & Geräte", "Salud de batería y periféricos", "Salute batteria e dispositivi", "Saúde da Bateria e Periféricos")
        add(.cardTitleWeatherFull, "实时天气预报", "即時天氣預報", "Live Weather Forecast", "リアルタイム天気予報", "실시간 일기 예보",
            "Météo en direct", "Echtzeit-Wettervorhersage", "Pronóstico del tiempo en vivo", "Previsioni meteo in tempo reale", "Previsão do Tempo em Tempo Real")
        add(.cardTitleNetworkDetailFull, "网络连接与公网 IP", "網路連線與公網 IP", "Network Connection & Public IP", "ネットワーク接続とパブリックIP", "네트워크 연결 및 공인 IP",
            "Connexion réseau et IP publique", "Netzwerkverbindung & Öffentliche IP", "Conexión de red e IP pública", "Connessione di rete e IP pubblico", "Conexão de Rede e IP Público")
        add(.cardTitleTopProcessesFull, "高耗资源进程排行", "高耗資源處理程序排行", "Top Resource-Hungry Apps", "高負荷プロセス一覧", "고부하 리소스 프로세스 순위",
            "Processus les plus gourmands", "Ressourcenintensive Prozesse", "Procesos con mayor consumo", "Processi a maggior consumo", "Processos com Maior Consumo")
        add(.cardTitleFooterToolbarFull, "快捷控制工具栏", "快捷控制工具列", "Quick Control Toolbar", "クイックコントロールツールバー", "빠른 제어 툴바",
            "Barre d'outils de contrôle rapide", "Schnellsteuerungs-Leiste", "Barra de herramientas rápidas", "Barra strumenti di controllo rapido", "Barra de Ferramentas de Controle Rápido")

        // 清理回执文案
        add(.receiptReclaimedAndTrashedFormat, "证实释放 %@ · 移至废纸篓 %@", "證實釋放 %@ · 移至垃圾桶 %@", "Verified Freed %@ · Moved to Trash %@", "解放確認 %@ · ゴミ箱へ移動 %@", "확인된 확보 공간 %@ · 휴지통으로 이동 %@",
            "Libéré confirmé %@ · Mis à la corbeille %@", "Bestätigt freigegeben %@ · In den Papierkorb verschoben %@", "Liberado confirmado %@ · Movido a la papelera %@", "Liberato confermato %@ · Spostato nel cestino %@", "Liberado confirmado %@ · Movido para a Lixeira %@")
        add(.receiptPermanentlyDeletedAndTrashedFormat, "永久删除 %@ · 移至废纸篓 %@", "永久刪除 %@ · 移至垃圾桶 %@", "Permanently Deleted %@ · Moved to Trash %@", "完全に削除 %@ · ゴミ箱へ移動 %@", "영구 삭제 %@ · 휴지통으로 이동 %@",
            "Supprimé définitivement %@ · Mis à la corbeille %@", "Dauerhaft gelöscht %@ · In den Papierkorb verschoben %@", "Eliminado permanentemente %@ · Movido a la papelera %@", "Eliminato definitivamente %@ · Spostato nel cestino %@", "Excluído permanentemente %@ · Movido para a Lixeira %@")
        add(.receiptPermanentlyDeletedFormat, "已永久删除 %@", "已永久刪除 %@", "Permanently deleted %@", "%@ を完全に削除しました", "%@ 영구 삭제 완료",
            "%@ définitivement supprimé", "%@ dauerhaft gelöscht", "%@ eliminado permanentemente", "%@ eliminato definitivamente", "%@ excluído permanentemente")
        add(.receiptMovedToTrashFormat, "已安全移入废纸篓 %@ (可随时复原)", "已安全移入垃圾桶 %@ (可隨時復原)", "Safely moved to Trash %@ (Can be restored)", "%@ を安全にゴミ箱へ移動しました (いつでも復元可能)", "%@ 휴지통으로 안전하게 이동됨 (언제든 복원 가능)",
            "Mis à la corbeille en toute sécurité %@ (Restauration possible)", "Sicher in den Papierkorb verschoben %@ (Wiederherstellbar)", "Movido a la papelera de forma segura %@ (Restaurable)", "Spostato nel cestino in sicurezza %@ (Ripristinabile)", "Movido com segurança para a Lixeira %@ (Restaurável)")
        add(.receiptMovedToTrashTagFormat, "移至废纸篓 %@", "移至垃圾桶 %@", "Moved to Trash %@", "ゴミ箱へ移動 %@", "휴지통으로 이동 %@",
            "Mis à la corbeille %@", "In den Papierkorb verschoben %@", "Movido a la papelera %@", "Spostato nel cestino %@", "Movido para a Lixeira %@")
        add(.receiptPermanentlyDeletedTagFormat, "永久删除 %@", "永久刪除 %@", "Permanently Deleted %@", "完全に削除 %@", "영구 삭제 %@",
            "Supprimé définitivement %@", "Dauerhaft gelöscht %@", "Eliminado permanentemente %@", "Eliminato definitivamente %@", "Excluído permanentemente %@")
        add(.receiptReclaimedTagFormat, "证实释放 %@", "證實釋放 %@", "Verified Freed %@", "解放確認 %@", "확인된 확보 %@",
            "Libéré confirmé %@", "Bestätigt freigegeben %@", "Liberado confirmado %@", "Liberato confermato %@", "Liberado confirmado %@")
        add(.receiptDiskSpaceFreedFormat, "已彻底释放磁盘空间 %@", "已徹底釋放磁碟空間 %@", "Disk space freed: %@", "%@ のディスク領域を解放しました", "디스크 공간 %@ 완전히 확보됨",
            "Espace disque libéré : %@", "Festplattenspeicher freigegeben: %@", "Espacio en disco liberado: %@", "Spazio su disco liberato: %@", "Espaço em disco liberado: %@")

        // 危险清理确认弹窗
        add(.dangerCleanPermanentNoticeFormat, "【永久销毁·不可撤销】包含 %d 项废纸篓项目 (%@)，将直接物理抹除，无法从废纸篓复原。", "【永久銷毀·不可撤銷】包含 %d 項垃圾桶項目 (%@)，將直接物理抹除，無法從垃圾桶復原。", "[Irreversible Permanent Delete] Includes %d trash items (%@). They will be erased immediately and cannot be recovered from Trash.", "【完全削除・復元不可】%d 個のゴミ箱項目 (%@) を直接削除します。ゴミ箱から復元することはできません。", "【영구 삭제·취소 불가】휴지통 항목 %d개(%@)를 완전히 삭제합니다. 휴지통에서 복원할 수 없습니다.",
            "[Suppression définitive irréversible] Comprend %d éléments de la corbeille (%@). Ils seront effacés et ne pourront pas être restaurés.", "[Unwiderrufliche Löschung] Enthält %d Papierkorb-Objekte (%@). Sie werden direkt gelöscht und können nicht wiederhergestellt werden.", "[Eliminación permanente irreversible] Incluye %d elementos de la papelera (%@). Se borrarán y no podrán recuperarse.", "[Eliminazione definitiva irreversibile] Include %d elementi del cestino (%@). Verranno rimossi e non potranno essere recuperati.", "[Exclusão permanente irreversível] Inclui %d itens da Lixeira (%@). Eles serão apagados e não poderão ser recuperados.")
        add(.dangerCleanSystemReclaimNoticeFormat, "【系统底层清理·不可恢复】包含 %d 项虚拟化容器/模拟器/快照项目 (%@)，将由系统服务直接抹除，无法从废纸篓复原。", "【系統底層清理·不可恢復】包含 %d 項虛擬化容器/模擬器/快照項目 (%@)，將由系統服務直接抹除，無法從垃圾桶復原。", "[System Service Cleanup·Irreversible] Includes %d container/simulator/snapshot items (%@). They will be purged by system tools and cannot be recovered.", "【システム低層クリーンアップ・復元不可】%d 個のコンテナ/シミュレータ/スナップショット項目 (%@) を消去します。ゴミ箱からは復元できません。", "【시스템 저수준 정리·복구 불가】컨테이너/시뮬레이터/스냅샷 항목 %d개(%@)를 시스템 도구로 직접 정리합니다. 복원할 수 없습니다.",
            "[Nettoyage système irréversible] Comprend %d conteneurs/simulateurs/instantanés (%@) purgés par les outils système.", "[Systembereinigung unwiderruflich] Enthält %d Container-/Simulator-/Snapshot-Objekte (%@). Werden von Systemdiensten bereinigt.", "[Limpieza del sistema irreversible] Incluye %d elementos de contenedores/simuladores/instantáneas (%@) purgados por el sistema.", "[Pulizia sistema irreversibile] Include %d elementi container/simulatori/snapshot (%@) eliminati dai servizi di sistema.", "[Limpeza do sistema irreversível] Inclui %d itens de contêineres/simuladores/instantâneos (%@) limpos pelo sistema.")
        add(.dangerCleanCustomMaintenanceNoticeFormat, "【专用维护任务】包含 %d 项系统维护动作，将直接执行对应系统操作。", "【專用維護任務】包含 %d 項系統維護動作，將直接執行對應系統操作。", "[Maintenance Tasks] Includes %d maintenance actions that will run directly.", "【専用メンテナンス】%d 個のシステムメンテナンスタスクを直接実行します。", "【유지 관리 작업】%d개의 시스템 유지 관리 작업을 직접 실행합니다.",
            "[Tâches de maintenance] Comprend %d actions de maintenance système exécutées directement.", "[Wartungsaufgaben] Enthält %d Systemwartungsaktionen, die direkt ausgeführt werden.", "[Tareas de mantenimiento] Incluye %d tareas de mantenimiento que se ejecutarán directamente.", "[Attività di manutenzione] Include %d attività di manutenzione eseguite direttamente.", "[Tarefas de manutenção] Inclui %d ações de manutenção executadas diretamente.")
        add(.dangerCleanTrashNoticeFormat, "【移至废纸篓】包含 %d 项文件 (%@)，可随时在访达废纸篓中放回原处。", "【移至垃圾桶】包含 %d 項檔案 (%@)，可隨時在 Finder 垃圾桶中放回原處。", "[Move to Trash] Includes %d items (%@). You can restore them from Finder Trash anytime.", "【ゴミ箱へ移動】%d 個のファイル (%@) をゴミ箱へ移動します。Finderでいつでも元に戻せます。", "【휴지통으로 이동】파일 %d개(%@)를 휴지통으로 이동합니다. 언제든지 원위치로 복원할 수 있습니다.",
            "[Mettre à la corbeille] Comprend %d fichiers (%@). Restaurables à tout moment depuis la corbeille du Finder.", "[In den Papierkorb] Enthält %d Dateien (%@). Können jederzeit im Finder-Papierkorb wiederhergestellt werden.", "[Mover a la papelera] Incluye %d archivos (%@). Se pueden restaurar desde la papelera en cualquier momento.", "[Sposta nel cestino] Include %d file (%@). Possono essere ripristinati dal cestino del Finder in qualsiasi momento.", "[Mover para a Lixeira] Inclui %d arquivos (%@). Podem ser restaurados da Lixeira a qualquer momento.")
        add(.dangerCleanRiskWarningFormat, "风险警示：包含高危资产类目 [%@]", "風險警示：包含高危資產類目 [%@]", "Security Alert: Contains high-risk category [%@]", "セキュリティ警告: 高リスクカテゴリ [%@] を含みます", "보안 경고: 고위험 카테고리 [%@] 포함",
            "Alerte de sécurité : contient une catégorie à haut risque [%@]", "Sicherheitswarnung: Enthält Hochrisiko-Kategorie [%@]", "Alerta de seguridad: contiene categoría de alto riesgo [%@]", "Avviso di sicurezza: contiene categoria ad alto risque [%@]", "Alerta de segurança: contém categoria de alto risco [%@]")
        add(.toastCleanupAlreadyRunning, "已有清理任务正在运行中，请等待其完成", "已有清理任務正在執行中，請等待其完成", "A cleanup task is already in progress. Please wait for it to finish.", "別のクリーンアップタスクを実行中です。完了までお待ちください。", "다른 정리 작업이 진행 중입니다. 완료될 때까지 기다려 주세요.",
            "Un nettoyage est déjà en cours. Veuillez patienter.", "Ein Bereinigungsvorgang läuft bereits. Bitte warten.", "Ya hay una tarea de limpieza en curso. Por favor, espera a que termine.", "È già in corso un'attività di pulizia. Attendi il completamento.", "Uma limpeza já está em andamento. Aguarde a conclusão.")
        add(.statusAppRunningSkipped, "应用仍在运行且拒绝退出，已安全跳过所有关联数据以防损坏", "應用程式仍在執行且拒絕退出，已安全跳過所有關聯資料以防損壞", "The application is still running and did not quit. All related files were safely skipped to prevent corruption.", "アプリが実行中で終了しなかったため、データ破損を防ぐため関連データをスキップしました。", "앱이 여전히 실행 중이며 종료되지 않아 데이터 손상을 방지하기 위해 관련 데이터를 건너뛰었습니다.",
            "L'application est toujours en cours d'exécution. Les données associées ont été ignorées en toute sécurité.", "Die Anwendung läuft noch. Alle zugehörigen Daten wurden sicher übersprungen, um Beschädigungen zu verhindern.", "La aplicación sigue en ejecución. Todos los datos asociados se omitieron para evitar daños.", "L'applicazione è ancora in esecuzione. Tutti i dati associati sono stati ignorati per evitare danni.", "O aplicativo ainda está em execução. Todos os dados associados foram ignorados para evitar corrupção.")

        // MARK: - 清理方案选择器 (Cleaning Profiles)
        add(.cleanProfileSafeDaily, "日常安全", "日常安全", "Daily Safe", "日常セーフ", "일상 안전",
            "Sécurité quotidienne", "Tägliche Sicherheit", "Seguridad diaria", "Sicurezza quotidiana", "Segurança diária")
        add(.cleanProfileSafeDailyDesc, "零风险清理系统与应用临时缓存，保留所有聊天媒体、工程依赖与本地大模型，随用随建。", "零風險清理系統與應用程式臨時快取，保留所有聊天媒體、工程依賴與本重大模型，隨用隨建。", "Zero-risk cleanup of system and app temporary caches. Preserves chat media, project dependencies, and local AI models.", "システムとアプリの一時キャッシュをゼロリスクで削除。チャットメディア、プロジェクト依存関係、ローカルAIモデルを完全に保護します。", "시스템 및 앱 임시 캐시를 무위험으로 정리합니다. 채팅 미디어, 프로젝트 종속성 및 로컬 AI 모델은 안전하게 유지됩니다.",
            "Nettoyage sans risque des caches temporaires du système et des applications. Conserve les médias de discussion, dépendances de projet et modèles IA locaux.", "Risikofreie Bereinigung temporärer System- und App-Caches. Chat-Medien, Projektabhängigkeiten und lokale KI-Modelle bleiben erhalten.", "Limpieza sin riesgo de cachés temporales de sistema y apps. Conserva medios de chat, dependencias de proyecto y modelos de IA locales.", "Pulizia a rischio zero delle cache temporanee di sistema e app. Conserva i media delle chat, le dipendenze di progetto e i modelli IA locali.", "Limpeza sem risco de caches temporários do sistema e aplicativos. Mantém mídias de chat, dependências de projetos e modelos de IA locais.")
        add(.cleanProfileDevPro, "清理开发和设计缓存", "清理開發和設計快取", "Clean Dev & Design Caches", "開発・デザインキャッシュを整理", "개발 및 디자인 캐시 정리",
            "Nettoyer les caches dév. et design", "Entwickler- & Design-Caches bereinigen", "Limpiar cachés de desarrollo y diseño", "Pulisci cache di sviluppo e design", "Limpar caches de desenv. e design")
        add(.cleanProfileDevProDesc, "面向开发者与设计师，额外清理 Xcode 派生数据、包管理器旧缓存与设计渲染中间层，首次构建需重建。", "面向開發者與設計師，額外清理 Xcode 衍生資料、套件管理器舊快取與設計算繪中間層，首次建構需重建。", "For developers and designers: additionally cleans Xcode DerivedData, package manager caches, and design intermediate renders. Rebuilt on next run.", "開発者やデザイナー向け：Xcode DerivedData、パッケージマネージャーの古いキャッシュ、デザイン中間レンダリングを追加削除します（次回初回ビルド時に再構築）。", "개발자 및 디자이너를 위해 Xcode 파생 데이터, 패키지 관리자 캐시 및 디자인 중간 렌더링을 추가로 정리합니다. 다음 빌드 시 다시 생성됩니다.",
            "Pour développeurs et designers : nettoie en plus Xcode DerivedData, les caches de gestionnaires de paquets et les rendus intermédiaires.", "Für Entwickler & Designer: Bereinigt zusätzlich Xcode DerivedData, Paketmanager-Caches und Zwischen-Renderings.", "Para desarrolladores y diseñadores: limpia además Xcode DerivedData, cachés de gestores de paquetes y renderizados intermedios de diseño.", "Per sviluppatori e designer: pulisce inoltre Xcode DerivedData, cache dei gestori di pacchetti e rendering intermedi di progettazione.", "Para desenvolvedores e designers: limpa adicionalmente Xcode DerivedData, caches de gerenciadores de pacotes e renderizações intermediárias de design.")
        add(.cleanProfileMaxSpace, "极限清理", "極限清理", "Extreme Clean", "極限クリーン", "극한 정리",
            "Nettoyage extrême", "Extreme Bereinigung", "Limpieza extrema", "Pulizia estrema", "Limpeza extrema")
        add(.cleanProfileMaxSpaceDesc, "磁盘告急时强力释放大缓存与过期本地快照，微信聊天文件与大模型核心资产依然受保护。", "磁碟告急時強力釋放大快取與過期本地快照，微信聊天檔案與大模型核心資產依然受保護。", "Strongly purges large caches and expired local snapshots during storage crunches. Chat history and local AI models remain strictly protected.", "ストレージ逼迫時に大容量キャッシュと期限切れローカルスナップショットを強力削除。チャットファイルとAIモデル資産は厳格に保護されます。", "저장 공간 부족 시 대용량 캐시 및 만료된 로컬 스냅샷을 강력히 정리합니다. 채팅 파일과 AI 모델 자산은 엄격히 보호됩니다.",
            "Purge énergiquement les gros caches et instantanés locaux expirés en cas de saturation. Les discussions et modèles IA restent strictement protégés.", "Bereinigt bei Speicherknappheit große Caches und abgelaufene lokale Snapshots. Chat-Dateien und KI-Modelle bleiben streng geschützt.", "Purga enérgicamente cachés grandes e instantáneas locales expiradas en emergencias de disco. Los chats y modelos de IA siguen estrictamente protegidos.", "Elimina vigorosamente le grandi cache e gli snapshot locali scaduti in caso di spazio ridotto. Chat e modelli IA rimangono protetti.", "Libera vigorosamente grandes caches e snapshots locais expirados durante emergências de espaço. Chats e modelos de IA permanecem estritamente protegidos.")
        add(.cleanProfileCustom, "自定义微调", "自訂微調", "Custom Adjust", "カスタム調整", "사용자 지정 조정",
            "Ajustement personnalisé", "Benutzerdefinierte Anpassung", "Ajuste personalizado", "Personalizzato", "Ajuste personalizado")
        add(.cleanProfileResetToRecommended, "恢复推荐方案", "恢復推薦方案", "Reset to Recommended", "推奨プランに戻す", "추천 플랜으로 복원",
            "Rétablir le profil recommandé", "Auf Empfehlung zurücksetzen", "Restablecer al recomendado", "Ripristina consigliato", "Restaurar para o recomendado")

        // MARK: - 影响透视条 (Pre-Clean Impact Bar)
        add(.impactTrashReversibleNotice, "100% 移入废纸篓，随时可撤回还原", "100% 移入垃圾桶，隨時可撤回還原", "100% moved to Trash; safely reversible anytime", "100% ゴミ箱へ移動、いつでも元に戻せます", "100% 휴지통으로 이동되며 언제든 복원 가능",
            "100% mis à la corbeille, réversible à tout moment", "100% in den Papierkorb verschoben, jederzeit wiederherstellbar", "100% movido a la papelera, reversible en cualquier momento", "100% spostato nel cestino, ripristinabile in qualsiasi momento", "100% movido para a Lixeira, reversível a qualquer momento")
        add(.impactProtectedNoticeFormat, "已严格保护本地模型与核心数据", "已嚴格保護本地模型與核心資料", "Local models and critical assets strictly protected", "ローカルAIモデルと中核資産を厳格に保護中", "로컬 AI 모델 및 핵심 자산 엄격히 보호됨",
            "Modèles locaux et données essentielles strictement protégés", "Lokale Modelle und wichtige Daten streng geschützt", "Modelos locales y datos críticos estrictamente protegidos", "Modelli locali e dati critici rigorosamente protetti", "Modelos locais e ativos essenciais estritamente protegidos")
        add(.impactRebuildNotice, "包含开发构建产物，下次编译时将重新索引", "包含開發建構產物，下次編譯時將重新索引", "Includes build artifacts; projects will re-index on next compile", "開発ビルド成果物が含まれます。次回のコンパイル時に再インデックスされます", "개발 빌드 아티팩트가 포함되어 있어 다음 컴파일 시 다시 인덱싱됩니다",
            "Contient des artefacts de build ; réindexation au prochain build", "Enthält Build-Artefakte; Projekte werden beim nächsten Build neu indiziert", "Incluye artefactos de compilación; los proyectos se reindexarán en la próxima compilación", "Include artefatti di build; i progetti verranno reindicizzati alla prossima compilazione", "Inclui artefatos de build; os projetos serão reindexados na próxima compilação")

        // MARK: - 受保护资产与修复文案
        add(.assetProtectedBadge, "受保护资产", "受保護資產", "Protected Asset", "保護された資産", "보호된 자산",
            "Actif protégé", "Geschütztes Objekt", "Activo protegido", "Elemento protetto", "Ativo protegido")
        add(.assetReadOnlyNotice, "本地离线模型/系统备份，默认锁定不自动清理", "本地離線模型/系統備份，預設鎖定不自動清理", "Local offline models/system backups are locked from auto-cleaning", "ローカルオフラインモデル/システムバックアップは自動削除からロックされています", "로컬 오프라인 모델 및 시스템 백업은 자동 정리에서 잠겨 있습니다",
            "Modèles hors ligne locaux/sauvegardes système verrouillés contre le nettoyage auto", "Lokale Offline-Modelle/System-Backups sind vor automatischer Bereinigung geschützt", "Los modelos sin conexión locales y copias de seguridad están bloqueados", "Modelli offline locali e backup di sistema bloccati dalla pulizia automatica", "Modelos offline locais e backups do sistema estão bloqueados para limpeza automática")
        add(.assetRevealInFinder, "在访达中显示", "在 Finder 中顯示", "Show in Finder", "Finder で表示", "Finder에서 보기",
            "Afficher dans le Finder", "Im Finder anzeigen", "Mostrar en Finder", "Mostra nel Finder", "Mostrar no Finder")
        add(.appProtectedGroupSubtitleFormat, "受保护的%@资产与模型，仅供查看，展开查看具体项", "受保護的%@資產與模型，僅供檢視，展開檢視具體項", "Protected %@ assets and models (view only); expand to view details", "保護された%@の資産とモデル（閲覧のみ）。展開して詳細を表示", "보호된 %@ 자산 및 모델(보기 전용). 펼쳐서 상세 항목 보기",
            "Actifs et modèles %@ protégés (lecture seule) ; développer pour voir les détails", "Geschützte %@-Objekte und Modelle (schreibgeschützt); für Details aufklappen", "Activos y modelos protegidos de %@ (solo lectura); expandir para ver detalles", "Elementi e modelli protetti di %@ (sola visualizzazione); espandi per i dettagli", "Ativos e modelos protegidos de %@ (apenas exibição); expanda para ver detalhes")
        add(.appMixedGroupSubtitleFormat, "可清理%@临时缓存，核心模型已受保护，展开查看具体项", "可清理%@臨時快取，核心模型已受保護，展開檢視具體項", "Cleanable %@ temporary caches; models protected; expand for details", "%@の一時キャッシュを削除可能、コアモデルは保護済み。展開して詳細を表示", "%@ 임시 캐시 정리 가능, 핵심 모델은 보호됨. 펼쳐서 상세 항목 보기",
            "Caches temporaires de %@ nettoyables ; modèles protégés ; développer pour voir", "Bereinigbare temporäre Caches von %@; Modelle geschützt; für Details aufklappen", "Cachés temporales de %@ limpiables; modelos protegidos; expandir para ver", "Cache temporanee di %@ eliminabili; modelli protetti; espandi per i dettagli", "Caches temporários de %@ limpáveis; modelos protegidos; expanda para ver detalhes")

        // MARK: - Phase 2: 资产闭环与深度联动
        add(.assetCopyCliCommandFormat, "复制: %@", "複製: %@", "Copy: %@", "コピー: %@", "복사: %@",
            "Copier : %@", "Kopieren: %@", "Copiar: %@", "Copia: %@", "Copiar: %@")
        add(.assetCopiedToast, "已复制终端管理命令到剪贴板", "已複製終端機管理命令至剪貼簿", "Terminal management command copied to clipboard", "ターミナル管理コマンドをクリップボードにコピーしました", "터미널 관리 명령어가 클립보드에 복사되었습니다",
            "Commande copiée dans le presse-papiers", "Befehl in die Zwischenablage kopiert", "Comando copiado al portapapeles", "Comando copiato negli appunti", "Comando copiado para a área de transferência")
        add(.assetOpenSystemStorage, "打开系统「存储空间」设置", "打開系統「儲存空間」設定", "Open System Storage Settings", "システム「ストレージ」設定を開く", "시스템 '저장 공간' 설정 열기",
            "Ouvrir les réglages de stockage", "Systemeinstellungen „Speicher“ öffnen", "Abrir ajustes de almacenamiento", "Apri impostazioni spazio", "Abrir configurações de armazenamento")
        add(.assetInspectInSpaceLens, "在「空间透镜」中透视", "在「空間透鏡」中透視", "Inspect in Space Lens", "「空間レンズ」で詳細を見る", "'공간 렌즈'에서 분석",
            "Examiner dans Space Lens", "In Space Lens untersuchen", "Inspeccionar en Lente Espacial", "Esamina in Space Lens", "Inspecionar na Lente Espacial")
        add(.profileDeltaFormat, "+%@ 额外释放", "+%@ 額外釋放", "+%@ extra release", "+%@ 追加解放", "+%@ 추가 확보",
            "+%@ libération suppl.", "+%@ zusätzlich freigeben", "+%@ liberación extra", "+%@ rilascio extra", "+%@ liberação extra")

        // MARK: - Phase 3: 运行态防护与终极回执
        add(.statusRunningAppHoverTip, "该应用当前正在运行中", "該應用程式目前正在執行中", "This application is currently running", "このアプリは現在実行中です", "이 앱은 현재 실행 중입니다",
            "Cette application est en cours d'exécution", "Diese Anwendung läuft derzeit", "Esta aplicación se está ejecutando", "Questa applicazione è attualmente in esecuzione", "Este aplicativo está em execução")
        add(.runningAppsDetectedTitle, "检测到正在运行的应用", "偵測到正在執行的應用程式", "Running Applications Detected", "実行中のアプリを検出しました", "실행 중인 앱 감지됨",
            "Applications en cours d'exécution détectées", "Laufende Anwendungen erkannt", "Aplicaciones en ejecución detectadas", "Rilevate applicazioni in esecuzione", "Aplicativos em execução detectados")
        add(.runningAppsDetectedSubtitle, "以下应用正在运行，其缓存可能处于占用状态。建议退出以保证彻底清理，或跳过继续。", "以下應用程式正在執行，其快取可能處於佔用狀態。建議退出以保證徹底清理，或跳過繼續。", "The following apps are running and may have locked caches. Quitting them ensures thorough cleaning, or you can skip them.", "以下のアプリが実行中であり、キャッシュがロックされている可能性があります。終了して完全に削除するか、スキップして続行できます。", "다음 앱이 실행 중이며 캐시가 사용 중일 수 있습니다. 완전히 정리하려면 종료하거나 건너뛰고 계속할 수 있습니다.",
            "Les applications suivantes sont en cours d'exécution. Les quitter permet un nettoyage complet, ou vous pouvez les ignorer.", "Die folgenden Apps laufen noch. Ein Beenden sorgt für eine gründliche Bereinigung, oder Sie können sie überspringen.", "Las siguientes aplicaciones están abiertas. Cerrarlas garantiza una limpieza completa, o puedes omitirlas.", "Le seguenti app sono aperte. Chiuderle garantisce una pulizia completa, oppure puoi saltarle.", "Os seguintes aplicativos estão em execução. Fechá-los garante uma limpeza completa, ou você pode ignorá-los.")
        add(.runningAppQuitAndClean, "退出应用并清理", "退出應用程式並清理", "Quit Apps and Clean", "アプリを終了してクリーンアップ", "앱 종료 후 정리",
            "Quitter et nettoyer", "Apps beenden und bereinigen", "Cerrar apps y limpiar", "Chiudi app e pulisci", "Encerrar apps e limpar")
        add(.runningAppSkipAndCleanRest, "跳过运行中应用并清理其余", "跳過執行中應用程式並清理其餘", "Skip Running Apps and Clean Rest", "実行中のアプリをスキップして残りを削除", "실행 중인 앱을 건너뛰고 나머지 정리",
            "Ignorer les apps actives et nettoyer le reste", "Laufende Apps überspringen und Rest bereinigen", "Omitir apps abiertas y limpiar el resto", "Salta app in esecuzione e pulisci il resto", "Ignorar apps em execução e limpar o restante")
        add(.receiptProtectedSummaryTitle, "已严格守护的核心资产", "已嚴格守護的核心資產", "Strictly Protected Core Assets", "厳格に保護された中核資産", "엄격히 보호된 핵심 자산",
            "Actifs essentiels strictement protégés", "Streng geschützte Kernobjekte", "Activos esenciales estrictamente protegidos", "Asset essenziali rigorosamente protetti", "Ativos essenciais estritamente protegidos")
        add(.receiptUndoCleanupButton, "撤回本次清理 (⌘Z)", "復原本次清理 (⌘Z)", "Undo Cleanup (⌘Z)", "クリーンアップを取り消す (⌘Z)", "정리 실행 취소 (⌘Z)",
            "Annuler le nettoyage (⌘Z)", "Bereinigung widerrufen (⌘Z)", "Deshacer limpieza (⌘Z)", "Annulla pulizia (⌘Z)", "Desfazer limpeza (⌘Z)")
        add(.receiptUndoSuccessNotice, "已成功从废纸篓撤回还原 %d 项文件 (%@)", "已成功從垃圾桶復原 %d 項檔案 (%@)", "Successfully restored %d items (%@) from Trash", "ゴミ箱から %d 個の項目 (%@) を正常に復元しました", "휴지통에서 파일 %d개(%@)를 성공적으로 복원했습니다",
            "%d éléments (%@) restaurés avec succès depuis la corbeille", "%d Objekte (%@) erfolgreich aus dem Papierkorb wiederhergestellt", "Se restauraron con éxito %d elementos (%@) de la papelera", "Ripristinati con successo %d elementi (%@) dal cestino", "%d itens (%@) restaurados com sucesso da Lixeira")
        add(.receiptUndoDone, "已撤回还原", "已復原", "Restored", "復元完了", "복원 완료",
            "Restauré", "Wiederhergestellt", "Restaurado", "Ripristinato", "Restaurado")
        add(.receiptApfsTrashNotice, "文件已安全移入废纸篓。如需立刻释放物理磁盘空间，请在确认无误后倾倒废纸篓。", "檔案已安全移入垃圾桶。如需立刻釋放實體磁碟空間，請在確認無誤後傾倒垃圾桶。", "Files are safely in Trash. To instantly reclaim physical APFS storage, empty Trash when ready.", "ファイルは安全にゴミ箱へ移動しました。物理ディスク容量を直ちに解放するには、確認後にゴミ箱を空にしてください。", "파일이 휴지통으로 안전하게 이동되었습니다. 물리적 디스크 공간을 즉시 확보하려면 휴지통을 비워주세요.",
            "Les fichiers sont dans la corbeille. Pour libérer immédiatement l'espace physique, videz la corbeille.", "Dateien liegen sicher im Papierkorb. Um physischen Speicher sofort freizugeben, leeren Sie den Papierkorb.", "Los archivos están seguros en la papelera. Para liberar espacio físico de inmediato, vacía la papelera.", "I file sono al sicuro nel cestino. Per recuperare immediatamente lo spazio fisico, svuota il cestino.", "Os arquivos estão seguros na Lixeira. Para liberar imediatamente o espaço físico, esvazie a Lixeira.")
    }

}
