
function decode(url) {

  const removePrefix = (url) => {
    if (url.indexOf("ssr://") == 0) {
      return url.substring(6)
    }
    return url
  }

  const decodeBase64 = (data) => {
    const buff = Buffer.from(data, 'base64')
    return buff.toString('ascii')
  }

  const decodeUrl = (url) => {
    if (url.indexOf("/?") >= 0) {
      const arr = url.split("/?")
      const part1 = arr[0].split(":")
      const part2 = arr[1].split("&").reduce((o, s) => {
        let [key, value] = s.split("=")
        if (value) {
          value = decodeBase64(value)
        }
        o[key] = value
        return o
      }, {})
      const opt = {
        ss: {
          host: part1[0],
          port: part1[1],
          cipher: part1[3],
          password: part1[5]
        },
        obfs:part1[4],
        obfsParam:part2['obfsparam'],
        protocol: part1[2],
        protocolParam: part2['protoparam'],
        group: part2['group']
      }
      return opt
    }
    return url
  }
  
  return decodeUrl(
    decodeBase64(
      removePrefix(url)
    )
  )
}

const [, , input] = process.argv

console.log(decode(input))
