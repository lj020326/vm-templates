# // first argument is mapped to $url
## ref: https://amgeneral.wordpress.com/2019/01/03/powershell-download-certificate-chain-from-https-site/
param(
    [string] $CERT_URL_ENDPOINT = $env:CERT_URL_ENDPOINT
)

## ref: https://stackoverflow.com/questions/48603203/powershell-invoke-webrequest-throws-webcmdletresponseexception
[System.Net.ServicePointManager]::SecurityProtocol = (
    [System.Net.ServicePointManager]::SecurityProtocol -bor
    [System.Net.SecurityProtocolType]::Tls12
)

## ref: https://stackoverflow.com/questions/34331206/ignore-ssl-warning-with-powershell-downloadstring#58323408
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};

#[Net.HttpWebRequest] $webRequest = [Net.WebRequest]::create($CERT_URL_ENDPOINT)
[Net.HttpWebRequest] $webRequest = [Net.HttpWebRequest]::create($CERT_URL_ENDPOINT)

[Net.HttpWebResponse] $result = $webRequest.GetResponse()
Write-Output "result: $result"

$cert = $webRequest.ServicePoint.Certificate
$chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
$chain.build($cert)
$chain.ChainElements.Certificate | % {set-content -value $($_.Export([Security.Cryptography.X509Certificates.X509ContentType]::Cert)) -encoding byte -path "$pwd\$($_.Thumbprint).cer"}

## ref: https://stackoverflow.com/questions/53531462/how-to-install-multiple-certificates-using-powershell
foreach ( $file in ( Get-ChildItem "$pwd\" -filter *.cer )) {
    ## ref: https://superuser.com/questions/1506440/import-certificates-using-command-line-on-windows
    Import-Certificate -FilePath $file.fullname -CertStoreLocation Cert:\LocalMachine\Root
}
