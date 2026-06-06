<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Process;
use Illuminate\Support\Facades\File;

class LauncherController extends Controller
{
    private $projectRoot;
    private $pidFile;

    public function __construct()
    {
        $this->projectRoot = base_path('..');
        $this->pidFile = storage_path('app/launcher_pids.json');
    }

    /**
     * Display the launcher dashboard
     */
    public function index()
    {
        return view('launcher');
    }

    /**
     * Get network interfaces and IP addresses
     */
    public function getNetworkInfo()
    {
        try {
            // Use shell_exec for reliable PowerShell execution
            $psScript = "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { \$_.InterfaceAlias -notmatch 'Loopback' -and \$_.IPAddress -notmatch '^169' -and \$_.PrefixOrigin -ne 'WellKnown' } | Select-Object IPAddress, InterfaceAlias | ConvertTo-Json";
            $output = shell_exec("powershell -NoProfile -Command \"{$psScript}\" 2>&1");

            $ips = [];
            if (!empty($output)) {
                $decoded = json_decode(trim($output), true);
                if ($decoded) {
                    // Normalize to array if single result
                    if (isset($decoded['IPAddress'])) {
                        $decoded = [$decoded];
                    }
                    // Filter out gateway IPs (usually .1 or .254)
                    foreach ($decoded as $ip) {
                        if (isset($ip['IPAddress'])) {
                            $addr = $ip['IPAddress'];
                            $lastOctet = (int) substr($addr, strrpos($addr, '.') + 1);
                            // Skip gateway-like IPs
                            if ($lastOctet !== 1 && $lastOctet !== 254) {
                                $ips[] = $ip;
                            }
                        }
                    }
                }
            }

            // Add localhost option at the start
            array_unshift($ips, [
                'IPAddress' => 'localhost',
                'InterfaceAlias' => 'Local Development'
            ]);

            // If no IPs found, try alternative method
            if (count($ips) <= 1) {
                $hostname = gethostname();
                $hostIp = gethostbyname($hostname);
                if ($hostIp && $hostIp !== $hostname && $hostIp !== '127.0.0.1') {
                    $ips[] = [
                        'IPAddress' => $hostIp,
                        'InterfaceAlias' => 'Host IP'
                    ];
                }
            }

            return response()->json([
                'success' => true,
                'interfaces' => $ips
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => true,
                'message' => 'Exception: ' . $e->getMessage(),
                'interfaces' => [
                    ['IPAddress' => 'localhost', 'InterfaceAlias' => 'Local Development']
                ]
            ]);
        }
    }

    /**
     * Check server status on specified ports
     */
    public function getServerStatus(Request $request)
    {
        $ports = $request->input('ports', [3000, 6001, 8080]);

        // Handle string input (from query string)
        if (is_string($ports)) {
            $ports = json_decode($ports, true) ?? [3000, 6001, 8080];
        }

        $statuses = [];

        // Get all listening ports at once for efficiency
        $psScript = 'Get-NetTCPConnection -State Listen | Select-Object LocalPort | ConvertTo-Json';
        $output = shell_exec("powershell -NoProfile -Command \"{$psScript}\" 2>&1");

        $listeningPorts = [];
        if (!empty($output)) {
            $decoded = json_decode(trim($output), true);
            if ($decoded) {
                // Normalize to array
                if (isset($decoded['LocalPort'])) {
                    $decoded = [$decoded];
                }
                foreach ($decoded as $conn) {
                    if (isset($conn['LocalPort'])) {
                        $listeningPorts[(int) $conn['LocalPort']] = true;
                    }
                }
            }
        }

        foreach ($ports as $port) {
            $port = (int) $port;
            $statuses[$port] = [
                'running' => isset($listeningPorts[$port]),
                'port' => $port
            ];
        }

        return response()->json([
            'success' => true,
            'statuses' => $statuses
        ]);
    }

