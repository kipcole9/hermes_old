# 
# Moveable Type API
#
require 'blog'
class MovableTypeAPI < ActionWebService::API::Base
  inflect_names false
  
  api_method :supportedTextFilters, :returns => [[Blog::Filter]]
  
  api_method :supportedMethods, :returns => [[:string]]
  
  api_method :setPostCategories, :returns => [:bool], :expects => [
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:categories=>[Blog::PostCategory]},
    ]
    
  api_method :publishPost, :returns => [:bool], :expects => [
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
    ]
  
  api_method :getTrackbackPings, :returns => [[Blog::Trackback]], :expects => [
    {:postid=>:string},
    ]
    
  api_method :getRecentPostTitles, :returns => [[Blog::Title]], :expects => [
    {:blogid=>:string},
    {:username=>:string},
    {:password=>:string},
    {:numberOfPosts=>:int},
    ]
    
  api_method :getPostCategories, :returns => [[Blog::PostCategory]], :expects => [
    {:postid=>:string},
    {:username=>:string},
    {:password=>:string},
    ]
    
  api_method :getCategoryList, :returns => [[Blog::MtCategory]], :expects => [
      {:blogid=>:string},
      {:username=>:string},
      {:password=>:string},
    ]
end
