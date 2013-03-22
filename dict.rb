#author mmsssmm1@gmail.com
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'htmlentities'
require 'iconv'
require 'json'

words=ARGV[0]


def trim(text)
 return text.gsub( /\r\n/, "|" ).gsub(/\|\|/,"\n").gsub("|","")
end
class EnWord
 @@phonetic="\n\n音标:\n"
 @@explanation = "\n\n解释:\n"
 @@etyma = "\n\n词根:\n"
 @@analogy = "\n\n近义词:\n"
 @@sentence = "\n\n例句:\n"
 @@auth_sentence = "\n\n权威例句:\n"
 attr_accessor :word,:pho,:exp,:etyma,:ana,:sen,:ausent
 def to_hash
    Hash[instance_variables.map { |var| [var[1..-1].to_sym, instance_variable_get(var)] }]
 end
 def get_json
  return to_hash.to_json 
 end
 def get_original
  return word + "\n" + @@phonetic + pho + @@explanation + exp + @@etyma + etyma + @@analogy + ana + @@sentence + sen + @@auth_sentence + ausent

 end
end
class Youdao
 def query(word, block)
  pages = Nokogiri::HTML(open("http://dict.youdao.com/dp/dp?block="+block+"&q="+word+"&keyfrom=mdict.3.0.1.iphone&vendor=AppStore&version=iphone_3.0&version=iphone_3.0"))
  return pages
 end

  
 # get the base explanation of a word
 
 def getBase(word)
  begin
   page_base = query(word,"")
   if page_base.css('span').to_s.length==0 || page_base.css('ul').to_s.length==0 then
    return ""
   end
   rst_pho = page_base.css('span')[0].text
   rst_exp = page_base.css('ul')[0].text.to_s 
   return rst_pho+"|"+rst_exp.gsub(/\s+/, "")
  rescue
   return ""
  end
 end
 #get the etyma
 def getEtyma(word)
  begin
   page_base = query(word,"relword")
   if page_base.css('p').length==0 then 
    return ""
   end
   etyma=Iconv.conv("ISO-8859-1","UTF-8",page_base.css('p').css('strong')[0].text)+"\n"
   etyma+=Iconv.conv("ISO-8859-1","UTF-8",page_base.css('ul').text).to_s.gsub(/\t+/, "")
   return etyma
  rescue
   return "" 
  end
 end
 def getAnalogy(word)
  begin
   page_base = query(word,"synonyms")
   if page_base.css('ul').length==0 then
    return
   end
   analogy=Iconv.conv("ISO-8859-1","UTF-8",page_base.css('ul').text).to_s.gsub(/\t+/, "")
   return analogy
  rescue
   return ""
  end
 end
 def getSentence(word)
  begin
   page_base = query(word,"lj")
   sentence= Iconv.conv("ISO-8859-1","UTF-8",page_base.css('li')[0].text).to_s.gsub(/\t+|\r\n/, "").lines.to_a[0]+"\n"
   sentence+=Iconv.conv("ISO-8859-1","UTF-8",page_base.css('li').css('div')[0].text).to_s.gsub(/\t+/, "")
  #puts @@sentence+":\n"+Iconv.conv("ISO-8859-1","UTF-8",page_base.css('li')[0].text).to_s.gsub(/\t+|\r\n/, "").lines.to_a[0].gsub(word,"<font color='blue'>"+word+"<b></b></font>")
   #puts Iconv.conv("ISO-8859-1","UTF-8",page_base.css('li').css('div')[0].text).to_s.gsub(/\t+/, "")
   return sentence
  rescue
   return ""
  end
 end
 def getAuthSentence(word)
  begin
   page_base = query(word,"authsent")
   if page_base.css('li').to_s.length==0 then
    return ""
   end
   auth_sent=Iconv.conv("ISO-8859-1","UTF-8",page_base.css('li')[0].text).to_s.gsub(/\t+|\r\n/, "").lines.to_a[0]
   return auth_sent
   #puts @@auth_sentence+":\n"+Iconv.conv("ISO-8859-1","UTF-8",page_base.css('li')[0].text).to_s.gsub(/\t+|\r\n/, "").lines.to_a[0].gsub(word,"<font color='blue'>"+word+"<b></b></font>")
   #puts "\n"
  rescue
   return ""
  end
 end
end

querist = Youdao.new

enWord = EnWord.new
base=querist.getBase(words)
enWord.word=words
enWord.pho=trim(base.split("|")[0])
enWord.exp=trim(base.split("|")[1])
enWord.etyma=trim(querist.getEtyma(words))
enWord.ana=trim(querist.getAnalogy(words))
enWord.sen=trim(querist.getSentence(words).gsub(/\n/,"|"))
enWord.ausent=trim(querist.getAuthSentence(words))
if ARGV[1] == "json" then
 puts enWord.get_json
end
if ARGV[1] != "json" then
 puts enWord.get_original
end
