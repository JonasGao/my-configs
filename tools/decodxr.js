function decode(url) {
  const removePrefix = url => {
    if (url.indexOf("ssr://") == 0) {
      return url.substring(6);
    }
    return url;
  };

  const decodeBase64 = data => {
    const buff = Buffer.from(data, "base64");
    return buff.toString("ascii");
  };

  const decodePassword = value => {
    if (value) {
      return decodeBase64(value)
    }
    return value
  }

  const decodeMainPart = (url, opt) => {
    let main = url;
    if (url.indexOf("/?") >= 0) {
      main = url.substring(0, url.indexOf("/?"));
    }
    const values = main.split(":");
    return Object.assign(opt, {
      host: values[0],
      port: values[1],
      cipher: values[3],
      password: decodePassword(values[5]),
      obfs: values[4],
      protocol: values[2]
    });
  };

  const decodeParams = (url, opt) => {
    if (url.indexOf("/?") < 0) {
      return opt;
    }
    const params = url.substring(url.indexOf("/?") + 2);
    return params.split("&").reduce((o, s) => {
      let [key, value] = s.split("=");
      if (value) {
        value = decodeBase64(value);
      }
      o[key] = value;
      return o;
    }, opt);
  };

  const decodeUrl = url => {
    return decodeParams(url, decodeMainPart(url, {}));
  };

  return decodeUrl(decodeBase64(removePrefix(url)));
}

const [, , input] = process.argv;

console.log(decode(input));
