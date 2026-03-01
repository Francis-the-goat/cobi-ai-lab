#!/usr/bin/env python3
"""
OpenClaw Mission Control Dashboard
Real-time monitoring and control for your automation system
"""

import os
import json
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
import threading

VAULT_PATH = Path(os.path.expanduser("~/obsidian/openclaw"))
WORKSPACE_PATH = Path(os.path.expanduser("~/.openclaw/workspace"))

class DashboardHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.generate_dashboard().encode())
        elif self.path == '/api/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(self.get_status()).encode())
        elif self.path == '/api/run-pipeline':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            result = self.run_pipeline()
            self.wfile.write(json.dumps(result).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Suppress logs
    
    def get_status(self):
        """Gather system status"""
        status = {
            'timestamp': datetime.now().isoformat(),
            'gateway': self.check_gateway(),
            'cron': self.check_cron(),
            'vault': self.check_vault(),
            'today': self.get_today_stats(),
            'proposals': self.get_pending_proposals(),
            'recent_activity': self.get_recent_activity(),
            'self_improvement': self.get_self_improvement_status()
        }
        return status
    
    def check_gateway(self):
        try:
            result = subprocess.run(
                ['openclaw', 'gateway', 'status'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if 'Runtime: running' in result.stdout:
                return {'status': 'running', 'healthy': True}
            return {'status': 'stopped', 'healthy': False}
        except:
            return {'status': 'unknown', 'healthy': False}
    
    def check_cron(self):
        try:
            result = subprocess.run(
                ['crontab', '-l'],
                capture_output=True,
                text=True
            )
            lines = [l for l in result.stdout.split('\n') if l.strip() and not l.startswith('#')]
            return {
                'enabled': len(lines) > 0,
                'jobs': len(lines),
                'next_runs': self.calculate_next_runs(lines)
            }
        except:
            return {'enabled': False, 'jobs': 0, 'next_runs': {}}
    
    def calculate_next_runs(self, cron_lines):
        """Calculate next run times for cron jobs"""
        next_runs = {}
        now = datetime.now()
        
        for line in cron_lines:
            if 'morning-briefing' in line:
                next_runs['Morning Briefing'] = (now.replace(hour=6, minute=0) + 
                    timedelta(days=1 if now.hour >= 6 else 0)).strftime('%H:%M')
            elif 'full-pipeline' in line:
                next_runs['Pipeline'] = (now.replace(hour=17, minute=0) + 
                    timedelta(days=0 if now.hour < 17 else 1)).strftime('%H:%M')
            elif 'self-improvement' in line:
                next_runs['Self-Improvement'] = (now.replace(hour=9, minute=0) + 
                    timedelta(days=1 if now.hour >= 9 else 0)).strftime('%H:%M')
        
        return next_runs
    
    def check_vault(self):
        stats = {}
        for dir_name in ['01-daily', '03-patterns', '04-decisions', '05-sessions', 'self-improvement']:
            path = VAULT_PATH / dir_name
            if path.exists():
                files = list(path.glob('**/*.md'))
                today_files = [f for f in files if datetime.fromtimestamp(f.stat().st_mtime).date() == datetime.now().date()]
                stats[dir_name] = {'total': len(files), 'today': len(today_files)}
            else:
                stats[dir_name] = {'total': 0, 'today': 0}
        return stats
    
    def get_today_stats(self):
        today = datetime.now().date()
        
        # Check for today's briefing
        briefing_file = VAULT_PATH / '01-daily' / f'{today.strftime("%Y-%m-%d")}-morning-briefing.md'
        briefing_exists = briefing_file.exists()
        
        # Check for today's self-improvement task
        task_file = VAULT_PATH / 'self-improvement' / 'daily-tasks' / f'{today.strftime("%Y-%m-%d")}-task.md'
        task_exists = task_file.exists()
        
        # Count today's patterns
        patterns_dir = VAULT_PATH / '03-patterns'
        if patterns_dir.exists():
            today_patterns = len([
                f for f in patterns_dir.glob('*.md')
                if datetime.fromtimestamp(f.stat().st_mtime).date() == today
            ])
        else:
            today_patterns = 0
        
        return {
            'briefing_generated': briefing_exists,
            'self_improvement_task': task_exists,
            'patterns_extracted': today_patterns,
            'date': today.strftime('%Y-%m-%d')
        }
    
    def get_pending_proposals(self):
        proposals_dir = VAULT_PATH / '04-decisions' / 'skill-proposals'
        if not proposals_dir.exists():
            return []
        
        proposals = []
        for f in proposals_dir.glob('*.md'):
            content = f.read_text()
            if 'Status: Proposed' in content or 'Status: Queued' in content:
                # Extract title
                title = content.split('\n')[0].replace('# ', '') if content.startswith('# ') else f.stem
                proposals.append({
                    'name': f.stem,
                    'title': title,
                    'file': str(f)
                })
        return proposals
    
    def get_recent_activity(self):
        activity = []
        
        # Check recent sessions
        sessions_dir = VAULT_PATH / '05-sessions'
        if sessions_dir.exists():
            recent_sessions = sorted(
                sessions_dir.glob('*.md'),
                key=lambda x: x.stat().st_mtime,
                reverse=True
            )[:5]
            for s in recent_sessions:
                activity.append({
                    'time': datetime.fromtimestamp(s.stat().st_mtime).strftime('%H:%M'),
                    'type': 'Session',
                    'description': s.stem
                })
        
        # Check recent patterns
        patterns_dir = VAULT_PATH / '03-patterns'
        if patterns_dir.exists():
            recent_patterns = sorted(
                patterns_dir.glob('*.md'),
                key=lambda x: x.stat().st_mtime,
                reverse=True
            )[:3]
            for p in recent_patterns:
                activity.append({
                    'time': datetime.fromtimestamp(p.stat().st_mtime).strftime('%H:%M'),
                    'type': 'Pattern',
                    'description': p.stem
                })
        
        return sorted(activity, key=lambda x: x['time'], reverse=True)[:8]
    
    def get_self_improvement_status(self):
        corrections_file = VAULT_PATH / 'self-improvement' / 'corrections' / 'log.md'
        if corrections_file.exists():
            content = corrections_file.read_text()
            correction_count = content.count('### ')
        else:
            correction_count = 0
        
        # Check weekly learnings
        learnings_file = VAULT_PATH / 'self-improvement' / 'learnings' / 'weekly.md'
        if learnings_file.exists():
            content = learnings_file.read_text()
            learning_count = content.count('### ')
        else:
            learning_count = 0
        
        return {
            'corrections_logged': correction_count,
            'learnings_logged': learning_count,
            'today_task_completed': False  # Would need to parse task file
        }
    
    def run_pipeline(self):
        """Trigger the full pipeline manually"""
        try:
            subprocess.Popen(
                ['bash', str(WORKSPACE_PATH / 'scripts' / 'full-pipeline.sh')],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
            return {'status': 'started', 'message': 'Pipeline running in background'}
        except Exception as e:
            return {'status': 'error', 'message': str(e)}
    
    def generate_dashboard(self):
        """Generate HTML dashboard"""
        return '''<!DOCTYPE html>
<html>
<head>
    <title>OpenClaw Mission Control</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0a0a0f;
            color: #e0e0e0;
            line-height: 1.6;
        }
        .header {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            padding: 20px;
            border-bottom: 2px solid #0f3460;
        }
        .header h1 {
            font-size: 24px;
            color: #e94560;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .header .status {
            font-size: 12px;
            color: #888;
            margin-top: 5px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .card {
            background: #16162a;
            border-radius: 12px;
            padding: 20px;
            border: 1px solid #252547;
        }
        .card h2 {
            font-size: 14px;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #888;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #252547;
        }
        .metric:last-child { border-bottom: none; }
        .metric-label { color: #888; font-size: 14px; }
        .metric-value { font-weight: 600; }
        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }
        .status-ok { background: #0f3d0f; color: #4ade80; }
        .status-warn { background: #3d3d0f; color: #facc15; }
        .status-error { background: #3d0f0f; color: #f87171; }
        .dot { width: 8px; height: 8px; border-radius: 50%; }
        .dot-green { background: #4ade80; }
        .dot-yellow { background: #facc15; }
        .dot-red { background: #f87171; }
        .button {
            background: #e94560;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            transition: background 0.2s;
        }
        .button:hover { background: #ff6b6b; }
        .activity-list {
            max-height: 300px;
            overflow-y: auto;
        }
        .activity-item {
            display: flex;
            gap: 15px;
            padding: 10px;
            border-bottom: 1px solid #252547;
            font-size: 14px;
        }
        .activity-time { color: #888; font-size: 12px; min-width: 50px; }
        .activity-type { 
            background: #0f3460; 
            padding: 2px 8px; 
            border-radius: 4px; 
            font-size: 11px;
            text-transform: uppercase;
        }
        .proposal-item {
            background: #1a1a2e;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 10px;
            border-left: 3px solid #e94560;
        }
        .proposal-title { font-weight: 600; margin-bottom: 4px; }
        .proposal-file { font-size: 12px; color: #888; }
        .refresh-indicator {
            position: fixed;
            top: 20px;
            right: 20px;
            background: #1a1a2e;
            padding: 10px 20px;
            border-radius: 8px;
            font-size: 12px;
            color: #888;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }
        .pulse { animation: pulse 2s infinite; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🦞 OpenClaw Mission Control</h1>
        <div class="status">Autonomous Intelligence System • <span id="last-updated">Loading...</span></div>
    </div>
    
    <div class="refresh-indicator">
        Auto-refresh: <span class="pulse">●</span> <span id="countdown">30</span>s
    </div>
    
    <div class="container">
        <!-- System Status Row -->
        <div class="grid">
            <div class="card">
                <h2>🔌 Gateway</h2>
                <div class="metric">
                    <span class="metric-label">Status</span>
                    <span id="gateway-status" class="status-badge status-error">Checking...</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Health</span>
                    <span id="gateway-health">Unknown</span>
                </div>
            </div>
            
            <div class="card">
                <h2>⏰ Automation</h2>
                <div class="metric">
                    <span class="metric-label">Cron Jobs</span>
                    <span id="cron-jobs" class="metric-value">-</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Status</span>
                    <span id="cron-status" class="status-badge status-warn">Unknown</span>
                </div>
            </div>
            
            <div class="card">
                <h2>📊 Today's Progress</h2>
                <div class="metric">
                    <span class="metric-label">Briefing</span>
                    <span id="briefing-status" class="status-badge status-warn">-</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Patterns</span>
                    <span id="patterns-count" class="metric-value">-</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Self-Improvement</span>
                    <span id="si-task" class="status-badge status-warn">-</span>
                </div>
            </div>
        </div>
        
        <!-- Vault Stats -->
        <div class="grid">
            <div class="card">
                <h2>📁 Vault Overview</h2>
                <div id="vault-stats">
                    <div class="metric"><span class="metric-label">Loading...</span></div>
                </div>
            </div>
            
            <div class="card">
                <h2>⏱️ Next Runs</h2>
                <div id="next-runs">
                    <div class="metric"><span class="metric-label">Loading...</span></div>
                </div>
            </div>
            
            <div class="card">
                <h2>🎯 Quick Actions</h2>
                <div style="display: flex; flex-direction: column; gap: 10px;">
                    <button class="button" onclick="runPipeline()">▶ Run Pipeline Now</button>
                    <button class="button" onclick="location.reload()">🔄 Refresh Dashboard</button>
                </div>
                <div id="pipeline-status" style="margin-top: 10px; font-size: 12px;"></div>
            </div>
        </div>
        
        <!-- Pending Proposals -->
        <div class="grid">
            <div class="card" style="grid-column: span 2;">
                <h2>🔨 Pending Build Proposals</h2>
                <div id="proposals-list">
                    <div class="metric"><span class="metric-label">Loading...</span></div>
                </div>
            </div>
            
            <div class="card">
                <h2>🧠 Self-Improvement</h2>
                <div id="si-stats">
                    <div class="metric"><span class="metric-label">Loading...</span></div>
                </div>
            </div>
        </div>
        
        <!-- Recent Activity -->
        <div class="card">
            <h2>📈 Recent Activity</h2>
            <div id="activity-list" class="activity-list">
                <div class="activity-item">Loading...</div>
            </div>
        </div>
    </div>
    
    <script>
        let countdown = 30;
        
        function updateCountdown() {
            countdown--;
            if (countdown <= 0) {
                countdown = 30;
                fetchStatus();
            }
            document.getElementById('countdown').textContent = countdown;
        }
        
        function fetchStatus() {
            fetch('/api/status')
                .then(r => r.json())
                .then(data => updateDashboard(data))
                .catch(e => console.error('Failed to fetch status:', e));
        }
        
        function updateDashboard(data) {
            document.getElementById('last-updated').textContent = new Date(data.timestamp).toLocaleString();
            
            // Gateway
            const gw = data.gateway;
            const gwEl = document.getElementById('gateway-status');
            gwEl.className = 'status-badge ' + (gw.healthy ? 'status-ok' : 'status-error');
            gwEl.innerHTML = (gw.healthy ? '<span class="dot dot-green"></span> ' : '<span class="dot dot-red"></span> ') + gw.status;
            document.getElementById('gateway-health').textContent = gw.healthy ? 'Healthy' : 'Issues detected';
            
            // Cron
            const cron = data.cron;
            document.getElementById('cron-jobs').textContent = cron.jobs;
            const cronEl = document.getElementById('cron-status');
            cronEl.className = 'status-badge ' + (cron.enabled ? 'status-ok' : 'status-error');
            cronEl.innerHTML = (cron.enabled ? '<span class="dot dot-green"></span> ' : '<span class="dot dot-red"></span> ') + (cron.enabled ? 'Active' : 'Inactive');
            
            // Next runs
            const nextRunsHtml = Object.entries(cron.next_runs || {}).map(([name, time]) => 
                `<div class="metric"><span class="metric-label">${name}</span><span class="metric-value">${time}</span></div>`
            ).join('') || '<div class="metric"><span class="metric-label">No scheduled jobs</span></div>';
            document.getElementById('next-runs').innerHTML = nextRunsHtml;
            
            // Today's progress
            const today = data.today;
            const brEl = document.getElementById('briefing-status');
            brEl.className = 'status-badge ' + (today.briefing_generated ? 'status-ok' : 'status-warn');
            brEl.textContent = today.briefing_generated ? 'Generated' : 'Pending';
            
            document.getElementById('patterns-count').textContent = today.patterns_extracted;
            
            const siEl = document.getElementById('si-task');
            siEl.className = 'status-badge ' + (today.self_improvement_task ? 'status-ok' : 'status-warn');
            siEl.textContent = today.self_improvement_task ? 'Ready' : 'Pending';
            
            // Vault stats
            const vaultHtml = Object.entries(data.vault).map(([dir, stats]) =>
                `<div class="metric"><span class="metric-label">${dir}</span><span class="metric-value">${stats.today} / ${stats.total}</span></div>`
            ).join('');
            document.getElementById('vault-stats').innerHTML = vaultHtml;
            
            // Proposals
            const proposalsHtml = data.proposals.length > 0 
                ? data.proposals.map(p => `
                    <div class="proposal-item">
                        <div class="proposal-title">${p.title}</div>
                        <div class="proposal-file">${p.file}</div>
                    </div>
                `).join('')
                : '<div class="metric"><span class="metric-label">No pending proposals</span></div>';
            document.getElementById('proposals-list').innerHTML = proposalsHtml;
            
            // Self-improvement
            const si = data.self_improvement;
            document.getElementById('si-stats').innerHTML = `
                <div class="metric"><span class="metric-label">Corrections</span><span class="metric-value">${si.corrections_logged}</span></div>
                <div class="metric"><span class="metric-label">Learnings</span><span class="metric-value">${si.learnings_logged}</span></div>
            `;
            
            // Activity
            const activityHtml = data.recent_activity.map(a => `
                <div class="activity-item">
                    <span class="activity-time">${a.time}</span>
                    <span class="activity-type">${a.type}</span>
                    <span>${a.description}</span>
                </div>
            `).join('');
            document.getElementById('activity-list').innerHTML = activityHtml;
        }
        
        function runPipeline() {
            document.getElementById('pipeline-status').textContent = 'Starting pipeline...';
            fetch('/api/run-pipeline')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('pipeline-status').textContent = data.message;
                    setTimeout(fetchStatus, 2000);
                })
                .catch(e => {
                    document.getElementById('pipeline-status').textContent = 'Error: ' + e.message;
                });
        }
        
        // Initial load
        fetchStatus();
        
        // Auto-refresh countdown
        setInterval(updateCountdown, 1000);
    </script>
</body>
</html>'''

def start_dashboard(port=8765):
    """Start the dashboard server"""
    server = HTTPServer(('127.0.0.1', port), DashboardHandler)
    print(f"🦞 OpenClaw Mission Control")
    print(f"Dashboard: http://127.0.0.1:{port}")
    print(f"Press Ctrl+C to stop")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()

if __name__ == '__main__':
    start_dashboard()
