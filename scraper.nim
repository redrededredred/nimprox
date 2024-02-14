import std/httpclient
import std/htmlparser
import std/xmltree # To use '$' for XmlNode
import std/strtabs # To access XmlAttributes
import std/sequtils
import std/strutils
#[
    Simple Program for scraping a few
    free proxy websites.
]#

const
    tests: bool = true
    freeProxyCzUrl: string = "http://free-proxy.cz/en/proxylist/country/all/https/ping/level1"
    netzweltUrl: string = "https://www.netzwelt.de/proxy/index.html"
    badNetzweltData: array[3, string] = ["FoxyProxy", "IP", "Port"]
    maxTimeoutNetzwelt: int = 2000
let client: HttpClient = newHttpClient(userAgent = "nim")

type
    CzProxy = object
        address: string
        port: string
        country: string
        speed: int         # in kB/s
        uptime: 1.0..100.0 # in %
        responsetime: int  # in ms

    NetzweltProxy = object
        address: string
        port: string
        country: string


proc getFreeProxiesCz(client: HttpClient): seq[CzProxy] =
    let response: Response = client.get(freeProxyCzUrl)
    if response.code != Http200:
        return # Returning an empty seq@[] indecates failure
    echo response.body

proc getNetzweltProxies(client: HttpClient): seq[NetzweltProxy] =
    let response: Response = client.get(netzweltUrl)
    if response.code != Http200:
        return
    let tempFile = open("scrape.html", fmWrite)
    defer: tempFile.close()
    tempFile.write(response.body)
    var html = loadHtml("scrape.html")
    var rawData: seq[string] = @[]
    for tr in findAll(html, "tr"):
        for td in tr.items:
            if badNetzweltData.contains(td.innerText):
                continue
            rawData.add(td.innerText)
    let chunks: int = toInt(rawData.len / 5)
    for data in rawData.distribute(chunks):
        if "HTTP/HTTPS" in data:
            result.add(NetzweltProxy(address: data[0], port: data[1],
                    country: data[2]))

proc testProxySpeed(proxies: seq[NetzweltProxy]) =
    for proxy in proxies:
        try:
            var testClient: HttpClient = newHttpClient(proxy = newProxy("http://" & proxy.address & ":" & proxy.port), timeout = maxTimeoutNetzwelt)
            var res: Response = testClient.get("https://example.com")
            echo res.code
        except:
            echo "adw"

when tests:
    echo "Testing!"
    testProxySpeed(client.getNetzweltProxies()) 

