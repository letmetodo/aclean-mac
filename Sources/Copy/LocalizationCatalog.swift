import Foundation

// ============================================================
//  LocalizationCatalog —— 10 国主流语言母语级词条库
//
//  键名规范：全量采用 L10nKey 强类型英文常量作为主键
//  支持语言 (10 门主流语言)：
//    1. zh-Hans : 简体中文
//    2. zh-Hant : 繁體中文
//    3. en      : English
//    4. ja      : 日本語
//    5. ko      : 한국어
//    6. fr      : Français
//    7. de      : Deutsch
//    8. es      : Español
//    9. it      : Italiano
//   10. pt-BR   : Português (Brasil)
// ============================================================

struct MultiLangEntry: Sendable {
    let zhHans: String
    let zhHant: String
    let en: String
    let ja: String
    let ko: String
    let fr: String
    let de: String
    let es: String
    let it: String
    let ptBR: String

    func text(for lang: AppLanguage) -> String {
        switch lang {
        case .zhHans, .system: return zhHans
        case .zhHant: return zhHant
        case .en:     return en
        case .ja:     return ja
        case .ko:     return ko
        case .fr:     return fr
        case .de:     return de
        case .es:     return es
        case .it:     return it
        case .ptBR:   return ptBR
        }
    }
}

enum LocalizationCatalog {
    /// 核心 10 语言词典（以英文常量 L10nKey 为强类型索引键）
    static let entries: [L10nKey: MultiLangEntry] = {
        var map: [L10nKey: MultiLangEntry] = [:]
        map[.junkHistoricalVersionFormat] = MultiLangEntry(
            zhHans: "%@ · 历史版本 %@", zhHant: "%@ · 歷史版本 %@", en: "%@ · Version %@",
            ja: "%@ · バージョン %@", ko: "%@ · 버전 %@", fr: "%@ · Version %@",
            de: "%@ · Version %@", es: "%@ · Versión %@", it: "%@ · Versione %@", ptBR: "%@ · Versão %@")
        map[.junkVersionRetentionReason] = MultiLangEntry(
            zhHans: "已保留：当前、回退、更新中或尚未确认可删除的版本", zhHant: "已保留：目前、回復、更新中或尚未確認可刪除的版本",
            en: "Retained: current, rollback, updating, or not yet verified for removal",
            ja: "保持：現在、復元用、更新中、または削除未確認のバージョン",
            ko: "유지됨: 현재, 롤백용, 업데이트 중 또는 삭제 가능 여부 미확인 버전",
            fr: "Conservée : version actuelle, de secours, en cours de mise à jour ou non vérifiée",
            de: "Beibehalten: aktuelle, Rückfall-, aktualisierte oder noch nicht zur Entfernung geprüfte Version",
            es: "Conservada: versión actual, de respaldo, en actualización o sin verificar",
            it: "Conservata: versione attuale, di ripristino, in aggiornamento o non verificata",
            ptBR: "Mantida: versão atual, de recuperação, em atualização ou ainda não verificada")
        populateSafetyRemediation(&map)
        populateBatch0(&map)
        populateBatch1(&map)
        populateBatch2(&map)
        populateBatch3(&map)
        populateBatch4(&map)
        populateBatch5(&map)
        populateBatch6(&map)
        populateBatch7(&map)
        populateBatch8(&map)
        populateBatch9(&map)
        populateBatch10(&map)
        populateBatch11(&map)
        populateBatch12(&map)
        populateBatch13(&map)
        populateBatch14(&map)
        populateBatch15(&map)
        populateA11y(&map)
        populateJunkTitles(&map)
        map[.reviewNetworkUnavailable] = MultiLangEntry(zhHans: "网络不可用或未获授权，保留缓存数据。", zhHant: "網路無法使用或未獲授權，保留快取資料。", en: "Network unavailable or disabled. Cached data is retained.", ja: "ネットワークが利用できないか無効です。キャッシュを保持します。", ko: "네트워크를 사용할 수 없거나 꺼져 있습니다. 캐시를 유지합니다.", fr: "Réseau indisponible ou désactivé. Cache conservé.", de: "Netzwerk nicht verfügbar oder deaktiviert. Cache bleibt erhalten.", es: "Red no disponible o desactivada. Se conserva la caché.", it: "Rete non disponibile o disattivata. Cache conservata.", ptBR: "Rede indisponível ou desativada. Cache preservado.")
        map[.reviewUndoIncomplete] = MultiLangEntry(zhHans: "部分项目未能恢复，请检查冲突、权限或废纸篓内容后重试。", zhHant: "部分項目未能還原，請檢查衝突、權限或垃圾桶內容後重試。", en: "Some items could not be restored. Check conflicts, permissions or Trash, then retry.", ja: "一部を復元できませんでした。競合、権限、ゴミ箱を確認して再試行してください。", ko: "일부 항목을 복원하지 못했습니다. 충돌, 권한 또는 휴지통을 확인한 후 다시 시도하세요.", fr: "Restauration incomplète. Vérifiez les conflits, autorisations ou la corbeille, puis réessayez.", de: "Wiederherstellung unvollständig. Konflikte, Rechte oder Papierkorb prüfen und erneut versuchen.", es: "Restauración incompleta. Revisa conflictos, permisos o la papelera e inténtalo de nuevo.", it: "Ripristino incompleto. Controlla conflitti, permessi o cestino e riprova.", ptBR: "Restauração incompleta. Verifique conflitos, permissões ou a Lixeira e tente novamente.")
        map[.reviewRestoreNotSaved] = MultiLangEntry(zhHans: "撤销记录未能保存，请在关闭此回执前恢复需要保留的项目。", zhHant: "還原記錄未能儲存，請在關閉此回執前還原需要保留的項目。", en: "Undo history could not be saved. Restore any needed items before closing this receipt.", ja: "復元履歴を保存できませんでした。この画面を閉じる前に必要な項目を復元してください。", ko: "실행 취소 기록을 저장하지 못했습니다. 이 화면을 닫기 전에 필요한 항목을 복원하세요.", fr: "Historique non enregistré. Restaurez les éléments nécessaires avant de fermer ce reçu.", de: "Verlauf konnte nicht gespeichert werden. Benötigte Dateien vor dem Schließen wiederherstellen.", es: "No se pudo guardar el historial. Restaura lo necesario antes de cerrar este recibo.", it: "Cronologia non salvata. Ripristina gli elementi necessari prima di chiudere la ricevuta.", ptBR: "Não foi possível salvar o histórico. Restaure os itens necessários antes de fechar este recibo.")
        map[.weatherClear] = MultiLangEntry(zhHans: "晴", zhHant: "晴", en: "Clear", ja: "晴れ", ko: "맑음", fr: "Dégagé", de: "Klar", es: "Despejado", it: "Sereno", ptBR: "Céu limpo")
        map[.weatherMostlyClear] = MultiLangEntry(zhHans: "大部晴朗", zhHant: "大致晴朗", en: "Mostly Clear", ja: "おおむね晴れ", ko: "대체로 맑음", fr: "Plutôt dégagé", de: "Überwiegend klar", es: "Mayormente despejado", it: "Prevalentemente sereno", ptBR: "Predominantemente limpo")
        map[.weatherPartlyCloudy] = MultiLangEntry(zhHans: "局部多云", zhHant: "局部多雲", en: "Partly Cloudy", ja: "晴れ時々曇り", ko: "구름 조금", fr: "Partiellement nuageux", de: "Teilweise bewölkt", es: "Parcialmente nublado", it: "Parzialmente nuvoloso", ptBR: "Parcialmente nublado")
        map[.weatherOvercast] = MultiLangEntry(zhHans: "阴", zhHant: "陰", en: "Overcast", ja: "曇り", ko: "흐림", fr: "Couvert", de: "Bedeckt", es: "Cubierto", it: "Coperto", ptBR: "Encoberto")
        map[.weatherFog] = MultiLangEntry(zhHans: "雾", zhHant: "霧", en: "Fog", ja: "霧", ko: "안개", fr: "Brouillard", de: "Nebel", es: "Niebla", it: "Nebbia", ptBR: "Nevoeiro")
        map[.weatherDrizzle] = MultiLangEntry(zhHans: "毛毛雨", zhHant: "毛毛雨", en: "Drizzle", ja: "霧雨", ko: "이슬비", fr: "Bruine", de: "Nieselregen", es: "Llovizna", it: "Pioviggine", ptBR: "Garoa")
        map[.weatherRain] = MultiLangEntry(zhHans: "雨", zhHant: "雨", en: "Rain", ja: "雨", ko: "비", fr: "Pluie", de: "Regen", es: "Lluvia", it: "Pioggia", ptBR: "Chuva")
        map[.weatherHeavyRain] = MultiLangEntry(zhHans: "大雨", zhHant: "大雨", en: "Heavy Rain", ja: "大雨", ko: "폭우", fr: "Forte pluie", de: "Starkregen", es: "Lluvia intensa", it: "Pioggia intensa", ptBR: "Chuva forte")
        map[.weatherSnow] = MultiLangEntry(zhHans: "雪", zhHant: "雪", en: "Snow", ja: "雪", ko: "눈", fr: "Neige", de: "Schnee", es: "Nieve", it: "Neve", ptBR: "Neve")
        map[.weatherShowers] = MultiLangEntry(zhHans: "阵雨", zhHant: "陣雨", en: "Showers", ja: "にわか雨", ko: "소나기", fr: "Averses", de: "Regenschauer", es: "Chubascos", it: "Rovesci", ptBR: "Pancadas de chuva")
        map[.weatherThunderstorm] = MultiLangEntry(zhHans: "雷暴", zhHant: "雷暴", en: "Thunderstorm", ja: "雷雨", ko: "뇌우", fr: "Orage", de: "Gewitter", es: "Tormenta", it: "Temporale", ptBR: "Trovoada")
        map[.weatherCloudy] = MultiLangEntry(zhHans: "多云", zhHant: "多雲", en: "Cloudy", ja: "曇り", ko: "구름 많음", fr: "Nuageux", de: "Bewölkt", es: "Nublado", it: "Nuvoloso", ptBR: "Nublado")
        populateReview20261025(&map)
        return map
    }()

