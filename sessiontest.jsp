<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Random" %>
<%
    // Get server info
    String serverPort = String.valueOf(request.getServerPort());
    String serverInfo = application.getServerInfo();
    String jvmRoute = System.getProperty("jvmRoute", "unknown");
    
    // Available servers for switching
    List<String> availableServers = new ArrayList<>();
    availableServers.add("tomcat1");
    availableServers.add("tomcat2");
    
    // Handle session invalidation
    if ("invalidate".equals(request.getParameter("action"))) {
        session.invalidate();
        session = request.getSession(true); // Create new session
    }
    
    // Check for specific route parameter
    String specifiedRoute = request.getParameter("route");
    boolean dynamicSwitchEnabled = "true".equals(request.getParameter("dynamicSwitch"));
    
    // Handle switch server request
    boolean switchRequested = "true".equals(request.getParameter("switchServer"));
    String switchMessage = null;
    
    if (switchRequested && dynamicSwitchEnabled) {
        // Determine available servers other than the current one
        List<String> otherServers = new ArrayList<>(availableServers);
        otherServers.remove(jvmRoute); // Remove current server from options
        
        if (!otherServers.isEmpty()) {
            // Pick a random server from the remaining options
            Random rand = new Random();
            String targetServer = otherServers.get(rand.nextInt(otherServers.size()));
            specifiedRoute = targetServer; // Set the target for this request
            switchMessage = "Switching to server: " + targetServer;
        } else {
            switchMessage = "No other servers available. Staying on current server.";
        }
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
    
    // Track server history
    List<String> serverHistory = (List<String>) session.getAttribute("serverHistory");
    if (serverHistory == null) {
        serverHistory = new ArrayList<String>();
    }
    serverHistory.add(jvmRoute + " (Port " + serverPort + ")");
    session.setAttribute("serverHistory", serverHistory);
    
    Date startTime = (Date) session.getAttribute("startTime");
    
    // Determine server class based on jvmRoute
    String serverClass = jvmRoute.equals("tomcat1") ? "server1" : "server2";
    String serverName = jvmRoute.equals("tomcat1") ? "Instance 1" : "Instance 2";
    
    // Get request origin info
    String routeMethod = specifiedRoute != null ? "Manual Selection" : 
                         dynamicSwitchEnabled ? "Dynamic Switching Enabled" : "Load Balancer Decision";
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
        .btn-warning { background: #ffc107; }
        .btn-warning:hover { background: #e0a800; }
        
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
        
        .routing-info {
            background: linear-gradient(135deg, #f3f4f6, #e5e7eb);
            border-left-color: #6366f1;
            padding: 15px;
            margin-top: 20px;
            border-radius: 8px;
            border-left: 5px solid #6366f1;
        }
        
        .home-btn {
            display: inline-block;
            padding: 10px 20px;
            background: #6c757d;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 20px;
        }
        
        .server-history {
            margin-top: 20px;
            max-height: 200px;
            overflow-y: auto;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 15px;
        }
        
        .server-history ul {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        
        .server-history li {
            padding: 8px;
            border-bottom: 1px solid #eee;
        }
        
        .server-history li:last-child {
            border-bottom: none;
            font-weight: bold;
        }
        
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 8px;
        }
        
        .alert-success {
            background-color: #d4edda;
            border-color: #c3e6cb;
            color: #155724;
        }
        
        .alert-info {
            background-color: #d1ecf1;
            border-color: #bee5eb;
            color: #0c5460;
        }
        
        .tooltip {
            position: relative;
            display: inline-block;
            border-bottom: 1px dotted #ccc;
            cursor: help;
        }
        
        .tooltip .tooltip-text {
            visibility: hidden;
            width: 200px;
            background-color: #555;
            color: #fff;
            text-align: center;
            border-radius: 6px;
            padding: 5px;
            position: absolute;
            z-index: 1;
            bottom: 125%;
            left: 50%;
            margin-left: -100px;
            opacity: 0;
            transition: opacity 0.3s;
        }
        
        .tooltip:hover .tooltip-text {
            visibility: visible;
            opacity: 1;
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
                // Preserve URL parameters when refreshing
                const currentUrl = window.location.href.split('?')[0];
                const params = new URLSearchParams(window.location.search);
                
                // Remove switch parameter if it exists
                params.delete('switchServer');
                
                refreshInterval = setInterval(() => {
                    window.location.href = currentUrl + '?' + params.toString();
                }, 3000);
                autoRefresh = true;
                btn.textContent = 'Stop Auto Refresh';
                btn.style.background = '#ffc107';
            }
        }
        
        function confirmInvalidate() {
            return confirm('Are you sure you want to invalidate the current session?');
        }
        
        function switchServer() {
            // Get current URL and parameters
            const currentUrl = window.location.href.split('?')[0];
            const params = new URLSearchParams(window.location.search);
            
            // Add switch parameter
            params.set('switchServer', 'true');
            
            // Navigate to the new URL
            window.location.href = currentUrl + '?' + params.toString();
        }
    </script>
</head>
<body>
    <div class="container">
        <h1 style="text-align: center; color: #333;">🔄 Sticky Session Test</h1>
        <p style="text-align: center; color: #666;">Testing load balancer session affinity</p>
        
        <% if (switchMessage != null) { %>
            <div class="alert alert-info">
                <strong>Server Switch:</strong> <%= switchMessage %>
            </div>
        <% } %>
        
        <div class="info-box <%= serverClass %>">
            <div class="server-badge"><%= serverName %></div>
            <h2>Server Information</h2>
            <p><strong>Server:</strong> <%= serverInfo %></p>
            <p><strong>Server Port:</strong> <%= serverPort %></p>
            <p><strong>JVM Route:</strong> <%= jvmRoute %></p>
            <p><strong>Session ID:</strong> <span class="session-id"><%= session.getId() %></span></p>
        </div>
        
        <div class="routing-info">
            <h3>Routing Information</h3>
            <p><strong>Routing Method:</strong> <%= routeMethod %></p>
            <% if (specifiedRoute != null) { %>
                <p><strong>Requested Route:</strong> <%= specifiedRoute %></p>
            <% } %>
            <% if (dynamicSwitchEnabled) { %>
                <p><strong>Dynamic Server Switching:</strong> 
                    <span class="tooltip">Enabled
                        <span class="tooltip-text">You can click the "Switch Server" button to send your next request to a different server.</span>
                    </span>
                </p>
            <% } %>
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
                <div class="stat-value"><%= serverHistory.size() %></div>
                <div class="stat-label">Server Changes</div>
            </div>
            <div class="stat-card">
                <div class="stat-value"><%= new Date().getTime() - startTime.getTime() %>ms</div>
                <div class="stat-label">Session Age</div>
            </div>
        </div>
        
        <div class="server-history">
            <h3>Server Access History</h3>
            <ul>
                <% for (int i = 0; i < serverHistory.size(); i++) { %>
                    <li><%= (i+1) %>. <%= serverHistory.get(i) %></li>
                <% } %>
            </ul>
        </div>
        
        <div class="action-buttons">
            <% 
                // Preserve route parameters in refresh links
                String currentParams = "";
                if (specifiedRoute != null) {
                    currentParams += "route=" + specifiedRoute;
                }
                if (dynamicSwitchEnabled) {
                    if (!currentParams.isEmpty()) currentParams += "&";
                    currentParams += "dynamicSwitch=true";
                }
                String refreshUrl = "sessiontest.jsp" + (currentParams.isEmpty() ? "" : "?" + currentParams);
                String invalidateUrl = "sessiontest.jsp?action=invalidate" + (currentParams.isEmpty() ? "" : "&" + currentParams);
            %>
            <a href="<%= refreshUrl %>" class="btn">🔄 Manual Refresh</a>
            <button id="autoRefreshBtn" class="btn" onclick="toggleAutoRefresh()" style="background: #28a745;">▶️ Start Auto Refresh</button>
            
            <% if (dynamicSwitchEnabled) { %>
                <button onclick="switchServer()" class="btn btn-warning">🔀 Switch Server</button>
            <% } %>
            
            <a href="<%= invalidateUrl %>" class="btn btn-danger" onclick="return confirmInvalidate()">🗑️ Invalidate Session</a>
            <a href="index.html" class="home-btn">🏠 Back to Home</a>
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
                <% if (dynamicSwitchEnabled) { %>
                    <li><strong>Dynamic Server Switching:</strong> Click the "Switch Server" button to force your next request to go to a different server.</li>
                <% } else { %>
                    <li><strong>Server Selection:</strong> Return to home and select a specific server or enable dynamic switching.</li>
                <% } %>
                <li><strong>Session Reset:</strong> Click "Invalidate Session" to test new session creation.</li>
            </ol>
        </div>
    </div>
</body>
</html>