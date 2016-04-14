class IgnController < ApplicationController
  layout "ign"
  
  def articles
    request = IGNRequest.new
    @articles = request.articles($startIndex.to_s, $RES_PER_PAGE)
  end

  def videos
    request = IGNRequest.new
    @videos = request.videos($startIndex.to_i, $RES_PER_PAGE)
  end
end

#HTTP class
class IGNRequest
  include HTTParty
  
  base_uri 'http://ign-apis.herokuapp.com'
  
  def initialize()
    @results = []
  end
  
  def articles(startIndex, count)
    response = self.class.get("/articles?startIndex=#{startIndex}&count=#{count}")
    if response.success?
      dataArray = response["data"]
      
      for data in dataArray
        meta = data["metadata"]
        title = meta["headline"]
        description = meta["subHeadline"]
        thumbnail = data["thumbnail"]
        slug = meta["slug"]
        publishDate = meta["publishDate"]
        url = articleURL(slug, publishDate)
        info = IGNInfo.new(title, description, thumbnail, url, "")
        @results.push(info)
      end
      
      return @results
      
    else
      raise response.response
    end
  end
  
  def videos(startIndex, count)
    response = self.class.get("/videos?startIndex=#{startIndex}&count=#{count}")
    if response.success?
      dataArray = response["data"]
      
      for data in dataArray
        meta = data["metadata"]
        title = meta["name"]
        description = meta["description"]
        thumbnail = data["thumbnail"]
        url = meta["url"]
        durString = meta["duration"]
        duration = Time.at(durString.to_i).utc.strftime("%M:%S")
        info = IGNInfo.new(title, description, thumbnail, url, duration)
        @results.push(info)
      end
      
      return @results
    else
      raise response.response
    end
  end
  
  def articleURL(slug, date)
    baseURL = "http://www.ign.com/articles"
    splitDate = date.split(/-|T/)
    year = splitDate[0]
    month = splitDate[1]
    day = splitDate[2]
    return "#{baseURL}/#{year}/#{month}/#{day}/#{slug}"
  end
end


#Store info to be displayed
class IGNInfo
  attr_accessor :title, :description, :thumbnail, :url, :duration
  
  def initialize(title, description, thumbnail, url, duration)
    @title = title
    @description = description
    @thumbnail = thumbnail
    @url = url
    @duration = duration
  end
end