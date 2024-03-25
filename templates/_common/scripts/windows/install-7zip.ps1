$ProgressPreference="SilentlyContinue"

for ([byte]$c = [char]'A'; $c -le [char]'Z'; $c++)  
{  
	$variablePath = [char]$c + ':\variables.ps1'

	if (test-path $variablePath) {
		. $variablePath
		break
	}
}

$version = '1604'
$msi_file_name = "7z$version-x64.msi"

if ($httpIp){
	if (!$httpPort){
    	$httpPort = "80"
    }
    $download_url = "http://$($httpIp):$($httpPort)/$msi_file_name"
} else {
    $download_url = "http://www.7-zip.org/a/$msi_file_name"
}

$dest_path = "C:\Windows\Temp\$msi_file_name"

## ref: https://stackoverflow.com/questions/34331206/ignore-ssl-warning-with-powershell-downloadstring#58323408
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};

#(New-Object System.Net.WebClient).DownloadFile($download_url, $dest_path)

## https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.3
## https://stackoverflow.com/questions/69124584/how-to-download-file-with-powershell
Invoke-WebRequest -Uri $download_url -OutFile $dest_path

$argumentList = '/qb /i "C:\Windows\Temp\' + $msi_file_name + '" INSTALLDIR="C:\7-zip"'
$process = Start-Process -FilePath "msiexec" -ArgumentList $argumentList -NoNewWindow -PassThru -Wait
$process.ExitCode
