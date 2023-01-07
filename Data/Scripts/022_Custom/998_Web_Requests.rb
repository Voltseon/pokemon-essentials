def pbWebRequest(request)
  request[:PLAYER_ID] = $player.id
  return pbPostDataPHP("http://75.119.152.89/", request)
end

def pbPostDataPHP(url, postdata, filename = nil, depth = 0)
  if url[/^http:\/\/([^\/]+)(.*)$/] || url[/^https:\/\/([^\/]+)(.*)$/]
    host = $1
    path = $2
    path = "/" if path.length==0
    userAgent = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.14) Gecko/2009082707 Firefox/3.0.14 bot"
    body = postdata.map { |key, value|
      keyString   = key.to_s
      valueString = value.to_s
      keyString.gsub!(/[^a-zA-Z0-9_\.\-]/n) { |s| sprintf('%%%02x', s[0]) }
      #valueString.gsub!(/[^a-zA-Z0-9_\.\-]/n) { |s| sprintf('%%%02x', s[0]) }
      next "#{keyString}=#{valueString}"
    }.join('&')
    ret = HTTPLite.post_body(
      url,
      body,
      "application/x-www-form-urlencoded",
      {
        "Host" => host, # might not be necessary
        "Proxy-Connection" => "Close",
        "Pragma" => "no-cache",
        "User-Agent" => userAgent
      }
    ) rescue "couldnt post"
    return ret if !ret.is_a?(Hash)
    return "couldnt connect" if ret[:status] != 200
    return ret[:body] if !filename
    File.open(filename, "wb"){|f|f.write(ret[:body])}
    return "didnt get anything"
  end
  return "didnt url"
end