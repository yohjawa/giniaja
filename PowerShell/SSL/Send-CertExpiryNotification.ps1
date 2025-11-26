$smtpServer = "smtp.mydomain.com"
$smtpPort = 25
$smtpFrom = "cert-expiry@mydomain.com"
$smtpTo = "me@mydomain.com"
$smtpSubject = "SSL certificate about to expired"
$expThreshold = 365


$certName = "certname.mydomain.com"
$isExpired = Get-ChildItem -Path cert: -Recurse -ExpiringInDays $expThreshold | Where-Object {$_.FriendlyName -eq $certName} | Select-Object FriendlyName,NotAfter

if($isExpired) {

    $smtpBody = "
        <p> The following certificate is about to expired </p> <br />
        <table border=1 style='border-collapse: collapse;'>
            <tr>
                <th>Certificate Name</th>
                <th>Expiry Date</th>
            </tr>
            <tr>
                <td>" + $certName + "</td>
                <td>" + $isExpired.NotAfter + "</td>
            </tr>
        </table><br />
        <p>Please renew the certificate to ensure there is no interuption with the service using it</p><br />
        </br>
        <p>
        Thanks
        </p>
    "

    Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -From $smtpFrom -To $smtpTo -Subject $smtpSubject -Body $smtpBody -BodyAsHtml
}