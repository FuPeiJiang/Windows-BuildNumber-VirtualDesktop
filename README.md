https://github.com/slnz00/VirtualDesktopDumper<br>
https://github.com/NyaMisty/GetVirtualDesktopAPI_DIA<br>
<br>
but translated to ahk_v2<br>
extract_vftables.ah2 covers all the important ones<br>
extract_extras_unchanging.ah2 is for completeness<br>
<br>
byVersion.txt
```
if (buildNumber < 20348) {
} else if (buildNumber < 22000) { ;22000.51 to be more precise
} else if (buildNumber < 22483) { ;22483.1000 to be more precise
} else if (buildNumber.revisionNumber < 22621.2215) {
} else if (buildNumber.revisionNumber < 22631.3085) {
} else {
}
```
```
if (buildNumber < 20348) {
    ;from 17763.1
} else if (buildNumber < 22000) { ;22000.51 to be more precise
    ;from 20348.2227 - Windows Server 2022
} else if (buildNumber < 22483) { ;22483.1000 to be more precise
    ;from 22000.51
} else if (buildNumber.revisionNumber < 22621.2215) {
    ;from 22483.1000
    ;from 22621.1778 (they're identical)
    ;yeah yeah, IID are the same as above, but vftable differs
} else if (buildNumber.revisionNumber < 22631.3085) {
    ;from 22621.2215
} else {
    ;from 22631.3085
    ;the only difference with the above is IID_IVirtualDesktopNotification
}
```

<br>find.mjs: which `.dll` contain "D7C641189D4FC042AF418747538F10E5"=IID_IApplicationViewCollection ?<br>
download.mjs: copies specified `.dll` from System32 to specified folder, and downloads corresponding `.pdb`<br>