-- 规则在线更新的最终数据草案；不包含旧结构和历史追加补丁。
-- 本文件尚未接入生产加载器，不能直接替换当前 Resources。
PRAGMA foreign_keys=ON;
BEGIN TRANSACTION;
PRAGMA defer_foreign_keys=ON;
CREATE TABLE cm_application_identity (bundle_id TEXT PRIMARY KEY,name TEXT NOT NULL);
CREATE TABLE cm_auto_clean_cache (
 cache_key TEXT PRIMARY KEY COLLATE NOCASE
);
CREATE TABLE cm_cache_profile (
    id TEXT PRIMARY KEY,
    rule_id TEXT NOT NULL REFERENCES cm_junk_rule(id),
    root_template TEXT NOT NULL,
    discovery_kind TEXT NOT NULL CHECK(discovery_kind IN
        ('exact_root','chromium_leaves','electron_leaves','firefox_leaves','derived_children')),
    cache_class TEXT NOT NULL CHECK(cache_class IN ('app','developer')),
    rebuild_effect TEXT NOT NULL CHECK(rebuild_effect IN ('redownload','recompile','first_launch')),
    cost_override TEXT NOT NULL CHECK(cost_override IN ('none','low','medium','high')),
    UNIQUE(rule_id,root_template,discovery_kind)
);
CREATE TABLE cm_cache_profile_lock (
    profile_id TEXT NOT NULL REFERENCES cm_cache_profile(id),
    lock_kind TEXT NOT NULL CHECK(lock_kind IN ('bundle_id','process_name','process_family')),
    lock_value TEXT NOT NULL,
    PRIMARY KEY(profile_id,lock_kind,lock_value)
);
CREATE TABLE cm_cache_subdir (
    rule_id TEXT NOT NULL REFERENCES cm_junk_rule(id),
    name TEXT NOT NULL,
    tier TEXT NOT NULL CHECK (tier IN ('L1','L2')),
    PRIMARY KEY (rule_id, name)
);
CREATE TABLE cm_chromium_profile_subdir (
    name   TEXT PRIMARY KEY,
    tier   TEXT NOT NULL CHECK (tier IN ('L1','L2')),
    action TEXT NOT NULL CHECK (action IN ('trash','trash_children_only'))
);
CREATE TABLE cm_discovery_binding (
 rule_id TEXT NOT NULL REFERENCES cm_junk_rule(id),
 path_template TEXT NOT NULL,
 path_kind TEXT NOT NULL CHECK(path_kind IN('root','glob','none')),
 scanner_id TEXT NOT NULL,
 discovery_kind TEXT NOT NULL CHECK(discovery_kind IN ('fixed_path','wildcard_child','profile_leaves','bundle_predicate','system_temp','explicit_not_supported')),
 status TEXT NOT NULL CHECK(status IN ('active','inventory_only','deferred','rejected')),
 PRIMARY KEY(rule_id,path_template)
);
CREATE TABLE cm_electron_data_dir (
    bundle_id TEXT PRIMARY KEY,
    dir_name  TEXT NOT NULL
);
CREATE TABLE cm_file_type (extension TEXT PRIMARY KEY,category TEXT NOT NULL);
CREATE TABLE cm_global_guard (
 value TEXT NOT NULL,
 kind TEXT NOT NULL CHECK(kind IN('protected_bundle','protected_path','protected_root')),
 PRIMARY KEY(value,kind)
);
CREATE TABLE cm_junk_rule (
    id                TEXT PRIMARY KEY,
    section           TEXT NOT NULL CHECK (section IN (
                          'app','communication','developer','ai','design',
                          'leftovers','system','storage')),
    tier              TEXT NOT NULL CHECK (tier IN ('L1','L2','L3','L4')),
    action            TEXT NOT NULL CHECK (action IN (
                          'trash','trash_children_only','read_only','native')),
    status            TEXT NOT NULL CHECK (status IN ('active','deferred','rejected')),
    default_selected  INTEGER NOT NULL CHECK (default_selected IN (0,1)),
    min_bytes         INTEGER,
    min_age_hours     INTEGER,
    rebuild_cost      TEXT NOT NULL CHECK (rebuild_cost IN ('none','low','medium','high')),
    predicate         TEXT,
    reason_code       TEXT NOT NULL DEFAULT 'REASON_CODE_MANUAL_REVIEW',
    title_key         TEXT NOT NULL,
    note              TEXT,
    fixture_required  INTEGER NOT NULL CHECK (fixture_required IN (0,1)),
    CHECK (default_selected = 0 OR (status = 'active' AND tier = 'L1')),
    CHECK (status != 'rejected' OR tier = 'L4'),
    CHECK (fixture_required = 0 OR status != 'active')
);
CREATE TABLE cm_junk_rule_exclude (
    rule_id TEXT NOT NULL REFERENCES cm_junk_rule(id),
    name    TEXT NOT NULL,
    PRIMARY KEY (rule_id, name)
);
CREATE TABLE cm_junk_rule_lock (
    rule_id    TEXT NOT NULL REFERENCES cm_junk_rule(id),
    lock_kind  TEXT NOT NULL CHECK (lock_kind IN ('bundle_id','process_name')),
    lock_value TEXT NOT NULL,
    PRIMARY KEY (rule_id, lock_kind, lock_value)
);
CREATE TABLE cm_launchd_protected_prefix (
    prefix TEXT PRIMARY KEY,
    reason TEXT NOT NULL
);
CREATE TABLE cm_mail_client (
    bundle_id          TEXT PRIMARY KEY,
    name               TEXT NOT NULL,
    match_kind         TEXT NOT NULL CHECK (match_kind IN ('exact','prefix')),
    role               TEXT NOT NULL CHECK (role IN ('third_party','system')),
    list_on_uninstall  INTEGER NOT NULL CHECK (list_on_uninstall IN (0,1)),
    default_selected   INTEGER NOT NULL CHECK (default_selected = 0),
    exclude_from_junk  INTEGER NOT NULL CHECK (exclude_from_junk = 1),
    exclude_from_orphan INTEGER NOT NULL CHECK (exclude_from_orphan = 1),
    CHECK (role != 'third_party' OR list_on_uninstall = 1),
    CHECK (role != 'system' OR list_on_uninstall = 0)
);
CREATE TABLE cm_name_collision (
    name TEXT PRIMARY KEY COLLATE NOCASE
);
CREATE TABLE cm_organize_path (
 path_template TEXT NOT NULL,
 role TEXT NOT NULL CHECK(role IN('exclude_component','installer_root')),
 PRIMARY KEY(path_template,role)
);
CREATE TABLE cm_package_extension (extension TEXT PRIMARY KEY);
CREATE TABLE cm_performance_task (
    task_id           TEXT PRIMARY KEY,
    status            TEXT NOT NULL CHECK (status IN ('allowed','disabled','forbidden')),
    needs_admin       INTEGER NOT NULL CHECK (needs_admin IN (0,1)),
    default_selected  INTEGER NOT NULL CHECK (default_selected IN (0,1)),
    risk              TEXT NOT NULL CHECK (risk IN ('safe','caution','disruptive','forbidden')),
    reversible        INTEGER NOT NULL CHECK (reversible IN (0,1)),
    note              TEXT NOT NULL,
    CHECK (status != 'forbidden' OR default_selected = 0),
    CHECK (default_selected = 0 OR (status = 'allowed' AND needs_admin = 0 AND risk = 'safe'))
);
CREATE TABLE cm_project_artifact (
 artifact_name TEXT PRIMARY KEY,
 candidate INTEGER NOT NULL CHECK(candidate IN(0,1)),
 generic_name INTEGER NOT NULL CHECK(generic_name IN(0,1)),
 proof_kind TEXT NOT NULL CHECK(proof_kind IN('parent_any','dotnet_project','disabled'))
);
CREATE TABLE cm_project_artifact_proof (
 artifact_name TEXT NOT NULL REFERENCES cm_project_artifact(artifact_name),
 proof_path TEXT NOT NULL,
 PRIMARY KEY(artifact_name,proof_path)
);
CREATE TABLE cm_project_manifest (name TEXT PRIMARY KEY);
CREATE TABLE cm_project_scan_root (root_template TEXT PRIMARY KEY);
CREATE TABLE cm_protected_path (
    id            TEXT PRIMARY KEY,
    path_template TEXT NOT NULL,
    match_kind    TEXT NOT NULL CHECK (match_kind IN ('prefix','suffix','exact','marker')),
    reason        TEXT NOT NULL
);
CREATE TABLE cm_rule_meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
CREATE TABLE cm_rule_selection (
 rule_id TEXT PRIMARY KEY REFERENCES cm_junk_rule(id),
 daily_allowed INTEGER NOT NULL CHECK(daily_allowed IN(0,1)),
 developer_allowed INTEGER NOT NULL CHECK(developer_allowed IN(0,1)),
 maximum_allowed INTEGER NOT NULL CHECK(maximum_allowed IN(0,1)),
 manual_only INTEGER NOT NULL CHECK(manual_only IN(0,1)),
 CHECK(manual_only=0 OR (daily_allowed=0 AND developer_allowed=0 AND maximum_allowed=0))
);
CREATE TABLE cm_service_worker_domain (
    domain TEXT PRIMARY KEY,
    tier   TEXT NOT NULL CHECK (tier = 'L2')
);
CREATE TABLE cm_shared_vendor_root (
    name TEXT PRIMARY KEY COLLATE NOCASE
);
CREATE TABLE cm_uninstall_template (
    id                TEXT PRIMARY KEY,
    path_template     TEXT NOT NULL,
    tier              TEXT NOT NULL CHECK (tier IN ('L1','L2','L3','L4')),
    domain            TEXT NOT NULL CHECK (domain IN ('user','system','session')),
    execute           INTEGER NOT NULL CHECK (execute IN (0,1)),
    default_selected  INTEGER NOT NULL CHECK (default_selected IN (0,1)),
    status            TEXT NOT NULL CHECK (status IN ('active','deferred','rejected')),
    note              TEXT,
    CHECK (default_selected = 0 OR (status = 'active' AND tier = 'L1' AND execute = 1)),
    CHECK (domain != 'system' OR execute = 0),
    CHECK (status != 'rejected' OR (execute = 0 AND default_selected = 0))
);
CREATE TABLE cm_vacuum_forbidden (
    id     TEXT PRIMARY KEY,
    marker TEXT NOT NULL,
    reason TEXT NOT NULL
);
CREATE TABLE cm_version_cache (
 rule_id TEXT NOT NULL REFERENCES cm_junk_rule(id),
 root_template TEXT NOT NULL,
 current_template TEXT,
 name_pattern TEXT NOT NULL,
 keep_latest INTEGER NOT NULL CHECK(keep_latest>=2),
 min_age_hours INTEGER NOT NULL CHECK(min_age_hours>=168),
 family TEXT NOT NULL CHECK(family IN('browser','agent')),
 PRIMARY KEY(rule_id,root_template),
 CHECK(family='browser' OR current_template IS NOT NULL)
);
INSERT INTO "cm_application_identity" VALUES('com.apple.finder','Finder');
INSERT INTO "cm_application_identity" VALUES('com.apple.dock','Dock');
INSERT INTO "cm_application_identity" VALUES('com.apple.Safari','Safari');
INSERT INTO "cm_application_identity" VALUES('com.apple.mail','Mail');
INSERT INTO "cm_application_identity" VALUES('com.apple.dt.Xcode','Xcode');
INSERT INTO "cm_application_identity" VALUES('com.google.Chrome','Chrome');
INSERT INTO "cm_application_identity" VALUES('com.tencent.xinWeChat','WeChat');
INSERT INTO "cm_auto_clean_cache" VALUES('com.apple.Safari');
INSERT INTO "cm_auto_clean_cache" VALUES('com.google.Chrome');
INSERT INTO "cm_auto_clean_cache" VALUES('com.google.Chrome.canary');
INSERT INTO "cm_auto_clean_cache" VALUES('com.brave.Browser');
INSERT INTO "cm_auto_clean_cache" VALUES('com.microsoft.edgemac');
INSERT INTO "cm_auto_clean_cache" VALUES('company.thebrowser.Browser');
INSERT INTO "cm_auto_clean_cache" VALUES('org.mozilla.firefox');
INSERT INTO "cm_auto_clean_cache" VALUES('com.vivaldi.Vivaldi');
INSERT INTO "cm_auto_clean_cache" VALUES('com.operasoftware.Opera');
INSERT INTO "cm_auto_clean_cache" VALUES('org.chromium.Chromium');
INSERT INTO "cm_auto_clean_cache" VALUES('com.apple.dt.Xcode');
INSERT INTO "cm_auto_clean_cache" VALUES('com.microsoft.VSCode');
INSERT INTO "cm_auto_clean_cache" VALUES('com.todesktop.230313mzl4w4u92');
INSERT INTO "cm_auto_clean_cache" VALUES('com.exafunction.windsurf');
INSERT INTO "cm_auto_clean_cache" VALUES('dev.zed.Zed');
INSERT INTO "cm_auto_clean_cache" VALUES('Homebrew');
INSERT INTO "cm_auto_clean_cache" VALUES('md.obsidian');
INSERT INTO "cm_auto_clean_cache" VALUES('Obsidian');
INSERT INTO "cm_auto_clean_cache" VALUES('com.colliderli.iina');
INSERT INTO "cm_auto_clean_cache" VALUES('com.raycast.macos');
INSERT INTO "cm_auto_clean_cache" VALUES('com.aone.keka');
INSERT INTO "cm_auto_clean_cache" VALUES('pl.maketheweb.cleanshotx');
INSERT INTO "cm_auto_clean_cache" VALUES('abnerworks.Typora');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tdesktop.Telegram');
INSERT INTO "cm_auto_clean_cache" VALUES('ru.keepcoder.Telegram');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tencent.xinWeChat');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tencent.qq');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tencent.WeWorkMac');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tencent.meeting');
INSERT INTO "cm_auto_clean_cache" VALUES('us.zoom.xos');
INSERT INTO "cm_auto_clean_cache" VALUES('com.electron.lark');
INSERT INTO "cm_auto_clean_cache" VALUES('com.bytedance.feishu');
INSERT INTO "cm_auto_clean_cache" VALUES('com.alibaba.DingTalkMac');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tinyspeck.slackmacgap');
INSERT INTO "cm_auto_clean_cache" VALUES('com.hnc.Discord');
INSERT INTO "cm_auto_clean_cache" VALUES('notion.id');
INSERT INTO "cm_auto_clean_cache" VALUES('com.figma.Desktop');
INSERT INTO "cm_auto_clean_cache" VALUES('com.bohemiancoding.sketch3');
INSERT INTO "cm_auto_clean_cache" VALUES('com.postmanlabs.mac');
INSERT INTO "cm_auto_clean_cache" VALUES('com.insomnia.app');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tinyapp.TablePlus');
INSERT INTO "cm_auto_clean_cache" VALUES('com.sequelace.SequelAce');
INSERT INTO "cm_auto_clean_cache" VALUES('com.googlecode.iterm2');
INSERT INTO "cm_auto_clean_cache" VALUES('dev.warp.Warp-Stable');
INSERT INTO "cm_auto_clean_cache" VALUES('org.alacritty');
INSERT INTO "cm_auto_clean_cache" VALUES('net.kovidgoyal.kitty');
INSERT INTO "cm_auto_clean_cache" VALUES('com.sublimetext.4');
INSERT INTO "cm_auto_clean_cache" VALUES('com.docker.docker');
INSERT INTO "cm_auto_clean_cache" VALUES('dev.kdrag0n.MacVirt');
INSERT INTO "cm_auto_clean_cache" VALUES('eu.exelban.Stats');
INSERT INTO "cm_auto_clean_cache" VALUES('me.guillaumeb.MonitorControl');
INSERT INTO "cm_auto_clean_cache" VALUES('com.knollsoft.Rectangle');
INSERT INTO "cm_auto_clean_cache" VALUES('com.lwouis.alt-tab-macos');
INSERT INTO "cm_auto_clean_cache" VALUES('com.ripperhe.Bob');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tisfeng.Easydict');
INSERT INTO "cm_auto_clean_cache" VALUES('com.netease.163music');
INSERT INTO "cm_auto_clean_cache" VALUES('com.tencent.QQMusicMac');
INSERT INTO "cm_auto_clean_cache" VALUES('com.kingsoft.wpsoffice.mac');
INSERT INTO "cm_auto_clean_cache" VALUES('com.sangfor.EasyConnect');
INSERT INTO "cm_auto_clean_cache" VALUES('EasyConnect');
INSERT INTO "cm_auto_clean_cache" VALUES('com.google.antigravity');
INSERT INTO "cm_auto_clean_cache" VALUES('com.openai.codex');
INSERT INTO "cm_auto_clean_cache" VALUES('com.anthropic.claudefordesktop');
INSERT INTO "cm_cache_profile" VALUES('chrome','JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Google/Chrome','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('chromium','JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Chromium','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('brave','JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/BraveSoftware/Brave-Browser','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('edge','JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Microsoft Edge','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('vivaldi','JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Vivaldi','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('opera','JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/com.operasoftware.Opera','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('arc','JC.BRW.ARC.CACHE','~/Library/Application Support/Arc/User Data','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('chrome-cache','JC.BRW.CHROMIUM.CACHE','~/Library/Caches/Google/Chrome','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('arc-cache','JC.BRW.ARC.CACHE','~/Library/Caches/Arc','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('arc-bundle-cache','JC.BRW.ARC.CACHE','~/Library/Caches/company.thebrowser.Browser','chromium_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('firefox','JC.BRW.FIREFOX.CACHE','~/Library/Caches/Firefox/Profiles','firefox_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Code','JC.ELECTRON.CACHE','~/Library/Application Support/Code','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Cursor','JC.AI.IDE.CACHE','~/Library/Application Support/Cursor','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Windsurf','JC.AI.IDE.CACHE','~/Library/Application Support/Windsurf','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Antigravity','JC.AI.IDE.CACHE','~/Library/Application Support/Antigravity','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Claude','JC.AI.IDE.CACHE','~/Library/Application Support/Claude','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-LarkShell','JC.ELECTRON.CACHE','~/Library/Application Support/LarkShell','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Notion','JC.ELECTRON.CACHE','~/Library/Application Support/Notion','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Slack','JC.ELECTRON.CACHE','~/Library/Application Support/Slack','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-discord','JC.ELECTRON.CACHE','~/Library/Application Support/discord','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Figma','JC.ELECTRON.CACHE','~/Library/Application Support/Figma','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Insomnia','JC.ELECTRON.CACHE','~/Library/Application Support/Insomnia','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Linear','JC.ELECTRON.CACHE','~/Library/Application Support/Linear','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-Postman','JC.ELECTRON.CACHE','~/Library/Application Support/Postman','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-CherryStudio','JC.ELECTRON.CACHE','~/Library/Application Support/CherryStudio','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('electron-obsidian','JC.ELECTRON.CACHE','~/Library/Application Support/obsidian','electron_leaves','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('npm-download','JC.DEV.NPM.CACACHE','~/.npm/_cacache','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('brew-download','JC.DEV.BREW.DOWNLOADS','~/Library/Caches/Homebrew/downloads','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('pip-macos','JC.DEV.PKG.SAFE','~/Library/Caches/pip','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('pip-xdg','JC.DEV.PKG.SAFE','~/.cache/pip','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('bun-download','JC.DEV.PKG.SAFE','~/.bun/install/cache','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('cargo-archive','JC.DEV.PKG.SAFE','~/.cargo/registry/cache','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('go-build-macos','JC.DEV.PKG.SAFE','~/Library/Caches/go-build','exact_root','developer','recompile','medium');
INSERT INTO "cm_cache_profile" VALUES('go-build-xdg','JC.DEV.PKG.SAFE','~/.cache/go-build','exact_root','developer','recompile','medium');
INSERT INTO "cm_cache_profile" VALUES('xcode-modules','JC.DEV.XCODE.CACHE','~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex','exact_root','developer','recompile','medium');
INSERT INTO "cm_cache_profile" VALUES('xcode-derived-live','JC.DEV.XCODE.DERIVED.LIVE','~/Library/Developer/Xcode/DerivedData','derived_children','developer','recompile','medium');
INSERT INTO "cm_cache_profile" VALUES('xcode-derived-orphan','JC.DEV.XCODE.DERIVED.ORPHAN','~/Library/Developer/Xcode/DerivedData','derived_children','developer','recompile','medium');
INSERT INTO "cm_cache_profile" VALUES('jianying-audioWave','JC.DSG.JIANYING.CACHE','~/Movies/JianyingPro/User Data/Cache/audioWave','exact_root','developer','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('jianying-recognize','JC.DSG.JIANYING.CACHE','~/Movies/JianyingPro/User Data/Cache/recognize','exact_root','developer','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('jianying-frameThumbnail','JC.DSG.JIANYING.CACHE','~/Movies/JianyingPro/User Data/Cache/frameThumbnail','exact_root','developer','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('devtools-http','JC.BRW.AUTOMATION.CACHE','~/.cache/chrome-devtools-mcp/chrome-profile','chromium_leaves','developer','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('playwright-mcp-http','JC.BRW.AUTOMATION.CACHE','~/Library/Caches/ms-playwright-mcp/mcp-chrome-*','chromium_leaves','developer','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-aha-profile_all-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/profile_*/Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-aha-profile_all-Code-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/profile_*/Code Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-aha-PartitionsV2-all-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/PartitionsV2/*/Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-aha-PartitionsV2-all-Code-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/PartitionsV2/*/Code Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-iron-profile_all-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/profile_*/Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-iron-profile_all-Code-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/profile_*/Code Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-iron-PartitionsV2-all-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/PartitionsV2/*/Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('lark-iron-PartitionsV2-all-Code-Cache','JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/PartitionsV2/*/Code Cache','exact_root','app','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('netease-online','JC.MEDIA.NETEASE.CACHE','~/Library/Containers/com.netease.163music/Data/Library/Caches/online_play_cache','exact_root','app','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('cursor-vsix','JC.AI.IDE.CACHE','~/Library/Application Support/Cursor/CachedExtensionVSIXs','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('code-vsix','JC.ELECTRON.CACHE','~/Library/Application Support/Code/CachedExtensionVSIXs','exact_root','developer','redownload','low');
INSERT INTO "cm_cache_profile" VALUES('gradle-build-cache-1','JC.DEV.PKG.SAFE','~/.gradle/caches/build-cache-1','exact_root','developer','recompile','low');
INSERT INTO "cm_cache_profile" VALUES('adobe-Media-Cache','JC.DSG.ADOBE.MEDIACACHE','~/Library/Application Support/Adobe/Common/Media Cache','exact_root','developer','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('adobe-Media-Cache-Files','JC.DSG.ADOBE.MEDIACACHE','~/Library/Application Support/Adobe/Common/Media Cache Files','exact_root','developer','first_launch','low');
INSERT INTO "cm_cache_profile" VALUES('puppeteer-chrome','JC.DEV.BROWSER.DOWNLOAD','~/.cache/puppeteer/chrome','derived_children','developer','redownload','medium');
INSERT INTO "cm_cache_profile" VALUES('puppeteer-headless','JC.DEV.BROWSER.DOWNLOAD','~/.cache/puppeteer/chrome-headless-shell','derived_children','developer','redownload','medium');
INSERT INTO "cm_cache_profile" VALUES('cursor-agent-versions','JC.AI.OLDVERSION','~/.local/share/cursor-agent/versions','derived_children','developer','redownload','medium');
INSERT INTO "cm_cache_profile" VALUES('cursor-embedded-versions','JC.AI.OLDVERSION','~/Library/Application Support/Cursor/User/globalStorage/anysphere.cursor-agent-worker/agent-cli/.local/share/cursor-agent/versions','derived_children','developer','redownload','medium');
INSERT INTO "cm_cache_profile" VALUES('codex-daemon-versions','JC.AI.OLDVERSION','~/.codex/packages/app-server-daemon/releases','derived_children','developer','redownload','medium');
INSERT INTO "cm_cache_profile_lock" VALUES('chrome','bundle_id','com.google.Chrome');
INSERT INTO "cm_cache_profile_lock" VALUES('chromium','bundle_id','org.chromium.Chromium');
INSERT INTO "cm_cache_profile_lock" VALUES('brave','bundle_id','com.brave.Browser');
INSERT INTO "cm_cache_profile_lock" VALUES('edge','bundle_id','com.microsoft.edgemac');
INSERT INTO "cm_cache_profile_lock" VALUES('vivaldi','bundle_id','com.vivaldi.Vivaldi');
INSERT INTO "cm_cache_profile_lock" VALUES('opera','bundle_id','com.operasoftware.Opera');
INSERT INTO "cm_cache_profile_lock" VALUES('arc','bundle_id','company.thebrowser.Browser');
INSERT INTO "cm_cache_profile_lock" VALUES('chrome-cache','bundle_id','com.google.Chrome');
INSERT INTO "cm_cache_profile_lock" VALUES('arc-cache','bundle_id','company.thebrowser.Browser');
INSERT INTO "cm_cache_profile_lock" VALUES('arc-bundle-cache','bundle_id','company.thebrowser.Browser');
INSERT INTO "cm_cache_profile_lock" VALUES('firefox','bundle_id','org.mozilla.firefox');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Code','bundle_id','com.microsoft.VSCode');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Cursor','bundle_id','com.todesktop.230313mzl4w4u92');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Windsurf','bundle_id','com.codeium.windsurf');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Windsurf','bundle_id','com.exafunction.windsurf');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Antigravity','bundle_id','com.google.antigravity');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Claude','bundle_id','com.anthropic.claudefordesktop');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-LarkShell','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-LarkShell','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Notion','bundle_id','notion.id');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Slack','bundle_id','com.tinyspeck.slackmacgap');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-discord','bundle_id','com.hnc.Discord');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Figma','bundle_id','com.figma.Desktop');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Insomnia','bundle_id','com.insomnia.app');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Linear','bundle_id','com.linear');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-Postman','bundle_id','com.postmanlabs.mac');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-CherryStudio','bundle_id','com.tencent.CherryStudio');
INSERT INTO "cm_cache_profile_lock" VALUES('electron-obsidian','bundle_id','md.obsidian');
INSERT INTO "cm_cache_profile_lock" VALUES('npm-download','process_name','node');
INSERT INTO "cm_cache_profile_lock" VALUES('npm-download','process_name','npm');
INSERT INTO "cm_cache_profile_lock" VALUES('npm-download','process_name','npx');
INSERT INTO "cm_cache_profile_lock" VALUES('npm-download','process_name','pnpm');
INSERT INTO "cm_cache_profile_lock" VALUES('npm-download','process_name','yarn');
INSERT INTO "cm_cache_profile_lock" VALUES('brew-download','process_name','brew');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-macos','process_name','python');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-macos','process_name','python3');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-macos','process_name','pip');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-macos','process_name','pip3');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-macos','process_family','python3Versioned');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-xdg','process_name','python');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-xdg','process_name','python3');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-xdg','process_name','pip');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-xdg','process_name','pip3');
INSERT INTO "cm_cache_profile_lock" VALUES('pip-xdg','process_family','python3Versioned');
INSERT INTO "cm_cache_profile_lock" VALUES('bun-download','process_name','bun');
INSERT INTO "cm_cache_profile_lock" VALUES('bun-download','process_name','node');
INSERT INTO "cm_cache_profile_lock" VALUES('cargo-archive','process_name','cargo');
INSERT INTO "cm_cache_profile_lock" VALUES('cargo-archive','process_name','rustc');
INSERT INTO "cm_cache_profile_lock" VALUES('cargo-archive','process_name','rustup');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-macos','process_name','go');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-macos','process_name','compile');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-macos','process_name','link');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-macos','process_name','gopls');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-xdg','process_name','go');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-xdg','process_name','compile');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-xdg','process_name','link');
INSERT INTO "cm_cache_profile_lock" VALUES('go-build-xdg','process_name','gopls');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-modules','process_name','xcodebuild');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-modules','process_name','swift');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-modules','process_name','swift-frontend');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-modules','process_name','clang');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-modules','process_name','clang++');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-modules','process_name','ibtool');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-modules','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-live','process_name','xcodebuild');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-live','process_name','swift');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-live','process_name','swift-frontend');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-live','process_name','clang');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-live','process_name','clang++');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-live','process_name','ibtool');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-live','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-orphan','process_name','xcodebuild');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-orphan','process_name','swift');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-orphan','process_name','swift-frontend');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-orphan','process_name','clang');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-orphan','process_name','clang++');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-orphan','process_name','ibtool');
INSERT INTO "cm_cache_profile_lock" VALUES('xcode-derived-orphan','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_cache_profile_lock" VALUES('jianying-audioWave','process_name','JianyingPro');
INSERT INTO "cm_cache_profile_lock" VALUES('jianying-recognize','process_name','JianyingPro');
INSERT INTO "cm_cache_profile_lock" VALUES('jianying-frameThumbnail','process_name','JianyingPro');
INSERT INTO "cm_cache_profile_lock" VALUES('devtools-http','process_name','chrome');
INSERT INTO "cm_cache_profile_lock" VALUES('playwright-mcp-http','process_name','chrome');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-profile_all-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-profile_all-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-profile_all-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-profile_all-Code-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-profile_all-Code-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-profile_all-Code-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-PartitionsV2-all-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-PartitionsV2-all-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-PartitionsV2-all-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-PartitionsV2-all-Code-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-PartitionsV2-all-Code-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-aha-PartitionsV2-all-Code-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-profile_all-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-profile_all-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-profile_all-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-profile_all-Code-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-profile_all-Code-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-profile_all-Code-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-PartitionsV2-all-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-PartitionsV2-all-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-PartitionsV2-all-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-PartitionsV2-all-Code-Cache','bundle_id','com.bytedance.feishu');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-PartitionsV2-all-Code-Cache','bundle_id','com.electron.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('lark-iron-PartitionsV2-all-Code-Cache','bundle_id','com.larksuite.feishu.ka.kywl.lark');
INSERT INTO "cm_cache_profile_lock" VALUES('netease-online','bundle_id','com.netease.163music');
INSERT INTO "cm_cache_profile_lock" VALUES('cursor-vsix','bundle_id','com.todesktop.230313mzl4w4u92');
INSERT INTO "cm_cache_profile_lock" VALUES('code-vsix','bundle_id','com.microsoft.VSCode');
INSERT INTO "cm_cache_profile_lock" VALUES('gradle-build-cache-1','process_name','GradleDaemon');
INSERT INTO "cm_cache_profile_lock" VALUES('adobe-Media-Cache','process_name','Adobe Premiere Pro');
INSERT INTO "cm_cache_profile_lock" VALUES('adobe-Media-Cache-Files','process_name','Adobe Premiere Pro');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','Cache/Cache_Data','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','Code Cache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','GPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','ShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','GrShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','DawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','GraphiteDawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','DawnGraphiteCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.CACHE','DawnWebGPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.SW','Service Worker/CacheStorage','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.CHROMIUM.SW','Service Worker/ScriptCache','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','Cache/Cache_Data','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','Code Cache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','GPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','ShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','GrShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','DawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','GraphiteDawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','DawnGraphiteCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.BRW.ARC.CACHE','DawnWebGPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','Cache/Cache_Data','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','Code Cache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','GPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','ShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','GrShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','DawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','GraphiteDawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','DawnGraphiteCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','DawnWebGPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.SW','Service Worker/CacheStorage','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.SW','Service Worker/ScriptCache','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','Cache/Cache_Data','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','Code Cache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','GPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','ShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','GrShaderCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','DawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','GraphiteDawnCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','DawnGraphiteCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','DawnWebGPUCache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','Cache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','CachedData','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','CachedExtensionVSIXs','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','logs','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.ELECTRON.CACHE','Crashpad/completed','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','Cache','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','CachedData','L1');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','CachedExtensionVSIXs','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','logs','L2');
INSERT INTO "cm_cache_subdir" VALUES('JC.AI.IDE.CACHE','Crashpad/completed','L2');
INSERT INTO "cm_chromium_profile_subdir" VALUES('Cache/Cache_Data','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('Code Cache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('GPUCache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('ShaderCache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('GrShaderCache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('DawnCache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('GraphiteDawnCache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('DawnGraphiteCache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('DawnWebGPUCache','L1','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('Service Worker/CacheStorage','L2','trash_children_only');
INSERT INTO "cm_chromium_profile_subdir" VALUES('Service Worker/ScriptCache','L2','trash_children_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.GEMINI.TMP','~/.codex/log','root','scanDeveloperCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.GEMINI.TMP','~/.cursor/ai-tracking','root','scanDeveloperCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.GEMINI.TMP','~/.gemini/tmp','root','scanDeveloperCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.IDE.CACHE','~/Library/Application Support/Antigravity','root','scanUserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.IDE.CACHE','~/Library/Application Support/Claude','root','scanUserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.IDE.CACHE','~/Library/Application Support/Cursor','root','scanUserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.IDE.CACHE','~/Library/Application Support/Windsurf','root','scanUserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.OLDVERSION','~/.codex/packages/app-server-daemon/releases/*','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.OLDVERSION','~/.local/share/cursor-agent/versions/*','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.OLDVERSION','~/Library/Application Support/Cursor/User/globalStorage/anysphere.cursor-agent-worker/agent-cli/.local/share/cursor-agent/versions/*','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.OLLAMA.ORPHAN','~/.ollama/models/blobs','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.cache/chrome-devtools-mcp','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.cache/codex-runtimes','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.cache/cursor-agent','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.cache/opencode','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.claude/downloads','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.claude/shell-snapshots','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.claude/telemetry','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.codex/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.gemini/antigravity-browser-profile','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/.local/share/opencode/log','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/Library/Caches/antigravity-updater','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/Library/Caches/claude-cli-nodejs','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/Library/Caches/com.google.antigravity','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/Library/Caches/com.openai.codex','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.TOOL.CACHE','~/Library/Caches/cursor-compile-cache','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.WORKTREE','~/.claude/worktrees','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.WORKTREE','~/.codex/worktrees','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.WORKTREE','~/.cursor/worktrees','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/PartitionsV2/*/Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/PartitionsV2/*/Code Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/profile_*/Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/aha/users/*/profile_*/Code Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/PartitionsV2/*/Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/PartitionsV2/*/Code Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/profile_*/Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.APP.LARK.CACHE','~/Library/Caches/LarkShell*/iron/users/*/profile_*/Code Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.ARC.CACHE','~/Library/Application Support/Arc/User Data','root','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.ARC.CACHE','~/Library/Caches/Arc','root','scanBrowserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.ARC.CACHE','~/Library/Caches/company.thebrowser.Browser','root','scanBrowserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/BraveSoftware/Brave-Browser','root','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Chromium','root','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Google/Chrome','root','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Microsoft Edge','root','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/Vivaldi','root','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.CACHE','~/Library/Application Support/com.operasoftware.Opera','root','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.CACHE','~/Library/Caches/Google/Chrome','root','scanBrowserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.CHROMIUM.SW','','none','inventoryOnly','explicit_not_supported','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.FIREFOX.CACHE','~/Library/Caches/Firefox/Profiles/*/cache2','glob','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.FIREFOX.CACHE','~/Library/Caches/Firefox/Profiles/*/startupCache','glob','scanBrowserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.SAFARI','','none','deferred','explicit_not_supported','deferred');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.SAFARI.CACHE','~/Library/Caches/com.apple.Safari','root','scanBrowserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.SAFARI.CACHE','~/Library/Containers/com.apple.Safari/Data/Library/Caches','root','scanBrowserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.CACHE.CONTAINER','~/Library/Containers/*/Data/Library/Caches','glob','scanUserCaches','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.CACHE.CONTAINER','~/Library/Containers/com.youku.mac/Data/Documents/YTCORE_PLAYER_CACHE','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.CACHE.CONTAINER','~/Library/Group Containers/*/Library/Caches','glob','scanUserCaches','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.CACHE.USER','~/Library/Caches','root','scanUserCaches','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.ELECTRON.CACHE','~/Library/Application Support/{electronDataDir}','root','scanUserCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.ELECTRON.CACHE','~/Library/Containers/{bundleID}/Data/Library/Application Support/{electronDataDir}','root','scanUserCaches','profile_leaves','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.ELECTRON.SW','','none','inventoryOnly','explicit_not_supported','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.MEDIA.NETEASE.CACHE','~/Library/Containers/com.netease.163music/Data/Library/Caches/online_play_cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.MEDIA.SPOTIFY','~/Library/Application Support/Spotify/PersistentCache/Storage','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.MEDIA.SPOTIFY.CACHE','~/Library/Caches/com.spotify.client','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.MEET','~/Library/Caches/us.zoom.xos','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.MEET','~/Library/Containers/com.tencent.meeting/Data/Library/Caches','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.MEET','~/Library/Containers/com.tencent.meeting/Data/Library/Logs','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.MEET','~/Library/Logs/zoom.us','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.QQ','~/Library/Containers/com.tencent.qq','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.TELEGRAM.MEDIA','~/Library/Application Support/Telegram Desktop/tdata/user_data/cache','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.TELEGRAM.MEDIA','~/Library/Application Support/Telegram Desktop/tdata/user_data/media_cache','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.TELEGRAM.MEDIA','~/Library/Containers/org.telegram.desktop/Data/Library/Application Support/Telegram Desktop/tdata/user_data/cache','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.TELEGRAM.MEDIA','~/Library/Containers/org.telegram.desktop/Data/Library/Application Support/Telegram Desktop/tdata/user_data/media_cache','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.TELEGRAM.MEDIA','~/Library/Group Containers/*.ru.keepcoder.Telegram/account-*/postbox/media','glob','inventoryOnly','wildcard_child','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.WECHAT.CACHE','~/Library/Containers/com.tencent.xinWeChat/Data/Library/Caches','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.WECHAT.MEDIA','~/Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.WECHAT.MEDIA','~/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.IM.WECOM','~/Library/Containers/com.tencent.WeWorkMac','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.ADOBE.CACHE','~/Library/Application Support/Adobe/Common/Peak Files','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.ADOBE.CACHE','~/Library/Caches/Adobe','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.ADOBE.MEDIACACHE','~/Library/Application Support/Adobe/Common/Media Cache','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.ADOBE.MEDIACACHE','~/Library/Application Support/Adobe/Common/Media Cache Files','root','scanUserCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.FCP','','none','deferred','explicit_not_supported','deferred');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.JIANYING.CACHE','~/Movies/JianyingPro/User Data/Cache/audioWave','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.JIANYING.CACHE','~/Movies/JianyingPro/User Data/Cache/frameThumbnail','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DSG.JIANYING.CACHE','~/Movies/JianyingPro/User Data/Cache/recognize','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.AUTOMATION.CACHE','~/.cache/chrome-devtools-mcp/chrome-profile/*/Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.AUTOMATION.CACHE','~/.cache/chrome-devtools-mcp/chrome-profile/*/Code Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.AUTOMATION.CACHE','~/.cache/chrome-devtools-mcp/chrome-profile/*/GPUCache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.AUTOMATION.CACHE','~/Library/Caches/ms-playwright-mcp/mcp-chrome-*/*/Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.AUTOMATION.CACHE','~/Library/Caches/ms-playwright-mcp/mcp-chrome-*/*/Code Cache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.BRW.AUTOMATION.CACHE','~/Library/Caches/ms-playwright-mcp/mcp-chrome-*/*/GPUCache','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.BREW.CACHE','~/Library/Caches/Homebrew','root','BrewHelper.scanCacheItems','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.BREW.DOWNLOADS','~/Library/Caches/Homebrew/downloads','root','BrewHelper.scanCacheItems','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.BROWSER.DOWNLOAD','~/.cache/puppeteer/chrome-headless-shell/*','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.BROWSER.DOWNLOAD','~/.cache/puppeteer/chrome/*','root','scanProfileCache','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.GRADLE.DAEMON','~/.gradle/daemon','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.JETBRAINS.CACHE','~/Library/Caches/JetBrains/*/caches','glob','scanJetBrainsCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.JETBRAINS.CACHE','~/Library/Caches/JetBrains/*/compile-server','glob','scanJetBrainsCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.JETBRAINS.CACHE','~/Library/Caches/JetBrains/*/index','glob','scanJetBrainsCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.JETBRAINS.CACHE','~/Library/Caches/JetBrains/*/jcef_cache','glob','scanJetBrainsCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.JETBRAINS.CACHE','~/Library/Caches/JetBrains/*/log','glob','scanJetBrainsCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.JETBRAINS.CACHE','~/Library/Caches/JetBrains/*/tmp','glob','scanJetBrainsCaches','profile_leaves','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.NPM.CACACHE','~/.npm/_cacache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.NPM.LOGS','~/.npm/_logs','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.cache/ms-playwright','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.cache/playwright','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.cache/torch','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.cache/torch/hub/checkpoints','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.cargo/registry/src','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.conda/pkgs','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.gradle/wrapper/dists','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.m2/repository','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/.nuget/packages','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.L2','~/Library/Caches/ms-playwright','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.android/build-cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.android/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.bun/install/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.cache/go-build','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.cache/helm','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.cache/pip','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.cache/uv','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.cache/yarn','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.cargo/git/db','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.cargo/registry/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.composer/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.docker/buildx/activity','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.gem/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.gradle/caches','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.ivy2/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.local/share/pnpm/store','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.node-gyp','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.sbt/boot','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.terraform.d/plugin-cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/.yarn/cache','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/CocoaPods','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/Yarn','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/composer','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/go-build','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/goimports','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/helm','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/hermit','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/node-gyp','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/org.swift.swiftpm','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/pip','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/pnpm','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Caches/uv','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/Logs/JetBrains','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.SAFE','~/Library/pnpm/store','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PKG.UNVERIFIED','','none','inventoryOnly','explicit_not_supported','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PROJECT','','none','ProjectPurgeEngine.scan','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.PUB.ASSET','~/.pub-cache','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.SIMCTL.RUNTIME','','none','deferred','explicit_not_supported','deferred');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.ARCHIVES','~/Library/Developer/Xcode/Archives','root','scanXcodeJunk','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.ARCHIVES','~/Library/Developer/Xcode/Products','root','scanXcodeJunk','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.CACHE','~/Library/Caches/com.apple.dt.Xcode','root','scanXcodeJunk','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.CACHE','~/Library/Developer/CoreSimulator/Caches','root','scanXcodeJunk','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.CACHE','~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex','root','scanXcodeJunk','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.CACHE','~/Library/Developer/Xcode/DocumentationCache','root','scanXcodeJunk','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.CACHE','~/Library/Developer/Xcode/UserData/IB Support','root','scanXcodeJunk','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.CACHE','~/Library/Developer/Xcode/UserData/Previews','root','scanXcodeJunk','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.CACHE','~/Library/Logs/CoreSimulator','root','scanXcodeJunk','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DERIVED.LIVE','~/Library/Developer/Xcode/DerivedData','root','scanXcodeJunk','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','~/Library/Developer/Xcode/DerivedData','root','scanXcodeJunk','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DEVICESUPPORT','~/Library/Developer/Xcode/iOS DeviceSupport','root','scanXcodeJunk','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DEVICESUPPORT','~/Library/Developer/Xcode/macOS DeviceSupport','root','scanXcodeJunk','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DEVICESUPPORT','~/Library/Developer/Xcode/tvOS DeviceSupport','root','scanXcodeJunk','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DEVICESUPPORT','~/Library/Developer/Xcode/visionOS DeviceSupport','root','scanXcodeJunk','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DEVICESUPPORT','~/Library/Developer/Xcode/watchOS DeviceSupport','root','scanXcodeJunk','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.DEVICESUPPORT.LATEST','','none','scanXcodeJunk','bundle_predicate','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.SIMULATOR','~/Library/Developer/CoreSimulator/Devices','root','XcodeHelper.scanSimulatorDevices','wildcard_child','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.DEV.XCODE.SYSTEM.CACHE','/Library/Developer/CoreSimulator/Caches','root','scanXcodeJunk','profile_leaves','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.LEFTOVER.ORPHAN','~/Library/Application Support/CrashReporter','root','scanOrphanedAppFiles','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LEFTOVER.ORPHAN','~/Library/Caches','root','scanOrphanedAppFiles','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LEFTOVER.ORPHAN','~/Library/HTTPStorages','root','scanOrphanedAppFiles','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LEFTOVER.ORPHAN','~/Library/Logs','root','scanOrphanedAppFiles','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LEFTOVER.ORPHAN','~/Library/Saved Application State','root','scanOrphanedAppFiles','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LEFTOVER.ORPHAN','~/Library/WebKit','root','scanOrphanedAppFiles','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.HF.MODEL','~/.cache/huggingface/hub','root','scanDeveloperCaches','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.LMSTUDIO','','none','inventoryOnly','explicit_not_supported','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.AI.OLLAMA.MODEL','~/.ollama/models/manifests','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.IOS.BACKUP','~/Library/Application Support/MobileSync/Backup','root','scanMobileBackups','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.DIAG.USER','~/Library/Application Support/CrashReporter','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.DIAG.USER','~/Library/Logs/CrashReporter','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.DIAG.USER','~/Library/Logs/DiagnosticReports','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.DIAG.USER','~/Library/Logs/HangReporter','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.USER','/Library/Logs/CrashReporter','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.USER','/Library/Logs/DiagnosticReports','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.USER','~/Library/Containers/*/Data/Library/Logs','glob','scanSystemLogs','wildcard_child','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.LOG.USER','~/Library/Logs','root','scanSystemLogs','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.APPSTORE.CACHE','~/Library/Caches/com.apple.appstore','root','scanAppStoreCache','fixed_path','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.CACHE.DARWIN','{DARWIN_USER_CACHE_DIR}','root','scanSystemCaches','system_temp','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.DMG.INSTALLED','~/Desktop','root','scanUnusedDiskImages','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.DMG.INSTALLED','~/Downloads','root','scanUnusedDiskImages','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.DMG.OTHER','~/Desktop','root','scanUnusedDiskImages','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.DMG.OTHER','~/Downloads','root','scanUnusedDiskImages','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.IPSW','~/Downloads','root','scanIOSUpdates','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.MAIL','','none','rejected','explicit_not_supported','rejected');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.PLIST.BROKEN','~/Library/Preferences','root','scanBrokenPreferences','bundle_predicate','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.QUARANTINE','~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2','root','rejected','explicit_not_supported','rejected');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.SAVEDSTATE','~/Library/Saved Application State','root','inventoryOnly','fixed_path','inventory_only');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.TMP.DARWIN','{DARWIN_USER_TEMP_DIR}','root','scanSystemCaches','system_temp','active');
INSERT INTO "cm_discovery_binding" VALUES('JC.SYS.VARLOG','','none','rejected','explicit_not_supported','rejected');
INSERT INTO "cm_electron_data_dir" VALUES('com.microsoft.VSCode','Code');
INSERT INTO "cm_electron_data_dir" VALUES('com.todesktop.230313mzl4w4u92','Cursor');
INSERT INTO "cm_electron_data_dir" VALUES('com.tencent.CherryStudio','CherryStudio');
INSERT INTO "cm_electron_data_dir" VALUES('com.codeium.windsurf','Windsurf');
INSERT INTO "cm_electron_data_dir" VALUES('com.google.antigravity','Antigravity');
INSERT INTO "cm_electron_data_dir" VALUES('com.anthropic.claudefordesktop','Claude');
INSERT INTO "cm_electron_data_dir" VALUES('com.tinyspeck.slackmacgap','Slack');
INSERT INTO "cm_electron_data_dir" VALUES('com.hnc.Discord','discord');
INSERT INTO "cm_electron_data_dir" VALUES('notion.id','Notion');
INSERT INTO "cm_electron_data_dir" VALUES('md.obsidian','obsidian');
INSERT INTO "cm_electron_data_dir" VALUES('com.figma.Desktop','Figma');
INSERT INTO "cm_electron_data_dir" VALUES('com.linear','Linear');
INSERT INTO "cm_electron_data_dir" VALUES('com.postmanlabs.mac','Postman');
INSERT INTO "cm_electron_data_dir" VALUES('com.insomnia.app','Insomnia');
INSERT INTO "cm_electron_data_dir" VALUES('com.electron.lark','LarkShell');
INSERT INTO "cm_file_type" VALUES('pdf','Documents');
INSERT INTO "cm_file_type" VALUES('doc','Documents');
INSERT INTO "cm_file_type" VALUES('docx','Documents');
INSERT INTO "cm_file_type" VALUES('txt','Documents');
INSERT INTO "cm_file_type" VALUES('rtf','Documents');
INSERT INTO "cm_file_type" VALUES('pages','Documents');
INSERT INTO "cm_file_type" VALUES('key','Documents');
INSERT INTO "cm_file_type" VALUES('ppt','Documents');
INSERT INTO "cm_file_type" VALUES('pptx','Documents');
INSERT INTO "cm_file_type" VALUES('xls','Documents');
INSERT INTO "cm_file_type" VALUES('xlsx','Documents');
INSERT INTO "cm_file_type" VALUES('md','Documents');
INSERT INTO "cm_file_type" VALUES('jpg','Images');
INSERT INTO "cm_file_type" VALUES('jpeg','Images');
INSERT INTO "cm_file_type" VALUES('png','Images');
INSERT INTO "cm_file_type" VALUES('heic','Images');
INSERT INTO "cm_file_type" VALUES('gif','Images');
INSERT INTO "cm_file_type" VALUES('tiff','Images');
INSERT INTO "cm_file_type" VALUES('webp','Images');
INSERT INTO "cm_file_type" VALUES('raw','Images');
INSERT INTO "cm_file_type" VALUES('psd','Images');
INSERT INTO "cm_file_type" VALUES('mp4','Videos');
INSERT INTO "cm_file_type" VALUES('mov','Videos');
INSERT INTO "cm_file_type" VALUES('avi','Videos');
INSERT INTO "cm_file_type" VALUES('mkv','Videos');
INSERT INTO "cm_file_type" VALUES('m4v','Videos');
INSERT INTO "cm_file_type" VALUES('mp3','Audio');
INSERT INTO "cm_file_type" VALUES('m4a','Audio');
INSERT INTO "cm_file_type" VALUES('wav','Audio');
INSERT INTO "cm_file_type" VALUES('aac','Audio');
INSERT INTO "cm_file_type" VALUES('flac','Audio');
INSERT INTO "cm_file_type" VALUES('zip','Archives');
INSERT INTO "cm_file_type" VALUES('rar','Archives');
INSERT INTO "cm_file_type" VALUES('7z','Archives');
INSERT INTO "cm_file_type" VALUES('tar','Archives');
INSERT INTO "cm_file_type" VALUES('gz','Archives');
INSERT INTO "cm_file_type" VALUES('dmg','Installers');
INSERT INTO "cm_file_type" VALUES('pkg','Installers');
INSERT INTO "cm_file_type" VALUES('iso','Installers');
INSERT INTO "cm_file_type" VALUES('app','Applications');
INSERT INTO "cm_file_type" VALUES('ipa','Applications');
INSERT INTO "cm_global_guard" VALUES('com.apple.dock','protected_bundle');
INSERT INTO "cm_global_guard" VALUES('com.apple.finder','protected_bundle');
INSERT INTO "cm_global_guard" VALUES('com.apple.loginwindow','protected_bundle');
INSERT INTO "cm_global_guard" VALUES('com.apple.systemuiserver','protected_bundle');
INSERT INTO "cm_global_guard" VALUES('/','protected_path');
INSERT INTO "cm_global_guard" VALUES('/Applications','protected_path');
INSERT INTO "cm_global_guard" VALUES('/Library','protected_path');
INSERT INTO "cm_global_guard" VALUES('/Library/Caches','protected_path');
INSERT INTO "cm_global_guard" VALUES('/Library/Logs','protected_path');
INSERT INTO "cm_global_guard" VALUES('/System','protected_path');
INSERT INTO "cm_global_guard" VALUES('/Volumes','protected_path');
INSERT INTO "cm_global_guard" VALUES('/bin','protected_path');
INSERT INTO "cm_global_guard" VALUES('/cores','protected_path');
INSERT INTO "cm_global_guard" VALUES('/opt','protected_path');
INSERT INTO "cm_global_guard" VALUES('/sbin','protected_path');
INSERT INTO "cm_global_guard" VALUES('/usr','protected_path');
INSERT INTO "cm_global_guard" VALUES('~','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/.aws','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/.gnupg','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/.ssh','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Desktop','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Documents','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Downloads','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Application Support','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Caches','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Containers','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Developer','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Group Containers','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Keychains','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Logs','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Mail','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Library/Messages','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Movies','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Music','protected_path');
INSERT INTO "cm_global_guard" VALUES('~/Pictures','protected_path');
INSERT INTO "cm_global_guard" VALUES('/','protected_root');
INSERT INTO "cm_global_guard" VALUES('/Applications','protected_root');
INSERT INTO "cm_global_guard" VALUES('/Library','protected_root');
INSERT INTO "cm_global_guard" VALUES('/Library/Caches','protected_root');
INSERT INTO "cm_global_guard" VALUES('/Library/Logs','protected_root');
INSERT INTO "cm_global_guard" VALUES('/System','protected_root');
INSERT INTO "cm_global_guard" VALUES('/Volumes','protected_root');
INSERT INTO "cm_global_guard" VALUES('/bin','protected_root');
INSERT INTO "cm_global_guard" VALUES('/cores','protected_root');
INSERT INTO "cm_global_guard" VALUES('/opt','protected_root');
INSERT INTO "cm_global_guard" VALUES('/sbin','protected_root');
INSERT INTO "cm_global_guard" VALUES('/usr','protected_root');
INSERT INTO "cm_global_guard" VALUES('~','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Desktop','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Documents','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Downloads','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Library','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Library/Application Support','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Library/Caches','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Library/Containers','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Library/Developer','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Library/Group Containers','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Library/Logs','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Movies','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Music','protected_root');
INSERT INTO "cm_global_guard" VALUES('~/Pictures','protected_root');
INSERT INTO "cm_junk_rule" VALUES('JC.CACHE.USER','app','L1','trash_children_only','active',1,0,NULL,'low','direct_child_of_user_caches AND NOT protected','REASON_CODE_GENERAL_CACHE','junk.cache.user',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.CACHE.CONTAINER','app','L2','trash_children_only','active',0,0,NULL,'low','container_or_group_caches_child AND NOT apple_private','REASON_CODE_GENERAL_CACHE','junk.cache.container',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.ELECTRON.CACHE','app','L1','trash_children_only','active',1,NULL,NULL,'low','app_not_running','REASON_CODE_GENERAL_CACHE','junk.electron.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.ELECTRON.SW','app','L3','read_only','active',0,NULL,NULL,'medium','app_not_running','REASON_CODE_WHITELIST_PROTECTED','junk.electron.serviceWorker',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.BRW.CHROMIUM.CACHE','app','L1','trash_children_only','active',1,NULL,NULL,'low','browser_not_running AND profile_split','REASON_CODE_GENERAL_CACHE','junk.browser.chromium.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.BRW.CHROMIUM.SW','app','L3','read_only','active',0,NULL,NULL,'medium','browser_not_running','REASON_CODE_WHITELIST_PROTECTED','junk.browser.chromium.serviceWorker',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.BRW.SAFARI.CACHE','app','L1','trash_children_only','active',1,0,NULL,'low','browser_not_running','REASON_CODE_GENERAL_CACHE','junk.browser.safari.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.BRW.FIREFOX.CACHE','app','L1','trash_children_only','active',1,NULL,NULL,'low','browser_not_running','REASON_CODE_GENERAL_CACHE','junk.browser.firefox.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.BRW.ARC.CACHE','app','L1','trash_children_only','active',1,NULL,NULL,'low','browser_not_running AND profile_split','REASON_CODE_GENERAL_CACHE','junk.browser.arc.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.BRW.SAFARI','app','L4','read_only','deferred',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.browser.safari',NULL,1);
INSERT INTO "cm_junk_rule" VALUES('JC.LOG.USER','system','L1','trash_children_only','active',1,NULL,NULL,'none',NULL,'REASON_CODE_SYSTEM_LOGS_ASL','junk.log.user',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.LOG.DIAG.USER','system','L1','trash_children_only','active',1,NULL,336,'none',NULL,'REASON_CODE_SYSTEM_LOGS_ASL','junk.log.diag.user',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.CACHE','developer','L2','trash_children_only','active',0,NULL,NULL,'none',NULL,'REASON_CODE_DEV_DERIVED_DATA','junk.xcode.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','developer','L1','trash','active',1,NULL,NULL,'none','workspace_path_missing AND xcode_not_running','REASON_CODE_DEV_DERIVED_DATA','junk.xcode.derived.orphan',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.DERIVED.LIVE','developer','L2','trash','active',0,NULL,NULL,'medium','workspace_path_exists OR plist_missing','REASON_CODE_DEV_DERIVED_DATA','junk.xcode.derived.live',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.DEVICESUPPORT','developer','L2','trash','active',0,NULL,NULL,'high','not_latest_per_platform','REASON_CODE_DEV_DERIVED_DATA','junk.xcode.deviceSupport',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.DEVICESUPPORT.LATEST','developer','L3','read_only','active',0,NULL,NULL,'high','latest_per_platform','REASON_CODE_WHITELIST_PROTECTED','junk.xcode.deviceSupport.latest',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.ARCHIVES','developer','L3','read_only','active',0,NULL,NULL,'high','xcode_not_running','REASON_CODE_WHITELIST_PROTECTED','junk.xcode.archives',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.SIMULATOR','developer','L3','read_only','active',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.xcode.simulator',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.SIMCTL.RUNTIME','developer','L2','native','deferred',0,NULL,NULL,'high','state_ready AND deletable AND no_booted_device','REASON_CODE_MANUAL_REVIEW','junk.xcode.simctl',NULL,1);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.NPM.LOGS','developer','L1','trash_children_only','active',1,NULL,NULL,'none',NULL,'REASON_CODE_SYSTEM_LOGS_ASL','junk.dev.npm.logs',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.NPM.CACACHE','developer','L2','trash_children_only','active',0,0,NULL,'low',NULL,'REASON_CODE_PKG_MANAGER_CACHE','junk.dev.npm.cacache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.PKG.SAFE','developer','L2','trash_children_only','active',0,0,NULL,'low',NULL,'REASON_CODE_PKG_MANAGER_CACHE','junk.dev.pkg.safe',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.PKG.L2','developer','L2','trash_children_only','active',0,NULL,NULL,'medium',NULL,'REASON_CODE_PKG_MANAGER_CACHE','junk.dev.pkg',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.GRADLE.DAEMON','developer','L1','trash_children_only','active',1,0,NULL,'low','daemon_not_running','REASON_CODE_PKG_MANAGER_CACHE','junk.dev.gradle.daemon',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.BREW.DOWNLOADS','developer','L2','trash_children_only','active',0,NULL,NULL,'none',NULL,'REASON_CODE_PKG_MANAGER_CACHE','junk.dev.brew.downloads',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.BREW.CACHE','developer','L2','trash_children_only','active',0,0,NULL,'low','not_downloads_subdir','REASON_CODE_PKG_MANAGER_CACHE','junk.dev.brew.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.PKG.UNVERIFIED','developer','L2','trash_children_only','active',0,NULL,NULL,'medium',NULL,'REASON_CODE_PKG_MANAGER_CACHE','junk.dev.pkg.unverified',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.PROJECT','developer','L2','trash','active',0,NULL,NULL,'high','manifest_and_git_and_sensitive_ok AND cwd_not_inside AND stale_by_git','REASON_CODE_MANUAL_REVIEW','junk.dev.project',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.IM.WECHAT.CACHE','communication','L2','trash_children_only','active',0,0,NULL,'low','wechat_not_running','REASON_CODE_GENERAL_CACHE','junk.im.wechat.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.IM.WECHAT.MEDIA','communication','L3','read_only','active',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.im.wechat.media',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.IM.QQ','communication','L3','read_only','active',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.im.qq',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.IM.WECOM','communication','L3','read_only','active',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.im.wecom',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.IM.TELEGRAM.MEDIA','communication','L3','read_only','active',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.im.telegram.media',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.IM.MEET','communication','L2','trash_children_only','active',0,0,NULL,'low','app_not_running','REASON_CODE_GENERAL_CACHE','junk.im.meet',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.IDE.CACHE','ai','L1','trash_children_only','active',1,NULL,NULL,'low','app_not_running','REASON_CODE_GENERAL_CACHE','junk.ai.ide.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.TOOL.CACHE','ai','L2','trash_children_only','active',0,0,NULL,'low',NULL,'REASON_CODE_GENERAL_CACHE','junk.ai.tool.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.WORKTREE','ai','L3','read_only','active',0,NULL,NULL,'medium','worktree_list_missing AND no_process','REASON_CODE_WHITELIST_PROTECTED','junk.ai.worktree',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.OLLAMA.ORPHAN','ai','L3','read_only','active',0,NULL,NULL,'none','blob_refcount_zero','REASON_CODE_WHITELIST_PROTECTED','junk.ai.ollama.orphan',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.OLLAMA.MODEL','storage','L3','read_only','active',0,NULL,NULL,'high','referenced_by_manifest','REASON_CODE_WHITELIST_PROTECTED','junk.ai.ollama.model',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.HF.MODEL','storage','L2','trash','active',0,NULL,NULL,'high','one_row_per_model','REASON_CODE_MANUAL_REVIEW','junk.ai.hf.model',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.LMSTUDIO','storage','L3','read_only','active',0,NULL,NULL,'high','one_row_per_model','REASON_CODE_WHITELIST_PROTECTED','junk.ai.lmstudio',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.GEMINI.TMP','ai','L2','trash_children_only','active',0,NULL,NULL,'medium',NULL,'REASON_CODE_MANUAL_REVIEW','junk.ai.gemini.tmp',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DSG.ADOBE.CACHE','design','L2','trash','active',0,0,NULL,'low','app_not_running','REASON_CODE_GENERAL_CACHE','junk.design.adobe.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DSG.ADOBE.MEDIACACHE','design','L2','trash_children_only','active',0,0,NULL,'low','premiere_or_ae_not_running','REASON_CODE_GENERAL_CACHE','junk.design.adobe.mediaCache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DSG.FCP','design','L4','read_only','deferred',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.design.fcp',NULL,1);
INSERT INTO "cm_junk_rule" VALUES('JC.DSG.JIANYING.CACHE','design','L2','trash','active',0,0,NULL,'low',NULL,'REASON_CODE_GENERAL_CACHE','junk.design.jianying.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.LEFTOVER.ORPHAN','leftovers','L2','trash','active',0,NULL,NULL,'low','orphan_app_uninstalled_and_volatile_root','REASON_CODE_GENERAL_CACHE','junk.leftover.orphan',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.TMP.DARWIN','system','L2','trash_children_only','active',0,0,72,'none','confstr_user_temp AND regular_file AND no_open_handle','REASON_CODE_GENERAL_CACHE','junk.system.darwinTemp',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.CACHE.DARWIN','system','L2','trash_children_only','active',0,0,168,'low','confstr_user_cache AND regular_file AND no_open_handle','REASON_CODE_GENERAL_CACHE','junk.system.darwinCache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.PLIST.BROKEN','system','L2','trash','active',0,0,24,'low','plutil_lint_failed AND not_in_use','REASON_CODE_GENERAL_CACHE','junk.system.plist',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.SAVEDSTATE','system','L3','read_only','active',0,NULL,NULL,'low',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.system.savedState',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.DMG.INSTALLED','system','L2','trash','active',0,NULL,168,'none','normalized_name_matches_installed_app','REASON_CODE_MANUAL_REVIEW','junk.system.diskImage.installed',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.DMG.OTHER','system','L2','trash','active',0,NULL,NULL,'medium','not_installed OR younger_than_7d','REASON_CODE_MANUAL_REVIEW','junk.system.diskImage.other',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.IPSW','system','L2','trash','active',0,NULL,NULL,'high','not_open','REASON_CODE_MANUAL_REVIEW','junk.system.ipsw',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.IOS.BACKUP','storage','L3','read_only','active',0,NULL,NULL,'high','not_latest_backup','REASON_CODE_WHITELIST_PROTECTED','junk.system.iosBackup',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.QUARANTINE','system','L4','read_only','rejected',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.system.quarantine',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.MAIL','system','L4','read_only','rejected',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.system.mail',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.VARLOG','system','L4','read_only','rejected',0,NULL,NULL,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junk.system.varlog',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.MEDIA.SPOTIFY','app','L3','read_only','active',0,0,NULL,'low','app_not_running','REASON_CODE_WHITELIST_PROTECTED','junk.media.spotify',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.PUB.ASSET','developer','L3','read_only','active',0,0,0,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junkProtectedPubCacheTitle',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.JETBRAINS.CACHE','developer','L2','trash_children_only','active',0,0,0,'medium','app_not_running','REASON_CODE_MANUAL_REVIEW','junkJetBrainsCacheTitle',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.MEDIA.SPOTIFY.CACHE','app','L3','read_only','active',0,0,0,'high',NULL,'REASON_CODE_WHITELIST_PROTECTED','junkProtectedSpotifyCacheTitle',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.SYS.APPSTORE.CACHE','system','L2','trash_children_only','active',0,0,0,'low','app_not_running','REASON_CODE_GENERAL_CACHE','junkAppStoreCacheTitle',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.BRW.AUTOMATION.CACHE','developer','L2','trash','active',0,0,NULL,'low',NULL,'REASON_CODE_GENERAL_CACHE','junk.dev.pkg.safe',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.APP.LARK.CACHE','app','L2','trash','active',0,0,NULL,'low',NULL,'REASON_CODE_GENERAL_CACHE','junk.app.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.MEDIA.NETEASE.CACHE','app','L2','trash_children_only','active',0,0,NULL,'low',NULL,'REASON_CODE_GENERAL_CACHE','junk.app.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.BROWSER.DOWNLOAD','developer','L2','trash','active',0,0,168,'medium',NULL,'REASON_CODE_GENERAL_CACHE','junk.dev.pkg',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.AI.OLDVERSION','ai','L2','trash','active',0,0,168,'medium',NULL,'REASON_CODE_GENERAL_CACHE','junk.ai.tool.cache',NULL,0);
INSERT INTO "cm_junk_rule" VALUES('JC.DEV.XCODE.SYSTEM.CACHE','developer','L3','read_only','active',0,0,NULL,'low',NULL,'REASON_CODE_MANUAL_REVIEW','junk.xcode.cache',NULL,0);
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.ELECTRON.CACHE','User/workspaceStorage');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.ELECTRON.CACHE','User/globalStorage');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.ELECTRON.CACHE','mcp.json');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.ELECTRON.CACHE','IndexedDB');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.ELECTRON.CACHE','Local Storage');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.BRW.FIREFOX.CACHE','places.sqlite');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.IM.WECHAT.MEDIA','MM.sqlite');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.IM.WECHAT.MEDIA','WCDB_Contact.sqlite');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.IM.WECHAT.MEDIA','ChatPackage');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.IM.TELEGRAM.MEDIA','postbox/db');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.IM.MEET','~/Documents/Zoom');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.IM.MEET','~/Documents/WeMeet');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.AI.IDE.CACHE','User/workspaceStorage');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.AI.IDE.CACHE','User/globalStorage');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.AI.IDE.CACHE','mcp.json');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.AI.IDE.CACHE','IndexedDB');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.AI.IDE.CACHE','Local Storage');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.AI.HF.MODEL','token');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','ModuleCache.noindex');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.DEV.BREW.CACHE','downloads');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.SYS.PLIST.BROKEN','com.apple.');
INSERT INTO "cm_junk_rule_exclude" VALUES('JC.CACHE.USER','JetBrains');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.CHROMIUM.CACHE','bundle_id','com.google.Chrome');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.CHROMIUM.CACHE','bundle_id','com.brave.Browser');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.CHROMIUM.CACHE','bundle_id','com.microsoft.edgemac');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.CHROMIUM.CACHE','bundle_id','com.vivaldi.Vivaldi');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.CHROMIUM.CACHE','bundle_id','com.operasoftware.Opera');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.CHROMIUM.CACHE','bundle_id','org.chromium.Chromium');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.CHROMIUM.SW','bundle_id','com.google.Chrome');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.SAFARI.CACHE','bundle_id','com.apple.Safari');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.FIREFOX.CACHE','bundle_id','org.mozilla.firefox');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.BRW.ARC.CACHE','bundle_id','company.thebrowser.Browser');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.ELECTRON.CACHE','bundle_id','{bundleID}');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.AI.IDE.CACHE','bundle_id','{bundleID}');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.IM.WECHAT.CACHE','bundle_id','com.tencent.xinWeChat');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.IM.WECHAT.MEDIA','bundle_id','com.tencent.xinWeChat');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.IM.TELEGRAM.MEDIA','bundle_id','ru.keepcoder.Telegram');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.IM.TELEGRAM.MEDIA','bundle_id','org.telegram.desktop');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.IM.MEET','bundle_id','com.tencent.meeting');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.IM.MEET','bundle_id','us.zoom.xos');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.MEDIA.SPOTIFY','bundle_id','com.spotify.client');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.CACHE','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.LIVE','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.ARCHIVES','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DSG.ADOBE.MEDIACACHE','process_name','Adobe Premiere Pro');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DSG.ADOBE.MEDIACACHE','process_name','Adobe After Effects');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.GRADLE.DAEMON','process_name','GradleDaemon');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.BREW.CACHE','process_name','brew');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.BREW.DOWNLOADS','process_name','brew');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.NPM.CACACHE','process_name','npm');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.NPM.CACACHE','process_name','pnpm');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.NPM.CACACHE','process_name','yarn');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.NPM.CACACHE','process_name','node');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','GradleDaemon');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','gradle');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','java');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','kotlin');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','npm');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','pnpm');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','yarn');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','node');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','bun');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','cargo');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','rustc');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','rustup');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','go');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','pip');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','pip3');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','uv');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','conda');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','pod');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','swift');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.SAFE','process_name','xcodebuild');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.L2','process_name','mvn');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.L2','process_name','dotnet');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.L2','process_name','java');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.L2','process_name','cargo');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.PKG.L2','process_name','conda');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','idea');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','pycharm');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','webstorm');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','goland');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','clion');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','rider');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','datagrip');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','phpstorm');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','rubymine');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','rustrover');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.JETBRAINS.CACHE','process_name','java');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.MEDIA.SPOTIFY.CACHE','bundle_id','com.spotify.client');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.MEDIA.SPOTIFY.CACHE','process_name','Spotify');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.SYS.APPSTORE.CACHE','bundle_id','com.apple.AppStore');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.SYS.APPSTORE.CACHE','process_name','storedownloadd');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','process_name','xcodebuild');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','process_name','swift');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','process_name','swift-frontend');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','process_name','clang');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','process_name','clang++');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN','process_name','ibtool');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DEVICESUPPORT','bundle_id','com.apple.dt.Xcode');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DEVICESUPPORT','process_name','xcodebuild');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DEVICESUPPORT','process_name','swift');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DEVICESUPPORT','process_name','swift-frontend');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DEVICESUPPORT','process_name','clang');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DEVICESUPPORT','process_name','clang++');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DEVICESUPPORT','process_name','ibtool');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.CACHE','process_name','xcodebuild');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.CACHE','process_name','swift');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.CACHE','process_name','swift-frontend');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.CACHE','process_name','clang');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.CACHE','process_name','clang++');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.CACHE','process_name','ibtool');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.LIVE','process_name','xcodebuild');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.LIVE','process_name','swift');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.LIVE','process_name','swift-frontend');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.LIVE','process_name','clang');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.LIVE','process_name','clang++');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DEV.XCODE.DERIVED.LIVE','process_name','ibtool');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DSG.JIANYING.CACHE','process_name','JianyingPro');
INSERT INTO "cm_junk_rule_lock" VALUES('JC.DSG.JIANYING.CACHE','bundle_id','com.lemon.lv');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.apple.','system');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.nssurge.','vpn');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.west2online.ClashX','vpn');
INSERT INTO "cm_launchd_protected_prefix" VALUES('io.github.clash-verge-rev','vpn');
INSERT INTO "cm_launchd_protected_prefix" VALUES('io.tailscale.','vpn');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.wireguard.','vpn');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.cisco.','vpn');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.paloaltonetworks.','vpn');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.crowdstrike.','edr');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.sentinelone.','edr');
INSERT INTO "cm_launchd_protected_prefix" VALUES('com.jamf.','mdm');
INSERT INTO "cm_mail_client" VALUES('com.microsoft.Outlook','Outlook','exact','third_party',1,0,1,1);
INSERT INTO "cm_mail_client" VALUES('org.mozilla.thunderbird','Thunderbird','exact','third_party',1,0,1,1);
INSERT INTO "cm_mail_client" VALUES('com.readdle.smartemail-Mac','Spark','exact','third_party',1,0,1,1);
INSERT INTO "cm_mail_client" VALUES('com.readdle.SparkDesktop','Spark','exact','third_party',1,0,1,1);
INSERT INTO "cm_mail_client" VALUES('it.bloop.airmail','Airmail','prefix','third_party',1,0,1,1);
INSERT INTO "cm_mail_client" VALUES('com.tencent.Foxmail','Foxmail','exact','third_party',1,0,1,1);
INSERT INTO "cm_mail_client" VALUES('com.apple.mail','Mail','exact','system',0,0,1,1);
INSERT INTO "cm_name_collision" VALUES('git');
INSERT INTO "cm_name_collision" VALUES('node');
INSERT INTO "cm_name_collision" VALUES('npm');
INSERT INTO "cm_name_collision" VALUES('pnpm');
INSERT INTO "cm_name_collision" VALUES('yarn');
INSERT INTO "cm_name_collision" VALUES('bun');
INSERT INTO "cm_name_collision" VALUES('python');
INSERT INTO "cm_name_collision" VALUES('pip');
INSERT INTO "cm_name_collision" VALUES('uv');
INSERT INTO "cm_name_collision" VALUES('conda');
INSERT INTO "cm_name_collision" VALUES('cargo');
INSERT INTO "cm_name_collision" VALUES('rustup');
INSERT INTO "cm_name_collision" VALUES('go');
INSERT INTO "cm_name_collision" VALUES('java');
INSERT INTO "cm_name_collision" VALUES('ruby');
INSERT INTO "cm_name_collision" VALUES('brew');
INSERT INTO "cm_name_collision" VALUES('nvim');
INSERT INTO "cm_name_collision" VALUES('kubectl');
INSERT INTO "cm_name_collision" VALUES('docker');
INSERT INTO "cm_name_collision" VALUES('colima');
INSERT INTO "cm_name_collision" VALUES('ollama');
INSERT INTO "cm_name_collision" VALUES('claude');
INSERT INTO "cm_name_collision" VALUES('ffmpeg');
INSERT INTO "cm_name_collision" VALUES('postgres');
INSERT INTO "cm_name_collision" VALUES('redis');
INSERT INTO "cm_organize_path" VALUES('.git','exclude_component');
INSERT INTO "cm_organize_path" VALUES('node_modules','exclude_component');
INSERT INTO "cm_organize_path" VALUES('.Trash','exclude_component');
INSERT INTO "cm_organize_path" VALUES('DerivedData','exclude_component');
INSERT INTO "cm_organize_path" VALUES('Pods','exclude_component');
INSERT INTO "cm_organize_path" VALUES('target','exclude_component');
INSERT INTO "cm_organize_path" VALUES('.build','exclude_component');
INSERT INTO "cm_organize_path" VALUES('Downloads','installer_root');
INSERT INTO "cm_organize_path" VALUES('Desktop','installer_root');
INSERT INTO "cm_organize_path" VALUES('Library/Caches/Homebrew/downloads','installer_root');
INSERT INTO "cm_package_extension" VALUES('app');
INSERT INTO "cm_package_extension" VALUES('framework');
INSERT INTO "cm_package_extension" VALUES('photoslibrary');
INSERT INTO "cm_package_extension" VALUES('xcodeproj');
INSERT INTO "cm_package_extension" VALUES('xcworkspace');
INSERT INTO "cm_package_extension" VALUES('xcarchive');
INSERT INTO "cm_package_extension" VALUES('bundle');
INSERT INTO "cm_package_extension" VALUES('plugin');
INSERT INTO "cm_package_extension" VALUES('kext');
INSERT INTO "cm_package_extension" VALUES('qlgenerator');
INSERT INTO "cm_package_extension" VALUES('mdimporter');
INSERT INTO "cm_package_extension" VALUES('appex');
INSERT INTO "cm_package_extension" VALUES('xpc');
INSERT INTO "cm_package_extension" VALUES('playground');
INSERT INTO "cm_package_extension" VALUES('doccarchive');
INSERT INTO "cm_package_extension" VALUES('saver');
INSERT INTO "cm_performance_task" VALUES('quickLookCache','allowed',0,1,'safe',1,'缩略图缓存走废纸篓，回执用前后体积差');
INSERT INTO "cm_performance_task" VALUES('flushDNS','allowed',1,0,'safe',1,'AdminBatch，不虚构释放量');
INSERT INTO "cm_performance_task" VALUES('thinTimeMachine','allowed',1,0,'caution',0,'默认关。上限 20 GB。备份进行中跳过。三口径回执。失败不得按可用空间变大判成功');
INSERT INTO "cm_performance_task" VALUES('purgeableSpace','allowed',1,0,'caution',0,'与 thinTimeMachine 同一口径，禁止写大文件逼回收');
INSERT INTO "cm_performance_task" VALUES('clearDiskCache','allowed',1,0,'caution',1,'原 purge。不得称释放内存。默认关，不进智能推荐');
INSERT INTO "cm_performance_task" VALUES('reindexSpotlight','allowed',1,0,'disruptive',0,'默认关。先 mdutil -s /。说明重建可能持续数小时');
INSERT INTO "cm_performance_task" VALUES('disableDSStore','allowed',0,0,'caution',1,'持久设置，默认关，必须可撤销');
INSERT INTO "cm_performance_task" VALUES('savedStateCleanup','allowed',0,0,'safe',1,'超过 30 天且 App 未运行才允许移入废纸篓。默认关');
INSERT INTO "cm_performance_task" VALUES('fixBrokenPrefs','allowed',0,0,'caution',1,'跳过 com.apple.* 与运行中的 App。走废纸篓');
INSERT INTO "cm_performance_task" VALUES('restartFinder','allowed',0,0,'disruptive',1,'单独确认');
INSERT INTO "cm_performance_task" VALUES('restartDock','allowed',0,0,'disruptive',1,'单独确认');
INSERT INTO "cm_performance_task" VALUES('restartAppleInputMethod','allowed',0,0,'disruptive',1,'仅 Apple 输入法进程，SIGTERM。不代杀第三方输入法');
INSERT INTO "cm_performance_task" VALUES('vacuumDatabases','disabled',0,0,'caution',0,'允许名单为空。浏览器库、CloudTabs、Firefox places 永久不准入');
INSERT INTO "cm_performance_task" VALUES('freeRAM','forbidden',0,0,'forbidden',0,'不得以释放内存为名恢复。DNA 口径未改前 UI 也不承诺释放内存');
INSERT INTO "cm_performance_task" VALUES('quarantineCleanup','forbidden',0,0,'forbidden',0,'DNA 禁令邻域：下载痕迹');
INSERT INTO "cm_performance_task" VALUES('coreduetCleanup','forbidden',0,0,'forbidden',0,'使用痕迹');
INSERT INTO "cm_performance_task" VALUES('notificationCleanup','forbidden',0,0,'forbidden',0,'通知痕迹');
INSERT INTO "cm_performance_task" VALUES('diskPermissionsRepair','forbidden',0,0,'forbidden',0,'diskutil resetUserPermissions 风险高于收益');
INSERT INTO "cm_performance_task" VALUES('rebuildLaunchServicesKill','forbidden',0,0,'forbidden',0,'lsregister -kill -r 会清空打开方式');
INSERT INTO "cm_performance_task" VALUES('killallInputMethod','forbidden',0,0,'forbidden',0,'禁止 killall -9');
INSERT INTO "cm_performance_task" VALUES('writeFileToPurge','forbidden',0,0,'forbidden',0,'禁止写大文件逼系统回收 purgeable');
INSERT INTO "cm_project_artifact" VALUES('.astro',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.build',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.cache',1,1,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.dart_tool',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.docusaurus',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.godot',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.gradle',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.import',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.mypy_cache',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.next',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.nuxt',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.output',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.parcel-cache',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.pytest_cache',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.ruff_cache',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.sass-cache',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.serverless',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.svelte-kit',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.swiftpm',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.terraform',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.tox',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.turbo',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.venv',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('.vite',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('DerivedData',1,0,'disabled');
INSERT INTO "cm_project_artifact" VALUES('Pods',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('__pycache__',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('bin',0,0,'dotnet_project');
INSERT INTO "cm_project_artifact" VALUES('build',1,1,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('cmake-build-debug',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('cmake-build-release',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('coverage',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('dist',1,1,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('env',0,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('node_modules',1,0,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('obj',1,1,'dotnet_project');
INSERT INTO "cm_project_artifact" VALUES('out',1,1,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('target',1,1,'parent_any');
INSERT INTO "cm_project_artifact" VALUES('venv',1,0,'parent_any');
INSERT INTO "cm_project_artifact_proof" VALUES('.astro','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.build','Package.swift');
INSERT INTO "cm_project_artifact_proof" VALUES('.cache','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.dart_tool','pubspec.yaml');
INSERT INTO "cm_project_artifact_proof" VALUES('.docusaurus','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.godot','project.godot');
INSERT INTO "cm_project_artifact_proof" VALUES('.gradle','build.gradle');
INSERT INTO "cm_project_artifact_proof" VALUES('.gradle','build.gradle.kts');
INSERT INTO "cm_project_artifact_proof" VALUES('.gradle','settings.gradle');
INSERT INTO "cm_project_artifact_proof" VALUES('.import','project.godot');
INSERT INTO "cm_project_artifact_proof" VALUES('.mypy_cache','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('.mypy_cache','mypy.ini');
INSERT INTO "cm_project_artifact_proof" VALUES('.next','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.nuxt','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.output','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.parcel-cache','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.pytest_cache','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('.pytest_cache','pytest.ini');
INSERT INTO "cm_project_artifact_proof" VALUES('.ruff_cache','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('.ruff_cache','ruff.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('.ruff_cache','.ruff.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('.sass-cache','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.sass-cache','Gemfile');
INSERT INTO "cm_project_artifact_proof" VALUES('.serverless','serverless.yml');
INSERT INTO "cm_project_artifact_proof" VALUES('.serverless','serverless.yaml');
INSERT INTO "cm_project_artifact_proof" VALUES('.svelte-kit','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.swiftpm','Package.swift');
INSERT INTO "cm_project_artifact_proof" VALUES('.terraform','main.tf');
INSERT INTO "cm_project_artifact_proof" VALUES('.terraform','versions.tf');
INSERT INTO "cm_project_artifact_proof" VALUES('.terraform','providers.tf');
INSERT INTO "cm_project_artifact_proof" VALUES('.tox','tox.ini');
INSERT INTO "cm_project_artifact_proof" VALUES('.tox','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('.turbo','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('.venv','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('.venv','requirements.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('.venv','setup.py');
INSERT INTO "cm_project_artifact_proof" VALUES('.venv','Pipfile');
INSERT INTO "cm_project_artifact_proof" VALUES('.vite','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('Pods','Podfile');
INSERT INTO "cm_project_artifact_proof" VALUES('__pycache__','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('__pycache__','requirements.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('__pycache__','setup.py');
INSERT INTO "cm_project_artifact_proof" VALUES('__pycache__','Pipfile');
INSERT INTO "cm_project_artifact_proof" VALUES('build','CMakeLists.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('build','build.gradle');
INSERT INTO "cm_project_artifact_proof" VALUES('build','build.gradle.kts');
INSERT INTO "cm_project_artifact_proof" VALUES('build','pubspec.yaml');
INSERT INTO "cm_project_artifact_proof" VALUES('cmake-build-debug','CMakeLists.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('cmake-build-release','CMakeLists.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('coverage','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('coverage','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('dist','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('dist','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('env','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('env','requirements.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('env','setup.py');
INSERT INTO "cm_project_artifact_proof" VALUES('env','Pipfile');
INSERT INTO "cm_project_artifact_proof" VALUES('node_modules','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('out','package.json');
INSERT INTO "cm_project_artifact_proof" VALUES('out','CMakeLists.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('target','Cargo.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('target','pom.xml');
INSERT INTO "cm_project_artifact_proof" VALUES('venv','pyproject.toml');
INSERT INTO "cm_project_artifact_proof" VALUES('venv','requirements.txt');
INSERT INTO "cm_project_artifact_proof" VALUES('venv','setup.py');
INSERT INTO "cm_project_artifact_proof" VALUES('venv','Pipfile');
INSERT INTO "cm_project_manifest" VALUES('package.json');
INSERT INTO "cm_project_manifest" VALUES('tsconfig.json');
INSERT INTO "cm_project_manifest" VALUES('Cargo.toml');
INSERT INTO "cm_project_manifest" VALUES('go.mod');
INSERT INTO "cm_project_manifest" VALUES('CMakeLists.txt');
INSERT INTO "cm_project_manifest" VALUES('Makefile');
INSERT INTO "cm_project_manifest" VALUES('pom.xml');
INSERT INTO "cm_project_manifest" VALUES('build.gradle');
INSERT INTO "cm_project_manifest" VALUES('build.gradle.kts');
INSERT INTO "cm_project_manifest" VALUES('settings.gradle');
INSERT INTO "cm_project_manifest" VALUES('setup.py');
INSERT INTO "cm_project_manifest" VALUES('pyproject.toml');
INSERT INTO "cm_project_manifest" VALUES('requirements.txt');
INSERT INTO "cm_project_manifest" VALUES('Pipfile');
INSERT INTO "cm_project_manifest" VALUES('Package.swift');
INSERT INTO "cm_project_manifest" VALUES('pubspec.yaml');
INSERT INTO "cm_project_manifest" VALUES('.git');
INSERT INTO "cm_project_scan_root" VALUES('~/Projects');
INSERT INTO "cm_project_scan_root" VALUES('~/Developer');
INSERT INTO "cm_project_scan_root" VALUES('~/Workspace');
INSERT INTO "cm_project_scan_root" VALUES('~/Development');
INSERT INTO "cm_project_scan_root" VALUES('~/src');
INSERT INTO "cm_project_scan_root" VALUES('~/code');
INSERT INTO "cm_protected_path" VALUES('DNA.CLOUD.MOBILE_DOCS','~/Library/Mobile Documents','prefix','dna_cloud');
INSERT INTO "cm_protected_path" VALUES('DNA.CLOUD.CLOUDSTORAGE','~/Library/CloudStorage','prefix','dna_cloud');
INSERT INTO "cm_protected_path" VALUES('DNA.CLOUD.DROPBOX','~/Dropbox','prefix','dna_cloud');
INSERT INTO "cm_protected_path" VALUES('DNA.CLOUD.ONEDRIVE','~/OneDrive','prefix','dna_cloud');
INSERT INTO "cm_protected_path" VALUES('DNA.CLOUD.FILEPROVIDER','~/Library/Application Support/FileProvider','prefix','dna_cloud');
INSERT INTO "cm_protected_path" VALUES('DNA.MAIL.APPLE','~/Library/Containers/com.apple.mail','prefix','dna_mail');
INSERT INTO "cm_protected_path" VALUES('DNA.MAIL.MAILDIR','~/Library/Mail','prefix','dna_mail');
INSERT INTO "cm_protected_path" VALUES('DNA.MAIL.DOWNLOADS','Mail Downloads','marker','dna_mail');
INSERT INTO "cm_protected_path" VALUES('DNA.KEYCHAIN','~/Library/Keychains','prefix','credential');
INSERT INTO "cm_protected_path" VALUES('DNA.TCC','com.apple.TCC/TCC.db','marker','tcc');
INSERT INTO "cm_protected_path" VALUES('DNA.PHOTOS','.photoslibrary','suffix','photos');
INSERT INTO "cm_protected_path" VALUES('CRED.SSH','~/.ssh','prefix','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.GNUPG','~/.gnupg','prefix','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.AWS','~/.aws','prefix','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.KUBE','~/.kube','prefix','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.DOCKER','~/.docker/config.json','exact','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.NPMRC','~/.npmrc','exact','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.NETRC','~/.netrc','exact','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.GITCONFIG','~/.gitconfig','exact','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.ZSH_HISTORY','~/.zsh_history','exact','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.BASH_HISTORY','~/.bash_history','exact','credential');
INSERT INTO "cm_protected_path" VALUES('CRED.HF_TOKEN','~/.cache/huggingface/token','exact','credential');
INSERT INTO "cm_protected_path" VALUES('DENY.COOKIES','Cookies','marker','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.LOGIN_DATA','Login Data','marker','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.WEB_DATA','Web Data','marker','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.HISTORY','History','marker','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.BOOKMARKS','Bookmarks','marker','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.LOCAL_STORAGE','Local Storage','marker','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.INDEXEDDB','IndexedDB','marker','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.BINARYCOOKIES','.binarycookies','suffix','dna_session');
INSERT INTO "cm_protected_path" VALUES('DENY.APP_INTERIOR','.app/','marker','code_signature');
INSERT INTO "cm_protected_path" VALUES('DENY.LPROJ','.lproj','suffix','code_signature');
INSERT INTO "cm_protected_path" VALUES('DENY.VM_PVM','.pvm','suffix','vm_disk');
INSERT INTO "cm_protected_path" VALUES('DENY.VM_VMWARE','.vmwarevm','suffix','vm_disk');
INSERT INTO "cm_protected_path" VALUES('DENY.EAGLE','.library','suffix','eagle_library');
INSERT INTO "cm_protected_path" VALUES('DENY.JIANYING_DRAFT','com.lveditor.draft','marker','jianying_draft');
INSERT INTO "cm_protected_path" VALUES('DENY.SYSTEM','/System','prefix','system');
INSERT INTO "cm_protected_path" VALUES('ROOT.CONFIG','~/.config','exact','config_root');
INSERT INTO "cm_protected_path" VALUES('ROOT.LOCAL','~/.local','exact','config_root');
INSERT INTO "cm_protected_path" VALUES('ROOT.CACHE','~/.cache','exact','config_root');
INSERT INTO "cm_protected_path" VALUES('DENY.KEYCHAIN_PW_EXT','com.apple.passwordmanager.json','marker','keychain_ext');
INSERT INTO "cm_protected_path" VALUES('DENY.STEAM_COMMON','Steam/steamapps/common','marker','steam_library');
INSERT INTO "cm_protected_path" VALUES('DENY.ANDR_AVD','.android/avd','marker','android_vm');
INSERT INTO "cm_protected_path" VALUES('DENY.ANDR_KEYSTORE','debug.keystore','marker','dev_keystore');
INSERT INTO "cm_protected_path" VALUES('DENY.ANDR_ADBKEY','adbkey','marker','dev_keystore');
INSERT INTO "cm_protected_path" VALUES('DENY.IME_INPUTMETHOD','InputMethod','marker','ime_user_dict');
INSERT INTO "cm_protected_path" VALUES('DENY.IME_INPUTMETHODS','Input Methods','marker','ime_user_dict');
INSERT INTO "cm_protected_path" VALUES('DENY.COCOAPODS_REPOS','~/.cocoapods/repos','prefix','cocoapods_repo');
INSERT INTO "cm_protected_path" VALUES('DENY.CURSOR_EXT','~/.cursor/extensions','prefix','ide_extensions');
INSERT INTO "cm_protected_path" VALUES('DENY.VSCODE_EXT','**/.vscode/extensions','marker','ide_extensions');
INSERT INTO "cm_protected_path" VALUES('DENY.WINDSURF_EXT','**/.windsurf/extensions','marker','ide_extensions');
INSERT INTO "cm_protected_path" VALUES('DENY.CLAUDE_VERSIONS','~/.claude/versions','prefix','ai_cli_binary');
INSERT INTO "cm_protected_path" VALUES('DENY.CLAUDE_LOCAL_VERSIONS','~/.local/share/claude/versions','prefix','ai_cli_binary');
INSERT INTO "cm_protected_path" VALUES('DENY.CLAUDE_STATS_STATE','~/.claude/stats-cache.json','exact','ai_cli_state');
INSERT INTO "cm_protected_path" VALUES('DENY.CLAUDE_MCP_AUTH_STATE','~/.claude/mcp-needs-auth-cache.json','exact','ai_cli_state');
INSERT INTO "cm_protected_path" VALUES('DENY.CLAUDE_PLUGIN_STATE','~/.claude/plugins/install-counts-cache.json','exact','ai_cli_state');
INSERT INTO "cm_protected_path" VALUES('JUNK.PUB.ASSET','~/.pub-cache','prefix','user_installed_tools');
INSERT INTO "cm_protected_path" VALUES('JUNK.JETBRAINS.LOCAL_HISTORY','/LocalHistory','suffix','user_local_history');
INSERT INTO "cm_protected_path" VALUES('JUNK.SPOTIFY.CACHE','~/Library/Caches/com.spotify.client','prefix','offline_assets');
INSERT INTO "cm_protected_path" VALUES('JUNK.SPOTIFY.STORAGE','~/Library/Application Support/Spotify/PersistentCache/Storage','prefix','offline_assets');
INSERT INTO "cm_rule_meta" VALUES('schema_version','1');
INSERT INTO "cm_rule_meta" VALUES('min_user_cache_bytes','204800');
INSERT INTO "cm_rule_meta" VALUES('darwin_temp_min_age_hours','72');
INSERT INTO "cm_rule_meta" VALUES('darwin_cache_min_age_hours','168');
INSERT INTO "cm_rule_meta" VALUES('disk_image_installed_min_age_days','7');
INSERT INTO "cm_rule_meta" VALUES('device_support_keep_latest_per_platform','1');
INSERT INTO "cm_rule_meta" VALUES('vacuum_allowlist','empty');
INSERT INTO "cm_rule_meta" VALUES('trash_sentinel','off');
INSERT INTO "cm_rule_meta" VALUES('cache_app_suggestion_bytes','524288000');
INSERT INTO "cm_rule_meta" VALUES('cache_developer_suggestion_bytes','1073741824');
INSERT INTO "cm_rule_meta" VALUES('cache_age_suggestion_enabled','0');
INSERT INTO "cm_rule_meta" VALUES('project_min_age_days','7');
INSERT INTO "cm_rule_meta" VALUES('project_max_depth','4');
INSERT INTO "cm_rule_meta" VALUES('project_manifest_search_depth','3');
INSERT INTO "cm_rule_meta" VALUES('rule_version','1');
INSERT INTO "cm_rule_selection" VALUES('JC.AI.GEMINI.TMP',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.IDE.CACHE',1,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.OLDVERSION',0,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.OLLAMA.ORPHAN',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.TOOL.CACHE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.WORKTREE',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.APP.LARK.CACHE',0,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.BRW.ARC.CACHE',1,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.BRW.CHROMIUM.CACHE',1,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.BRW.CHROMIUM.SW',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.BRW.FIREFOX.CACHE',1,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.BRW.SAFARI',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.BRW.SAFARI.CACHE',1,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.CACHE.CONTAINER',0,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.CACHE.USER',1,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.ELECTRON.CACHE',1,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.ELECTRON.SW',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.MEDIA.NETEASE.CACHE',0,0,1,0);
INSERT INTO "cm_rule_selection" VALUES('JC.MEDIA.SPOTIFY',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.MEDIA.SPOTIFY.CACHE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.IM.MEET',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.IM.QQ',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.IM.TELEGRAM.MEDIA',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.IM.WECHAT.CACHE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.IM.WECHAT.MEDIA',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.IM.WECOM',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.DSG.ADOBE.CACHE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DSG.ADOBE.MEDIACACHE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DSG.FCP',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DSG.JIANYING.CACHE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.BRW.AUTOMATION.CACHE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.BREW.CACHE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.BREW.DOWNLOADS',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.BROWSER.DOWNLOAD',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.GRADLE.DAEMON',1,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.JETBRAINS.CACHE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.NPM.CACACHE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.NPM.LOGS',1,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.PKG.L2',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.PKG.SAFE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.PKG.UNVERIFIED',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.PROJECT',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.PUB.ASSET',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.SIMCTL.RUNTIME',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.ARCHIVES',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.CACHE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.DERIVED.LIVE',0,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.DERIVED.ORPHAN',1,1,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.DEVICESUPPORT',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.DEVICESUPPORT.LATEST',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.SIMULATOR',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.DEV.XCODE.SYSTEM.CACHE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.LEFTOVER.ORPHAN',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.HF.MODEL',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.LMSTUDIO',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.AI.OLLAMA.MODEL',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.IOS.BACKUP',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.LOG.DIAG.USER',1,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.LOG.USER',1,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.APPSTORE.CACHE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.CACHE.DARWIN',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.DMG.INSTALLED',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.DMG.OTHER',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.IPSW',0,0,0,1);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.MAIL',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.PLIST.BROKEN',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.QUARANTINE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.SAVEDSTATE',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.TMP.DARWIN',0,0,0,0);
INSERT INTO "cm_rule_selection" VALUES('JC.SYS.VARLOG',0,0,0,0);
INSERT INTO "cm_service_worker_domain" VALUES('docs.google.com','L2');
INSERT INTO "cm_service_worker_domain" VALUES('drive.google.com','L2');
INSERT INTO "cm_service_worker_domain" VALUES('notion.so','L2');
INSERT INTO "cm_service_worker_domain" VALUES('figma.com','L2');
INSERT INTO "cm_service_worker_domain" VALUES('canva.com','L2');
INSERT INTO "cm_service_worker_domain" VALUES('capcut.com','L2');
INSERT INTO "cm_service_worker_domain" VALUES('jianying.com','L2');
INSERT INTO "cm_service_worker_domain" VALUES('excalidraw.com','L2');
INSERT INTO "cm_service_worker_domain" VALUES('photopea.com','L2');
INSERT INTO "cm_shared_vendor_root" VALUES('Adobe');
INSERT INTO "cm_shared_vendor_root" VALUES('Microsoft');
INSERT INTO "cm_shared_vendor_root" VALUES('Google');
INSERT INTO "cm_shared_vendor_root" VALUES('JetBrains');
INSERT INTO "cm_shared_vendor_root" VALUES('Autodesk');
INSERT INTO "cm_shared_vendor_root" VALUES('Mozilla');
INSERT INTO "cm_shared_vendor_root" VALUES('Atlassian');
INSERT INTO "cm_shared_vendor_root" VALUES('Valve');
INSERT INTO "cm_shared_vendor_root" VALUES('Epic');
INSERT INTO "cm_shared_vendor_root" VALUES('Tencent');
INSERT INTO "cm_shared_vendor_root" VALUES('Alibaba');
INSERT INTO "cm_shared_vendor_root" VALUES('ByteDance');
INSERT INTO "cm_shared_vendor_root" VALUES('Baidu');
INSERT INTO "cm_shared_vendor_root" VALUES('Netease');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_01','{appBundle}','L1','user',1,1,'active','先移走 .app，失败则数据整组跳过');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_05','~/Library/Caches/{bundleID}','L2','user',1,0,'active','精确 Bundle ID 人工确认；不推断兄弟产品所有权');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_02','{DARWIN_USER_CACHE_DIR}/{bundleID}','L2','user',1,0,'active','精确匹配，共享目录不整棵删除');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_12','~/Library/Logs/DiagnosticReports/{appName}-*','L3','user',0,0,'active',NULL);
INSERT INTO "cm_uninstall_template" VALUES('UNINST_LOG','~/Library/Logs/{bundleID}','L2','user',1,0,'active',NULL);
INSERT INTO "cm_uninstall_template" VALUES('UNINST_08','~/Library/HTTPStorages/{bundleID}','L3','session',0,0,'active','仅卸载该 App 且 Bundle ID 精确命中。不含 .binarycookies');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_09','~/Library/WebKit/{bundleID}','L3','session',0,0,'active','会话数据，默认不勾');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_10','~/Library/Saved Application State/{bundleID}.savedState','L3','session',0,0,'active','会话数据，默认不勾');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_13','~/Library/LaunchAgents/{bundleID}*','L3','user',0,0,'active','有边界发现，仅展示；未核实 Label/运行状态前不执行');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_18','~/Library/Containers/{bundleID}','L2','user',1,0,'active','含 {bundleID}. 边界前缀');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_19','~/Library/Group Containers/{appGroupID}','L3','user',0,0,'active','签名 entitlement 仅用于发现；无法证明完整独占时只读');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_20','~/Library/Application Support/{vendor}/{appName}','L3','user',0,0,'active','仅二级精确名称发现；厂商归属未经验证只读');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_23','~/Library/Preferences/{bundleID}.plist','L2','user',1,0,'active','之后用 CFPreferences 刷新，不用 defaults delete');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_24','~/Library/Preferences/ByHost/{bundleID}.*.plist','L3','user',0,0,'active',NULL);
INSERT INTO "cm_uninstall_template" VALUES('UNINST_NAME','{appName}','L2','user',1,0,'active','名称匹配必须过同名 CLI 黑名单与共享厂商下钻');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_07','/Library/Caches/{bundleID}','L3','system',0,0,'active','只展示');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_15','/Library/LaunchDaemons/{bundleID}*','L3','system',0,0,'active','只展示，不 bootout，不计入将释放');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_16','/Library/PrivilegedHelperTools/{bundleID}*','L3','system',0,0,'active','只展示');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_17','/Library/Receipts','L4','system',0,0,'rejected','不删除收据。只读解析 BOM 用来发现文件');
INSERT INTO "cm_uninstall_template" VALUES('UNINST_COOKIES','Cookies/{bundleID}.binarycookies','L4','session',0,0,'rejected','DNA 禁令：不清理 Cookie / 会话');
INSERT INTO "cm_vacuum_forbidden" VALUES('MAIL','~/Library/Mail','dna_mail');
INSERT INTO "cm_vacuum_forbidden" VALUES('MESSAGES','~/Library/Messages/chat.db','system_db');
INSERT INTO "cm_vacuum_forbidden" VALUES('PHOTOS','.photoslibrary/database','photos');
INSERT INTO "cm_vacuum_forbidden" VALUES('NOTES','group.com.apple.notes/NoteStore.sqlite','system_db');
INSERT INTO "cm_vacuum_forbidden" VALUES('SAFARI_HISTORY','History.db','dna_session');
INSERT INTO "cm_vacuum_forbidden" VALUES('KEYCHAIN','~/Library/Keychains','credential');
INSERT INTO "cm_vacuum_forbidden" VALUES('TCC','TCC.db','tcc');
INSERT INTO "cm_vacuum_forbidden" VALUES('CHAT_DB','MM.sqlite','chat');
INSERT INTO "cm_vacuum_forbidden" VALUES('CLOUDTABS','CloudTabs.db','dna_cloud');
INSERT INTO "cm_vacuum_forbidden" VALUES('FIREFOX_PLACES','places.sqlite','bookmarks');
INSERT INTO "cm_vacuum_forbidden" VALUES('CHROME_HISTORY','History','dna_session');
INSERT INTO "cm_vacuum_forbidden" VALUES('CHROME_COOKIES','Cookies','dna_session');
INSERT INTO "cm_vacuum_forbidden" VALUES('CHROME_WEB_DATA','Web Data','dna_session');
INSERT INTO "cm_version_cache" VALUES('JC.DEV.BROWSER.DOWNLOAD','~/.cache/puppeteer/chrome',NULL,'\A(mac|mac_arm|linux|linux_arm|win32|win64)-[0-9]+(?:\.[0-9]+){2,3}\z',2,168,'browser');
INSERT INTO "cm_version_cache" VALUES('JC.DEV.BROWSER.DOWNLOAD','~/.cache/puppeteer/chrome-headless-shell',NULL,'\A(mac|mac_arm|linux|linux_arm|win32|win64)-[0-9]+(?:\.[0-9]+){2,3}\z',2,168,'browser');
INSERT INTO "cm_version_cache" VALUES('JC.AI.OLDVERSION','~/.local/share/cursor-agent/versions','~/.local/bin/cursor-agent','\A[0-9]+(?:\.[0-9]+){1,3}(?:-[A-Za-z0-9._-]+)?\z',2,168,'agent');
INSERT INTO "cm_version_cache" VALUES('JC.AI.OLDVERSION','~/Library/Application Support/Cursor/User/globalStorage/anysphere.cursor-agent-worker/agent-cli/.local/share/cursor-agent/versions','~/Library/Application Support/Cursor/User/globalStorage/anysphere.cursor-agent-worker/agent-cli/.local/bin/cursor-agent','\A[0-9]+(?:\.[0-9]+){1,3}(?:-[A-Za-z0-9._-]+)?\z',2,168,'agent');
INSERT INTO "cm_version_cache" VALUES('JC.AI.OLDVERSION','~/.codex/packages/app-server-daemon/releases','~/.codex/packages/app-server-daemon/current','\A[0-9]+(?:\.[0-9]+){1,3}(?:-[A-Za-z0-9._-]+)?\z',2,168,'agent');
INSERT INTO cm_performance_task VALUES ('fixInputMethod','allowed',0,0,'disruptive',1,'Restart Apple input services');
INSERT INTO cm_performance_task VALUES ('fixNotificationCenter','allowed',0,0,'disruptive',1,'Restart notification services; do not remove notification data');
INSERT INTO cm_performance_task VALUES ('fixClipboardHandoff','allowed',0,0,'disruptive',1,'Restart clipboard and handoff services');
INSERT INTO cm_performance_task VALUES ('fixFinderDock','allowed',0,0,'disruptive',1,'Restart Finder and Dock');
COMMIT;
