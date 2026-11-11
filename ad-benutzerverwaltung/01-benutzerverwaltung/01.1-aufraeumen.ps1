<#
.SYNOPSIS
    Entfernt die Uebungs-OU "Alpenwerk" samt Inhalt aus der Test-Domaene.

.DESCRIPTION
    Hebt den Schutz vor versehentlichem Loeschen auf allen OUs unter der Uebungs-OU auf und loescht
    die OU rekursiv (Benutzer, Gruppen, Unter-OUs). Sicherheitsabfrage: Das Skript bricht ab, wenn
    die Domaene nicht der erwarteten Test-Domaene entspricht.
    Freigaben und Ordner auf CL01 werden nicht angefasst (siehe Uebung, Teil 3).

.EXAMPLE
    .\01.1-aufraeumen.ps1 -WhatIf
    .\01.1-aufraeumen.ps1

.NOTES
    Zu Uebung 01.1 (Benutzerverwaltung im Active Directory). Nur in der Test-Domaene ausfuehren.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$ErwarteteDomaene = 'alpenwerk.example',
    [string]$Root = 'Alpenwerk'
)

Import-Module ActiveDirectory -ErrorAction Stop

$domaene = Get-ADDomain
if ($domaene.DNSRoot -ne $ErwarteteDomaene) {
    throw "Falsche Domaene '$($domaene.DNSRoot)', erwartet '$ErwarteteDomaene'. Abbruch."
}

$rootDn = "OU=$Root,$($domaene.DistinguishedName)"
$rootOu = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$rootDn'" -ErrorAction SilentlyContinue
if (-not $rootOu) {
    Write-Host "Nichts zu tun: $rootDn existiert nicht."
    return
}

Get-ADOrganizationalUnit -SearchBase $rootDn -SearchScope Subtree -Filter * -Properties ProtectedFromAccidentalDeletion |
    Where-Object { $_.ProtectedFromAccidentalDeletion } |
    Set-ADObject -ProtectedFromAccidentalDeletion $false

if ($PSCmdlet.ShouldProcess($rootDn, 'OU samt Inhalt loeschen')) {
    Remove-ADOrganizationalUnit -Identity $rootDn -Recursive -Confirm:$false
    Write-Host "Geloescht: $rootDn"
}
