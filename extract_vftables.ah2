extract_IID(dll_paths,pdb_paths) {
    msdia_path:=A_LineFile "\..\msdia80.dll"
    DllGetClassObject:=DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", msdia_path, "Ptr") || DllCall("LoadLibrary", "Str", msdia_path, "Ptr"), "AStr", "DllGetClassObject", "Ptr")
    DllCall("ole32\CLSIDFromString","WStr","{bce36434-2c24-499e-bf49-8bd99b0eeb68}","Ptr",CLSID_IDiaDataSource:=Buffer(16)) ;msdia80.dll
    DllCall("ole32\CLSIDFromString","WStr","{00000001-0000-0000-c000-000000000046}","Ptr",IID_IClassFactory:=Buffer(16))
    DllCall(DllGetClassObject,"Ptr",CLSID_IDiaDataSource,"Ptr",IID_IClassFactory,"Ptr*",&IClassFactory:=0)

    DllCall("ole32\CLSIDFromString","WStr","{79f1bb5f-b66e-48e5-b6a9-1545c323ca3d}","Ptr",IID_IDiaDataSource:=Buffer(16))

    toClip:=""
    for dll_path in dll_paths {
        pdb_path:=pdb_paths[A_Index]

        ComCall(3,IClassFactory,"Ptr",0,"Ptr",IID_IDiaDataSource,"Ptr*",&IDiaDataSource:=0)
        ComCall(4,IDiaDataSource,"WStr",pdb_path) ;loadDataFromPdb
        ComCall(8,IDiaDataSource,"Ptr*",&IDiaSession:=0) ;openSession

        symbols:=[]

        append_to_symbols_by_SymTagEnum(symbols,IDiaSession,10) ;10=SymTagPublicSymbol
        ;append_to_symbols_by_SymTagEnum(symbols,IDiaSession,11) ;11=SymTagUDT

        append_to_symbols_by_SymTagEnum(symbols,IDiaSession,SymTagEnum) {
            ComCall(5,IDiaSession,"Ptr*",&IDiaSymbol:=0) ;get_globalScope
            ComCall(85,IDiaSymbol,"Int",SymTagEnum,"Ptr",0,"Uint",0,"Ptr*",&IDiaEnumSymbols:=0) ;findChildren
            ComCall(4,IDiaEnumSymbols,"Int*",&pRetVal:=0) ;get_Count
            rgelt:=Buffer(pRetVal*A_PtrSize)
            ComCall(6,IDiaEnumSymbols,"Uint",pRetVal,"Ptr",rgelt,"Uint*",&pceltFetched:=0) ;Next
            i:=0
            while (i<rgelt.Size) {
                IDiaSymbol:=NumGet(rgelt,i,"Ptr")
                symbols.Push(obj_from_IDiaSymbol(IDiaSymbol))
                i+=8
            }
        }

        obj_from_IDiaSymbol(IDiaSymbol) {
            ComCall(100,IDiaSymbol,"Uint*",&udtKind:=0) ;get_udtKind
            ComCall(5,IDiaSymbol,"WStr*",&name) ;get_name
            ComCall(74,IDiaSymbol,"WStr*",&undecoratedName) ;get_undecoratedName
            ComCall(14,IDiaSymbol,"UInt64*",&virtualAddress:=0) ;get_virtualAddress
            ComCall(17,IDiaSymbol,"UInt64*",&length:=0) ;get_length

            UDT_ENUM_TO_STR:=["struct","class","union","interface"]
            udtKind_str:=UDT_ENUM_TO_STR[udtKind+1]
            return {
                udtKind_str:udtKind_str,
                udtKind:udtKind,
                name:name,
                undecoratedName:undecoratedName,
                virtualAddress:virtualAddress,
                length:length,
            }
        }

        buf:=FileRead(dll_path,"RAW")

        e_lfanew:=NumGet(buf,0x3C,"Int")

        NumberOfSections:=NumGet(buf,e_lfanew+0x6,"UShort")
        SizeOfOptionalHeader:=NumGet(buf,e_lfanew+0x14,"UShort")

        sections_offset:=e_lfanew + 0x18 + SizeOfOptionalHeader

        ImageBase:=NumGet(buf,e_lfanew + 0x30,"Ptr")

        ptr:=sections_offset
        end:=sections_offset + 0x28*NumberOfSections
        sections:=[]
        while (ptr < end) {

            name:=StrGet(buf.Ptr+ptr,"UTF-8")
            Misc_VirtualSize:=NumGet(buf,ptr+0x08,"Int")
            VirtualAddress:=NumGet(buf,ptr+0x0C,"Int")
            SizeOfRawData:=NumGet(buf,ptr+0x10,"Int")
            PointerToRawData:=NumGet(buf,ptr+0x14,"Int")

            section:={
                name:name,
                Misc_VirtualSize:Misc_VirtualSize,
                VirtualAddress:VirtualAddress,
                SizeOfRawData:SizeOfRawData,
                PointerToRawData:PointerToRawData,
            }
            sections.Push(section)
            ptr+=0x28
        }

        get_offset_by_rva(sections,rva) {
            for section in sections {
                size:=Max(section.SizeOfRawData, section.Misc_VirtualSize)
                if ((section.VirtualAddress <= rva) && (rva < section.VirtualAddress + size)) {
                    ;return section
                    offset := rva - section.VirtualAddress + section.PointerToRawData
                    return offset
                }
            }
        }

        rva_to_symbol_map:=Map()
        for o in symbols {
            rva_to_symbol_map[o.virtualAddress]:=o
        }

        IIDs:=[
            IID_IVirtualDesktopManagerInternal:=[],
            IID_IVirtualDesktopManager:=[],
            IID_IVirtualDesktop:=[],
            IID_IVirtualDesktopPinnedApps:=[],
            IID_IVirtualDesktopNotification:=[],
            IID_IVirtualDesktopNotificationService:=[],
        ]
        vftables:=[
            ["IVirtualDesktopManagerInternal",vftable_IVirtualDesktopManagerInternal:=[]],
            ["IVirtualDesktopManager",vftable_IVirtualDesktopManager:=[]],
            ["IVirtualDesktop",vftable_IVirtualDesktop:=[]],
            ["IVirtualDesktopPinnedApps",vftable_IVirtualDesktopPinnedApps:=[]],
            ["IVirtualDesktopNotification",vftable_IVirtualDesktopNotification:=[]],
            ["IVirtualDesktopNotificationService",vftable_IVirtualDesktopNotificationService:=[]],
        ]

        for o in symbols {
            ;IIDs
            if (o.name ~= "^IID_IVirtualDesktopManagerInternal\d*$") {
                IID_IVirtualDesktopManagerInternal.Push(o)
            }
            if (o.name ~= "^IID_IVirtualDesktopManager$") {
                IID_IVirtualDesktopManager.Push(o)
            }
            if (o.name ~= "^IID_IVirtualDesktop\d*$") {
                IID_IVirtualDesktop.Push(o)
            }
            if (o.name ~= "^IID_IVirtualDesktopPinnedApps$") {
                IID_IVirtualDesktopPinnedApps.Push(o)
            }
            if (o.name ~= "^IID_IVirtualDesktopNotification$") {
                IID_IVirtualDesktopNotification.Push(o)
            }
            if (o.name ~= "^IID_IVirtualDesktopNotificationService$") {
                IID_IVirtualDesktopNotificationService.Push(o)
            }
            ;vftables
            if (o.undecoratedName ~= "^const CVirtualDesktopManager::``vftable'.*IVirtualDesktopManagerInternal.*$") {
                vftable_IVirtualDesktopManagerInternal.Push(o)
            }
            if (o.undecoratedName ~= "^const VirtualDesktopsApi::``vftable'$") {
                vftable_IVirtualDesktopManager.Push(o)
            }
            if (o.undecoratedName ~= "^const CVirtualDesktop::``vftable'.*IVirtualDesktop\d*\b.*$") {
                vftable_IVirtualDesktop.Push(o)
            }
            if (o.undecoratedName ~= "^const VirtualPinnedAppsHandler::``vftable'.*IVirtualDesktopPinnedApps.*$") {
                vftable_IVirtualDesktopPinnedApps.Push(o)
            }
            if (o.undecoratedName ~= "^const CVirtualDesktopNotificationsDerived::``vftable'.*IVirtualDesktopNotification.*$") {
                vftable_IVirtualDesktopNotification.Push(o)
            }
            if (o.undecoratedName ~= "^const CVirtualDesktopNotificationsDerived::``vftable'$") {
                vftable_IVirtualDesktopNotificationService.Push(o)
            }
        }

        for a in IIDs {
            for o in a {
                offset:=get_offset_by_rva(sections,o.virtualAddress)
                toClip.=o.name "`n"
                ;toClip.=o.virtualAddress "`n"
                ;toClip.=o.length "`n"
                toClip.="{" ptr_to_guid(buf.Ptr+offset) "}`n"
                toClip.="`n"
            }
        }

        for name_and_a in vftables {
            interface_name:=name_and_a[1]
            a:=name_and_a[2]
            for o in a {
                offset:=get_offset_by_rva(sections,o.virtualAddress)
                toClip.=interface_name "`n"
                toClip.=o.name "`n"
                toClip.=o.undecoratedName "`n"
                toClip.="length: " o.length "`n"

                ptr:=offset
                end:=offset + o.length
                while (ptr < end) {
                    rva:=NumGet(buf,ptr,"Ptr") - ImageBase
                    try {
                        symbol:=rva_to_symbol_map[rva] ;threw at 22621.2215, IVirtualDesktopManagerInternal, A_Index=23
                        toClip.=interface_name "." (A_Index - 1) "`n"
                        toClip.=symbol.name "`n"
                        toClip.=symbol.undecoratedName "`n"
                    }
                    ptr+=0x8
                }
                toClip.="`n"
            }
        }

        ptr_to_guid(ptr) {
            guid_str:=Format("{:08x}-{:04x}-{:04x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",NumGet(ptr,"Uint"),NumGet(ptr+4,"UShort"),NumGet(ptr+6,"UShort"),NumGet(ptr+8,"UChar"),NumGet(ptr+9,"UChar"),NumGet(ptr+10,"UChar"),NumGet(ptr+11,"UChar"),NumGet(ptr+12,"UChar"),NumGet(ptr+13,"UChar"),NumGet(ptr+14,"UChar"),NumGet(ptr+15,"UChar"))
            return guid_str
        }
    }


    return toClip
}

extract_IID_from_same_folder(folderName) {
    dll_paths:=[]
    pdb_paths:=[]
    for fileName in ["actxprxy","twinui.pcshell"] {
        dll_paths.Push(folderName "\" fileName ".dll")
        pdb_paths.Push(folderName "\" fileName ".pdb")
    }
    return extract_IID(dll_paths,pdb_paths)
}

;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\17763.1")
;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\Windows Server 2019 - 17763.3650")

;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\Windows Server 2022 - 20348.2227")


A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\22000.51")
;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\22483.1011")
;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\22621.1778")
;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\22621.2215")
;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\23H2-22631.2715")
;A_Clipboard:=extract_IID_from_same_folder(A_LineFile "\..\22631.3085")
