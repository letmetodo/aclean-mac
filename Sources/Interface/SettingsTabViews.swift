import SwiftUI
import AppKit
import UniformTypeIdentifiers

extension SettingsView {
    // MARK: - 3. 扫描配置 (扫描阈值 + 排除白名单)

    var scanningTabContent: some View {
        let largeThresholdOptions: [(label: String, value: Int)] = [
            ("50 MB", 50),
            ("100 MB", 100),
            ("250 MB", 250),
            ("500 MB", 500),
            ("1024 MB (1 GB)", 1024)
        ]
        let oldMonthsOptions: [(label: String, value: Int)] = [
            ("1M", 1),
            ("3M", 3),
            ("6M", 6),
            ("12M", 12)
        ]

        return VStack(alignment: .leading, spacing: 18) {
            sectionTitle(L10n.localized(.settingsLargeAndOldFilesCriteriaTitle))

            settingsCard {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L10n.localized(.thresholdLargeFileMinSize))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Text("\(state.largeFileThresholdMB) MB")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.accent)
                        }

                        HStack(spacing: 8) {
                            ForEach(largeThresholdOptions, id: \.value) { opt in
                                let active = state.largeFileThresholdMB == opt.value
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        state.largeFileThresholdMB = opt.value
                                    }
                                } label: {
                                    Text(opt.label)
                                        .font(.system(size: 12, weight: active ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(active ? Theme.onAccent : Theme.text)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(active ? Theme.accent : Theme.hover)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .strokeBorder(active ? Theme.accent : Theme.sep, lineWidth: 1)
                                                )
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            }
                        }
                    }

                    Divider().background(Theme.sep)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L10n.localized(.thresholdOldFileMonths))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Text("\(state.oldFileMonths)M")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.accent)
                        }

                        HStack(spacing: 8) {
                            ForEach(oldMonthsOptions, id: \.value) { opt in
                                let active = state.oldFileMonths == opt.value
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        state.oldFileMonths = opt.value
                                    }
                                } label: {
                                    Text(opt.label)
                                        .font(.system(size: 12, weight: active ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(active ? Theme.onAccent : Theme.text)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(active ? Theme.accent : Theme.hover)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .strokeBorder(active ? Theme.accent : Theme.sep, lineWidth: 1)
                                                )
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            }
                        }
                    }
                }
            }

            // 扫描与清理完成提示：音效 + 系统通知
            settingsCard {
                VStack(spacing: 14) {
                    toggleRow(
                        title: L10n.localized(.soundEffectsToggleTitle),
                        subtitle: L10n.localized(.soundEffectsToggleSubtitle),
                        isOn: $config.soundEffects
                    )
                    toggleRow(
                        title: L10n.localized(.settingsNotifyOnCompletionTitle),
                        subtitle: L10n.localized(.settingsNotifyOnCompletionCaption),
                        isOn: $config.notifyOnCompletion
                    )
                }
            }

            // 排除白名单（移入扫描配置中）
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionTitle(L10n.localized(.scanExclusionWhitelistTitle))
                    Spacer()
                    Button {
                        pickFolderForWhitelist()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                            Text(L10n.localized(.actionAddFolderOrFile))
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.16))
                        .foregroundStyle(Theme.accent)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                }

                settingsCard {
                    if state.ignoredPaths.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "shield.slash")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.tert)
                            Text(L10n.localized(.settingsNoCustomExclusionPathsPrompt))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.sub)
                            Text(L10n.localized(.settingsAddExclusionPathHint))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.tert)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(state.ignoredPaths).sorted(), id: \.self) { path in
                                HStack(spacing: 10) {
                                    Image(systemName: "folder.fill.badge.gearshape")
                                        .foregroundStyle(Theme.accent)
                                    Text(path)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(Theme.text)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button {
                                        state.removeIgnoredPath(path)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.red)
                                            .frame(width: 26, height: 26)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                                }
                                .padding(.vertical, 8)
                                Divider().background(Theme.sep)
                            }

                            HStack {
                                Text(String(format: L10n.localized(.settingsProtectedExclusionCountFormat), state.ignoredPaths.count))
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.sub)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 4. 定时配置 (LaunchAgent 后台调度、巡检周期与静默维护)

    var scheduleTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle(L10n.localized(.settingsScheduledScanAndMaintenanceTitle))

            settingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    toggleRow(
                        title: L10n.localized(.settingsEnableScheduledInspectionToggle),
                        subtitle: L10n.localized(.settingsScheduledInspectionDesc),
                        isOn: $scheduler.config.isEnabled
                    )
                    .onChange(of: scheduler.config.isEnabled) { enabled in
                        if enabled {
                            scheduler.toggleEnabled(true)
                            if !scheduler.installLaunchAgent() {
                                scheduler.toggleEnabled(false)
                                state.showToast(L10n.localized(.executionFailedOrCancelled), kind: .error)
                            }
                        } else {
                            scheduler.toggleEnabled(false)
                            if !scheduler.uninstallLaunchAgent() {
                                scheduler.config.isEnabled = true
                                state.showToast(L10n.localized(.executionFailedOrCancelled), kind: .error)
                            }
                        }
                    }

                    if scheduler.config.isEnabled {
                        Divider().background(Theme.sep)

                        HStack {
                            Text(L10n.localized(.settingsInspectionIntervalLabel))
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(Theme.text)
                            Spacer()
                            HStack(spacing: 6) {
                                ForEach(ScheduleInterval.allCases) { item in
                                    let active = scheduler.config.interval == item
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            scheduler.updateSchedule(interval: item)
                                        }
                                    } label: {
                                        Text(item.displayName)
                                            .font(.system(size: 11.5, weight: active ? .bold : .medium))
                                            .foregroundStyle(active ? Theme.onAccent : Theme.text)
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                    .fill(active ? Theme.accent : Theme.hover)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                            .strokeBorder(active ? Theme.accent : Theme.sep, lineWidth: 1)
                                                    )
                                            )
                                            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }

                        Divider().background(Theme.sep)

                        toggleRow(
                            title: L10n.localized(.settingsSilentCleanSafeCachesToggle),
                            subtitle: L10n.localized(.settingsSilentCleanSafeCachesDesc),
                            isOn: $scheduler.config.autoClean
                        )
                    }
                }
            }

            sectionTitle(L10n.localized(.settingsSystemDaemonStatusTitle))

            settingsCard {
                HStack(spacing: 12) {
                    Image(systemName: scheduler.config.isEnabled ? "clock.badge.checkmark.fill" : "clock.badge.xmark")
                        .font(.system(size: 24))
                        .foregroundStyle(scheduler.config.isEnabled ? Theme.green : Theme.sub)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(scheduler.config.isEnabled
                             ? L10n.localized(.settingsDaemonReadyLaunchdManaged)
                             : L10n.localized(.settingsDaemonNotEnabled))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Text("~/Library/LaunchAgents/\(AppConfig.Paths.launchAgentLabel).plist")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.sub)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - 5. 权限配置 (高危清理确认 + 权限获取情况)

    var permissionsTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 1. 高危清理确认
            sectionTitle(L10n.localized(.highRiskCleanupConfirm))

            settingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    toggleRow(
                        title: L10n.localized(.highRiskCleanupConfirmSubtitle),
                        subtitle: L10n.localized(.settingsRiskControlMatrixSectionSubtitle),
                        isOn: $config.confirmBeforeDelete
                    )

                    Divider().background(Theme.sep)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.localized(.settingsRiskControlNotesHeader))
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Theme.text)

                        HStack(spacing: 12) {
                            riskLevelBadge(
                                color: Theme.green,
                                icon: "checkmark.shield.fill",
                                title: L10n.localized(.levelSafe),
                                desc: L10n.localized(.cachesAndOrphanedLogsMovedToTrashReversibleAnytime)
                            )

                            riskLevelBadge(
                                color: Theme.amber,
                                icon: "exclamationmark.shield.fill",
                                title: L10n.localized(.levelPrompt),
                                desc: L10n.localized(.installersInDownloadsAndOldArchivesConfirmationRequested)
                            )

                            riskLevelBadge(
                                color: Theme.red,
                                icon: "shield.slash.fill",
                                title: L10n.localized(.levelDangerous),
                                desc: L10n.localized(.xcodeBuildDataDockerImagesAndBackupsRequiresSecondaryConfirmation)
                            )
                        }
                    }
                }
            }

            settingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.localized(.ruleUpdateTitle)).font(.headline)
                    Text(String(format: L10n.localized(.ruleUpdateVersionFormat), ruleUpdates.version.isEmpty ? "—" : ruleUpdates.version))
                    Toggle(L10n.localized(.ruleUpdateAutomatic), isOn: $automaticRuleUpdates)
                        .onChange(of: automaticRuleUpdates) { _ in ruleUpdates.preferenceChanged() }
                    Text(L10n.localized(.ruleUpdateDescription)).font(.system(size: 12)).foregroundStyle(Theme.sub)
                    Text(ruleUpdates.statusText).font(.system(size: 12)).foregroundStyle(Theme.sub)
                    HStack {
                        Button(L10n.localized(.ruleUpdateCheck)) { ruleUpdates.check(manual: true) }
                            .disabled(ruleUpdates.status == .checking || ruleUpdates.status == .notConfigured)
                        if ruleUpdates.status == .checking { ProgressView().controlSize(.small) }
                    }
                    Text(String(format: L10n.localized(.ruleUpdateLastCheckFormat),
                                ruleUpdates.lastCheck.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? L10n.localized(.ruleUpdateNever)))
                        .font(.system(size: 12)).foregroundStyle(Theme.sub)
                }
            }

            settingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(L10n.localized(.optionalNetworkFeatures), isOn: $networkFeaturesEnabled)
                        .onChange(of: networkFeaturesEnabled) { _ in WeatherService.shared.networkPreferenceChanged() }
                    Text(L10n.localized(.optionalNetworkDescription))
                        .font(.system(size: 12)).foregroundStyle(Theme.sub)
                }
            }

            settingsCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.localized(.helperTitle)).font(.headline)
                    Text(L10n.localized(helperMessage)).font(.system(size: 12)).foregroundStyle(Theme.sub)
                    Button(L10n.localized(.helperEnable)) {
                        do { try PrivilegedMaintenanceClient.register(); helperMessage = .helperRequested }
                        catch { helperMessage = .helperFailed }
                    }
                }
            }

            // 2. 权限获取情况
            sectionTitle(L10n.localized(.permissionStatus))

            settingsCard {
                VStack(spacing: 16) {
                    // 权限 1：macOS 完全磁盘访问权限 (FDA)
                    HStack(spacing: 14) {
                        Image(systemName: state.hasFullDiskAccess ? "checkmark.seal.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(state.hasFullDiskAccess ? Theme.green : Theme.amber)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.hasFullDiskAccess
                                 ? L10n.localized(.settingsFdaGrantedStatusTitle)
                                 : L10n.localized(.settingsFdaNotGrantedStatusTitle))
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                            Text(state.hasFullDiskAccess
                                 ? L10n.localized(.settingsFdaGrantedStatusDesc)
                                 : L10n.localized(.settingsFdaNotGrantedStatusDesc))
                                .font(.system(size: 11.5))
                                .foregroundStyle(Theme.sub)
                                .lineLimit(1)
                        }

                        Spacer()

                        if !state.hasFullDiskAccess {
                            HStack(spacing: 8) {
                                Button {
                                    permissionCoordinator.requestAccess(context: .general) {
                                        state.checkFullDiskAccess()
                                    }
                                } label: {
                                    Text(L10n.localized(.actionConfigurePermissionsNow))
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Theme.amber.opacity(0.2))
                                        .foregroundStyle(Theme.amber)
                                        .clipShape(Capsule())
                                        .contentShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }

                                Button {
                                    FullDiskAccessManager.shared.revealAppInFinder()
                                } label: {
                                    Text(L10n.localized(.actionLocateAppInFinder))
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Theme.sub)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.hover)
                                        .clipShape(Capsule())
                                        .contentShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            }
                        } else {
                            HStack(spacing: 8) {
                                Button {
                                    state.checkFullDiskAccess()
                                } label: {
                                    Text(L10n.localized(.actionRefreshStatusCheck))
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Theme.sub)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Theme.hover)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .contentShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            }
                        }
                    }

                    Divider().background(Theme.sep)

                    // 权限 2：系统级废纸篓保护
                    HStack(spacing: 14) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.green)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.localized(.settingsTrashProtectionTitle))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Text(L10n.localized(.cleanupPolicyDisclosure))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.sub)
                        }

                        Spacer()

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.green)
                    }

                    Divider().background(Theme.sep)

                    // 权限 3：最小特权安全模型
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.accent)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.localized(.settingsLeastPrivilegeTitle))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Text(L10n.localized(.settingsLeastPrivilegeDesc))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.sub)
                        }

                        Spacer()

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.green)
                    }
                }
            }

            // 3. 安装引导与快速设置向导
            sectionTitle(L10n.localized(.onboardingSectionTitle))

            settingsCard {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.accent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.localized(.onboardingSectionTitle))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Text(L10n.localized(.onboardingSectionDesc))
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.sub)
                    }

                    Spacer()

                    Button {
                        state.presentOnboarding()
                    } label: {
                        Text(L10n.localized(.onboardingActionReopenGuide))
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accent.opacity(0.16))
                            .foregroundStyle(Theme.accent)
                            .clipShape(Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                }
            }
        }
    }

    func riskLevelBadge(color: Color, icon: String, title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.text)
            }
            Text(desc)
                .font(.system(size: 10))
                .foregroundStyle(Theme.sub)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - 辅助组件与动作

    func pickFolderForWhitelist() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.prompt = L10n.localized(.actionAddToWhitelist)
        if panel.runModal() == .OK {
            for url in panel.urls {
                state.addIgnoredPath(url.path)
            }
        }
    }

    func exportConfiguration() {
        guard let data = config.exportJSONData() else {
            state.showToast(L10n.localized(.executionFailedOrCancelled), kind: .error)
            return
        }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ACleaner-Config.json"
        savePanel.prompt = L10n.localized(.actionExportConfig)
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try data.write(to: url, options: .atomic)
                state.showToast(L10n.localized(.toastConfigExportedSuccess), kind: .success)
            } catch {
                state.showToast(L10n.localized(.executionFailedOrCancelled), kind: .error)
            }
        }
    }

    func importConfiguration() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = L10n.localized(.actionImportConfig)
        if openPanel.runModal() == .OK, let url = openPanel.url {
            if let data = try? Data(contentsOf: url),
               config.importJSONData(data) {
                state.largeFileThresholdMB = config.largeFileThresholdMB
                state.oldFileMonths = config.oldFileMonths
                state.ignoredPaths = config.ignoredPaths
                MenuBarCompanion.shared.setVisible(config.menuBarMonitor)
                state.showToast(L10n.localized(.toastConfigImportedSuccess), kind: .success)
            } else {
                state.showToast(L10n.localized(.executionFailedOrCancelled), kind: .error)
            }
        }
    }

    func sectionTitle(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 14.5, weight: .bold))
                .foregroundStyle(Theme.text)
            if let sub = subtitle, !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.sub)
            }
        }
    }

    func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.sep, lineWidth: 1)
                    )
            )
    }

    func toggleRow(title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                isOn.wrappedValue.toggle()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                    if let sub = subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.sub)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 16)
                SmoothCapsuleToggle(isOn: isOn, tint: Theme.accent)
                    .allowsHitTesting(false)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
    }
}