    /**
     * Start a server
     */
    public function startServer(Request $request)
    {
        $type = $request->input('type'); // laravel, reverb, flutter
        $port = $request->input('port');
        $host = $request->input('host', '0.0.0.0');

        try {
            $command = '';
            $cwd = '';

            switch ($type) {
                case 'laravel':
                    $cwd = base_path();
                    $command = "start /B php artisan serve --host={$host} --port={$port}";
                    break;

                case 'reverb':
                    $cwd = base_path();
                    $command = "start /B php artisan reverb:start --host={$host} --port={$port}";
                    break;

                case 'flutter':
                    $cwd = $this->projectRoot;
                    $command = "start /B flutter run -d web-server --web-port={$port} --web-hostname={$host}";
                    break;

                default:
                    return response()->json([
                        'success' => false,
                        'message' => 'Unknown server type'
                    ]);
            }

            // Execute via cmd to properly start background process
            $fullCommand = "cd /d \"{$cwd}\" && {$command}";
            pclose(popen("start /B cmd /C \"{$fullCommand}\"", 'r'));

            // Wait a moment for server to start
            sleep(2);

            return response()->json([
                'success' => true,
                'message' => ucfirst($type) . ' server starting on port ' . $port,
                'command' => $fullCommand
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Stop a server running on a specific port
     */
    public function stopServer(Request $request)
    {
        $port = $request->input('port');

        try {
            // Find and kill process using the port
            $psCommand = 'Get-NetTCPConnection -LocalPort ' . $port . ' -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }';
            $result = Process::run(['powershell', '-Command', $psCommand]);

            return response()->json([
                'success' => true,
                'message' => "Stopped server on port {$port}"
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Kill process by port (alternative method)
     */
    public function killPort(Request $request)
    {
        $port = $request->input('port');

        try {
            // Find PID using netstat and kill it
            $findCommand = "netstat -ano | findstr :{$port} | findstr LISTENING";
            $result = Process::run("cmd /C \"{$findCommand}\"");

            $output = trim($result->output());
            if (!empty($output)) {
                // Extract PID from netstat output (last column)
                $lines = explode("\n", $output);
                foreach ($lines as $line) {
                    $parts = preg_split('/\s+/', trim($line));
                    $pid = end($parts);
                    if (is_numeric($pid)) {
                        Process::run("taskkill /F /PID {$pid}");
                    }
                }
            }

            return response()->json([
                'success' => true,
                'message' => "Killed process on port {$port}"
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Update Flutter constants.dart file
     */
    public function updateConstants(Request $request)
    {
        $ip = $request->input('ip');
        $apiPort = $request->input('apiPort', 3000);
        $reverbPort = $request->input('reverbPort', 6001);

        $constantsPath = $this->projectRoot . '/lib/core/constants.dart';

        try {
            if (!File::exists($constantsPath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'constants.dart not found'
                ]);
            }

            $content = File::get($constantsPath);

            // Update API URL
            $content = preg_replace(
                "/static const String apiBaseUrl = '[^']+';/",
                "static const String apiBaseUrl = 'http://{$ip}:{$apiPort}/api';",
                $content
            );

            // Update Reverb host
            $content = preg_replace(
                "/static const String reverbHost = '[^']+';/",
                "static const String reverbHost = '{$ip}';",
                $content
            );

            // Update Reverb port
            $content = preg_replace(
                "/static const int reverbPort = \d+;/",
                "static const int reverbPort = {$reverbPort};",
                $content
            );

            File::put($constantsPath, $content);

            return response()->json([
                'success' => true,
                'message' => 'constants.dart updated successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Get current configuration from constants.dart
     */
    public function getConstants()
    {
        $constantsPath = $this->projectRoot . '/lib/core/constants.dart';

        try {
            if (!File::exists($constantsPath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'constants.dart not found'
                ]);
            }

            $content = File::get($constantsPath);

            // Extract current values
            preg_match("/apiBaseUrl = '([^']+)'/", $content, $apiMatch);
            preg_match("/reverbHost = '([^']+)'/", $content, $hostMatch);
            preg_match("/reverbPort = (\d+)/", $content, $portMatch);

            return response()->json([
                'success' => true,
                'config' => [
                    'apiBaseUrl' => $apiMatch[1] ?? '',
                    'reverbHost' => $hostMatch[1] ?? '',
                    'reverbPort' => (int) ($portMatch[1] ?? 6001)
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Scan common ports and return which are in use with process details
     */
    public function scanPorts(Request $request)
    {
        $portsToScan = $request->input('ports', [3000, 6001, 8080, 8081, 8082, 8000, 5173, 4200, 3001, 5000]);

        // Handle string input
        if (is_string($portsToScan)) {
            $portsToScan = json_decode($portsToScan, true) ?? [3000, 6001, 8080, 8081, 8082];
        }

        $results = [];

        try {
            // Use shell_exec for more reliable PowerShell execution on Windows
            $psScript = 'Get-NetTCPConnection -State Listen | Select-Object LocalPort, OwningProcess | ConvertTo-Json';
            $output = shell_exec("powershell -NoProfile -Command \"{$psScript}\" 2>&1");

            $connections = [];
            if (!empty($output)) {
                $decoded = json_decode(trim($output), true);
                if ($decoded) {
                    // Normalize to array
                    if (isset($decoded['LocalPort'])) {
                        $decoded = [$decoded];
                    }
                    foreach ($decoded as $conn) {
                        if (isset($conn['LocalPort'])) {
                            $connections[(int) $conn['LocalPort']] = (int) $conn['OwningProcess'];
                        }
                    }
                }
            }

            // Check each port
            foreach ($portsToScan as $port) {
                $port = (int) $port;
                $portInfo = [
                    'port' => $port,
                    'running' => isset($connections[$port]),
                    'pid' => $connections[$port] ?? null,
                    'process' => null
                ];

                // Get process name if running
                if ($portInfo['pid']) {
                    $pid = $portInfo['pid'];
                    $procOutput = shell_exec("powershell -NoProfile -Command \"Get-Process -Id {$pid} -ErrorAction SilentlyContinue | Select-Object ProcessName | ConvertTo-Json\" 2>&1");
                    if (!empty($procOutput)) {
                        $procInfo = json_decode(trim($procOutput), true);
                        if ($procInfo && isset($procInfo['ProcessName'])) {
                            $portInfo['process'] = $procInfo['ProcessName'];
                        }
                    }
                }

                $results[] = $portInfo;
            }

            return response()->json([
                'success' => true,
                'ports' => $results
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'ports' => []
            ]);
        }
    }

    /**
     * Kill a process by PID
     */
    public function killProcess(Request $request)
    {
        $pid = $request->input('pid');

        if (!$pid || !is_numeric($pid)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid PID'
            ]);
        }

        try {
            $output = shell_exec("taskkill /F /PID {$pid} 2>&1");

            // Check if successful
            if (strpos($output, 'SUCCESS') !== false || strpos($output, 'terminated') !== false) {
                return response()->json([
                    'success' => true,
                    'message' => "Process {$pid} terminated"
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => trim($output) ?: "Failed to kill process {$pid}"
                ]);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Get all available Flutter devices
     */
    public function getFlutterDevices()
    {
        try {
            // Run flutter devices --machine for JSON output
            $output = shell_exec("cd /d \"{$this->projectRoot}\" && flutter devices --machine 2>&1");

            $devices = [];
            if (!empty($output)) {
                $decoded = json_decode(trim($output), true);
                if (is_array($decoded)) {
                    foreach ($decoded as $device) {
                        $devices[] = [
                            'id' => $device['id'] ?? 'unknown',
                            'name' => $device['name'] ?? 'Unknown Device',
                            'platform' => $device['targetPlatform'] ?? $device['platform'] ?? 'unknown',
                            'emulator' => $device['emulator'] ?? false,
                            'sdk' => $device['sdk'] ?? '',
                            'category' => $this->getDeviceCategory($device)
                        ];
                    }
                }
            }

            // Always add web-server option
            $hasWebServer = false;
            foreach ($devices as $d) {
                if ($d['id'] === 'web-server')
                    $hasWebServer = true;
            }
            if (!$hasWebServer) {
                $devices[] = [
                    'id' => 'web-server',
                    'name' => 'Web Server',
                    'platform' => 'web',
                    'emulator' => false,
                    'sdk' => 'Flutter Web',
                    'category' => 'web'
                ];
            }

            return response()->json([
                'success' => true,
                'devices' => $devices
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'devices' => []
            ]);
        }
    }

    /**
     * Get device category for UI grouping
     */
    private function getDeviceCategory($device)
    {
        $id = strtolower($device['id'] ?? '');
        $platform = strtolower($device['targetPlatform'] ?? $device['platform'] ?? '');

        if (str_contains($id, 'chrome'))
            return 'browser';
        if (str_contains($id, 'edge'))
            return 'browser';
        if (str_contains($id, 'web'))
            return 'web';
        if (str_contains($platform, 'android'))
            return 'android';
        if (str_contains($platform, 'ios'))
            return 'ios';
        if (str_contains($platform, 'windows'))
            return 'desktop';
        if (str_contains($platform, 'macos'))
            return 'desktop';
        if (str_contains($platform, 'linux'))
            return 'desktop';

        return 'other';
    }

    /**
     * Get ADB devices
     */
    public function getAdbDevices()
    {
        try {
            $output = shell_exec("adb devices -l 2>&1");

            $devices = [];
            if (!empty($output)) {
                $lines = explode("\n", trim($output));
                foreach ($lines as $line) {
                    $line = trim($line);
                    // Skip header and empty lines
                    if (empty($line) || str_starts_with($line, 'List of devices') || str_starts_with($line, '*')) {
                        continue;
                    }

                    // Parse device info: ID device product:... model:... device:...
                    if (preg_match('/^(\S+)\s+(device|offline|unauthorized)(.*)$/', $line, $matches)) {
                        $deviceId = $matches[1];
                        $status = $matches[2];
                        $info = $matches[3] ?? '';

                        // Extract model name
                        $model = 'Unknown';
                        if (preg_match('/model:(\S+)/', $info, $modelMatch)) {
                            $model = str_replace('_', ' ', $modelMatch[1]);
                        }

                        $devices[] = [
                            'id' => $deviceId,
                            'model' => $model,
                            'status' => $status,
                            'wireless' => str_contains($deviceId, ':')
                        ];
                    }
                }
            }

            return response()->json([
                'success' => true,
                'devices' => $devices
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'devices' => []
            ]);
        }
    }

    /**
     * Connect to ADB device via IP
     */
    public function connectAdbDevice(Request $request)
    {
        $ip = $request->input('ip');
        $port = $request->input('port', '5555');

        if (empty($ip)) {
            return response()->json([
                'success' => false,
                'message' => 'IP address is required'
            ]);
        }

        try {
            $address = "{$ip}:{$port}";
            $output = shell_exec("adb connect {$address} 2>&1");

            $success = str_contains($output, 'connected') || str_contains($output, 'already connected');

            return response()->json([
                'success' => $success,
                'message' => trim($output),
                'address' => $address
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Disconnect ADB device
     */
    public function disconnectAdbDevice(Request $request)
    {
        $address = $request->input('address');

        if (empty($address)) {
            return response()->json([
                'success' => false,
                'message' => 'Device address is required'
            ]);
        }

        try {
            $output = shell_exec("adb disconnect {$address} 2>&1");

            return response()->json([
                'success' => true,
                'message' => trim($output)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }

    /**
     * Launch Flutter on specified device(s)
     */
    public function launchFlutter(Request $request)
    {
        $deviceId = $request->input('device');
        $port = $request->input('port', 8080);

        if (empty($deviceId)) {
            return response()->json([
                'success' => false,
                'message' => 'Device ID is required'
            ]);
        }

        try {
            // Build the flutter run command
            $cmd = "flutter run -d {$deviceId}";

            // For web devices, add web-specific flags
            if (str_contains($deviceId, 'chrome') || str_contains($deviceId, 'edge') || $deviceId === 'web-server') {
                $cmd = "flutter run -d {$deviceId} --web-port={$port} --web-hostname=0.0.0.0";
            }

            // Run in background (Windows)
            $fullCmd = "cd /d \"{$this->projectRoot}\" && start /B cmd /c \"{$cmd}\"";
            pclose(popen($fullCmd, 'r'));

            return response()->json([
                'success' => true,
                'message' => "Launched Flutter on {$deviceId}",
                'command' => $cmd
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ]);
        }
    }
}
