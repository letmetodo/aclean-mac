import Foundation

// MARK: - 无障碍（VoiceOver）语义文案
//
// 仅承载读屏专用文案：这些字符串不会出现在视觉界面上，
// 但同样必须全语言覆盖，否则读屏用户在非中文环境下会听到中文。
// 对应 L10nKey 声明见 L10nKey.swift 末尾（init 为 private，必须同文件）。

func populateA11y(_ map: inout [L10nKey: MultiLangEntry]) {
    func add(_ key: L10nKey, _ zh: String, _ zhHant: String, _ en: String, _ ja: String, _ ko: String,
             _ fr: String, _ de: String, _ es: String, _ it: String, _ ptBR: String) {
        map[key] = MultiLangEntry(zhHans: zh, zhHant: zhHant, en: en, ja: ja, ko: ko,
                                  fr: fr, de: de, es: es, it: it, ptBR: ptBR)
    }

    add(.a11yClearSearchField,
        "清除搜索内容", "清除搜尋內容",
        "Clear search text", "検索文字を消去", "검색어 지우기",
        "Effacer la recherche", "Suchtext löschen", "Borrar búsqueda",
        "Cancella ricerca", "Limpar pesquisa")

    add(.a11ySearchFieldHint,
        "输入关键词筛选列表", "輸入關鍵字篩選列表",
        "Type keywords to filter the list", "キーワードを入力して一覧を絞り込む", "키워드를 입력해 목록 필터링",
        "Saisissez des mots-clés pour filtrer la liste", "Suchbegriffe eingeben, um die Liste zu filtern", "Escribe palabras clave para filtrar la lista",
        "Digita parole chiave per filtrare l’elenco", "Digite palavras-chave para filtrar a lista")

    add(.a11yStorageChartLabel,
        "存储占用环形图", "儲存空間環形圖",
        "Storage usage ring chart", "ストレージ使用量のリンググラフ", "저장 공간 사용량 링 차트",
        "Graphique annulaire de l’espace disque", "Ringdiagramm der Speicherbelegung", "Gráfico circular del uso de almacenamiento",
        "Grafico ad anello dell’uso dello spazio", "Gráfico de anel do uso de armazenamento")

    add(.a11yStorageChartValueFormat,
        "已用 %@，共 %@", "已用 %@，共 %@",
        "%@ used of %@", "%@ 使用済み（全 %@）", "%@ 사용 중 / 전체 %@",
        "%@ utilisés sur %@", "%@ von %@ belegt", "%@ usados de %@",
        "%@ usati su %@", "%@ usados de %@")

    add(.a11yProgressPercentFormat,
        "%d%%", "%d%%", "%d%%", "%d%%", "%d%%", "%d%%", "%d%%", "%d%%", "%d%%", "%d%%")

    add(.a11ySectionGroupHint,
        "使用方向键在项目中移动", "使用方向鍵在項目中移動",
        "Use arrow keys to move between items", "矢印キーで項目間を移動します", "화살표 키로 항목 간 이동",
        "Utilisez les flèches pour naviguer entre les éléments", "Mit den Pfeiltasten zwischen Elementen wechseln", "Usa las flechas para moverte entre elementos",
        "Usa le frecce per spostarti tra gli elementi", "Use as setas para navegar entre os itens")

    add(.a11yLockedItemHint,
        "此项受系统保护，无法清理", "此項受系統保護，無法清理",
        "This item is protected by the system and cannot be cleaned", "この項目はシステムで保護されており、削除できません", "이 항목은 시스템에서 보호되어 정리할 수 없습니다",
        "Cet élément est protégé par le système et ne peut pas être nettoyé", "Dieses Element ist systemgeschützt und kann nicht bereinigt werden", "Este elemento está protegido por el sistema y no se puede limpiar",
        "Questo elemento è protetto dal sistema e non può essere pulito", "Este item é protegido pelo sistema e não pode ser limpo")

    // MARK: - 长任务回音（预计剩余时间）

    add(.etaSecondsFormat,
        "约剩 %d 秒", "約剩 %d 秒",
        "about %ds left", "残り約 %d 秒", "약 %d초 남음",
        "environ %ds restantes", "noch ca. %ds", "quedan ~%ds",
        "circa %ds rimanenti", "cerca de %ds restantes")

    add(.etaMinutesFormat,
        "约剩 %d 分钟", "約剩 %d 分鐘",
        "about %d min left", "残り約 %d 分", "약 %d분 남음",
        "environ %d min restantes", "noch ca. %d Min.", "quedan ~%d min",
        "circa %d min rimanenti", "cerca de %d min restantes")

    // MARK: - 长任务完成通知

    add(.notifyScanFinishedTitle,
        "扫描完成", "掃描完成",
        "Scan complete", "スキャン完了", "스캔 완료",
        "Analyse terminée", "Scan abgeschlossen", "Análisis completado",
        "Scansione completata", "Verificação concluída")

    add(.notifyScanFinishedBodyFormat,
        "%@：发现 %d 个可清理项，共 %@", "%@：發現 %d 個可清理項目，共 %@",
        "%@: %d cleanable items found, %@ in total", "%@：整理可能な項目 %d 件、合計 %@", "%@: 정리 가능한 항목 %d개, 총 %@",
        "%@ : %d éléments nettoyables, %@ au total", "%@: %d bereinigbare Elemente, insgesamt %@", "%@: %d elementos limpiables, %@ en total",
        "%@: %d elementi pulibili, %@ in totale", "%@: %d itens limpáveis, %@ no total")

    add(.notifyCleanFinishedTitle,
        "清理完成", "清理完成",
        "Cleanup complete", "クリーンアップ完了", "정리 완료",
        "Nettoyage terminé", "Bereinigung abgeschlossen", "Limpieza completada",
        "Pulizia completata", "Limpeza concluída")

    add(.notifyCleanFinishedBodyFormat,
        "%@：已释放 %@", "%@：已釋放 %@",
        "%@: %@ freed", "%@：%@ を解放しました", "%@: %@ 확보",
        "%@ : %@ libérés", "%@: %@ freigegeben", "%@: %@ liberados",
        "%@: %@ liberati", "%@: %@ liberados")

    add(.notifyCleanPartialBodyFormat,
        "%@：已释放 %@，另有 %d 项未能清理", "%@：已釋放 %@，另有 %d 項未能清理",
        "%@: %@ freed, %d items could not be cleaned", "%@：%@ を解放、%d 件は削除できませんでした", "%@: %@ 확보, %d개 항목은 정리하지 못했습니다",
        "%@ : %@ libérés, %d éléments non nettoyés", "%@: %@ freigegeben, %d Elemente nicht bereinigt", "%@: %@ liberados, %d elementos sin limpiar",
        "%@: %@ liberati, %d elementi non puliti", "%@: %@ liberados, %d itens não limpos")

    add(.settingsNotifyOnCompletionTitle,
        "完成时通知我", "完成時通知我",
        "Notify me when finished", "完了時に通知", "완료 시 알림",
        "M’avertir à la fin", "Bei Abschluss benachrichtigen", "Avisarme al terminar",
        "Avvisami al termine", "Avisar ao concluir")

    add(.settingsNotifyOnCompletionCaption,
        "扫描或清理在后台完成时，发一条系统通知；窗口在前台时不打扰",
        "掃描或清理在背景完成時，發一條系統通知；視窗在前景時不打擾",
        "Send a system notification when a scan or cleanup finishes in the background. Silent while the window is in front.",
        "スキャンやクリーンアップがバックグラウンドで完了したときに通知します。ウィンドウが前面にあるときは通知しません。",
        "스캔이나 정리가 백그라운드에서 끝나면 알림을 보냅니다. 창이 앞에 있을 때는 알리지 않습니다.",
        "Envoyer une notification lorsque l’analyse ou le nettoyage se termine en arrière-plan. Silencieux si la fenêtre est au premier plan.",
        "Benachrichtigung, wenn Scan oder Bereinigung im Hintergrund endet. Kein Hinweis, solange das Fenster im Vordergrund ist.",
        "Enviar una notificación cuando el análisis o la limpieza terminen en segundo plano. Silencioso si la ventana está al frente.",
        "Invia una notifica quando scansione o pulizia terminano in background. Silenzioso se la finestra è in primo piano.",
        "Enviar uma notificação quando a verificação ou limpeza terminar em segundo plano. Silencioso se a janela estiver à frente.")

    // MARK: - 撤销窗口期与空状态

    add(.receiptUndoWindowHint,
        "关闭此页面后将无法撤销", "關閉此頁面後將無法撤銷",
        "You can’t undo after leaving this page", "この画面を閉じると取り消せません", "이 화면을 닫으면 실행 취소할 수 없습니다",
        "Impossible d’annuler après avoir quitté cette page", "Nach Verlassen dieser Seite ist kein Rückgängigmachen möglich", "No se puede deshacer tras salir de esta página",
        "Non puoi annullare dopo aver lasciato questa pagina", "Não é possível desfazer após sair desta página")

    add(.emptyStateFilteredTitleFormat,
        "没有匹配「%@」的项目", "沒有符合「%@」的項目",
        "No items match “%@”", "「%@」に一致する項目はありません", "‘%@’와 일치하는 항목이 없습니다",
        "Aucun élément ne correspond à « %@ »", "Keine Elemente passen zu „%@“", "Ningún elemento coincide con «%@»",
        "Nessun elemento corrisponde a «%@»", "Nenhum item corresponde a “%@”")

    add(.emptyStateCleanTitle,
        "没有需要清理的项目，这台 Mac 很干净", "沒有需要清理的項目，這台 Mac 很乾淨",
        "Nothing to clean — this Mac is in good shape", "クリーンアップが必要な項目はありません。この Mac は良好な状態です", "정리할 항목이 없습니다. 이 Mac은 깨끗합니다",
        "Rien à nettoyer — ce Mac est en bon état", "Nichts zu bereinigen – dieser Mac ist in gutem Zustand", "Nada que limpiar: este Mac está en buen estado",
        "Niente da pulire: questo Mac è in buone condizioni", "Nada para limpar — este Mac está em bom estado")

    add(.actionClearFilters,
        "清除筛选", "清除篩選",
        "Clear filters", "フィルターを解除", "필터 지우기",
        "Effacer les filtres", "Filter zurücksetzen", "Borrar filtros",
        "Cancella filtri", "Limpar filtros")

    add(.actionCopyPath,
        "复制路径", "複製路徑",
        "Copy path", "パスをコピー", "경로 복사",
        "Copier le chemin", "Pfad kopieren", "Copiar ruta",
        "Copia percorso", "Copiar caminho")

    add(.toastPathCopied,
        "路径已复制", "路徑已複製",
        "Path copied", "パスをコピーしました", "경로를 복사했습니다",
        "Chemin copié", "Pfad kopiert", "Ruta copiada",
        "Percorso copiato", "Caminho copiado")

    // MARK: - 命令面板（⌘K）

    add(.commandPaletteTitle,
        "快速跳转", "快速跳轉",
        "Quick jump", "クイックジャンプ", "빠른 이동",
        "Accès rapide", "Schnellzugriff", "Acceso rápido",
        "Accesso rapido", "Acesso rápido")

    add(.commandPalettePlaceholder,
        "跳转到模块、设置或操作…", "跳轉到模組、設定或操作…",
        "Jump to a module, setting, or action…", "モジュール・設定・操作へ移動…", "모듈, 설정, 작업으로 이동…",
        "Aller à un module, réglage ou action…", "Zu Modul, Einstellung oder Aktion springen…", "Ir a un módulo, ajuste o acción…",
        "Vai a modulo, impostazione o azione…", "Ir para módulo, ajuste ou ação…")

    add(.commandPaletteNoResults,
        "没有匹配项", "沒有符合項目",
        "No matches", "一致する項目がありません", "일치하는 항목 없음",
        "Aucun résultat", "Keine Treffer", "Sin resultados",
        "Nessun risultato", "Nenhum resultado")

    add(.commandPaletteGroupModules,
        "模块", "模組",
        "Module", "モジュール", "모듈",
        "Module", "Modul", "Módulo",
        "Modulo", "Módulo")

    add(.commandPaletteGroupActions,
        "操作", "操作",
        "Action", "操作", "작업",
        "Action", "Aktion", "Acción",
        "Azione", "Ação")

    add(.receiptLifetimeTotalFormat,
        "累计已为这台 Mac 腾出 %@", "累計已為這台 Mac 騰出 %@",
        "%@ freed on this Mac so far", "この Mac で累計 %@ を解放しました", "이 Mac에서 누적 %@ 확보",
        "%@ libérés au total sur ce Mac", "Insgesamt %@ auf diesem Mac freigegeben", "%@ liberados en total en este Mac",
        "%@ liberati in totale su questo Mac", "%@ liberados no total neste Mac")

    add(.moduleTipDismiss,
        "关闭提示", "關閉提示",
        "Dismiss tip", "ヒントを閉じる", "팁 닫기",
        "Fermer l’astuce", "Hinweis schließen", "Cerrar sugerencia",
        "Chiudi suggerimento", "Fechar dica")

    // MARK: - 清理暂停 / 续传

    add(.actionPauseCleaning,
        "暂停", "暫停",
        "Pause", "一時停止", "일시정지",
        "Suspendre", "Pausieren", "Pausar",
        "Sospendi", "Pausar")

    add(.actionResumeCleaning,
        "继续", "繼續",
        "Resume", "再開", "계속",
        "Reprendre", "Fortsetzen", "Reanudar",
        "Riprendi", "Retomar")

    add(.statusCleaningPaused,
        "已暂停", "已暫停",
        "Paused", "一時停止中", "일시정지됨",
        "En pause", "Pausiert", "En pausa",
        "In pausa", "Pausado")

    add(.statusPauseTakesEffectAfterCurrentItem,
        "正在完成当前项目，随后暂停", "正在完成目前項目，隨後暫停",
        "Finishing the current item, then pausing", "現在の項目を完了してから一時停止します", "현재 항목을 마친 후 일시정지합니다",
        "Fin de l’élément en cours, puis pause", "Aktuelles Element wird beendet, dann Pause", "Terminando el elemento actual y luego pausa",
        "Completamento dell’elemento corrente, poi pausa", "Concluindo o item atual e depois pausando")
}
