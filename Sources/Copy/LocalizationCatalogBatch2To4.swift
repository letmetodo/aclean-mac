import Foundation

extension LocalizationCatalog {
    static func populateBatch2(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.batteryPower, "电池供电", "電池供電", "Battery Power", "バッテリー動作", "배터리 전원",
            "Sur batterie", "Batteriebetrieb", "Batería", "Alimentazione a batteria", "Bateria")
        add(.bigFilesCountAndSizeFormat, "共 %d 个超过 100 MB 的单体大文件，占用 %@。", "共 %d 個超過 100 MB 的單體大檔案，佔用 %@。", "%d standalone files over 100 MB, taking %@.", "100 MB を超える単体大容量ファイル %d 個（合計 %@）。", "100 MB 초과 대용량 파일 %d개, 총 %@ 차지.",
            "%d fichiers de plus de 100 Mo, occupant %@.", "%d Einzeldateien über 100 MB, belegen %@.", "%d archivos grandes de más de 100 MB, ocupan %@.", "%d file grandi oltre 100 MB, occupano %@.", "%d arquivos grandes com mais de 100 MB, ocupam %@.")
        add(.biweekly, "每两周", "每兩周", "Biweekly", "隔週", "2주마다",
            "Toutes les 2 semaines", "Alle 2 Wochen", "Cada 2 semanas", "Ogni 2 settimane", "A Cada 2 Semanas")
        add(.bluetoothAccessory, "蓝牙外设", "藍牙外設", "Bluetooth Accessory", "Bluetooth デバイス", "블루투스 기기",
            "Accessoire Bluetooth", "Bluetooth-Gerät", "Accesorio Bluetooth", "Accessorio Bluetooth", "Acessório Bluetooth")
        add(.bootDateFormattedSuffixFormat, "%@开机", "%@開機", "Booted %@", "%@ 起動", "%@ 부팅됨",
            "Démarré le %@", "Gestartet %@", "Iniciado el %@", "Avviato %@", "Inicializado %@")
        add(.brewService, "Brew 服务", "Brew 服務", "Brew Service", "Brew サービス", "Brew 서비스",
            "Service Brew", "Brew-Dienst", "Servicio Brew", "Servizio Brew", "Serviço Brew")
        add(.brokenBackgroundItemsCountFormat, "其中 %d 项指向已失效的程序。", "其中 %d 項指向已失效的程式。", "%d of these point to broken or missing binaries.", "%d 件が無効または存在しないバイナリを指しています。", "그중 %d개 항목이 유효하지 않은 실행 파일을 가리킵니다.",
            "%d d'entre eux pointent vers des binaires introuvables.", "%d davon verweisen auf fehlerhafte oder fehlende Programme.", "%d de ellos apuntan a binarios rotos o inexistentes.", "%d di questi puntano a file binari non validi o mancanti.", "%d deles apontam para binários inválidos ou ausentes.")
        add(.brokenItemsCountFormat, "其中 %d 项指向已失效的程序。", "其中 %d 項指向已失效的程式。", "%d items point to missing programs.", "%d 項目が無効なプログラムを参照しています。", "그중 %d개 항목이 유실된 프로그램을 가리킵니다.",
            "%d éléments pointent vers des programmes manquants.", "%d Objekte verweisen auf fehlende Programme.", "%d elementos apuntan a programas que faltan.", "%d elementi puntano a programmi mancanti.", "%d itens apontam para programas ausentes.")
        add(.brokenPreferences, "损坏的偏好设置", "損壞的偏好設定檔", "Broken Preferences", "破損した環境設定ファイル", "손상된 환경설정 파일",
            "Préférences corrompues", "Beschädigte Einstellungen", "Preferencias dañadas", "Preferenze danneggiate", "Preferências Corrompidas")
        add(.browserCaches, "浏览器缓存", "瀏覽器快取", "Browser Caches", "ブラウザキャッシュ", "브라우저 캐시",
            "Caches des navigateurs", "Browser-Caches", "Caché del navegador", "Cache dei browser", "Caches de Navegadores")
        add(.buildArtifactsAndCachesFromXcodeDeriveddataGradleNpmRustEtc, "Xcode 派生数据、Gradle、npm、Rust 等编译冗余", "Xcode 派生資料、Gradle、npm、Rust 等編譯冗余", "Build artifacts and caches from Xcode DerivedData, Gradle, npm, Rust, etc.", "Xcode DerivedData、Gradle、npm、Rust などのビルド生成物とキャッシュ", "Xcode DerivedData, Gradle, npm, Rust 등의 빌드 결과물 및 캐시",
            "Artefacts de compilation et caches d’Xcode DerivedData, Gradle, npm, Rust, etc.", "Build-Artefakte und Caches von Xcode DerivedData, Gradle, npm, Rust usw.", "Artefactos de compilación y cachés de Xcode DerivedData, Gradle, npm, Rust, etc.", "Artefatti di compilazione e cache di Xcode DerivedData, Gradle, npm, Rust, ecc.", "Artefatos de compilação e caches do Xcode DerivedData, Gradle, npm, Rust, etc.")
        add(.buildingDiskTreePrompt, "正在构建磁盘空间比例树图…", "正在構建磁碟空間比例樹圖…", "Building disk proportion treemap…", "ディスク容量比率ツリーマップを構築中…", "디스크 공간 비율 트리맵 생성 중…",
            "Génération du treemap de proportion du disque…", "Erstelle Speicherplatz-Treemap…", "Creando mapa de proporciones de disco…", "Creazione della mappa ad albero dello spazio…", "Construindo treemap de proporção de disco…")
        add(.burstShotsOrVisuallySimilarPhotosHighestQualityKeptByDefault, "连拍或视觉高度相似的图片，默认保留每组最高质量原图", "連拍或視覺高度相似的圖片，預設保留每組最高質量原圖", "Burst shots or visually similar photos; highest quality kept by default", "連写や視覚的に極めて類似した写真。デフォルトで最高画質を保持", "연사 촬영 또는 시각적으로 유사한 사진. 기본적으로 최고 화질 원본 유지",
            "Photos en rafale ou visuellement similaires ; meilleure qualité conservée par défaut", "Serienaufnahmen oder optisch ähnliche Fotos; behält standardmäßig beste Qualität", "Ráfagas o fotos visualmente similares; se conserva la de mayor calidad", "Scatti a raffica o foto visivamente simili; la massima qualità viene conservata per impostazione predefinita", "Fotos em sequência ou visualmente semelhantes; a mais alta qualidade é mantida por padrão")
        add(.cachesAndOrphanedLogsMovedToTrashReversibleAnytime, "临时缓存、孤立垃圾日志，移入废纸篓随时可放回", "暫存快取、孤立垃圾日誌，移入垃圾桶隨時可放回", "Caches & orphaned logs; moved to Trash, reversible anytime", "キャッシュと孤立ログ。ゴミ箱に移動するためいつでも復元可能", "임시 캐시 및 고립된 로그. 휴지통으로 이동되어 언제든 복원 가능",
            "Caches et journaux orphelins ; mis à la corbeille, récupérables à tout moment", "Caches und verwaiste Logs; in den Papierkorb verschoben, jederzeit wiederherstellbar", "Cachés y registros huérfanos; movidos a la papelera, recuperables en cualquier momento", "Cache e registri orfani; spostati nel Cestino, ripristinabili in qualsiasi momento", "Caches e logs órfãos; movidos para a lixeira, recuperáveis a qualquer momento")
        add(.caffeineReady, "防休眠就绪", "防休眠就緒", "Caffeine Ready", "スリープ防止スタンバイ", "절전 방지 대기",
            "Anti-veille prêt", "Ruhezustandsverhinderung bereit", "Antisuspensión lista", "Anti-sospensione pronto", "Anti-repouso Pronto")
        add(.cameraAndMicInUse, "相机与麦克风使用中", "相機與麥克風使用中", "Camera & Mic in Use", "カメラとマイクを使用中", "카메라 및 마이크 사용 중",
            "Caméra et micro en cours d’utilisation", "Kamera & Mikrofon aktiv", "Cámara y micrófono en uso", "Fotocamera e microfono in uso", "Câmera e Microfone em Uso")
        add(.cameraInUse, "相机使用中", "相機使用中", "Camera in Use", "カメラを使用中", "카메라 사용 중",
            "Caméra en cours d’utilisation", "Kamera aktiv", "Cámara en uso", "Fotocamera in uso", "Câmera em Uso")
        add(.categorizingDownloadedFiles, "整理下载文件", "整理下載文件", "Categorizing downloaded files", "ダウンロードファイルを整理中", "다운로드된 파일 정리 중",
            "Classement des fichiers téléchargés", "Heruntergeladene Dateien kategorisieren", "Categorizando archivos descargados", "Categorizzazione dei file scaricati", "Categorizando arquivos baixados")
        add(.categoryAiAndDesignCaches, "AI 与设计缓存", "AI 與設計緩存", "AI & Design Caches", "AI およびデザインキャッシュ", "AI 및 디자인 캐시",
            "Caches IA et conception graphique", "KI- & Design-Caches", "Cachés de IA y diseño", "Cache IA e grafica", "Caches de IA e design")
        add(.categoryAiAndDesignCachesDesc, "安全释放 AI 工具中间文件与设计软件临时渲染素材", "安全釋放 AI 工具中間文件與設計軟件臨時渲染素材", "Safely free intermediate files from AI tools and temporary render assets from design software", "AI ツールの生成中間ファイルやデザインソフトの一時レンダリング素材を安全に解放", "AI 도구의 중간 산출물과 디자인 프로그램의 임시 렌더링 리소스를 안전하게 확보",
            "Libérez les fichiers intermédiaires d'outils IA et rendus temporaires des logiciels de design", "Gibt Zwischendateien von KI-Tools und temporäre Render-Assets sicher frei", "Libere con seguridad archivos intermedios de herramientas de IA y recursos de diseño", "Libera in sicurezza i file intermedi degli strumenti IA e i render temporanei dei software di grafica", "Libere com segurança arquivos intermediários de ferramentas de IA e renderizações temporárias")
        add(.categoryAppBundle, "App", "App", "App", "App", "App",
            "App", "App", "App", "App", "App")
        add(.categoryAppLeftoversDesc, "清除已卸载应用遗留的各类文件", "清除已卸載應用遺留的各類檔案", "Remove files left behind by previously uninstalled apps", "すでに削除されたアプリが残した各種ファイルを一掃", "이전에 삭제된 앱이 남긴 잔여 파일을 제거합니다",
            "Supprimez les fichiers laissés par des applications supprimées", "Entfernen Sie Dateien, die von gelöschten Apps hinterlassen wurden", "Elimine los archivos dejados por aplicaciones ya desinstaladas", "Rimuovi i file rimasti da app disinstallate in precedenza", "Remova arquivos deixados para trás por apps já desinstalados")
        add(.categoryAppLeftoversTitle, "应用残留清理", "應用殘留清理", "Leftovers Cleanup", "残りファイルのクリーンアップ", "잔여 파일 정리",
            "Nettoyage des résidus", "Reste-Bereinigung", "Limpieza de restos", "Pulizia residui", "Limpeza de Resíduos")
        add(.categoryAppSupport, "应用支持", "應用程式支援", "App Support", "アプリサポート", "앱 지원 데이터",
            "Support d’app", "App-Support", "Soporte de app", "Supporto app", "Suporte do App")
        add(.categoryAppUninstallDesc, "彻底卸载应用并清除全部关联残留", "徹底卸載應用並清除全部關聯殘留", "Cleanly uninstall apps and erase all associated leftovers", "アプリを完全に削除し、関連する残りファイルをすべて消去", "앱을 완전히 제거하고 모든 연관 잔여 파일을 정리합니다",
            "Désinstallez proprement les applications et effacez tous les résidus", "Apps sauber deinstallieren und alle zugehörigen Reste löschen", "Desinstale aplicaciones por completo y elimine todos los restos asociados", "Disinstalla le app in modo pulito ed elimina tutti i residui associati", "Desinstale aplicativos com segurança e apague todos os resíduos associados")
        add(.categoryAppUninstallTitle, "应用程序卸载", "應用程式卸載", "Uninstaller", "アンインストーラ", "응용 프로그램 제거",
            "Désinstallateur", "Deinstallationsprogramm", "Desinstalador", "Programma di disinstallazione", "Desinstalador")
        add(.categoryApplicationCacheSubtitle, "可安全清理的各类应用程序运行时缓存与着色器", "可安全清理的各類應用程序運行時緩存與著色器", "Safely cleanable application runtime caches and shader buffers", "安全にクリーンアップできる各種アプリのランタイムキャッシュとシェーダー", "안전하게 정리할 수 있는 각종 애플리케이션 런타임 캐시 및 셰이더",
            "Caches d'exécution et shaders d'applications pouvant être nettoyés en toute sécurité", "Sicher entfernbare App-Laufzeitcaches und Shader-Puffer", "Cachés de ejecución y sombreadores de aplicaciones que se pueden limpiar con seguridad", "Cache di runtime e shader delle applicazioni eliminabili in sicurezza", "Caches de tempo de execução e sombreadores de aplicativos que podem ser limpos com segurança")
        add(.categoryApplicationCacheTitle, "应用缓存", "應用緩存", "App Caches", "アプリキャッシュ", "앱 캐시",
            "Caches d'applications", "App-Caches", "Cachés de aplicaciones", "Cache delle app", "Caches de aplicativos")
        add(.categoryAssociatedData, "关联数据", "關聯資料", "Associated Data", "関連データ", "연관 데이터",
            "Données associées", "Zugehörige Daten", "Datos asociados", "Dati associati", "Dados Associados")
        add(.categoryBackgroundServices, "后台服务", "背景服務", "Background Services", "バックグラウンドサービス", "백그라운드 서비스",
            "Services d’arrière-plan", "Hintergrunddienste", "Servicios en segundo plano", "Servizi in background", "Serviços em segundo plano")
        add(.categoryCache, "缓存", "快取", "Cache", "キャッシュ", "캐시",
            "Cache", "Cache", "Caché", "Cache", "Cache")
        add(.categoryClutteredFilesSubtitle, "占用空间的陈旧杂乱文件", "佔用空間的陳舊雜亂文件", "Cluttered and obsolete files consuming storage space", "ストレージ容量を占有している不要な雑多ファイル", "저장 공간을 낭비하는 오래되고 복잡한 불필요 파일",
            "Fichiers encombrants et obsolètes occupant de l'espace", "Überflüssige und veraltete Dateien, die Speicherplatz belegen", "Archivos obsoletos y desordenados que ocupan espacio", "File obsoleti e disordinati che occupano spazio", "Arquivos obsoletos e desordenados que ocupam espaço")
        add(.categoryCommunicationCacheSubtitle, "微信、飞书、QQ等已下载的图片、视频临时缓存", "微信、飛書、QQ等已下載的圖片、視頻臨時緩存", "Temporary image and video caches from WeChat, Feishu, QQ, etc.", "WeChat、Feishu、QQ などのダウンロード済み画像・動画の一時キャッシュ", "WeChat, Feishu, QQ 등에서 다운로드된 이미지 및 비디오 임시 캐시",
            "Caches temporaires d'images et vidéos téléchargées depuis WeChat, Feishu, QQ, etc.", "Temporäre Bild- und Video-Caches von WeChat, Feishu, QQ usw.", "Cachés temporales de imágenes y vídeos descargados de WeChat, Feishu, QQ, etc.", "Cache temporanee di immagini e video scaricati da WeChat, Feishu, QQ, ecc.", "Caches temporários de imagens e vídeos baixados do WeChat, Feishu, QQ, etc.")
        add(.categoryCommunicationCacheTitle, "通讯工具缓存", "通訊工具緩存", "Messaging Apps Cache", "メッセージアプリキャッシュ", "메신저 캐시",
            "Caches de messagerie", "Messenger-Caches", "Cachés de mensajería", "Cache app di messaggistica", "Caches de mensagens")
        add(.categoryContainer, "容器", "容器", "Container", "コンテナ", "컨테이너",
            "Conteneur", "Container", "Contenedor", "Contenitore", "Contêiner")
        add(.categoryCookies, "Cookies", "Cookies", "Cookies", "Cookie", "쿠키",
            "Cookies", "Cookies", "Cookies", "Cookie", "Cookies")
        add(.categoryCrashReports, "崩溃报告", "當機報告", "Crash Reports", "クラッシュレポート", "충돌 보고서",
            "Rapports de crash", "Absturzberichte", "Informes de fallos", "Report di crash", "Relatórios de Falha")
        add(.categoryDailyAppsAndSystem, "日常应用与系统", "日常應用與系統", "Daily Apps & System", "日常アプリとシステム", "일반 앱 및 시스템",
            "Apps quotidiennes et système", "Alltägliche Apps & System", "Apps cotidianas y sistema", "App quotidiane e sistema", "Apps diários e sistema")
        add(.categoryDailyAppsAndSystemDesc, "清理浏览器、日常软件和系统生成的临时缓存与运行日志", "清理瀏覽器、日常軟件和系統生成的臨時緩存與運行日誌", "Clean temporary caches and runtime logs generated by browsers, everyday software, and the system", "ブラウザ、常用アプリ、システムが生成した一時キャッシュや実行ログをクリーンアップ", "브라우저, 일상 소프트웨어 및 시스템이 생성한 임시 캐시와 실행 로그 정리",
            "Nettoyez les caches temporaires et journaux générés par les navigateurs et le système", "Bereinigen Sie temporäre Caches und Protokolle von Browsern, Alltags-Apps und dem System", "Limpie cachés temporales y registros generados por navegadores, software y el sistema", "Pulisci cache temporanee e log generati da browser, software comune e dal sistema", "Limpe caches temporários e logs gerados por navegadores, softwares diários e pelo sistema")
        add(.categoryDevAndBuildCaches, "开发与构建缓存", "開發與構建緩存", "Development & Build Caches", "開発およびビルドキャッシュ", "개발 및 빌드 캐시",
            "Caches de développement et de compilation", "Entwicklungs- & Build-Caches", "Cachés de desarrollo y compilación", "Cache di sviluppo e compilazione", "Caches de desenvolvimento e compilação")
        add(.categoryDeveloperEnvironmentCacheTitle, "开发环境缓存", "開發環境緩存", "Developer Environment Caches", "開発環境キャッシュ", "개발 환경 캐시",
            "Caches d'environnement de développement", "Entwicklungsumgebungs-Caches", "Cachés del entorno de desarrollo", "Cache dell'ambiente di sviluppo", "Caches de ambiente de desenvolvimento")
        add(.categoryExpiredChatFiles, "过期聊天文件", "過期聊天文件", "Expired Chat Files", "期限切れのチャットファイル", "만료된 대화 파일",
            "Fichiers de discussion expirés", "Abgelaufene Chat-Dateien", "Archivos de chat caducados", "File di chat scaduti", "Arquivos de chat expirados")
        add(.categoryGroupContainer, "共享容器", "共享容器", "Group Container", "共有コンテナ", "공유 컨테이너",
            "Conteneur partagé", "Geteilter Container", "Contenedor compartido", "Contenitore condiviso", "Contêiner compartilhado")
        add(.categoryGroupContainerAlt, "群组容器", "群組容器", "Group Container", "グループコンテナ", "그룹 컨테이너",
            "Conteneur de groupe", "Gruppencontainer", "Contenedor de grupo", "Contenitore gruppo", "Contêiner de Grupo")
        add(.categoryHardwareSensors, "传感器", "傳感器", "Sensors", "センサー", "센서",
            "Capteurs", "Sensoren", "Sensores", "Sensori", "Sensores")
        add(.categoryHttpStorage, "HTTP 存储", "HTTP 儲存", "HTTP Storage", "HTTP ストレージ", "HTTP 저장소",
            "Stockage HTTP", "HTTP-Speicher", "Almacenamiento HTTP", "Archiviazione HTTP", "Armazenamento HTTP")
        add(.categoryLargeFilesSubtitle, "长时间未打开的归档包、视频或占用巨量磁盘的单文件", "長時間未打開的歸檔包、視頻或佔用巨量磁盤的單文件", "Long-unopened archives, videos, or giant single files consuming disk space", "長期間開かれていないアーカイブ、動画、または大容量の単一ファイル", "오랫동안 열지 않은 압축 파일, 비디오 또는 대용량 단일 파일",
            "Archives, vidéos ou fichiers volumineux non ouverts depuis longtemps", "Lange ungeöffnete Archive, Videos oder riesige Einzeldateien", "Archivos comprimidos, vídeos o archivos gigantes no abiertos en mucho tiempo", "Archivi, video o file giganti non aperti da molto tempo", "Arquivos compactados, vídeos ou arquivos gigantes não abertos há muito tempo")
        add(.categoryLargeFilesTitle, "超大文件", "超大文件", "Large Files", "大容量ファイル", "대용량 파일",
            "Fichiers volumineux", "Große Dateien", "Archivos grandes", "File di grandi dimensioni", "Arquivos grandes")
        add(.categoryLaunchAgent, "启动代理", "啟動代理", "Launch Agent", "起動エージェント", "시작 에이전트",
            "Agent de lancement", "Launch-Agent", "Agente de inicio", "Agente di avvio", "Agente de Inicialização")
        add(.categoryLocalAiModelsSubtitle, "本地 AI 运行模型缓存、HuggingFace 与临时权重", "本地 AI 運行模型緩存、HuggingFace 與臨時權重", "Local AI runtime model caches, HuggingFace, and temporary weights", "ローカル AI モデルキャッシュ、HuggingFace、一時ウェイトファイル", "로컬 AI 실행 모델 캐시, HuggingFace 및 임시 가중치 데이터",
            "Caches de modèles IA locaux, HuggingFace et poids temporaires", "Lokale KI-Modellcaches, HuggingFace und temporäre Weights", "Cachés de modelos de IA locales, HuggingFace y pesos temporales", "Cache di modelli IA locali, HuggingFace e pesi temporanei", "Caches de modelos locais de IA, HuggingFace e pesos temporários")
        add(.categoryLogs, "日志", "日誌", "Logs", "ログ", "로그",
            "Journaux", "Protokolle", "Registros", "Log", "Logs")
        add(.categoryMessagingAndSocialMedia, "通讯与社交媒体", "通訊與社交媒體", "Messaging & Social Media", "メッセージおよびソーシャルメディア", "메신저 및 소셜 미디어",
            "Messagerie et réseaux sociaux", "Kommunikation & Soziale Medien", "Mensajería y redes sociales", "Messaggistica e social media", "Mensagens e redes sociais")
        add(.categoryMessagingDeepScanDesc, "深度检索微信、飞书、钉钉等通讯软件本地缓存与离线文件", "深度檢索微信、飛書、釘釘等通訊軟件本地緩存與離線文件", "Deep scan local caches and offline media from WeChat, Lark, DingTalk, and other apps", "WeChat、Lark、DingTalk などのメッセージアプリのローカルキャッシュとオフラインファイルを詳細スキャン", "WeChat, Lark, DingTalk 등 메신저 앱의 로컬 캐시와 오프라인 파일을 정밀 검사",
            "Analyse approfondie des caches locaux et fichiers hors ligne de messageries instantanées", "Tiefenscan lokaler Caches und Offline-Dateien von Messaging-Apps", "Escaneo profundo de cachés locales y archivos de apps de mensajería", "Scansione approfondita di cache locali e file offline di app di messaggistica", "Verificação profunda de caches locais e arquivos offline de apps de mensagens")
        add(.categoryModelsAndDesignAssets, "模型与图形素材", "模型與圖形素材", "Models & Graphic Assets", "モデルおよび画像素材", "모델 및 그래픽 리소스",
            "Modèles et ressources graphiques", "Modelle & Grafik-Assets", "Modelos y recursos gráficos", "Modelli e risorse grafiche", "Modelos e recursos visuais")
        add(.categoryOldDownloadsSubtitle, "超过 30 天未曾触碰的下载文档与临时安装载体", "超過 30 天未曾觸碰的下載文檔與臨時安裝載體", "Downloaded documents and temporary media untouched for over 30 days", "30 日以上開かれていないダウンロード書類や一時ファイル", "30일 이상 사용하지 않은 다운로드 문서 및 임시 파일",
            "Documents et supports temporaires téléchargés non consultés depuis plus de 30 jours", "Heruntergeladene Dokumente und temporäre Medien, die seit über 30 Tagen unberührt sind", "Documentos y archivos temporales descargados no abiertos en más de 30 días", "Documenti e file temporanei scaricati e non toccati da oltre 30 giorni", "Documentos baixados e arquivos temporários não utilizados há mais de 30 dias")
        add(.categoryOldDownloadsTitle, "陈旧下载项", "陳舊下載項", "Old Downloads", "古いダウンロード項目", "오래된 다운로드 항목",
            "Téléchargements anciens", "Veraltete Downloads", "Descargas antiguas", "Vecchi download", "Downloads antigos")
        add(.categoryOverview, "总览", "總覽", "Overview", "概要", "개요",
            "Aperçu", "Übersicht", "Resumen", "Panoramica", "Visão Geral")
        add(.categoryPreferences, "偏好设置", "偏好設定", "Preferences", "環境設定", "환경설정",
            "Préférences", "Einstellungen", "Preferencias", "Preferenze", "Preferências")
        add(.categoryQuickScanDesc, "一次扫描覆盖清理、防护与性能", "一次掃描覆蓋清理、防護與性能", "A single scan covering cleanup, protection, and performance", "クリーンアップ、セキュリティ、パフォーマンスを一度にカバー", "정리, 보호 및 성능 최적화를 단 한 번의 스캔으로 수행합니다",
            "Une seule analyse pour le nettoyage, la sécurité et la vitesse", "Ein einziger Scan für Bereinigung, Schutz und Leistung", "Un solo análisis para limpieza, protección y rendimiento", "Un'unica scansione per pulizia, protezione e prestazioni", "Uma única verificação para limpeza, proteção e desempenho")
        add(.categoryQuickScanTitle, "快速扫描", "快速掃描", "Quick Scan", "クイックスキャン", "빠른 스캔",
            "Analyse rapide", "Schnellscan", "Análisis rápido", "Scansione rapida", "Verificação Rápida")
        add(.categoryReceipt, "安装收据", "安裝收據", "Receipt", "インストール履歴", "설치 영수증",
            "Reçu d’installation", "Installationsquittung", "Recibo de instalación", "Ricevuta installazione", "Recibo de Instalação")
        add(.categorySavedState, "保存状态", "儲存狀態", "Saved State", "保存された状態", "저장된 상태",
            "État enregistré", "Gespeicherter Status", "Estado guardado", "Stato salvato", "Estado Salvo")
        add(.categorySecurityCheckDesc, "检查漏洞并保护隐私痕迹", "檢查漏洞並保護隱私痕跡", "Inspect vulnerabilities and protect your privacy traces", "システムの脆弱性を検査し、プライバシーの痕跡を保護", "취약점을 점검하고 개인정보 사용 흔적을 안전하게 보호합니다",
            "Détectez les vulnérabilités et protégez vos données privées", "Prüfen Sie auf Sicherheitslücken und schützen Sie Ihre Privatsphäre", "Inspeccione vulnerabilidades y proteja sus rastros de privacidad", "Controlla le vulnerabilità e proteggi le tracce della privacy", "Inspecione vulnerabilidades e proteja seus rastros de privacidade")
        add(.categorySecurityCheckTitle, "安全检查", "安全檢查", "Security Check", "セキュリティチェック", "보안 점검",
            "Contrôle de sécurité", "Sicherheitsprüfung", "Revisión de seguridad", "Controllo di sicurezza", "Verificação de Segurança")
        add(.categorySimilarPhotosSubtitle, "连拍、连拍微调或角度极度接近的冗余快照", "連拍、連拍微調或角度極度接近的冗餘快照", "Redundant shots from burst modes or visually near-identical photo angles", "連写ショットやアングルが極めて近い冗長なスナップ写真", "연속 촬영, 미세 조정 샷 또는 각도가 매우 유사한 중복 사진",
            "Prises de vue en rafale ou photos presque identiques sous des angles très proches", "Serienaufnahmen oder redundante Schnappschüsse mit fast identischem Winkel", "Disparos en ráfaga o instantáneas redundantes con ángulos muy similares", "Scatti a raffica o foto ridondanti con angolazioni quasi identiche", "Fotos em sequência ou capturas redundantes com ângulos quase idênticos")
        add(.categorySimilarPhotosTitle, "相似照片", "相似照片", "Similar Photos", "類似写真", "유사한 사진",
            "Photos similaires", "Ähnliche Fotos", "Fotos similares", "Foto simili", "Fotos semelhantes")
        add(.categoryStorageDisk, "磁盘", "磁盤", "Disk", "ディスク", "디스크",
            "Disque", "Festplatte", "Disco", "Disco", "Disco")
        add(.categorySummaryGeneral, "综合", "綜合", "Overview", "総合", "종합",
            "Aperçu", "Übersicht", "Resumen", "Panoramica", "Visão geral")
        add(.categorySystemAndPeripherals, "系统与外围", "系統與外圍", "System & Peripherals", "システムと周辺機器", "시스템 및 주변 기기",
            "Système et périphériques", "System & Peripherie", "Sistema y periféricos", "Sistema e periferiche", "Sistema e periféricos")
        add(.categorySystemLogsAndDiagnosticsTitle, "系统日志与诊断", "系統日誌與診斷", "System Logs & Diagnostics", "システムログと診断", "시스템 로그 및 진단",
            "Journaux système et diagnostics", "Systemprotokolle & Diagnose", "Registros del sistema y diagnósticos", "Log di sistema e diagnostica", "Logs do sistema e diagnósticos")
        add(.categorySystemPurgeableCacheDataTitle, "系统可清理缓存数据", "系統可清理緩存數據", "System Purgeable Cache Data", "システムが自動消去可能なキャッシュデータ", "시스템 자동 정리 가능 캐시 데이터",
            "Données de cache purgeables du système", "Vom System freigebbare Cache-Daten", "Datos de caché purgables del sistema", "Dati di cache eliminabili dal sistema", "Dados de cache purgáveis do sistema")
        add(.categorySystemTuneupDesc, "提升运行速度并进行系统维护", "提升運行速度並進行系統維護", "Boost responsiveness and perform routine maintenance", "動作スピードを向上させ、定期的なシステムメンテナンスを実施", "작업 속도를 향상시키고 시스템 유지 관리 작업을 실행합니다",
            "Améliorez la réactivité et exécutez la maintenance", "Steigern Sie die Reaktionszeit und führen Sie Systemwartungen durch", "Mejore la respuesta del equipo y realice el mantenimiento del sistema", "Migliora la reattività ed esegui la manutenzione ordinaria", "Aumente a velocidade e execute manutenções periódicas no sistema")
        add(.categorySystemTuneupTitle, "系统优化", "系統優化", "System Tuneup", "システム最適化", "시스템 최적화",
            "Optimisation du système", "Systemoptimierung", "Optimización del sistema", "Ottimizzazione del sistema", "Otimização do Sistema")
        add(.categoryTempCache, "临时缓存", "暫存快取", "Temp Cache", "一時キャッシュ", "임시 캐시",
            "Cache temp.", "Temp-Cache", "Caché temp.", "Cache temp.", "Cache temp.")
        add(.categoryTempFiles, "临时文件", "暫存檔案", "Temp Files", "一時ファイル", "임시 파일",
            "Fichiers temp.", "Temp-Dateien", "Archivos temp.", "File temp.", "Arquivos Temp.")
        add(.categoryTrashFilesSubtitle, "各磁盘卷宗中已被删除但尚未彻底清空的文件", "各磁盤卷宗中已被刪除但尚未徹底清空的文件", "Deleted files across volumes waiting to be permanently emptied", "各ボリュームで削除されたが完全には消去されていないファイル", "각 디스크 볼륨에서 삭제되었으나 아직 완전히 비워지지 않은 파일",
            "Fichiers supprimés sur les volumes mais pas encore vidés définitivement", "Gelöschte, aber noch nicht vollständig geleerte Dateien auf allen Volumes", "Archivos eliminados en los volúmenes pero no vaciados por completo", "File eliminati sui volumi ma non ancora svuotati definitivamente", "Arquivos excluídos nos volumes que ainda não foram esvaziados por completo")
        add(.categoryUsedInstallersSubtitle, "已完成安装后遗留在下载目录的 DMG 或 PKG 镜像", "已完成安裝後遺留在下載目錄的 DMG 或 PKG 鏡像", "Leftover DMG or PKG disk images in Downloads folder after installation", "インストール完了後にダウンロードフォルダに残された DMG や PKG イメージ", "설치 완료 후 다운로드 폴더에 남아 있는 DMG 또는 PKG 디스크 이미지",
            "Images disques DMG ou PKG restant dans les téléchargements après installation", "Nach der Installation im Download-Ordner verbliebene DMG- oder PKG-Images", "Imágenes DMG o PKG residuales en Descargas tras completar la instalación", "Immagini disco DMG o PKG rimaste nei Download dopo l'installazione", "Imagens DMG ou PKG deixadas na pasta Downloads após a instalação")
        add(.categoryUsedInstallersTitle, "已用安装包", "已用安裝包", "Used Installers", "使用済みインストーラ", "사용된 설치 패키지",
            "Installeurs déjà utilisés", "Verwendete Installationsdateien", "Instaladores usados", "Pacchetti di installazione utilizzati", "Instaladores usados")
        add(.categoryWebKit, "WebKit", "WebKit", "WebKit", "WebKit", "WebKit",
            "WebKit", "WebKit", "WebKit", "WebKit", "WebKit")
        add(.categoryWebKitCache, "网页缓存", "網頁快取", "Web Caches", "ウェブキャッシュ", "웹 캐시",
            "Caches Web", "Web-Caches", "Cachés web", "Cache web", "Caches da Web")
        add(.categoryWindowState, "窗口状态", "窗口狀態", "Saved Window State", "ウィンドウ状態", "창 상태 복원 정보",
            "État de la fenêtre", "Fensterstatus", "Estado de ventana", "Stato finestra", "Estado da Janela")
        add(.categoryXcodeAndPackageManagers, "Xcode / 包管理器", "Xcode / 包管理器", "Xcode / Package Managers", "Xcode / パッケージマネージャ", "Xcode / 패키지 관리자",
            "Xcode / Gestionnaires de paquets", "Xcode / Paketmanager", "Xcode / Administradores de paquetes", "Xcode / Gestori di pacchetti", "Xcode / Gerenciadores de pacotes")
        add(.categoryXcodeAndPackageManagersDesc, "清除 Xcode 衍生数据、Homebrew、Node 与构建中间产物", "清除 Xcode 衍生數據、Homebrew、Node 與構建中間產物", "Clear Xcode DerivedData, Homebrew, Node, and build intermediate artifacts", "Xcode DerivedData、Homebrew、Node、ビルド中間成果物をクリーンアップ", "Xcode 파생 데이터, Homebrew, Node 및 빌드 중간 산출물 삭제",
            "Videz les données dérivées de Xcode, Homebrew, Node et artefacts de compilation", "Xcode DerivedData, Homebrew, Node und Build-Zwischenprodukte bereinigen", "Borre datos derivados de Xcode, Homebrew, Node y artefactos intermedios de compilación", "Rimuovi dati derivati di Xcode, Homebrew, Node e artefatti di compilazione", "Limpe dados derivados do Xcode, Homebrew, Node e artefatos intermediários de build")
        add(.chartOrbitLens, "行星透镜", "行星透鏡", "Orbit Lens", "オービットレンズ", "궤도 렌즈",
            "Vue orbitale", "Orbit-Ansicht", "Vista orbital", "Vista orbitale", "Visão Orbital")
        add(.chartTreemap, "矩形树图", "矩形樹圖", "Treemap", "ツリーマップ", "트리맵",
            "Carte proportionnelle", "Treemap", "Mapa de árbol", "Mappa ad albero", "Mapa de Árvore")
        add(.chatAppCachesOlderImagesorvideosMustBeReDownloadedAndExpiredMediaCannotBeRecovered, "聊天 App 缓存，旧图片视频清理后需重新下载，过期的找不回", "聊天 App 快取，舊圖片影片清理後需重新下載，過期的找不回", "Chat app caches; older images/videos must be re-downloaded and expired media cannot be recovered", "チャット App のキャッシュ（古い画像・動画は再ダウンロードが必要、期限切れは復元不可）", "메신저 캐시, 오래된 사진/동영상은 다시 다운로드해야 하며 만료된 파일은 복구할 수 없습니다",
            "Caches de messagerie ; les médias anciens devront être retéléchargés", "Chat-App-Caches; ältere Medien müssen neu geladen werden, abgelaufene sind nicht wiederherstellbar", "Cachés de chat; fotos y vídeos antiguos deberán descargarse de nuevo", "Cache delle chat; foto e video vecchi dovranno essere riscaricati", "Caches de chat; fotos e vídeos antigos precisarão ser baixados novamente")
        add(.checkFolderByFolderWhereSpaceWent, "按文件夹逐层查看空间去了哪里", "按資料夾逐層檢視空間去了哪裡", "See where storage went folder by folder", "フォルダごとにストレージの内訳を詳細確認", "폴더별로 저장 공간이 어디에 쓰였는지 확인",
            "Découvrez l'utilisation du stockage dossier par dossier", "Detailliert nach Ordnern sehen, wo Speicherplatz verbraucht wird", "Consulta el uso del almacenamiento carpeta por carpeta", "Scopri dove è finito lo spazio cartella per cartella", "Veja o uso do armazenamento pasta por pasta")
        add(.checkVulnerabilitiesAndProtectPrivacyDesc, "检查漏洞并保护隐私痕迹", "檢查弱點並保護隱私痕跡", "Check vulnerabilities and protect privacy traces", "脆弱性を確認し、プライバシーの痕跡を保護", "취약점 확인 및 개인정보 흔적 보호",
            "Vérifier les vulnérabilités et protéger la confidentialité", "Schwachstellen prüfen und Privatsphäre schützen", "Comprobar vulnerabilidades y proteger la privacidad", "Verifica le vulnerabilità e proteggi le tracce della privacy", "Verificar vulnerabilidades e proteger rastros de privacidade")
        add(.checkedItemsFoundActionableFormat, "勾选项目共发现 %@ 可处理", "勾選項目共發現 %@ 可處理", "Selected items: %@ found to process", "選択項目で %@ を検出", "선택한 항목에서 처리 가능한 %@ 발견",
            "Éléments sélectionnés : %@ trouvés à traiter", "Ausgewählte Objekte: %@ zur Bereinigung gefunden", "Elementos seleccionados: %@ listos para procesar", "Elementi selezionati: %@ trovati da elaborare", "Itens selecionados: %@ encontrados para processar")
        add(.checkingBackgroundProcessesPrompt, "检查在后台运行的应用程序与进程…", "檢查在背景執行的應用程式與處理程序…", "Checking background applications and processes…", "バックグラウンドで実行中のアプリとプロセスを確認中…", "백그라운드에서 실행 중인 앱 및 프로세스 확인 중…",
            "Vérification des applications et processus en arrière-plan…", "Hintergrundanwendungen und -prozesse prüfen…", "Comprobando aplicaciones y procesos en segundo plano…", "Controllo applicazioni e processi in background…", "Verificando aplicativos e processos em segundo plano…")
        add(.checkingDownloadsFolderPrompt, "检查可能不再需要的下载文件…", "檢查可能不再需要的下載檔案…", "Checking downloaded files that might no longer be needed…", "不要になった可能性があるダウンロード項目を確認中…", "더 이상 필요하지 않을 수 있는 다운로드 파일 확인 중…",
            "Vérification des fichiers téléchargés peut-être inutiles…", "Überprüfung möglicherweise nicht mehr benötigter Downloads…", "Comprobando archivos descargados que quizás ya no necesites…", "Controllo file scaricati potenzialmente non necessari…", "Verificando arquivos baixados que talvez não sejam mais necessários…")
        add(.checkingLoginItemsPrompt, "检查开机自动启动的应用程序…", "檢查開機自動啟動的應用程式…", "Checking apps that launch automatically at login…", "ログイン時に自動起動するアプリを確認中…", "로그인 시 자동 실행되는 앱 확인 중…",
            "Vérification des applications lancées au démarrage…", "Automatisch startende Anwendungen prüfen…", "Comprobando aplicaciones que se inician automáticamente…", "Controllo app ad avvio automatico…", "Verificando aplicativos iniciados automaticamente…")
        add(.checkingSnapshotsAndMemoryPrompt, "检查本地快照与内存状态…", "檢查本機快照與記憶體狀態…", "Checking local snapshots and memory state…", "ローカルスナップショットとメモリ状態を確認中…", "로컬 스냅샷 및 메모리 상태 확인 중…",
            "Vérification des instantanés locaux et de la mémoire…", "Lokale Schnappschüsse und Speicherstatus prüfen…", "Comprobando instantáneas locales y estado de memoria…", "Controllo snapshot locali e stato memoria…", "Verificando instantâneos locais e estado da memória…")
        add(.checkingYourSystemPrompt, "正在检查您的系统…", "正在檢查您的系統…", "Checking your system…", "システムを確認中…", "시스템 점검 중…",
            "Vérification de votre système…", "Überprüfe Ihr System…", "Comprobando su sistema…", "Controllo del sistema in corso…", "Verificando seu sistema…")
        add(.chipPowerFormat, "芯片功耗 %.1f W", "晶片功耗 %.1f W", "Chip Power: %.1f W", "チップ消費電力: %.1f W", "칩 소비 전력: %.1f W",
            "Puissance de la puce : %.1f W", "Chip-Leistung: %.1f W", "Potencia del chip: %.1f W", "Potenza del chip: %.1f W", "Potência do chip: %.1f W")
        add(.chooseFolderOrRescanPrompt, "请选择其他文件夹或点击重新扫描", "請選擇其他檔案夾或點擊重新掃描", "Please select another folder or click Rescan", "別のフォルダを選択するか、再スキャンをクリックしてください", "다른 폴더를 선택하거나 다시 스캔을 클릭하세요",
            "Veuillez choisir un autre dossier ou réanalyser", "Bitte anderen Ordner wählen oder erneut scannen", "Selecciona otra carpeta o vuelve a escanear", "Seleziona un’altra cartella o fai clic su Ripeti scansione", "Selecione outra pasta ou clique em Escanear Novamente")
        add(.cleanAiToolCachesLogsAndIdleLocalModelsToReclaimStorage, "清理 AI 工具的缓存、日志以及闲置的本地模型，以释放存储空间。", "清理 AI 工具的快取、日誌以及閒置的本機模型，以釋放儲存空間。", "Clean AI tool caches, logs, and idle local models to reclaim storage.", "AIツールのキャッシュ、ログ、未使用のローカルモデルを削除して容量を確保します。", "AI 도구의 캐시, 로그 및 유휴 로컬 모델을 정리하여 저장 공간을 확보합니다.",
            "Supprimez les caches, journaux et modèles locaux IA inutilisés pour libérer de l’espace.", "Bereinigen Sie KI-Caches, Protokolle und inaktive Modelle für mehr Speicherplatz.", "Limpia cachés, registros y modelos locales de IA para recuperar espacio.", "Pulisci cache, log e modelli IA locali inutilizzati per recuperare spazio.", "Limpe caches de IA, relatórios e modelos locais inativos para liberar espaço.")
        add(.cleanCatDescArchSlice, "二进制架构切片（根据架构红线禁止在位精简）", "二進位架構切片（根據架構紅線禁止在位精簡）", "Binary architecture slices (in-place thinning prohibited by safety policy)", "バイナリアーキテクチャスライス（安全ポリシーにより間引き禁止）", "바이너리 아키텍처 슬라이스 (안전 정책에 따라 내부 압축 금지)",
            "Tranches d'architecture binaire (amincissement interdit par sécurité)", "Binäre Architekturscheiben (Bereinigung durch Sicherheitsrichtlinie untersagt)", "Cortes de arquitectura binaria (adelgazamiento prohibido por seguridad)", "Fette di architettura binaria (alleggerimento vietato per politica di sicurezza)", "Fatias de arquitetura binária (redução local proibida por política de segurança)")
        add(.cleanCatDescBrokenItem, "已失效的配置或启动项，对应的程序不存在", "已失效的設定或啟動項，對應的程式不存在", "Broken preference or startup item, the target app does not exist", "無効な設定または起動項目、対象のアプリは存在しません", "손상된 환경설정 또는 시작 항목, 대상 앱이 존재하지 않음",
            "Élément de démarrage ou préférence orphelin, l'application cible est absente", "Beschädigtes Anmeldeobjekt oder Einstellung, Zielprogramm existiert nicht", "Elemento de inicio o preferencia dañado, el programa de destino no existe", "Elemento di avvio o preferenza danneggiata, l'app associata non esiste", "Item de inicialização ou preferência corrompido, o aplicativo associado não existe")
        add(.cleanCatDescDevCache, "开发工具编译缓存，删除后下次构建会重新生成（耗时）", "開發工具編譯快取，刪除後下次建置會重新產生（耗時）", "Developer build cache, will be regenerated during next build (time-consuming)", "開発ツールのビルドキャッシュ、次回ビルド時に再生成されます（時間要）", "개발 도구 빌드 캐시, 다음 빌드 시 다시 생성됩니다 (시간 소요)",
            "Cache de compilation développeur, sera régénéré lors du prochain build", "Entwickler-Build-Cache, wird beim nächsten Build neu erstellt", "Caché de compilación para desarrolladores, se regenerará en la siguiente compilación", "Cache di build per sviluppatori, verrà rigenerata alla prossima compilazione", "Cache de compilação de desenvolvedor, será regenerado no próximo build")
        add(.cleanCatDescDiagnosticLog, "日志与崩溃诊断报告，可安全删除", "記錄與崩潰診斷報告，可安全刪除", "Logs and crash diagnostic reports, safe to delete", "ログおよびクラッシュ診断レポート、安全に削除できます", "로그 및 충돌 진단 보고서, 안전하게 삭제 가능",
            "Journaux et rapports de diagnostic de crash, suppression sûre", "Protokolle und Absturzberichte, sicher zu löschen", "Registros e informes de diagnóstico de fallos, eliminación segura", "Registri e report di diagnostica dei crash, sicuri da eliminare", "Logs e relatórios de diagnóstico de falhas, seguros para exclusão")
        add(.cleanCatDescDuplicateCopy, "内容完全相同的重复副本（最早一份将被保留）", "內容完全相同的重複副本（最早一份將被保留）", "Identical duplicate copy (the earliest original will be preserved)", "完全に一致する重複コピー（最も古いオリジナルが保持されます）", "내용이 동일한 중복 사본 (가장 오래된 원본 유지)",
            "Copie en double identique (la copie originale la plus ancienne sera conservée)", "Exakte Duplikatskopie (die älteste Originaldatei bleibt erhalten)", "Copia duplicada idéntica (la copia original más antigua se conservará)", "Copia duplicata identica (verrà mantenuto l'originale più vecchio)", "Cópia duplicada idêntica (o original mais antigo será preservado)")
        add(.cleanCatDescIosBackup, "iOS 设备备份，删除后需重新备份才能恢复", "iOS 裝置備份，刪除後需重新備份才能恢復", "iOS device backup, new backup required to restore after deletion", "iOS デバイスバックアップ、削除後は再バックアップが必要になります", "iOS 기기 백업, 삭제 후 복원하려면 새 백업이 필요합니다",
            "Sauvegarde d'appareil iOS, une nouvelle sauvegarde sera requise après suppression", "iOS-Gerätebackup, nach dem Löschen muss ein neues Backup erstellt werden", "Copia de seguridad de dispositivo iOS, requerirá nueva copia para restaurar", "Backup dispositivo iOS, sarà necessario un nuovo backup per il ripristino", "Backup do dispositivo iOS, será necessário um novo backup para restaurar")
        add(.cleanCatDescLanguagePack, "应用程序语言包（根据架构红线禁止在位精简）", "應用程式語言包（根據架構紅線禁止在位精簡）", "Application language packages (in-place thinning prohibited by safety policy)", "アプリケーション言語パッケージ（安全ポリシーにより間引き禁止）", "응용 프로그램 언어 팩 (안전 정책에 따라 내부 압축 금지)",
            "Packs de langue de l'application (amincissement interdit par politique de sécurité)", "App-Sprachpakete (Bereinigung durch Sicherheitsrichtlinie untersagt)", "Paquetes de idioma de apps (adelgazamiento prohibido por política de seguridad)", "Pacchetti di lingua dell'app (alleggerimento sul posto vietato per sicurezza)", "Pacotes de idiomas de aplicativos (redução local proibida por política de segurança)")
        add(.cleanCatDescSafeCache, "应用运行时缓存，可安全删除并自动重建", "應用程式執行時快取，可安全刪除並自動重建", "App runtime cache, safe to delete and automatically rebuilt", "アプリの実行時キャッシュ、安全に削除可能で自動再構築されます", "앱 런타임 캐시, 안전하게 삭제할 수 있으며 자동 재구축됩니다",
            "Cache d'exécution de l'application, suppression sûre et reconstruction auto", "App-Laufzeitcache, sicher zu löschen und wird automatisch neu erstellt", "Caché de tiempo de ejecución de la app, eliminación segura y reconstrucción automática", "Cache di runtime dell'app, sicura da eliminare e ricostruita automaticamente", "Cache de tempo de execução do aplicativo, seguro para exclusão e reconstruído automaticamente")
        add(.cleanCatDescSystemLevel, "系统级位置，部分操作需要管理员权限", "系統級位置，部分操作需要管理員權限", "System location, some operations require administrator privileges", "システム領域、一部の操作には管理者権限が必要です", "시스템 위치, 일부 작업에는 관리자 권한이 필요합니다",
            "Emplacement système, certaines opérations nécessitent des privilèges admin", "Systemebene, einige Vorgänge erfordern Administratorrechte", "Ubicación del sistema, algunas acciones requieren permisos de administrador", "Percorso di sistema, alcune operazioni richiedono privilegi amministratore", "Local do sistema, algumas operações requerem privilégios de administrador")
        add(.cleanCatDescTrashContent, "废纸篓中的内容，删除后不可从废纸篓恢复", "廢紙簍中的內容，刪除後不可從廢紙簍恢復", "Trash contents, cannot be restored from Trash once deleted", "ゴミ箱の中身、削除後はゴミ箱から復元できません", "휴지통의 내용물, 삭제 후에는 휴지통에서 복원할 수 없습니다",
            "Contenu de la corbeille, impossible à restaurer une fois vidé", "Papierkorbinhalt, kann nach dem Löschen nicht wiederhergestellt werden", "Contenido de la papelera, no se podrá restaurar una vez eliminado", "Contenuto del cestino, impossibile da ripristinare dopo l'eliminazione", "Conteúdo da lixeira, não poderá ser restaurado após a exclusão")
        add(.cleanCatDescUnknown, "请确认后再删除", "請確認後再刪除", "Please confirm before deleting", "確認してから削除してください", "확인 후 삭제해 주세요",
            "Veuillez confirmer avant de supprimer", "Bitte vor dem Löschen bestätigen", "Confirme antes de eliminar", "Conferma prima di eliminare", "Confirme antes de excluir")
        add(.cleanCatDescUserContent, "用户目录中的文件，请确认不再需要", "使用者目錄中的檔案，請確認不再需要", "Files in user home folder, please confirm you no longer need them", "ユーザーディレクトリ内のファイル、不要であることをご確認ください", "사용자 홈 폴더의 파일, 더 이상 필요하지 않은지 확인하세요",
            "Fichiers du dossier utilisateur, vérifiez qu'ils ne sont plus nécessaires", "Dateien im Benutzerordner, bitte bestätigen Sie den Bedarf", "Archivos en carpeta de usuario, confirme que ya no los necesita", "File nella cartella utente, conferma di non averne più bisogno", "Arquivos na pasta do usuário, confirme que não precisa mais deles")
        add(.cleanCatTitleArchSlice, "架构切片", "架構切片", "Architecture Slices", "アーキテクチャスライス", "아키텍처 슬라이스",
            "Tranches d'architecture", "Architekturscheiben", "Cortes de arquitectura", "Fette di architettura", "Fatias de arquitetura")
        add(.cleanCatTitleBrokenItem, "损坏项", "損壞項", "Broken Items", "破損項目", "손상된 항목",
            "Éléments endommagés", "Beschädigte Objekte", "Elementos dañados", "Elementi danneggiati", "Itens corrompidos")
        add(.cleanCatTitleDevCache, "开发编译缓存", "開發編譯快取", "Developer Build Cache", "開発ビルドキャッシュ", "개발 빌드 캐시",
            "Cache de build développeur", "Entwickler-Build-Cache", "Caché de compilación", "Cache build sviluppatori", "Cache de build de desenvolvedor")
        add(.cleanCatTitleDiagnosticLog, "诊断日志", "診斷記錄", "Diagnostic Logs", "診断ログ", "진단 로그",
            "Journaux de diagnostic", "Diagnoseprotokolle", "Registros de diagnóstico", "Log diagnostici", "Logs de diagnóstico")
        add(.cleanCatTitleDuplicateCopy, "重复副本", "重複副本", "Duplicate Copies", "重複コピー", "중복 사본",
            "Copies en double", "Duplikate", "Copias duplicadas", "Copie duplicate", "Cópias duplicadas")
        add(.cleanCatTitleIosBackup, "iOS 备份", "iOS 備份", "iOS Backups", "iOS バックアップ", "iOS 백업",
            "Sauvegardes iOS", "iOS-Backups", "Copias de iOS", "Backup iOS", "Backups do iOS")
        add(.cleanCatTitleLanguagePack, "语言包", "語言包", "Language Packs", "言語パック", "언어 팩",
            "Packs linguistiques", "Sprachpakete", "Paquetes de idioma", "Pacchetti lingua", "Pacotes de idiomas")
        add(.cleanCatTitleSafeCache, "常规缓存", "常規快取", "Standard Cache", "通常キャッシュ", "일반 캐시",
            "Cache standard", "Standard-Cache", "Caché estándar", "Cache standard", "Cache padrão")
        add(.cleanCatTitleSystemLevel, "系统级", "系統級", "System Level", "システムレベル", "시스템 수준",
            "Niveau système", "Systemebene", "Nivel de sistema", "Livello di sistema", "Nível do sistema")
        add(.cleanCatTitleTrashContent, "废纸篓内容", "廢紙簍內容", "Trash Contents", "ゴミ箱の内容", "휴지통 내용물",
            "Contenu de la corbeille", "Papierkorbinhalt", "Contenido de la papelera", "Contenuto del cestino", "Conteúdo da lixeira")
        add(.cleanCatTitleUserContent, "用户内容", "使用者內容", "User Content", "ユーザーコンテンツ", "사용자 콘텐츠",
            "Contenu utilisateur", "Benutzerinhalt", "Contenido de usuario", "Contenuto utente", "Conteúdo do usuário")
    }

    static func populateBatch3(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.cleanDmgAndPkgInstallersDesc, "清理已安装或失效的 .dmg 与 .pkg 安装包", "清理已安裝或失效的 .dmg 與 .pkg 安裝套件", "Clean up installed or obsolete .dmg and .pkg packages", "インストール済みまたは不要な .dmg および .pkg を削除", "설치되었거나 불필요한 .dmg 및 .pkg 패키지 정리",
            "Nettoyer les packages .dmg et .pkg installés ou obsolètes", "Installierte oder veraltete .dmg- und .pkg-Pakete bereinigen", "Limpiar paquetes .dmg y .pkg instalados u obsoletos", "Pulisci i pacchetti .dmg e .pkg installati o obsoleti", "Limpar pacotes .dmg e .pkg instalados ou obsoletos")
        add(.cleanExactDuplicateFilesDesc, "清理不同位置内容完全相同的文件", "清理不同位置內容完全相同的檔案", "Clean up identical copies of files in different folders", "異なる場所にある完全に同一内容の重複ファイルを整理", "서로 다른 위치에 있는 동일한 내용의 중복 파일을 정리합니다",
            "Supprimez les copies identiques dispersées dans vos dossiers", "Bereinigen Sie identische Kopien von Dateien in verschiedenen Ordnern", "Elimine copias idénticas de archivos en diferentes carpetas", "Pulisci le copie identiche di file archiviate in posizioni diverse", "Remova cópias idênticas de arquivos em diferentes locais")
        add(.cleanLeftoverAppFilesDesc, "清除已卸载应用遗留的各类文件", "清除已解除安裝應用程式遺留的各類檔案", "Remove leftover files from uninstalled applications", "アンインストールされたアプリの残骸ファイルを削除", "삭제된 응용 프로그램의 잔여 파일 제거",
            "Supprimer les fichiers résiduels des applications désinstallées", "Überreste deinstallierter Anwendungen entfernen", "Eliminar archivos residuales de aplicaciones desinstaladas", "Rimuovi i file residui delle applicazioni disinstallate", "Remover arquivos residuais de aplicativos desinstalados")
        add(.cleanRedundantSystemFiles, "清理系统冗余文件", "清理系統冗餘檔案", "Clean redundant system files", "システムの不要ファイルをクリーンアップ", "시스템 불필요 파일 정리",
            "Supprimez les fichiers système inutiles", "Überflüssige Systemdateien bereinigen", "Limpia archivos redundantes del sistema", "Pulisci i file di sistema ridondanti", "Limpar arquivos redundantes do sistema")
        add(.cleanRedundantSystemFilesForPeakPerformanceAndFreeUpDiskSpace, "清理系统冗余文件以实现最佳性能，并释放更多可用空间。", "清理系統冗餘檔案以實現最佳效能，並釋放更多可用空間。", "Clean redundant system files for peak performance and free up disk space.", "不要ファイルを削除してシステム性能を最大限に高め、空き容量を確保します。", "불필요한 시스템 파일을 정리하여 최적의 성능을 유지하고 저장 공간을 확보합니다.",
            "Nettoyez les fichiers inutiles pour des performances maximales et plus d’espace.", "Bereinigen Sie Systemmüll für beste Leistung und mehr Speicherplatz.", "Limpia archivos innecesarios para optimizar el rendimiento y liberar espacio.", "Pulisci i file ridondanti per ottenere le migliori prestazioni e liberare spazio.", "Limpe arquivos desnecessários para obter melhor desempenho e mais espaço.")
        add(.cleanableTag, "可清理", "可清理", "Cleanable", "削減可能", "정리 가능",
            "Nettoyable", "Bereinigbar", "Limpiable", "Pulibile", "Limpável")
        add(.cleaning, "清理中", "清理中", "Cleaning", "クリーンアップ中", "정리 중",
            "Nettoyage en cours", "Wird bereinigt", "Limpiando", "Pulizia in corso", "Limpando")
        add(.cleanupFailedTitle, "清理失败…", "清理失敗…", "Cleanup failed…", "クリーニングに失敗しました…", "청소 실패…",
            "Échec du nettoyage…", "Bereinigung fehlgeschlagen…", "Error en la limpieza…", "Pulizia non riuscita…", "Falha na limpeza…")
        add(.cleanupPartiallyCompletedTitle, "部分项目未完成", "部分項目未完成", "Some items could not be completed", "一部の項目が未完了です", "일부 항목이 완료되지 않았습니다",
            "Certains éléments n'ont pas pu être complétés", "Einige Objekte konnten nicht abgeschlossen werden", "No se pudieron completar algunos elementos", "Alcuni elementi non sono stati completati", "Alguns itens não puderam ser concluídos")
        add(.clearFontCaches, "清理字体缓存", "清理字體快取", "Clear Font Caches", "フォントキャッシュをクリア", "폰트 캐시 정리",
            "Vider les caches de polices", "Schriftarten-Caches leeren", "Borrar cachés de fuentes", "Cancella cache dei caratteri", "Limpar Caches de Fontes")
        add(.clearedNameFormat, "已清空%@", "已清空%@", "%@ Cleared", "%@ を消去しました", "%@ 정리됨",
            "%@ vidé", "%@ geleert", "%@ vaciado", "%@ svuotato", "%@ esvaziado")
        add(.clickToPreviewCheckToSelect, "轻点预览 · 勾选选择", "輕點預覽 · 勾選選擇", "Click to preview · Check to select", "クリックでプレビュー · チェックで選択", "클릭하여 미리보기 · 선택하려면 체크",
            "Cliquer pour prévisualiser · Cocher pour sélectionner", "Klicken für Vorschau · Markieren zum Auswählen", "Haz clic para vista previa · Marca para seleccionar", "Fai clic per l’anteprima · Seleziona con spunta", "Clique para pré-visualizar · Marque para selecionar")
        add(.clipboardHandoffFix, "通用剪贴板与接力修复", "通用剪貼板與接力修復", "Fix Universal Clipboard & Handoff", "ユニバーサルクリップボードとHandoff修復", "공용 클립보드 및 Handoff 복구",
            "Réparer le Presse-papiers universel et Handoff", "Universelle Zwischenablage & Handoff reparieren", "Corregir portapapeles universal y Handoff", "Risolvi Appunti condivisi e Handoff", "Corrigir Área de Transferência Universal e Handoff")
        add(.compactLocalAppDatabases, "紧缩本地应用数据库", "壓縮本機應用程式資料庫", "Compact App SQLite Databases", "アプリのSQLiteデータベースを最適化", "로컬 앱 SQLite 데이터베이스 압축",
            "Compacter les bases SQLite locales", "App-SQLite-Datenbanken komprimieren", "Compactar bases de datos SQLite", "Compatta database SQLite delle app", "Compactar Bancos de Dados SQLite")
        add(.comparingAndFindingDuplicatesPrompt, "比对并查找内容完全相同的重复文件…", "比對並尋找內容完全相同的重複檔案…", "Comparing and finding exact duplicate files…", "内容が完全に一致する重複ファイルを比較・検出中…", "내용이 동일한 중복 파일 비교 및 찾는 중…",
            "Comparaison et recherche des fichiers identiques…", "Vergleichen und Suchen identischer Duplikate…", "Comparando y buscando archivos duplicados exactos…", "Confronto e ricerca di file duplicati esatti…", "Comparando e encontrando arquivos duplicados exatos…")
        add(.completed, "已完成", "已完成", "Completed", "完了", "완료됨",
            "Terminé", "Abgeschlossen", "Completado", "Completato", "Concluído")
        add(.compressedMemory, "已压缩内存 (Compressed)", "已壓縮記憶體 (Compressed)", "Compressed Memory", "圧縮メモリ", "압축된 메모리 (Compressed)",
            "Mémoire compressée", "Komprimierter Speicher", "Memoria comprimida", "Memoria compressa", "Memória Comprimida")
        add(.config, "配置", "設定", "Configure", "設定", "구성",
            "Configurer", "Konfigurieren", "Configurar", "Configura", "Configurar")
        add(.configBackupAndRestoreSubtitle, "安全架构保障", "安全架構保障", "Safety Architecture", "安全アーキテクチャの保証", "보안 아키텍처 보증",
            "Garantie d’architecture sécurisée", "Sicherheitsarchitektur", "Garantía de arquitectura segura", "Sicurezza del sistema", "Arquitetura Segura")
        add(.configBackupAndRestoreTitle, "配置备份与恢复", "配置備份與恢復", "Configuration Backup & Restore", "設定のバックアップと復元", "설정 백업 및 복원",
            "Sauvegarde et restauration de la configuration", "Konfigurations-Backup & Wiederherstellung", "Copia de seguridad y restauración", "Backup e ripristino configurazione", "Backup e Restauração de Configurações")
        add(.configuratorAddTokenBtn, "添加指标", "新增指標", "Add Metric", "項目を追加", "지표 추가",
            "Ajouter une métrique", "Metrik hinzufügen", "Añadir métrica", "Aggiungi metrica", "Adicionar Métrica")
        add(.configuratorCombinedSubtitle, "顶部菜单栏支持直接左右拖拽排序并点击切换数据格式；下方瀑布流面板支持跨度 (1/1 · 1/2 · 1/3) 动态组合拼装", "頂部選單列支援直接左右拖曳排序並點擊切換資料格式；下方瀑布流面板支援跨度 (1/1 · 1/2 · 1/3) 動態組合拼裝", "Drag to reorder menu bar items and click to switch formats. Dropdown waterfall supports 1/1, 1/2, and 1/3 dynamic spans", "メニューバー項目のドラッグ並び替えとフォーマット切り替えに対応。下部パネルは 1/1・1/2・1/3 の可変幅に対応", "메뉴 막대 항목을 드래그하여 순서를 변경하고 클릭하여 포맷을 전환합니다. 하단 패널은 1/1, 1/2, 1/3 가변 너비를 지원합니다",
            "Glissez pour réorganiser les éléments de la barre des menus et cliquez pour changer de format. Prise en charge des largeurs 1/1, 1/2 et 1/3", "Ziehen zum Neuanordnen der Menüleistenelemente, Klick zum Formatwechsel. Unterstützt 1/1, 1/2 und 1/3 Breiten", "Arrastra para reordenar los elementos y haz clic para cambiar el formato. Soporta anchos de 1/1, 1/2 y 1/3", "Trascina per riordinare gli elementi e fai clic per cambiare formato. Supporta larghezze 1/1, 1/2 e 1/3", "Arraste para reordenar itens na barra de menus e clique para alterar formatos. Suporta larguras 1/1, 1/2 e 1/3")
        add(.configuratorDragAndClickHint, "✋ 直接左右拖拽调序 · 🖱️ 点击选格式", "✋ 直接左右拖曳調序 · 🖱️ 點擊選格式", "✋ Drag to reorder · 🖱️ Click to select format", "✋ ドラッグで並び替え · 🖱️ クリックで書式選択", "✋ 드래그하여 순서 변경 · 🖱️ 클릭하여 서식 선택",
            "✋ Glisser pour réorganiser · 🖱️ Cliquer pour choisir le format", "✋ Ziehen zum Neuanordnen · 🖱️ Klick für Format", "✋ Arrastra para reordenar · 🖱️ Clic para elegir formato", "✋ Trascina per riordinare · 🖱️ Fai clic per scegliere il formato", "✋ Arraste para reordenar · 🖱️ Clique para escolher o formato")
        add(.configuratorDragHandleTooltip, "按住拖动手柄调整卡片在瀑布流中的排布顺序", "按住拖動手柄調整卡片在瀑布流中的排布順序", "Hold and drag handle to reorder cards in waterfall", "ハンドルをドラッグしてカードの並び順を変更", "핸들을 드래그하여 카드의 배치 순서를 변경하세요",
            "Faites glisser la poignée pour réorganiser les cartes", "Am Griff ziehen, um Karten in der Übersicht neu anzuordnen", "Arrastra el tirador para reordenar las tarjetas", "Trascina la maniglia per riordinare le schede", "Arraste a alça para reordenar os cartões")
        add(.configuratorEnabledBadge, "已启用", "已啟用", "Enabled", "有効", "활성화됨",
            "Activé", "Aktiviert", "Activado", "Abilitato", "Ativado")
        add(.configuratorFilterOnlyActiveFormat, "仅看已启用 (%d)", "僅看已啟用 (%d)", "Active Only (%d)", "有効のみ (%d)", "활성화된 항목만 (%d)",
            "Activés uniquement (%d)", "Nur aktive (%d)", "Solo activos (%d)", "Solo attivi (%d)", "Apenas Ativos (%d)")
        add(.configuratorFilterShowAllFormat, "显示全部 (%d)", "顯示全部 (%d)", "Show All (%d)", "すべて表示 (%d)", "전체 표시 (%d)",
            "Tout afficher (%d)", "Alle anzeigen (%d)", "Mostrar todos (%d)", "Mostra tutti (%d)", "Mostrar Todos (%d)")
        add(.configuratorHeightEstimateFormat, "弹窗自适应高度: ~%dpt (最大 680pt)", "彈窗自適應高度: ~%dpt (最大 680pt)", "Estimated Popover Height: ~%dpt (Max 680pt)", "推定ポップオーバー高さ: ~%dpt (最大 680pt)", "예상 팝오버 높이: ~%dpt (최대 680pt)",
            "Hauteur estimée : ~%dpt (max 680pt)", "Geschätzte Popover-Höhe: ~%dpt (Max. 680pt)", "Altura estimada del popover: ~%dpt (Máx. 680pt)", "Altezza stimata popover: ~%dpt (Max 680pt)", "Altura Estimada do Popover: ~%dpt (Máx. 680pt)")
        add(.configuratorMenuBarTokensSectionSubtitle, "拖动调整指标显示顺序，点击胶囊切换展示样式", "拖動調整指標顯示順序，點擊膠囊切換展示樣式", "Drag to reorder indicators, click a pill to customize its style", "ドラッグで並び替え、クリックで表示スタイルを変更", "드래그하여 순서 조정, 클릭하여 표시 스타일 변경",
            "Glisser pour réorganiser, cliquer pour changer le format", "Ziehen zum Neuanordnen, Klick für Formate", "Arrastra para reordenar, clic para cambiar formato", "Trascina per riordinare, clic per cambiare formato", "Arraste para reordenar, clique para alterar formato")
        add(.configuratorMenuBarTokensSectionTitle, "菜单栏常驻指标", "選單列常駐指標", "Menu Bar Indicators", "メニューバー常駐項目", "메뉴 막대 상주 항목",
            "Indicateurs de la barre de menus", "Menüleisten-Indikatoren", "Indicadores de la barra de menús", "Indicatori della barra dei menu", "Indicadores da Barra de Menus")
        add(.configuratorQuickSwitchesTitle, "指标快捷开关：", "指標快捷開關：", "Metric Switches:", "モジュール切り替え：", "항목 스위치:",
            "Commutateurs de métriques :", "Metrik-Schalter:", "Interruptores de métricas:", "Selettori metriche:", "Chaves de Métricas:")
        add(.configuratorRemoveTokenBtn, "从顶部菜单栏移除此指标", "從頂部選單列移除此指標", "Remove this metric from menu bar", "この項目をメニューバーから削除", "메뉴 막대에서 이 항목 제거",
            "Retirer cet élément de la barre des menus", "Diesen Eintrag aus der Menüleiste entfernen", "Eliminar esta métrica de la barra de menús", "Rimuovi questo elemento dalla barra dei menu", "Remover esta métrica da barra de menus")
        add(.configuratorSelectFormatHeader, "选择显示数据格式（点击即时生效）：", "選擇顯示資料格式（點擊即時生效）：", "Select Display Format (Applies immediately):", "表示形式を選択（即座に反映）：", "표시 서식 선택 (즉시 적용):",
            "Sélectionner le format d’affichage (application immédiate) :", "Anzeigeformat wählen (wird sofort angewendet):", "Seleccionar formato de visualización (se aplica al instante):", "Seleziona formato di visualizzazione (si applica subito):", "Selecionar Formato de Exibição (aplica imediatamente):")
        add(.configuratorSimulatedBarHeader, "macOS 顶部菜单栏交互式仿真条（按住指标直接左右拖动，点击指标切换格式）：", "macOS 頂部選單列互動式仿真列（按住指標直接左右拖動，點擊指標切換格式）：", "macOS Menu Bar Interactive Simulation (Drag to reorder, click to switch format):", "macOS メニューバーシミュレーション（ドラッグで並び替え、クリックで書式変更）：", "macOS 메뉴 막대 시뮬레이션 (드래그하여 순서 변경, 클릭하여 서식 전환):",
            "Simulation interactive de la barre des menus macOS (Glisser pour réorganiser, cliquer pour changer) :", "Interaktive macOS Menüleistensimulation (Ziehen zum Neuanordnen, Klick für Formate):", "Simulación interactiva de la barra de menús de macOS (Arrastra para reordenar, clic para formato):", "Simulazione interattiva della barra dei menu macOS (Trascina per riordinare, clic per formato):", "Simulação Interativa da Barra de Menus macOS (Arraste para reordenar, clique para formato):")
        add(.configuratorSwitchSpanTooltipFormat, "切换卡片宽度跨度为 %@", "切換卡片寬度跨度為 %@", "Change card width to %@", "カードの幅を %@ に変更", "카드 너비를 %@로 변경",
            "Changer la largeur de la carte à %@", "Kartenbreite auf %@ ändern", "Cambiar el ancho de la tarjeta a %@", "Imposta la larghezza della scheda su %@", "Alterar largura do cartão para %@")
        add(.configuratorTitleCombined, "组合主面板配置", "組合主面板配置", "Combined Panel Settings", "複合パネル設定", "복합 패널 설정",
            "Configuration du panneau combiné", "Einstellungen für Kombi-Panel", "Configuración del panel combinado", "Impostazioni pannello combinato", "Configurações do Painel Combinado")
        add(.configuratorTooltipAddFormat, "点击添加到顶部菜单栏", "點擊添加到頂部選單列", "Click to add to menu bar", "クリックしてメニューバーに追加", "클릭하여 메뉴 막대에 추가",
            "Cliquer pour ajouter à la barre des menus", "Klicken zum Hinzufügen zur Menüleiste", "Haz clic para añadir a la barra de menús", "Fai clic per aggiungere alla barra dei menu", "Clique para adicionar à barra de menus")
        add(.configuratorTooltipDragFormat, "按住直接左右拖动调整位置；点击切换【%@】显示数据格式", "按住直接左右拖動調整位置；點擊切換【%@】顯示資料格式", "Drag to reorder; click to change [%@] display format", "ドラッグで位置調整、クリックで【%@】の表示形式を切り替え", "드래그하여 위치 조정, 클릭하여 [%@] 표시 서식 전환",
            "Glisser pour réorganiser ; cliquer pour modifier le format de [%@]", "Ziehen zum Neuanordnen; Klick ändert das Format für [%@]", "Arrastra para mover; haz clic para cambiar el formato de [%@]", "Trascina per spostare; fai clic per cambiare il formato di [%@]", "Arraste para mover; clique para alterar o formato de [%@]")
        add(.configuratorTooltipHideFormat, "点击从菜单栏隐藏 %@", "點擊從選單列隱藏 %@", "Click to hide %@ from menu bar", "クリックして %@ をメニューバーから非表示", "클릭하여 메뉴 막대에서 %@ 숨기기",
            "Cliquer pour masquer %@ de la barre des menus", "Klicken, um %@ in der Menüleiste auszublenden", "Haz clic para ocultar %@ de la barra de menús", "Fai clic per nascondere %@ dalla barra dei menu", "Clique para ocultar %@ da barra de menus")
        add(.configuratorWaterfallSectionSubtitle, "拖拽卡片调整先后顺序，自由组合下拉状态面板", "拖拽卡片調整先後順序，自由組合下拉狀態面板", "Drag cards to reorder, customize your dropdown status panel", "カードをドラッグして並び替え、ドロップダウンパネルを自由に構成", "카드를 드래그하여 순서를 바꾸고 드롭다운 패널을 자유롭게 구성하세요",
            "Glissez les cartes pour les réorganiser et personnaliser le panneau", "Karten ziehen zum Neuanordnen und Anpassen des Panels", "Arrastra tarjetas para reordenar y personalizar el panel", "Trascina le schede per riordinare e personalizzare il pannello", "Arraste os cartões para reorganizar e personalizar o painel")
        add(.configuratorWaterfallSectionTitle, "下拉面板卡片排版", "下拉麵板卡片排版", "Dropdown Panel Cards", "ドロップダウンカード配置", "드롭다운 패널 카드 레이아웃",
            "Disposition des cartes du panneau", "Panel-Kartenlayout", "Diseño de tarjetas del panel", "Disposizione schede pannello", "Layout dos Cartões do Painel")
        add(.confirmItemsBeforeRemovalTitle, "移除前，请确认要移除的项目", "移除前，請確認要移除的項目", "Confirm items before removal", "削除前に項目を確認してください", "삭제하기 전에 항목을 확인하세요",
            "Veuillez confirmer les éléments avant suppression", "Bitte bestätigen Sie die Elemente vor dem Entfernen", "Confirme los elementos antes de eliminarlos", "Conferma gli elementi prima della rimozione", "Confirme os itens antes de remover")
        add(.confirmTasksToRunTitle, "确认要运行的任务", "確認要運行的任務", "Confirm Tasks to Run", "実行するタスクを確認", "실행할 작업 확인",
            "Confirmer les tâches à exécuter", "Auszuführende Aufgaben bestätigen", "Confirmar tareas a ejecutar", "Conferma le attività da eseguire", "Confirmar tarefas a serem executadas")
        add(.connectionStatus, "连接状态", "連線狀態", "Connection Status", "接続状態", "연결 상태",
            "État de connexion", "Verbindungsstatus", "Estado de conexión", "Stato connessione", "Status da conexão")
        add(.considerRemovingForgottenLargeFilesDesc, "可以考虑删除那些您可能已经遗忘且不再需要的大文件。", "可以考慮刪除那些您可能已經遺忘且不再需要的大檔案。", "Consider removing large files that you might have forgotten and no longer need.", "忘れてしまって不要になった大容量ファイルの削除をご検討ください。", "잊혀진 채 방치된 불필요한 대용량 파일의 삭제를 고려해 보세요.",
            "Envisagez de supprimer les gros fichiers oubliés dont vous n'avez plus besoin.", "Erwägen Sie das Löschen großer Dateien, die Sie nicht mehr benötigen.", "Considere eliminar los archivos grandes olvidados que ya no necesite.", "Valuta di eliminare i file di grandi dimensioni dimenticati che non ti servono più.", "Considere excluir arquivos grandes esquecidos que não são mais necessários.")
        add(.coreApplicationDataDirectoryPluginsLocalDatabasesUserConfigAndOfflineAssets, "应用核心数据目录（含插件扩展、本地数据库、用户配置与离线资源）", "應用程式核心資料目錄（含外掛擴充、本機資料庫、使用者設定與離線資源）", "Core application data directory (plugins, local databases, user config, and offline assets)", "アプリのコアデータフォルダ（プラグイン、ローカルDB、ユーザー設定、オフライン資産）", "앱 핵심 데이터 디렉토리 (플러그인, 로컬 데이터베이스, 사용자 설정 및 오프라인 리소스)",
            "Dossier de données principales (extensions, bases locales, configuration)", "Kerndatenverzeichnis (Plug-ins, lokale Datenbanken, Benutzereinstellungen)", "Directorio de datos principales (plugins, bases de datos locales y ajustes)", "Cartella dati principali dell’app (plugin, database locali e configurazione)", "Diretório principal de dados do app (plugins, bancos de dados locais e configuração)")
        add(.corePluginsLocalBusinessDatabasesAndUserExtensions, "应用核心插件、本地业务数据库与扩展用户数据", "應用核心插件、本地業務資料庫與擴展使用者資料", "Core plugins, local business databases, and user extensions", "アプリ主要プラグイン、ローカルデータベース、拡張ユーザーデータ", "앱 핵심 플러그인, 로컬 데이터베이스 및 확장 사용자 데이터",
            "Plug-ins essentiels, bases de données locales et extensions utilisateur", "Kern-Plugins, lokale Datenbanken und Benutzererweiterungen", "Complementos principales, bases de datos locales y extensiones de usuario", "Plugin principali, database locali ed estensioni utente", "Plug-ins principais, bancos de dados locais e extensões do usuário")
        add(.coresLabel, "核心", "核心", "Cores", "コア", "코어",
            "Cœurs", "Kerne", "Núcleos", "Core", "Núcleos")
        add(.cpuAndMemoryUsageHeader, "CPU% · 内存占用", "CPU% · 記憶體佔用", "CPU% · Memory Usage", "CPU% · メモリ使用量", "CPU% · 메모리 사용량",
            "CPU % · Utilisation mémoire", "CPU-% · Speicherauslastung", "% CPU · Uso de memoria", "% CPU · Utilizzo memoria", "CPU% · Uso de Memória")
        add(.cpuLoadDetails, "CPU 运行详情", "CPU 執行詳情", "CPU Usage Details", "CPU 詳細状況", "CPU 상세 정보",
            "Détails du processeur (CPU)", "CPU-Details", "Detalles del procesador", "Dettagli CPU", "Detalhes da CPU")
        add(.cpuProcessor, "CPU 处理器", "CPU 處理器", "CPU Processor", "CPU プロセッサ", "CPU 프로세서",
            "Processeur CPU", "CPU-Prozessor", "Procesador CPU", "Processore CPU", "Processador CPU")
        add(.creationDate, "创建日期", "建立日期", "Date Created", "作成日", "생성된 날짜",
            "Date de création", "Erstellungsdatum", "Fecha de creación", "Data di creazione", "Data de criação")
        add(.currentLoadState, "当前负载状态", "目前負載狀態", "Load Status", "現在の負荷状態", "현재 부하 상태",
            "État de charge", "Laststatus", "Estado de carga", "Stato del carico", "Status de Carga")
        add(.customizeAcleanMenuBarAndWidgets, "自定义 AClean 菜单栏与监控组件…", "自訂 AClean 選單列與監控組件…", "Customize AClean's Menu Bar & Widgets…", "メニューバーとウィジェットをカスタマイズ…", "메뉴 막대 및 위젯 맞춤설정…",
            "Personnaliser la barre des menus…", "Menüleiste & Widgets anpassen…", "Personalizar barra de menús…", "Personalizza barra dei menu…", "Personalizar Barra de Menus…")
        add(.cycleCountPrefix, "循环", "循環", "Cycles", "充放電回数", "사이클",
            "Cycles", "Zyklen", "Ciclos", "Cicli", "Ciclos")
        add(.daemons, "守护进程", "守護程式", "Daemons", "デーモン", "데몬",
            "Démons", "Daemons", "Demonios", "Demoni", "Daemons")
        add(.daemonsDesc, "在后台常驻运行的系统服务。", "在背景常駐執行的系統服務。", "System services running persistently in the background.", "バックグラウンドで常駐実行されるシステムサービス。", "백그라운드에서 상주 실행되는 시스템 서비스입니다.",
            "Services système exécutés en continu en arrière-plan.", "Systemdienste, die dauerhaft im Hintergrund ausgeführt werden.", "Servicios del sistema que se ejecutan de forma persistente en segundo plano.", "Servizi di sistema eseguiti costantemente in background.", "Serviços do sistema executados continuamente em segundo plano.")
        add(.daily, "每天", "每天", "Daily", "毎日", "매일",
            "Tous les jours", "Täglich", "Diariamente", "Ogni giorno", "Diariamente")
        add(.dark, "暗色", "深色", "Dark", "ダーク", "다크",
            "Sombre", "Dunkel", "Oscuro", "Scuro", "Escuro")
        add(.darkMode, "暗色模式", "深色模式", "Dark Mode", "ダークモード", "다크 모드",
            "Mode sombre", "Dunkelmodus", "Modo oscuro", "Modalità scura", "Modo Escuro")
        add(.dashboardAllIsWellSubtitle, "一切正常", "一切正常", "Everything looks good", "すべて順調です", "모든 상태가 양호합니다",
            "Tout est en ordre", "Alles in bester Ordnung", "Todo en orden", "Tutto in ordine", "Tudo em ordem")
        add(.dashboardAppsUpToDateSubtitle, "应用程序已是最新状态", "應用程式已是最新狀態", "All applications are up to date", "すべてのアプリが最新です", "모든 응용 프로그램이 최신 상태입니다",
            "Toutes les applications sont à jour", "Alle Programme sind auf dem neuesten Stand", "Todas las aplicaciones están actualizadas", "Tutte le applicazioni sono aggiornate", "Todos os aplicativos estão atualizados")
        add(.dashboardJunkSizeFormat, "%@ 的垃圾", "%@ 的垃圾", "%@ of junk", "%@ のジャンク", "%@의 정크 파일",
            "%@ de fichiers inutiles", "%@ Datenmüll", "%@ de basura", "%@ di elementi inutili", "%@ de lixo")
        add(.dashboardMacIsCleanSubtitle, "您的 Mac 电脑很干净", "您的 Mac 電腦很乾淨", "Your Mac is clean", "お使いの Mac はクリーンです", "Mac이 깨끗합니다",
            "Votre Mac est propre", "Ihr Mac ist sauber", "Tu Mac está limpio", "Il tuo Mac è pulito", "Seu Mac está limpo")
        add(.dashboardNoDuplicatesFoundDetail, "未发现重复文件", "未發現重複檔案", "No duplicates found", "重複ファイルはありません", "중복 파일이 없습니다",
            "Aucun doublon trouvé", "Keine Duplikate gefunden", "No se encontraron duplicados", "Nessun duplicato trovato", "Nenhum duplicado encontrado")
        add(.dashboardNoJunkFoundDetail, "未发现垃圾", "未發現垃圾", "No junk found", "ジャンクは見つかりませんでした", "정크 파일이 없습니다",
            "Aucun fichier inutile", "Kein Datenmüll gefunden", "No se encontró basura", "Nessun elemento inutile trovato", "Nenhum lixo encontrado")
        add(.dashboardNoLeftoversDetail, "无残留", "無殘留", "No leftovers", "関連ファイルなし", "잔여 파일 없음",
            "Aucun résidu", "Keine Reste", "Sin restos", "Nessun residuo", "Sem sobras")
        add(.dashboardNoTasksToRunDetail, "无任务待运行", "無任務待執行", "No tasks to run", "実行待ちタスクなし", "실행할 작업 없음",
            "Aucune tâche à exécuter", "Keine Aufgaben auszuführen", "No hay tareas para ejecutar", "Nessuna attività da eseguire", "Nenhuma tarefa para executar")
        add(.dashboardNoUpdatesToInstallDetail, "无待安装的更新", "無待安裝的更新", "No pending updates", "保留中のアップデートなし", "대기 중인 업데이트 없음",
            "Aucune mise à jour en attente", "Keine ausstehenden Updates", "No hay actualizaciones pendientes", "Nessun aggiornamento in sospeso", "Nenhuma atualização pendente")
        add(.dashboardNothingToOrganizeSubtitle, "没有需要整理的内容", "沒有需要整理的內容", "Nothing to declutter", "整理する項目はありません", "정리할 항목이 없습니다",
            "Rien à désencombrer", "Kein Aufräumbedarf", "Nada por organizar", "Niente da riordinare", "Nada para organizar")
        add(.dashboardOneScanAllBenefitsDesc, "一次扫描即可完成清理、防护与性能优化。", "一次掃描即可完成清理、防護與性能優化。", "One scan covers cleaning, protection, and performance optimization.", "1 回のスキャンでクリーンアップ、セキュリティ、パフォーマンス向上を完了。", "한 번의 검사로 정리, 보안 보호 및 성능 최적화를 완료하세요.",
            "Une seule analyse pour le nettoyage, la sécurité et la performance.", "Ein einziger Scan für Bereinigung, Schutz und Leistungsoptimierung.", "Un solo escaneo cubre limpieza, protección y optimización de rendimiento.", "Una sola scansione per pulizia, protezione e ottimizzazione delle prestazioni.", "Uma única verificação cobre limpeza, proteção e otimização de desempenho.")
        add(.dashboardOptimizableTag, "可优化", "可最佳化", "Optimizable", "最適化可能", "최적화 가능",
            "Optimisable", "Optimierbar", "Optimizable", "Ottimizzabile", "Otimizável")
        add(.dashboardOrganizeSizeFormat, "%@ 待整理", "%@ 待整理", "%@ to declutter", "%@ 整理可能", "%@ 정리 대기 중",
            "%@ à désencombrer", "%@ aufzuräumen", "%@ por organizar", "%@ da riordinare", "%@ para organizar")
        add(.dashboardPendingItemsCountFormat, "%d 个待处理项", "%d 個待處理項", "%d items pending", "%d 個の保留中アイテム", "%d개 처리 대기 중",
            "%d éléments en attente", "%d ausstehende Objekte", "%d elementos pendientes", "%d elementi in sospeso", "%d itens pendentes")
        add(.dashboardPerformanceNormalSubtitle, "性能正常", "效能正常", "Performance is optimal", "パフォーマンスは正常です", "성능이 최적 상태입니다",
            "Performances optimales", "Optimale Leistung", "Rendimiento óptimo", "Prestazioni ottimali", "Desempenho ideal")
        add(.dashboardReadyToRunPrompt, "运行任务已准备就绪。看看我们发现了什么：", "運行任務已準備就緒。看看我們發現了什麼：", "Tasks ready to run. Here is what we found:", "タスクの実行準備が完了しました。検出結果：", "작업 실행 준비가 완료되었습니다. 검색된 항목:",
            "Tâches prêtes à être exécutées. Voici ce que nous avons trouvé :", "Aufgaben bereit. Folgendes wurde gefunden:", "Tareas listas para ejecutarse. Esto es lo que encontramos:", "Attività pronte. Ecco cosa abbiamo trovato:", "Tarefas prontas para execução. Veja o que encontramos:")
        add(.dashboardRemovableTag, "可移除", "可移除", "Removable", "削除可能", "제거 가능",
            "Supprimable", "Entfernbar", "Eliminable", "Rimovibile", "Removível")
        add(.dashboardSizeAndItemsCountFormat, "%@ · %d 项", "%@ · %d 項", "%@ · %d items", "%@ · %d 項目", "%@ · %d개 항목",
            "%@ · %d éléments", "%@ · %d Objekte", "%@ · %d elementos", "%@ · %d elementi", "%@ · %d itens")
        add(.dashboardTasksToRunCountFormat, "%d 项待运行的任务", "%d 項待執行的任務", "%d tasks ready to run", "%d 個の実行待ちタスク", "%d개의 실행할 작업",
            "%d tâches à exécuter", "%d Aufgaben bereit", "%d tareas listas para ejecutar", "%d attività pronte", "%d tarefas prontas para executar")
        add(.dashboardToProcessTag, "要处理", "要處理", "To Process", "処理対象", "처리할 항목",
            "À traiter", "Zu verarbeiten", "Por procesar", "Da elaborare", "A Processar")
        add(.dashboardToRunTag, "要运行", "要執行", "To Run", "実行", "실행할 작업",
            "À exécuter", "Ausführen", "Por ejecutar", "Da eseguire", "A Executar")
        add(.dashboardTotalSizeToProcessFormat, "勾选项目共发现 %@ 可处理", "勾選項目共發現 %@ 可處理", "Selected items found %@ ready to clean", "選択項目で合計 %@ の処理対象を発見", "선택한 항목에서 총 %@의 정리 가능 대상 발견",
            "Éléments cochés : %@ prêts à être traités", "Ausgewählte Elemente: %@ bereit zur Bereinigung", "Elementos seleccionados: %@ listos para procesar", "Elementi selezionati: trovati %@ pronti per essere puliti", "Itens selecionados: %@ prontos para limpeza")
        add(.dataCategoryNoteAllApps, "查看 Mac 上安装的所有应用程序，并彻底卸载它们及其关联残留文件。", "檢視 Mac 上安裝的所有應用程式，並徹底解除安裝它們及其關聯殘留檔案。", "View all installed apps on your Mac and cleanly remove them along with associated leftovers.", "Mac にインストールされているすべてのアプリを確認し、関連ファイルごと完全にアンインストールします。", "Mac에 설치된 모든 응용 프로그램을 확인하고 관련 잔여물과 함께 깨끗하게 제거하세요.",
            "Affichez toutes les applications installées sur votre Mac et désinstallez-les proprement avec leurs résidus.", "Alle installierten Apps anzeigen und mitsamt zugehöriger Reste restlos entfernen.", "Revisa todas las apps instaladas en tu Mac y desinstálalas por completo junto con sus restos.", "Visualizza tutte le app installate sul tuo Mac e disinstallale completamente assieme ai file residui.", "Veja todos os aplicativos instalados no seu Mac e desinstale-os completamente junto com os arquivos associados.")
        add(.dataCategoryNoteAllJunk, "查看垃圾清理发现的所有项目并按需清理。", "檢視垃圾清理發現的所有項目並按需清理。", "Review all items found during junk cleaning and remove as needed.", "システムジャンクで見つかったすべての項目を確認し、必要に応じて削除します。", "정크 청소에서 발견된 모든 항목을 검토하고 필요에 따라 청소하세요.",
            "Passez en revue tous les éléments indésirables détectés et nettoyez-les selon vos besoins.", "Überprüfen Sie alle gefundenen Datenmüllobjekte und bereinigen Sie diese nach Bedarf.", "Revisa todos los elementos no deseados encontrados y límpialos según sea necesario.", "Esamina tutti gli elementi inutili rilevati ed eliminali in base alle tue esigenze.", "Revise todos os itens inúteis encontrados e limpe-os conforme necessário.")
        add(.dataCategoryNoteAllModuleItems, "查看当前模块发现的所有项目并按需清理。", "檢視目前模組發現的所有項目並按需清理。", "Review all items discovered in this module and clean up as needed.", "このモジュールで見つかったすべての項目を確認し、必要に応じて整理します。", "이 모듈에서 검색된 모든 항목을 검토하고 필요에 따라 정리하세요.",
            "Consultez tous les éléments découverts dans ce module et nettoyez-les au besoin.", "Alle in diesem Modul gefundenen Objekte ansehen und nach Bedarf bereinigen.", "Revisa todos los elementos detectados en este módulo y límpialos según convenga.", "Esamina tutti gli elementi rilevati in questo modulo e puliscili secondo necessità.", "Revise todos os itens encontrados neste módulo e limpe conforme necessário.")
        add(.dataCategoryNoteAppStoreApps, "从 Mac App Store 下载并安装的受签名保护的应用程序。", "從 Mac App Store 下載並安裝的受簽名保護的應用程式。", "Signed applications downloaded and installed from the Mac App Store.", "Mac App Store からダウンロードしてインストールされた署名付きアプリ。", "Mac App Store에서 다운로드하여 설치된 서명된 응용 프로그램입니다.",
            "Applications signées téléchargées et installées depuis le Mac App Store.", "Signierte Programme, die aus dem Mac App Store heruntergeladen und installiert wurden.", "Aplicaciones firmadas descargadas e instaladas desde la Mac App Store.", "Applicazioni con firma digitale scaricate e installate dal Mac App Store.", "Aplicativos com assinatura digital baixados e instalados da Mac App Store.")
        add(.dataCategoryNoteBackgroundDaemons, "管理在后台静默运行的进程和代理。", "管理在背景默默執行的處理程序和代理程式。", "Manage background processes and agents running silently on your Mac.", "バックグラウンドで静かに動作しているプロセスやエージェントを管理します。", "백그라운드에서 조용히 실행되는 프로세스와 데몬을 관리합니다.",
            "Gérez les processus et agents d'arrière-plan qui s'exécutent discrètement sur votre Mac.", "Verwalten Sie Hintergrundprozesse und Agents, die unbemerkt im Hintergrund laufen.", "Administra los procesos y agentes que se ejecutan en segundo plano en tu Mac.", "Gestisci i processi e i daemon in esecuzione silenziosa in background.", "Gerencie os processos e agentes que operam silenciosamente em segundo plano.")
        add(.dataCategoryNoteLeftovers, "如果您手动删除了一个应用程序文件，其所有残留的项目将保留在系统上。ACleaner 允许您查找并删除这些残留文件，即使主应用程序已被删除。", "如果您手動刪除了一個應用程式檔案，其所有殘留的項目將保留在系統上。ACleaner 允許您尋找並刪除這些殘留檔案，即使主應用程式已被刪除。", "When an app is manually deleted, leftover support files remain. ACleaner detects and purges these remnants easily.", "手動でアプリを削除した場合でも関連ファイルが残ります。ACleaner はそれらを検出し、完全に削除します。", "앱을 수동으로 삭제해도 잔여 지원 파일이 남을 수 있습니다. ACleaner은 삭제된 앱의 잔여물까지 깨끗하게 정리합니다.",
            "Lorsqu'une app est supprimée manuellement, des résidus subsistent. ACleaner vous permet de les repérer et de les éliminer.", "Wird eine App manuell gelöscht, bleiben oft Reste zurück. ACleaner spürt diese Restdateien auf und entfernt sie zuverlässig.", "Al eliminar una app a mano quedan archivos residuales. ACleaner te ayuda a encontrarlos y borrarlos fácilmente.", "Quando un'app viene eliminata a mano, rimangono file residui. ACleaner consente di individuarli e rimuoverli facilmente.", "Ao remover um app manualmente, arquivos residuais continuam no sistema. O ACleaner localiza e elimina essas sobras.")
        add(.dataCategoryNoteLegacy32BitApps, "仅包含 32 位代码的旧应用程序，当前 macOS 系统已无法再运行它们。", "僅包含 32 位元程式碼的舊應用程式，目前 macOS 系統已無法再執行它們。", "Legacy 32-bit applications that are no longer compatible with current macOS versions.", "現在の macOS では実行できないレガシーな 32 ビットアプリ。", "현재 macOS 버전과 호환되지 않는 이전 32비트 응용 프로그램입니다.",
            "Anciennes applications 32 bits qui ne sont plus compatibles avec votre version actuelle de macOS.", "Alte 32-Bit-Programme, die mit aktuellen macOS-Versionen nicht mehr kompatibel sind.", "Aplicaciones antiguas de 32 bits que ya no son compatibles con la versión actual de macOS.", "Vecchie applicazioni a 32 bit che non sono più compatibili con l'attuale versione di macOS.", "Aplicativos antigos de 32 bits que não são mais compatíveis com a versão atual do macOS.")
        add(.dataCategoryNoteMaintenanceTasks, "运行维护脚本优化磁盘性能与系统响应。", "執行維護指令碼最佳化磁碟效能與系統回應。", "Run maintenance scripts to optimize disk performance and system responsiveness.", "メンテナンスタスクを実行してディスクのパフォーマンスと応答速度を最適化します。", "유지 관리 스크립트를 실행하여 디스크 성능과 시스템 응답 속도를 최적화합니다.",
            "Exécutez des scripts d'entretien pour optimiser les performances du disque et la réactivité du système.", "Führen Sie Wartungsskripte aus, um die Festplattenleistung und Reaktionszeit zu optimieren.", "Ejecuta secuencias de mantenimiento para optimizar el rendimiento del disco y del sistema.", "Esegui script di manutenzione per ottimizzare le prestazioni del disco e la reattività del sistema.", "Execute scripts de manutenção para otimizar o desempenho do disco e a agilidade do sistema.")
        add(.dataCategoryNoteOtherApps, "从互联网或第三方开发者网站直接下载安装的独立应用程序。", "從網際網路或第三方開發者網站直接下載安裝的獨立應用程式。", "Standalone applications downloaded directly from the internet or third-party developer websites.", "インターネットやサードパーティの開発者サイトから直接入手したアプリ。", "인터넷이나 타사 개발자 웹사이트에서 직접 다운로드하여 설치한 독립형 앱입니다.",
            "Applications autonomes téléchargées directement depuis Internet ou des sites tiers.", "Eigenständige Programme, die direkt aus dem Web oder von Entwickler-Websites geladen wurden.", "Aplicaciones independientes descargadas directamente de internet o de sitios de terceros.", "Applicazioni autonome scaricate direttamente da Internet o da siti di terze parti.", "Aplicativos independentes baixados diretamente da internet ou do site dos desenvolvedores.")
        add(.dataCategoryNoteSetappApps, "通过 Setapp 订阅服务安装的应用程序。", "透過 Setapp 訂閱服務安裝的應用程式。", "Applications installed via the Setapp subscription service.", "Setapp サブスクリプションサービス経由でインストールされたアプリ。", "Setapp 구독 서비스를 통해 설치된 응용 프로그램입니다.",
            "Applications installées via le service d'abonnement Setapp.", "Über den Setapp-Abonnementdienst installierte Programme.", "Aplicaciones instaladas a través de la suscripción de Setapp.", "Applicazioni installate tramite il servizio di abbonamento Setapp.", "Aplicativos instalados por meio da assinatura do Setapp.")
        add(.dataCategoryNoteStartupItems, "管理开机时自动启动的应用程序。", "管理開機時自動啟動的應用程式。", "Manage applications that launch automatically when your Mac starts up.", "Mac の起動時に自動的に起動するアプリを管理します。", "Mac 시작 시 자동으로 실행되는 응용 프로그램을 관리합니다.",
            "Gérez les applications qui s'ouvrent automatiquement au démarrage de votre Mac.", "Verwalten Sie Programme, die beim Start Ihres Macs automatisch gestartet werden.", "Administra las aplicaciones que se inician automáticamente al arrancar el Mac.", "Gestisci le applicazioni che si avviano automaticamente all'accensione del Mac.", "Gerencie os aplicativos que iniciam automaticamente ao ligar o seu Mac.")
        add(.dataCategoryNoteSystemJunk, "冗余文件会占用存储空间，影响设备发挥最佳性能。", "冗餘檔案會佔用儲存空間，影響裝置發揮最佳效能。", "Redundant files take up valuable disk space and impact device performance.", "不要なファイルは貴重なストレージを消費し、システムの動作に影響を与えます。", "불필요한 파일은 디스크 공간을 차지하고 시스템 성능에 영향을 줍니다.",
            "Les fichiers redondants occupent de l'espace de stockage et réduisent les performances.", "Überflüssige Dateien belegen Speicherplatz und beeinträchtigen die Spitzenleistung.", "Los archivos redundantes ocupan espacio y afectan el rendimiento del dispositivo.", "I file ridondanti occupano spazio prezioso e influiscono sulle prestazioni del sistema.", "Arquivos redundantes ocupam espaço de armazenamento e afetam o desempenho do dispositivo.")
        add(.dataCategoryNoteUnusedApps, "列出超过 6 个月未打开的应用程序。卸载闲置应用以释放宝贵存储空间。", "列出超過 6 個月未開啟的應用程式。解除安裝閒置應用以釋放寶貴儲存空間。", "List applications unopened for over 6 months. Uninstall unused apps to reclaim precious storage.", "6か月以上開かれていないアプリを一覧表示します。不要なアプリを削除して空き容量を増やしましょう。", "6개월 이상 열지 않은 앱을 나열합니다. 사용하지 않는 앱을 제거하여 저장 공간을 확보하세요.",
            "Répertoriez les applications non ouvertes depuis plus de 6 mois pour libérer un espace précieux.", "Apps auflisten, die seit über 6 Monaten nicht geöffnet wurden. Ungenutzte Apps entfernen, um Speicher zu gewinnen.", "Lista las aplicaciones que no has abierto en más de 6 meses. Desinstala las que no uses para liberar espacio.", "Elenca le applicazioni non aperte da oltre 6 mesi. Disinstalla le app inutilizzate per recuperare spazio.", "Lista os aplicativos não abertos há mais de 6 meses. Desinstale aplicativos ociosos para liberar espaço.")
        add(.dataCategoryNoteUnusedBinaries, "从应用程序中删除未使用的代码版本。您的系统仅需保留适合的版本。", "從應用程式中刪除未使用的程式碼版本。您的系統僅需保留適合的版本。", "Remove unused binary architectures from apps. Keep only the version optimized for your Mac.", "アプリから不要なアーキテクチャバイナリを削除し、Mac に最適なコードのみを残します。", "앱에서 사용하지 않는 바이너리 아키텍처를 제거하고 현재 Mac에 적합한 버전만 유지합니다.",
            "Supprimez les architectures non utilisées des applications. Conservez uniquement la version adaptée à votre Mac.", "Entfernen Sie ungenutzte Binärversionen aus Apps. Behalten Sie nur die für Ihren Mac passende Architektur.", "Elimina arquitecturas binarias no utilizadas de las apps y conserva solo la versión para tu Mac.", "Rimuovi le architetture binarie inutilizzate dalle app e mantieni solo quella adatta al tuo Mac.", "Remova arquiteturas binárias não utilizadas de aplicativos e mantenha apenas a versão adequada para o seu Mac.")
        add(.dataCategoryNoteXcodeJunk, "移除 Xcode 生成的大量派生数据、设备支持与归档，以释放空间。", "移除 Xcode 產生的大量衍生資料、裝置支援與封存，以釋放空間。", "Remove Xcode derived data, device support, and archives to reclaim storage.", "Xcode が生成した派生データ、デバイスサポート、アーカイブを削除して容量を確保します。", "Xcode에서 생성된 파생 데이터, 기기 지원 및 아카이브를 제거하여 공간을 확보합니다.",
            "Supprimez les données dérivées de Xcode, la prise en charge des appareils et les archives pour libérer de l'espace.", "Entfernen Sie Xcode-Derived-Data, Gerätedateien und Archive, um Speicherplatz freizugeben.", "Elimina los datos derivados de Xcode, el soporte para dispositivos y los archivos para liberar espacio.", "Rimuovi i dati derivati di Xcode, i supporti dispositivo e gli archivi per recuperare spazio.", "Remova os dados derivados do Xcode, suporte a dispositivos e arquivos compactados para liberar espaço.")
        add(.dataGroupNoteAiClutter, "Claude、Codex、Gemini、Cursor 等 AI 工具生成的缓存、日志与临时文件。", "Claude、Codex、Gemini、Cursor 等 AI 工具產生的快取、記錄檔與暫存檔。", "Caches, logs, and temporary artifacts produced by AI coding and assistant tools.", "Claude、Codex、Gemini、Cursor などの AI ツールが生成したキャッシュや作業用一時ファイル。", "Claude, Codex, Gemini, Cursor 등 AI 도구가 생성한 캐시, 로그 및 임시 파일입니다.",
            "Caches, journaux et fichiers temporaires générés par les outils d'IA (Claude, Codex, Gemini, Cursor).", "Caches, Protokolle und temporäre Dateien von KI-Tools wie Claude, Codex, Gemini und Cursor.", "Cachés, registros y archivos temporales generados por herramientas de IA como Claude, Gemini o Cursor.", "Cache, log e file temporanei generati da strumenti di intelligenza artificiale come Claude, Gemini e Cursor.", "Caches, registros e arquivos temporários gerados por ferramentas de IA como Claude, Gemini e Cursor.")
        add(.dataGroupNoteBrokenLoginItems, "在某些情况下，应用程序或服务被删除后，其损坏的链接仍保留在您的启动项中。使用 ACleaner 可以轻松解决此问题。", "在某些情況下，應用程式或服務被刪除後，其損壞的連結仍保留在您的啟動項中。使用 ACleaner 可以輕鬆解決此問題。", "Broken pointers to deleted applications can linger in your startup items. ACleaner cleans them up cleanly.", "削除されたアプリへの無効な参照が起動項目に残ることがあります。ACleaner なら簡単に解消できます。", "삭제된 앱의 잘못된 링크가 시작 항목에 남아 있을 수 있습니다. ACleaner으로 깔끔하게 정리하세요.",
            "Des liens orphelins vers des apps supprimées peuvent rester dans vos éléments d'ouverture. ACleaner les résout facilement.", "Fehlerhafte Verknüpfungen zu gelöschten Programmen bleiben oft in den Anmeldeobjekten zurück. ACleaner behebt dies zügig.", "Los enlaces rotos a aplicaciones eliminadas pueden persistir en el inicio. ACleaner los limpia con facilidad.", "I collegamenti interrotti ad app rimosse possono rimanere tra gli elementi di avvio. ACleaner li elimina senza problemi.", "Atalhos corrompidos de aplicativos excluídos podem permanecer na inicialização. O ACleaner os resolve com facilidade.")
        add(.dataGroupNoteBrokenPreferences, "应用程序的偏好设置文件可能会因多种原因而损坏，从而导致运行异常或是稍后无法启动相关应用程序。好消息是，此类问题完全可以避免。", "應用程式的偏好設定檔案可能會因多種原因而損壞，從而導致運作異常或是稍後無法啟動相關應用程式。好消息是，此類問題完全可以避免。", "Corrupted preference files can cause apps to crash or malfunction. Purging them allows apps to reset cleanly.", "破損した設定ファイルはアプリのクラッシュや不具合の原因になります。これらを削除することで正常に戻せます。", "손상된 환경설정 파일은 앱 충돌이나 오작동을 유발할 수 있습니다. 이를 제거하여 정상 상태로 복원할 수 있습니다.",
            "Des préférences endommagées peuvent provoquer des blocages ou des pannes d'apps. Leur suppression résout ces anomalies.", "Beschädigte Einstellungsdateien können zu App-Abstürzen führen. Ein Zurücksetzen behebt solche Störungen.", "Los archivos de preferencias dañados pueden hacer que las apps fallen. Borrarlos restablece su buen funcionamiento.", "I file di preferenze danneggiati possono causare blocchi delle app. La loro rimozione permette un ripristino pulito.", "Arquivos de preferências corrompidos podem fazer aplicativos falharem. Eliminá-los permite redefini-los de forma limpa.")
        add(.dataGroupNoteDefaultFallback, "清理选中的项目以释放 Mac 存储空间。", "清理選取的項目以釋放 Mac 儲存空間。", "Clean selected items to reclaim valuable disk space on your Mac.", "選択した項目を削除して Mac の空き領域を回復します。", "선택한 항목을 청소하여 Mac의 저장 공간을 확보하세요.",
            "Nettoyez les éléments sélectionnés pour libérer de l'espace disque sur votre Mac.", "Ausgewählte Objekte bereinigen, um wertvollen Speicherplatz auf dem Mac freizugeben.", "Limpia los elementos seleccionados para recuperar espacio en tu Mac.", "Pulisci gli elementi selezionati per recuperare spazio prezioso sul tuo Mac.", "Limpe os itens selecionados para recuperar espaço em disco no seu Mac.")
        add(.dataGroupNoteDeletedUsers, "如果您曾经从 Mac 上删除了某个用户帐户，该用户的文件夹中可能仍然有残留数据。这些数据或许还有价值，值得查看。但是您也可以轻松将其删除，以节省空间。", "如果您曾經從 Mac 上刪除了某個使用者帳戶，該使用者的資料夾中可能仍然有殘留資料。這些資料或許還有價值，值得查看。但是您也可以輕鬆將其刪除，以節省空間。", "Orphaned folders from previously deleted macOS user accounts can occupy gigabytes. Remove them to save space.", "以前削除したユーザーアカウントの残存フォルダは容量を圧迫します。不要な場合は安全に消去できます。", "이전에 삭제된 macOS 사용자 계정의 잔여 폴더는 큰 공간을 차지할 수 있습니다. 필요 없을 시 안전하게 삭제하세요.",
            "Les dossiers de comptes utilisateurs supprimés peuvent occuper plusieurs gigaoctets. Supprimez-les pour libérer de l'espace.", "Ordner von früher gelöschten Benutzerkonten können viel Platz belegen. Löschen Sie diese Reste zur Freigabe von Speicher.", "Las carpetas de cuentas de usuario eliminadas pueden ocupar muchos gigas. Bórralas para recuperar almacenamiento.", "Le cartelle di utenti eliminati possono occupare diversi gigabyte. Rimuovile per recuperare spazio prezioso.", "Pastas de contas de usuário já excluídas podem ocupar muito espaço. Remova-as com facilidade para liberar armazenamento.")
        add(.dataGroupNoteDocumentVersions, "您的许多应用程序为正在操作的文稿创建了多个版本，从而保存当前工作结果。然而，您可能只需要最终版本，移除过期的版本可以释放许多空间。", "您的許多應用程式為正在操作的文稿建立了多個版本，從而儲存目前工作結果。然而，您可能只需要最終版本，移除過期的版本可以釋放許多空間。", "Apps save redundant document revisions. Pruning older intermediate versions frees up storage safely.", "ドキュメントの過去の編集バージョンが多数保存されています。古い履歴を削除して空き容量を回復できます。", "앱이 작업 중인 문서의 여러 버전을 자동으로 저장합니다. 오래된 중간 버전을 정리하여 공간을 확보하세요.",
            "Les applications conservent de multiples versions de documents. Supprimer les versions intermédiaires libère de l'espace.", "Programme sichern Zwischenstände von Dokumenten. Das Entfernen alter Fassungen spart viel Speicherplatz.", "Muchas apps guardan versiones anteriores de tus documentos. Eliminar las intermedias libera espacio seguro.", "Le applicazioni salvano versioni intermedie dei documenti. Eliminare le revisioni obsolete libera molto spazio.", "Aplicativos salvam várias versões de documentos em andamento. Remover versões antigas libera espaço com segurança.")
        add(.dataGroupNoteIosBackups, "所有 iOS 设备备份都储存在 Mac 上。您可以轻松移除旧备份，而且不丢失任何数据，同时恢复大量空间。", "所有 iOS 裝置備份都儲存在 Mac 上。您可以輕鬆移除舊備份，而且不遺失任何資料，同時恢復大量空間。", "Old iPhone and iPad local backups take up large storage chunks. Remove unneeded backups safely.", "古い iPhone や iPad のローカルバックアップは膨大な容量を消費します。不要な履歴を安全に整理できます。", "오래된 iPhone 및 iPad 로컬 백업은 큰 공간을 차지합니다. 불필요한 백업을 안전하게 삭제하세요.",
            "Les anciennes sauvegardes locales d'iPhone ou iPad occupent beaucoup d'espace. Supprimez les anciennes en toute sécurité.", "Alte lokale iOS-Backups belegen oft etliche Gigabyte. Entfernen Sie überholte Sicherungen sicher.", "Las copias de seguridad antiguas de iPhone e iPad ocupan mucho espacio. Elimina las que ya no necesites.", "I vecchi backup locali di iPhone e iPad occupano molto spazio. Rimuovi i backup obsoleti in sicurezza.", "Backups locais antigos de iPhone e iPad ocupam muito espaço. Remova com segurança backups que não precisa mais.")
        add(.dataGroupNoteLanguageFiles, "您可以轻松移除应用程序内不需要的本地化语言包，从而帮助您节省大量磁盘空间。", "您可以輕鬆移除應用程式內不需要的本地化語言包，從而幫助您節省大量磁碟空間。", "Safely remove unused language resource packs within applications to recover gigabytes of storage space.", "アプリ内に含まれる使わない言語パックを削除し、ディスク容量を大幅に節約できます。", "응용 프로그램에 포함된 사용하지 않는 언어 팩을 제거하여 디스크 공간을 절약하세요.",
            "Supprimez facilement les modules linguistiques inutilisés dans vos applications pour libérer de l'espace.", "Entfernen Sie mühelos ungenutzte Sprachpakete in Programmen und sparen Sie wertvollen Speicherplatz.", "Elimina paquetes de idiomas que no utilizas dentro de las apps para recuperar valioso espacio.", "Rimuovi facilmente i pacchetti lingua non utilizzati all'interno delle applicazioni per risparmiare spazio.", "Remova com segurança pacotes de idiomas não utilizados em aplicativos para economizar espaço em disco.")
        add(.dataGroupNoteLeftoverFiles, "已卸载应用程序的偏好设置和配置文件是多余的，可以删除。", "已解除安裝應用程式的偏好設定和設定檔是多餘的，可以刪除。", "Preferences and config files from uninstalled apps are redundant and safe to remove.", "アンインストールされたアプリの設定ファイルや構成データは不要なため、安全に削除できます。", "삭제된 앱의 환경설정 및 구성 파일은 불필요하므로 안전하게 제거할 수 있습니다.",
            "Les préférences et fichiers de configuration des applications désinstallées sont superflus et peuvent être supprimés.", "Einstellungen und Konfigurationsdateien deinstallierter Apps sind überflüssig und können sicher gelöscht werden.", "Las preferencias y configuraciones de apps ya eliminadas son redundantes y se pueden borrar.", "Le preferenze e i file di configurazione delle app disinstallate sono superflui e possono essere rimossi.", "As preferências e arquivos de configuração de aplicativos desinstalados são desnecessários e podem ser excluídos.")
        add(.dataGroupNoteLocalModels, "Ollama 和 LM Studio 下载的模型单个可达数 GB。您可以对比相近版本，确认 Mac 是否可运行，并选择需要删除的模型。", "Ollama 和 LM Studio 下載的模型單個可達數 GB。您可以對比相近版本，確認 Mac 是否可執行，並選擇需要刪除的模型。", "Large language models from Ollama or LM Studio can take tens of gigabytes each. Prune idle models easily.", "Ollama や LM Studio のローカルモデルは単体で数 GB に達します。不要なモデルを選択して整理できます。", "Ollama 및 LM Studio에서 다운로드한 로컬 모델은 개당 수 GB에 달합니다. 사용하지 않는 모델을 손쉽게 정리하세요.",
            "Les modèles locaux téléchargés par Ollama ou LM Studio pèsent plusieurs gigaoctets. Nettoyez les modèles inactifs.", "Lokale KI-Modelle von Ollama und LM Studio belegen oft viele Gigabyte. Entfernen Sie ungenutzte Modelle mühelos.", "Los modelos locales de Ollama y LM Studio ocupan varios gigabytes cada uno. Elimina fácilmente los que no uses.", "I modelli locali scaricati da Ollama ed LM Studio possono pesare molti gigabyte. Elimina facilmente quelli inattivi.", "Modelos locais do Ollama e LM Studio podem pesar dezenas de gigabytes cada. Remova facilmente modelos ociosos.")
        add(.dataGroupNoteSystemCacheFiles, "系统应用程序会产生并保存大量的缓存文件。它们最终导致更长的开机时间，整体性能下降甚至有时会使功能失常。", "系統應用程式會產生並儲存大量的快取檔案。它們最終導致更長的開機時間，整體效能下降甚至有時會使功能失常。", "System apps generate large cache files that can lead to longer boot times and sluggish responsiveness.", "システムアプリが生成した大量のキャッシュは、起動時間の長期化や動作低下を引き起こす場合があります。", "시스템 앱에서 생성된 대용량 캐시는 부팅 시간을 지연시키고 전반적인 성능을 저하시킬 수 있습니다.",
            "Les applications système génèrent d'importants fichiers de cache qui peuvent allonger le démarrage et ralentir le système.", "Systemprogramme erzeugen umfangreiche Cache-Dateien, die zu längeren Startzeiten und Leistungseinbußen führen können.", "Las aplicaciones del sistema generan cachés que pueden alargar el tiempo de arranque y ralentizar el equipo.", "Le applicazioni di sistema generano file di cache che possono allungare i tempi di avvio e ridurre la velocità.", "Aplicativos do sistema geram caches que podem aumentar o tempo de inicialização e diminuir o desempenho.")
        add(.dataGroupNoteSystemLogFiles, "系统内置应用程序和服务的活动会被记录并保存到各个日志文件中。这些日志文件仅可能仅对应用程序的开发调试有用，所以您可以毫无顾虑的删除它们。", "系統內建應用程式和服務的活動會被記錄並儲存到各個記錄檔中。這些記錄檔僅可能僅對應用程式的開發除錯有用，所以您可以毫無顧慮的刪除它們。", "System service logs are primarily useful for deep debugging and can be safely purged.", "システムサービスのログは主にデバッグ用途であり、安全に消去できます。", "시스템 서비스 로그는 디버깅 목적 외에는 불필요하므로 안심하고 삭제할 수 있습니다.",
            "Les journaux système ne servent généralement qu'au débogage et peuvent être purgés en toute sécurité.", "Systemprotokolle dienen primär der Fehlersuche und können bedenkenlos gelöscht werden.", "Los registros del sistema solo son útiles para depuración avanzada y pueden eliminarse con seguridad.", "I registri di sistema sono utili quasi esclusivamente per il debug e possono essere rimossi in sicurezza.", "Os registros do sistema destinam-se principalmente a depuração técnica e podem ser removidos com segurança.")
        add(.dataGroupNoteTrashBins, "清空各驱动器上的废纸篓文件以恢复磁盘可用空间。", "清空各磁碟機上的垃圾桶檔案以恢復磁碟可用空間。", "Empty Trash files across all connected drives to restore available storage.", "すべてのドライブのゴミ箱を空にしてストレージ容量を回復します。", "모든 드라이브의 휴지통을 비워 디스크 공간을 확보합니다.",
            "Videz la corbeille de tous les disques pour récupérer de l'espace disponible.", "Papierkorbdateien aller Laufwerke leeren, um Speicherplatz wiederherzustellen.", "Vacía la papelera de todas las unidades para recuperar espacio en disco.", "Svuota il cestino su tutti i dischi per ripristinare lo spazio disponibile.", "Esvazie as lixeiras de todos os discos para restaurar o espaço disponível.")
        add(.dataGroupNoteUniversalBinaries, "Apple 自研处理器已经发布，开发者需要在自己的应用程序中使用两种代码版本。这样应用程序就可以支持搭载英特尔和 Apple 自研芯片的 Mac。您的 Mac 只需要采用一种副本。", "Apple 自研處理器已經發布，開發者需要在自己的應用程式中使用兩種程式碼版本。這樣應用程式就可以支援搭載英特爾和 Apple 自研晶片的 Mac。您的 Mac 只需要採用一種副本。", "Universal binaries contain code for both Intel and Apple Silicon chips. Your Mac only needs the version suited for its processor.", "ユニバーサルバイナリには Intel と Apple シリコン両方のコードが含まれます。お使いの Mac に適したコードのみを残せます。", "유니버설 바이너리에는 Intel 및 Apple Silicon용 코드가 모두 포함되어 있습니다. 현재 Mac에 적합한 버전만 유지하면 됩니다.",
            "Les binaires universels contiennent le code pour Intel et Apple Silicon. Votre Mac n'a besoin que de la version adaptée à sa puce.", "Universal-Binärdateien enthalten Code für Intel und Apple Silicon. Ihr Mac benötigt nur den für ihn passenden Teil.", "Los binarios universales contienen código para Intel y Apple Silicon. Tu Mac solo necesita la arquitectura compatible con su procesador.", "I binari universali contengono codice per Intel e Apple Silicon. Il tuo Mac ha bisogno solo della parte adatta al proprio processore.", "Binários universais contêm código para Intel e Apple Silicon. Seu Mac só precisa do código compatível com o chip dele.")
        add(.dataGroupNoteUserCacheFiles, "应用程序的缓存文件原本用来缩短开机时间，但最终会大量堆积，并导致无法正常运行或整体性能下降。", "應用程式的快取檔案原本用來縮短開機時間，但最終會大量堆積，並導致無法正常運作或整體效能下降。", "Application cache files speed up startup, but over time accumulate heavily and slow down your Mac.", "アプリのキャッシュは起動を高速化しますが、蓄積されると動作不良やパフォーマンス低下の原因になります。", "앱 캐시 파일은 시작 시간을 단축하지만, 시간이 지나면서 대량으로 축적되어 성능을 저하시킵니다.",
            "Les caches d'apps accélèrent le démarrage, mais finissent par s'accumuler et ralentir le système.", "App-Cache-Dateien beschleunigen den Start, häufen sich jedoch mit der Zeit an und können Probleme verursachen.", "Las cachés agilizan la apertura de apps, pero con el tiempo se acumulan y pueden ralentizar el sistema.", "Le cache delle app accelerano l'avvio, ma col tempo si accumulano e possono rallentare il computer.", "Arquivos de cache aceleram o início dos apps, mas com o tempo acumulam-se e causam lentidão.")
        add(.dataGroupNoteUserLogFiles, "应用程序的活动会不断被捕捉并保存到众多日志文件中。一段时间之后，这些文件就会占用大量磁盘空间，却没有任何用处，尤其是那些旧日志。", "應用程式的活動會不斷被捕捉並儲存到眾多記錄檔中。一段時間之後，這些檔案就會佔用大量磁碟空間，卻沒有任何用處，尤其是那些舊記錄。", "App activity logs accumulate quietly over time, consuming disk space without providing ongoing benefits.", "アプリの動作ログは長期間蓄積され、使われないまま多くのディスク容量を消費します。", "앱 활동 로그는 시간이 지남에 따라 축적되어 불필요하게 많은 디스크 공간을 차지합니다.",
            "Les journaux d'activité des applications s'accumulent avec le temps sans utilité pour un usage quotidien.", "Aktivitätsprotokolle häufen sich mit der Zeit an und belegen unnötig Speicherplatz.", "Los registros de actividad de las apps se van acumulando con el tiempo sin aportar utilidad continua.", "I file di registro delle attività si accumulano nel tempo occupando spazio senza un reale vantaggio.", "Registros de atividade acumulam-se gradualmente ao longo do tempo, consumindo espaço em disco sem necessidade.")
        add(.dataGroupNoteXcodeDerivedData, "如果您是一位开发者，那么您会发现 Xcode 生成大量中间版本信息和项目索引。如果您的项目变慢，或者如果您需要更多可用空间，那么将这些项目清理掉非常有用。", "如果您是一位開發者，那麼您會發現 Xcode 產生大量中間版本資訊和專案索引。如果您的專案變慢，或者如果您需要更多可用空間，那麼將這些項目清理掉非常有用。", "Xcode generates massive build caches, intermediate indexes, and device archives that consume huge disk space.", "Xcode はビルドの中間データやプロジェクト索引を大量に生成します。整理することでディスク容量を大幅に回復できます。", "Xcode는 빌드 중간 정보와 프로젝트 인덱스를 대량으로 생성합니다. 이를 정리하면 디스크 공간을 대폭 확보할 수 있습니다.",
            "Xcode génère d'importantes données de compilation et d'indexation. Les purger permet de récupérer un espace disque considérable.", "Xcode generiert riesige Datenmengen an Zwischenversionen und Indizes. Eine Bereinigung verschafft rasch viel freien Speicherplatz.", "Xcode genera gran cantidad de datos intermedios e índices. Limpiarlos es muy útil para ganar espacio libre.", "Xcode genera enormi quantità di dati intermedi e indici di progetto. Rimuoverli è essenziale per liberare spazio su disco.", "O Xcode gera grandes volumes de dados intermediários de compilação. Limpá-los é ideal para recuperar espaço precioso.")
        add(.dataManagerChildrenCountFormat, "%d 项明细", "%d 項明細", "%d details", "%d 件の詳細", "%d개 항목 세부정보",
            "%d détails", "%d Details", "%d detalles", "%d dettagli", "%d detalhes")
        add(.daysAgo, "天前", "天前", "days ago", "日前", "일 전",
            "jours plus tôt", "Tage her", "días atrás", "giorni fa", "dias atrás")
        add(.declutterCleanProjects, "整理项目", "整理項目", "Items to Declutter", "整理する項目", "정리할 항목",
            "Éléments à désencombrer", "Zu bereinigende Objekte", "Elementos para organizar", "Elementi da riordinare", "Itens para Organizar")
        add(.declutterDownloads, "下载项", "下載項目", "Downloads", "ダウンロード", "다운로드",
            "Téléchargements", "Downloads", "Descargas", "Download", "Downloads")
        add(.declutterDownloadsHistoryDesc, "来自浏览器与聊天工具的下载记录。", "來自瀏覽器與聊天工具的下載記錄。", "Download records and temporary files from web browsers and chat tools.", "ブラウザやチャットツールからのダウンロード履歴やファイルです。", "웹 브라우저 및 대화 도구에서 다운로드한 기록과 파일입니다.",
            "Fichiers et historiques de téléchargement issus des navigateurs et messageries.", "Download-Dateien und -Verläufe aus Browsern und Messaging-Apps.", "Archivos e historial de descargas de navegadores web y apps de mensajería.", "File e cronologia di download da browser web e strumenti di chat.", "Arquivos e histórico de downloads de navegadores web e ferramentas de chat.")
        add(.declutterDuplicates, "重复文件", "重複檔案", "Duplicates", "重複ファイル", "중복 파일",
            "Doublons", "Duplikate", "Duplicados", "Duplicati", "Duplicados")
    }

    static func populateBatch4(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.declutterHeroScanSubtitle, "智能检索超大文件、重复文件副本、相似图片及陈旧下载", "智能檢索超大文件、重複文件副本、相似圖片及陳舊下載", "Smart search for large files, duplicate copies, similar photos, and stale downloads", "大容量ファイル、重複ファイルのコピー、類似写真、古いダウンロード項目をスマート検索", "대용량 파일, 중복 복사본, 유사한 사진 및 오래된 다운로드 항목 스마트 검색",
            "Recherche intelligente de gros fichiers, doublons, photos similaires et téléchargements anciens", "Intelligente Suche nach großen Dateien, Duplikaten, ähnlichen Fotos und alten Downloads", "Búsqueda inteligente de archivos grandes, duplicados, fotos similares y descargas antiguas", "Ricerca intelligente di file di grandi dimensioni, duplicati, foto simili e vecchi download", "Busca inteligente por arquivos grandes, duplicatas, fotos semelhantes e downloads antigos")
        add(.declutterHeroSubtitle, "智能扫描超大文件、重复文件副本、相似图片及陈旧下载", "智能掃描超大檔案、重複檔案副本、相似圖片及陳舊下載", "Scan for huge files, duplicate copies, similar photos, and stale downloads", "巨大ファイル、重複ファイル、類似写真、古いダウンロード項目をスキャン", "초대형 파일, 중복 파일 사본, 유사 사진 및 오래된 다운로드 스마트 스캔",
            "Analyse intelligente des très gros fichiers, doublons, photos similaires et vieux téléchargements", "Intelligenter Scan nach riesigen Dateien, Duplikaten, ähnlichen Fotos und alten Downloads", "Escaneo inteligente de archivos gigantes, duplicados, fotos similares y descargas antiguas", "Scansione intelligente di file enormi, duplicati, foto simili e vecchi download", "Escaneamento inteligente de arquivos enormes, duplicatas, fotos semelhantes e downloads antigos")
        add(.declutterHeroTitle, "让你的磁盘井井有条", "讓你的磁碟井井有條", "Keep Your Storage Organized", "ディスクをすっきり整理整頓", "디스크를 깔끔하게 정돈하세요",
            "Gardez votre stockage parfaitement ordonné", "Bringen Sie Ordnung auf Ihr Laufwerk", "Mantén tu almacenamiento organizado", "Mantieni il tuo spazio perfettamente in ordine", "Mantenha seu Armazenamento Organizado")
        add(.declutterInspectSimilarPhotosIntro, "查看近乎相同的照片，并仅保留值得保存的最佳副本。", "查看近乎相同的照片，並僅保留值得保存的最佳副本。", "Review near-identical photos and keep only the best copies worth saving.", "ほぼ同じ写真を比較し、残す価値のある最高の 1 枚だけを保持します。", "거의 동일한 사진들을 확인하고 보관할 가치가 있는 최상의 사진만 유지하세요.",
            "Passez en revue les photos quasi identiques et ne conservez que les meilleures.", "Prüfen Sie fast identische Fotos und behalten Sie nur die besten Aufnahmen.", "Revise fotos casi idénticas y conserve solo las mejores copias que merezca la pena guardar.", "Controlla le foto quasi identiche e conserva solo le migliori copie da salvare.", "Revise fotos quase idênticas e mantenha apenas as melhores cópias que valem a pena salvar.")
        add(.declutterInstallers, "安装包", "安裝封裝檔", "Installers", "インストーラ", "설치 파일",
            "Installateurs", "Installationsprogramme", "Instaladores", "Installer", "Instaladores")
        add(.declutterKeepNewestSimilarPhotoDesc, "每组保留最新的一张，其余副本可删除。", "每組保留最新的一張，其餘副本可刪除。", "The best or newest photo in each similar group is preserved; redundant shots can be removed.", "類似写真グループごとに最適な 1 枚が保持され、重複したショットは安全に削除できます。", "각 유사 사진 그룹마다 가장 최신의 잘 나온 사진이 보존되며 불필요한 컷은 삭제할 수 있습니다.",
            "La photo la plus récente de chaque groupe est préservée ; les doublons peuvent être supprimés.", "Das beste oder neueste Foto jeder Gruppe bleibt erhalten; redundante Aufnahmen können gelöscht werden.", "Se conserva la foto más reciente de cada grupo; las tomas redundantes se pueden eliminar.", "La foto migliore o più recente di ogni gruppo viene conservata; gli scatti ridondanti possono essere eliminati.", "A melhor ou mais recente foto de cada grupo é preservada; as capturas redundantes podem ser removidas.")
        add(.declutterKeepOldestDuplicateDesc, "每组重复文件都会保留最早的一份，其余可安全删除。", "每組重複文件都會保留最早的一份，其餘可安全刪除。", "The oldest original file in each duplicate group is kept by default; copies can be safely removed.", "各重複グループの最も古いオリジナルがデフォルトで保持され、コピーは安全に削除できます。", "각 중복 파일 그룹마다 가장 오래된 원본 1개가 유지되며 나머지는 안전하게 삭제할 수 있습니다.",
            "Le fichier original le plus ancien est conservé par défaut ; les copies peuvent être supprimées.", "Das älteste Original in jeder Duplikatgruppe bleibt erhalten; Kopien können sicher gelöscht werden.", "Se conserva el archivo original más antiguo de cada grupo; las copias se eliminan de forma segura.", "La copia originale più vecchia viene conservata per impostazione predefinita; le altre sono eliminabili.", "O arquivo original mais antigo em cada grupo é mantido por padrão; as cópias podem ser excluídas com segurança.")
        add(.declutterLargeAndOldFiles, "大型和旧文件", "大型與舊檔案", "Large & Old Files", "大容量・古いファイル", "대용량 및 오래된 파일",
            "Fichiers volumineux et anciens", "Große & alte Dateien", "Archivos grandes y antiguos", "File grandi e vecchi", "Arquivos Grandes e Antigos")
        add(.declutterObsoleteInstallersDesc, "下载后已废弃的 DMG 映像、PKG 安装包与 ZIP 归档。", "下載後已廢棄的 DMG 映像、PKG 安裝包與 ZIP 歸檔。", "Obsolete DMG disk images, PKG packages, and ZIP archives left after installation.", "インストール後に不要になった DMG イメージ、PKG パッケージ、ZIP 書庫です。", "설치 후 방치된 DMG 이미지, PKG 설치 패키지 및 ZIP 압축 파일입니다.",
            "Images DMG, paquets PKG et archives ZIP obsolètes restant après installation.", "Veraltete DMG-Images, PKG-Pakete und ZIP-Archive, die nach der Installation verblieben sind.", "Imágenes DMG, paquetes PKG y archivos ZIP obsoletos tras la instalación.", "Immagini DMG, pacchetti PKG e archivi ZIP obsoleti rimasti dopo l'installazione.", "Imagens DMG, pacotes PKG e arquivos ZIP obsoletos deixados após a instalação.")
        add(.declutterReviewDownloadsSaveSpaceDesc, "查看并删除不必要的下载文件，以节省大量空间。", "查看並刪除不必要的下載文件，以節省大量空間。", "Review and remove unnecessary downloaded files to save significant disk space.", "不要なダウンロードファイルを確認・削除して、大幅な空き容量を確保します。", "불필요한 다운로드 파일을 검토하고 삭제하여 디스크 공간을 대폭 절약하세요.",
            "Passez en revue et supprimez les téléchargements inutiles pour économiser de l'espace.", "Löschen Sie unnötige Downloads, um viel Speicherplatz zu sparen.", "Revise y elimine descargas innecesarias para ahorrar una gran cantidad de espacio.", "Rivedi ed elimina i file scaricati non necessari per risparmiare molto spazio.", "Revise e remova downloads desnecessários para economizar um espaço significativo.")
        add(.declutterReviewLargeFilesDesc, "可以考虑删除那些您可能已经遗忘且不再需要的大文件。", "可以考慮刪除那些您可能已經遺忘且不再需要的大文件。", "Consider deleting large forgotten files that you no longer need.", "不要になり忘れ去られた大容量ファイルを見直して削除することを検討してください。", "잊어버렸거나 더 이상 필요하지 않은 대용량 파일의 삭제를 고려해 보세요.",
            "Pensez à supprimer les gros fichiers oubliés dont vous n'avez plus besoin.", "Erwägen Sie das Löschen großer, vergessener Dateien, die Sie nicht mehr benötigen.", "Considere eliminar los archivos grandes olvidados que ya no necesite.", "Prendi in considerazione l'eliminazione di file di grandi dimensioni che non ti servono più.", "Considere excluir arquivos grandes e esquecidos dos quais você não precisa mais.")
        add(.declutterSafetyNote, "安全保障：文件扫描为只读模式，默认移入废纸篓且可随时还原", "安全保障：檔案掃描為只讀模式，預設移入垃圾桶且可隨時還原", "Safe: File scan is read-only. Items are moved to Trash and can be restored anytime.", "安心の安全性：スキャンは読み取り専用で、削除項目はゴミ箱に入るためいつでも復元可能", "안전 보장: 파일 스캔은 읽기 전용이며, 기본적으로 휴지통으로 이동되어 언제든 복원 가능",
            "Sécurisé : l’analyse est en lecture seule. Les fichiers vont à la Corbeille et peuvent être restaurés.", "Sicher: Der Scan ist schreibgeschützt. Dateien landen im Papierkorb und sind wiederherstellbar.", "Seguridad: el escaneo es de solo lectura. Los archivos van a la papelera y se pueden restaurar.", "Sicuro: la scansione è di sola lettura. Gli elementi vanno nel Cestino e sono ripristinabili.", "Seguro: a verificação é somente leitura. Os itens vão para a lixeira e podem ser restaurados.")
        add(.declutterScanningSubtitle, "正在扫描大文件、重复文件与下载项…", "正在掃描大檔案、重複檔案與下載項…", "Scanning large files, duplicates, and downloads…", "大容量ファイル、重複ファイル、ダウンロード項目をスキャン中…", "대용량 파일, 중복 파일 및 다운로드 항목 스캔 중…",
            "Recherche de gros fichiers, doublons et téléchargements…", "Scanne nach großen Dateien, Duplikaten und Downloads…", "Buscando archivos grandes, duplicados y descargas…", "Scansione file grandi, duplicati e download in corso…", "Escaneando arquivos grandes, duplicatas e downloads…")
        add(.declutterScanningTitle, "正在深度整理杂乱…", "正在深度整理雜亂…", "Decluttering your files…", "ファイルを詳細整理中…", "파일 정밀 정리 중…",
            "Désencombrement approfondi en cours…", "Umfassende Bereinigung läuft…", "Organizando archivos a fondo…", "Riordino approfondito in corso…", "Organizando arquivos a fundo…")
        add(.declutterSimilarPhotos, "相似图片", "相似照片", "Similar Photos", "類似写真", "유사한 사진",
            "Photos similaires", "Ähnliche Fotos", "Fotos similares", "Foto simili", "Fotos Semelhantes")
        add(.declutterStartAction, "开始深度整理", "開始深度整理", "Start Decluttering", "詳細整理を開始", "정밀 정리 시작",
            "Démarrer le désencombrement", "Bereinigung starten", "Iniciar organización", "Avvia riordino", "Iniciar Organização")
        add(.deepScanApplicationBundleContainersAppSupportAndPreferencesForACleanRemoval, "深度扫描 App 本体、容器、应用支持与偏好设置，实现干净彻底卸载", "深度掃描 App 本體、容器、應用支援與偏好設定，實現乾淨徹底解除安裝", "Deep scan application bundle, containers, app support, and preferences for a clean removal", "本体、コンテナ、サポート、設定ファイルをスキャンし、綺麗に完全アンインストール", "앱 본체, 컨테이너, 지원 파일 및 환경설정을 정밀 스캔하여 완벽하게 제거합니다",
            "Analyse approfondie de l’app, des conteneurs, du support et des préférences pour une suppression propre", "Tiefenscan von App-Paket, Containern, App-Support und Einstellungen für saubere Deinstallation", "Escaneo profundo de la app, contenedores, soporte y preferencias para una eliminación limpia", "Scansione approfondita del bundle dell’app, container, supporto e preferenze", "Varredura profunda do pacote do app, contêineres, suporte e preferências para remoção limpa")
        add(.deletePermanently, "彻底删除", "徹底刪除", "Delete Permanently", "完全に削除", "영구 삭제",
            "Supprimer définitivement", "Endgültig löschen", "Eliminar permanentemente", "Elimina definitivamente", "Apagar Definitivamente")
        add(.designToolCachesYourDesignFilesAndArtworksRemainUntouched, "设计工具缓存，作品本身不受影响", "設計工具快取，作品本身不受影響", "Design tool caches; your design files and artworks remain untouched", "デザインツールのキャッシュ（作品データ自体は影響を受けません）", "디자인 도구 캐시, 원본 작업물은 영향을 받지 않습니다",
            "Caches d’outils de design ; vos créations restent intactes", "Caches von Design-Tools; Ihre Entwürfe bleiben unberührt", "Cachés de herramientas de diseño; tus proyectos no se ven afectados", "Cache degli strumenti di design; i tuoi progetti restano intatti", "Caches de ferramentas de design; seus projetos permanecem intactos")
        add(.desktopAcPowerSupplying, "桌面交流电源持续供电中", "桌面交流電源持續供電中", "AC desktop power connected", "デスクトップ AC 電源供給中", "데스크탑 AC 전원 지속 공급 중",
            "Alimentation secteur de bureau connectée", "Desktop-Netzteil kontinuierlich angeschlossen", "Alimentación de CA de escritorio conectada", "Alimentazione CA desktop collegata", "Alimentação CA de mesa conectada")
        add(.detecting, "检测中…", "檢測中…", "Detecting…", "検出中…", "감지 중…",
            "Détection en cours…", "Erkennung läuft…", "Detectando…", "Rilevamento in corso…", "Detectando…")
        add(.dialogRestoreDefaultsDesc, "这将把菜单栏显示项、下拉弹窗显示卡片及其排序恢复至出厂推荐设置。", "這將把菜單欄顯示項、下拉彈窗顯示卡片及其排序恢複至出廠推薦設置。", "This will reset all menu bar tokens, dropdown cards, and their ordering to factory defaults.", "メニューバーの表示項目、ドロップダウンカード、並び順が推奨設定にリセットされます。", "메뉴 막대 표시 항목, 드롭다운 카드 및 순서가 권장 기본값으로 복원됩니다.",
            "Cela rétablira les éléments de la barre des menus, cartes et ordre recommandés par défaut.", "Dadurch werden alle Menüleistensymbole, Dropdown-Karten und ihre Reihenfolge zurückgesetzt.", "Esto restablecerá los elementos de la barra de menús, tarjetas y orden a los valores recomendados.", "Questo ripristinerà gli elementi della barra dei menu, le schede e il loro ordine ai valori predefiniti.", "Isso redefinirá todos os itens da barra de menus, cartões e ordem para os padrões recomendados.")
        add(.dialogRestoreDefaultsTitle, "恢复默认配置？", "恢複默認配置？", "Restore Defaults?", "デフォルトに戻しますか？", "기본 설정으로 복원하시겠습니까?",
            "Rétablir la configuration par défaut ?", "Standardeinstellungen wiederherstellen?", "¿Restaurar ajustes predeterminados?", "Ripristinare le impostazioni predefinite?", "Restaurar configurações padrão?")
        add(.directConnection, "内网直连", "內網直連", "Direct Connection", "ダイレクト接続", "내부망 직접 연결",
            "Connexion directe", "Direkte Verbindung", "Conexión directa", "Connessione diretta", "Conexão Direta")
        add(.directoryIsEmpty, "当前目录为空", "當前目錄為空", "Current directory is empty", "現在のフォルダは空です", "현재 디렉토리가 비어 있습니다",
            "Le répertoire actuel est vide", "Aktuelles Verzeichnis ist leer", "La carpeta actual está vacía", "La cartella corrente è vuota", "O diretório atual está vazio")
        add(.disableMenuBarCompanion, "关闭监控伴侣", "關閉監控伴侶", "Disable Menu Bar Companion", "メニューバー監視を終了", "메뉴 막대 모니터 닫기",
            "Désactiver le compagnon de la barre des menus", "Menüleisten-Begleiter deaktivieren", "Cerrar monitor de barra de menús", "Chiudi compagno barra dei menu", "Desativar Companheiro da Barra de Menus")
        add(.disableNetworkUsbDSStore, "禁用外接盘与网络 .DS_Store", "停用外接硬碟與網路 .DS_Store", "Disable Network & USB .DS_Store", "外部ドライブとネットワーク上の.DS_Store作成を無効化", "네트워크 및 USB .DS_Store 생성 방지",
            "Désactiver .DS_Store sur réseau et USB", ".DS_Store auf Netzwerk & USB deaktivieren", "Desactivar .DS_Store en red y USB", "Disabilita .DS_Store su rete e USB", "Desativar .DS_Store em Rede e USB")
        add(.disableStartupItem, "停用启动项", "停用啟動項", "Disable Startup Item", "起動項目を無効化", "시작 프로그램 비활성화",
            "Désactiver l’élément au démarrage", "Autostart-Objekt deaktivieren", "Desactivar elemento de inicio", "Disattiva elemento di avvio", "Desativar Item de Inicialização")
        add(.disabledItemNameFormat, "已停用 %@", "已停用 %@", "Disabled %@", "%@ を無効にしました", "%@ 비활성화됨",
            "%@ désactivé", "%@ deaktiviert", "%@ desactivado", "%@ disabilitato", "%@ desativado")
        add(.disabledStartupItemsCountFormat, "已停用 %d 个后台项目", "已停用 %d 個後台項目", "Disabled %d startup items", "%d 件のスタートアップ項目を無効にしました", "%d개 시작 프로그램 비활성화됨",
            "%d éléments d'arrière-plan désactivés", "%d Hintergrundelemente deaktiviert", "%d elementos de inicio desactivados", "%d elementi di avvio disabilitati", "%d itens de inicialização desativados")
        add(.disabledViaLaunchctl, "已停用（launchctl）", "已停用（launchctl）", "Disabled (launchctl)", "無効（launchctl）", "비활성화됨 (launchctl)",
            "Désactivé (launchctl)", "Deaktiviert (launchctl)", "Desactivado (launchctl)", "Disabilitato (launchctl)", "Desativado (launchctl)")
        add(.disconnected, "未连接", "未連接", "Disconnected", "未接続", "연결 안 됨",
            "Déconnecté", "Nicht verbunden", "Desconectado", "Non connesso", "Desconectado")
        add(.discoveredAbandonedInstallersCountFormat, "已找到 %d 个废弃安装包", "已找到 %d 個廢棄安裝套件", "%d abandoned installers found", "%d 件の不要なインストーラを発見", "%d개의 방치된 설치 파일 발견",
            "%d installateurs abandonnés trouvés", "%d verwaiste Installationsprogramme gefunden", "%d instaladores obsoletos encontrados", "%d programmi di installazione abbandonati trovati", "%d instaladores descartados encontrados")
        add(.discoveredAppLeftoversSizeFormat, "发现 %@ 个应用程序残留文件", "發現 %@ 個應用程式殘留檔案", "Found %@ of leftover files", "%@ のアプリ残骸ファイルを検出", "%@의 응용 프로그램 잔여 파일 발견",
            "%@ de résidus d'applications trouvés", "%@ an Anwendungsüberresten gefunden", "Se encontraron %@ de archivos residuales", "Trovati %@ di file residui", "Encontrados %@ em arquivos residuais")
        add(.discoveredBackgroundItemsCountFormat, "已发现 %d 个后台项目", "已發現 %d 個後台項目", "Found %d background items", "%d 個のバックグラウンド項目を発見", "%d개의 백그라운드 항목 발견",
            "%d éléments d'arrière-plan trouvés", "%d Hintergrundobjekte gefunden", "Se encontraron %d elementos en segundo plano", "Trovati %d elementi in background", "%d itens em segundo plano encontrados")
        add(.discoveredBackgroundItemsFormat, "已发现 %d 个后台项目", "已發現 %d 個背景項目", "Found %d background items", "%d 個のバックグラウンド項目を検出", "백그라운드 항목 %d개 발견",
            "%d éléments d'arrière-plan trouvés", "%d Hintergrundobjekte gefunden", "Se encontraron %d elementos en segundo plano", "%d elementi in background trovati", "%d itens em segundo plano encontrados")
        add(.discoveredDownloadsCountFormat, "已找到 %d 个下载项", "已找到 %d 個下載項", "%d downloads found", "%d 件のダウンロード項目を発見", "%d개의 다운로드 항목 발견",
            "%d téléchargements trouvés", "%d Downloads gefunden", "%d descargas encontradas", "%d download trovati", "%d downloads encontrados")
        add(.discoveredDuplicatesCountFormat, "已发现 %d 个重复文件", "已發現 %d 個重複檔案", "%d duplicate files discovered", "%d 件の重複ファイルを検出", "%d개의 중복 파일 발견",
            "%d fichiers en double découverts", "%d Duplikate entdeckt", "%d archivos duplicados descubiertos", "%d file duplicati rilevati", "%d arquivos duplicados descobertos")
        add(.discoveredDuplicatesFormat, "已发现 %d 个重复文件", "已發現 %d 個重複檔案", "Found %d duplicate files", "%d 個の重複ファイルを検出", "중복 파일 %d개 발견",
            "%d fichiers dupliqués trouvés", "%d Duplikate gefunden", "Se encontraron %d archivos duplicados", "%d file duplicati trovati", "%d arquivos duplicados encontrados")
        add(.discoveredHiddenResourcesFormat, "已发现 %d 个隐藏的大型资源与缓存。", "已發現 %d 個隱藏的大型資源與快取。", "Found %d hidden large resources and caches.", "%d 個の隠された大容量リソースとキャッシュを検出。", "숨겨진 대용량 리소스 및 캐시 %d개 발견.",
            "%d ressources et caches cachés volumineux trouvés.", "%d ausgeblendete große Ressourcen und Caches gefunden.", "Se encontraron %d recursos y cachés grandes ocultos.", "Trovati %d risorse e cache nascoste di grandi dimensioni.", "Encontrados %d recursos e caches grandes ocultos.")
        add(.discoveredLargeOldFilesSizeFormat, "已找到 %@ 的大型和旧文件", "已找到 %@ 的大型和舊檔案", "Found %@ of large and old files", "%@ の大容量・古いファイルを発見", "%@의 대용량 및 오래된 파일 발견",
            "%@ de fichiers volumineux et anciens trouvés", "%@ an großen und alten Dateien gefunden", "Se encontraron %@ de archivos grandes y antiguos", "Trovati %@ di file grandi e obsoleti", "%@ em arquivos grandes e antigos encontrados")
        add(.discoveredLeftoversSizeSummaryFormat, "发现 %@ 个应用程序残留文件", "發現 %@ 個應用程式殘留檔案", "Found %@ of application leftover files", "%@ のアプリ残留ファイルを発見", "%@의 애플리케이션 잔여 파일 발견",
            "%@ de fichiers résiduels d'applications trouvés", "%@ an App-Restdateien gefunden", "Se encontraron %@ de archivos residuales de aplicaciones", "Trovati %@ di file residui delle applicazioni", "%@ em arquivos residuais de aplicativos encontrados")
        add(.discoveredLoginItemsCountFormat, "已发现 %d 个开机启动项", "已發現 %d 個開機啟動項", "Found %d startup items", "%d 個のスタートアップ項目を発見", "%d개의 시작 프로그램 발견",
            "%d éléments d'ouverture trouvés", "%d Anmeldeobjekte gefunden", "Se encontraron %d elementos de inicio", "Trovati %d elementi di avvio", "%d itens de inicialização encontrados")
        add(.discoveredLoginItemsFormat, "已发现 %d 个开机启动项", "已發現 %d 個開機啟動項", "Found %d login items", "%d 個のログイン項目を検出", "시동 항목 %d개 발견",
            "%d éléments d'ouverture trouvés", "%d Anmeldeobjekte gefunden", "Se encontraron %d elementos de inicio", "%d elementi di login trovati", "%d itens de início encontrados")
        add(.discoveredObsoleteInstallersCountFormat, "已找到 %d 个废弃安装包", "已找到 %d 個廢棄安裝套件", "Found %d obsolete packages", "%d 個の不要インストーラを検出", "불필요한 설치 패키지 %d개 발견",
            "%d packages obsolètes trouvés", "%d veraltete Pakete gefunden", "Se encontraron %d paquetes obsoletos", "%d pacchetti obsoleti trovati", "%d pacotes obsoletos encontrados")
        add(.discoveredSimilarPhotosCountFormat, "已发现 %d 张相似照片", "已發現 %d 張相似照片", "%d similar photos discovered", "%d 枚の類似写真を検出", "%d장의 유사한 사진 발견",
            "%d photos similaires découvertes", "%d ähnliche Fotos entdeckt", "%d fotos similares descubiertas", "%d foto simili rilevate", "%d fotos semelhantes descobertas")
        add(.discoveredSimilarPhotosFormat, "已发现 %d 张相似照片", "已發現 %d 張相似照片", "Found %d similar photos", "%d 枚の類似写真を検出", "유사한 사진 %d장 발견",
            "%d photos similaires trouvées", "%d ähnliche Fotos gefunden", "Se encontraron %d fotos similares", "%d foto simili trovate", "%d fotos semelhantes encontradas")
        add(.discoveredUnsupportedAppsCountFormat, "已发现 %d 个不支持的应用程序", "已發現 %d 個不支援的應用程式", "%d unsupported applications discovered", "%d 件の非対応アプリケーションを検出", "%d개의 지원되지 않는 응용 프로그램 발견",
            "%d applications non prises en charge découvertes", "%d nicht unterstützte Anwendungen entdeckt", "%d aplicaciones no compatibles descubiertas", "%d applicazioni non supportate rilevate", "%d aplicativos não compatíveis descobertos")
        add(.discoveredUnsupportedAppsFormat, "已发现 %d 个不支持的应用程序", "已發現 %d 個不支援的應用程式", "Found %d unsupported applications", "%d 個の非対応アプリを検出", "지원되지 않는 응용 프로그램 %d개 발견",
            "%d applications non prises en charge trouvées", "%d nicht unterstützte Apps gefunden", "Se encontraron %d aplicaciones no compatibles", "%d app non supportate trovate", "%d aplicativos incompatíveis encontrados")
        add(.discoveredUnusedAppsCountFormat, "已发现 %d 个未使用的应用程序", "已發現 %d 個未使用的應用程式", "%d unused applications discovered", "%d 件の未使用アプリケーションを検出", "%d개의 사용하지 않는 응용 프로그램 발견",
            "%d applications inutilisées découvertes", "%d ungenutzte Anwendungen entdeckt", "%d aplicaciones sin usar descubiertas", "%d applicazioni inutilizzate rilevate", "%d aplicativos não utilizados descobertos")
        add(.discoveredUnusedAppsFormat, "已发现 %d 个未使用的应用程序", "已發現 %d 個未使用的應用程式", "Found %d unused applications", "%d 個の未使用アプリを検出", "미사용 응용 프로그램 %d개 발견",
            "%d applications inutilisées trouvées", "%d unbenutzte Apps gefunden", "Se encontraron %d aplicaciones sin usar", "%d app non utilizzate trovate", "%d aplicativos não utilizados encontrados")
        add(.discoveredUpdatableAppsCountFormat, "已识别 %d 个含更新通道的应用", "已識別 %d 個含更新通道的應用程式", "%d apps with update channels identified", "%d 件のアップデートチャネル対応アプリを検出", "업데이트 채널이 있는 응용 프로그램 %d개 확인됨",
            "%d applications avec canal de mise à jour identifiées", "%d Apps mit Update-Kanal erkannt", "%d aplicaciones con canal de actualización identificadas", "%d app con canale di aggiornamento identificate", "%d aplicativos com canal de atualização identificados")
        add(.discoveredUpdatableAppsFormat, "已识别 %d 个含更新通道的应用", "已識別 %d 個含更新通道的應用程式", "Identified %d apps with update channels", "%d 個のアップデートチャネル対応アプリを検出", "업데이트 채널이 있는 응용 프로그램 %d개 확인됨",
            "%d applications avec canal de mise à jour trouvées", "%d Apps mit Update-Kanal gefunden", "Se identificaron %d aplicaciones con canal de actualización", "%d app con canale di aggiornamento trovate", "%d aplicativos com canal de atualização encontrados")
        add(.diskCapacityIoTrends, "磁盘容量与读写趋势", "磁碟容量與讀寫趨勢", "Disk Capacity & I/O Trends", "ディスク容量とアクセス傾向", "디스크 용량 및 읽기/쓰기 추이",
            "Capacité disque et tendances I/O", "Speicherplatz & I/O-Trends", "Capacidad y tendencias de disco", "Capacità disco e andamento I/O", "Capacidade do Disco e Tendências de E/S")
        add(.disks, "磁盘", "磁碟", "Disks", "ディスク", "디스크",
            "Disques", "Festplatten", "Discos", "Dischi", "Discos")
        add(.dnsServer, "DNS 服务器", "DNS 服務器", "DNS Server", "DNS サーバー", "DNS 서버",
            "Serveur DNS", "DNS-Server", "Servidor DNS", "Server DNS", "Servidor DNS")
        add(.dockerAndContainers, "Docker 与容器镜像", "Docker 與容器映像檔", "Docker & Containers", "Docker・コンテナ", "Docker 및 컨테이너",
            "Docker et conteneurs", "Docker & Container", "Docker y contenedores", "Docker e container", "Docker e Contêineres")
        add(.download, "下载", "下載", "Download", "ダウンロード", "다운로드",
            "Téléchargement", "Download", "Descarga", "Scaricamento", "Download")
        add(.downloadLabel, "下载", "下載", "Download", "ダウンロード", "다운로드",
            "Téléchargement", "Download", "Descarga", "Download", "Download")
        add(.downloadedInstallers, "下载目录安装包", "下載項目安裝檔", "Downloaded Installers", "ダウンロード済みインストーラ", "다운로드된 설치 파일",
            "Installateurs téléchargés", "Heruntergeladene Installer", "Instaladores descargados", "Installer scaricati", "Instaladores Baixados")
        add(.downloadsCategoryPrefixFormat, "下载 · %@", "下載 · %@", "Downloads · %@", "ダウンロード · %@", "다운로드 · %@",
            "Téléchargements · %@", "Downloads · %@", "Descargas · %@", "Download · %@", "Downloads · %@")
        add(.downloadsFromBrowsersAndChatsDesc, "来自浏览器与聊天工具的下载记录。", "來自瀏覽器與通訊軟體的下載記錄。", "Downloaded files from browsers and messenger applications.", "ブラウザやチャットツールから保存されたダウンロードファイル。", "브라우저 및 메신저 앱에서 다운로드된 파일들입니다.",
            "Fichiers téléchargés depuis les navigateurs et messageries.", "Heruntergeladene Dateien aus Browsern und Messenger-Apps.", "Descargas de navegadores y herramientas de mensajería.", "File scaricati da browser e applicazioni di messaggistica.", "Arquivos baixados através de navegadores e mensageiros.")
        add(.dragHandleToReorderHorizontalTooltip, "按住卡片手柄可左右拖拽调序", "按住卡片手柄可左右拖曳調序", "Drag handle to reorder horizontally", "ハンドルをドラッグして左右に並べ替え", "핸들을 드래그하여 좌우 순서 변경",
            "Faites glisser pour réorganiser horizontalement", "Griff ziehen, um horizontal neu anzuordnen", "Arrastra el control para reordenar horizontalmente", "Trascina la maniglia per riordinare orizzontalmente", "Arraste a alça para reordenar horizontalmente")
        add(.dragHandleToReorderTooltip, "按住此手柄上下拖动即可平滑重排", "按住此手柄上下拖動即可平滑重排", "Drag handle up or down to reorder smoothly", "ハンドルをドラッグしてスムーズに並べ替え", "핸들을 위아래로 드래그하여 부드럽게 재정렬",
            "Faites glisser la poignée vers le haut ou le bas pour réorganiser", "Griff nach oben oder unten ziehen, um neu anzuordnen", "Arrastre el controlador hacia arriba o hacia abajo para reordenar", "Trascina la maniglia verso l'alto o verso il basso per riordinare", "Arraste a alça para cima ou para baixo para reordenar suavemente")
        add(.dropdownBatteryCardDesc, "展示电池容量健康度、充放电功率 (W)、充满预估与键鼠耳机电量", "展示電池容量健康度、充放電功率 (W)、充滿預估與鍵鼠耳機電量", "Displays battery health, charge watts, remaining time estimate, and accessory levels", "バッテリー容量、充放電電力、充電完了予測、周辺機器残量を表示", "배터리 수명, 충방전 전력, 충전 완료 예상 시간 및 기기 잔량 표시",
            "Affiche l’état de la batterie, la puissance, l’estimation de temps et le niveau des accessoires", "Zeigt Akkugesundheit, Ladeleistung, Restzeit und Zubehörstände an", "Muestra salud de batería, potencia de carga, tiempo restante y accesorios", "Mostra salute batteria, potenza di ricarica, tempo stimato e accessori", "Exibe saúde da bateria, potência de recarga, estimativa de tempo e periféricos")
        add(.dropdownBatteryCardTitle, "电池状态、充放电瓦数与蓝牙外设电量", "電池狀態、充放電瓦數與藍牙外設電量", "Battery Status, Power Watts & Bluetooth Peripherals", "バッテリー状態、電力 (W)、Bluetooth 機器", "배터리 상태, 전력(W) 및 Bluetooth 주변기기",
            "État de la batterie, puissance et périphériques Bluetooth", "Akkustatus, Leistung & Bluetooth-Zubehör", "Estado de batería, consumo y periféricos Bluetooth", "Stato batteria, potenza e periferiche Bluetooth", "Status da Bateria, Potência e Periféricos Bluetooth")
        add(.dropdownFooterToolbarDesc, "实时显示摄像头/麦克风使用状态、一键防休眠、推出外置卷", "即時顯示攝影機/麥克風使用狀態、一鍵防休眠、退出外接磁碟", "Live camera/mic signals, one-click keep awake, and safe volume ejection", "カメラ/マイクの使用状態、ワンクリックスリープ防止、ドライブ取り出し", "카메라/마이크 사용 감지, 원클릭 절전 방지 및 외장 드라이브 추출",
            "État caméra/micro en direct, prévention de veille et éjection sécurisée", "Kamera-/Mikrofonstatus in Echtzeit, Wachbleiben und sicheres Auswerfen", "Señales de cámara/micrófono, mantener activo y expulsar volúmenes", "Stato fotocamera/microfono, prevenzione sospensione ed espulsione volumi", "Sinais de câmera/microfone, prevenção de suspensão e ejeção de unidades")
        add(.dropdownFooterToolbarTitle, "快捷工具栏 (隐私监测 / 咖啡防休眠 / 内存释放)", "快捷工具列 (隱私監測 / 咖啡防休眠 / 記憶體釋放)", "Quick Toolbar (Privacy / Anti-Sleep / Purge)", "クイックツールバー (プライバシー / スリープ防止 / メモリ解放)", "빠른 도구 모음 (개인정보 / 절전 방지 / 메모리 정리)",
            "Barre d’outils rapide (Confidentialité / Éveil / Libération)", "Schnellzugriffsleiste (Datenschutz / Wachbleiben / Speicher)", "Barra de herramientas rápida (Privacidad / Sin reposo / Liberar)", "Barra rapida (Privacy / Anti-sospensione / Libera RAM)", "Barra de Ferramentas Rápida (Privacidade / Sem Suspensão / Liberar)")
        add(.dropdownHealthBannerDesc, "展示综合权重健康评分、芯片型号、运行时间与发光恒星", "展示綜合權重健康評分、晶片型號、運行時間與發光恆星", "Displays system health score, chip model, uptime, and pulsar aura", "ヘルススコア、チップ型番、稼働時間、パルサーを表示", "시스템 건강 점수, 칩 모델, 가동 시간 및 오라 표시",
            "Affiche le score de santé, le modèle de puce, le temps d’activité et l’aura pulsante", "Zeigt den Zustandswert, den Chip-Typ, die Laufzeit und die Pulsar-Aura an", "Muestra la puntuación de estado, modelo de chip, tiempo activo y aura", "Mostra il punteggio di salute, il modello di chip, il tempo di attività e l’aura", "Exibe a pontuação de saúde, modelo do chip, tempo ativo e aura pulsar")
        add(.dropdownHealthBannerTitle, "系统健康度与硬件规格横幅", "系統健康度與硬體規格橫幅", "System Health & Specs Banner", "システムヘルス＆仕様バナー", "시스템 상태 및 사양 배너",
            "Bannière d’état et spécifications", "Systemzustand & Spezifikationen", "Banner de estado y especificaciones", "Banner stato e specifiche", "Banner de Saúde e Especificações")
        add(.dropdownModulesSubtitle, "勾选在控制台弹窗中展示的 Bento 卡片与功能区块", "勾選在主控台彈窗中展示的 Bento 卡片與功能區塊", "Select Bento cards and sections to display in the companion popover", "コンソールポップオーバーに表示する Bento カードと項目を選択", "팝오버 콘솔에 표시할 벤토 카드 및 섹션 선택",
            "Sélectionnez les cartes Bento à afficher dans le menu déroulant", "Wählen Sie die Bento-Karten für das Menüfenster aus", "Elige las tarjetas Bento a mostrar en el panel de control", "Seleziona le schede Bento da mostrare nel riquadro", "Selecione os cartões Bento a serem exibidos no menu suspenso")
        add(.dropdownModulesTitle, "下拉弹窗模块与顺序", "下拉彈窗模組與順序", "Dropdown Popover Modules & Order", "ポップオーバーのモジュールと並び順", "드롭다운 팝오버 모듈 및 순서",
            "Modules du menu déroulant et ordre", "Dropdown-Module & Anordnung", "Módulos y orden del desplegable", "Moduli del menu a comparsa e ordine", "Módulos do Popover e Ordem")
        add(.dropdownHardwareGridDesc, "实时呈现 6 大核心硬件传感器、波形走势与风扇档位控制", "即時呈現 6 大核心硬體感測器、波形走勢與風扇檔位控制", "Live telemetry for 6 core hardware sensors, waveforms, and fan presets", "6 つの主要センサー、波形チャート、ファン制御をリアルタイム表示", "6개 핵심 하드웨어 센서, 파형 그래프 및 팬 프리셋 실시간 표시",
            "Métriques en direct de 6 capteurs clés, graphiques et préréglages de ventilateur", "Live-Werte für 6 Kernsensoren, Wellenformen und Lüfterstufen", "Métricas en vivo de 6 sensores clave, ondas y modos de ventilador", "Metriche in tempo reale di 6 sensori chiave, forme d’onda e ventole", "Telemetria ao vivo de 6 sensores principais, ondas e perfis de ventoinha")
        add(.dropdownHardwareGridTitle, "2×3 核心硬件 Bento 网格 (CPU/GPU/内存/磁盘/网络/风扇)", "2×3 核心硬體 Bento 網格 (CPU/GPU/記憶體/磁碟/網路/風扇)", "2×3 Hardware Bento Grid (CPU/GPU/RAM/Disk/Net/Fan)", "2×3 ハードウェア Bento グリッド", "2×3 하드웨어 벤토 그리드",
            "Grille Bento 2×3 pour le matériel", "2×3 Hardware-Bento-Raster", "Cuadrícula Bento 2×3 de hardware", "Griglia Bento hardware 2×3", "Grade Bento 2×3 de Hardware")
        add(.dropdownNetworkDetailCardDesc, "展示本机 IPv4、公网 IP (ISP)、系统代理与 TCP 握手延迟 (ms)", "展示本機 IPv4、公網 IP (ISP)、系統代理與 TCP 握手延遲 (ms)", "Displays local IPv4, public IP, ISP, proxy, and TCP handshake latency (ms)", "ローカル IPv4、パブリック IP、ISP、プロキシ、TCP ハンドシェイク遅延を表示", "로컬 IPv4, 공인 IP, ISP, 프록시 및 TCP 지연 시간(ms) 표시",
            "Affiche l’IPv4 locale, l’IP publique, le FAI, le proxy et la latence TCP (ms)", "Zeigt lokale IPv4, öffentliche IP, ISP, Proxy und TCP-Latenz (ms) an", "Muestra IPv4 local, IP pública, ISP, proxy y latencia TCP (ms)", "Mostra IPv4 locale, IP pubblico, ISP, proxy e latenza TCP (ms)", "Exibe IPv4 local, IP público, ISP, proxy e latência TCP (ms)")
        add(.dropdownNetworkDetailCardTitle, "网络接口、公网 IP 与代理延迟诊断", "網路介面、公網 IP 與代理延遲診斷", "Network Interfaces, Public IP & Proxy Diagnostics", "ネットワーク、パブリック IP、プロキシ遅延", "네트워크 인터페이스, 공인 IP 및 프록시 지연 진단",
            "Interfaces réseau, IP publique et diagnostic de latence", "Netzwerk, öffentliche IP & Proxy-Latenz", "Interfaces de red, IP pública y diagnóstico de proxy", "Interfacce di rete, IP pubblico e diagnostica proxy", "Interfaces de Rede, IP Público e Diagnóstico de Proxy")
        add(.dropdownSectionsConfigHeaderTitle, "下拉弹窗显示模块与顺序", "下拉彈窗顯示模塊與順序", "Dropdown Sections & Ordering", "ドロップダウンモジュールと順序", "드롭다운 모듈 및 표시 순서",
            "Sections déroulantes et disposition", "Dropdown-Module & Anordnung", "Secciones desplegables y orden", "Sezioni a comparsa e ordinamento", "Seções suspensas e ordenação")
        add(.dropdownSectionsConfigHint, "勾选复选框决定是否在控制台弹窗中展示，拖拽手柄或列表项即可调整从上到下的展示顺序", "勾選複選框決定是否在控製台彈窗中展示，拖拽手柄或列表項即可調整從上到下的展示順序", "Select checkboxes to show in dropdown console. Drag handle or row to reorder items from top to bottom", "チェックボックスで表示を切り替え、ドラッグして上から下の表示順序を調整できます", "체크박스를 선택하여 드롭다운 콘솔에 표시하고, 드래그하여 상하 표시 순서를 조정하세요",
            "Cochez pour afficher dans la console déroulante. Glissez pour réorganiser de haut en bas", "Checkbox aktivieren, um im Dropdown anzuzeigen. Per Drag & Drop von oben nach unten sortieren", "Marque las casillas para mostrar en el panel. Arrastre para reordenar de arriba a abajo", "Seleziona per mostrare nella console a comparsa. Trascina per riordinare dall'alto in basso", "Marque as caixas para exibir no console suspenso. Arraste para reordenar de cima para baixo")
        add(.dropdownSectionsCountFormat, "/ %d 个卡片", "/ %d 個卡片", "/ %d cards", "/ %d 個のカード", "/ %d개 카드",
            "/ %d cartes", "/ %d Karten", "/ %d tarjetas", "/ %d schede", "/ %d cartões")
        add(.dropdownSectionsCountSuffixFormat, "/ %d 个模块", "/ %d 個模組", "/ %d modules", "/ %d モジュール", "/ %d개 모듈",
            "/ %d modules", "/ %d Module", "/ %d módulos", "/ %d moduli", "/ %d módulos")
        add(.dropdownTopProcessesDesc, "按实时 CPU% 与 rusage 能耗指数展示前 5 名活跃应用", "按即時 CPU% 與 rusage 能耗指數展示前 5 名活躍應用", "Ranks top 5 active applications by real-time CPU% and energy impact", "リアルタイム CPU% とエネルギー影響度に基づき上位 5 アプリを表示", "실시간 CPU% 및 에너지 지수를 기준으로 상위 5개 앱 표시",
            "Classe les 5 applications les plus actives selon le CPU% et l’impact énergétique", "Zeigt die 5 aktivsten Apps nach Echtzeit-CPU% und Energieverbrauch an", "Muestra las 5 apps más activas por CPU% en tiempo real e impacto energético", "Classifica le prime 5 app per CPU% in tempo reale e impatto energetico", "Lista os 5 principais aplicativos por CPU% em tempo real e impacto de energia")
        add(.dropdownTopProcessesTitle, "高占用进程与能耗排行榜", "高佔用處理程序與能耗排行榜", "Top Resource & Energy Processes", "高負荷プロセスと消費エネルギー順位", "리소스 및 전력 소비 순위",
            "Classement des processus par ressource et énergie", "Top-Prozesse nach CPU & Energie", "Ranking de procesos por uso y energía", "Classifica dei processi per risorse ed energia", "Processos com Maior Consumo e Energia")
        add(.dropdownWeatherQuickCardDesc, "展示当前气温、最高/最低温与天气现象，点击展开完整预报", "展示當前氣溫、最高/最低溫與天氣現象，點擊展開完整預報", "Displays temperature, daily high/low, and conditions. Click to view full forecast", "現在の気温、最高/最低気温、天気を表示。クリックで週間予報を展開", "현재 기온, 최고/최저 기온 및 날씨 표시. 클릭 시 주간 예보 확장",
            "Affiche la température, min/max du jour et conditions. Cliquez pour afficher les prévisions", "Zeigt aktuelle Temperatur, Höchst-/Tiefstwerte und Bedingungen an. Klick öffnet Vorhersage", "Muestra temperatura actual, máx./mín. y condiciones. Clic para ver pronóstico completo", "Mostra temperatura, massime/minime e meteo. Fai clic per espandere le previsioni", "Exibe temperatura atual, máxima/mínima e condições. Clique para previsão completa")
        add(.dropdownWeatherQuickCardTitle, "天气预报摘要卡片", "天氣預報摘要卡片", "Weather Forecast Summary Card", "天気予報サマリーカード", "날씨 요약 카드",
            "Carte résumé météo", "Wetterbericht-Karte", "Tarjeta de pronóstico del clima", "Scheda previsioni meteo", "Cartão Resumo de Previsão do Tempo")
        add(.duplicateCopy, "重复副本", "重複副本", "Duplicate Copy", "重複コピー", "중복 사본",
            "Copie en double", "Duplikat", "Copia duplicada", "Copia duplicata", "Cópia Duplicada")
        add(.duplicatesRetentionRuleDesc, "每组重复文件都会保留最早的一份，其余可安全删除。", "每組重複檔案都會保留最早的一份，其餘可安全刪除。", "The oldest copy of each duplicate group is kept; others can be safely removed.", "重複ファイルの各グループで最も古い1件が保持され、残りは安全に削除できます。", "각 중복 그룹에서 가장 오래된 복사본이 보존되며, 나머지는 안전하게 삭제할 수 있습니다.",
            "La copie la plus ancienne de chaque groupe est conservée ; les autres peuvent être supprimées.", "Die älteste Kopie jedes Duplikatsatzes bleibt erhalten; die übrigen können sicher gelöscht werden.", "Se conserva la copia más antigua de cada grupo de duplicados; las demás pueden eliminarse sin riesgo.", "La copia meno recente di ciascun gruppo viene conservata; le altre possono essere rimosse in sicurezza.", "A cópia mais antiga de cada grupo é mantida; as outras podem ser removidas com segurança.")
        add(.dutyCycle, "占空比", "工作週期", "Duty Cycle", "デューティ比", "듀티 사이클",
            "Cycle de service", "Tastverhältnis", "Ciclo de trabajo", "Ciclo di lavoro", "Ciclo de trabalho")
        add(.eCoreAvgLoadPrefix, "能效核均载", "節能核均載", "E-Core Avg Load", "Eコア平均負荷", "E코어 평균 부하",
            "Charge moy. cœurs E", "E-Kern Durchschn. Last", "Carga media núcleos E", "Carico medio core E", "Carga média núcleos E")
        add(.eCoreLoad, "能效核 (E-Cores) 负载", "節能核心 (E-Cores) 負載", "Efficiency Cores (E-Cores)", "高効率コア (Eコア) 負荷", "효율 코어 (E-Cores) 부하",
            "Cœurs haute efficacité (E)", "Effizienzkerne (E-Kerne)", "Núcleos de eficiencia (E)", "Core ad alta efficienza (E)", "Núcleos de Eficiência (E)")
        add(.embeddedWebkitWebviewOfflineStorageAndScriptCaches, "内嵌 WebKit 网页视图离线存储与脚本缓存", "內嵌 WebKit 網頁視圖離線存儲與腳本快取", "Embedded WebKit WebView offline storage and script caches", "内蔵 WebKit WebView オフラインストレージおよびスクリプトキャッシュ", "임베디드 WebKit 웹뷰 오프라인 저장소 및 스크립트 캐시",
            "Stockage hors ligne et caches de scripts pour WebKit WebView intégré", "Eingebettete WebKit-WebView-Offlinespeicher und Skript-Caches", "Almacenamiento sin conexión y cachés de scripts de WebKit WebView integrado", "Archiviazione offline e cache di script di WebKit WebView incorporata", "Armazenamento offline e caches de scripts de WebKit WebView incorporada")
        add(.embeddedWebviewOfflineStorageAndIndexeddbCache, "内置网页视图（WebView）本地离线存储与 IndexedDB 缓存", "內建網頁視圖（WebView）本機離線儲存與 IndexedDB 快取", "Embedded WebView offline storage and IndexedDB cache", "内蔵WebViewのオフラインストレージとIndexedDBキャッシュ", "내장 WebView 오프라인 저장소 및 IndexedDB 캐시",
            "Stockage hors ligne WebView et cache IndexedDB", "WebView-Offline-Speicher und IndexedDB-Cache", "Almacenamiento sin conexión WebView y caché IndexedDB", "Archiviazione offline WebView e cache IndexedDB", "Armazenamento offline WebView e cache IndexedDB")
        add(.emptyAllActiveTrashBinsAcrossYourMac, "清空 Mac 电脑上所有在用的「废纸篓」。", "清空 Mac 電腦上所有在用的「垃圾桶」。", "Empty all active Trash bins across your Mac.", "Mac で使用されているすべてのゴミ箱を空にします。", "Mac에서 사용 중인 모든 휴지통을 비웁니다.",
            "Videz toutes les corbeilles actives de votre Mac.", "Leeren Sie alle aktiven Papierkörbe auf Ihrem Mac.", "Vacía todas las papeleras en uso de tu Mac.", "Svuota tutti i cestini attivi sul tuo Mac.", "Esvazie todas as lixeiras ativas do seu Mac.")
        add(.emptyFoundNameFormat, "未发现%@", "未發現%@", "No %@ Found", "%@ は見つかりませんでした", "%@을(를) 찾을 수 없음",
            "Aucun %@ trouvé", "Kein %@ gefunden", "No se encontró %@", "Nessun %@ trovato", "Nenhum %@ encontrado")
        add(.enableLowLatency, "开启低延迟", "開啟低延遲", "Low Latency", "低遅延モード", "저지연 켜기",
            "Activer faible latence", "Niedrige Latenz", "Activar baja latencia", "Attiva bassa latenza", "Ativar Baixa Latência")
        add(.enableMenuBarCompanion, "开启状态栏实时监控 (MenuBar Companion)", "開啟狀態列即時監控 (MenuBar Companion)", "Enable Menu Bar Live Companion", "メニューバーライブ監視を有効化", "메뉴 막대 실시간 모니터 활성화",
            "Activer le compagnon dans la barre des menus", "Menüleisten-Begleiter aktivieren", "Activar monitor de barra de menús", "Attiva monitor nella barra dei menu", "Ativar Monitor na Barra de Menus")
        add(.enableMenuBarCompanionDesc, "在 macOS 顶部菜单栏实时显示双行硬件走势、天气与一键加速入口", "在 macOS 頂部選單列即時顯示雙行硬體走勢、天氣與一鍵加速入口", "Display dual-line hardware graphs, weather, and quick cleanup in the macOS menu bar", "macOS メニューバーにハードウェア推移、天気、最適化ショートカットを2段表示", "macOS 메뉴 막대에 하드웨어 추이, 날씨 및 원클릭 최적화 도구를 2줄로 표시",
            "Affiche les graphes matériels, la météo et le nettoyage rapide dans la barre des menus", "Zeigt Hardware-Graphen, Wetter und Schnelltasten in der Menüleiste an", "Muestra gráficas de hardware, clima y optimización rápida en la barra de menús", "Mostra grafici hardware, meteo e pulizia rapida nella barra dei menu", "Exibe gráficos de hardware, clima e atalhos de limpeza na barra de menus")
        add(.enabledItemNameFormat, "已启用 %@", "已啟用 %@", "Enabled %@", "%@ を有効にしました", "%@ 활성화됨",
            "%@ activé", "%@ aktiviert", "%@ activado", "%@ abilitato", "%@ ativado")
        add(.enabledStartupItemsCountFormat, "已启用 %d 个后台项目", "已啟用 %d 個後台項目", "Enabled %d startup items", "%d 件のスタートアップ項目を有効にしました", "%d개 시작 프로그램 활성화됨",
            "%d éléments d'arrière-plan activés", "%d Hintergrundelemente aktiviert", "%d elementos de inicio activados", "%d elementi di avvio abilitati", "%d itens de inicialização ativados")
        add(.energyImpact, "能耗", "能耗", "Energy", "エネルギー", "에너지",
            "Énergie", "Energie", "Energía", "Energia", "Energia")
        add(.ethernet, "以太网", "乙太網路", "Ethernet", "イーサネット", "이더넷",
            "Ethernet", "Ethernet", "Ethernet", "Ethernet", "Ethernet")
        add(.exactDuplicatesVerifiedBySha256OldestOriginalKeptByDefault, "内容经 SHA-256 校验完全相同的重复文件，默认保留每组最早原件", "內容經 SHA-256 校驗完全相同的重複檔案，預設保留每組最早原件", "Exact duplicates verified by SHA-256; oldest original kept by default", "SHA-256 で完全に一致する重複ファイル。デフォルトで最古のオリジナルを保持", "SHA-256 검증으로 완전히 일치하는 중복 파일. 기본적으로 최초 원본 보존",
            "Doublons exacts vérifiés par SHA-256 ; l’original le plus ancien est conservé par défaut", "Exakte Duplikate (über SHA-256 verifiziert); behält standardmäßig das älteste Original", "Duplicados exactos verificados por SHA-256; se conserva el original más antiguo", "Duplicati esatti verificati tramite SHA-256; il file originale più vecchio viene conservato per impostazione predefinita", "Duplicatas exatas verificadas por SHA-256; o original mais antigo é mantido por padrão")
        add(.exclusionWhitelist, "排除白名单", "排除白名單", "Whitelist", "除外リスト", "제외 목록",
            "Liste d’exclusion", "Ausnahmen", "Lista blanca", "Esclusioni", "Lista de Exclusão")
        add(.executionFailedOrCancelled, "执行失败或已取消", "執行失敗或已取消", "Execution Failed or Cancelled", "実行失敗またはキャンセル済み", "실행 실패 또는 취소됨",
            "Échec de l'exécution ou annulé", "Ausführung fehlgeschlagen oder abgebrochen", "Ejecución fallida o cancelada", "Esecuzione non riuscita o annullata", "Falha na execução ou cancelado")
        add(.executionFailedOrUserCancelledAuth, "执行失败或用户取消授权", "執行失敗或用戶取消授權", "Execution failed or authorization cancelled", "実行に失敗したか、認証がキャンセルされました", "실행에 실패했거나 사용자가 권한 부여를 취소했습니다",
            "Échec de l'exécution ou autorisation annulée", "Ausführung fehlgeschlagen oder Autorisierung abgebrochen", "Error de ejecución o autorización cancelada por el usuario", "Esecuzione non riuscita o autorizzazione annullata", "Falha na execução ou autorização cancelada pelo usuário")
        add(.extraBinaries, "额外二进制文件", "額外二進位檔案", "Extra Binaries", "不要なバイナリ", "추가 바이너리",
            "Fichiers binaires supplémentaires", "Zusätzliche Binärdateien", "Binarios adicionales", "Binari extra", "Binários adicionais")
        add(.failedOrCancelled, "失败或已取消", "失敗或已取消", "Failed or Cancelled", "失敗またはキャンセル済み", "실패 또는 취소됨",
            "Échoué ou annulé", "Fehlgeschlagen oder abgebrochen", "Fallido o cancelado", "Non riuscito o annullato", "Com falha ou cancelado")
        add(.failedToReclaimApfsPurgeableSpace, "APFS 可清除空间回收执行失败", "APFS 可清除空間回收執行失敗", "Failed to reclaim APFS purgeable space", "APFS パージ可能領域の解放に失敗しました", "APFS 확보 가능 공간 회수 실패",
            "Échec de la récupération de l’espace purgeable APFS", "Freigabe des APFS-Speicherplatzes fehlgeschlagen", "Error al purgar espacio APFS", "Recupero spazio eliminabile APFS non riuscito", "Falha ao recuperar espaço purgável APFS")
        add(.fanModeAuto, "自动", "自動", "Auto", "自動", "자동",
            "Auto", "Auto", "Auto", "Auto", "Auto")
        add(.fanModeCool, "降温", "降溫", "Cool", "冷却", "냉각",
            "Refroidir", "Kühlen", "Enfriar", "Raffredda", "Resfriar")
        add(.fanModeCooling50, "降温 50%", "降溫 50%", "Cooling 50%", "冷却 50%", "냉각 50%",
            "Refroidissement 50%", "Kühlung 50%", "Refrigeración 50%", "Raffreddamento 50%", "Resfriamento 50%")
        add(.fanModeMax, "强冷", "強冷", "Max", "最大", "최대 냉각",
            "Max", "Maximal", "Máximo", "Massimo", "Máximo")
        add(.fanModeMaxCooling100, "强冷 100%", "強冷 100%", "Max Cooling 100%", "フル冷却 100%", "강력 냉각 100%",
            "Refroidissement max 100%", "Max. Kühlung 100%", "Refrigeración máx. 100%", "Raffreddamento max 100%", "Resfriamento máximo 100%")
        add(.fanModeSilentFanless, "静音架构", "靜音架構", "Silent Fanless", "静音ファンレス", "무소음 무팬",
            "Silencieux sans ventilateur", "Lüfterlos leise", "Silencioso sin ventilador", "Silenzioso senza ventola", "Silencioso sem ventoinha")
        add(.fanModeSystemAuto, "系统自动", "系統自動", "System Auto", "システム自動", "시스템 자동",
            "Automatique", "System automatisch", "Automático del sistema", "Automatico di sistema", "Automático do sistema")
        add(.fanSpeedMonitor, "风扇转速监控", "風扇轉速監控", "Fan Speed Monitor", "ファン回転数モニター", "팬 속도 모니터",
            "Moniteur de ventilateurs", "Lüfterdrehzahl", "Monitor de ventiladores", "Monitor ventole", "Monitor de Ventoinhas")
        add(.fanSpeedShort, "转速", "轉速", "Speed", "回転", "속도",
            "Vitesse", "Drehzahl", "Velocidad", "Velocità", "Velocidade")
        add(.fanSpeedThermalControl, "风扇转速监控与温控", "風扇轉速監控與溫控", "Fan Speed & Thermal Control", "ファン速度と温度制御", "팬 속도 모니터링 및 온도 제어",
            "Vitesse du ventilateur et thermique", "Lüfterdrehzahl & Temperaturregelung", "Velocidad de ventiladores y temperatura", "Velocità ventole e controllo termico", "Velocidade das Ventoinhas e Controle Térmico")
        add(.fanlessPassive, "被动散热", "被動散熱", "Fanless", "ファンレス", "팬리스",
            "Sans ventilateur", "Lüfterlos", "Sin ventilador", "Senza ventola", "Sem Ventoinha")
        add(.fans, "风扇", "風扇", "Fans", "ファン", "팬",
            "Ventilateurs", "Lüfter", "Ventiladores", "Ventole", "Ventoinhas")
        add(.favoriteAdd, "收藏", "加入常用", "Favorite", "お気に入りに追加", "즐겨찾기",
            "Ajouter aux favoris", "Favorit", "Favorito", "Aggiungi ai preferiti", "Favorito")
    }

}
