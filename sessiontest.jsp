<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Date" %>
<%
    // Get server info
    String serverPort = String.valueOf(request.getServerPort());
    String serverInfo = application.getServerInfo();
    String jvmRoute = System.getProperty("jvmRoute", "unknown");
    
    // Handle session invalidation
    if ("invalidate".equals(request.getParameter("action"))) {
        session.invalidate();
        session = request.getSession(true); // Create new session
    }
    
    // Get or create visit count
    Integer visitCount = (Integer) session.getAttribute("visitCount");
    if (visitCount == null) {
        visitCount = 1;
        session.setAttribute("startTime", new Date());
    } else {
        visitCount++;
    }
    session.setAttribute("visitCount", visitCount);
    
    Date startTime = (Date) session.getAttribute("startTime");
    
    // Determine server class based on port
    String serverClass = serverPort.equals("8080") ? "server1" : "server2";
    String serverName = serverPort.equals("8080") ? "Instance 1" : "Instance 2";
%>
<!DOCTYPE html>
<html>
<head>
    <title>Sticky Session Test</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .info-box { 
            background: #f8f9fa; 
            padding: 20px; 
            margin: 15px 0; 
            border-radius: 8px;
            border-left: 5px solid #007bff;
        }
        .server1 { 
            background: linear-gradient(135deg, #e3f2fd, #bbdefb);
            border-left-color: #2196f3;
        }
        .server2 { 
            background: linear-gradient(135deg, #fff3e0, #ffcc80);
            border-left-color: #ff9800;
        }
        .server-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            color: white;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .server1 .server-badge { background: #2196f3; }
        .server2 .server-badge { background: #ff9800; }
        
        .action-buttons {
            text-align: center;
            margin: 20px 0;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            margin: 5px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.3s;
        }
        .btn:hover { background: #0056b3; }
        .btn-danger { background: #dc3545; }
        .btn-danger:hover { background: #c82333; }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .stat-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #dee2e6;
            text-align: center;
        }
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #007bff;
        }
        .stat-label {
            color: #6c757d;
            font-size: 14px;
        }
        
        .session-id {
            font-family: monospace;
            background: #f8f9fa;
            padding: 5px;
            border-radius: 3px;
            word-break: break-all;
        }
    </style>
    <script>
        // Auto-refresh functionality
        let autoRefresh = false;
        let refreshInterval;
        
        function toggleAutoRefresh() {
            const btn = document.getElementById('autoRefreshBtn');
            if (autoRefresh) {
                clearInterval(refreshInterval);
                autoRefresh = false;
                btn.textContent = 'Start Auto Refresh';
                btn.style.background = '#28a745';
            } else {
                refreshInterval = setInterval(() => {
                    window.location.reload();
                }, 3000);
                autoRefresh = true;
                btn.textContent = 'Stop Auto Refresh';
                btn.style.background = '#ffc107';
            }
        }
        
        function confirmInvalidate() {
            return confirm('Are you sure you want to invalidate the current session?');
        }
    </script>
</head>
<body>
    <div class="container">
        <h1 style="text-align: center; color: #333;">🔄 Sticky Session Test</h1>
        <p style="text-align: center; color: #666;">Testing load balancer session affinity</p>
        
        <div class="info-box <%= serverClass %>">
            <div class="server-badge"><%= serverName %></div>
            <h2>Server Information</h2>
            <p><strong>Server:</strong> <%= serverInfo %></p>
            <p><strong>Server Port:</strong> <%= serverPort %></p>
            <p><strong>JVM Route:</strong> <%= jvmRoute %></p>
            <p><strong>Session ID:</strong> <span class="session-id"><%= session.getId() %></span></p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value"><%= visitCount %></div>
                <div class="stat-label">Page Visits</div>
            </div>
            <div class="stat-card">
                <div class="stat-value"><%= session.getMaxInactiveInterval() %>s</div>
                <div class="stat-label">Session Timeout</div>
            </div>
            <div class="stat-card">
                <div class="stat-value"><%= serverPort %></div>
                <div class="stat-label">Server Port</div>
            </div>
            <div class="stat-card">
                <div class="stat-value"><%= new Date().getTime() - startTime.getTime() %>ms</div>
                <div class="stat-label">Session Age</div>
            </div>
        </div>
        
        <div class="info-box">
            <h3>Session Timeline</h3>
            <p><strong>Session Started:</strong> <%= startTime %></p>
            <p><strong>Current Time:</strong> <%= new Date() %></p>
            <p><strong>Last Request:</strong> Just now</p>
        </div>
        
        <div class="action-buttons">
            <a href="sessiontest.jsp" class="btn">🔄 Manual Refresh</a>
            <button id="autoRefreshBtn" class="btn" onclick="toggleAutoRefresh()" style="background: #28a745;">▶️ Start Auto Refresh</button>
            <a href="sessiontest.jsp?action=invalidate" class="btn btn-danger" onclick="return confirmInvalidate()">🗑️ Invalidate Session</a>
        </div>
        
        <% if ("invalidate".equals(request.getParameter("action"))) { %>
        <div class="info-box" style="border-left-color: #dc3545; background: #f8d7da;">
            <h3 style="color: #721c24;">✅ Session Invalidated!</h3>
            <p>A new session has been created. Visit count has been reset.</p>
        </div>
        <% } %>
        
        <div class="info-box">
            <h3>🧪 Testing Instructions</h3>
            <ol>
                <li><strong>Sticky Session Test:</strong> Refresh this page multiple times. The server port should remain the same.</li>
                <li><strong>Auto Refresh Test:</strong> Click "Start Auto Refresh" to automatically test every 3 seconds.</li>
                <li><strong>Session Persistence:</strong> The visit count should increment with each refresh.</li>
                <li><strong>Load Balancer Test:</strong> Open this page in different browsers - they may hit different servers.</li>
                <li><strong>Session Reset:</strong> Click "Invalidate Session" to test new session creation.</li>
            </ol>
        </div>
    </div>
</body>
</html>