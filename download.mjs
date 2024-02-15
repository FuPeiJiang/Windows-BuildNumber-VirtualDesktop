import { copyFileSync, existsSync, lstatSync, readFileSync, writeFileSync } from "fs";
import { request } from "https";

const __dirname = import.meta.dirname;


//const dir = `${__dirname}/fromJavascript`
const dir = `${__dirname}/23H2-22631.2715`
for (const name of [
//"AboveLockAppHost",
//"actxprxy",
//"ConsentUxClient",
//"HolographicExtensions",
//"HoloSI.PCShell",
"OneCoreUAPCommonProxyStub",
//"RDXTaskFactory",
//"Taskbar",
//"TaskFlowDataEngine",
//"twinui",
//"twinui.pcshell",
//"Windows.Cortana.Desktop",
//"windows.immersiveshell.serviceprovider",
//"Windows.Internal.CapturePicker.Desktop",
//"windows.storage",
//"Windows.UI.Immersive",
]) {
    const source_path = `C:/Windows/System32/${name}.dll`
    const path_dll = `${dir}/${name}.dll`
    const path_pdb = `${dir}/${name}.pdb`
    if (!existsSync(path_dll)) {
        copyFileSync(source_path,path_dll)
    }
    if (!existsSync(path_pdb) || lstatSync(path_pdb).size === 0) {
        const buf = readFileSync(path_dll)
        const str = buf.toString("binary").toLowerCase()
        const fileName = `${name.toLowerCase()}.pdb`
        const pos = str.indexOf(fileName) - 20
        const guid = `${buf.toString("hex",pos+3,pos+4)}${buf.toString("hex",pos+2,pos+3)}${buf.toString("hex",pos+1,pos+2)}${buf.toString("hex",pos+0,pos+1)}${buf.toString("hex",pos+5,pos+6)}${buf.toString("hex",pos+4,pos+5)}${buf.toString("hex",pos+7,pos+8)}${buf.toString("hex",pos+6,pos+7)}${buf.toString("hex",pos+8,pos+16)}`.toUpperCase()
        const url_path = `/download/symbols/${name}.pdb/${guid}1/${name}.pdb`

        const downloadedBuf = await new Promise(resolve=>{
            const req = request({
                method:"GET",
                path:url_path,
                hostname:"msdl.microsoft.com",
            },res=>{
                if (res.statusCode === 302) {
                    res.destroy()
                    const url = res.headers.location
                    const pos_slash = url.indexOf("/",8)
                    const path = url.slice(pos_slash)
                    const hostname = url.slice(8,pos_slash)

                    const req = request({
                        method:"GET",
                        path:path,
                        hostname:hostname,
                    },res=>{
                        const toConcat=[]
                        res.on("data",chunk=>{
                            toConcat.push(chunk)
                        })
                        res.on("end",()=>{
                            const lol = Buffer.concat(toConcat)
                            resolve(lol)
                        })
                    })
                    req.end()

                } else {
                    debugger
                }
            })
            req.end()
        })

        writeFileSync(path_pdb,downloadedBuf)
    }
}