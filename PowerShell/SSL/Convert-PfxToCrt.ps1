$dpath = "C:\temp\certs"
$dfile = $dpath + "\cert1.pfx"
$ofile = $dpath + +"\cert1.pem"
$crtFile = $dpath + "\cert1.crt"
$keyFile = $dpath + "\cert1.key"
$certPass = "c3rtp@ss"

Convert-PfxToPem -InputFile $dfile -OutputFile $ofile -Password (ConvertTo-SecureString -String $certPass -AsPlainText -Force)

(Get-Content $ofile -Raw) -match "(?ms)(\s*((?<privatekey>-----BEGIN PRIVATE KEY-----.*?-----END PRIVATE KEY-----)|(?<certificate>-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----))\s*){2}"

$Matches["privatekey"] | Set-Content $keyFile
$Matches["certificate"] | Set-Content $crtFile
