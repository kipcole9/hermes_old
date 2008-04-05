
module Blog
  ISO8601 = '%Y-%m-%d %H:%M:%S%Z'
  UPLOAD_DIR = "#{RAILS_ROOT}/tmp/uploads/"
  
  class Post < ActionWebService::Struct
    member :title,       :string
    member :link,        :string
    member :description, :string
    member :author,      :string
    member :category,    :string
    member :comments,    :string
    #member :guid,        :string
    member :postid,      :string
    #member :pubDate,     :string
    member :dateCreated, :string
    
    # Items supported for MoveableType API
    member :mt_allow_comments,  :string
    member :mt_allow_pings,     :bool
    member :mt_convert_breaks,  :string
    member :mt_text_more,       :string
    member :mt_excerpt,         :string
    member :mt_keywords,        :string
    member :mt_tb_ping_urls,    [:string]
  end

  class Category < ActionWebService::Struct
    member :description, :string
    member :htmlUrl,     :string
    member :rssUrl,      :string
  end
  
  class Filter < ActionWebService::Struct
    member :key,        :string
    member :label,      :string
  end
  
  class Trackback < ActionWebService::Struct
    member :pingTitle,  :string
    member :pingUrl,    :string
    member :pingIp,     :string
  end
  
  class Title < ActionWebService::Struct
    member :dateCreated,  :string
    member :userid,       :string
    member :postid,       :string
    member :title,        :string
  end
  
  class PostCategory < ActionWebService::Struct
    member :categoryName, :string
    member :categoryId,   :string
    member :isPrimary,    :bool
  end
  
  class MtCategory < ActionWebService::Struct
    member :categoryId,   :string
    member :categoryName, :string
  end
  
  class File < ActionWebService::Struct
    member :name,         :string
    member :bits,         :string
    member :type,         :string
  end
end