    static func populateReview20261025(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }
        add(.organizeLastOpenedFormat, "上次打开：%@", "上次打開：%@", "Last opened: %@", "最終アクセス：%@", "마지막 열기: %@", "Dernière ouverture : %@", "Zuletzt geöffnet: %@", "Última apertura: %@", "Ultima apertura: %@", "Última abertura: %@")
        add(.organizeNotUsedForMonthsFormat, "超过 %d 个月未使用", "超過 %d 個月未使用", "Not used for over %d months", "%d ヶ月以上未使用", "%d개월 이상 사용 안 함", "Inutilisé depuis plus de %d mois", "Seit über %d Monaten ungenutzt", "Sin usar durante más de %d meses", "Non utilizzato da oltre %d mesi", "Sem uso há mais de %d meses")
        add(.organizeComparingFilesOfSizeFormat, "正在比对 %d 个 %@ 的文件", "正在比對 %d 個 %@ 的檔案", "Comparing %d files of %@", "%@ のファイル %d 件を比較中", "%@ 크기의 파일 %d개 비교 중", "Comparaison de %d fichiers de %@", "Vergleiche %d Dateien mit %@", "Comparando %d archivos de %@", "Confronto di %d file da %@", "Comparando %d arquivos de %@")
        add(.organizeDuplicateCopiesGroupFormat, "%@（%d 个副本）", "%@（%d 個副本）", "%@ (%d copies)", "%@（%d 件のコピー）", "%@(%d개 사본)", "%@ (%d copies)", "%@ (%d Kopien)", "%@ (%d copias)", "%@ (%d copie)", "%@ (%d cópias)")
        add(.organizeAnalyzingImagesProgressFormat, "正在分析图片 %d/%d", "正在分析圖片 %d/%d", "Analyzing images %d/%d", "画像を解析中 %d/%d", "이미지 분석 중 %d/%d", "Analyse des images %d/%d", "Bilder werden analysiert %d/%d", "Analizando imágenes %d/%d", "Analisi immagini %d/%d", "Analisando imagens %d/%d")
        add(.organizePhotosLibraryProtectedNote, "位于系统照片图库内，请通过「照片」应用管理（受保护只读）。", "位於系統照片圖庫內，請透過「照片」應用程式管理（受保護唯讀）。", "Located inside Photos library. Manage via Photos app (protected).", "写真ライブラリ内にあります。「写真」アプリで管理してください（保護対象）。", "사진 보관함 내부에 있습니다. 사진 앱에서 관리하세요(보호됨).", "Situé dans la photothèque. Gérez via l’app Photos (protégé).", "In der Fotos-Mediathek. Bitte über die Fotos-App verwalten (geschützt).", "Ubicado en la fototeca. Adminístrelo desde la app Fotos (protegido).", "All'interno della libreria Foto. Gestisci tramite l'app Foto (protetto).", "Localizado na biblioteca Fotos. Gerencie pelo app Fotos (protegido).")
        add(.organizeNewestInGroupKeepNote, "组内最新，建议保留", "組內最新，建議保留", "Newest in group, recommend keeping", "グループ内で最新、保持を推奨", "그룹 내 최신 항목, 유지 권장", "Le plus récent du groupe, conservation recommandée", "Neueste Datei der Gruppe, Behalten empfohlen", "Más reciente del grupo, se recomienda conservar", "Più recente del gruppo, si consiglia di conservare", "Mais recente do grupo, recomenda-se manter")
        add(.organizeSimilarToTargetFormat, "与「%@」相似", "與「%@」相似", "Similar to \"%@\"", "「%@」に類似", "\"%@\" 항목과 유사함", "Similaire à « %@ »", "Ähnlich wie „%@“", "Similar a \"%@\"", "Simile a \"%@\"", "Semelhante a \"%@\"")
        add(.organizeSimilarImagesGroupTitleFormat, "相似图片组 %d（%d 张）", "相似圖片組 %d（%d 張）", "Similar Images Group %d (%d photos)", "類似画像グループ %d（%d 枚）", "유사 이미지 그룹 %d(%d장)", "Groupe d’images similaires %d (%d photos)", "Ähnliche Bildergruppe %d (%d Fotos)", "Grupo de imágenes similares %d (%d fotos)", "Gruppo immagini simili %d (%d foto)", "Grupo de imagens semelhantes %d (%d fotos)")
        add(.organizeInstallersGroupNote, "未使用的应用安装包、DMG 磁盘映像与归档包。", "未使用的應用安裝套件、DMG 磁碟映像與封存檔。", "Unused application installers, DMG disk images, and package archives.", "未使用のアプリインストーラ、DMG ディスクイメージ、パッケージアーカイブ。", "사용하지 않는 앱 설치 파일, DMG 디스크 이미지 및 패키지 아카이브.", "Programmes d’installation inutilisés, images disque DMG et archives.", "Ungenutzte Installationsprogramme, DMG-Images und Paketarchive.", "Instaladores de aplicaciones sin usar, imágenes DMG y paquetes.", "Programmi di installazione inutilizzati, immagini disco DMG e archivi.", "Instaladores de aplicativos não usados, imagens DMG e pacotes.")
        add(.organizeCandidateLimitTruncatedFormat, "仅展示前 %d 项（共发现 %d 项候选）", "僅展示前 %d 項（共發現 %d 項候選）", "Showing top %d items (of %d candidates found)", "上位 %d 件を表示中（全 %d 件の候補）", "상위 %d개 항목 표시 중(총 %d개 후보 발견)", "Affichage des %d premiers éléments (sur %d candidats)", "Zeige Top %d Elemente (von %d gefundenen Kandidaten)", "Mostrando los primeros %d elementos (de %d candidatos)", "Visualizzazione dei primi %d elementi (su %d candidati)", "Mostrando os primeiros %d itens (de %d candidatos)")
        add(.statusTargetNotRunningNoActionNeeded, "目标服务当前未运行，无需重启", "目標服務目前未執行，無需重啟", "Target service is not running; no action needed", "対象サービスは実行されていないため、操作は不要です", "대상 서비스가 실행 중이 아니므로 작업이 필요하지 않습니다", "Le service cible n’est pas actif ; aucune action requise", "Zieldienst läuft nicht; keine Aktion erforderlich", "El servicio de destino no está en ejecución; no se requiere acción", "Il servizio di destinazione non è in esecuzione; nessuna azione richiesta", "O serviço de destino não está em execução; nenhuma ação necessária")
        add(.perfStorageSnapshots, "快照与存储回收", "快照與儲存空間回收", "Snapshots & Storage Reclaim", "スナップショットと領域回収", "스냅샷 및 저장 공간 회수", "Instantanés et récupération d’espace", "Schnappschüsse & Speicherfreigabe", "Instantáneas y recuperación de espacio", "Istantanee e recupero spazio", "Instantâneos e recuperação de espaço")
        add(.perfStorageSnapshotsDesc, "精简本地时间机器快照并释放可回收的系统存储空间", "精簡本機時光機快照並釋放可回收的系統儲存空間", "Thin local Time Machine snapshots and reclaim purgeable storage", "ローカル Time Machine スナップショットを整理してパージ可能領域を解放", "로컬 Time Machine 스냅샷을 정리하고 확보 가능한 저장 공간 회수", "Réduire les instantanés Time Machine locaux et récupérer l’espace purgeable", "Lokale Time Machine-Schnappschüsse ausdünnen und löschbaren Speicher freigeben", "Reducir instantáneas locales de Time Machine y recuperar espacio purgable", "Riduci le istantanee locali di Time Machine e recupera spazio", "Reduzir instantâneos locais do Time Machine e recuperar espaço purgável")
        add(.perfTagLocalSnapshots, "本地快照精简", "本機快照精簡", "Snapshot Thinning", "ローカルスナップショット整理", "로컬 스냅샷 정리", "Réduction d’instantanés", "Schnappschuss-Bereinigung", "Reducción de instantáneas", "Riduzione istantanee", "Redução de instantâneos")
        add(.ollamaSharedBlobsNoteFormat, "逻辑大小：%@ · 独占物理块：%@（含共享权重层，只读保护）", "邏輯大小：%@ · 獨佔實體區塊：%@（含共享權重層，唯讀保護）", "Logical size: %@ · Exclusive blobs: %@ (shares weight layers; read-only protected)", "論理サイズ：%@ ・ 専用物理ブロック：%@（共有レイヤーを含む・読み取り専用保護）", "논리 크기: %@ · 전용 블록: %@(공유 가중치 포함, 읽기 전용 보호)", "Taille logique : %@ · Blocs exclusifs : %@ (couches partagées, protégé en lecture seule)", "Logische Größe: %@ · Exklusive Blobs: %@ (geteilte Layer, schreibgeschützt)", "Tamaño lógico: %@ · Bloques exclusivos: %@ (capas compartidas, solo lectura)", "Dimensione logica: %@ · Blocchi esclusivi: %@ (livelli condivisi, sola lettura)", "Tamanho lógico: %@ · Blocos exclusivos: %@ (camadas compartilhadas, somente leitura)")
        add(.ollamaOrphanBlobNote, "未被任何模型清单引用的孤立权重块（只读保护）", "未被任何模型清單引用的孤立權重區塊（唯讀保護）", "Orphan blob not referenced by any model manifest (read-only protected)", "どのモデルマニフェストからも参照されていない孤立ブロック（読み取り専用保護）", "어떤 모델 매니페스트에서도 참조하지 않는 고아 블록(읽기 전용 보호)", "Bloc orphelin non référencé par un manifeste (protégé en lecture seule)", "Verwaister Blob ohne Modell-Manifest-Referenz (schreibgeschützt)", "Bloque huérfano sin referencia en manifiestos (protegido, solo lectura)", "Blob orfano non referenziato da alcun manifesto (sola lettura)", "Bloco órfão não referenciado por nenhum manifesto (somente leitura)")
        add(.processIdentityChangedOrExited, "目标进程已退出或 PID 身份已变更，已取消发送信号", "目標行程已結束或 PID 身份已變更，已取消發送信號", "Target process already exited or PID identity changed; signal aborted", "対象プロセスが既に終了したか PID が変更されたため、シグナル送信を中止しました", "대상 프로세스가 이미 종료되었거나 PID가 변경되어 신호 전송을 취소했습니다", "Le processus cible a quitté ou changé d’identité PID ; signal annulé", "Zielprozess bereits beendet oder PID-Identität geändert; Signal abgebrochen", "El proceso ya terminó o cambió su identidad PID; señal cancelada", "Il processo è terminato o l'identità PID è cambiata; segnale annullato", "O processo já foi encerrado ou a identidade PID mudou; sinal cancelado")
        add(.processTerminatedSigtermSuccess, "已发送终止信号 (SIGTERM)", "已發送終止信號 (SIGTERM)", "Sent termination signal (SIGTERM)", "終了シグナル (SIGTERM) を送信しました", "종료 신호(SIGTERM)를 전송했습니다", "Signal de terminaison (SIGTERM) envoyé", "Beendigungssignal (SIGTERM) gesendet", "Señal de terminación (SIGTERM) enviada", "Segnale di terminazione (SIGTERM) inviato", "Sinal de encerramento (SIGTERM) enviado")
        add(.processTerminatedSigkillSuccess, "已强制结束进程 (SIGKILL)", "已強制結束行程 (SIGKILL)", "Forcefully terminated process (SIGKILL)", "プロセスを強制終了 (SIGKILL) しました", "프로세스를 강제 종료(SIGKILL)했습니다", "Processus arrêté de force (SIGKILL)", "Prozess erzwungen beendet (SIGKILL)", "Proceso terminado forzosamente (SIGKILL)", "Processo terminato forzatamente (SIGKILL)", "Processo encerrado à força (SIGKILL)")
        add(.processTerminateFailedErrnoFormat, "结束进程失败（错误码：%d）", "結束行程失敗（錯誤碼：%d）", "Failed to terminate process (error code: %d)", "プロセスの終了に失敗しました（エラーコード：%d）", "프로세스 종료 실패(오류 코드: %d)", "Échec de l’arrêt du processus (code d’erreur : %d)", "Prozess konnte nicht beendet werden (Fehlercode: %d)", "Error al terminar el proceso (código: %d)", "Impossibile terminare il processo (codice errore: %d)", "Falha ao encerrar o processo (código de erro: %d)")
        add(.actionTerminateRepresentativeProcessFormat, "结束主进程 (PID %d · 聚合 %d 个进程)", "結束主行程 (PID %d · 聚合 %d 個行程)", "Terminate Primary Process (PID %d · %d grouped processes)", "代表プロセスを終了 (PID %d ・ 計 %d プロセス)", "대표 프로세스 종료 (PID %d · 총 %d개 프로세스)", "Arrêter le processus principal (PID %d · %d processus groupés)", "Hauptprozess beenden (PID %d · %d gruppierte Prozesse)", "Terminar proceso principal (PID %d · %d procesos agrupados)", "Termina processo principale (PID %d · %d processi raggruppati)", "Encerrar processo principal (PID %d · %d processos agrupados)")
        add(.cleanErrorInvalidSimRuntime, "无效的模拟器运行时标识符", "無效的模擬器執行環境識別碼", "Invalid simulator runtime identifier", "無効なシミュレータランタイム識別子です", "잘못된 시뮬레이터 런타임 식별자입니다", "Identifiant d’exécution du simulateur invalide", "Ungültige Simulator-Laufzeitkennung", "Identificador de entorno de simulador no válido", "Identificatore runtime simulatore non valido", "Identificador de runtime do simulador inválido")
        add(.cleanErrorMissingFilePath, "缺少目标文件路径", "缺少目標檔案路徑", "Missing target file path", "対象ファイルパスが見つかりません", "대상 파일 경로가 없습니다", "Chemin du fichier cible manquant", "Ziel-Dateipfad fehlt", "Falta la ruta del archivo de destino", "Percorso del file di destinazione mancante", "Caminho do arquivo de destino ausente")
        add(.cleanErrorTrashRootViolation, "拒绝永久删除：目标不在已授权的废纸篓目录内", "拒絕永久刪除：目標不在已授權的垃圾桶目錄內", "Permanent deletion rejected: item is not inside an authorized Trash folder", "完全削除が拒否されました：対象が許可されたゴミ箱フォルダ内にありません", "영구 삭제 거부됨: 항목이 승인된 휴지통 폴더 내에 없습니다", "Suppression définitive refusée : l’élément n’est pas dans une corbeille autorisée", "Endgültiges Löschen abgelehnt: Objekt liegt nicht in einem autorisierten Papierkorb", "Eliminación permanente rechazada: el elemento no está en una papelera autorizada", "Eliminazione definitiva rifiutata: l'elemento non è in un Cestino autorizzato", "Exclusão permanente recusada: o item não está em uma Lixeira autorizada")
        add(.cleanErrorSymlinkEscape, "拒绝永久删除：检测到符号链接越界", "拒絕永久刪除：偵測到符號連結越界", "Permanent deletion rejected: symlink escape detected", "完全削除が拒否されました：シンボリックリンクの境界逸脱を検出", "영구 삭제 거부됨: 심볼릭 링크 이탈이 감지되었습니다", "Suppression définitive refusée : échappement de lien symbolique détecté", "Endgültiges Löschen abgelehnt: Symlink-Ausbruch erkannt", "Eliminación permanente rechazada: se detectó escape de enlace simbólico", "Eliminazione definitiva rifiutata: rilevata fuga di link simbolico", "Exclusão permanente recusada: escape de link simbólico detectado")
        add(.cleanErrorUnknownAction, "未知的清理动作类型", "未知的清理動作類型", "Unknown cleanup action", "不明なクリーンアップ操作です", "알 수 없는 정리 작업입니다", "Action de nettoyage inconnue", "Unbekannte Bereinigungsaktion", "Acción de limpieza desconocida", "Azione di pulizia sconosciuta", "Ação de limpeza desconhecida")
        add(.cleanErrorDockerPruneFailed, "Docker 构建缓存清理执行失败", "Docker 建置快取清理執行失敗", "Docker build cache prune failed", "Docker ビルドキャッシュの整理に失敗しました", "Docker 빌드 캐시 정리 실행에 실패했습니다", "Échec du nettoyage du cache de build Docker", "Bereinigung des Docker-Build-Caches fehlgeschlagen", "Error al limpiar la caché de compilación de Docker", "Pulizia della cache di build Docker non riuscita", "Falha ao limpar o cache de build do Docker")
        add(.cleanErrorSimRuntimeDeleteFailed, "删除模拟器运行时失败", "刪除模擬器執行環境失敗", "Failed to delete simulator runtime", "シミュレータランタイムの削除に失敗しました", "시뮬레이터 런타임 삭제에 실패했습니다", "Échec de la suppression de l’environnement du simulateur", "Simulator-Laufzeit konnte nicht gelöscht werden", "Error al eliminar el entorno del simulador", "Impossibile eliminare il runtime del simulatore", "Falha ao excluir o runtime do simulador")
        add(.cleanErrorSimUnavailableDeleteFailed, "清理不可用模拟器失败", "清理無法使用的模擬器失敗", "Failed to delete unavailable simulators", "利用不可なシミュレータの削除に失敗しました", "사용할 수 없는 시뮬레이터 삭제에 실패했습니다", "Échec de la suppression des simulateurs indisponibles", "Nicht verfügbare Simulatoren konnten nicht gelöscht werden", "Error al eliminar simuladores no disponibles", "Impossibile eliminare i simulatori non disponibili", "Falha ao excluir simuladores indisponíveis")
    }

    static func populateBatch0(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.downloadKindDocuments, "文档", "文件", "Documents", "書類", "문서", "Documents", "Dokumente", "Documentos", "Documenti", "Documentos")
        add(.downloadKindImages, "图片", "圖片", "Images", "画像", "이미지", "Images", "Bilder", "Imágenes", "Immagini", "Imagens")
        add(.downloadKindVideos, "视频", "影片", "Videos", "動画", "동영상", "Vidéos", "Videos", "Vídeos", "Video", "Vídeos")
        add(.downloadKindAudio, "音频", "音訊", "Audio", "音声", "오디오", "Audio", "Audio", "Audio", "Audio", "Áudio")
        add(.downloadKindArchives, "压缩包", "壓縮檔", "Archives", "圧縮ファイル", "압축 파일", "Archives", "Archive", "Archivos comprimidos", "Archivi compressi", "Arquivos compactados")
        add(.downloadKindInstallers, "安装包", "安裝套件", "Installers", "インストーラ", "설치 파일", "Programmes d’installation", "Installationspakete", "Instaladores", "Programmi di installazione", "Instaladores")
        add(.downloadKindApplications, "应用程序", "應用程式", "Applications", "アプリケーション", "애플리케이션", "Applications", "Anwendungen", "Aplicaciones", "Applicazioni", "Aplicativos")
        add(.downloadFilesCategoryNoteFormat, "下载文件：%@", "下載檔案：%@", "Files in Downloads: %@", "ダウンロード内のファイル：%@", "다운로드 파일: %@", "Fichiers téléchargés : %@", "Dateien in Downloads: %@", "Archivos en Descargas: %@", "File in Download: %@", "Arquivos em Downloads: %@")
        add(.projectBuildArtifactNoteFormat, "%@ 构建产物 · %@", "%@ 建置產物 · %@", "%@ build artifact · %@", "%@ ビルド生成物 · %@", "%@ 빌드 산출물 · %@", "Artefact de compilation %@ · %@", "%@-Build-Artefakt · %@", "Artefacto de compilación %@ · %@", "Artefatto di compilazione %@ · %@", "Artefato de compilação %@ · %@")
        add(.projectToolchainFrontend, "Node / 前端", "Node / 前端", "Node / Frontend", "Node / フロントエンド", "Node / 프런트엔드", "Node / Front-end", "Node / Frontend", "Node / Interfaz web", "Node / Frontend", "Node / Front-end")
        add(.projectToolchainRust, "Rust / Cargo", "Rust / Cargo", "Rust / Cargo", "Rust / Cargo", "Rust / Cargo", "Rust / Cargo", "Rust / Cargo", "Rust / Cargo", "Rust / Cargo", "Rust / Cargo")
        add(.projectToolchainNative, "C++ / Go / 构建", "C++ / Go / 建置", "C++ / Go / Build", "C++ / Go / ビルド", "C++ / Go / 빌드", "C++ / Go / Compilation", "C++ / Go / Build", "C++ / Go / Compilación", "C++ / Go / Compilazione", "C++ / Go / Compilação")
        add(.projectToolchainJava, "Java / Gradle", "Java / Gradle", "Java / Gradle", "Java / Gradle", "Java / Gradle", "Java / Gradle", "Java / Gradle", "Java / Gradle", "Java / Gradle", "Java / Gradle")
        add(.projectToolchainPython, "Python 虚拟环境", "Python 虛擬環境", "Python virtual environment", "Python 仮想環境", "Python 가상 환경", "Environnement virtuel Python", "Virtuelle Python-Umgebung", "Entorno virtual de Python", "Ambiente virtuale Python", "Ambiente virtual Python")
        add(.projectToolchainApple, "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods", "Swift / Xcode / CocoaPods")
        add(.projectToolchainDart, "Flutter / Dart", "Flutter / Dart", "Flutter / Dart", "Flutter / Dart", "Flutter / Dart", "Flutter / Dart", "Flutter / Dart", "Flutter / Dart", "Flutter / Dart", "Flutter / Dart")
        add(.projectToolchainGeneric, "开发项目产物", "開發專案產物", "Developer project artifact", "開発プロジェクトの生成物", "개발 프로젝트 산출물", "Artefact de projet de développement", "Entwicklungsprojekt-Artefakt", "Artefacto de proyecto de desarrollo", "Artefatto di progetto di sviluppo", "Artefato de projeto de desenvolvimento")
        add(.menuBarCpuShort, "CPU", "CPU", "CPU", "CPU", "CPU", "CPU", "CPU", "CPU", "CPU", "CPU")
        add(.menuBarGpuShort, "GPU", "GPU", "GPU", "GPU", "GPU", "GPU", "GPU", "GPU", "GPU", "GPU")
        add(.menuBarCoreCountsFormat, "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d", "P:%d · E:%d")
        add(.runningAppFallbackName, "应用", "應用", "App", "アプリ", "앱", "Application", "App", "Aplicación", "App", "Aplicativo")
        add(.statsPresetCustom, "自定义", "自訂", "Custom", "カスタム", "사용자 지정", "Personnalisé", "Benutzerdefiniert", "Personalizado", "Personalizzato", "Personalizado")
        add(.presetName_line_chart, "折线微图", "折線微圖", "Line Chart", "折れ線グラフ", "선형 차트", "Graphique linéaire", "Liniendiagramm", "Gráfico de líneas", "Grafico a linee", "Gráfico de linhas")
        add(.presetName_bar_chart, "柱状槽", "柱狀槽", "Bar Chart", "棒グラフ", "막대 차트", "Barre verticale", "Balkendiagramm", "Gráfico de barras", "Grafico a barre", "Gráfico de barras")
        add(.presetName_pie_chart, "环形图", "環形圖", "Pie Ring", "リングチャート", "도넛 차트", "Anneau", "Ringdiagramm", "Anillo", "Grafico ad anello", "Gráfico de anel")
        add(.presetName_bat_icon_only, "电池图标", "電池圖示", "Battery Icon", "バッテリーアイコン", "배터리 아이콘", "Icône batterie", "Batteriesymbol", "Icono de batería", "Icona batteria", "Ícone da bateria")
        add(.optionalNetworkFeatures, "允许天气、城市搜索与公网网络诊断", "允許天氣、城市搜尋與公網網路診斷", "Allow weather, city search and internet diagnostics", "天気・都市検索・インターネット診断を許可", "날씨, 도시 검색 및 인터넷 진단 허용", "Autoriser météo, recherche de villes et diagnostic Internet", "Wetter, Stadtsuche und Internetdiagnose erlauben", "Permitir clima, búsqueda de ciudades y diagnóstico de Internet", "Consenti meteo, ricerca città e diagnostica Internet", "Permitir clima, busca de cidades e diagnóstico da internet")
        add(.optionalNetworkDescription, "默认关闭。开启后向第三方请求公网 IP、位置和天气；清理不需要联网。", "預設關閉。開啟後向第三方要求公網 IP、位置與天氣；清理無須連網。", "Off by default. Enabling requests public IP, location and weather from third parties. Cleanup works offline.", "初期設定はオフです。有効にすると第三者に公開IP・位置・天気を問い合わせます。削除はオフラインで動作します。", "기본값은 꺼짐입니다. 켜면 타사에 공용 IP, 위치, 날씨를 요청합니다. 정리는 오프라인으로 작동합니다.", "Désactivé par défaut. Une fois activé, l’IP publique, le lieu et la météo sont demandés à des tiers. Le nettoyage fonctionne hors ligne.", "Standardmäßig aus. Bei Aktivierung werden öffentliche IP, Standort und Wetter bei Dritten abgefragt. Die Bereinigung funktioniert offline.", "Desactivado por defecto. Al activarlo se solicita IP pública, ubicación y clima a terceros. La limpieza funciona sin conexión.", "Disattivato per impostazione predefinita. Se attivo, richiede IP pubblico, posizione e meteo a terzi. La pulizia funziona offline.", "Desativado por padrão. Ao ativar, solicita IP público, localização e clima a terceiros. A limpeza funciona offline.")
        add(.cleanupPolicyDisclosure, "普通文件移入系统废纸篓；清空废纸篓、模拟器与系统回收不可恢复，执行前单独确认。", "一般檔案移入系統垃圾桶；清空垃圾桶、模擬器與系統回收無法復原，執行前另行確認。", "Ordinary files go to system Trash. Emptying Trash, simulator deletion and system reclaim are irreversible and require separate confirmation.", "通常のファイルはゴミ箱へ移動します。ゴミ箱の消去・シミュレータ削除・システム回収は元に戻せず、個別に確認します。", "일반 파일은 시스템 휴지통으로 이동합니다. 휴지통 비우기, 시뮬레이터 삭제 및 시스템 회수는 되돌릴 수 없으며 별도 확인이 필요합니다.", "Les fichiers ordinaires vont à la Corbeille. Vider la Corbeille, supprimer un simulateur et récupérer l’espace système sont irréversibles et nécessitent une confirmation distincte.", "Normale Dateien kommen in den Papierkorb. Leeren, Simulatorlöschung und Systemrückgewinnung sind unwiderruflich und erfordern eine gesonderte Bestätigung.", "Los archivos normales van a la Papelera. Vaciarla, eliminar simuladores y recuperar espacio del sistema son acciones irreversibles con confirmación independiente.", "I file normali vanno nel Cestino. Svuotarlo, eliminare simulatori e recuperare spazio di sistema sono azioni irreversibili che richiedono conferma separata.", "Arquivos comuns vão para o Lixo. Esvaziá-lo, excluir simuladores e recuperar espaço do sistema são ações irreversíveis e exigem confirmação separada.")
        add(.scanCoverageIncomplete, "扫描未完成或存在无法读取的区域；结果仅覆盖已检查项目。", "掃描未完成或存在無法讀取的區域；結果僅涵蓋已檢查項目。", "Scan incomplete or some locations unreadable; results cover inspected items only.", "スキャン未完了、または読めない場所があります。結果は確認済み項目のみです。", "검사가 완료되지 않았거나 일부 위치를 읽을 수 없습니다. 결과는 검사된 항목만 포함합니다.", "Analyse incomplète ou emplacements illisibles ; les résultats couvrent uniquement les éléments vérifiés.", "Scan unvollständig oder Orte unlesbar; Ergebnisse gelten nur für geprüfte Elemente.", "Análisis incompleto o ubicaciones ilegibles; los resultados solo incluyen elementos revisados.", "Scansione incompleta o posizioni illeggibili; i risultati coprono solo gli elementi verificati.", "Verificação incompleta ou locais ilegíveis; resultados incluem apenas itens verificados.")
        add(.ruleUpdateTitle, "清理规则更新", "清理規則更新", "Cleanup rule updates", "クリーンアップルールの更新", "정리 규칙 업데이트", "Mise à jour des règles", "Bereinigungsregeln aktualisieren", "Actualizaciones de reglas", "Aggiornamenti delle regole", "Atualizações das regras")
        add(.ruleUpdateVersionFormat, "规则版本：%@", "規則版本：%@", "Rule version: %@", "ルールバージョン：%@", "규칙 버전: %@", "Version des règles : %@", "Regelversion: %@", "Versión de reglas: %@", "Versione regole: %@", "Versão das regras: %@")
        add(.ruleUpdateAutomatic, "自动更新清理规则", "自動更新清理規則", "Update cleanup rules automatically", "ルールを自動更新", "정리 규칙 자동 업데이트", "Mettre les règles à jour automatiquement", "Regeln automatisch aktualisieren", "Actualizar reglas automáticamente", "Aggiorna automaticamente le regole", "Atualizar regras automaticamente")
        add(.ruleUpdateDescription, "启动时检查最新规则，无需重新安装；不会上传文件列表或扫描结果。", "啟動時檢查最新規則，無需重新安裝；不會上傳檔案清單或掃描結果。", "Check for new rules at startup without reinstalling. File lists and scan results are never uploaded.", "起動時に最新ルールを確認します。再インストールは不要で、ファイル一覧やスキャン結果は送信しません。", "재설치 없이 시작 시 새 규칙을 확인합니다. 파일 목록과 검사 결과는 업로드하지 않습니다.", "Vérifie les règles au démarrage sans réinstallation. Aucun fichier ni résultat d’analyse n’est envoyé.", "Neue Regeln beim Start ohne Neuinstallation prüfen. Dateilisten und Scanergebnisse werden nicht hochgeladen.", "Busca reglas al iniciar sin reinstalar. No se suben listas de archivos ni resultados.", "Controlla nuove regole all’avvio senza reinstallare. Nessun elenco di file o risultato viene caricato.", "Verifica regras ao iniciar sem reinstalar. Listas de arquivos e resultados não são enviados.")
        add(.ruleUpdateCheck, "检查规则更新", "檢查規則更新", "Check for rule updates", "ルール更新を確認", "규칙 업데이트 확인", "Rechercher des mises à jour", "Nach Regelupdates suchen", "Buscar actualizaciones de reglas", "Verifica aggiornamenti regole", "Verificar atualizações de regras")
        add(.ruleUpdateLastCheckFormat, "上次检查：%@", "上次檢查：%@", "Last checked: %@", "最終確認：%@", "마지막 확인: %@", "Dernière vérification : %@", "Zuletzt geprüft: %@", "Última comprobación: %@", "Ultimo controllo: %@", "Última verificação: %@")
        add(.ruleUpdateNever, "尚未检查", "尚未檢查", "Not checked yet", "未確認", "아직 확인하지 않음", "Pas encore vérifié", "Noch nicht geprüft", "Aún no se ha comprobado", "Non ancora verificato", "Ainda não verificado")
        add(.ruleUpdateNotConfigured, "在线更新尚未配置，内置规则仍可离线使用。", "線上更新尚未設定，內建規則仍可離線使用。", "Online updates are not configured. Built-in rules remain available offline.", "オンライン更新は未設定です。内蔵ルールはオフラインで使用できます。", "온라인 업데이트가 설정되지 않았습니다. 내장 규칙은 오프라인에서 사용할 수 있습니다.", "Les mises à jour ne sont pas configurées. Les règles intégrées restent disponibles hors ligne.", "Online-Updates sind nicht eingerichtet. Integrierte Regeln bleiben offline nutzbar.", "Las actualizaciones no están configuradas. Las reglas integradas funcionan sin conexión.", "Aggiornamenti online non configurati. Le regole integrate sono disponibili offline.", "Atualizações online não configuradas. As regras internas funcionam offline.")
        add(.ruleUpdateReady, "本机规则可用", "本機規則可用", "Local rules are available", "ローカルルールを使用できます", "로컬 규칙 사용 가능", "Règles locales disponibles", "Lokale Regeln verfügbar", "Reglas locales disponibles", "Regole locali disponibili", "Regras locais disponíveis")
        add(.ruleUpdateChecking, "正在检查规则更新…", "正在檢查規則更新…", "Checking for rule updates…", "ルール更新を確認中…", "규칙 업데이트 확인 중…", "Recherche de mises à jour…", "Regelupdates werden geprüft…", "Buscando actualizaciones…", "Verifica aggiornamenti…", "Verificando atualizações…")
        add(.ruleUpdateWaiting, "发现新规则，当前任务结束后更新。", "發現新規則，目前工作結束後更新。", "New rules found. They will update after current tasks finish.", "新しいルールがあります。現在の処理終了後に更新します。", "새 규칙이 있습니다. 현재 작업이 끝나면 업데이트합니다.", "Nouvelles règles disponibles. Mise à jour à la fin des tâches en cours.", "Neue Regeln verfügbar. Aktualisierung nach Abschluss laufender Aufgaben.", "Hay nuevas reglas. Se actualizarán al finalizar las tareas actuales.", "Nuove regole disponibili. Verranno aggiornate al termine delle attività.", "Novas regras disponíveis. Serão atualizadas após as tarefas atuais.")
        add(.ruleUpdateUpdated, "规则已更新，请重新扫描。", "規則已更新，請重新掃描。", "Rules updated. Please scan again.", "ルールを更新しました。再スキャンしてください。", "규칙이 업데이트되었습니다. 다시 검사하세요.", "Règles mises à jour. Relancez l’analyse.", "Regeln aktualisiert. Bitte erneut scannen.", "Reglas actualizadas. Vuelve a analizar.", "Regole aggiornate. Ripeti la scansione.", "Regras atualizadas. Execute uma nova análise.")
        add(.ruleUpdateFailed, "暂时无法更新，将继续使用可用的本机规则。", "暫時無法更新，將繼續使用可用的本機規則。", "Updates are temporarily unavailable. Available local rules will continue to be used.", "現在更新できません。利用可能なローカルルールを引き続き使用します。", "일시적으로 업데이트할 수 없습니다. 사용 가능한 로컬 규칙을 계속 사용합니다.", "Mise à jour temporairement indisponible. Les règles locales disponibles restent utilisées.", "Updates sind vorübergehend nicht verfügbar. Verfügbare lokale Regeln werden weiter verwendet.", "No se puede actualizar por ahora. Se seguirán usando las reglas locales disponibles.", "Aggiornamento temporaneamente non disponibile. Verranno usate le regole locali disponibili.", "Atualização temporariamente indisponível. As regras locais disponíveis continuarão em uso.")
        add(.ruleUpdateRescanRequired, "规则已更新或停用，请重新扫描。", "規則已更新或停用，請重新掃描。", "Rules changed or were disabled. Please scan again.", "ルールが変更または無効化されました。再スキャンしてください。", "규칙이 변경되거나 비활성화되었습니다. 다시 검사하세요.", "Des règles ont changé ou ont été désactivées. Relancez l’analyse.", "Regeln wurden geändert oder deaktiviert. Bitte erneut scannen.", "Las reglas cambiaron o se desactivaron. Vuelve a analizar.", "Le regole sono cambiate o disattivate. Ripeti la scansione.", "As regras mudaram ou foram desativadas. Execute uma nova análise.")
        add(.ruleScanAdditionalPaths, "规则指定缓存", "規則指定快取", "Rule-defined caches", "ルールで指定されたキャッシュ", "규칙 지정 캐시", "Caches définis par les règles", "Regelbasierte Caches", "Cachés definidos por reglas", "Cache definite dalle regole", "Caches definidos por regras")
        add(.ruleDatabaseUnavailableTitle, "规则库未加载，已进入只读保护模式", "規則庫未載入，已進入唯讀保護模式", "Rule Database Unavailable — Read-Only Protection Active", "ルールデータベース未読込 — 読み取り専用保護モード", "규칙 데이터베이스 로드 실패 — 읽기 전용 보호 모드", "Base de règles indisponible — Mode lecture seule actif", "Regeldatenbank nicht verfügbar — Schreibgeschützter Modus aktiv", "Base de reglas no disponible — Modo de solo lectura activo", "Database regole non disponibile — Modalità sola lettura attiva", "Banco de regras indisponível — Proteção somente leitura ativa")
        add(.ruleDatabaseUnavailableBanner, "清理规则库未加载或校验失败；为保障数据安全，本次扫描无法判定可清理垃圾，所有候选项已锁定为只读。", "清理規則庫未載入或校驗失敗；為保障資料安全，本次掃描無法判定可清理垃圾，所有候選項已鎖定為唯讀。", "Cleanup rule database is unavailable or failed verification. To protect your data, cleanable junk cannot be determined and all candidates are locked as read-only.", "削除ルールデータベースを読み込めないため、安全のため削除可能なジャンクを判定できず、すべての候補を読み取り専用でロックしました。", "정리 규칙 데이터베이스를 불러올 수 없어 데이터 보호를 위해 모든 후보 항목을 읽기 전용으로 잠갔습니다.", "La base de règles de nettoyage est indisponible. Par sécurité, tous les éléments sont verrouillés en lecture seule.", "Die Bereinigungsregel-Datenbank ist nicht verfügbar. Zum Schutz Ihrer Daten sind alle Kandidaten schreibgeschützt gesperrt.", "La base de reglas de limpieza no está disponible. Por seguridad, todos los candidatos se han bloqueado en modo de solo lectura.", "Il database delle regole di pulizia non è disponibile. Per sicurezza, tutti gli elementi sono bloccati in sola lettura.", "O banco de regras de limpeza não está disponível. Por segurança, todos os candidatos foram bloqueados como somente leitura.")
        add(.safetyInspectionIncomplete, "检查未完成，已停止清理", "檢查未完成，已停止清理", "Inspection incomplete; cleanup stopped", "確認が完了していないため、削除を停止しました", "검사가 완료되지 않아 정리를 중단했습니다", "Vérification incomplète ; nettoyage arrêté", "Prüfung unvollständig; Bereinigung gestoppt", "Comprobación incompleta; limpieza detenida", "Verifica incompleta; pulizia interrotta", "Verificação incompleta; limpeza interrompida")
        add(.cleanupFileChanged, "文件已变化，请重新扫描", "檔案已變更，請重新掃描", "File changed; scan again", "ファイルが変更されました。再スキャンしてください", "파일이 변경되었습니다. 다시 검사하세요", "Fichier modifié ; relancez l’analyse", "Datei geändert; erneut scannen", "Archivo modificado; vuelve a analizar", "File modificato; ripeti la scansione", "Arquivo alterado; verifique novamente")
        add(.cleanupDuplicateUnavailable, "保留副本不可验证，请重新审查", "保留副本無法驗證，請重新審查", "Retained copy cannot be verified; review again", "残すコピーを確認できません。再確認してください", "보관할 사본을 확인할 수 없습니다. 다시 검토하세요", "Copie conservée non vérifiable ; revérifiez", "Behaltene Kopie nicht überprüfbar; erneut prüfen", "No se puede verificar la copia conservada; revisa de nuevo", "Copia conservata non verificabile; ricontrolla", "Não foi possível verificar a cópia mantida; revise novamente")
        add(.cleanupOutcomeCountsFormat, "成功 %d · 失败 %d · 跳过 %d · 取消 %d", "成功 %d · 失敗 %d · 略過 %d · 取消 %d", "Succeeded %d · Failed %d · Skipped %d · Cancelled %d", "成功 %d · 失敗 %d · スキップ %d · キャンセル %d", "성공 %d · 실패 %d · 건너뜀 %d · 취소 %d", "Réussis %d · Échecs %d · Ignorés %d · Annulés %d", "Erfolgreich %d · Fehlgeschlagen %d · Übersprungen %d · Abgebrochen %d", "Correctos %d · Fallidos %d · Omitidos %d · Cancelados %d", "Riusciti %d · Falliti %d · Saltati %d · Annullati %d", "Sucesso %d · Falha %d · Ignorados %d · Cancelados %d")
        add(.receiptToolReportedFormat, "工具报告回收 %@（非宿主磁盘实测）", "工具回報回收 %@（非主機磁碟實測）", "Tool reports %@ reclaimed (not measured on host disk)", "ツール報告の回収量 %@（ホストディスクの実測ではありません）", "도구 보고 회수량 %@ (호스트 디스크 실측 아님)", "Récupération signalée par l’outil : %@ (non mesurée sur le disque hôte)", "Vom Werkzeug gemeldet: %@ (nicht auf dem Host-Laufwerk gemessen)", "La herramienta informa %@ recuperados (sin medición del disco anfitrión)", "Lo strumento riporta %@ recuperati (non misurati sul disco host)", "Ferramenta informa %@ recuperados (não medidos no disco do host)")
        add(.dockerBuildCacheScope, "仅清理未使用的构建缓存；不删除容器、镜像或卷。", "僅清理未使用的建置快取；不刪除容器、映像或磁碟區。", "Removes unused build cache only; containers, images and volumes are retained.", "未使用のビルドキャッシュのみ削除します。コンテナ・イメージ・ボリュームは保持します。", "사용하지 않는 빌드 캐시만 정리합니다. 컨테이너, 이미지 및 볼륨은 유지됩니다.", "Supprime uniquement le cache de construction inutilisé ; conteneurs, images et volumes conservés.", "Entfernt nur ungenutzten Build-Cache; Container, Images und Volumes bleiben erhalten.", "Elimina solo caché de compilación sin usar; conserva contenedores, imágenes y volúmenes.", "Rimuove solo la cache di compilazione inutilizzata; conserva container, immagini e volumi.", "Remove apenas cache de compilação não utilizado; preserva contêineres, imagens e volumes.")
        add(.cleanupPartialResult, "部分完成，请查看未完成项目", "部分完成，請查看未完成項目", "Partially completed; review unfinished items", "一部完了しました。未完了の項目をご確認ください", "일부 완료되었습니다. 미완료 항목을 확인하세요", "Partiellement terminé ; consultez les éléments restants", "Teilweise abgeschlossen; offene Elemente prüfen", "Completado parcialmente; revisa los elementos pendientes", "Completato in parte; controlla gli elementi incompleti", "Concluído parcialmente; revise os itens pendentes")
        add(.cleanupCancelledResult, "已取消，已完成操作不会回滚", "已取消，已完成操作不會回復", "Cancelled; completed operations remain applied", "キャンセルしました。完了済みの操作は維持されます", "취소되었습니다. 완료된 작업은 유지됩니다", "Annulé ; les opérations terminées restent appliquées", "Abgebrochen; abgeschlossene Vorgänge bleiben wirksam", "Cancelado; las operaciones completadas se mantienen", "Annullato; le operazioni completate restano applicate", "Cancelado; as operações concluídas permanecem aplicadas")
        add(.abandonedInstallersDesc, "下载后已废弃的 DMG 映像、PKG 安装包与 ZIP 归档。", "下載後已廢棄的 DMG 映像、PKG 安裝套件與 ZIP 封存檔。", "Obsolete DMG disk images, PKG packages, and ZIP archives.", "使用後に残された DMG ディスクイメージ、PKG パッケージ、ZIP アーカイブ。", "사용 후 방치된 DMG 디스크 이미지, PKG 패키지 및 ZIP 압축 파일입니다.",
            "Images disque DMG, paquets PKG et archives ZIP obsolètes.", "Veraltete DMG-Images, PKG-Pakete und ZIP-Archive.", "Imágenes de disco DMG, paquetes PKG y archivos ZIP obsoletos.", "Immagini disco DMG, pacchetti PKG e archivi ZIP obsoleti.", "Imagens de disco DMG, pacotes PKG e arquivos ZIP descartados.")
        add(.acPower, "AC 直供", "AC 直供", "AC Power", "電源アダプタ接続", "AC 전원 공급",
            "Alimentation secteur", "Netzteilbetrieb", "Adaptador de corriente", "Alimentazione CA", "Alimentação CA")
        add(.acleanMenuBarAndCompanionConfiguration, "ACleaner 菜单栏与下拉模块配置", "ACleaner 菜單欄與下拉模塊配置", "ACleaner Menu Bar & Companion Configuration", "ACleaner メニューバーとポップオーバーの設定", "ACleaner 메뉴 막대 및 팝오버 구성",
            "Configuration de la barre des menus et du compagnon ACleaner", "ACleaner Menüleisten- und Begleiter-Konfiguration", "Configuración de barra de menús y panel ACleaner", "Configurazione barra dei menu e compagno ACleaner", "Configuração da Barra de Menus e Companheiro ACleaner")
        add(.acleanMenuBarAndCompanionPreferences, "ACleaner 菜单栏与下拉模块配置…", "ACleaner 菜單欄與下拉模塊配置…", "ACleaner Menu Bar & Companion Preferences…", "ACleaner メニューバーとポップオーバー設定…", "ACleaner 메뉴 막대 및 팝오버 설정…",
            "Réglages de la barre des menus et du compagnon ACleaner…", "ACleaner Menüleisten- und Begleiter-Einstellungen…", "Ajustes de barra de menús y panel ACleaner…", "Impostazioni barra dei menu e compagno ACleaner…", "Configurações da Barra de Menus e Companheiro ACleaner…")
        add(.acleanMenuBarAndDropdownConfiguration, "ACleaner 菜单栏与下拉模块配置…", "ACleaner 選單列與下拉模組設定…", "ACleaner Menu Bar & Dropdown Configuration…", "ACleaner メニューバーとドロップダウン設定…", "ACleaner 메뉴 막대 및 드롭다운 구성…",
            "Configuration de la barre de menus ACleaner…", "ACleaner Menüleisten-Konfiguration…", "Configuración de barra de menús ACleaner…", "Configurazione barra dei menu ACleaner…", "Configuração da Barra de Menus ACleaner…")
        add(.acleanPreferences, "ACleaner 偏好设置", "ACleaner 偏好設定", "ACleaner Preferences", "ACleaner 環境設定", "ACleaner 환경설정",
            "Préférences ACleaner", "ACleaner Einstellungen", "Preferencias de ACleaner", "Preferenze ACleaner", "Preferências do ACleaner")
        add(.actionAddFolderOrFile, "添加目录或文件…", "新增目錄或檔案…", "Add Folder or File…", "フォルダやファイルを追加…", "폴더 또는 파일 추가…",
            "Ajouter un dossier ou un fichier…", "Ordner oder Datei hinzufügen…", "Añadir carpeta o archivo…", "Aggiungi cartella o file…", "Adicionar Pasta ou Arquivo…")
        add(.actionAddNodeToIgnoreListFormat, "将“%@”添加到忽略列表", "將“%@”添加到忽略列表", "Add \"%@\" to Ignore List", "「%@」を無視リストに追加", "\"%@\"을(를) 제외 목록에 추가",
            "Ajouter « %@ » à la liste d'exclusion", "„%@“ zur Ausschlussliste hinzufügen", "Añadir \"%@\" a la lista de exclusión", "Aggiungi \"%@\" alla lista elementi ignorati", "Adicionar \"%@\" à lista de exclusão")
        add(.actionAddToIgnoreWhitelist, "加入忽略白名单", "加入忽略白名單", "Add to Whitelist", "ホワイトリストに追加", "제외 목록에 추가",
            "Ajouter à la liste d'exclusion", "Zur Ausschlussliste hinzufügen", "Añadir a la lista de exclusión", "Aggiungi alla whitelist", "Adicionar à lista de exclusão")
        add(.actionAddToWhitelist, "加入白名单", "加入白名單", "Add to Whitelist", "ホワイトリストに追加", "화이트리스트에 추가",
            "Ajouter à la liste blanche", "Zur Whitelist hinzufügen", "Añadir a lista blanca", "Aggiungi a whitelist", "Adicionar à Lista Branca")
        add(.actionAlsoRemoveUserData, "一并移除用户数据", "一併移除使用者資料", "Also remove user data", "ユーザーデータも一緒に削除", "사용자 데이터도 함께 제거",
            "Supprimer également les données utilisateur", "Benutzerdaten ebenfalls entfernen", "Eliminar también los datos del usuario", "Rimuovi anche i dati utente", "Remover também os dados do usuário")
        add(.actionAnalyze, "分析", "分析", "Analyze", "分析", "분석",
            "Analyser", "Analysieren", "Analizar", "Analizza", "Analisar")
        add(.actionAssessMyMac, "评估我的 Mac", "評估我的 Mac", "Assess My Mac", "Mac の健康度を評価", "내 Mac 상태 평가",
            "Évaluer mon Mac", "Meinen Mac bewerten", "Evaluar mi Mac", "Valuta il mio Mac", "Avaliar meu Mac")
        add(.actionAuthorizedAndContinue, "我已授权并继续", "我已授權並繼續", "I've Granted Access, Continue", "許可しました。続ける", "권한을 허용했습니다. 계속하기",
            "J'ai autorisé, continuer", "Ich habe Zugriff erteilt, fortfahren", "Ya he concedido acceso, continuar", "Ho concesso l'accesso, continua", "Já autorizei, continuar")
        add(.actionBack, "返回", "返回", "Back", "戻る", "뒤로",
            "Retour", "Zurück", "Atrás", "Indietro", "Voltar")
        add(.actionBackAlt, "后退", "返回", "Back", "戻る", "뒤로",
            "Retour", "Zurück", "Atrás", "Indietro", "Voltar")
        add(.actionBuildSpaceLensMap, "开始构建空间透视图", "開始構建空間透視圖", "Start Building Space Lens Map", "スペースレンズマップの構築を開始", "스페이스 렌즈 맵 생성 시작",
            "Construire la carte de la lentille d'espace", "Erstellung der Speicherlinse starten", "Comenzar a crear el mapa espacial", "Avvia la creazione della mappa dello spazio", "Iniciar criação do mapa da lente de espaço")
        add(.actionCaffeinateAlwaysOn, "常亮", "常亮", "Always On", "常時点灯", "항상 켜짐",
            "Toujours allumé", "Immer an", "Siempre encendido", "Sempre attivo", "Sempre ligado")
        add(.actionCaffeinateShort, "防休眠", "防休眠", "Caffeinate", "スリープ防止", "잠자기 방지",
            "Anti-veille", "Wachhalten", "Antisuspensión", "Anti-sospensione", "Evitar suspensão")
        add(.actionCaffeinateTooltip, "防止 Mac 进入睡眠模式", "防止 Mac 進入睡眠模式", "Prevent Mac from sleeping", "Macのスリープを防止", "Mac이 잠자기 상태로 전환되지 않도록 방지",
            "Empêcher le Mac de se mettre en veille", "Verhindert, dass der Mac in den Ruhezustand wechselt", "Evitar que el Mac entre en reposo", "Impedisci al Mac di andare in stop", "Impedir o Mac de entrar em repouso")
        add(.actionCancel, "取消", "取消", "Cancel", "キャンセル", "취소",
            "Annuler", "Abbrechen", "Cancelar", "Annulla", "Cancelar")
        add(.actionCleanDockerCache, "清理 Docker 构建缓存", "清理 Docker 建置快取", "Clean Docker Build Cache", "Docker ビルドキャッシュを消去", "Docker 빌드 캐시 정리",
            "Nettoyer le cache de construction Docker", "Docker-Build-Cache bereinigen", "Limpiar caché de compilación Docker", "Pulisci cache di compilazione Docker", "Limpar cache de compilação Docker")
        add(.actionCleanNow, "立即清理", "立即清理", "Clean Now", "今すぐクリーンアップ", "지금 정리",
            "Nettoyer maintenant", "Jetzt bereinigen", "Limpiar ahora", "Pulisci ora", "Limpar Agora")
        add(.actionClickToDisableThisItem, "点击停用此项", "點擊停用此項", "Click to disable this item", "クリックして無効化", "클릭하여 비활성화",
            "Cliquer pour désactiver cet élément", "Klicken, um dieses Element zu deaktivieren", "Haga clic para desactivar este elemento", "Fai clic per disabilitare questo elemento", "Clique para desativar este item")
        add(.actionClickToEnableThisItem, "点击启用此项", "點擊啟用此項", "Click to enable this item", "クリックして有効化", "클릭하여 활성화",
            "Cliquer pour activer cet élément", "Klicken, um dieses Element zu aktivieren", "Haga clic para activar este elemento", "Fai clic per abilitare questo elemento", "Clique para ativar este item")
        add(.actionClickToStart, "点击开始", "點擊開始", "Click to Start", "クリックして開始", "클릭하여 시작",
            "Cliquer pour démarrer", "Klicken zum Starten", "Haga clic para comenzar", "Fai clic per iniziare", "Clique para iniciar")
        add(.actionCollapseHint, "收起提示", "收起提示", "Hide Help", "ヘルプを閉じる", "안내 접기",
            "Masquer l'aide", "Hilfe ausblenden", "Ocultar ayuda", "Nascondi aiuto", "Ocultar ajuda")
        add(.actionConfigurePermissionsNow, "立即配置权限", "立即配置權限", "Configure Permissions Now", "アクセス権限を設定", "지금 권한 설정하기",
            "Configurer les autorisations", "Berechtigungen jetzt einrichten", "Configurar permisos ahora", "Configura autorizzazioni ora", "Configurar permissões agora")
        add(.actionConfirm, "确认", "確認", "Confirm", "確認", "확인",
            "Confirmer", "Bestätigen", "Confirmar", "Conferma", "Confirmar")
        add(.actionConfirmRemoval, "确认移除", "確認移除", "Confirm Removal", "削除を確認", "제거 확인",
            "Confirmer la suppression", "Entfernen bestätigen", "Confirmar eliminación", "Conferma rimozione", "Confirmar Remoção")
        add(.actionDeleteSimulatorRuntime, "删除模拟器运行时", "刪除模擬器執行階段", "Delete Simulator Runtime", "シミュレータランタイムを削除", "시뮬레이터 런타임 삭제",
            "Supprimer le runtime du simulateur", "Simulator-Laufzeitumgebung löschen", "Eliminar tiempo de ejecución del simulador", "Elimina runtime simulatore", "Excluir runtime do simulador")
        add(.actionDeleteUnavailableSimulators, "清理不可用模拟器", "清理不可用模擬器", "Clean Unavailable Simulators", "利用不可シミュレータをクリーンアップ", "사용할 수 없는 시뮬레이터 정리",
            "Nettoyer les simulateurs indisponibles", "Nicht verfügbare Simulatoren bereinigen", "Limpiar simuladores no disponibles", "Pulisci simulatori non disponibili", "Limpar simuladores indisponíveis")
        add(.actionDeselect, "取消选择", "取消選擇", "Deselect", "選択を解除", "선택 해제",
            "Désélectionner", "Auswahl aufheben", "Deseleccionar", "Deseleziona", "Desmarcar")
        add(.actionDeselectAll, "取消全选", "取消全選", "Deselect All", "選択を解除", "선택 해제",
            "Tout désélectionner", "Auswahl aufheben", "Deseleccionar todo", "Deseleziona tutto", "Desmarcar Tudo")
        add(.actionDeselectAllItemsInNodeFormat, "取消选择“%@”中的所有项目", "取消選擇“%@”中的所有項目", "Deselect all items in \"%@\"", "「%@」内のすべての選択を解除", "\"%@\" 내의 모든 항목 선택 해제",
            "Désélectionner tout dans « %@ »", "Alle Elemente in „%@“ abwählen", "Deseleccionar todo en \"%@\"", "Deseleziona tutto in \"%@\"", "Desmarcar tudo em \"%@\"")
        add(.actionDisable, "禁用", "禁用", "Disable", "無効化", "비활성화",
            "Désactiver", "Deaktivieren", "Desactivar", "Disabilita", "Desativar")
        add(.actionClose, "关闭", "關閉", "Close", "閉じる", "닫기",
            "Fermer", "Schließen", "Cerrar", "Chiudi", "Fechar")
        add(.actionDone, "完成", "完成", "Done", "完了", "완료",
            "Terminé", "Fertig", "Listo", "Fine", "Concluído")
        add(.actionEmpty, "清空", "清空", "Empty", "空にする", "비우기",
            "Vider", "Leeren", "Vaciar", "Svuota", "Esvaziar")
        add(.actionEnterDirectory, "进入目录", "進入目錄", "Open Folder", "フォルダを開く", "폴더 열기",
            "Ouvrir le dossier", "Ordner öffnen", "Abrir carpeta", "Apri cartella", "Abrir Pasta")
        add(.actionExecuteNow, "立即执行", "立即執行", "Run Now", "今すぐ実行", "지금 실행",
            "Exécuter maintenant", "Jetzt ausführen", "Ejecutar ahora", "Esegui ora", "Executar Agora")
        add(.actionExportConfig, "导出配置…", "匯出設定…", "Export Settings…", "設定を書き出し…", "설정 내보내기…",
            "Exporter la configuration…", "Konfiguration exportieren…", "Exportar ajustes…", "Esporta configurazione…", "Exportar Configurações…")
        add(.actionFree, "释放", "釋放", "Free", "解放", "확보",
            "Libérer", "Freigeben", "Liberar", "Libera", "Liberar")
        add(.actionFreeUpRamMemory, "释放 RAM 内存", "釋放 RAM 內存", "Free Up RAM Memory", "RAM メモリを解放", "RAM 메모리 확보",
            "Libérer la mémoire RAM", "RAM-Speicher freigeben", "Liberar memoria RAM", "Libera memoria RAM", "Liberar memória RAM")
        add(.actionGetInfo, "显示简介", "顯示簡介", "Get Info", "情報を見る", "정보 가져오기",
            "Lire les informations", "Informationen", "Obtener información", "Ottieni informazioni", "Obter Informações")
        add(.actionGoToAuthorize, "前往授权", "前往授權", "Grant Access", "アクセスを許可", "권한 부여하기",
            "Autoriser l'accès", "Berechtigung erteilen", "Conceder permiso", "Concedi autorizzazione", "Conceder permissão")
        add(.actionGoToSection, "前往", "前往", "Go", "移動", "이동",
            "Accéder", "Öffnen", "Ir", "Vai", "Ir")
        add(.actionHideFromDropdownConsole, "取消在下拉控制台显示", "取消在下拉控製台顯示", "Hide from Dropdown", "ドロップダウンから非表示", "드롭다운 콘솔에서 숨기기",
            "Masquer du menu déroulant", "Im Dropdown ausblenden", "Ocultar del menú desplegable", "Nascondi dal menu a comparsa", "Ocultar do menu suspenso")
        add(.actionHideFromMenuBar, "取消在菜单栏显示", "取消在菜單欄顯示", "Hide from Menu Bar", "メニューバーから非表示", "메뉴 막대에서 숨기기",
            "Masquer de la barre des menus", "In Menüleiste ausblenden", "Ocultar de la barra de menús", "Nascondi dalla barra dei menu", "Ocultar da barra de menus")
        add(.actionImportConfig, "导入配置…", "匯入設定…", "Import Settings…", "設定を読み込み…", "설정 가져오기…",
            "Importer une configuration…", "Konfiguration importieren…", "Importar ajustes…", "Importa configurazione…", "Importar Configurações…")
        add(.actionInspect, "检查", "檢查", "Inspect", "検査", "검사",
            "Inspecter", "Überprüfen", "Inspeccionar", "Ispeziona", "Inspecionar")
        add(.actionIpLocate, "IP定位", "IP定位", "Locate by IP", "IP自動判定", "IP 위치 확인",
            "Localiser par IP", "Per IP lokalisieren", "Localizar por IP", "Localizza tramite IP", "Localizar por IP")
        add(.actionKeep, "保留", "保留", "Keep", "保持", "유지",
            "Conserver", "Behalten", "Conservar", "Conserva", "Manter")
        add(.actionKillProcessSigkill, "强制终止进程 (SIGKILL)", "強製終止進程 (SIGKILL)", "Force Kill Process (SIGKILL)", "プロセスを強制終了 (SIGKILL)", "프로세스 강제 종료 (SIGKILL)",
            "Forcer l'arrêt du processus (SIGKILL)", "Sofortiges Beenden erzwingen (SIGKILL)", "Forzar la detención del proceso (SIGKILL)", "Uccisione forzata del processo (SIGKILL)", "Forçar encerramento do processo (SIGKILL)")
        add(.actionLocateAppInFinder, "在访达中定位 App", "在訪達中定位 App", "Reveal in Finder", "Finder で表示", "Finder에서 앱 찾기",
            "Afficher dans le Finder", "Im Finder anzeigen", "Mostrar en el Finder", "Mostra nel Finder", "Revelar no Finder")
        add(.actionLocateAppInFinderButton, "访达中定位应用", "訪達中定位應用", "Locate App in Finder", "Finder でアプリを特定", "Finder에서 앱 찾기",
            "Localiser l'application dans le Finder", "App im Finder suchen", "Localizar app en el Finder", "Individua app nel Finder", "Localizar app no Finder")
        add(.actionManageMyApplications, "管理我的应用程序", "管理我的應用程序", "Manage My Apps", "アプリケーションを管理", "내 애플리케이션 관리",
            "Gérer mes applications", "Meine Apps verwalten", "Gestionar mis aplicaciones", "Gestisci le mie app", "Gerenciar meus aplicativos")
        add(.actionMoveBackwardOne, "向后移动一位", "向後移動一位", "Move Right", "右へ移動", "뒤로 이동",
            "Déplacer vers la droite", "Nach rechts verschieben", "Mover a la derecha", "Sposta a destra", "Mover para a direita")
        add(.actionMoveDownOne, "向下移动一位", "向下移動一位", "Move Down", "下へ移動", "아래로 이동",
            "Déplacer vers le bas", "Nach unten verschieben", "Mover abajo", "Sposta in basso", "Mover para baixo")
        add(.actionMoveForwardOne, "向前移动一位", "向前移動一位", "Move Left", "左へ移動", "앞으로 이동",
            "Déplacer vers la gauche", "Nach links verschieben", "Mover a la izquierda", "Sposta a sinistra", "Mover para a esquerda")
        add(.actionMoveToTrash, "移至废纸篓", "移到垃圾桶", "Move to Trash", "ゴミ箱に移動", "휴지통으로 이동",
            "Mettre dans la Corbeille", "In den Papierkorb", "Mover a la Papelera", "Sposta nel Cestino", "Mover para o Lixo")
        add(.actionMoveToTrashAlt, "移到废纸篓", "移到垃圾桶", "Move to Trash", "ゴミ箱に入れる", "휴지통으로 이동",
            "Placer dans la corbeille", "In den Papierkorb legen", "Trasladar a la papelera", "Sposta nel Cestino", "Mover para o Lixo")
        add(.actionMoveUpOne, "向上移动一位", "向上移動一位", "Move Up", "上へ移動", "위로 이동",
            "Déplacer vers le haut", "Nach oben verschieben", "Mover arriba", "Sposta in alto", "Mover para cima")
        add(.actionNeverCleanThis, "永不清理此项", "永不清理此項", "Never Clean This", "この項目を除外", "이 항목 제외",
            "Ne jamais nettoyer", "Nie bereinigen", "No limpiar nunca", "Non pulire mai", "Nunca Limpar")
        add(.actionNone, "全不选", "全不選", "Deselect All", "選択を解除", "모두 선택 해제",
            "Tout désélectionner", "Auswahl aufheben", "Deseleccionar todo", "Deseleziona tutto", "Desmarcar tudo")
        add(.actionOnlyRemoveSafeCacheAndApp, "仅移除安全缓存与主程序", "僅移除安全快取與主程式", "Only remove safe cache and main app", "安全なキャッシュとメインアプリのみ削除", "안전한 캐시 및 메인 앱만 제거",
            "Supprimer uniquement le cache sûr et l'application principale", "Nur sicheren Cache und Hauptanwendung entfernen", "Eliminar solo la caché segura y la app principal", "Rimuovi solo cache sicura e app principale", "Remover apenas o cache seguro e o app principal")
        add(.actionOpen, "打开", "打開", "Open", "開く", "열기",
            "Ouvrir", "Öffnen", "Abrir", "Apri", "Abrir")
        add(.actionOpenACleanConsole, "打开 ACleaner 主控制台", "打開 ACleaner 主控制台", "Open ACleaner Main Console", "ACleaner メインコンソールを開く", "ACleaner 메인 콘솔 열기",
            "Ouvrir la console principale ACleaner", "ACleaner-Hauptkonsole öffnen", "Abrir la consola principal de ACleaner", "Apri console principale di ACleaner", "Abrir Console Principal do ACleaner")
        add(.actionOpenActivityMonitor, "打开 macOS 活动监视器", "打開 macOS 活動監視器", "Open Activity Monitor", "アクティビティモニタを開く", "활성 상태 보기 열기",
            "Ouvrir le Moniteur d'activité", "Aktivitätsanzeige öffnen", "Abrir Monitor de Actividad", "Apri Monitoraggio Attività", "Abrir Monitor de Atividade")
        add(.actionOpenActivityMonitorHelp, "打开活动监视器", "打開活動監視器", "Open Activity Monitor", "アクティビティモニタを開く", "활성 상태 보기 열기",
            "Ouvrir le Moniteur d'activité", "Aktivitätsanzeige öffnen", "Abrir Monitor de Actividad", "Apri Monitoraggio Attività", "Abrir Monitor de Atividade")
        add(.actionOpenCleanMateMainWindow, "打开 ACleaner 主控制台", "打開 ACleaner 主控制台", "Open ACleaner", "ACleaner を開く", "ACleaner 메인 창 열기",
            "Ouvrir ACleaner", "ACleaner öffnen", "Abrir ACleaner", "Apri ACleaner", "Abrir ACleaner")
        add(.actionOpenConsole, "打开 macOS 系统控制台 (Console)", "打開 macOS 系統控製台 (Console)", "Open Console", "コンソールを開く", "콘솔 열기",
            "Ouvrir la Console", "Konsole öffnen", "Abrir Consola", "Apri Console", "Abrir Console")
        add(.actionOpenConsoleHelp, "打开控制台", "打開控制台", "Open Console", "コンソールを開く", "콘솔 열기",
            "Ouvrir la Console", "Konsole öffnen", "Abrir Consola", "Apri Console", "Abrir Console")
        add(.actionOpenFolder, "打开文件夹", "打開資料夾", "Open Folder", "フォルダを開く", "폴더 열기",
            "Ouvrir le dossier", "Ordner öffnen", "Abrir carpeta", "Apri cartella", "Abrir pasta")
        add(.actionOpenInFinder, "在访达中打开", "在 Finder 中打開", "Open in Finder", "Finderで開く", "Finder에서 열기",
            "Ouvrir dans le Finder", "Im Finder öffnen", "Abrir en el Finder", "Apri nel Finder", "Abrir no Finder")
        add(.actionOpenMenuBarCustomConfig, "打开菜单栏与监控项自定义配置", "打開菜單欄與監控項自定義配置", "Customize Menu Bar & Monitoring Items", "メニューバーと監視項目のカスタマイズを開く", "메뉴 막대 및 모니터링 항목 사용자 정의 설정 열기",
            "Personnaliser la barre des menus et les indicateurs", "Menüleiste & Monitoreinstellungen anpassen", "Personalizar barra de menús y monitorización", "Personalizza barra dei menu e monitoraggio", "Personalizar barra de menus e monitoramento")
        add(.actionOpenSystemSettings, "打开 macOS 系统设置", "打開 macOS 系統設置", "Open System Settings", "システム設定を開く", "시스템 설정 열기",
            "Ouvrir les Réglages Système", "Systemeinstellungen öffnen", "Abrir Ajustes del Sistema", "Apri Impostazioni di Sistema", "Abrir Ajustes do Sistema")
        add(.actionOpenSystemSettingsToApp, "打开系统设置并定位 ACleaner", "打開系統設置並定位 ACleaner", "Open System Settings & Locate ACleaner", "システム設定を開いて ACleaner を選択", "시스템 설정 열기 및 ACleaner 찾기",
            "Ouvrir les Réglages Système et localiser ACleaner", "Systemeinstellungen öffnen & ACleaner auswählen", "Abrir Ajustes del Sistema y localizar ACleaner", "Apri Impostazioni di Sistema e individua ACleaner", "Abrir Ajustes do Sistema e localizar o ACleaner")
        add(.actionOpenTerminal, "打开 终端 (Terminal)", "打開 終端 (Terminal)", "Open Terminal", "ターミナルを開く", "터미널 열기",
            "Ouvrir le Terminal", "Terminal öffnen", "Abrir Terminal", "Apri Terminale", "Abrir Terminal")
        add(.actionOpenTerminalHelp, "打开终端", "打開終端機", "Open Terminal", "ターミナルを開く", "터미널 열기",
            "Ouvrir le Terminal", "Terminal öffnen", "Abrir Terminal", "Apri Terminale", "Abrir Terminal")
        add(.actionParentDirectory, "上一级", "上一層", "Parent Folder", "上の階層へ", "상위 폴더",
            "Dossier parent", "Übergeordneter Ordner", "Carpeta superior", "Cartella superiore", "Pasta Superior")
        add(.actionPurgeInactiveCacheButton, "释放非活跃缓存", "釋除非作用快取", "Purge Inactive Cache", "非アクティブキャッシュを解放", "비활성 캐시 정리",
            "Purger le cache inactif", "Inaktiven Cache bereinigen", "Purgar caché inactiva", "Svuota cache inattiva", "Liberar cache inativo")
        add(.actionPurgeInactiveMemoryCache, "一键优化释放不活跃缓存 (Purge)", "一鍵優化釋放不活躍緩存 (Purge)", "Purge Inactive Memory Cache", "非アクティブメモリキャッシュをパージ", "비활성 메모리 캐시 최적화 해제 (Purge)",
            "Purger le cache mémoire inactif", "Inaktiven Speicher-Cache leeren (Purge)", "Purgar caché de memoria inactiva", "Elimina la cache di memoria inattiva (Purge)", "Limpar cache de memória inativa (Purge)")
        add(.actionPutBack, "放回原处", "放回原處", "Put Back", "元に戻す", "원래 위치로 복원",
            "Remettre en place", "Zurücklegen", "Restaurar", "Ripristina", "Restaurar ao Local")
        add(.actionQuickLook, "快速查看", "快速查看", "Quick Look", "クイックルック", "훑어보기",
            "Coup d’œil", "Übersicht", "Vista rápida", "Visualizzazione rapida", "Visualização Rápida")
        add(.actionQuickScan, "快速扫描", "快速掃描", "Quick Scan", "クイックスキャン", "빠른 검사",
            "Analyse rapide", "Schnellscan", "Escaneo rápido", "Scansione rapida", "Verificação rápida")
        add(.actionQuit, "退出", "結束", "Quit", "終了", "종료",
            "Quitter", "Beenden", "Salir", "Esci", "Encerrar")
        add(.actionReAssess, "重新评估", "重新評估", "Re-assess", "再評価", "다시 평가",
            "Réévaluer", "Erneut bewerten", "Volver a evaluar", "Rivaluta", "Reavaliar")
        add(.actionRecommended, "推荐", "推薦", "Recommended", "おすすめ", "추천",
            "Recommandé", "Empfohlen", "Recomendado", "Consigliato", "Recomendado")
        add(.actionRefresh, "刷新", "重新整理", "Refresh", "更新", "새로 고침",
            "Actualiser", "Aktualisieren", "Actualizar", "Aggiorna", "Atualizar")
        add(.actionRefreshStatusCheck, "刷新检测", "刷新檢測", "Refresh Check", "状態を再確認", "검사 상태 새로고침",
            "Rafraîchir la vérification", "Überprüfung aktualisieren", "Actualizar comprobación", "Aggiorna verifica", "Atualizar verificação")
        add(.actionRefreshWeatherImmediately, "立即刷新实时天气", "立即刷新實時天氣", "Refresh Live Weather", "リアルタイム天気を今すぐ更新", "실시간 날씨 즉시 새로고침",
            "Actualiser la météo en direct", "Live-Wetter jetzt aktualisieren", "Actualizar el tiempo en directo ahora", "Aggiorna subito il meteo in tempo reale", "Atualizar o clima em tempo real agora")
        add(.actionReleasePurgeableSpace, "释放 APFS 可清除空间", "釋放 APFS 可清除空間", "Free Up APFS Purgeable Space", "APFS 消去可能スペースを解放", "APFS 제거 가능 공간 확보",
            "Libérer l'espace purgeable APFS", "Bereinigbaren APFS-Speicher freigeben", "Liberar espacio purgable de APFS", "Libera spazio eliminabile APFS", "Liberar espaço purgável do APFS")
        add(.actionRemoveNow, "立即移除", "立即移除", "Remove Now", "今すぐ削除", "지금 제거",
            "Supprimer maintenant", "Jetzt entfernen", "Eliminar ahora", "Rimuovi ora", "Remover Agora")
        add(.actionRescan, "重新扫描", "重新掃描", "Rescan", "再スキャン", "다시 스캔",
            "Réanalyser", "Erneut scannen", "Volver a escanear", "Ripeti scansione", "Escanear Novamente")
        add(.actionResetAndReregisterTcc, "重置并重新注册", "重置並重新註冊", "Reset & Re-register TCC", "リセットして再登録", "초기화 및 다시 등록",
            "Réinitialiser et réenregistrer", "Zurücksetzen & neu registrieren", "Restablecer y volver a registrar", "Reimposta e registra nuovamente", "Redefinir e registrar novamente")
        add(.actionResetSelection, "重置选择", "重置選擇", "Reset Selection", "選択をリセット", "선택 초기화",
            "Réinitialiser", "Auswahl zurücksetzen", "Restablecer selección", "Reimposta selezione", "Redefinir seleção")
        add(.actionRestoreDefaults, "恢复默认设置", "恢復預設設定", "Restore Defaults", "初期設定に戻す", "기본 설정으로 복원",
            "Rétablir les réglages par défaut", "Standardeinstellungen wiederherstellen", "Restaurar ajustes por defecto", "Ripristina impostazioni predefinite", "Restaurar Configurações Padrão")
        add(.actionRestoreDefaultsButton, "恢复默认", "恢複默認", "Restore Defaults", "デフォルトに戻す", "기본값 복원",
            "Rétablir les valeurs par défaut", "Standard wiederherstellen", "Restaurar predeterminados", "Ripristina predefiniti", "Restaurar padrões")
        add(.actionRestoreRecommended, "恢复推荐", "恢復推薦", "Restore Recommended", "推奨に戻す", "권장 설정 복원",
            "Rétablir les recommandations", "Empfehlung wiederherstellen", "Restaurar recomendados", "Ripristina consigliati", "Restaurar Recomendados")
        add(.actionRetryFetchWeather, "立即重新联网获取", "立即重新聯網獲取", "Retry Network Fetch", "再試行", "다시 가져오기",
            "Réessayer", "Erneut abrufen", "Reintentar conexión", "Riprova connessione", "Tentar novamente")
        add(.actionRevealAppInFinder, "在访达中显示主程序", "在訪達中顯示主程序", "Show Application in Finder", "Finder でアプリを表示", "Finder에서 애플리케이션 보기",
            "Afficher l'application dans le Finder", "Hauptprogramm im Finder anzeigen", "Mostrar aplicación en el Finder", "Mostra applicazione nel Finder", "Mostrar aplicativo no Finder")
        add(.actionRevealInFinder, "在访达中显示", "在 Finder 中顯示", "Reveal in Finder", "Finderで表示", "Finder에서 보기",
            "Afficher dans le Finder", "Im Finder zeigen", "Mostrar en el Finder", "Mostra nel Finder", "Mostrar no Finder")
        add(.actionReviewAndRemove, "查看并移除", "檢視並移除", "Review & Remove", "確認して削除", "검토 및 제거",
            "Examiner et supprimer", "Überprüfen & Entfernen", "Revisar y eliminar", "Esamina e rimuovi", "Revisar e remover")
        add(.actionReviewDetails, "查看详情", "檢視詳情", "Review Details", "詳細を確認", "상세 보기",
            "Examiner les détails", "Details anzeigen", "Revisar detalles", "Mostra dettagli", "Ver Detalhes")
        add(.actionRun, "运行", "執行", "Run", "実行", "실행",
            "Exécuter", "Ausführen", "Ejecutar", "Esegui", "Executar")
        add(.actionRunNow, "立即运行", "立即執行", "Run", "実行", "실행",
            "Exécuter", "Ausführen", "Ejecutar", "Esegui", "Executar")
        add(.actionRunRecommendedMaintenanceTasks, "运行建议的维护任务", "運行建議的維護任務", "Run Recommended Maintenance Tasks", "推奨メンテナンスタスクを実行", "권장 유지보수 작업 실행",
            "Exécuter les tâches de maintenance recommandées", "Empfohlene Wartungsaufgaben ausführen", "Ejecutar tareas de mantenimiento recomendadas", "Esegui attività di manutenzione consigliate", "Executar tarefas de manutenção recomendadas")
        add(.actionRunSystemMaintenance, "执行系统维护", "執行系統維護", "Run System Maintenance", "システムメンテナンスを実行", "시스템 유지보수 실행",
            "Exécuter la maintenance du système", "Systemwartung ausführen", "Ejecutar mantenimiento del sistema", "Esegui manutenzione di sistema", "Executar manutenção do sistema")
        add(.actionRunTasks, "运行任务", "執行任務", "Run Tasks", "タスクを実行", "작업 실행",
            "Exécuter", "Aufgaben ausführen", "Ejecutar tareas", "Esegui attività", "Executar Tarefas")
        add(.actionSafeEjectAllButton, "全部安全弹出", "全部安全退出", "Safe Eject All", "すべて安全に取り出す", "모두 안전하게 추출",
            "Tout éjecter en toute sécurité", "Alle sicher auswerfen", "Expulsar todo de forma segura", "Espelli tutto in sicurezza", "Ejetar tudo com segurança")
        add(.actionSafeEjectVolume, "一键安全推出", "一鍵安全推出", "Safely Eject", "安全に取り外す", "안전하게 추출",
            "Éjecter en toute sécurité", "Sicher auswerfen", "Expulsar con seguridad", "Espelli in sicurezza", "Ejetar com segurança")
        add(.actionScan, "扫描", "掃描", "Scan", "スキャン", "스캔",
            "Analyser", "Scannen", "Escanear", "Scansiona", "Escanear")
        add(.actionSearch, "搜索", "搜尋", "Search", "検索", "검색",
            "Rechercher", "Suchen", "Buscar", "Cerca", "Buscar")
        add(.actionSearchEllipsis, "搜索…", "搜尋…", "Search…", "検索…", "검색…",
            "Rechercher…", "Suchen…", "Buscar…", "Cerca…", "Buscar…")
        add(.actionSecurityCheck, "安全检查", "安全檢查", "Security Check", "セキュリティチェック", "보안 점검",
            "Contrôle de sécurité", "Sicherheitsprüfung", "Comprobación de seguridad", "Controllo di sicurezza", "Verificação de segurança")
        add(.actionSelectAll, "全选", "全選", "Select All", "すべて選択", "모두 선택",
            "Tout sélectionner", "Alle auswählen", "Seleccionar todo", "Seleziona tutto", "Selecionar Tudo")
        add(.actionSelectAllAndRunMaintenance, "全选并运行所有建议维护任务", "全選並運行所有建議維護任務", "Select All & Run Recommended Maintenance Tasks", "すべて選択して推奨メンテナンスタスクを実行", "모두 선택하여 권장 유지보수 작업 실행",
            "Tout sélectionner et lancer les tâches recommandées", "Alle auswählen & empfohlene Wartungsaufgaben ausführen", "Seleccionar todo y ejecutar mantenimiento recomendado", "Seleziona tutto ed esegui la manutenzione consigliata", "Selecionar tudo e executar a manutenção recomendada")
        add(.actionShowInDropdownConsole, "勾选以在下拉控制台显示", "勾選以在下拉控製台顯示", "Show in Dropdown", "ドロップダウンに表示", "드롭다운 콘솔에 표시",
            "Afficher dans le menu déroulant", "Im Dropdown anzeigen", "Mostrar en el menú desplegable", "Mostra nel menu a comparsa", "Exibir no menu suspenso")
        add(.actionShowInFinder, "在访达中查看", "在訪達中查看", "Show in Finder", "Finder で表示", "Finder에서 보기",
            "Afficher dans le Finder", "Im Finder anzeigen", "Mostrar en el Finder", "Mostra nel Finder", "Mostrar no Finder")
        add(.actionShowInMenuBar, "勾选以在菜单栏显示", "勾選以在菜單欄顯示", "Show in Menu Bar", "メニューバーに表示", "메뉴 막대에 표시",
            "Afficher dans la barre des menus", "In Menüleiste anzeigen", "Mostrar en la barra de menús", "Mostra nella barra dei menu", "Exibir na barra de menus")
        add(.actionSkipForNow, "暂不处理", "暫不處理", "Skip for Now", "今はスキップ", "지금은 건너뛰기",
            "Ignorer pour le moment", "Vorerst überspringen", "Omitir por ahora", "Ignora per ora", "Ignorar por enquanto")
        add(.actionOpenModuleManagement, "AClean 模块管理", "AClean 模組管理", "AClean Module Management", "AClean モジュール管理", "AClean 모듈 관리",
            "Gestion des modules AClean", "AClean-Modulverwaltung", "Gestión de módulos AClean", "Gestione moduli AClean", "Gerenciamento de módulos AClean")
        add(.oneClickCleanMenuTitle, "一键清理", "一鍵清理", "One-Click Clean", "ワンクリッククリーン", "원클릭 정리",
            "Nettoyage en un clic", "Ein-Klick-Bereinigung", "Limpieza en un clic", "Pulizia con un clic", "Limpeza em um clique")
        add(.openPreferencesMenuTitle, "打开偏好设置", "開啟偏好設定", "Open Preferences", "環境設定を開く", "환경설정 열기",
            "Ouvrir les préférences", "Einstellungen öffnen", "Abrir preferencias", "Apri preferenze", "Abrir preferências")
        add(.quitCleanMateMenuTitle, "退出 CleanMate", "結束 CleanMate", "Quit CleanMate", "CleanMate を終了", "CleanMate 종료",
            "Quitter CleanMate", "CleanMate beenden", "Salir de CleanMate", "Esci da CleanMate", "Encerrar CleanMate")
    }

    static func populateBatch1(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                      fr: fr, de: de, es: es, it: it, ptBR: ptBR)
        }

        add(.actionSmartRecommended, "智能推荐", "智慧推薦", "Recommended", "推奨を選択", "권장 항목 선택",
            "Recommandés", "Empfohlen", "Recomendados", "Consigliati", "Recomendados")
        add(.actionStartAnalyzeApps, "开始分析应用", "開始分析應用", "Start Analyzing Apps", "アプリの分析を開始", "앱 분석 시작",
            "Commencer l’analyse des apps", "Programmanalyse starten", "Iniciar análisis de apps", "Avvia analisi app", "Iniciar Análise de Apps")
        add(.actionStartScan, "开始扫描", "開始掃描", "Start Scan", "スキャン開始", "스캔 시작",
            "Lancer l’analyse", "Scan starten", "Iniciar escaneo", "Avvia scansione", "Iniciar Escaneamento")
        add(.actionStartSmartScan, "开始智能扫描", "開始智能掃描", "Start Smart Scan", "スマートスキャンを開始", "스마트 검사 시작",
            "Démarrer l'analyse intelligente", "Intelligenten Scan starten", "Iniciar escaneo inteligente", "Avvia scansione intelligente", "Iniciar verificação inteligente")
        add(.actionStop, "停止", "停止", "Stop", "停止", "중지",
            "Arrêter", "Stoppen", "Detener", "Ferma", "Parar")
        add(.actionStopAnalysis, "停止分析", "停止分析", "Stop Analysis", "分析を停止", "분석 중지",
            "Arrêter l'analyse", "Analyse anhalten", "Detener análisis", "Interrompi analisi", "Parar análise")
        add(.actionStopCleaning, "停止清理", "停止清理", "Stop Cleaning", "クリーンアップを停止", "정리 중지",
            "Arrêter le nettoyage", "Bereinigung stoppen", "Detener limpieza", "Ferma pulizia", "Parar Limpeza")
        add(.actionStopScanning, "停止扫描", "停止掃描", "Stop Scan", "スキャン停止", "스캔 중지",
            "Arrêter l’analyse", "Scan stoppen", "Detener escaneo", "Interrompi scansione", "Parar Escaneamento")
        add(.actionTerminateProcessSigterm, "温和退出进程 (SIGTERM)", "溫和退出進程 (SIGTERM)", "Gracefully Terminate Process (SIGTERM)", "プロセスを安全に終了 (SIGTERM)", "정상적으로 프로세스 종료 (SIGTERM)",
            "Terminer le processus en douceur (SIGTERM)", "Prozess ordnungsgemäß beenden (SIGTERM)", "Finalizar proceso de forma suave (SIGTERM)", "Termina processo delicatamente (SIGTERM)", "Encerrar processo normalmente (SIGTERM)")
        add(.actionThin, "精简", "精簡", "Thin", "最適化", "축소",
            "Alléger", "Verkleinern", "Reducir", "Riduci", "Reduzir")
        add(.actionThinBinary, "精简二进制", "精簡二進位檔案", "Thin Binary", "バイナリの軽量化", "바이너리 슬림화",
            "Alléger le binaire", "Binärdatei verschlanken", "Reducir binario", "Riduci binario", "Reduzir binário")
        add(.actionUndo, "撤销", "撤銷", "Undo", "取り消す", "실행 취소",
            "Annuler", "Widerrufen", "Deshacer", "Annulla azione", "Desfazer")
        add(.actionUninstallNow, "立即卸载", "立即解除安裝", "Uninstall Now", "今すぐアンインストール", "지금 제거",
            "Désinstaller maintenant", "Jetzt deinstallieren", "Desinstalar ahora", "Disinstalla ora", "Desinstalar Agora")
        add(.actionView, "查看", "查看", "View", "確認", "보기",
            "Voir", "Anzeigen", "Ver", "Visualizza", "Visualizar")
        add(.actionViewLogs, "查看日志", "查看日誌", "View Logs", "ログを表示", "로그 보기",
            "Afficher les journaux", "Protokolle anzeigen", "Ver registros", "Visualizza registri", "Ver registros")
        add(.active, "有活动", "有活動", "Active", "アクティビティあり", "활동 있음",
            "Activité récente", "Aktivität", "Con actividad", "Attività rilevata", "Com Atividade")
        add(.activeInterface, "活跃接口", "活躍接口", "Active Interface", "アクティブインターフェース", "활성 인터페이스",
            "Interface active", "Aktive Schnittstelle", "Interfaz activa", "Interfaccia attiva", "Interface ativa")
        add(.activeProcesses, "活跃进程", "活動處理程序", "Processes", "プロセス", "활성 프로세스",
            "Processus actifs", "Aktive Prozesse", "Procesos activos", "Processi attivi", "Processos Ativos")
        add(.activityDaysAgoSuffix, "天前有活动", "天前有活動", "d ago", "日前にアクティブ", "일 전 활동",
            "j auparavant", "Tage zuvor aktiv", "días antes", "giorni fa", "dias atrás")
        add(.activityHoursAgoSuffix, "小时前有活动", "小時前有活動", "h ago", "時間前にアクティブ", "시간 전 활동",
            "h auparavant", "Std. zuvor aktiv", "h antes", "ore fa", "h atrás")
        add(.activityMinutesAgoSuffix, "分钟前有活动", "分鐘前有活動", "m ago", "分前にアクティブ", "분 전 활동",
            "min auparavant", "Min. zuvor aktiv", "min antes", "min fa", "min atrás")
        add(.activityMonthsAgoSuffix, "个月前有活动", "個月前有活動", "mo ago", "か月前にアクティブ", "개월 전 활동",
            "mois auparavant", "Monate zuvor aktiv", "meses antes", "mesi fa", "meses atrás")
        add(.adminRequired, "需要授权", "需要授權", "Admin Required", "管理者権限が必要", "관리자 권한 필요",
            "Accès admin requis", "Admin-Rechte nötig", "Requiere admin", "Richiede admin", "Requer Admin")
        add(.aiAppCachesAndOldToolchainsPreservesChatsProjectsAndLocalModels, "AI App 缓存和旧版工具，保留对话、项目和本地模型", "AI App 快取和舊版工具，保留對話、專案和本機模型", "AI app caches and old toolchains; preserves chats, projects, and local models", "AI App のキャッシュと古いツール（チャット履歴・プロジェクト・ローカルモデルは保持）", "AI 앱 캐시 및 구버전 도구 (대화, 프로젝트 및 로컬 모델 유지)",
            "Caches d’apps IA ; conserve les conversations, projets et modèles locaux", "KI-App-Caches; Chats, Projekte und lokale Modelle bleiben erhalten", "Cachés de apps de IA; conserva conversaciones, proyectos y modelos locales", "Cache delle app IA; mantiene chat, progetti e modelli locali", "Caches de apps de IA; mantém conversas, projetos e modelos locais")
        add(.aiModelsAndTools, "AI 模型与工具", "AI 模型與工具", "AI Models & Tools", "AI モデルとツール", "AI 모델 및 도구",
            "Modèles et outils IA", "KI-Modelle & Tools", "Modelos y herramientas de IA", "Modelli e strumenti IA", "Modelos e Ferramentas de IA")
        add(.alertConfirmDeleteTitle, "确定要删除吗？", "確定要刪除嗎？", "Are you sure you want to delete?", "本当に削除しますか？", "정말 삭제하시겠습니까?",
            "Voulez-vous vraiment supprimer ces éléments ?", "Möchten Sie diese Elemente wirklich löschen?", "¿Seguro que quieres eliminar estos elementos?", "Sei sicuro di voler eliminare?", "Tem certeza de que deseja apagar?")
        add(.allApplications, "所有应用程序", "所有應用程式", "All Applications", "すべてのアプリケーション", "모든 응용 프로그램",
            "Toutes les applications", "Alle Programme", "Todas las aplicaciones", "Tutte le applicazioni", "Todos os aplicativos")
        add(.allJunk, "全部垃圾", "全部垃圾", "All Junk", "すべてのジャンク", "모든 정크",
            "Tous les indésirables", "Alle Datenreste", "Toda la basura", "Tutti i file inutili", "Todo o lixo")
        add(.alsoRemoveUserData, "一并移除用户数据", "一併移除使用者資料", "Also remove user data", "ユーザーデータも削除", "사용자 데이터 함께 제거",
            "Supprimer aussi les données", "Benutzerdaten mitentfernen", "Eliminar también datos de usuario", "Rimuovi anche dati utente", "Remover dados do usuário")
        add(.alsoRemoveUserDataWithSizeFormat, "一并移除用户数据 (+%@)", "一併移除用戶數據 (+%@)", "Also remove user data (+%@)", "ユーザーデータも一括削除 (+%@)", "사용자 데이터도 함께 제거 (+%@)",
            "Supprimer aussi les données utilisateur (+%@)", "Benutzerdaten ebenfalls entfernen (+%@)", "Eliminar también datos de usuario (+%@)", "Rimuovi anche i dati utente (+%@)", "Remover também dados do usuário (+%@)")
        add(.analyzedDiskSpaceUsageFormat, "已分析 %@ 磁盘占用", "已分析 %@ 磁碟佔用", "Analyzed %@ of disk space", "%@ のディスク領域を分析完了", "%@의 디스크 사용 공간 분석 완료",
            "%@ d'espace disque analysé", "%@ Speicherplatz analysiert", "Se analizaron %@ de espacio en disco", "Analizzati %@ di spazio su disco", "Analisados %@ de espaço em disco")
        add(.analyzedDiskUsageSummaryFormat, "已分析 %@ 磁盘占用", "已分析 %@ 磁碟佔用", "Analyzed %@ of disk usage", "%@ のディスク使用量を分析完了", "%@의 디스크 사용량 분석 완료",
            "%@ d'espace disque analysé", "%@ an Festplattenbelegung analysiert", "Se analizaron %@ de uso de disco", "Analizzati %@ di spazio su disco", "%@ de uso do disco analisados")
        add(.analyzingDirectorySizes, "正在实时分析目录体积…", "正在實時分析目錄體積…", "Analyzing directory sizes in real time…", "フォルダサイズをリアルタイム分析中…", "디렉토리 용량을 실시간 분석하는 중…",
            "Analyse en temps réel de la taille des répertoires…", "Echtzeit-Analyse der Verzeichnisgrößen…", "Analizando tamaño de carpetas en tiempo real…", "Analisi in tempo reale delle dimensioni delle cartelle…", "Analisando tamanho dos diretórios em tempo real…")
        add(.analyzingDirectoryUsageInRealTime, "正在实时分析目录占用…", "正在實時分析目錄佔用…", "Analyzing directory usage in real time…", "リアルタイムでディレクトリ容量を分析中…", "실시간 디렉토리 사용량 분석 중…",
            "Analyse de l'utilisation du répertoire en temps réel…", "Analysiere Verzeichnisbelegung in Echtzeit…", "Analizando el uso de directorios en tiempo real…", "Analisi dell'utilizzo delle directory in tempo reale…", "Analisando o uso de diretórios em tempo real…")
        add(.analyzingInstalledApps, "正在深度分析已安装应用…", "正在深度分析已安裝應用…", "Analyzing installed applications…", "インストール済みアプリを詳細分析中…", "설치된 응용 프로그램 정밀 분석 중…",
            "Analyse approfondie des applications installées…", "Installierte Programme werden analysiert…", "Analizando aplicaciones instaladas a fondo…", "Analisi approfondita delle applicazioni installate…", "Analisando aplicativos instalados a fundo…")
        add(.apfsPurgeableSpacePurgeable, "APFS 可清除空间 (Purgeable)", "APFS 可清除空間 (Purgeable)", "APFS Purgeable Space", "APFS パージ可能領域", "APFS 확보 가능 공간 (Purgeable)",
            "Espace purgeable APFS", "APFS Freigebbarer Speicherplatz", "Espacio purgable APFS", "Spazio eliminabile APFS", "Espaço Purgável APFS")
        add(.appActiveMemory, "App 活跃内存", "App 活躍記憶體", "App Memory", "App メモリ", "앱 활성 메모리",
            "Mémoire des applications", "App-Speicher", "Memoria de apps", "Memoria app", "Memória dos Aplicativos")
        add(.appBinaryBundle, "应用程序本体", "應用程式本體", "Application Bundle", "アプリケーション本体", "응용 프로그램 본체",
            "Paquet de l'application", "Anwendungs-Bundle", "Paquete de la aplicación", "Bundle dell'applicazione", "Pacote do aplicativo")
        add(.appBrowserAndCloudCachesPlusOldLogsKeepsSignInsAndBrowsingHistory, "App、浏览器和云盘缓存及旧日志，保留登录状态和浏览记录", "App、瀏覽器和雲碟快取及舊日誌，保留登入狀態和瀏覽紀錄", "App, browser, and cloud caches plus old logs; keeps sign-ins and browsing history", "App・ブラウザ・クラウドのキャッシュと古いログ（ログイン状態と履歴は保持）", "앱, 브라우저, 클라우드 캐시 및 오래된 로그 (로그인 및 방문 기록 유지)",
            "Caches d’apps, de navigateurs et journaux anciens (conserve les sessions et l’historique)", "App-, Browser- und Cloud-Caches sowie alte Protokolle (Logins und Verlauf bleiben erhalten)", "Cachés de apps, navegadores y registros antiguos (conserva sesiones e historial)", "Cache di app, browser e vecchi log (mantiene accessi e cronologia)", "Caches de apps, navegadores e logs antigos (mantém sessões e histórico)")
        add(.appBundleBody, "应用程序本体", "應用程式本體", "Application Binary", "アプリケーション本体", "응용 프로그램 본체",
            "Binaire de l'application", "Anwendungs-Paket", "Binario de la aplicación", "Binario dell'applicazione", "Binário do Aplicativo")
        add(.appCaches, "用户缓存", "使用者快取", "App Caches", "アプリキャッシュ", "앱 캐시",
            "Caches d’applications", "App-Caches", "Caché de apps", "Cache delle app", "Caches de Apps")
        add(.appCategoryApplicationScripts, "应用脚本", "應用腳本", "App Scripts", "アプリスクリプト", "앱 스크립트",
            "Scripts d'application", "App-Skripte", "Scripts de aplicación", "Script applicazione", "Scripts do aplicativo")
        add(.appCategoryApplicationSupportDesc, "应用程序关联的支持文件或附加目录", "應用程序關聯的支持文件或附加目錄", "Application associated directory", "アプリケーション関連のサポートファイルまたは追加ディレクトリ", "애플리케이션 관련 지원 파일 또는 추가 디렉토리",
            "Fichiers d'assistance ou répertoires associés à l'application", "Zugehörige Support-Dateien oder Zusatzverzeichnisse der App", "Archivos de soporte o directorios asociados a la aplicación", "File di supporto o directory associate all'applicazione", "Arquivos de suporte ou diretórios associados ao aplicativo")
        add(.appCategoryCoreConfigAndDatabase, "应用核心配置、扩展插件与本地业务数据库（含用户数据）", "應用核心配置、擴展插件與本地業務數據庫（含用戶數據）", "Core configuration, plugins & local user data", "アプリ設定・プラグインおよびローカルデータベース（ユーザーデータ含む）", "앱 핵심 설정, 확장 플러그인 및 로컬 업무 데이터베이스 (사용자 데이터 포함)",
            "Configuration principale, modules d'extension et base de données locale", "Kernkonfiguration, Plugins und lokale Datenbank (inkl. Benutzerdaten)", "Configuración básica, plugins y bases de datos locales del usuario", "Configurazione principale, plug-in e database locali (inclusi dati utente)", "Configuração principal, plug-ins e banco de dados local (inclui dados do usuário)")
        add(.appCategoryDiskCacheThumbnails, "应用本地磁盘缓存与缩略图加速数据，清除后会自动重建", "應用本地磁盤緩存與縮略圖加速數據，清除後會自動重建", "Local disk cache, rebuilt automatically", "ローカルディスクキャッシュおよびサムネイル（削除後に自動再生成）", "로컬 디스크 캐시 및 축소판 가속 데이터 (삭제 후 자동 재생성)",
            "Cache disque local et données de vignettes, recréés automatiquement", "Lokaler Festplattencache und Vorschaubilder, werden automatisch neu erstellt", "Caché local en disco y miniaturas, se reconstruyen automáticamente", "Cache del disco locale e miniature, ricreate automaticamente", "Cache local em disco e dados de miniaturas, recriados automaticamente")
        add(.appCategoryEmbeddedWebKitCache, "内置网页视图缓存与网页本地存储数据", "內置網頁視圖緩存與網頁本地存儲數據", "Embedded WebKit browser cache & storage", "内蔵 WebKit ブラウザキャッシュおよびローカルストレージ", "내장 WebKit 브라우저 캐시 및 로컬 웹 저장 데이터",
            "Cache de navigateur WebKit intégré et stockage local", "Eingebetteter WebKit-Browsercache und lokaler Webspeicher", "Caché del navegador WebKit integrado y almacenamiento local", "Cache del browser WebKit incorporato e archiviazione locale", "Cache do navegador WebKit integrado e armazenamento local")
        add(.appCategoryHttpNetworkCache, "网络请求缓存、HSTS 策略与会话存储数据", "網絡請求緩存、HSTS 策略與會話存儲數據", "HTTP network cache & session storage", "ネットワークリクエストキャッシュ、HSTS ポリシー、セッションストレージ", "네트워크 요청 캐시, HSTS 정책 및 세션 저장 데이터",
            "Cache réseau HTTP, règles HSTS et données de session", "HTTP-Netzwerkcache, HSTS-Richtlinien und Sitzungsspeicher", "Caché de red HTTP, directivas HSTS y datos de sesión", "Cache di rete HTTP, criteri HSTS e dati di sessione", "Cache de rede HTTP, políticas HSTS e dados de sessão")
        add(.appCategoryLaunchAgentPlist, "用户登录自启服务与后台伴随助手配置 (.plist)", "用戶登錄自啟服務與後台伴隨助手配置 (.plist)", "User login launch agent plist", "ログイン時自動起動サービスおよびバックグラウンド設定（.plist）", "사용자 로그인 자동 실행 서비스 및 백그라운드 도우미 설정 (.plist)",
            "Agents de lancement au démarrage de l'utilisateur (.plist)", "Launch-Agent-Konfigurationen für den Benutzer-Login (.plist)", "Agentes de inicio de sesión de usuario y asistentes (.plist)", "Agenti di avvio all'accesso dell'utente e assistenti (.plist)", "Agentes de inicialização de login do usuário e assistentes (.plist)")
        add(.appCategoryLaunchDaemonPlist, "系统级后台特权守护服务配置 (.plist)", "系統級後台特權守護服務配置 (.plist)", "System-level background daemon plist", "システムレベルのバックグラウンドデーモン設定（.plist）", "시스템 수준의 백그라운드 데몬 서비스 설정 (.plist)",
            "Démons d'arrière-plan avec privilèges système (.plist)", "Systemweite Hintergrund-Daemon-Konfigurationen (.plist)", "Demonios en segundo plano con privilegios del sistema (.plist)", "Demoni in background con privilegi di sistema (.plist)", "Daemons em segundo plano com privilégios de sistema (.plist)")
        add(.appCategoryLoginCookiesData, "应用内置网络登录凭证与站点 Cookie 数据", "應用內置網絡登錄憑證與站點 Cookie 數據", "Stored login state & binary cookies", "保存されたログイン情報およびサイト Cookie データ", "앱 내장 네트워크 로그인 자격 증명 및 사이트 Cookie 데이터",
            "Identifiants de connexion réseau et cookies de sites", "Gespeicherte Login-Anmeldedaten und Website-Cookies", "Credenciales de inicio de sesión de red y cookies guardadas", "Credenziali di accesso alla rete memorizzate e cookie", "Credenciais de login de rede salvas e dados de cookies")
        add(.appCategoryMainBundleExecutable, "应用程序主程序包（可执行二进制与内置资源）", "應用程序主程序包（可執行二進製與內置資源）", "Main application bundle & executable", "メインアプリケーションバンドル（バイナリと内包リソース）", "기본 애플리케이션 번들 (실행 바이너리 및 내장 리소스)",
            "Paquet principal de l'application (exécutable et ressources)", "Hauptanwendungspaket (ausführbare Binärdateien & Ressourcen)", "Paquete principal de la aplicación (binario ejecutable y recursos)", "Pacchetto principale dell'applicazione (eseguibile e risorse)", "Pacote principal do aplicativo (binário executável e recursos)")
        add(.appCategoryPkgReceiptsAndBom, "系统安装器 (.pkg) 留存的安装记录与 BOM 文件清单", "系統安裝器 (.pkg) 留存的安裝記錄與 BOM 文件清單", "Installer package receipt & BOM", "インストーラ（.pkg）のインストール履歴および BOM マニフェスト", "시스템 설치 프로그램(.pkg)의 설치 기록 및 BOM 파일 목록",
            "Reçus du paquet d'installation (.pkg) et fichiers BOM", "Installationsquittungen (.pkg) und BOM-Dateilisten", "Recibos de paquetes del instalador (.pkg) y listas BOM", "Ricevute pacchetto di installazione (.pkg) e manifest BOM", "Recibos do pacote do instalador (.pkg) e listas de arquivos BOM")
        add(.appCategoryPluginModulesDesc, "应用集成功能扩展或浏览器插件模块", "應用集成功能擴展或瀏覽器插件模塊", "Application plug-in bundle", "アプリ統合機能拡張またはブラウザプラグインモジュール", "애플리케이션 통합 기능 확장 또는 브라우저 플러그인 모듈",
            "Modules d'extension intégrés à l'application ou au navigateur", "Integrierte App-Funktionserweiterungen oder Browser-Plugins", "Módulos de extensión de funciones de la aplicación o plugins", "Moduli di estensione delle funzionalità dell'app o plug-in del browser", "Módulos de extensão de recursos do app ou plug-ins do navegador")
        add(.appCategoryPlugins, "扩展插件", "擴展插件", "Plug-Ins", "プラグイン", "플러그인",
            "Modules externes", "Plug-ins", "Plugins", "Plug-in", "Plug-ins")
        add(.appCategoryPreferencesPlist, "用户个性化设置、快捷键与许可证偏好属性表 (.plist)", "用戶個性化設置、快捷鍵與許可證偏好屬性表 (.plist)", "User settings & preferences plist", "ユーザー設定・ショートカットおよびライセンス設定（.plist）", "사용자 맞춤 설정, 단축키 및 라이선스 환경설정 파일 (.plist)",
            "Préférences utilisateur, raccourcis et licences (.plist)", "Benutzereinstellungen, Tastaturkurzbefehle und Lizenzen (.plist)", "Preferencias de usuario, atajos y licencias (.plist)", "Preferenze utente, scorciatoie e licenze (.plist)", "Preferências do usuário, atalhos e licenças (.plist)")
        add(.appCategoryRuntimeShaderCache, "系统级运行时临时缓存与着色器编译缓存，可安全清除", "系統級運行時臨時緩存與著色器編譯緩存，可安全清除", "macOS runtime & shader temporary cache", "macOS ランタイムおよびシェーダーの一時キャッシュ（安全に削除可能）", "macOS 런타임 및 셰이더 임시 캐시 (안전하게 삭제 가능)",
            "Cache temporaire d'exécution et de shaders macOS", "macOS-Laufzeit- und Shader-Temporärcache (sicher entfernbar)", "Caché temporal de ejecución y sombreadores de macOS", "Cache temporanea di runtime e shader di macOS", "Cache temporário de execução e sombreadores do macOS")
        add(.appCategorySandboxedScriptsDesc, "沙盒应用专属自动化脚本与工作流目录", "沙盒應用專屬自動化腳本與工作流目錄", "Sandboxed automation scripts", "サンドボックスアプリ専用の自動化スクリプトとワークフロー", "샌드박스 앱 전용 자동화 스크립트 및 워크플로 디렉토리",
            "Scripts d'automatisation et flux de travail en bac à sable", "Automatisierungsskripte und Workflows in der Sandbox", "Scripts de automatización y flujos de trabajo aislados", "Script di automazione e flussi di lavoro in sandbox", "Scripts de automação e fluxos de trabalho isolados em sandbox")
        add(.appCategorySessionTemporaryFiles, "应用会话期间产生的临时工作区文件，可安全清除", "應用會話期間產生的臨時工作區文件，可安全清除", "Temporary session files", "アプリセッション中の一時ファイル（安全に削除可能）", "앱 세션 동안 생성된 임시 작업 파일 (안전하게 삭제 가능)",
            "Fichiers temporaires de session d'application", "Temporäre Sitzungsdateien der Anwendung", "Archivos temporales de sesión de la aplicación", "File temporanei di sessione dell'applicazione", "Arquivos temporários de sessão do aplicativo")
        add(.appCategorySharedDeveloperAppGroup, "同开发者主程序、菜单栏助手与小组件共享的数据目录", "同開發者主程序、菜單欄助手與小組件共享的數據目錄", "Shared data container across app & extensions", "同一開発者のアプリ・メニューバー機能・ウィジェット間の共有データ", "동일 개발자 메인 프로그램, 메뉴 막대 도우미 및 위젯 간 공유 데이터",
            "Conteneur de données partagées entre l'application et ses extensions", "Geteilter Datencontainer für App, Menüleisten-Helfer und Widgets", "Contenedor de datos compartido entre la app y sus extensiones", "Container di dati condiviso tra l'app principale e le estensioni", "Contêiner de dados compartilhado entre o app principal e extensões")
        add(.appCategoryWidgetSandboxContainer, "小组件/扩展沙盒容器（存放桌面小组件配置与状态）", "小組件/擴展沙盒容器（存放桌面小組件配置與狀態）", "Widget/extension sandbox container", "ウィジェット／拡張機能サンドボックスコンテナ（設定と状態）", "위젯/확장 프로그램 샌드박스 컨테이너 (위젯 설정 및 상태 저장)",
            "Conteneur sandbox de widgets/extensions (réglages et état)", "Sandbox-Container für Widgets/Erweiterungen (Konfiguration & Status)", "Contenedor de sandbox de widgets/extensiones (ajustes y estado)", "Container sandbox di widget/estensioni (impostazioni e stato)", "Contêiner sandbox de widgets/extensões (configurações e estado)")
        add(.appCategoryWindowLayoutState, "窗口尺寸位置与上次退出时的界面恢复快照", "窗口尺寸位置與上次退出時的界面恢複快照", "Saved window layout & restoration state", "ウィンドウのサイズ・位置および終了時の復元スナップショット", "창 크기 및 위치, 마지막 종료 시의 인터페이스 복원 스냅샷",
            "Taille et position des fenêtres et état de restauration", "Fensterlayout und Status der Wiederherstellung beim Beenden", "Diseño y posición de ventanas y estado de restauración", "Dimensioni e posizione delle finestre e stato di ripristino", "Layout e posição da janela e estado de restauração")
        add(.appMainBundleAndExecutableDesc, "应用程序主程序包与可执行二进制文件", "應用程序主程序包與可執行二進製文件", "Main application bundle and executable binary files", "メインアプリケーションバンドルおよび実行可能バイナリファイル", "애플리케이션 기본 번들 및 실행 바이너리 파일",
            "Paquet principal de l'application et fichiers binaires exécutables", "Hauptanwendungspaket und ausführbare Binärdateien", "Paquete principal de la aplicación y archivos binarios ejecutables", "Pacchetto principale dell'applicazione e file binari eseguibili", "Pacote principal do aplicativo e arquivos binários executáveis")
        add(.appManagerSubtitleCleanUninstall, "彻底卸载已安装应用、清理残留孤立文件与管理关联数据", "徹底卸載已安裝應用、清理殘留孤立文件與管理關聯數據", "Completely uninstall apps, clean leftover files, and manage associated data", "インストール済みアプリの完全アンインストール、残留ファイルの削除、関連データの管理", "설치된 앱 완전 삭제, 잔여 고립 파일 정리 및 관련 데이터 관리",
            "Désinstallez complètement les applications et nettoyez les résidus orphelins", "Vollständiges Deinstallieren von Apps, Bereinigen von Resten und Verwalten zugehöriger Daten", "Desinstale completamente aplicaciones, limpie archivos residuales y gestione datos asociados", "Disinstalla completamente le app, pulisci i file residui e gestisci i dati associati", "Desinstale aplicativos por completo, limpe arquivos órfãos e gerencie dados associados")
        add(.appManagerUnsupported32BitAppsDesc, "旧的 32 位版本应用程序无法在您的操作系统上运行。卸载它们可以释放存储空间。", "舊的 32 位版本應用程序無法在您的操作系統上運行。卸載它們可以釋放存儲空間。", "Legacy 32-bit applications cannot run on your macOS. Uninstall them to free up storage.", "従来の 32 ビットアプリは現在の macOS では起動できません。アンインストールして容量を解放できます。", "기존 32비트 앱은 현재 운영체제에서 실행할 수 없습니다. 삭제하여 저장 공간을 확보하세요.",
            "Les anciennes applications 32 bits ne fonctionnent plus sur macOS. Désinstallez-les pour libérer de l'espace.", "Veraltete 32-Bit-Apps können nicht mehr ausgeführt werden. Deinstallieren Sie sie, um Platz zu sparen.", "Las aplicaciones antiguas de 32 bits no son compatibles con su macOS. Desinstálelas para liberar espacio.", "Le app a 32 bit non possono più essere eseguite su macOS. Disinstallale per recuperare spazio.", "Aplicativos legados de 32 bits não funcionam no seu macOS. Desinstale-os para liberar espaço.")
        add(.appManagerUnusedAppsDesc, "这些应用程序您或许早已不再使用，却持续占用着 Mac 的存储空间。", "這些應用程序您或許早已不再使用，卻持續佔用著 Mac 的存儲空間。", "Apps you may no longer use that are still consuming valuable disk space.", "長期間使用されておらず、ディスクスペースを消費し続けているアプリケーションです。", "오랫동안 사용하지 않았지만 여전히 Mac의 디스크 공간을 차지하고 있는 앱들입니다.",
            "Des applications inutilisées depuis longtemps qui continuent d'occuper de l'espace.", "Apps, die Sie möglicherweise nicht mehr verwenden, die aber Speicherplatz belegen.", "Aplicaciones que quizás ya no use pero que continúan ocupando espacio en su Mac.", "Applicazioni che potresti non usare più ma che continuano a occupare spazio prezioso.", "Aplicativos que você talvez não use mais, mas que continuam ocupando espaço no seu Mac.")
        add(.appManagerUpdatableChannelsDesc, "这些应用程序内置了更新通道。点按「检查」查看各自通过何种方式获取更新。", "這些應用程序內置了更新通道。點按「檢查」查看各自通過何種方式獲取更新。", "These apps include built-in update channels. Click Check to see how each acquires updates.", "これらのアプリにはアップデート機能が組み込まれています。「確認」をクリックして詳細を確認してください。", "이 앱들에는 업데이트 채널이 내장되어 있습니다. '확인'을 클릭하여 업데이트 방식을 확인하세요.",
            "Ces applications intègrent un canal de mise à jour. Cliquez sur Vérifier pour en savoir plus.", "Diese Apps besitzen integrierte Update-Kanäle. Klicken Sie auf Prüfen für Details.", "Estas aplicaciones incluyen canales de actualización. Haga clic en Comprobar para ver detalles.", "Queste app includono canali di aggiornamento integrati. Fai clic su Controlla per i dettagli.", "Esses aplicativos incluem canais de atualização integrados. Clique em Verificar para ver detalhes.")
        add(.appRuntimeDownloadAndRenderCachesRebuiltAutomaticallyWhenLaunched, "应用运行期下载与渲染缓存，清理后可自动重建", "應用執行期下載與渲染快取，清理後可自動重建", "App runtime download and render caches; rebuilt automatically when launched", "アプリ実行時のダウンロードおよび描画キャッシュ。起動時に自動再構築されます", "앱 실행 중 다운로드 및 렌더링 캐시. 정리 후 실행 시 자동 재생성",
            "Caches de téléchargement et de rendu d’exécution ; reconstruits automatiquement au lancement", "App-Laufzeit-Download- und Render-Caches; werden bei Start automatisch neu erstellt", "Cachés de descarga y renderizado de la app; se reconstruyen automáticamente", "Cache di download e rendering dell’app; ricreate automaticamente all’avvio", "Caches de download e renderização do app; recriados automaticamente ao iniciar")
        add(.appUninstallHint, "勾选要卸载的 App，或点击任意 App 展开查看不同文件夹的具体用途", "勾選要卸載的 App，或點擊任意 App 展開檢視不同檔案夾的具體用途", "Check apps to uninstall, or click any app to view folder purposes", "削除するアプリを選択するか、クリックして各フォルダの用途を確認", "삭제할 앱을 선택하거나, 앱을 클릭하여 폴더별 상세 용도를 확인하세요",
            "Cochez les apps à désinstaller, ou cliquez pour voir les dossiers associés", "Programme zum Deinstallieren markieren oder anklicken, um Ordnerdetails zu sehen", "Marca las apps a desinstalar o haz clic para ver carpetas asociadas", "Seleziona le app da disinstallare o fai clic per visualizzare le cartelle", "Marque os apps para desinstalar ou clique para ver a finalidade das pastas")
        add(.appearanceAndTheme, "外观与主题", "外觀與主題", "Appearance & Theme", "外観とテーマ", "화면 모드 및 테마",
            "Apparence et thème", "Erscheinungsbild & Thema", "Apariencia y tema", "Aspetto e tema", "Aparência e Tema")
        add(.appearanceConfig, "外观配置", "外觀配置", "Appearance", "外観設定", "외관 설정",
            "Apparence", "Erscheinungsbild", "Apariencia", "Aspetto", "Aparência")
        add(.appearanceMode, "外观模式", "外觀模式", "Appearance", "外観モード", "화면 모드",
            "Mode d’apparence", "Erscheinungsbild", "Modo de apariencia", "Modalità aspetto", "Modo de Aparência")
        add(.appearanceModeAndTheme, "外观模式与配色", "外觀模式與配色", "Appearance & Theme", "外観モードと配色", "화면 모드 및 테마",
            "Apparence et thème", "Erscheinungsbild & Thema", "Apariencia y tema", "Aspetto e tema", "Aparência e Tema")
        add(.applicationHelperRendererProcess, "应用程序子进程 / 渲染沙箱", "應用程序子進程 / 渲染沙箱", "Application Helper / Renderer Process", "アプリケーションヘルパー／レンダリングサンドボックス", "애플리케이션 도우미 / 렌더러 샌드박스 프로세스",
            "Processus d'assistance d'application / Bac à sable de rendu", "App-Hilfsprozess / Renderer-Sandbox", "Proceso asistente de aplicación / Sandbox de renderizado", "Processo helper dell'applicazione / Sandbox di rendering", "Processo auxiliar do aplicativo / Sandbox de renderização")
        add(.applicationPreferencesShortcutsAndUiSettingsPlist, "应用个性化开关、快捷键与界面偏好配置 (.plist)", "應用個性化開關、快捷鍵與界面偏好配置 (.plist)", "Application preferences, shortcuts, and UI settings (.plist)", "アプリの環境設定、ショートカットキー、UI設定 (.plist)", "앱 개인화 설정, 단축키 및 인터페이스 환경설정 (.plist)",
            "Préférences de l’application, raccourcis et réglages d’interface (.plist)", "App-Einstellungen, Tastaturkurzbefehle und Oberflächenoptionen (.plist)", "Preferencias de la aplicación, atajos y ajustes de interfaz (.plist)", "Preferenze dell’applicazione, scorciatoie e impostazioni dell’interfaccia (.plist)", "Preferências do aplicativo, atalhos e configurações de interface (.plist)")
        add(.applicationRuntimeDebugLogsAndHistoricalCrashReports, "应用运行调试日志与历史崩溃诊断报告", "應用執行調試日誌與歷史當機診斷報告", "Application runtime debug logs and historical crash reports", "アプリ実行時のデバッグログおよび過去のクラッシュ診断レポート", "앱 런타임 디버그 로그 및 과거 충돌 진단 보고서",
            "Journaux de débogage d’exécution de l’application et rapports de plantage historiques", "App-Laufzeit-Debugprotokolle und historische Absturzberichte", "Registros de depuración de la app e informes históricos de fallos", "Registri di debug dell’app e rapporti storici sugli arresti anomali", "Logs de depuração do app e relatórios históricos de falhas")
        add(.applicationRuntimeLogsAndDiagnosticTracesSafeToRemove, "应用运行日志与调试诊断记录（可安全清理）", "應用程式執行日誌與除錯診斷記錄（可安全清理）", "Application runtime logs and diagnostic traces (safe to remove)", "アプリの実行ログと診断記録（安全に削除可能）", "앱 실행 로그 및 디버그 진단 기록 (안전하게 삭제 가능)",
            "Journaux d’exécution et traces de diagnostic (suppression sûre)", "Laufzeitprotokolle und Diagnosedaten (sicher löschbar)", "Registros de ejecución y diagnóstico (seguro de eliminar)", "Log di esecuzione e tracciati diagnostici (rimozione sicura)", "Logs de execução e registros de diagnóstico (seguro remover)")
        add(.applicationsManager, "应用程序管理器", "應用程式管理器", "Applications Manager", "アプリケーションマネージャー", "응용 프로그램 관리자",
            "Gestionnaire d’applications", "Programm-Manager", "Gestor de aplicaciones", "Gestore applicazioni", "Gerenciador de Aplicativos")
        add(.archOnly32Bit, "仅 32 位", "僅 32 位元", "32-bit Only", "32ビット専用", "32비트 전용",
            "32 bits uniquement", "Nur 32-Bit", "Solo 32 bits", "Solo 32 bit", "Apenas 32 bits")
        add(.assistantAllGoodNoSuggestionsPrompt, "一切正常！今日暂无优化建议。", "一切正常！今日暫無優化建議。", "All good! No optimization suggestions today.", "すべて順調です！現在必要な最適化提案はありません。", "모든 상태가 양호합니다! 오늘 필요한 최적화 제안이 없습니다.",
            "Tout va bien ! Aucune suggestion d'optimisation aujourd'hui.", "Alles bestens! Heute sind keine Optimierungsvorschläge nötig.", "¡Todo en orden! No hay sugerencias de optimización para hoy.", "Tutto a posto! Nessun suggerimento di ottimizzazione per oggi.", "Tudo certo! Nenhuma sugestão de otimização para hoje.")
        add(.assistantBigFilesCountFormat, "存在 %d 个超大文件", "存在 %d 個超大檔案", "Found %d very large files", "%d 個の超大容量ファイルが存在します", "%d개의 대용량 파일 존재",
            "%d très gros fichiers détectés", "%d sehr große Dateien vorhanden", "Hay %d archivos muy grandes", "Trovati %d file di grandi dimensioni", "%d arquivos muito grandes encontrados")
        add(.assistantBigFilesOnDesktopDownloadsFormat, "下载与桌面上有 %@ 的单个文件超过 1GB。", "下載與桌面上有 %@ 的單一檔案超過 1GB。", "Downloads and Desktop have %@ in individual files exceeding 1GB.", "ダウンロードやデスクトップに 1GB 超のファイルが %@ あります。", "다운로드 및 데스크탑에 1GB를 초과하는 파일이 %@ 있습니다.",
            "Téléchargements et Bureau contiennent %@ de fichiers de plus d'1 Go.", "Downloads und Schreibtisch enthalten %@ an Dateien über 1 GB.", "Descargas y Escritorio tienen %@ en archivos individuales de más de 1 GB.", "Download e Scrivania contengono %@ di file superiori a 1 GB.", "Downloads e Mesa têm %@ em arquivos individuais com mais de 1 GB.")
        add(.assistantCacheUsageHighTitle, "缓存占用偏高", "緩存佔用偏高", "High Cache Usage", "キャッシュ使用量が高いです", "캐시 사용량 높음",
            "Utilisation élevée du cache", "Hohe Cache-Belegung", "Uso elevado de caché", "Utilizzo elevato della cache", "Uso elevado de cache")
        add(.assistantCachesHighDescFormat, "用户缓存已占 %@，建议跑一次垃圾清理。", "使用者快取已佔 %@，建議跑一次垃圾清理。", "User caches occupy %@. A cleanup scan is recommended.", "ユーザーキャッシュが %@ を消費しています。クリーンアップの実行をお勧めします。", "사용자 캐시가 %@를 차지하고 있습니다. 정리를 실행하는 것을 권장합니다.",
            "Les caches utilisateur occupent %@. Un nettoyage est recommandé.", "Benutzer-Caches belegen %@. Ein Bereinigungsscan wird empfohlen.", "La caché de usuario ocupa %@. Se recomienda ejecutar una limpieza.", "La cache utente occupa %@. Si consiglia di eseguire una pulizia.", "O cache do usuário ocupa %@. Recomenda-se realizar uma limpeza.")
        add(.assistantCachesHighTitle, "缓存占用偏高", "快取佔用偏高", "High Cache Usage", "キャッシュ使用量が高めです", "캐시 사용량 높음",
            "Utilisation élevée du cache", "Hohe Cache-Belegung", "Uso elevado de caché", "Utilizzo elevato della cache", "Alto Uso de Cache")
        add(.assistantDeviceBackupRemainingDescFormat, "设备备份已占 %@，过时的备份可清理。", "裝置備份已佔 %@，過時的備份可清理。", "Device backups occupy %@. Outdated backups can be cleaned.", "デバイスバックアップが %@ を占有中。古いものは削除可能です。", "기기 백업이 %@을(를) 차지합니다. 오래된 백업을 정리할 수 있습니다.",
            "Les sauvegardes occupent %@. Les anciennes peuvent être supprimées.", "Gerätesicherungen belegen %@. Veraltete Backups können gelöscht werden.", "Las copias ocupan %@. Se pueden eliminar las obsoletas.", "I backup occupano %@. Quelli obsoleti possono essere rimossi.", "Os backups ocupam %@. Backups antigos podem ser limpos.")
        add(.assistantDiscoveredHugeFilesTitleFormat, "存在 %d 个超大文件", "存在 %d 個超大檔案", "%d massive files found", "%d 件の超特大ファイルが存在します", "%d개의 초대형 파일 발견",
            "%d fichiers volumineux trouvés", "%d sehr große Dateien gefunden", "Se encontraron %d archivos enormes", "%d file molto grandi trovati", "%d arquivos enormes encontrados")
        add(.assistantDiskFreeSpaceLowDescFormat, "剩余空间不足 10%（%@），可能影响系统性能。", "剩餘空間不足 10%（%@），可能影響系統效能。", "Free disk space is below 10% (%@), which may impact macOS performance.", "空き容量が 10% 未満（%@）です。システムの動作速度に悪影響を及ぼす可能性があります。", "여유 공간이 10% 미만(%@)으로 남아 있어 시스템 성능에 영향을 줄 수 있습니다.",
            "L'espace libre est inférieur à 10% (%@), ce qui peut dégrader les performances.", "Der freie Speicherplatz liegt unter 10 % (%@), was die Leistung mindern kann.", "El espacio libre es inferior al 10% (%@), lo que puede afectar el rendimiento del sistema.", "Lo spazio libero è inferiore al 10% (%@), il che potrebbe compromettere le prestazioni.", "O espaço livre está abaixo de 10% (%@), o que pode afetar o desempenho do sistema.")
        add(.assistantDiskSpaceLowTitle, "磁盘空间不足", "磁碟空間不足", "Low Disk Space", "空きディスク容量が低下しています", "디스크 여유 공간 부족",
            "Espace disque faible", "Wenig freier Festplattenspeicher", "Poco espacio en disco", "Spazio su disco in esaurimento", "Pouco Espaço em Disco")
        add(.assistantEvaluationScoreExcellentDesc, "您的 Mac 电脑表现出色。记得定期进行维护，以保持这种状态。", "您的 Mac 電腦表現出色。記得定期進行維護，以保持這種狀態。", "Your Mac is performing exceptionally well. Remember to run routine maintenance to keep it that way.", "お使いの Mac は素晴らしいパフォーマンスを発揮しています。定期的なメンテナンスで状態を維持しましょう。", "Mac이 최상의 성능을 발휘하고 있습니다. 정기 유지 관리를 통해 이 상태를 유지하세요.",
            "Votre Mac fonctionne parfaitement. Pensez à effectuer un entretien régulier pour maintenir ce niveau.", "Ihr Mac läuft hervorragend. Führen Sie regelmäßige Wartungen durch, um dies beizubehalten.", "Tu Mac funciona de maravilla. Recuerda realizar un mantenimiento regular para conservarlo así.", "Il tuo Mac funziona in modo eccellente. Ricorda di eseguire una manutenzione regolare per mantenerlo tale.", "Seu Mac está com ótimo desempenho. Lembre-se de fazer manutenção regular para mantê-lo assim.")
        add(.assistantEvaluationScoreFairDesc, "您的 Mac 电脑目前状况尚可，但建议进行一些维护操作，以避免性能下降。", "您的 Mac 電腦目前狀況尚可，但建議進行一些維護操作，以避免效能下降。", "Your Mac is doing okay, but routine maintenance is recommended to prevent performance slowdowns.", "お使いの Mac は現在問題ありませんが、速度低下を防ぐためにメンテナンスをお勧めします。", "Mac 상태가 보통입니다. 성능 저하를 방지하기 위해 유지 관리 작업을 권장합니다.",
            "L'état de votre Mac est acceptable, mais un entretien est recommandé pour éviter les ralentissements.", "Ihr Mac ist in passabler Verfassung. Wartungsarbeiten werden empfohlen, um Verlangsamungen vorzubeugen.", "Tu Mac está bien, pero se recomienda realizar mantenimiento para evitar una pérdida de rendimiento.", "Il tuo Mac è in discrete condizioni, ma si consiglia una manutenzione per evitare cali di prestazioni.", "Seu Mac está funcionando razoavelmente, mas recomendamos uma manutenção para evitar lentidão.")
        add(.assistantEvaluationScoreGoodDesc, "您的 Mac 电脑状况良好。可以进行一些维护操作，以使其表现更佳。", "您的 Mac 電腦狀況良好。可以進行一些維護操作，以使其表現更佳。", "Your Mac is in good shape. Running a few maintenance tasks will make it even faster.", "お使いの Mac の状態は良好です。いくつかのメンテナンスタスクを実行するとさらに快適になります。", "Mac 상태가 양호합니다. 몇 가지 유지 관리를 진행하면 성능이 더 향상됩니다.",
            "Votre Mac est en bon état. Quelques tâches d'entretien peuvent encore améliorer ses performances.", "Ihr Mac ist in gutem Zustand. Einige Wartungsaufgaben können die Leistung weiter steigern.", "Tu Mac está en buen estado. Realizar algunas tareas de mantenimiento mejorará su rendimiento.", "Il tuo Mac è in buone condizioni. Alcune operazioni di manutenzione ne miglioreranno le prestazioni.", "Seu Mac está em bom estado. Executar algumas tarefas de manutenção melhorará ainda mais o desempenho.")
        add(.assistantEvaluationScorePoorDesc, "您的 Mac 电脑状况不佳。运行一些维护操作，以恢复其性能。", "您的 Mac 電腦狀況不佳。執行一些維護操作，以恢復其效能。", "Your Mac needs attention. Run recommended maintenance tasks to restore its full performance.", "お使いの Mac の状態が低下しています。メンテナンスタスクを実行してパフォーマンスを回復しましょう。", "Mac 상태가 원활하지 않습니다. 권장 작업을 실행하여 성능을 복구하세요.",
            "Votre Mac nécessite une intervention. Exécutez les tâches d'entretien pour restaurer ses performances.", "Ihr Mac benötigt Aufmerksamkeit. Führen Sie empfohlene Wartungsaufgaben aus, um die Leistung wiederherzustellen.", "Tu Mac necesita atención. Ejecuta las tareas de mantenimiento recomendadas para recuperar su velocidad.", "Il tuo Mac richiede attenzione. Esegui le attività di manutenzione consigliate per ripristinare le prestazioni.", "Seu Mac precisa de cuidados. Execute as tarefas de manutenção recomendadas para restaurar o desempenho.")
        add(.assistantEvaluationScoreSummaryFormat, "健康分 %d · %d 项建议", "健康分 %d · %d 項建議", "Health Score %d · %d suggestions", "ヘルススコア %d · %d 個の提案", "건강 점수 %d · %d개의 제안",
            "Score de santé %d · %d suggestions", "Gesundheitswert %d · %d Empfehlungen", "Puntuación de salud %d · %d sugerencias", "Punteggio di salute %d · %d suggerimenti", "Pontuação de Saúde %d · %d sugestões")
        add(.assistantHealthAssessmentTitle, "助手健康评估", "助手健康評估", "Assistant Health Assessment", "アシスタント健康評価", "도우미 건강 상태 평가",
            "Évaluation de santé par l'assistant", "Assistenten-Integritätsbewertung", "Evaluación de estado del asistente", "Valutazione di salute dell'assistente", "Avaliação de integridade do assistente")
        add(.assistantHeroSubtitle, "评估 Mac 的整体健康状况，并给出可执行的改进建议。", "評估 Mac 的整體健康狀況，並給出可執行的改進建議。", "Assess your Mac's overall health and provide actionable optimization tips.", "Mac の全体的な健全性を評価し、実用的な最適化提案を提供します。", "Mac의 전반적인 상태를 평가하고 실행 가능한 최적화 팁을 제공합니다.",
            "Évaluez la santé globale de votre Mac et obtenez des conseils pratiques.", "Gesamtzustand Ihres Mac bewerten und konkrete Optimierungstipps erhalten.", "Evalúe el estado general de su Mac y obtenga consejos prácticos de optimización.", "Valuta lo stato generale del Mac e ricevi consigli pratici di ottimizzazione.", "Avalie a integridade geral do seu Mac e obtenha dicas práticas de otimização.")
        add(.assistantHugeFilesCountDescFormat, "下载与桌面上有 %@ 的单个文件超过 1GB。", "下載與桌面上有 %@ 的單個檔案超過 1GB。", "Found %@ in single files over 1GB across Downloads and Desktop.", "ダウンロードやデスクトップに、1GBを超える合計 %@ のファイルが存在します。", "다운로드 및 데스크탑에 1GB를 초과하는 파일이 총 %@ 있습니다.",
            "%@ de fichiers dépassant 1 Go trouvés dans Téléchargements et Bureau.", "Downloads und Schreibtisch enthalten %@ an Dateien über 1 GB.", "Se encontraron %@ en archivos individuales de más de 1 GB en Descargas y Escritorio.", "Trovati %@ in singoli file superiori a 1GB tra Download e Scrivania.", "Encontrados %@ em arquivos individuais com mais de 1GB em Downloads e Mesa.")
        add(.assistantIosBackupDescFormat, "设备备份已占 %@（只读保护，可在垃圾清理或访达中查看备份详情）。", "裝置備份已佔 %@（唯讀保護，可在垃圾清理或 Finder 中查看備份詳情）。", "Device backups occupy %@ (read-only protected; inspect backup details in Junk or Finder).", "デバイスバックアップが %@ を占有しています（読み取り専用保護・詳細は不要ファイルまたは Finder で確認できます）。", "기기 백업이 %@를 차지하고 있습니다(읽기 전용 보호, 정크 정리 또는 Finder에서 백업 세부 정보 확인 가능).",
            "Les sauvegardes d'appareils occupent %@ (protégées en lecture seule ; inspectez-les dans Fichiers inutiles ou le Finder).", "Geräte-Backups belegen %@ (schreibgeschützt; Details in Systemmüll oder im Finder prüfen).", "Las copias de seguridad ocupan %@ (protegidas en solo lectura; revíselas en Basura o Finder).", "I backup dei dispositivi occupano %@ (protetti in sola lettura; ispezionali in File inutili o nel Finder).", "Backups de dispositivos ocupam %@ (protegidos para somente leitura; inspecione em Lixo ou no Finder).")
        add(.assistantIosBackupLargeTitle, "iOS 备份占用较大", "iOS 備份佔用較大", "Large iOS Backup Footprint", "iOS バックアップが容量を消費しています", "iOS 백업 용량 과다",
            "Sauvegardes iOS volumineuses", "Große iOS-Backups", "Copias de seguridad de iOS voluminosas", "Backup iOS voluminoso", "Backups do iOS Ocupando Muito Espaço")
        add(.assistantLoginItemsCountDescFormat, "有 %d 个登录启动项，过多会拖慢开机速度。", "有 %d 個登入啟動項，過多會拖慢開機速度。", "There are %d login items. Too many can slow down startup.", "ログイン項目が %d 個あります。多すぎると起動が遅くなります。", "시동 항목이 %d개 있습니다. 너무 많으면 부팅이 느려집니다.",
            "Il y a %d éléments d'ouverture. Trop d'éléments ralentissent le démarrage.", "Es gibt %d Anmeldeobjekte. Zu viele verlangsamen den Start.", "Hay %d elementos de inicio. Demasiados pueden ralentizar el arranque.", "Ci sono %d elementi di login. Troppi possono rallentare l'avvio.", "Há %d itens de início. Muitos podem deixar a inicialização lenta.")
        add(.assistantLowDiskSpaceRemainingDescFormat, "剩余空间不足 10%%（%@），可能影响系统性能。", "剩餘空間不足 10%%（%@），可能影響系統效能。", "Free space is under 10%% (%@), which may impact performance.", "空き容量が10%%未満（%@）です。性能に影響する可能性があります。", "여유 공간이 10%% 미만(%@)으로, 성능에 영향을 줄 수 있습니다.",
            "Moins de 10 %% d'espace libre (%@), ce qui peut dégrader les performances.", "Freier Speicher unter 10 %% (%@), was die Leistung beeinträchtigen kann.", "Espacio libre inferior al 10 %% (%@), lo que puede afectar el rendimiento.", "Spazio libero inferiore al 10%% (%@), potrebbe influire sulle prestazioni.", "Espaço livre abaixo de 10%% (%@), o que pode afetar o desempenho.")
        add(.assistantTooManyStartupItemsTitle, "启动项偏多", "啟動項偏多", "Too Many Startup Items", "スタートアップ項目が多すぎます", "시작 프로그램이 너무 많음",
            "Trop d'éléments au démarrage", "Zu viele Startobjekte", "Demasiados elementos de inicio", "Troppi elementi di avvio", "Muitos itens de inicialização")
        add(.assistantTrashNotEmptyTitle, "废纸篓未清空", "廢紙簍未清空", "Trash Not Emptied", "ゴミ箱が空になっていません", "휴지통이 비워지지 않음",
            "Corbeille non vidée", "Papierkorb nicht geleert", "Papelera no vaciada", "Cestino non svuotato", "Lixeira não esvaziada")
        add(.assistantTrashRemainingDescFormat, "废纸篓里还有 %@，清倒后立即释放空间。", "垃圾桶裡還有 %@，清理後立即釋放空間。", "Trash contains %@. Empty it now to reclaim space.", "ゴミ箱に %@ 残っています。空にして容量を解放しましょう。", "휴지통에 %@이(가) 있습니다. 비워서 공간을 확보하세요.",
            "La corbeille contient %@. Videz-la pour libérer de l'espace.", "Der Papierkorb enthält %@. Leeren Sie ihn, um Platz zu schaffen.", "La papelera contiene %@. Vacíala ahora para liberar espacio.", "Il cestino contiene %@. Svuotalo per liberare spazio.", "O lixo contém %@. Esvazie-o para liberar espaço.")
        add(.assistantUserCacheRemainingDescFormat, "用户缓存已占 %@，建议跑一次垃圾清理。", "使用者快取已佔 %@，建議執行一次垃圾清理。", "User cache occupies %@. A junk cleanup is recommended.", "ユーザーキャッシュが %@ を占有中。クリーンアップをおすすめします。", "사용자 캐시가 %@을(를) 차지합니다. 정리를 권장합니다.",
            "Le cache utilisateur occupe %@. Un nettoyage est recommandé.", "Benutzercache belegt %@. Bereinigung wird empfohlen.", "La caché de usuario ocupa %@. Se recomienda una limpieza.", "La cache utente occupa %@. Si consiglia una pulizia.", "O cache do usuário ocupa %@. Uma limpeza é recomendada.")
        add(.associatedSupportFilesOrConfigurationDirectoriesForTheApplication, "应用关联的支持文件或配置目录", "應用關聯的支援檔案或配置目錄", "Associated support files or configuration directories for the application", "アプリに関連するサポートファイルまたは設定ディレクトリ", "애플리케이션과 연관된 지원 파일 또는 설정 디렉토리",
            "Fichiers de support ou répertoires de configuration associés à l’application", "Zugehörige Support-Dateien oder Konfigurationsverzeichnisse der App", "Archivos de soporte o directorios de configuración asociados a la app", "File di supporto o cartelle di configurazione associati all’applicazione", "Arquivos de suporte ou diretórios de configuração associados ao aplicativo")
        add(.availableLabel, "可用", "可用", "Available", "空き", "사용 가능",
            "Disponible", "Verfügbar", "Disponible", "Disponibile", "Disponível")
        add(.averagePeakFormat, "均值 %.1f%% · 峰值 %.1f%%", "平均 %.1f%% · 峰值 %.1f%%", "Avg %.1f%% · Peak %.1f%%", "平均 %.1f%% · ピーク %.1f%%", "평균 %.1f%% · 최대 %.1f%%",
            "Moyenne %.1f%% · Pic %.1f%%", "Mittel %.1f%% · Spitze %.1f%%", "Promedio %.1f%% · Pico %.1f%%", "Media %.1f%% · Picco %.1f%%", "Média %.1f%% · Pico %.1f%%")
        add(.avgLoad1m5m15m, "系统平均负载 (1m / 5m / 15m)", "系統平均負載 (1分 / 5分 / 15分)", "Load Average (1m / 5m / 15m)", "ロードアベレージ (1分/5分/15分)", "평균 부하율 (1분 / 5분 / 15분)",
            "Charge moyenne (1m / 5m / 15m)", "Lastdurchschnitt (1m / 5m / 15m)", "Carga media (1m / 5m / 15m)", "Carico medio (1m / 5m / 15m)", "Carga Média (1m / 5m / 15m)")
        add(.backgroundItems, "后台项目", "背景項目", "Background Services", "バックグラウンド項目", "백그라운드 서비스",
            "Services en arrière-plan", "Hintergrunddienste", "Servicios en segundo plano", "Servizi in background", "Serviços em Segundo Plano")
        add(.backgroundRunningItems, "后台运行项", "背景執行項", "Background Items", "バックグラウンド項目", "백그라운드 항목",
            "Éléments en arrière-plan", "Hintergrundobjekte", "Ítems en segundo plano", "Elementi in background", "Itens em segundo plano")
        add(.badgeCalculating, "计算中", "計算中", "Calculating", "計算中", "계산 중",
            "Calcul en cours", "Berechnung", "Calculando", "Calcolo in corso", "Calculando")
        add(.badgeNewest, "最新", "最新", "Newest", "最新", "최신",
            "Le plus récent", "Neueste", "Más reciente", "Più recente", "Mais recente")
        add(.badgeWillKeep, "将保留", "將保留", "Will Keep", "保持予定", "유지 예정",
            "Sera conservé", "Wird behalten", "Se conservará", "Verrà mantenuto", "Será mantido")
        add(.bannerAddedToIgnoreList, "项目已被添加到忽略列表", "項目已被添加到忽略列表", "Item added to Ignore List", "項目を除外リストに追加しました", "항목이 제외 목록에 추가되었습니다",
            "Élément ajouté à la liste d’exclusion", "Objekt zur Ignorierliste hinzugefügt", "Elemento añadido a la lista de exclusión", "Elemento aggiunto all’elenco di esclusione", "Item adicionado à Lista de Exclusão")
        add(.bannerAddedToWhitelist, "项目已被添加到忽略白名单", "項目已被添加到忽略白名單", "Item added to Whitelist", "項目をホワイトリストに追加しました", "항목이 화이트리스트에 추가되었습니다",
            "Élément ajouté à la liste blanche", "Objekt zur Whitelist hinzugefügt", "Elemento añadido a la lista blanca", "Elemento aggiunto alla whitelist", "Item adicionado à Lista Branca")
        add(.battery, "电池", "電池", "Battery", "バッテリー", "배터리",
            "Batterie", "Batterie", "Batería", "Batteria", "Bateria")
        add(.batteryChargingStateCharging, "正在充电中", "正在充電中", "Charging", "充電中", "충전 중",
            "En charge", "Lädt", "Cargando", "In carica", "Carregando")
        add(.batteryChargingStateFull, "已连接电源 (充满)", "已連接電源 (充滿)", "Fully Charged", "充電完了", "완충됨 (전원 연결됨)",
            "Complètement chargée", "Vollständig geladen", "Completamente cargada", "Completamente carica", "Totalmente carregada")
        add(.batteryCycleCountFormat, "%d 次", "%d 次", "%d cycles", "%d 回", "%d회",
            "%d cycles", "%d Zyklen", "%d ciclos", "%d cicli", "%d ciclos")
        add(.batteryHealthPowerDraw, "电池健康与电源功率", "電池健康度與電源功率", "Battery Health & Power Draw", "バッテリー状態と消費電力", "배터리 수명 및 전력 상태",
            "Santé de la batterie et puissance", "Batteriezustand & Leistungsaufnahme", "Salud de la batería y consumo", "Stato batteria e potenza erogata", "Saúde da Bateria e Potência")
    }


    /// 按强类型键名与目标语言获取本地化文本
    static func text(for key: L10nKey, lang: AppLanguage) -> String {
        if let entry = entries[key] {
            return entry.text(for: lang)
        }
        return entries[.statusUnknown]?.text(for: lang) ?? "—"
    }

}

