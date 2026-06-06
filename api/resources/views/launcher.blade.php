<!DOCTYPE html>
<html lang="en" data-theme="dark">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>🚀 3alamati DevOps Console</title>
    <link
        href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet">
    <style>
        /* Default Dark Blue Theme */
        :root,
        [data-theme="dark"] {
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-card: #334155;
            --bg-terminal: #0c1222;
            --accent-blue: #3b82f6;
            --accent-purple: #8b5cf6;
            --accent-green: #22c55e;
            --accent-red: #ef4444;
            --accent-orange: #f97316;
            --accent-cyan: #06b6d4;
            --text-primary: #f1f5f9;
            --text-secondary: #94a3b8;
            --text-muted: #64748b;
            --border: rgba(148, 163, 184, 0.15);
            --glow-blue: rgba(59, 130, 246, 0.4);
            --glow-green: rgba(34, 197, 94, 0.4);
        }

        /* Darker Theme (Original) */
        [data-theme="darker"] {
            --bg-primary: #0a0a0f;
            --bg-secondary: #12121a;
            --bg-card: #1a1a24;
            --bg-terminal: #0d0d12;
            --accent-blue: #3b82f6;
            --accent-purple: #8b5cf6;
            --accent-green: #22c55e;
            --accent-red: #ef4444;
            --accent-orange: #f97316;
            --accent-cyan: #06b6d4;
            --text-primary: #ffffff;
            --text-secondary: #a1a1aa;
            --text-muted: #71717a;
            --border: rgba(255, 255, 255, 0.08);
            --glow-blue: rgba(59, 130, 246, 0.5);
            --glow-green: rgba(34, 197, 94, 0.5);
        }

        /* Light Theme */
        [data-theme="light"] {
            --bg-primary: #f8fafc;
            --bg-secondary: #ffffff;
            --bg-card: #f1f5f9;
            --bg-terminal: #e2e8f0;
            --accent-blue: #2563eb;
            --accent-purple: #7c3aed;
            --accent-green: #16a34a;
            --accent-red: #dc2626;
            --accent-orange: #ea580c;
            --accent-cyan: #0891b2;
            --text-primary: #0f172a;
            --text-secondary: #475569;
            --text-muted: #64748b;
            --border: rgba(15, 23, 42, 0.1);
            --glow-blue: rgba(37, 99, 235, 0.2);
            --glow-green: rgba(22, 163, 74, 0.2);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            overflow-x: hidden;
            transition: background 0.3s, color 0.3s;
        }

        /* Layout */
        .app {
            display: grid;
            grid-template-columns: 260px 1fr 280px;
            grid-template-rows: auto auto 1fr;
            grid-template-areas:
                "header header header"
                "sidebar summary panel"
                "sidebar terminal panel";
            min-height: 100vh;
            gap: 1px;
            background: var(--border);
        }

        .header {
            grid-area: header;
        }

        .sidebar {
            grid-area: sidebar;
        }

        .main {
            grid-area: terminal;
        }

        .panel {
            grid-area: panel;
        }

        .summary-bar {
            grid-area: summary;
        }

        /* Header */
        .header {
            grid-column: 1 / -1;
            background: var(--bg-secondary);
            padding: 16px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid var(--border);
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .logo-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, var(--accent-blue), var(--accent-purple));
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .logo h1 {
            font-size: 1.25rem;
            font-weight: 700;
        }

        .logo h1 span {
            background: linear-gradient(90deg, var(--accent-blue), var(--accent-purple));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .header-actions {
            display: flex;
            gap: 10px;
        }

        /* Server Control Bar */
        .server-control-bar {
            background: var(--bg-secondary);
            padding: 12px 16px;
            display: flex;
            align-items: center;
            gap: 12px;
            border-bottom: 1px solid var(--border);
        }

        .control-card {
            display: flex;
            align-items: center;
            gap: 10px;
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 8px 12px;
            position: relative;
            transition: all 0.2s;
        }

        .control-card:hover {
            border-color: var(--accent-blue);
        }

        .control-card.running {
            border-color: var(--accent-green);
            box-shadow: 0 0 10px rgba(34, 197, 94, 0.15);
        }

        .control-status {
            position: absolute;
            top: -3px;
            right: -3px;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: var(--text-muted);
            border: 2px solid var(--bg-secondary);
        }

        .control-status.running {
            background: var(--accent-green);
            animation: pulse 2s infinite;
        }

        @keyframes pulse {

            0%,
            100% {
                opacity: 1;
            }

            50% {
                opacity: 0.5;
            }
        }

        .control-icon {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
        }

        .control-info {
            display: flex;
            flex-direction: column;
            min-width: 80px;
        }

        .control-name {
            font-size: 12px;
            font-weight: 600;
            color: var(--text-primary);
        }

        .control-port {
            font-size: 11px;
            font-family: 'JetBrains Mono', monospace;
            color: var(--text-muted);
        }

        .control-buttons {
            display: flex;
            gap: 6px;
        }

        .control-btn {
            width: 28px;
            height: 28px;
            border-radius: 6px;
            border: 1px solid var(--border);
            background: transparent;
            color: var(--text-muted);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
            font-size: 12px;
        }

        .control-btn:hover {
            background: var(--accent-blue);
            border-color: var(--accent-blue);
            color: white;
        }

        .control-toggle {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            border: 1px solid var(--border);
            background: var(--bg-secondary);
            color: var(--text-primary);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
        }

        .control-toggle:hover {
            background: var(--accent-blue);
            border-color: var(--accent-blue);
        }

        .control-toggle.stop:hover {
            background: var(--accent-red);
            border-color: var(--accent-red);
        }

        .control-separator {
            width: 1px;
            height: 40px;
            background: var(--border);
            margin: 0 8px;
        }

        .control-stats {
            display: flex;
            gap: 16px;
            margin-left: auto;
        }

        .stat-item {
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .stat-value {
            font-size: 18px;
            font-weight: 700;
            color: var(--accent-blue);
            font-family: 'JetBrains Mono', monospace;
        }

        .stat-label {
            font-size: 10px;
            color: var(--text-muted);
            text-transform: uppercase;
        }

        /* Sidebar */
        .sidebar {
            background: var(--bg-secondary);
            padding: 16px;
            overflow-y: auto;
        }

        .sidebar-section {
            margin-bottom: 24px;
        }

        .sidebar-title {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-muted);
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Server List */
        .server-list {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .server-item {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 12px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .server-item:hover {
            border-color: var(--accent-blue);
            background: rgba(59, 130, 246, 0.05);
        }

        .server-item.active {
            border-color: var(--accent-blue);
            box-shadow: 0 0 20px var(--glow-blue);
        }

        .server-item-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }

        .server-item-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .server-icon {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
        }

        .server-icon.laravel {
            background: linear-gradient(135deg, #ff2d20, #ff6f61);
        }

        .server-icon.reverb {
            background: linear-gradient(135deg, #8b5cf6, #a855f7);
        }

        .server-icon.flutter {
            background: linear-gradient(135deg, #02569b, #13b9fd);
        }

        .server-name {
            font-size: 13px;
            font-weight: 600;
        }

        .server-port {
            font-size: 11px;
            color: var(--text-muted);
            font-family: 'JetBrains Mono', monospace;
        }

        .status-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: var(--text-muted);
        }

        .status-dot.running {
            background: var(--accent-green);
            box-shadow: 0 0 10px var(--glow-green);
            animation: pulse 2s infinite;
        }

        @keyframes pulse {

            0%,
            100% {
                opacity: 1;
            }

            50% {
                opacity: 0.5;
            }
        }

        .server-actions {
            display: flex;
            gap: 6px;
        }

        /* Main Content - Terminal */
        .main {
            background: var(--bg-primary);
            display: flex;
            flex-direction: column;
        }

        .terminal-header {
            background: var(--bg-secondary);
            padding: 12px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid var(--border);
        }

        .terminal-tabs {
            display: flex;
            gap: 4px;
        }

        .terminal-tab {
            padding: 8px 16px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            background: transparent;
            border: none;
            color: var(--text-secondary);
            display: flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
        }

        .terminal-tab:hover {
            background: var(--bg-card);
            color: var(--text-primary);
        }

        .terminal-tab.active {
            background: var(--accent-blue);
            color: white;
        }

        .terminal-tab .tab-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
        }

        .terminal-controls {
            display: flex;
            gap: 8px;
        }

        .terminal-body {
            flex: 1;
            background: var(--bg-terminal);
            padding: 16px 20px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 13px;
            line-height: 1.6;
            overflow-y: auto;
            position: relative;
        }

        .terminal-body::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 50px;
            background: linear-gradient(to bottom, var(--bg-terminal), transparent);
            pointer-events: none;
            z-index: 1;
        }

        .log-line {
            display: flex;
            margin-bottom: 4px;
        }

        .log-time {
            color: var(--text-muted);
            margin-right: 12px;
            flex-shrink: 0;
        }

        .log-content {
            flex: 1;
        }

        .log-content.info {
            color: var(--accent-cyan);
        }

        .log-content.success {
            color: var(--accent-green);
        }

        .log-content.warning {
            color: var(--accent-orange);
        }

        .log-content.error {
            color: var(--accent-red);
        }

        .log-content.system {
            color: var(--accent-purple);
        }

        /* Right Panel */
        .panel {
            background: var(--bg-secondary);
            padding: 20px;
            overflow-y: auto;
        }

        .panel-section {
            margin-bottom: 24px;
        }

        .panel-title {
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-muted);
            margin-bottom: 12px;
        }

        /* IP Selector */
        .ip-selector {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 12px;
        }

        .ip-current {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
        }

        .ip-value {
            font-family: 'JetBrains Mono', monospace;
            font-size: 14px;
            font-weight: 600;
            color: var(--accent-green);
        }

        .ip-chips {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
        }

        .ip-chip {
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 12px;
            font-family: 'JetBrains Mono', monospace;
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            cursor: pointer;
            transition: all 0.2s;
        }

        .ip-chip:hover {
            border-color: var(--accent-blue);
        }

        .ip-chip.active {
            background: var(--accent-blue);
            border-color: var(--accent-blue);
            color: white;
        }

        /* Theme Toggle Buttons */
        .theme-btn {
            padding: 6px 10px !important;
            background: transparent;
            border: 1px solid transparent;
            border-radius: 6px;
            opacity: 0.6;
            transition: all 0.2s;
        }

        .theme-btn:hover {
            opacity: 1;
            background: var(--bg-secondary);
        }

        .theme-btn.active {
            opacity: 1;
            background: var(--accent-blue);
            border-color: var(--accent-blue);
        }

        /* URL Card */
        .url-card {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 10px 12px;
            margin-bottom: 8px;
        }

        .url-label {
            font-size: 10px;
            color: var(--text-muted);
            text-transform: uppercase;
            margin-bottom: 4px;
        }

        .url-value {
            font-family: 'JetBrains Mono', monospace;
            font-size: 12px;
            color: var(--accent-cyan);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .url-actions {
            display: flex;
            gap: 4px;
        }

        /* Buttons */
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            padding: 8px 16px;
            border: none;
            border-radius: 8px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            font-family: inherit;
        }

        .btn:hover {
            transform: translateY(-1px);
        }

        .btn-primary {
            background: var(--accent-blue);
            color: white;
        }

        .btn-success {
            background: var(--accent-green);
            color: white;
        }

        .btn-danger {
            background: var(--accent-red);
            color: white;
        }

        .btn-ghost {
            background: transparent;
            color: var(--text-secondary);
            border: 1px solid var(--border);
        }

        .btn-ghost:hover {
            background: var(--bg-card);
            color: var(--text-primary);
        }

        .btn-sm {
            padding: 6px 10px;
            font-size: 12px;
        }

        .btn-icon {
            padding: 8px;
            border-radius: 6px;
        }

        /* Input */
        .input {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--border);
            border-radius: 8px;
            background: var(--bg-card);
            color: var(--text-primary);
            font-size: 13px;
            font-family: inherit;
            transition: all 0.2s;
        }

        .input:focus {
            outline: none;
            border-color: var(--accent-blue);
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
        }

        .input-group {
            margin-bottom: 12px;
        }

        .input-label {
            display: block;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            color: var(--text-muted);
            margin-bottom: 6px;
        }

        /* Quick Ref Table */
        .ref-table {
            width: 100%;
            font-size: 11px;
        }

        .ref-table th,
        .ref-table td {
            padding: 6px 8px;
            text-align: left;
        }

        .ref-table th {
            color: var(--text-muted);
            font-weight: 500;
        }

        .ref-table tr:nth-child(even) {
            background: var(--bg-card);
        }

        .badge {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 10px;
            font-weight: 600;
            background: rgba(139, 92, 246, 0.2);
            color: var(--accent-purple);
        }

        /* Toast */
        .toast-container {
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 1000;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .toast {
            padding: 12px 16px;
            border-radius: 8px;
            background: var(--bg-card);
            border: 1px solid var(--border);
            display: flex;
            align-items: center;
            gap: 10px;
            animation: slideIn 0.3s ease;
            font-size: 13px;
        }

        .toast.success {
            border-left: 3px solid var(--accent-green);
        }

        .toast.error {
            border-left: 3px solid var(--accent-red);
        }

        .toast.info {
            border-left: 3px solid var(--accent-blue);
        }

        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }

            to {
                transform: translateX(0);
                opacity: 1;
            }
        }

        @media (max-width: 1200px) {
            .app {
                grid-template-columns: 1fr;
            }

            .sidebar,
            .panel {
                display: none;
            }
        }
    </style>
