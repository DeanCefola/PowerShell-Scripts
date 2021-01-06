$List = Get-Content -LiteralPath 'C:\_VSTS\GitHub\Dean Cefola\DeploymentScripts\David\list.txt'
foreach ($Uri in $List) {
    $w = Invoke-WebRequest -Uri $Uri
    $Text = $w.AllElements | Where-Object tagname -EQ "P" | Select-Object innerText
    $results = $Text.innerText    
    If (($results) -match 'code name "Monad"'){
        write "$URI  -  oh YEAH!"
    }
    else {
        write "$URI  -  no joy"
    }
}
