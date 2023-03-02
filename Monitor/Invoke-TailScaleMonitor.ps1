function Invoke-TailScaleMonitor {
    [CmdletBinding()]
    param (
    
    $SleepSeconds = 60,

    $LocalSSID = "ORBI14"
    )
    
    begin {
    #check to see if tailscale installed
    if (-not ($env:path -split ";" | select-string TailScale)) {
        if (-not (get-service tailscale)) {
            Write-Error "Tailscale not installed, nothing to do"
            return
        }
        Write-Error "Possible issue with Tailscale installation, aborting execution"
        return
    }
    }
    
    process {
        while ($true) {
            $ConnectedNICs = Get-NetAdapter | where-object {$_.ConnectorPresent -and $_.Mediaconnectionstate -eq "Connected" }
            if (-not $ConnectedNICs) {
                Write-Warning "No Connected NICs found, rechecking in $SleepSeconds"
                Start-Sleep -Seconds $SleepSeconds
                continue
            }
            
            $LocalWifi = Get-WifiInterfaces | Where-Object {$_.state -eq "Connected" -and $_.SSID -in $LocalSSID}
            $TSStatus = Invoke-Expression 'tailscale status --self --json' | ConvertFrom-Json
            
            if ($LocalWifi) {
                if ($TSStatus.BackendState -eq "Stopped") {
                    Write-Verbose "Local Wifi detected, but Tailscale appears stopped, no action taken"
                }
                Else {
                    Write-Verbose "Local Wifi detected, stopping TailScale"
                    $TSDown = Invoke-Expression 'tailscale down' | ConvertFrom-Json
                    $TSStatus = Invoke-Expression 'tailscale status --self --json' | ConvertFrom-Json
                    If (-not $TSStatus.BackendState -eq "Stopped") {
                        Write-Warning "Issue shutting down TailScale"
                        return
                }
                }
            }
            else {
                Write-Verbose "Non-Local Wifi detected, starting TailScale"
                $TSUp = Invoke-Expression 'tailscale up --json' | ConvertFrom-Json
                $TSStatus = Invoke-Expression 'tailscale status --self --json' | ConvertFrom-Json
                If (-not $TSStatus.BackendState -eq "Running") {
                    Write-Warning "Issue Starting up TailScale"
                    return
                }
            }
        Write-Verbose "Rechecking after $SleepSeconds second(s)..."
        Start-Sleep -Seconds $SleepSeconds
        }        
    }    
    end {
        
    }
}