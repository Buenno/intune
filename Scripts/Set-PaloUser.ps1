# Set the user-id on the Palo firewall via API

<#
Generate API Key

curl -H "Content-Type: application/x-www-form-urlencoded" -X POST https://firewall/api/?type=keygen -d 'user=<user>&password=<password>'
#>

$requestHeaders = @{
  "Content-Type" = "application/x-www-form-urlencoded"
}
$requestBody = "user=admin-tw&password=!BuenN08winadm"
$request = Invoke-WebRequest -Method Post -Uri "https://10.1.1.80/api/?type=keygen" -Headers $requestHeaders -Body $requestBody -SkipCertificateCheck

if ($request.StatusCode -eq "200"){
  [xml]$response = $request.Content
  $apiKey = $response.response.result.key
  return $apiKey
}