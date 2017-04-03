$CloudUsername=read-host -Prompt 'Please Enter the Cloud Account User Name';
$CloudAPIKey=read-host -Prompt 'Please the API Key';
$exporturl='C:\Users\'+$env:USERNAME+'\Desktop\cloudfile.csv'
Set-Variable -Name AuthBody -Value ('{"auth":{"RAX-KSKEY:apiKeyCredentials":{"username":"'+$CloudUsername+'", "apiKey":"'+$CloudAPIKey+'"}}}')
$url='https://identity.api.rackspacecloud.com/v2.0/tokens'

Try
{
$response=Invoke-WebRequest -Uri $url -ContentType application/json -Method Post -Body $AuthBody;
}
catch
{
    $ErrorMessage = $_.Exception.Message
    write-host $ErrorMessage
    break
}

$test=ConvertFrom-Json $response.Content 
$AUTH_TOKEN=$test.access.token.id
$cfendpoint=($test.access.serviceCatalog | Where-Object {$_.name -eq 'cloudFiles'} | Select-Object endpoints)
$cloudendpoint=$cfendpoint.endpoints.publicUrl
$curl=$cloudendpoint+'?format=json'

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.add("X-Auth-Token",$AUTH_TOKEN)

try{
    $Containers=Invoke-RestMethod -Method Get -Uri $curl -Headers $headers
}
catch
{
    $ErrorMessage = $_.Exception.Message
    write-host $ErrorMessage
    break
}

write-host 'Please Select one of the following options'
write-host '1: Get All cloud files Containers with size'
write-host '2: Get All cloud files Containers'
write-host '3: Export All Cloud file Containers and files'

$switchopt=read-host 

switch($switchopt)
{
    1{ Write-Output $Containers

     }
    2{Write-Output ($Containers | Select-Object name)
     
     }
     3{
          $col = @()
          foreach ($Container in $Containers)
                         {
                            #$Container.name
                            $conurl=$cloudendpoint+'/'+$Container.name+'?format=json'
    
                            $continerobj = New-Object System.Object
                            $continerobj | Add-Member -type NoteProperty -name ContainerName -value $Container.name
                            $containerdet=Invoke-RestMethod -Method Get -Uri $conurl -Headers $headers
                            $continerobj | Add-Member -type NoteProperty -name FileName -value $containerdet.name
                            $col +=  $continerobj

                         }

                    $list = @()
                    foreach ($c in $col)
                     {
                        foreach ($file in $c.FileName)
                        {
                            $list += New-Object PSObject -Property @{
                                FileName = $file
                                ContainerName = $C.ContainerName
                            }
                        }
                     }
                    $list | Export-csv $exporturl -notypeinformation
                    write-host 'File exported at '$exporturl
                

        }

}
