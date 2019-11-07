<#
.SYNOPSIS
Formats Azure Flow Log JSON for ingestion into SOF-ELK
.DESCRIPTION
Formats Azure Flow Log JSON for ingestion into SOF-ELK
.PARAMETER AZUREFLOWLOG
Azure Flow Log JSON
.PARAMETER SOFELKFORMAT
SOF-ELK Format Outfile
.EXAMPLE
Convert-AZNetflow2csv.ps1 <azureflowlog> <outfile>
.LINK
https://www.cybermohr.com
https://cybermohr.ghost.io
.NOTES
Brian P. Mohr
brian@cybermohr.com
#>

[cmdletbinding()]
Param(
[Parameter(ValuefromPipeline=$true,Mandatory=$true)][string]$r,
[Parameter(ValuefromPipeline=$true,Mandatory=$true)][string]$w)

#Function to convert Unix timestamp to human readable
Function Convert-TimeStamp ($UnixTimeStamp) {
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixTimeStamp))
 }

$file = $r
$json = ConvertFrom-JSON (Get-Content $file -Raw)
$azflow = $json.records | Select-Object -ExpandProperty properties | `
    Select-Object -ExpandProperty flows | Select-Object -ExpandProperty flows | `
    Select-Object -ExpandProperty flowtuples | `
    ForEach-Object{
        $array = $_ -split ","
        #Only process flows that were ALLOWED and END flow
        if ($array[9]) {
            
            $props = @{
                exporterIP = "0.0.0.0"
                destinationAS = 0
                destinationMask = 0
                engineType = "0/0"
                timeStamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($array[0])).DateTime).ToString("yyyy-MM-dd H:mm:ss.000")
                flows = 0
                int1 = 0
                bytes = $array[10] + $array[12]
                packets = $array[9] + $array[11]
                inputInterface = 0
                destinationAddress = $array[2]
                nextHopAddress = "0.0.0.0"
                sourceAddress = $array[1]
                destinationPort = $array[4]
                sourcePort = $array[3]
                endTimestamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($array[0])).DateTime).ToString("yyyy-MM-dd H:mm:ss.000")
                outputInterface = 0
                protocol = if ($array[5] -eq "T") {
                    6
                }
                else {
                    17  
                }
                int2 = 0
                int3 = 0
                sourceAS = 0
                sourceMask = 0
                sourceTOS = 0
                TCPFlags = "......"
                version = 0
            }
            New-Object -TypeName PSObject -Property $props
        }
    }    
$azflow | Select-Object -Property exporterIP,destinationAS,destinationMask,engineType,timeStamp,flows,int1,bytes,packets, `
            inputInterface,destinationAddress,nextHopAddress,sourceAddress,destinationPort,sourcePort,endTimestamp, `
            outputInterface,protocol,int2,int3,sourceAS,sourceMask,sourceTOS,TCPFlags,version | `
            ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | Select-Object -Skip 1 |  ForEach-Object {$_ -replace '"',''} | `
            Out-File -FilePath $w -Force