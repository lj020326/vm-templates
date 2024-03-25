
## ref: https://stackoverflow.com/questions/48603203/powershell-invoke-webrequest-throws-webcmdletresponseexception
#[System.Net.ServicePointManager]::SecurityProtocol = (
#    [System.Net.ServicePointManager]::SecurityProtocol -bor
#    [System.Net.SecurityProtocolType]::Tls12
#)

## ref: https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
## ref: https://stackoverflow.com/questions/48603203/powershell-invoke-webrequest-throws-webcmdletresponseexception
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
[System.Net.ServicePointManager]::SecurityProtocol = (
    [System.Net.ServicePointManager]::SecurityProtocol -bor
    [System.Net.SecurityProtocolType]::Tls12
)

## ref: https://stackoverflow.com/questions/34331206/ignore-ssl-warning-with-powershell-downloadstring#58323408
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};

## ref: https://superuser.com/questions/1287032/update-powershell-through-command-line
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
