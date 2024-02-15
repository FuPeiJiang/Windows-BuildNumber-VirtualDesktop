import { lstatSync, readFileSync, readdirSync } from 'fs'

const needle=Buffer.from("D7C641189D4FC042AF418747538F10E5","hex") //"D7C641189D4FC042AF418747538F10E5"=IID_IApplicationViewCollection

const dir = "C:/Windows/System32"
const names=readdirSync(dir).filter(v=>{
    if (!v.toLowerCase().endsWith(".dll")) {
        return false
    }

    let isFile = false
    try {
        isFile = lstatSync(`${dir}/${v}`).isFile()
    } catch {
    }
    return isFile
})

for (const v of names) {
    const buf = readFileSync(`${dir}/${v}`)
    if (buf.indexOf(needle) > -1) {
        console.log(v)
    }
}

debugger
//OneCoreUAPCommonProxyStub //IID_IApplicationViewCollection //{1841c6d7-4f9d-42c0-af41-8747538f10e5}
//OneCoreUAPCommonProxyStub //IID_IApplicationView //{372e1d3b-38d3-42e4-a15b-8ab2b178f513}
//OneCoreUAPCommonProxyStub //IID_IObjectArray //{92ca9dcd-5622-4bba-a805-5e9f541bd8c9}
//unchanging