</head>

<body>
    <div class="app">
        <!-- Header -->
        <header class="header">
            <div class="logo">
                <div class="logo-icon">🚀</div>
                <h1><span>3alamati</span> DevOps</h1>
            </div>
            <div class="header-actions">
                <div class="theme-toggle"
                    style="display: flex; gap: 4px; background: var(--bg-card); padding: 4px; border-radius: 8px;">
                    <button class="btn btn-sm theme-btn" onclick="setTheme('light')" title="Light Theme">☀️</button>
                    <button class="btn btn-sm theme-btn active" onclick="setTheme('dark')"
                        title="Dark Blue Theme">🌙</button>
                    <button class="btn btn-sm theme-btn" onclick="setTheme('darker')" title="Darker Theme">🌑</button>
                </div>
                <button class="btn btn-ghost" onclick="refreshAll()">🔄 Refresh</button>
                <button class="btn btn-success" onclick="startAllServers()">▶️ Start All</button>
                <button class="btn btn-danger" onclick="stopAllServers()">⏹️ Stop All</button>
            </div>
        </header>

        <!-- Sidebar -->
        <aside class="sidebar">

            <!-- Flutter Device Manager -->
            <div class="sidebar-section">
                <div class="sidebar-title" style="display: flex; justify-content: space-between;">
                    <span>📱 Flutter Devices</span>
                    <button class="btn btn-sm btn-ghost" onclick="refreshDevices()"
                        style="padding: 4px 8px; font-size: 11px;">🔄 Refresh</button>
                </div>

                <!-- Device List -->
                <div id="flutterDeviceList" style="font-size: 12px; max-height: 250px; overflow-y: auto;">
                    <div style="color: var(--text-muted); padding: 12px; text-align: center;">
                        Loading devices...
                    </div>
                </div>

                <!-- ADB Connection -->
                <div
                    style="margin-top: 12px; padding: 10px; background: var(--bg-card); border: 1px solid var(--border); border-radius: 8px;">
                    <div style="font-size: 11px; color: var(--text-muted); margin-bottom: 8px;">🔌 Connect ADB Device
                    </div>
                    <div style="display: flex; gap: 6px;">
                        <input type="text" id="adbIpInput" class="input" placeholder="192.168.0.23:5555"
                            style="flex: 1; padding: 6px 10px; font-size: 12px; font-family: 'JetBrains Mono', monospace;">
                        <button class="btn btn-sm btn-primary" onclick="connectAdbDevice()">Connect</button>
                    </div>
                </div>

                <!-- Actions -->
                <div style="margin-top: 12px; display: flex; gap: 8px;">
                    <button class="btn btn-success" style="flex: 1; font-size: 12px;" onclick="launchSelectedDevices()">
                        🚀 Launch Selected
                    </button>
                    <button class="btn btn-ghost" style="font-size: 12px;" onclick="copySelectedCommands()"
                        title="Copy Commands">
                        📋
                    </button>
                </div>
            </div>

            <!-- Port Scanner Section -->
            <div class="sidebar-section">
                <div class="sidebar-title" style="display: flex; justify-content: space-between;">
                    <span>🔍 Port Scanner</span>
                    <button class="btn btn-sm btn-ghost" onclick="scanPorts()"
                        style="padding: 4px 8px; font-size: 11px;">Scan</button>
                </div>
                <div id="portScannerList" style="font-size: 12px;">
                    <div style="color: var(--text-muted); padding: 12px; text-align: center;">
                        Click "Scan" to detect running ports
                    </div>
                </div>
            </div>
        </aside>

        <!-- Server Control Bar - Above Terminal -->
        <div class="server-control-bar">
            <!-- Laravel Server -->
            <div class="control-card" id="controlLaravel">
                <div class="control-status" id="statusLaravel"></div>
                <div class="control-icon" style="background: linear-gradient(135deg, #ff2d20, #ff6f61);">🔥</div>
                <div class="control-info">
                    <span class="control-name">Laravel API</span>
                    <span class="control-port">:3000</span>
                </div>
                <div class="control-buttons">
                    <button class="control-btn" onclick="openServer('laravel')" title="Open in Browser">🔗</button>
                    <button class="control-toggle" onclick="toggleServer('laravel', 3000)" title="Toggle Server">
                        <span class="toggle-icon" id="toggleLaravel">▶</span>
                    </button>
                </div>
            </div>

            <!-- Reverb Server -->
            <div class="control-card" id="controlReverb">
                <div class="control-status" id="statusReverb"></div>
                <div class="control-icon" style="background: linear-gradient(135deg, #8b5cf6, #a855f7);">📡</div>
                <div class="control-info">
                    <span class="control-name">Reverb WS</span>
                    <span class="control-port">:6001</span>
                </div>
                <div class="control-buttons">
                    <button class="control-toggle" onclick="toggleServer('reverb', 6001)" title="Toggle Server">
                        <span class="toggle-icon" id="toggleReverb">▶</span>
                    </button>
                </div>
            </div>

            <!-- Flutter Web -->
            <div class="control-card" id="controlFlutter">
                <div class="control-status" id="statusFlutter"></div>
                <div class="control-icon" style="background: linear-gradient(135deg, #02569b, #0175c2);">💙</div>
                <div class="control-info">
                    <span class="control-name">Flutter Web</span>
                    <span class="control-port">:8080</span>
                </div>
                <div class="control-buttons">
                    <button class="control-btn" onclick="window.open('http://' + getSelectedIP() + ':8080', '_blank')"
                        title="Open in Browser">🔗</button>
                    <button class="control-toggle" onclick="copyFlutterCommand()" title="Copy Command">
                        <span class="toggle-icon">📋</span>
                    </button>
                </div>
            </div>

            <!-- Separator -->
            <div class="control-separator"></div>

            <!-- Stats -->
            <div class="control-stats">
                <div class="stat-item">
                    <span class="stat-value" id="summaryPorts">0</span>
                    <span class="stat-label">Ports</span>
                </div>
                <div class="stat-item">
                    <span class="stat-value" id="summaryDevices">0</span>
                    <span class="stat-label">Devices</span>
                </div>
            </div>
        </div>

        <!-- Main - Terminal -->
        <main class="main">
            <div class="terminal-header">
                <div class="terminal-tabs">
                    <button class="terminal-tab active" data-tab="all" onclick="switchTab('all')">
                        📋 All Logs
                    </button>
                    <button class="terminal-tab" data-tab="laravel" onclick="switchTab('laravel')">
                        <span class="tab-dot" style="background: #ff2d20;"></span> Laravel
                    </button>
                    <button class="terminal-tab" data-tab="reverb" onclick="switchTab('reverb')">
                        <span class="tab-dot" style="background: #8b5cf6;"></span> Reverb
                    </button>
                    <button class="terminal-tab" data-tab="flutter" onclick="switchTab('flutter')">
                        <span class="tab-dot" style="background: #02569b;"></span> Flutter
                    </button>
                </div>
                <div class="terminal-controls">
                    <button class="btn btn-sm btn-ghost" onclick="clearLogs()">🗑️ Clear</button>
                </div>
            </div>
            <div class="terminal-body" id="terminal">
                <div class="log-line">
                    <span class="log-time">--:--:--</span>
                    <span
                        class="log-content system">╔══════════════════════════════════════════════════════════════╗</span>
                </div>
                <div class="log-line">
                    <span class="log-time">--:--:--</span>
                    <span class="log-content system">║ 🚀 3alamati DevOps Console ║</span>
                </div>
                <div class="log-line">
                    <span class="log-time">--:--:--</span>
                    <span class="log-content system">║ Ready to launch servers... ║</span>
                </div>
                <div class="log-line">
                    <span class="log-time">--:--:--</span>
                    <span
                        class="log-content system">╚══════════════════════════════════════════════════════════════╝</span>
                </div>
            </div>
        </main>

        <!-- Right Panel - Config -->
        <aside class="panel">
            <div class="panel-section">
                <div class="panel-title">🌐 Network</div>
                <div class="ip-selector">
                    <div class="ip-current">
                        <span style="color: var(--text-muted); font-size: 11px;">Selected IP</span>
                        <button class="btn btn-sm btn-ghost" onclick="detectIPs()">🔍 Detect</button>
                    </div>
                    <div class="ip-value" id="currentIP">localhost</div>
                    <div class="ip-chips" id="ipChips">
                        <div class="ip-chip active" data-ip="localhost" onclick="selectIP('localhost')">localhost</div>
                    </div>
                </div>
            </div>

            <div class="panel-section">
                <div class="panel-title">🔗 URLs</div>
                <div class="url-card">
                    <div class="url-label">Laravel API</div>
                    <div class="url-value">
                        <span id="laravelUrl">http://localhost:3000</span>
                        <div class="url-actions">
                            <button class="btn btn-icon btn-ghost btn-sm" onclick="copyUrl('laravelUrl')">📋</button>
                            <button class="btn btn-icon btn-ghost btn-sm" onclick="openUrl('laravelUrl')">🔗</button>
                        </div>
                    </div>
                </div>
                <div class="url-card">
                    <div class="url-label">Reverb WebSocket</div>
                    <div class="url-value">
                        <span id="reverbUrl">ws://localhost:6001</span>
                        <button class="btn btn-icon btn-ghost btn-sm" onclick="copyUrl('reverbUrl')">📋</button>
                    </div>
                </div>
                <div class="url-card">
                    <div class="url-label">Flutter Web</div>
                    <div class="url-value">
                        <span id="flutterUrl">http://localhost:8080</span>
                        <div class="url-actions">
                            <button class="btn btn-icon btn-ghost btn-sm" onclick="copyUrl('flutterUrl')">📋</button>
                            <button class="btn btn-icon btn-ghost btn-sm" onclick="openUrl('flutterUrl')">🔗</button>
                        </div>
                    </div>
                </div>

                <button class="btn btn-primary" style="width: 100%; margin-top: 12px;" onclick="updateConstants()">
                    📝 Update constants.dart
                </button>
            </div>

            <div class="panel-section">
                <div class="panel-title">👤 Demo Accounts</div>
                <table class="ref-table">
                    <tr>
                        <th>Role</th>
                        <th>Email</th>
                    </tr>
                    <tr>
                        <td><span class="badge">Admin</span></td>
                        <td>admin@3alamati.com</td>
                    </tr>
                    <tr>
                        <td><span class="badge">Owner</span></td>
                        <td>owner@coffeeshop.com</td>
                    </tr>
                    <tr>
                        <td><span class="badge">User</span></td>
                        <td>user@example.com</td>
                    </tr>
                </table>
                <div style="color: var(--text-muted); font-size: 11px; margin-top: 8px;">
                    Password: <code style="color: var(--accent-cyan);">password123</code>
                </div>
            </div>
        </aside>
    </div>

    <!-- Toast Container -->
    <div class="toast-container" id="toastContainer"></div>

    <script>
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
        let selectedIP = 'localhost';
        let interfaces = [];
        let currentTab = 'all';
        let logs = [];

        // API Helper
        async function api(endpoint, method = 'GET', data = null) {
            const options = {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken
                }
            };
            if (data) options.body = JSON.stringify(data);
            const response = await fetch('/launcher' + endpoint, options);
            return response.json();
        }

        // Toast
        function showToast(message, type = 'info') {
            const container = document.getElementById('toastContainer');
            const toast = document.createElement('div');
            toast.className = `toast ${type}`;
            toast.innerHTML = `<span>${type === 'success' ? '✅' : type === 'error' ? '❌' : 'ℹ️'}</span><span>${message}</span>`;
            container.appendChild(toast);
            setTimeout(() => toast.remove(), 4000);
        }

        // Theme Management
        function setTheme(theme) {
            document.documentElement.setAttribute('data-theme', theme);
            localStorage.setItem('launcher-theme', theme);

            // Update active button
            document.querySelectorAll('.theme-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            const icons = { 'light': '☀️', 'dark': '🌙', 'darker': '🌑' };
            document.querySelectorAll('.theme-btn').forEach(btn => {
                if (btn.textContent.trim() === icons[theme]) {
                    btn.classList.add('active');
                }
            });

            addLog(`Theme changed to ${theme}`, 'info');
        }

        function loadTheme() {
            const saved = localStorage.getItem('launcher-theme') || 'dark';
            setTheme(saved);
        }

        // Terminal Logging
        function addLog(message, type = 'info', server = 'system') {
            const now = new Date();
            const time = now.toTimeString().slice(0, 8);
            const log = { time, message, type, server };
            logs.push(log);
            renderLogs();
        }

        function renderLogs() {
            const terminal = document.getElementById('terminal');
            const filteredLogs = currentTab === 'all'
                ? logs
                : logs.filter(l => l.server === currentTab || l.server === 'system');

            // Keep the welcome message and add logs
            const startHtml = `
                <div class="log-line">
                    <span class="log-time">--:--:--</span>
                    <span class="log-content system">╔══════════════════════════════════════════════════════════════╗</span>
                </div>
                <div class="log-line">
                    <span class="log-time">--:--:--</span>
                    <span class="log-content system">║  🚀 3alamati DevOps Console                                   ║</span>
                </div>
                <div class="log-line">
                    <span class="log-time">--:--:--</span>
                    <span class="log-content system">╚══════════════════════════════════════════════════════════════╝</span>
                </div>
            `;

            const logsHtml = filteredLogs.map(log => `
                <div class="log-line">
                    <span class="log-time">${log.time}</span>
                    <span class="log-content ${log.type}">${log.message}</span>
                </div>
            `).join('');

            terminal.innerHTML = startHtml + logsHtml;
            terminal.scrollTop = terminal.scrollHeight;
        }

        function clearLogs() {
            logs = [];
            renderLogs();
            addLog('Console cleared', 'system');
        }

        function switchTab(tab) {
            currentTab = tab;
            document.querySelectorAll('.terminal-tab').forEach(t => {
                t.classList.toggle('active', t.dataset.tab === tab);
            });
            renderLogs();
        }

        // Server Selection
        function selectServer(server) {
            document.querySelectorAll('.server-item').forEach(item => {
                item.classList.toggle('active', item.dataset.server === server);
            });
        }

        // IP Management
        function getSelectedIP() {
            return selectedIP;
        }

        function selectIP(ip) {
            selectedIP = ip;
            document.getElementById('currentIP').textContent = ip;
            document.querySelectorAll('.ip-chip').forEach(chip => {
                chip.classList.toggle('active', chip.dataset.ip === ip);
            });
            updateURLs();
            addLog(`IP changed to: ${ip}`, 'info');
        }

        async function detectIPs() {
            addLog('Detecting network interfaces...', 'info');
            try {
                const result = await api('/network');
                if (result.success && result.interfaces) {
                    interfaces = result.interfaces;
                    const chipsContainer = document.getElementById('ipChips');
                    chipsContainer.innerHTML = interfaces.map(iface => `
                        <div class="ip-chip ${iface.IPAddress === selectedIP ? 'active' : ''}" 
                             data-ip="${iface.IPAddress}" 
                             onclick="selectIP('${iface.IPAddress}')">
                            ${iface.IPAddress}
                        </div>
                    `).join('');
                    addLog(`Found ${interfaces.length} network interfaces`, 'success');
                }
            } catch (e) {
                addLog('Failed to detect IPs: ' + e.message, 'error');
            }
        }

        // URL Management
        function updateURLs() {
            const ip = getSelectedIP();
            document.getElementById('laravelUrl').textContent = `http://${ip}:3000`;
            document.getElementById('reverbUrl').textContent = `ws://${ip}:6001`;
            document.getElementById('flutterUrl').textContent = `http://${ip}:8080`;
        }

        function copyUrl(elementId) {
            const text = document.getElementById(elementId).textContent;
            navigator.clipboard.writeText(text);
            showToast('Copied: ' + text, 'success');
        }

        function openUrl(elementId) {
            const url = document.getElementById(elementId).textContent;
            window.open(url, '_blank');
        }

        function copyFlutterCommand() {
            const cmd = 'flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0';
            navigator.clipboard.writeText(cmd);
            addLog('📋 Copied Flutter command to clipboard', 'success');
            addLog('💡 Paste and run in a new terminal window', 'info');
            showToast('Copied Flutter command! Paste in terminal.', 'success');
        }

        function openServer(server) {
            const ip = getSelectedIP();
            const portMap = { 'laravel': 3000, 'reverb': 6001 };
            window.open(`http://${ip}:${portMap[server]}`, '_blank');
        }

        // Server Status
        let serverStates = { laravel: false, reverb: false, flutter: false };

        function updateControlBar(server, running) {
            serverStates[server] = running;

            // Update control card
            const card = document.getElementById(`control${server.charAt(0).toUpperCase() + server.slice(1)}`);
            const status = document.getElementById(`status${server.charAt(0).toUpperCase() + server.slice(1)}`);
            const toggle = document.getElementById(`toggle${server.charAt(0).toUpperCase() + server.slice(1)}`);

            if (card) {
                card.classList.toggle('running', running);
            }
            if (status) {
                status.classList.toggle('running', running);
            }
            if (toggle && server !== 'flutter') {
                toggle.textContent = running ? '⏹' : '▶';
                toggle.parentElement.classList.toggle('stop', running);
            }

            // Also update sidebar dots
            const dot = document.getElementById(`dot-${server}`);
            if (dot) {
                dot.classList.toggle('running', running);
            }
        }

        async function toggleServer(type, port) {
            if (serverStates[type]) {
                // Stop server - we need to kill the process
                addLog(`Stopping ${type}...`, 'warning', type);
                showToast(`Stopping ${type}...`, 'info');

                // Scan ports to find PID
                const result = await api('/scan-ports');
                if (result.success && result.ports) {
                    const portInfo = result.ports.find(p => p.port === port);
                    if (portInfo && portInfo.pid) {
                        await api('/kill-process', 'POST', { pid: portInfo.pid });
                        setTimeout(checkServerStatus, 500);
                    }
                }
            } else {
                // Start server
                startServer(type, port);
            }
        }

        async function checkServerStatus() {
            try {
                const ports = [3000, 6001, 8080];
                const result = await api('/status?ports=' + JSON.stringify(ports));

                if (result.success) {
                    updateControlBar('laravel', result.statuses[3000]?.running);
                    updateControlBar('reverb', result.statuses[6001]?.running);
                    updateControlBar('flutter', result.statuses[8080]?.running);
                }
            } catch (e) {
                console.error('Status check failed:', e);
            }
        }

        // Server Control
        async function startServer(type, port = null) {
            const portMap = { 'laravel': 3000, 'reverb': 6001 };
            const serverPort = port || portMap[type];

            addLog(`Starting ${type} server on port ${serverPort}...`, 'info', type);
            showToast(`Starting ${type}...`, 'info');

            try {
                const result = await api('/start', 'POST', {
                    type: type === 'flutter' ? 'flutter' : type,
                    port: serverPort,
                    host: '0.0.0.0'
                });

                if (result.success) {
                    addLog(`✅ ${type} server starting on port ${serverPort}`, 'success', type);
                    addLog(`Command: ${result.command || 'N/A'}`, 'info', type);
                    showToast(result.message, 'success');
                    setTimeout(checkServerStatus, 3000);
                } else {
                    addLog(`❌ Failed to start ${type}: ${result.message}`, 'error', type);
                    showToast('Failed: ' + result.message, 'error');
                }
            } catch (e) {
                addLog(`❌ Error: ${e.message}`, 'error', type);
                showToast('Error: ' + e.message, 'error');
            }
        }

        async function stopServer(type, port = null) {
            const portMap = { 'laravel': 3000, 'reverb': 6001 };
            const serverPort = port || portMap[type];

            addLog(`Stopping server on port ${serverPort}...`, 'warning', type);
            showToast(`Stopping server on port ${serverPort}...`, 'info');

            try {
                const result = await api('/stop', 'POST', { port: serverPort });
                if (result.success) {
                    addLog(`⏹️ Server stopped on port ${serverPort}`, 'success', type);
                    showToast(result.message, 'success');
                    setTimeout(checkServerStatus, 1000);
                }
            } catch (e) {
                addLog(`❌ Error: ${e.message}`, 'error', type);
            }
        }

        async function startAllServers() {
            addLog('🚀 Starting Laravel and Reverb servers...', 'system');
            await startServer('laravel');
            await new Promise(r => setTimeout(r, 1000));
            await startServer('reverb');
            addLog('💡 For Flutter: Copy the command and run in terminal', 'info');
            copyFlutterCommand();
        }

        async function stopAllServers() {
            addLog('⏹️ Stopping all servers...', 'system');
            await stopServer('laravel');
            await stopServer('reverb');
            await stopServer('flutter', 8080);
            // Immediate refresh
            setTimeout(() => {
                checkServerStatus();
                scanPorts(true);
            }, 500);
        }

        function refreshAll() {
            detectIPs();
            checkServerStatus();
            addLog('🔄 Refreshed all data', 'info');
        }

        async function updateConstants() {
            const ip = getSelectedIP();
            addLog(`Updating constants.dart with IP: ${ip}`, 'info');

            try {
                const result = await api('/update-constants', 'POST', {
                    ip,
                    apiPort: 3000,
                    reverbPort: 6001
                });

                if (result.success) {
                    addLog('✅ constants.dart updated! Hot restart Flutter.', 'success');
                    showToast('constants.dart updated!', 'success');
                } else {
                    addLog('❌ Failed: ' + result.message, 'error');
                    showToast('Failed: ' + result.message, 'error');
                }
            } catch (e) {
                addLog('❌ Error: ' + e.message, 'error');
            }
        }

        // Port Scanner
        async function scanPorts(silent = false) {
            if (!silent) addLog('🔍 Scanning ports...', 'info');
            const container = document.getElementById('portScannerList');
            if (!silent) container.innerHTML = '<div style="color: var(--text-muted); padding: 12px; text-align: center;">Scanning...</div>';

            try {
                const result = await api('/scan-ports');
                if (result.success && result.ports) {
                    const runningPorts = result.ports.filter(p => p.running);

                    if (runningPorts.length === 0) {
                        container.innerHTML = '<div style="color: var(--text-muted); padding: 12px; text-align: center;">No ports in use</div>';
                        document.getElementById('summaryPorts').textContent = '0';
                        return;
                    }

                    container.innerHTML = runningPorts.map(p => `
                        <div class="port-item" style="
                            display: flex;
                            align-items: center;
                            justify-content: space-between;
                            padding: 8px 10px;
                            background: var(--bg-card);
                            border: 1px solid var(--border);
                            border-radius: 6px;
                            margin-bottom: 6px;
                        ">
                            <div>
                                <div style="font-family: 'JetBrains Mono', monospace; color: var(--accent-green);">:${p.port}</div>
                                <div style="font-size: 10px; color: var(--text-muted);">${p.process || 'Unknown'} (PID: ${p.pid})</div>
                            </div>
                            <button class="btn btn-sm btn-danger" 
                                    onclick="killProcess(${p.pid}, ${p.port})" 
                                    style="padding: 4px 8px; font-size: 11px;">
                                ☠️ Kill
                            </button>
                        </div>
                    `).join('');

                    if (!silent) addLog(`Found ${runningPorts.length} active port(s): ${runningPorts.map(p => p.port).join(', ')}`, 'success');
                    document.getElementById('summaryPorts').textContent = runningPorts.length;
                } else {
                    container.innerHTML = '<div style="color: var(--text-muted); padding: 12px; text-align: center;">Scan failed</div>';
                    if (!silent) addLog('Port scan failed: ' + (result.message || 'Unknown error'), 'error');
                }
            } catch (e) {
                container.innerHTML = '<div style="color: var(--accent-red); padding: 12px; text-align: center;">Error scanning</div>';
                if (!silent) addLog('Port scan error: ' + e.message, 'error');
            }
        }

        async function killProcess(pid, port) {
            if (!confirm(`Kill process ${pid} on port ${port}?`)) return;

            addLog(`☠️ Killing process ${pid} on port ${port}...`, 'warning');
            showToast(`Killing process on port ${port}...`, 'info');

            try {
                const result = await api('/kill-process', 'POST', { pid });
                if (result.success) {
                    addLog(`✅ Process ${pid} terminated`, 'success');
                    showToast(`Process ${pid} killed`, 'success');
                    // Refresh the port scanner and server status
                    setTimeout(() => {
                        scanPorts();
                        checkServerStatus();
                    }, 500);
                } else {
                    addLog(`❌ Failed to kill: ${result.message}`, 'error');
                    showToast('Failed: ' + result.message, 'error');
                }
            } catch (e) {
                addLog(`❌ Error: ${e.message}`, 'error');
                showToast('Error: ' + e.message, 'error');
            }
        }

        // Flutter Device Management
        let flutterDevices = [];
        let selectedDevices = new Set();

        async function refreshDevices() {
            addLog('📱 Detecting Flutter devices...', 'info');
            const container = document.getElementById('flutterDeviceList');
            container.innerHTML = '<div style="color: var(--text-muted); padding: 12px; text-align: center;">Scanning...</div>';

            try {
                const result = await api('/flutter-devices');
                if (result.success && result.devices) {
                    flutterDevices = result.devices;
                    renderDeviceList();
                    addLog(`Found ${flutterDevices.length} device(s)`, 'success');
                    document.getElementById('summaryDevices').textContent = flutterDevices.length;
                } else {
                    container.innerHTML = '<div style="color: var(--accent-red); padding: 12px; text-align: center;">Failed to detect devices</div>';
                    addLog('Device detection failed: ' + (result.message || 'Unknown error'), 'error');
                }
            } catch (e) {
                container.innerHTML = '<div style="color: var(--accent-red); padding: 12px; text-align: center;">Error</div>';
                addLog('Device error: ' + e.message, 'error');
            }
        }

        function renderDeviceList() {
            const container = document.getElementById('flutterDeviceList');

            if (flutterDevices.length === 0) {
                container.innerHTML = '<div style="color: var(--text-muted); padding: 12px; text-align: center;">No devices found</div>';
                return;
            }

            const getCategoryIcon = (cat) => {
                switch (cat) {
                    case 'browser': return '🌐';
                    case 'web': return '💻';
                    case 'android': return '📱';
                    case 'ios': return '🍎';
                    case 'desktop': return '🖥️';
                    default: return '📟';
                }
            };

            const getCategoryColor = (cat) => {
                switch (cat) {
                    case 'browser': return 'var(--accent-blue)';
                    case 'web': return 'var(--accent-cyan)';
                    case 'android': return 'var(--accent-green)';
                    case 'ios': return 'var(--accent-purple)';
                    default: return 'var(--text-muted)';
                }
            };

            container.innerHTML = flutterDevices.map(d => `
                <div class="device-item" style="
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    padding: 8px 10px;
                    background: var(--bg-card);
                    border: 1px solid ${selectedDevices.has(d.id) ? 'var(--accent-blue)' : 'var(--border)'};
                    border-radius: 6px;
                    margin-bottom: 6px;
                    cursor: pointer;
                    transition: all 0.2s;
                " onclick="toggleDevice('${d.id}')">
                    <input type="checkbox" ${selectedDevices.has(d.id) ? 'checked' : ''} 
                        style="accent-color: var(--accent-blue);" onclick="event.stopPropagation(); toggleDevice('${d.id}')">
                    <span style="font-size: 16px;">${getCategoryIcon(d.category)}</span>
                    <div style="flex: 1; min-width: 0;">
                        <div style="font-size: 12px; font-weight: 600; color: ${getCategoryColor(d.category)}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                            ${d.name}
                        </div>
                        <div style="font-size: 10px; color: var(--text-muted); font-family: 'JetBrains Mono', monospace;">
                            ${d.id}
                        </div>
                    </div>
                    <button class="btn btn-sm btn-ghost" onclick="event.stopPropagation(); copyDeviceCommand('${d.id}')" 
                        style="padding: 4px 8px; font-size: 10px;" title="Copy command">📋</button>
                </div>
            `).join('');
        }

        function toggleDevice(deviceId) {
            if (selectedDevices.has(deviceId)) {
                selectedDevices.delete(deviceId);
            } else {
                selectedDevices.add(deviceId);
            }
            renderDeviceList();
        }

        function getDeviceCommand(deviceId) {
            if (deviceId === 'web-server') {
                return 'flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0';
            }
            return `flutter run -d ${deviceId}`;
        }

        function copyDeviceCommand(deviceId) {
            const cmd = getDeviceCommand(deviceId);
            navigator.clipboard.writeText(cmd);
            addLog(`📋 Copied: ${cmd}`, 'success');
            showToast('Command copied!', 'success');
        }

        function copySelectedCommands() {
            if (selectedDevices.size === 0) {
                showToast('No devices selected', 'error');
                return;
            }

            const commands = Array.from(selectedDevices).map(id => getDeviceCommand(id));
            const text = commands.join('\n');
            navigator.clipboard.writeText(text);

            addLog(`📋 Copied ${commands.length} command(s):`, 'success');
            commands.forEach(cmd => addLog(`   ${cmd}`, 'info'));
            showToast(`Copied ${commands.length} command(s)!`, 'success');
        }

        async function launchSelectedDevices() {
            if (selectedDevices.size === 0) {
                showToast('No devices selected', 'error');
                return;
            }

            const devices = Array.from(selectedDevices);
            addLog(`🚀 Launching Flutter on ${devices.length} device(s)...`, 'info');
            showToast(`Launching on ${devices.length} device(s)...`, 'info');

            let successCount = 0;
            let basePort = 8080;

            for (const deviceId of devices) {
                try {
                    const port = basePort++;
                    const result = await api('/flutter-launch', 'POST', {
                        device: deviceId,
                        port: port
                    });

                    if (result.success) {
                        addLog(`✅ ${result.message}`, 'success', 'flutter');
                        successCount++;
                    } else {
                        addLog(`❌ Failed to launch on ${deviceId}: ${result.message}`, 'error', 'flutter');
                    }
                } catch (e) {
                    addLog(`❌ Error launching on ${deviceId}: ${e.message}`, 'error');
                }
            }

            if (successCount > 0) {
                showToast(`Launched on ${successCount} device(s)!`, 'success');
                // Refresh status after a delay
                setTimeout(checkServerStatus, 2000);
            }
        }

        async function connectAdbDevice() {
            const input = document.getElementById('adbIpInput').value.trim();
            if (!input) {
                showToast('Enter IP:Port', 'error');
                return;
            }

            const [ip, port] = input.includes(':') ? input.split(':') : [input, '5555'];
            addLog(`🔌 Connecting to ${ip}:${port}...`, 'info');
            showToast(`Connecting to ${ip}:${port}...`, 'info');

            try {
                const result = await api('/adb-connect', 'POST', { ip, port });
                if (result.success) {
                    addLog(`✅ ${result.message}`, 'success');
                    showToast('Connected!', 'success');
                    document.getElementById('adbIpInput').value = '';
                    // Refresh device list
                    setTimeout(refreshDevices, 1000);
                } else {
                    addLog(`❌ ${result.message}`, 'error');
                    showToast('Failed: ' + result.message, 'error');
                }
            } catch (e) {
                addLog(`❌ Error: ${e.message}`, 'error');
                showToast('Error: ' + e.message, 'error');
            }
        }

        // Initialize
        document.addEventListener('DOMContentLoaded', () => {
            loadTheme();
            addLog('Console initialized', 'success');
            detectIPs();
            checkServerStatus();
            scanPorts();
            refreshDevices();

            // Poll every 3 seconds for real-time updates (silent mode)
            setInterval(() => {
                checkServerStatus();
                scanPorts(true); // Silent mode - no log spam
            }, 3000);
        });
    </script>
</body>

</html>