private extension LocalizationCatalog {
    static func populateSafetyRemediation(_ map: inout [L10nKey: MultiLangEntry]) {
        func add(_ key: L10nKey, _ zh: String, _ hant: String, _ en: String, _ ja: String, _ ko: String,
                 _ fr: String, _ de: String, _ es: String, _ it: String, _ pt: String) {
            map[key] = MultiLangEntry(zhHans: zh, zhHant: hant, en: en, ja: ja, ko: ko, fr: fr, de: de, es: es, it: it, ptBR: pt)
        }
        add(.cleanupLogReason, "日志候选；仅已识别的非活动日志文件可默认选择，执行前会复核文件占用。", "日誌候選；僅已識別的非活動日誌檔可預設選取，執行前會複核檔案佔用。", "Log candidate. Only recognized inactive log files qualify for defaults; open handles are checked before execution.", "ログ候補です。認識済みの非アクティブなログのみ初期選択の対象となり、実行前に使用状況を確認します。", "로그 후보입니다. 확인된 비활성 로그만 기본 선택 대상이며 실행 전에 파일 사용 상태를 확인합니다.", "Journal candidat. Seuls les journaux reconnus inactifs sont présélectionnables ; les fichiers ouverts sont vérifiés avant exécution.", "Log-Kandidat. Nur erkannte inaktive Logs sind vorwählbar; offene Dateien werden vor Ausführung geprüft.", "Registro candidato. Solo se preseleccionan registros reconocidos e inactivos; se comprueba su uso antes de ejecutar.", "Registro candidato. Solo i log riconosciuti e inattivi sono preselezionabili; i file aperti vengono verificati prima dell’esecuzione.", "Log candidato. Apenas logs reconhecidos e inativos podem ser pré-selecionados; arquivos abertos são verificados antes da execução.")
        add(.cleanupRuleLabel, "清理规则", "清理規則", "Cleanup rule", "削除ルール", "정리 규칙", "Règle de nettoyage", "Bereinigungsregel", "Regla de limpieza", "Regola di pulizia", "Regra de limpeza")
        add(.cleanupManualReview, "此项可能包含配置或持久数据。请检查内容后确认，默认不选。", "此項可能包含設定或持久資料。請檢查內容後確認，預設不選。", "May contain settings or persistent data. Review contents before confirming; unselected by default.", "設定や永続データを含む可能性があります。内容を確認してください。初期選択はオフです。", "설정 또는 영구 데이터가 포함될 수 있습니다. 내용을 확인하세요. 기본 선택은 해제됩니다.", "Peut contenir des réglages ou des données persistantes. Vérifiez le contenu ; non sélectionné par défaut.", "Kann Einstellungen oder dauerhafte Daten enthalten. Inhalt prüfen; standardmäßig nicht ausgewählt.", "Puede contener ajustes o datos persistentes. Revise el contenido; sin seleccionar por defecto.", "Può contenere impostazioni o dati persistenti. Controlla il contenuto; non selezionato di default.", "Pode conter configurações ou dados persistentes. Revise o conteúdo; desmarcado por padrão.")
        add(.cleanupCacheReason, "命中已实现的缓存规则；执行前仍会复核保护项与文件身份。", "命中已實作的快取規則；執行前仍會複核保護項與檔案身分。", "Matches an implemented cache rule. Protection and file identity are checked again before execution.", "実装済みのキャッシュルールに一致します。実行前に保護項目とファイルの同一性を再確認します。", "구현된 캐시 규칙과 일치합니다. 실행 전에 보호 항목과 파일 식별 정보를 다시 확인합니다.", "Correspond à une règle de cache implémentée. Protection et identité du fichier sont revérifiées avant exécution.", "Entspricht einer implementierten Cache-Regel. Schutz und Dateiidentität werden vor Ausführung erneut geprüft.", "Coincide con una regla de caché implementada. Se revisan protección e identidad antes de ejecutar.", "Corrisponde a una regola cache implementata. Protezione e identità del file vengono ricontrollate prima dell’esecuzione.", "Corresponde a uma regra de cache implementada. Proteção e identidade são verificadas novamente antes da execução.")
        add(.cleanupPackageReason, "包仓库可能包含离线唯一副本；清理后可能无法重新下载。请人工确认。", "套件庫可能包含離線唯一副本；清理後可能無法重新下載。請人工確認。", "Package stores may contain the only offline copy. Downloads may no longer be available. Confirm manually.", "パッケージ保管庫には唯一のオフラインコピーが含まれる可能性があります。再取得できない場合があるため確認してください。", "패키지 저장소에 유일한 오프라인 사본이 있을 수 있으며 다시 다운로드하지 못할 수 있습니다. 직접 확인하세요.", "Le dépôt peut contenir la seule copie hors ligne. Le téléchargement peut être indisponible. Confirmez manuellement.", "Der Paketspeicher kann die einzige Offline-Kopie enthalten. Erneutes Laden kann unmöglich sein. Manuell bestätigen.", "El almacén puede contener la única copia sin conexión. Puede no ser posible volver a descargarla. Confirme manualmente.", "Il deposito può contenere l’unica copia offline. Potrebbe non essere più scaricabile. Conferma manualmente.", "O repositório pode conter a única cópia offline. O download pode não estar mais disponível. Confirme manualmente.")
        add(.cleanupDerivedReason, "Xcode 构建产物。仅已确认工程路径失效且 Xcode 关闭的孤儿项可默认选择。", "Xcode 建置產物。僅已確認專案路徑失效且 Xcode 關閉的孤兒項可預設選取。", "Xcode build data. Only verified missing-workspace data with Xcode closed can be selected by default.", "Xcodeのビルドデータです。プロジェクトの消失を確認し、Xcodeが終了している場合のみ初期選択できます。", "Xcode 빌드 데이터입니다. 프로젝트가 없고 Xcode가 종료되었음을 확인한 항목만 기본 선택됩니다.", "Données de compilation Xcode. Seules les données sans projet vérifié et avec Xcode fermé peuvent être présélectionnées.", "Xcode-Build-Daten. Nur bei nachweislich fehlendem Projekt und geschlossenem Xcode vorwählbar.", "Datos de compilación Xcode. Solo se preseleccionan si se verifica que falta el proyecto y Xcode está cerrado.", "Dati di compilazione Xcode. Preselezionabili solo se il progetto è assente e Xcode è chiuso, dopo verifica.", "Dados de compilação Xcode. Só são pré-selecionados com projeto ausente verificado e Xcode fechado.")
        add(.cleanupProtectedReason, "受保护数据，仅供查看。", "受保護資料，僅供檢視。", "Protected data; view only.", "保護されたデータです。閲覧のみ。", "보호된 데이터입니다. 보기만 가능합니다.", "Données protégées ; consultation seule.", "Geschützte Daten; nur Ansicht.", "Datos protegidos; solo lectura.", "Dati protetti; sola lettura.", "Dados protegidos; somente leitura.")
        add(.cleanupUninstallBlocked, "应用本体未成功移入废纸篓，或仍有其他安装使用此数据；已保留关联数据。", "應用程式本體未成功移入垃圾桶，或仍有其他安裝使用此資料；已保留關聯資料。", "The app was not moved to Trash, or another installation still uses this data. Associated data was preserved.", "アプリをゴミ箱へ移動できないか、別のインストールが使用中のため、関連データを保持しました。", "앱이 휴지통으로 이동되지 않았거나 다른 설치가 사용 중이므로 관련 데이터를 보존했습니다.", "L’app n’a pas été déplacée vers la Corbeille ou une autre installation utilise ces données. Données associées conservées.", "Die App wurde nicht in den Papierkorb verschoben oder eine andere Installation nutzt die Daten. Zugehörige Daten bleiben erhalten.", "La app no se movió a la Papelera u otra instalación usa los datos. Se conservaron los datos asociados.", "L’app non è stata spostata nel Cestino o un’altra installazione usa i dati. Dati associati conservati.", "O app não foi movido para o Lixo ou outra instalação usa os dados. Os dados associados foram preservados.")
        add(.appCacheGroupSubtitleFormat, "默认清理%@缓存及日志文件，展开查看具体可清理项", "預設清理%@快取及日誌檔案，展開檢視具體可清理項", "Clean %@ caches and logs by default; expand to view details", "デフォルトで%@のキャッシュとログを削除します。展開して詳細を表示", "기본적으로 %@ 캐시 및 로그 파일을 정리합니다. 펼쳐서 상세 항목 보기", "Nettoyer les caches et journaux de %@ par défaut ; développer pour voir les détails", "Caches und Protokolle von %@ standardmäßig bereinigen; für Details aufklappen", "Limpiar cachés y registros de %@ por defecto; expandir para ver detalles", "Pulisci cache e log di %@ per impostazione predefinita; espandi per i dettagli", "Limpar caches e logs de %@ por padrão; expanda para ver detalhes")
        add(.xcodeCacheGroupSubtitle, "默认清理Xcode缓存文件，展开查看具体可清理项", "預設清理Xcode快取檔案，展開檢視具體可清理項", "Clean Xcode cache files by default; expand to view details", "デフォルトでXcodeキャッシュファイルを削除します。展開して詳細を表示", "기본적으로 Xcode 캐시 파일을 정리합니다. 펼쳐서 상세 항목 보기", "Nettoyer les fichiers cache Xcode par défaut ; développer pour voir les détails", "Xcode-Cache-Dateien standardmäßig bereinigen; für Details aufklappen", "Limpiar archivos de caché de Xcode por defecto; expandir para ver detalles", "Pulisci i file di cache di Xcode per impostazione predefinita; espandi per i dettagli", "Limpar arquivos de cache do Xcode por padrão; expanda para ver detalhes")
        add(.xcodeDevJunkTitle, "Xcode 开发垃圾", "Xcode 開發垃圾", "Xcode Developer Junk", "Xcode 開発ジャンク", "Xcode 개발 정크", "Fichiers inutiles de développement Xcode", "Xcode-Entwicklerdatenmüll", "Basura de desarrollo de Xcode", "File inutili di sviluppo Xcode", "Lixo de desenvolvimento do Xcode")
        add(.subcatAppCacheFormat, "%@ app缓存", "%@ app快取", "%@ App Cache", "%@ アプリキャッシュ", "%@ 앱 캐시", "Cache d'application %@", "%@-App-Cache", "Caché de aplicación %@", "Cache app %@", "Cache do app %@")
        add(.subcatAppLogsFormat, "%@ 日志文件", "%@ 日誌檔案", "%@ Log Files", "%@ ログファイル", "%@ 로그 파일", "Fichiers journaux %@", "%@-Protokolldateien", "Archivos de registro de %@", "File di log %@", "Arquivos de log de %@")
        add(.subcatAppWebCacheFormat, "%@ 网页与离线缓存", "%@ 網頁與離線快取", "%@ Web & Offline Cache", "%@ Web・オフラインキャッシュ", "%@ 웹 및 오프라인 캐시", "Cache Web et hors ligne %@", "%@-Web- & Offline-Cache", "Caché web y sin conexión de %@", "Cache web e offline %@", "Cache web e offline de %@")
        add(.statusVeryClean, "很干净", "很乾淨", "Clean", "クリーン", "깨끗함", "Propre", "Sauber", "Limpio", "Pulito", "Limpo")
        add(.sizeRecommendCleanFormat, "共 %@，建议清理", "共 %@，建議清理", "Total %@, recommended", "合計 %@、削除推奨", "총 %@, 정리 권장", "Total %@, nettoyage recommandé", "Gesamt %@, Bereinigung empfohlen", "Total %@, limpieza recomendada", "Totale %@, pulizia consigliata", "Total %@, limpeza recomendada")
        add(.sizeCautionCleanFormat, "共 %@，谨慎清理", "共 %@，謹慎清理", "Total %@, clean with caution", "合計 %@、注意して削除", "총 %@, 신중히 정리", "Total %@, nettoyer avec précaution", "Gesamt %@, mit Vorsicht bereinigen", "Total %@, limpiar con precaución", "Totale %@, pulire con cautela", "Total %@, limpar com cautela")
        add(.sizeTotalFormat, "共 %@", "共 %@", "Total %@", "合計 %@", "총 %@", "Total %@", "Gesamt %@", "Total %@", "Totale %@", "Total %@")
        add(.xcodeSubAppCache, "Xcode app缓存", "Xcode app快取", "Xcode App Cache", "Xcode アプリキャッシュ", "Xcode 앱 캐시", "Cache d'application Xcode", "Xcode-App-Cache", "Caché de aplicación Xcode", "Cache app Xcode", "Cache do app Xcode")
        add(.xcodeSubDerivedData, "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData", "Xcode DerivedData")
        add(.xcodeSubIOSDeviceSupport, "iOS Device Support", "iOS Device Support", "iOS Device Support", "iOS Device Support", "iOS Device Support", "iOS Device Support", "iOS Device Support", "iOS Device Support", "iOS Device Support", "iOS Device Support")
        add(.xcodeSubMacOSDeviceSupport, "macOS Device Support", "macOS Device Support", "macOS Device Support", "macOS Device Support", "macOS Device Support", "macOS Device Support", "macOS Device Support", "macOS Device Support", "macOS Device Support", "macOS Device Support")
        add(.xcodeSubArchives, "Archives", "Archives", "Archives", "Archives", "Archives", "Archives", "Archives", "Archives", "Archives", "Archives")
        add(.xcodeSubDeviceLogs, "Device Logs", "Device Logs", "Device Logs", "Device Logs", "Device Logs", "Device Logs", "Device Logs", "Device Logs", "Device Logs", "Device Logs")
        add(.xcodeSubDocumentationCache, "DocumentationCache", "DocumentationCache", "DocumentationCache", "DocumentationCache", "DocumentationCache", "DocumentationCache", "DocumentationCache", "DocumentationCache", "DocumentationCache", "DocumentationCache")
        add(.xcodeSubSimulator, "Simulator", "Simulator", "Simulator", "Simulator", "Simulator", "Simulator", "Simulator", "Simulator", "Simulator", "Simulator")
        add(.xcodeSubSimulatorRuntimes, "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes", "Simulator Runtimes")
        add(.xcodeSubPreviews, "Previews", "Previews", "Previews", "Previews", "Previews", "Previews", "Previews", "Previews", "Previews", "Previews")
        add(.menuBarColorModeLabel, "状态栏配色", "狀態欄配色", "Menu Bar Color", "メニューバー配色", "메뉴 막대 색상", "Couleur de barre", "Menüleistenfarbe", "Color de barra", "Colore barra menu", "Cor da barra")
        add(.menuBarColorModeThemeAccent, "跟随主题色", "跟隨主題色", "Theme Accent", "テーマアクセント", "테마 강조색", "Accent du thème", "Themenakzent", "Acento del tema", "Accento tema", "Destaque do tema")
        add(.menuBarColorModeUtilization, "按负载变色", "按負載變色", "By Utilization", "負荷に応じて変化", "사용량별 색상", "Selon l'utilisation", "Nach Auslastung", "Por uso", "In base all'uso", "Por utilização")
        add(.menuBarColorModeMonochrome, "单色极简", "單色極簡", "Monochrome", "モノクロ", "모노크롬", "Monochrome", "Monochrom", "Monocromo", "Monocromatico", "Monocromático")
        add(.menuBarColorModeClassicMulti, "Stats 经典多色", "Stats 經典多色", "Stats Classic", "Stats クラシック", "Stats 클래식", "Stats Classique", "Stats Klassisch", "Stats Clásico", "Stats Classico", "Stats Clássico")
        add(.menuBarThemeQuickSwitchHelp, "切换菜单栏主题与着色风格", "切換選單列主題與著色風格", "Switch menu bar theme and color style", "メニューバーのテーマと配色を切り替え", "메뉴 막대 테마 및 색상 스타일 전환", "Changer le thème et le style de la barre", "Menüleistenthema und Farbstil wechseln", "Cambiar tema y estilo de color de la barra", "Cambia tema e stile colore della barra", "Alternar tema e estilo de cor da barra")
        add(.statsSectionUsageHistory, "历史趋势", "歷史趨勢", "USAGE HISTORY", "使用履歴", "사용 기록", "HISTORIQUE", "VERLAUF", "HISTORIAL", "CRONOLOGIA", "HISTÓRICO")
        add(.statsSectionDetails, "详细指标", "詳細指標", "DETAILS", "詳細情報", "상세 정보", "DÉTAILS", "DETAILS", "DETALLES", "DETTAGLI", "DETALHES")
        add(.statsSectionAverageLoad, "平均负载", "平均負載", "AVERAGE LOAD", "平均負荷", "평균 부하", "CHARGE MOYENNE", "DURCHSCHNITTSLAST", "CARGA MEDIA", "CARICO MEDIO", "CARGA MÉDIA")
        add(.statsSectionTopProcesses, "高占用进程", "高佔用程序", "TOP PROCESSES", "上位プロセス", "상위 프로세스", "PROCESSUS ACTIFS", "TOP-PROZESSE", "PROCESOS PRINCIPALES", "PROCESSI PRINCIPALI", "PRINCIPAIS PROCESSOS")
        add(.statsSectionPublicIP, "公网与连接", "公網與連線", "PUBLIC IP & LINK", "グローバルIPと接続", "공인 IP 및 연결", "IP PUBLIQUE & LIEN", "ÖFFENTLICHE IP", "IP PÚBLICA Y RED", "IP PUBBLICO E RETE", "IP PÚBLICO E REDE")
        add(.statsSectionPowerAndSensors, "电源与温感", "電源與溫感", "POWER & SENSORS", "電源とセンサー", "전원 및 센서", "ALIM. & CAPTEURS", "STROM & SENSOREN", "ENERGÍA Y SENSORES", "ENERGIA E SENSORI", "ENERGIA E SENSORES")
        add(.statsSectionDiskIO, "读写速率", "讀寫速率", "DISK I/O", "ディスク I/O", "디스크 I/O", "E/S DISQUE", "FESTPLATTEN-I/O", "E/S DE DISCO", "I/O DISCO", "E/S DE DISCO")
        add(.statsSelectPresetTitle, "选择预设", "選擇預設", "Select Preset", "プリセットを選択", "프리셋 선택", "Choisir un préréglage", "Voreinstellung wählen", "Seleccionar ajuste", "Seleziona preset", "Selecionar predefinição")
        add(.statsSelectPresetSubtitle, "选择一组初始模块。您稍后可以在下方自定义所有内容。", "選擇一組初始模組。您稍後可以在下方自訂所有內容。", "Select an initial set of modules. You can customize everything below.", "初期モジュールセットを選択してください。以下ですべてカスタマイズできます。", "초기 모듈 세트를 선택하세요. 아래에서 모든 항목을 사용자화할 수 있습니다.", "Sélectionnez un ensemble initial de modules. Vous pourrez tout personnaliser ci-dessous.", "Wählen Sie ein initiales Modul-Set. Sie können unten alles anpassen.", "Seleccione un conjunto inicial de módulos. Puede personalizar todo abajo.", "Seleziona un set iniziale di moduli. Puoi personalizzare tutto qui sotto.", "Selecione um conjunto inicial de módulos. Você pode personalizar tudo abaixo.")
        add(.statsPresetDefault, "默认", "預設", "Default", "デフォルト", "기본", "Par défaut", "Standard", "Predeterminado", "Predefinito", "Padrão")
        add(.statsPresetBasic, "基础", "基礎", "Basic", "ベーシック", "기본형", "Basique", "Basis", "Básico", "Base", "Básico")
        add(.statsPresetRecommended, "推荐", "推薦", "Recommended", "おすすめ", "추천", "Recommandé", "Empfohlen", "Recomendado", "Consigliato", "Recomendado")
        add(.statsPresetExtended, "扩展", "擴展", "Extended", "拡張", "확장", "Étendu", "Erweitert", "ampliado", "Esteso", "Estendido")
        add(.menuBarNoHighDiskAppsPrompt, "当前无高磁盘读写活动进程", "目前無高磁碟讀寫活動程序", "No active high disk I/O processes", "高ディスクI/Oプロセスなし", "높은 디스크 I/O 프로세스 없음", "Aucun processus à fort E/S disque", "Keine Prozesse mit hoher Festplatten-I/O", "Sin procesos de alto E/S de disco", "Nessun processo ad alto I/O disco", "Sem processos de alto E/S de disco")
        add(.weatherHourlyForecastSection, "24 小时趋势", "24 小時趨勢", "24-HOUR FORECAST", "24時間予報", "24시간 예보", "PRÉVISIONS 24H", "24-STUNDEN-TREND", "PRONÓSTICO 24H", "PREVISIONI 24H", "PREVISÃO 24H")
        add(.weatherDailyForecastSection, "7 日天气预报", "7 日天氣預報", "7-DAY FORECAST", "7日間予報", "7일 예보", "PRÉVISIONS 7 JOURS", "7-TAGE-TREND", "PRONÓSTICO 7 DÍAS", "PREVISIONI 7 GIORNI", "PREVISÃO 7 DIAS")
        add(.menuBarCalendarAndAgendaHeader, "日历与日程", "日曆與日程", "CALENDAR & AGENDA", "カレンダーと予定", "캘린더 및 일정", "CALENDRIER & AGENDA", "KALENDER & AGENDA", "CALENDARIO Y AGENDA", "CALENDARIO E AGENDA", "CALENDÁRIO E AGENDA")
        add(.menuBarTodayAgendaHeader, "今日日程", "今日日程", "TODAY'S AGENDA", "今日の予定", "오늘의 일정", "AGENDA DU JOUR", "HEUTIGE TERMINE", "AGENDA DE HOY", "IMPEGNI DI OGGI", "AGENDA DE HOJE")
        add(.menuBarAgendaEventsCountFormat, "%d 项安排", "%d 項安排", "%d events", "%d 件の予定", "%d개 일정", "%d événements", "%d Termine", "%d eventos", "%d eventi", "%d eventos")
        add(.menuBarWeekNumberFormat, "第 %d 周", "第 %d 週", "Week %d", "第 %d 週", "%d주차", "Semaine %d", "Woche %d", "Semana %d", "Settimana %d", "Semana %d")
        add(.menuBarAgendaSample1Title, "系统架构与主题样式评审", "系統架構與主題樣式評審", "Architecture & Theme Review", "設計とテーマのレビュー", "아키텍처 및 테마 리뷰", "Revue d'architecture et thème", "Architektur- & Themenprüfung", "Revisión de arquitectura y tema", "Revisione architettura e tema", "Revisão de arquitetura e tema")
        add(.menuBarAgendaSample2Title, "菜单栏遥测性能基准回归", "選單列遙測效能基準回歸", "MenuBar Telemetry Benchmark", "メニューバー性能ベンチマーク", "메뉴 막대 성능 벤치마크", "Benchmark télémétrie barre", "Menüleisten-Benchmark", "Benchmark de barra de menú", "Benchmark barra dei menu", "Benchmark da barra de menus")
        add(.menuBarAgendaSample3Title, "版本发布前安全门禁复核", "版本發佈前安全門禁複核", "Pre-release Safety Audit", "リリース前安全監査", "릴리스 전 보안 점검", "Audit sécurité pré-version", "Sicherheitsprüfung vor Release", "Auditoría de seguridad previa", "Audit sicurezza pre-rilascio", "Auditoria de segurança pré-lançamento")
        add(.menuBarAgendaTagActive, "进行中", "進行中", "Active", "進行中", "진행 중", "En cours", "Aktiv", "Activo", "In corso", "Ativo")
        add(.menuBarAgendaTagDev, "研发", "研發", "R&D", "開発", "개발", "R&D", "F&E", "I+D", "R&S", "P&D")
        add(.menuBarAgendaTagImportant, "重要", "重要", "Priority", "重要", "중요", "Priorité", "Wichtig", "Importante", "Importante", "Importante")
        add(.menuBarWeatherRealtimeHeader, "实时气象", "即時氣象", "LIVE WEATHER", "現在の天気", "실시간 날씨", "MÉTÉO EN DIRECT", "LIVE-WETTER", "CLIMA EN VIVO", "METEO LIVE", "CLIMA AO VIVO")
        add(.menuBarWeatherUpdatedJustNow, "更新于 刚刚", "更新於 剛剛", "Updated just now", "たった今更新", "방금 업데이트됨", "Mis à jour à l'instant", "Gerade aktualisiert", "Actualizado ahora", "Aggiornato ora", "Atualizado agora")
        add(.menuBarWeatherFeelsLikeFormat, "体感 %.0f°", "體感 %.0f°", "Feels %.0f°", "体感 %.0f°", "체감 %.0f°", "Ressenti %.0f°", "Gefühlt %.0f°", "Sensación %.0f°", "Percepita %.0f°", "Sensação %.0f°")
        add(.menuBarWeatherHighLowFormat, "最高 %.0f°  最低 %.0f°", "最高 %.0f°  最低 %.0f°", "H: %.0f°  L: %.0f°", "最高 %.0f°  最低 %.0f°", "최고 %.0f°  최저 %.0f°", "Max %.0f°  Min %.0f°", "H: %.0f°  T: %.0f°", "Máx %.0f°  Mín %.0f°", "Max %.0f°  Min %.0f°", "Máx %.0f°  Mín %.0f°")
        add(.menuBarWeatherAqiGoodFormat, "优 AQI %d", "優 AQI %d", "Good AQI %d", "良好 AQI %d", "좋음 AQI %d", "Bon IQA %d", "Gut AQI %d", "Bueno ICA %d", "Buono IQA %d", "Bom IQA %d")
        add(.menuBarWeatherHumidityLabel, "相对湿度", "相對濕度", "Humidity", "湿度", "습도", "Humidité", "Luftfeuchte", "Humedad", "Umidità", "Umidade")
        add(.menuBarWeatherWindLabel, "风速", "風速", "Wind", "風速", "풍속", "Vent", "Wind", "Viento", "Vento", "Vento")
        add(.menuBarWeatherUvLabel, "紫外线", "紫外線", "UV Index", "UV指数", "자외선", "Indice UV", "UV-Index", "Índice UV", "Indice UV", "Índice UV")
        add(.menuBarWeatherVisibilityLabel, "能见度", "能見度", "Visibility", "視程", "가시거리", "Visibilité", "Sichtweite", "Visibilidad", "Visibilità", "Visibilidade")
        add(.menuBarWeatherNowLabel, "现在", "現在", "Now", "現在", "지금", "Maint.", "Jetzt", "Ahora", "Ora", "Agora")
        add(.menuBarSensorsHeader, "SENSORS", "SENSORS", "SENSORS", "SENSORS", "SENSORS", "SENSORS", "SENSORS", "SENSORS", "SENSORS", "SENSORS")
        add(.menuBarFansLabel, "Fans", "Fans", "Fans", "ファン", "팬", "Ventilateurs", "Lüfter", "Ventiladores", "Ventole", "Ventoinhas")
        add(.menuBarSystemControlledLabel, "System Controlled", "System Controlled", "System Controlled", "システム制御", "시스템 제어", "Contrôlé par le système", "Systemgesteuert", "Controlado por el sistema", "Controllato dal sistema", "Controlado pelo sistema")
        add(.menuBarSensorCpuCoreShort, "CPU Core", "CPU Core", "CPU Core", "CPUコア", "CPU 코어", "Cœur CPU", "CPU-Kern", "Núcleo CPU", "Core CPU", "Núcleo CPU")
        add(.menuBarSensorPalmRestShort, "Palm Rest", "Palm Rest", "Palm Rest", "パームレスト", "팜레스트", "Repose-poignets", "Handballenauflage", "Reposamanos", "Poggiapolsi", "Apoio de mãos")
        add(.menuBarSensorLrFansShort, "L/R Fans", "L/R Fans", "L/R Fans", "L/Rファン", "좌/우 팬", "Ventil. G/D", "L/R Lüfter", "Vent. I/D", "Ventole S/D", "Vent. E/D")
        add(.menuBarBatteryPowerSourceLabel, "供电来源", "供電來源", "Power Source", "電源", "전원 공급", "Source d'alim.", "Stromquelle", "Fuente de energía", "Alimentazione", "Fonte de energia")
        add(.menuBarMemoryHistoryHeader, "MEMORY", "MEMORY", "MEMORY", "MEMORY", "MEMORY", "MEMORY", "MEMORY", "MEMORY", "MEMORY", "MEMORY")
        add(.menuBarCalendarPrevMonthHelp, "上个月", "上個月", "Previous Month", "前月", "이전 달", "Mois précédent", "Vorheriger Monat", "Mes anterior", "Mese precedente", "Mês anterior")
        add(.menuBarCalendarTodayHelp, "回到今天", "回到今天", "Back to Today", "今日へ戻る", "오늘로 이동", "Aujourd'hui", "Heute", "Volver a hoy", "Torna a oggi", "Voltar para hoje")
        add(.menuBarCalendarNextMonthHelp, "下个月", "下個月", "Next Month", "翌月", "다음 달", "Mois suivant", "Nächster Monat", "Mes siguiente", "Mese successivo", "Próximo mês")
        add(.menuBarCalendarWeekendBadge, "休息日", "休息日", "Weekend", "休日", "휴일", "Week-end", "Ruhetag", "Descanso", "Riposo", "Descanso")
        add(.menuBarCalendarWorkdayBadge, "工作日", "工作日", "Workday", "平日", "평일", "Jour ouvré", "Werktag", "Laborable", "Feriale", "Dia útil")
        add(.menuBarCalendarNoEventsPrompt, "当日无系统日历日程", "當日無系統日曆日程", "No calendar events on this day", "この日の予定はありません", "이 날의 일정이 없습니다", "Aucun événement ce jour", "Keine Termine an diesem Tag", "Sin eventos este día", "Nessun evento in questo giorno", "Sem eventos neste dia")
        add(.menuBarMoonPhaseNew, "新月", "新月", "New Moon", "新月", "삭(신월)", "Nouvelle lune", "Neumond", "Luna nueva", "Luna nuova", "Lua nova")
        add(.menuBarMoonPhaseWaxingCrescent, "蛾眉月", "蛾眉月", "Waxing Crescent", "三日月", "초승달", "Premier croissant", "Zunehmende Sichel", "Luna creciente", "Luna crescente", "Lua crescente")
        add(.menuBarMoonPhaseFirstQuarter, "上弦月", "上弦月", "First Quarter", "上弦の月", "상현달", "Premier quartier", "Erstes Viertel", "Cuarto creciente", "Primo quarto", "Quarto crescente")
        add(.menuBarMoonPhaseWaxingGibbous, "盈凸月", "盈凸月", "Waxing Gibbous", "十三夜月", "차오르는 달", "Lune gibbeuse croissante", "Zunehmender Mond", "Gibosa creciente", "Gibbosa crescente", "Gibosa crescente")
        add(.menuBarMoonPhaseFull, "满月", "滿月", "Full Moon", "満月", "보름달", "Pleine lune", "Vollmond", "Luna llena", "Luna piena", "Lua cheia")
        add(.menuBarMoonPhaseWaningGibbous, "亏凸月", "虧凸月", "Waning Gibbous", "寝待月", "이지러지는 달", "Lune gibbeuse décroissante", "Abnehmender Mond", "Gibosa menguante", "Gibbosa calante", "Gibosa minguante")
        add(.menuBarMoonPhaseLastQuarter, "下弦月", "下弦月", "Last Quarter", "下弦の月", "하현달", "Dernier quartier", "Letztes Viertel", "Cuarto menguante", "Ultimo quarto", "Quarto minguante")
        add(.menuBarMoonPhaseWaningCrescent, "残月", "殘月", "Waning Crescent", "有明月", "그믐달", "Dernier croissant", "Abnehmende Sichel", "Luna menguante", "Luna calante", "Lua minguante")
        add(.menuBarMoonIlluminationFormat, "照明度 %d%%", "照明度 %d%%", "%d%% Illumination", "輝面比 %d%%", "조명도 %d%%", "Illumination %d%%", "Beleuchtung %d%%", "Iluminación %d%%", "Illuminazione %d%%", "Iluminação %d%%")
        add(.menuBarWeatherUvLow, "低", "低", "Low", "弱い", "낮음", "Faible", "Niedrig", "Bajo", "Basso", "Baixo")
        add(.menuBarWeatherUvModerate, "中等", "中等", "Moderate", "中程度", "보통", "Modéré", "Mittel", "Moderado", "Moderato", "Moderado")
        add(.menuBarWeatherUvHigh, "高", "高", "High", "強い", "높음", "Élevé", "Hoch", "Alto", "Alto", "Alto")
        add(.menuBarWeatherUvVeryHigh, "极高", "極高", "Very High", "非常に強い", "매우 높음", "Très élevé", "Sehr hoch", "Muy alto", "Molto alto", "Muito alto")
        add(.menuBarNetworkTotalTrafficLabel, "累计流量", "累計流量", "Total Traffic", "累計通信量", "누적 트래픽", "Trafic total", "Gesamtverkehr", "Tráfico total", "Traffico totale", "Tráfego total")
        add(.menuBarNetworkGatewayLabel, "默认网关", "預設閘道", "Gateway", "ゲートウェイ", "게이트웨이", "Passerelle", "Gateway", "Puerta de enlace", "Gateway", "Gateway")
        add(.menuBarNetworkCopyIpHelp, "点击复制 IP 地址", "點擊複製 IP 位址", "Click to copy IP address", "クリックしてIPをコピー", "클릭하여 IP 주소 복사", "Cliquer pour copier l'IP", "Klicken zum Kopieren der IP", "Clic para copiar IP", "Clicca per copiare l'IP", "Clique para copiar o IP")
        add(.menuBarNetworkToggleMaskHelp, "隐藏/显示公网 IP", "隱藏/顯示公網 IP", "Hide/Show public IP", "グローバルIPの表示切替", "공인 IP 숨기기/표시", "Masquer/Afficher l'IP", "Öffentliche IP ein-/ausblenden", "Ocultar/Mostrar IP pública", "Mostra/Nascondi IP pubblico", "Ocultar/Mostrar IP público")

        // 首次安装引导与快捷授权 (Onboarding & Quick Auth)
        add(.appBrandName, "ACleaner", "ACleaner", "ACleaner", "ACleaner", "ACleaner", "ACleaner", "ACleaner", "ACleaner", "ACleaner", "ACleaner")
        add(.onboardingWelcomeTitle, "欢迎使用 ACleaner", "歡迎使用 ACleaner", "Welcome to ACleaner", "ACleaner へようこそ", "ACleaner에 오신 것을 환영합니다", "Bienvenue sur ACleaner", "Willkommen bei ACleaner", "Bienvenido a ACleaner", "Benvenuto in ACleaner", "Bem-vindo ao ACleaner")
        add(.onboardingWelcomeSubtitle, "专为 macOS 打造的深度清理、卸载与空间透视管家。", "專為 macOS 打造的深度清理、解除安裝與空間透視管家。", "Deep cleaning, thorough app uninstalling, and disk space insights built for macOS.", "macOS向けのディープクリーン、完全アンインストール、空間分析ツール。", "macOS를 위한 정밀 정리, 완벽한 앱 제거 및 공간 분석 도구입니다.", "Nettoyage profond, désinstallation complète et analyse d'espace pour macOS.", "Tiefenreinigung, vollständige Deinstallation und Speicheranalyse für macOS.", "Limpieza profunda, desinstalación completa y análisis de espacio para macOS.", "Pulizia profonda, disinstallazione completa e analisi dello spazio per macOS.", "Limpeza profunda, desinstalação completa e análise de espaço para macOS.")
        add(.onboardingSafetyContractBadge, "安全可逆承诺 · 默认移入废纸篓 · 零隐私越权", "安全可逆承諾 · 預設移入垃圾桶 · 零隱私越權", "Reversible by default · Moves to Trash · Privacy-first", "安全・復元可能 · デフォルトでゴミ箱へ移動 · プライバシー重視", "안전한 복원 보장 · 기본 휴지통 이동 · 개인정보 보호 우선", "Réversible par défaut · Déplacement vers la Corbeille · Respect de la vie privée", "Standardmäßig umkehrbar · In den Papierkorb · Datenschutz zuerst", "Reversible por defecto · Mueve a la Papelera · Privacidad primero", "Reversibile di default · Sposta nel Cestino · Privacy al primo posto", "Reversível por padrão · Move para o Lixo · Privacidade em primeiro lugar")
        add(.onboardingFeatureSmartCleanTitle, "智能深度清理", "智慧深度清理", "Smart Deep Clean", "スマートディープクリーン", "스마트 정밀 정리", "Nettoyage intelligent", "Intelligente Tiefenreinigung", "Limpieza inteligente", "Pulizia intelligente", "Limpeza inteligente")
        add(.onboardingFeatureSmartCleanDesc, "精准扫描系统缓存、开发构建残留与冗余日志，释放宝贵磁盘空间。", "精準掃描系統快取、開發建置殘留與冗餘日誌，釋放寶貴磁碟空間。", "Scan system caches, developer build artifacts, and logs to reclaim disk space.", "システムキャッシュ、開発ビルド残骸、ログをスキャンして空き容量を確保します。", "시스템 캐시, 개발 빌드 잔여물 및 로그를 스캔하여 디스크 공간을 확보합니다.", "Analysez les caches système, résidus de build et journaux pour libérer de l'espace.", "Systemcaches, Build-Artefakte und Protokolle scannen, um Speicherplatz freizugeben.", "Escanea cachés del sistema, residuos de compilación y registros para liberar espacio.", "Scansiona cache di sistema, artefatti di build e log per liberare spazio su disco.", "Analise caches do sistema, resíduos de compilação e logs para liberar espaço.")
        add(.onboardingFeatureUninstallerTitle, "彻底卸载无残留", "徹底解除安裝無殘留", "Complete App Uninstaller", "完全アプリアンインストーラー", "완벽한 앱 제거기", "Désinstallateur complet", "Vollständiger Deinstallierer", "Desinstalador completo", "Disinstallatore completo", "Desinstalador completo")
        add(.onboardingFeatureUninstallerDesc, "一键揪出应用散落在容器与支持目录中的所有孤儿残留文件。", "一鍵揪出應用程式散落在容器與支援目錄中的所有孤兒殘留檔案。", "Find and remove every leftover container, cache, and preference file an app leaves behind.", "アプリが残したコンテナ、キャッシュ、設定ファイルをすべて検出して削除します。", "앱이 남긴 컨테이너, 캐시 및 환경설정 잔여 파일을 모두 찾아 제거합니다.", "Trouvez et supprimez tous les conteneurs, caches et préférences laissés par une app.", "Alle verbleibenden Container, Caches und Einstellungen einer App finden und entfernen.", "Encuentra y elimina todos los contenedores, cachés y preferencias que deja una app.", "Trova e rimuovi tutti i container, cache e preferenze lasciati dalle app.", "Encontre e remova todos os contêineres, caches e preferências deixados por um app.")
        add(.onboardingFeatureSpaceLensTitle, "空间透视与大文件整理", "空間透視與大檔案整理", "Space Lens & Declutter", "スペースレンズ＆整理", "공간 렌즈 및 파일 정리", "Aperçu de l'espace", "Speicherlinse & Aufräumen", "Lente espacial y orden", "Lente spazio e riordino", "Lente de espaço e organização")
        add(.onboardingFeatureSpaceLensDesc, "交互式全景磁盘映射，直观定位深层大文件与下载杂乱项。", "互動式全景磁碟映射，直觀定位深層大檔案與下載雜亂項。", "Interactive disk map to visually pinpoint deep large files and clutter.", "インタラクティブなディスクマップで大容量ファイルや不要データを可視化します。", "대화형 디스크 맵으로 깊숙한 대용량 파일과 복잡한 항목을 한눈에 파악합니다.", "Carte interactive du disque pour localiser visuellement les gros fichiers.", "Interaktive Festplattenkarte zum schnellen Auffinden großer Dateien.", "Mapa interactivo del disco para localizar archivos grandes y desorden.", "Mappa interattiva del disco per individuare file grandi e disordine.", "Mapa interativo do disco para localizar arquivos grandes e bagunça.")
        add(.onboardingPermissionStepTitle, "一步授权，解锁完整清理能力", "一步授權，解鎖完整清理能力", "One Permission for Full Cleaning Power", "1つの権限で完全なクリーン機能を解放", "단 하나의 권한으로 모든 정리 기능 잠금 해제", "Une seule autorisation pour un nettoyage complet", "Eine Berechtigung für volle Reinigungsleistung", "Un permiso para desbloquear toda la potencia", "Un solo permesso per la pulizia completa", "Uma permissão para desbloquear todo o poder")
        add(.onboardingPermissionGrantedTitle, "完全磁盘访问权限已就绪", "完全磁碟取用權限已就緒", "Full Disk Access Granted", "フルディスクアクセス許可済み", "전체 디스크 접근 권한 허용됨", "Accès complet au disque accordé", "Festplattenvollzugriff gewährt", "Acceso total al disco concedido", "Accesso completo al disco concesso", "Acesso total ao disco concedido")
        add(.onboardingPermissionStepSubtitle, "macOS 默认隔离受保护的应用缓存与容器。开启「完全磁盘访问权限」即可一次授权，无需反复处理零散文件夹弹窗。", "macOS 預設隔離受保護的應用快取與容器。開啟「完全磁碟取用權限」即可一次授權，無需反覆處理零散資料夾彈窗。", "macOS hides protected app caches and containers by default. Grant Full Disk Access once instead of dealing with repeated folder prompts.", "macOSは保護されたキャッシュやコンテナを既定で隠します。フルディスクアクセスを一度許可すれば、個別のフォルダ確認は不要になります。", "macOS는 기본적으로 보호된 앱 캐시와 컨테이너를 숨깁니다. 반복되는 폴더 알림 대신 전체 디스크 접근 권한을 한 번만 허용하세요.", "macOS masque certains caches par défaut. Accordez l'accès complet au disque une seule fois pour éviter les invites répétées.", "macOS blendet geschützte Caches standardmäßig aus. Gewähren Sie einmalig Festplattenvollzugriff statt vieler einzelner Ordnerabfragen.", "macOS oculta cachés protegidas por defecto. Concede acceso total al disco una sola vez para evitar múltiples avisos.", "macOS nasconde le cache protette. Concedi l'accesso completo al disco una volta sola invece di rispondere a singoli avvisi.", "O macOS oculta caches protegidos por padrão. Conceda Acesso Total ao Disco uma única vez para evitar vários alertas.")
        add(.onboardingPermissionGrantedSubtitle, "ACleaner 现已能够安全扫描所有受保护缓存与卸载残留目录。", "ACleaner 現已能夠安全掃描所有受保護快取與解除安裝殘留目錄。", "ACleaner can now safely scan all protected caches and leftover app containers.", "ACleanerはすべての保護されたキャッシュと残存コンテナを安全にスキャンできます。", "이제 ACleaner가 모든 보호된 캐시 및 잔여 컨테이너를 안전하게 스캔할 수 있습니다.", "ACleaner peut désormais analyser tous les caches protégés et résidus d'applications.", "ACleaner kann nun alle geschützten Caches und App-Reste sicher scannen.", "ACleaner ahora puede escanear todas las cachés protegidas y contenedores restantes.", "ACleaner può ora scansionare in sicurezza tutte le cache protette e i residui.", "O ACleaner agora pode analisar com segurança todos os caches protegidos e resíduos.")
        add(.onboardingDragAppToListHint, "拖拽至设置列表", "拖拽至設定列表", "Drag into Settings list", "設定リストへドラッグ", "설정 목록으로 드래그", "Glisser dans la liste", "In die Liste ziehen", "Arrastrar a la lista", "Trascina nella lista", "Arraste para a lista")
        add(.onboardingDragIconTooltip, "按住此图标并直接拖入「系统设置 → 完全磁盘访问权限」列表中即可快速添加", "按住此圖示並直接拖入「系統設定 → 完全磁碟取用權限」列表中即可快速加入", "Drag this icon directly into the Full Disk Access list in System Settings", "このアイコンをシステム設定の「フルディスクアクセス」リストに直接ドラッグします", "이 아이콘을 시스템 설정의 '전체 디스크 접근 권한' 목록으로 직접 드래그하세요", "Faites glisser cette icône directement dans la liste Accès complet au disque", "Ziehen Sie dieses Symbol direkt in die Liste „Festplattenvollzugriff“", "Arrastra este icono directamente a la lista de Acceso total al disco", "Trascina questa icona direttamente nell'elenco Accesso completo al disco", "Arraste este ícone diretamente para a lista de Acesso Total ao Disco")
        add(.onboardingDemoPathHint, "系统设置 → 隐私与安全性 → 完全磁盘访问权限", "系統設定 → 隱私權與安全性 → 完全磁碟取用權限", "System Settings → Privacy & Security → Full Disk Access", "システム設定 → プライバシーとセキュリティ → フルディスクアクセス", "시스템 설정 → 개인정보 보호 및 보안 → 전체 디스크 접근 권한", "Réglages Système → Confidentialité et sécurité → Accès complet au disque", "Systemeinstellungen → Datenschutz & Sicherheit → Festplattenvollzugriff", "Ajustes del Sistema → Privacidad y seguridad → Acceso total al disco", "Impostazioni di Sistema → Privacy e sicurezza → Accesso completo al disco", "Ajustes do Sistema → Privacidade e Segurança → Acesso Total ao Disco")
        add(.onboardingAutoAdvancingPrompt, "已检测到权限生效，正在自动进入下一步…", "已偵測到權限生效，正在自動進入下一步…", "Permission detected — advancing to the next step…", "権限を確認しました。次のステップへ進みます…", "권한이 감지되었습니다. 다음 단계로 자동 이동합니다…", "Autorisation détectée — passage à l'étape suivante…", "Berechtigung erkannt — weiter zum nächsten Schritt…", "Permiso detectado — avanzando al siguiente paso…", "Permesso rilevato — passaggio alla fase successiva…", "Permissão detectada — avançando para a próxima etapa…")
        add(.onboardingReopenSettingsAction, "重新打开系统设置与访达", "重新打開系統設定與 Finder", "Reopen System Settings & Finder", "システム設定とFinderを再度開く", "시스템 설정 및 Finder 다시 열기", "Rouvrir Réglages Système et le Finder", "Systemeinstellungen & Finder erneut öffnen", "Reabrir Ajustes del Sistema y Finder", "Riapri Impostazioni di Sistema e Finder", "Reabrir Ajustes do Sistema e Finder")
        add(.onboardingReadyTitleGranted, "一切就绪，准备出发", "一切就緒，準備出發", "You're All Set", "準備が整いました", "모든 준비가 완료되었습니다", "Tout est prêt", "Alles bereit", "Todo listo", "Tutto pronto", "Tudo pronto")
        add(.onboardingReadyTitleLimited, "准备就绪（基础模式）", "準備就緒（基礎模式）", "Ready When You Are", "準備完了（基本モード）", "준비 완료 (기본 모드)", "Prêt à commencer", "Bereit zum Start", "Listo para empezar", "Pronto per iniziare", "Pronto para começar")
        add(.onboardingReadyDescGranted, "已获得完全磁盘访问权限。立即启动首次智能扫描，全面体检您的 Mac 磁盘空间。", "已獲得完全磁碟取用權限。立即啟動首次智慧掃描，全面體檢您的 Mac 磁碟空間。", "Full Disk Access is active. Run your first Smart Scan now to reclaim space across your Mac.", "フルディスクアクセスが有効です。最初のスマートスキャンを実行してMacの空き容量を増やしましょう。", "전체 디스크 접근 권한이 활성화되었습니다. 지금 첫 스마트 스캔을 시작해 보세요.", "L'accès complet au disque est actif. Lancez votre première analyse intelligente.", "Festplattenvollzugriff ist aktiv. Starten Sie jetzt Ihren ersten intelligenten Scan.", "El acceso total al disco está activo. Inicia tu primer análisis inteligente ahora.", "L'accesso completo al disco è attivo. Avvia subito la tua prima scansione intelligente.", "O Acesso Total ao Disco está ativo. Inicie sua primeira análise inteligente agora.")
        add(.onboardingReadyDescLimited, "未授予完全磁盘访问权限时，部分受保护缓存将跳过扫描。您随时可在左侧边栏或偏好设置中一键开启。", "未授予完全磁碟取用權限時，部分受保護快取將略過掃描。您隨時可在左側邊欄或偏好設定中一鍵開啟。", "Without Full Disk Access, protected caches will be skipped. You can grant it anytime from the sidebar or Settings.", "フルディスクアクセスがない場合、一部の保護されたキャッシュはスキップされます。サイドバーや設定からいつでも許可できます。", "전체 디스크 접근 권한이 없으면 일부 보호된 캐시는 건너뜁니다. 사이드바나 설정에서 언제든 허용할 수 있습니다.", "Sans accès complet au disque, certains caches protégés seront ignorés. Vous pourrez l'activer plus tard.", "Ohne Festplattenvollzugriff werden geschützte Caches übersprungen. Sie können ihn jederzeit in der Seitenleiste aktivieren.", "Sin acceso total al disco, algunas cachés protegidas se omitirán. Puedes activarlo en cualquier momento.", "Senza accesso completo al disco, alcune cache protette verranno saltate. Puoi attivarlo in qualsiasi momento.", "Sem Acesso Total ao Disco, alguns caches protegidos serão ignorados. Você pode ativá-lo a qualquer momento.")
        add(.onboardingMenuBarQuickToggleTitle, "在顶部菜单栏显示实时状态监控", "在頂部選單列顯示即時狀態監控", "Show Live Status Monitor in Menu Bar", "メニューバーにリアルタイム監視を表示", "메뉴 막대에 실시간 상태 모니터 표시", "Afficher le moniteur dans la barre des menus", "Live-Statusmonitor in der Menüleiste anzeigen", "Mostrar monitor en vivo en la barra de menús", "Mostra monitor di stato nella barra dei menu", "Mostrar monitor ao vivo na barra de menus")
        add(.onboardingMenuBarQuickToggleDesc, "随时查看 CPU、内存、网速、电池健康并支持一键释放内存", "隨時查看 CPU、記憶體、網速、電池健康並支援一鍵釋放記憶體", "Quickly view CPU, memory, network speed, battery health, and free up RAM with one click", "CPU、メモリ、通信速度、バッテリー状態を確認し、ワンクリックでメモリを解放", "CPU, 메모리, 네트워크 속도, 배터리 상태를 확인하고 원클릭으로 메모리를 확보하세요", "Consultez CPU, mémoire, réseau, batterie et libérez de la RAM en un clic", "CPU, Speicher, Netzwerk und Akku im Blick behalten und RAM mit einem Klick freigeben", "Consulta CPU, memoria, red, batería y libera RAM con un clic", "Controlla CPU, memoria, rete, batteria e libera RAM con un clic", "Veja CPU, memória, rede, bateria e libere RAM com um clique")
        add(.onboardingActionNext, "下一步", "下一步", "Next", "次へ", "다음", "Suivant", "Weiter", "Siguiente", "Avanti", "Avançar")
        add(.onboardingActionBack, "上一步", "上一步", "Back", "戻る", "이전", "Retour", "Zurück", "Atrás", "Indietro", "Voltar")
        add(.onboardingActionStartFirstScan, "开始首次智能扫描", "開始首次智慧掃描", "Start First Smart Scan", "最初のスマートスキャンを開始", "첫 스마트 스캔 시작", "Lancer la première analyse", "Ersten intelligenten Scan starten", "Iniciar primer escaneo inteligente", "Avvia la prima scansione", "Iniciar primeira análise")
        add(.onboardingActionReopenGuide, "重新打开新手引导与授权向导", "重新打開新手引導與授權精靈", "Reopen Welcome & Permission Guide", "セットアップと権限ガイドを再度開く", "초기 안내 및 권한 마법사 다시 열기", "Rouvrir le guide de bienvenue et d'autorisation", "Willkommens- & Berechtigungsassistent erneut öffnen", "Reabrir guía de bienvenida y permisos", "Riapri guida di benvenuto e permessi", "Reabrir guia de boas-vindas e permissões")
        add(.onboardingSectionTitle, "安装引导与快速设置", "安裝引導與快速設定", "Welcome Guide & Quick Setup", "セットアップガイド", "설치 안내 및 빠른 설정", "Guide de bienvenue", "Einrichtungsassistent", "Guía de inicio rápido", "Guida di benvenuto", "Guia de configuração rápida")
        add(.onboardingSectionDesc, "随时重新进入首次安装向导，查看拖拽式授权演示与功能指引。", "隨時重新進入首次安裝精靈，查看拖拽式授權演示與功能指引。", "Revisit the initial onboarding wizard anytime for interactive permission setup and feature overview.", "インタラクティブな権限設定デモや機能ガイドをいつでも再確認できます。", "언제든지 초기 설정 마법사를 다시 열어 대화형 권한 설정 및 기능 안내를 확인하세요.", "Rouvrez l'assistant d'installation à tout moment pour configurer vos autorisations.", "Öffnen Sie den Einrichtungsassistenten jederzeit erneut für die interaktive Berechtigungseinrichtung.", "Vuelve a abrir el asistente inicial en cualquier momento para configurar permisos.", "Riapri la procedura guidata iniziale in qualsiasi momento per configurare i permessi.", "Reabra o assistente inicial a qualquer momento para configurar permissões.")
        add(.sidebarQuickGrantFdaTitle, "完全磁盘权限未开启", "完全磁碟權限未開啟", "Full Disk Access Off", "フルディスクアクセス未許可", "전체 디스크 권한 꺼짐", "Accès disque désactivé", "Vollzugriff deaktiviert", "Acceso a disco desactivado", "Accesso disco disattivato", "Acesso ao disco desativado")
        add(.sidebarQuickGrantFdaSubtitle, "点击一键授权解锁深度扫描", "點擊一鍵授權解鎖深度掃描", "Click to grant for deep scan", "クリックしてディープスキャンを解放", "클릭하여 정밀 스캔 권한 허용", "Cliquer pour autoriser l'analyse", "Für Tiefenscan hier aktivieren", "Clic para autorizar escaneo", "Clicca per autorizzare la scansione", "Clique para autorizar análise")
        add(.actionDirectOpenFdaSettings, "直达系统设置", "直達系統設定", "System Settings", "システム設定へ", "시스템 설정 열기", "Réglages Système", "Systemeinstellungen", "Ajustes del Sistema", "Impostazioni", "Ajustes do Sistema")
        add(.fanControlPrivilegeRequiredPrompt, "调节风扇转速需要管理员权限。请在弹出窗口中授权，或在设置中启用特权维护助手。", "調節風扇轉速需要管理員權限。請在彈出視窗中授權，或在設定中啟用特權維護助手。", "Adjusting fan speed requires administrator privileges. Please authorize in the prompt or enable the helper in Settings.", "ファンの速度を調整するには管理者権限が必要です。プロンプトで承認するか、設定でヘルパーを有効にしてください。", "팬 속도를 조절하려면 관리자 권한이 필요합니다. 프롬프트에서 승인하거나 설정에서 도우미를 활성화하세요.", "Le réglage de la vitesse du ventilateur nécessite des privilèges d'administrateur. Veuillez autoriser dans l'invite ou activer l'assistant dans Réglages.", "Das Anpassen der Lüftergeschwindigkeit erfordert Administratorrechte. Bitte autorisieren Sie in der Eingabeaufforderung oder aktivieren Sie den Helfer in den Einstellungen.", "Ajustar la velocidad del ventilador requiere privilegios de administrador. Autorice en el aviso o active el asistente en Ajustes.", "La regolazione della velocità delle ventole richiede privilegi di amministratore. Autorizza nella richiesta o abilita l'assistente in Impostazioni.", "O ajuste da velocidade da ventoinha requer privilégios de administrador. Autorize no aviso ou ative o assistente em Ajustes.")
        add(.fanControlAuthFailedOrCancelled, "风扇调节未授权或已取消。若需持续控制，可在设置中安装特权助手。", "風扇調節未授權或已取消。若需持續控制，可在設定中安裝特權助手。", "Fan control was not authorized or was canceled. For continuous control, enable the helper in Settings.", "ファン制御が承認されなかったか、キャンセルされました。継続的な制御には設定でヘルパーを有効にしてください。", "팬 제어가 승인되지 않았거나 취소되었습니다. 지속적인 제어를 위해 설정에서 도우미를 활성화하세요.", "Le contrôle du ventilateur n'a pas été autorisé ou a été annulé. Pour un contrôle continu, activez l'assistant dans Réglages.", "Lüftersteuerung wurde nicht autorisiert oder abgebrochen. Für dauerhafte Steuerung aktivieren Sie den Helfer in den Einstellungen.", "El control del ventilador no fue autorizado o se canceló. Para un control continuo, active el asistente en Ajustes.", "Il controllo delle ventole non è stato autorizzato o è stato annullato. Per un controllo continuo, abilita l'assistente in Impostazioni.", "O controle da ventoinha não foi autorizado ou foi cancelado. Para controle contínuo, ative o assistente em Ajustes.")
        add(.fanControlAppliedToast, "风扇转速模式已成功更新", "風扇轉速模式已成功更新", "Fan speed mode updated successfully", "ファンスピードモードが正常に更新されました", "팬 속도 모드가 성공적으로 업데이트되었습니다", "Mode de vitesse du ventilateur mis à jour avec succès", "Lüftermodus erfolgreich aktualisiert", "Modo de velocidad del ventilador actualizado con éxito", "Modalità di velocità delle ventole aggiornata con successo", "Modo de velocidade da ventoinha atualizado com sucesso")
        add(.fanModeDisabledPassive, "当前设备采用被动散热（无内置物理风扇）", "當前設備採用被動散熱（無內建實體風扇）", "This device uses passive cooling (no physical fans)", "このデバイスはパッシブ冷却を使用しています（物理ファンなし）", "이 기기는 패시브 쿨링을 사용합니다 (물리 팬 없음)", "Cet appareil utilise un refroidissement passif (sans ventilateur)", "Dieses Gerät verwendet passive Kühlung (keine Lüfter)", "Este dispositivo usa refrigeración pasiva (sin ventiladores)", "Questo dispositivo usa il raffreddamento passivo (nessuna ventola)", "Este dispositivo usa resfriamento passivo (sem ventoinhas)")
        add(.networkTunnelBadge, "VPN", "VPN", "VPN", "VPN", "VPN", "VPN", "VPN", "VPN", "VPN", "VPN")

        // 系统健康度五维评估 (首屏) & 内存极速释放
        add(.moduleHealthCheck, "健康度检查", "健康度檢查", "Health Check", "ヘルスチェック", "건강 상태 점검", "Bilan de santé", "Zustandsprüfung", "Chequeo de salud", "Stato di salute", "Verificação de saúde")
        add(.moduleHealthCheckSubtitle, "全景五维系统健康评估与即时深度调优", "全景五維系統健康評估與即時深度調優", "5-axis panoramic system health check and instant tuning", "5軸パノラマシステムヘルスチェックと最適化", "5개 영역 파노라마 시스템 건강 진단 및 즉각적인 최적화", "Évaluation de santé système à 5 dimensions et optimisation", "5-Achsen-Systemzustandsprüfung und sofortige Optimierung", "Evaluación de salud del sistema en 5 ejes y optimización", "Valutazione a 5 assi dello stato del sistema e ottimizzazione", "Avaliação do sistema em 5 eixos e otimização instantânea")
        add(.systemHealthRadarTitle, "系统健康度五维评估 (Radar)", "系統健康度五維評估 (Radar)", "System Health 5-Axis Assessment (Radar)", "システム健康度5軸評価 (Radar)", "시스템 건강도 5차원 평가 (Radar)", "Évaluation de santé du système sur 5 axes (Radar)", "5-Achsen-Systemzustandsbewertung (Radar)", "Evaluación de salud del sistema en 5 ejes (Radar)", "Valutazione della salute del sistema a 5 assi (Radar)", "Avaliação da saúde do sistema em 5 eixos (Radar)")
        add(.systemHealthRadarSubtitle, "多维度实时权重量化 (存储 / 内存 / 启动 / 残留 / 隐私)", "多維度即時權重量化 (存儲 / 記憶體 / 啟動 / 殘留 / 隱私)", "Multi-dimensional real-time weight quantization (Storage / Memory / Boot / Residue / Privacy)", "リアルタイム多次元重み付け定量化 (ストレージ / メモリ / 起動 / 残留 / プライバシー)", "다차원 실시간 가중치 정량화 (저장공간 / 메모리 / 시동 / 잔여항목 / 개인정보)", "Quantification pondérée en temps réel (Stockage / Mémoire / Démarrage / Résidus / Confidentialité)", "Mehrdimensionale Echtzeit-Gewichtung (Speicher / RAM / Start / Rückstände / Datenschutz)", "Cuantificación ponderada en tiempo real (Almacenamiento / Memoria / Inicio / Residuos / Privacidad)", "Quantificazione pesata in tempo reale (Spazio / Memoria / Avvio / Residui / Privacy)", "Quantificação ponderada em tempo real (Armazenamento / Memória / Inicialização / Resíduos / Privacidade)")
        add(.healthScoreBadgeFormat, "得分: %d / 100", "得分: %d / 100", "Score: %d / 100", "スコア: %d / 100", "점수: %d / 100", "Score : %d / 100", "Punktzahl: %d / 100", "Puntuación: %d / 100", "Punteggio: %d / 100", "Pontuação: %d / 100")
        add(.healthDimStorage, "存储", "存儲", "Storage", "ストレージ", "저장공간", "Stockage", "Speicher", "Almacenamiento", "Spazio", "Armazenamento")
        add(.healthDimMemory, "内存", "記憶體", "Memory", "メモリ", "메모리", "Mémoire", "RAM", "Memoria", "Memoria", "Memória")
        add(.healthDimBoot, "启动", "啟動", "Boot", "起動", "시동", "Démarrage", "Start", "Inicio", "Avvio", "Inicialização")
        add(.healthDimResidue, "无冗余", "無冗餘", "Cleanliness", "残留ゼロ", "잔여물 없음", "Sans résidus", "Rückstandsfrei", "Sin residuos", "Senza residui", "Sem resíduos")
        add(.healthDimPrivacy, "隐私", "隱私", "Privacy", "プライバシー", "개인정보", "Confidentialité", "Datenschutz", "Privacidad", "Privacy", "Privacidade")
        add(.healthDimStorageDesc, "磁盘剩余空间充足，文件系统读写健康", "磁碟剩餘空間充足，檔案系統讀寫健康", "Ample disk space available, filesystem healthy", "ディスクの空き容量が十分でファイルシステムも正常です", "디스크 여유 공간이 충분하며 파일 시스템이 정상입니다", "Espace disque suffisant, système de fichiers sain", "Ausreichend Speicherplatz, Dateisystem gesund", "Espacio en disco suficiente, sistema de archivos óptimo", "Spazio su disco sufficiente, file system in salute", "Espaço em disco suficiente, sistema de arquivos saudável")
        add(.healthDimMemoryDesc, "物理内存压力极低，分页交换开销轻微", "實體記憶體壓力極低，分頁交換開銷輕微", "Physical RAM pressure is low with minimal swap usage", "物理メモリの負荷が低くスワップも最小限です", "물리 메모리 압박이 낮고 스왑 사용량이 적습니다", "Pression mémoire faible et pagination minime", "Niedriger RAM-Druck bei minimaler Auslagerung", "Presión de memoria baja y uso mínimo de swap", "Pressione della memoria bassa e swap minimo", "Pressão de memória baixa e uso mínimo de swap")
        add(.healthDimBootDesc, "自启动项与后台守护进程管控良好", "自啟動項與後台守護進程管控良好", "Login items and background daemons well managed", "ログイン項目とバックグラウンド処理が適切に管理されています", "시동 프로그램 및 백그라운드 데몬이 잘 관리됨", "Éléments d'ouverture et démons bien gérés", "Startobjekte und Hintergrunddienste gut verwaltet", "Ítems de inicio y daemons de fondo bien gestionados", "Elementi di avvio e demoni ben gestiti", "Itens de início e daemons em segundo plano sob controle")
        add(.healthDimResidueDesc, "应用缓存与无用日志处于健康管控范围", "應用快取與無用日誌處於健康管控範圍", "Application caches and logs are well controlled", "アプリキャッシュやログは適切な範囲に収まっています", "앱 캐시 및 로그가 안전한 범위 내에 유지됨", "Caches d'apps et journaux sous contrôle", "App-Caches und Protokolle im gesunden Bereich", "Cachés de apps y registros bajo control", "Cache di app e log entro limiti di sicurezza", "Caches de apps e logs sob controle saudável")
        add(.healthDimPrivacyDesc, "全盘访问权限与敏感系统权限配置严密", "全盤訪問權限與敏感系統權限配置嚴密", "Full Disk Access and sensitive permissions securely configured", "フルディスクアクセスと重要権限が適切に設定されています", "전체 디스크 접근 및 민감한 권한이 안전하게 구성됨", "Accès complet au disque et permissions sécurisées", "Festplattenvollzugriff und sensible Rechte sicher konfiguriert", "Acceso total al disco y permisos sensibles bien configurados", "Accesso completo al disco e permessi configurati in sicurezza", "Acesso Total ao Disco e permissões confidenciais protegidas")
        add(.healthScoreExcellent, "系统状态极佳", "系統狀態極佳", "System in Peak Condition", "システムは最高状態です", "시스템 상태가 매우 우수합니다", "Système en parfait état", "System in Bestzustand", "Sistema en estado óptimo", "Sistema in condizioni eccellenti", "Sistema em condições ideais")
        add(.healthScoreGood, "系统运行平稳", "系統運行平穩", "System Running Smoothly", "システムはスムーズに動作しています", "시스템이 안정적으로 작동 중입니다", "Système fluide", "System läuft reibungslos", "Sistema funcionando con fluidez", "Sistema stabile", "Sistema funcionando perfeitamente")
        add(.healthScoreNeedCare, "建议执行系统深度调优", "建議執行系統深度調優", "Tuning Recommended", "システムの最適化を推奨します", "시스템 최적화를 권장합니다", "Optimisation recommandée", "Optimierung empfohlen", "Optimización recomendada", "Ottimizzazione consigliata", "Otimização recomendada")
        add(.oneKeyHealthCheck, "重新评估", "重新評估", "Re-evaluate", "再評価", "다시 평가", "Réévaluer", "Neu bewerten", "Reevaluar", "Rivaluta", "Reavaliar")
        add(.oneKeyOptimize, "一键深度调优", "一鍵深度調優", "One-Click Deep Tuning", "ワンクリック徹底最適化", "원클릭 정밀 최적화", "Optimisation approfondie", "Tiefenoptimierung mit 1 Klick", "Optimización profunda", "Ottimizzazione profonda", "Otimização profunda em 1 clique")
        add(.memoryReleasing, "释放中...", "釋放中...", "Releasing...", "解放中...", "정리 중...", "Libération...", "Freigeben...", "Liberando...", "Rilascio in corso...", "Liberando...")
        add(.memoryReleased, "已释放", "已釋放", "Purged", "解放完了", "정리 완료", "Libéré", "Freigegeben", "Liberado", "Rilasciato", "Liberado")
        add(.actionFreeMemory, "释放", "釋放", "Purge", "解放", "정리", "Libérer", "Freigeben", "Liberar", "Libera", "Liberar")
        add(.memoryQuickReleasePrompt, "点击释放不活跃内存", "點擊釋放不活躍記憶體", "Click to purge inactive memory", "クリックして非アクティブメモリを解放", "클릭하여 비활성 메모리 정리", "Cliquer pour purger la mémoire inactive", "Klicken, um inaktiven RAM freizugeben", "Clic para purgar memoria inactiva", "Fai clic per liberare la memoria inattiva", "Clique para liberar memória inativa")
    }
}
