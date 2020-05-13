$csv = import-csv 'Utilisateurs.csv' -Delimiter ';'

ForEach ($data in $csv){
    $data_ou = $($data.Service)
    Write-Host $data_ou
}
