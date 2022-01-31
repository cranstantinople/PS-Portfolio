$SQL = @{}
$SQL.Server = "SQLSERVER:\SQL\PFL-APP01\DEFAULT\"
$SQL.$DataBases = Get-ChildItem "$($Server)databases"


ForEach ($DataBase in $DataBases) {
    $SQL.Tables = Get-ChildItem "$($Server)databases\$($DataBase.Name)\tables"
    ForEach ($Table in $SQL.Tables) {
    If ($Table.DataSpaceUsed -gt "0" -and $Table.DataSpaceUsed -lt "50000") {
        Read-SqlTableData $Table | Export-Csv "C:\TEMP\$($DataBase.Name)\$($Table.Name).csv" -Force 
    }
    }
}
