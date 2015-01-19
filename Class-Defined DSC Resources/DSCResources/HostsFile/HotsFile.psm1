enum Ensure
{
   Absent
   Present
}
 
[DscResource()]
class HostsFile
{
   [DscResourceKey()]
   [string] $IPAddress
 
   [DscResourceKey()]
   [string] $HostName
 
   [Ensure] $Ensure
 
   [void] Set()
   {
      $hostEntry = "`n${IPAddress}`t${HostName}"
      if($Ensure -eq [Ensure]::Present)
      {
          Write-Verbose "Adding a Hosts File entry"
          Add-Content -Path "${env:windir}\system32\drivers\etc\hosts" -Value $hostEntry -Force -Encoding ASCII
          Write-Verbose "Added a hosts File entry"
      }
      else
      {
          Write-Verbose "removing hosts file entry"
          ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -notmatch "^\s*$") -notmatch "^[^#]*$IPAddress\s+$HostName" | Set-Content "${env:windir}\system32\drivers\etc\hosts"
          Write-Verbose "removed hosts file entry"
      }
    }
 
    [bool] Test()
    {
        try {
           Write-Verbose "Checking if hosts file exists"
           $entryExist = ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -match "^[^#]*$IPAddress\s+$HostName")
 
           if ($Ensure -eq "Present") {
               if ($entryExist) {
                   Write-Verbose "Hosts file entry does not exist"
                   return $true
               } else {
                   Write-Verbose "Hosts file entry does not exist while it should"
                   return $false
               }
           } else {
               if ($entryExist) {
                   Write-Verbose "Hosts file entry exists while it should not"
                   return $false
               } else {
                   Write-Verbose "Hosts file entry does not exist"
                   return $true
               }
            }
         }
         catch {
             $exception = $_
             Write-Verbose "Error occurred"
             while ($exception.InnerException -ne $null)
             {
                 $exception = $exception.InnerException
                 Write-Verbose $exception.message
             }
          }
      }
 
      [HostsFile] Get()
      {
          $Configuration = [hashtable]::new()
          $Configuration.Add("IPAddress",$IPAddress)
          $Configuration.Add("HostName",$HostName)
 
          Write-Verbose "Checking Hosts file entry"
          try {
             if ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -match "^[^#]*$IPAddress\s+$HostName") {
                Write-Verbose "Hosts file entry found"
                $Configuration.Add('Ensure','Present')
             } else {
                Write-Verbose "Hosts File entry not found"
                $Configuration.Add('Ensure','Absent')
             }
          }
 
          catch {
             $exception = $_
             Write-Verbose "Error occurred"
             while ($exception.InnerException -ne $null)
             {
                 $exception = $exception.InnerException
                 Write-Verbose $exception.message
             }
          }
          return $Configuration
     }
}
