require 'hermes_keywords_import'
include HermesKeywordsImport

module CvUpdates
  def do_updates
  
    # India
    add_child  "India", ["Andaman and Nicobar Islands", "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar",
                    "Chandigarh", "Chhattisgarh", "Dadra and Nagar Haveli", "Daman and Diu", "Delhi", "Goa", "Gujarat",
                    "Haryana", "Himachal Pradesh", "Jammu and Kashmir", "Jharkhand", "Karnataka", "Kerala", "Lakshadweep",
                    "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Orissa", "Puducherry",
                    "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"]
                
    # Punjab state
    add_child  "Punjab", "Amritsar"
    add_child  "Amritsar", "Golden Temple"
    add_child "Punjab", "Wagah"

    # Tamil Nadu
    add_child "Tamil Nadu", "Chennai"
    add_synonym  "Chennai", "Madras"

    # Delhi
    add_child "Delhi", "New Delhi"
    add_child "New Delhi", "India Gate"
    add_child "New Delhi", "Lotus Temple"
    add_child "New Delhi", "Red Fort"

    # Maharashtra
    add_child "Maharashtra", "Mumbai"
    add_synonym  "Mumbai", "Bombay"
    add_child "Mumbai", "Gateway of India"
    add_child "Gateway of India", "Marathi"
    add_child "Maharashtra", "Pune"
                
    # Uttar Pradesh
    add_child "Uttar Pradesh", "Agra"
    add_child "Agra", "Taj Mahal"
    add_child "Uttar Pradesh", "Varanasi"
    add_synonym  "Varanasi", "Benaras"
    add_synonym  "Varanasi", "Kashi"
    add_child "Uttar Pradesh", "Sarnath"

    # Rajasthan
    add_child "Rajasthan", "Jaipur"
    add_child "Rajasthan", "Pushkar"

    # West Bengal
    add_child "West Bengal", "Kolkata"
    add_synonym  "Kolkata", "Calcutta"

    # Karnataka
    add_child "Karnataka", "Bengalaru"
    add_synonym  "Bengalaru", "Bangalore"
    add_synonym  "Bengalaru", "Bengalooru"

    # Andhra Pradesh
    add_child "Andhra Pradesh", "Hyderabad"

    # Australia
    add_child  "australia", ["New South Wales", "Queensland", "Victoria", "Western Australia", "Northern Territory", "Tasmania", 
                            "Australian Captital Territory"]
                        
    add_child  "new south wales", ["Sydney", "Newcastle"]

    # Vietnam
    add_child  "vietnam", "Ho Chi Minh City"
    add_synonym "Ho Chi Minh City", "Saigon"
    add_synonym "Ho Chi Minh City", "HCMC"
    add_child  "vietnam", "Ha Noi"
    add_synonym "Ha Noi", "Hanoi"
    add_child  "vietnam", "Hoi An"
    add_child  "vietnam", "Sa Pa"
    add_synonym "Sa Pa", "Sapa"
    add_child  "vietnam", "Nha Trang"
    add_child  "vietnam", "Hue"
    add_child  "vietnam", "Da Nang"
    add_child  "vietnam", "Nha Trang"
    add_child "Vietnam", "Bac Ha"
    add_synonym  "Vietnam", "Viet Nam"

    # Laos
    add_child "laos", "Viang Chang"
    add_synonym  "Viang Chang", "Vientiane"
    add_child "laos", "Luang Prabang"
    add_child "laos", "Vang Vieng"

    # Cambodia
    add_child "cambodia", "Phnom Penh"
    add_child "cambodia", "Siem Reap"
    add_child "Siem Reap", "Angkor Archaeological Park"
    add_synonym  "Angkor Archaeological Park", "Angkor"
    add_child "Angkor Archaeological Park", "Angkor Wat"
    add_child "Angkor Archaeological Park", "Angkor Thom"
    add_child "Angkor Thom", "Bayon Temple"
    add_child "Angkor Archaeological Park", "Ta Phrom"
    add_child "Angkor Archaeological Park", "Banteay Srei"
    add_synonym  "Banteay Srei", "Banteay Srey"

    # Myanmar
    add_synonym  "Myanmar", "Burma"
    add_child "Myanmar", "Yangon"
    add_synonym  "Yangon", "Rangoon"
    add_child "Yangon", "Shwedagon Pagada"
    add_child "Myanmar", "Bagan"

    # Indonesia
    add_child "Indonesia", "Bali"
    add_child "Bali", "Ubud"
    add_child "Bali", "Denpasar"

    # Thailand
    add_child "Thailand", "Bangkok"
    add_child "Bangkok", "Benjakitti Park"
    add_child "Thailand", "Phuket"
    add_child "Thailand", "Udon Thani"
    add_child "Thailand", "Chang Mai"
    add_child "Thailand", "Chang Rai"


    # Japan

    # Honshu Island
    add_child "japan",  ["Hokkaido", "Honshu", "Shikoku", "Kyushu", "Okinawa"]

    ## Chugoku region
    add_child "honshu", "Chugoku"
    add_child "Chugoku", "Hiroshima-ken" 
    add_child "Hiroshima-ken", "Hiroshima-shi"
    add_synonym  "Hiroshima-shi", "Hiroshima"
    add_child "Chugoku", "Okayama-ken" 
    add_child "Okayama-ken", "Okayama-shi"
    add_synonym  "Okayama-shi", "Okayama"
    add_child "Chugoku", "Shimane-ken" 
    add_child "Shimane-ken", "Matsue-shi"
    add_synonym  "Matsue-shi", "Matsue"
    add_child "Chugoku", "Tottori-ken" 
    add_child "Tottori-ken", "Tottori-shi"
    add_synonym  "Tottori-shi", "Tottori"
    add_child "Chugoku", "Yamaguchi-ken"
    add_child "Yamaguchi-ken", "Yamaguchi-shi"
    add_synonym  "Yamaguchi-shi", "Yamaguchi"

    ## Chubu Region
    add_child "Honshu", "Chubu"
    add_child "Chubu", "Aichi-ken" 
    add_child "Aichi-ken", "Nagoya-shi"
    add_synonym  "Nagoya-shi", "Nagoya"
    add_child "Chubu", "Fukui-ken"
    add_child "Fukui-ken", "Fukui-shi"
    add_synonym  "Fukui-shi", "Fukui"
    add_child "Chubu", "Gifu-ken"
    add_child "Gifu-ken", "Gifu-shi"
    add_synonym  "Gifu-shi", "Gifu"
    add_child "Chubu", "Ishikawa-ken"
    add_child "Ishikawa-ken", "Kanazawa-shi"
    add_synonym  "Kanazawa-shi", "Kanazawa"
    add_child "Chubu", "Nagano-ken"
    add_child "Nagano-ken", "Nagano-shi"
    add_child "Nagano-shi", "Nagano"
    add_child "Chubu", "Niigata-ken"
    add_child "Niigata-ken", "Niigata-shi"
    add_synonym  "Niigata-shi", "Niigata"
    add_child "Chubu", "Toyama-ken"
    add_child "Toyama-ken", "Toyama-shi"
    add_synonym  "Toyama-shi", "Toyama"
    add_child "Chubu", "Shizuoka-ken"
    add_child "Shizuoka-ken" , "Shizuoka-shi"
    add_synonym  "Shizuoka-shi", "Shizuoka"
    add_child "Chubu", "Yamanashi-ken"
    add_child "Yamanashi-ken", "Kofu-shi"
    add_synonym  "Kofu-shi", "Kofu"

    ## Kanto Region
    add_child "Honshu", "Kanto"
    add_child "Kanto", "Chiba-ken"
    add_child  "Chiba-ken", "Chiba-shi"
    add_synonym  "Chiba-shi", "Chiba"
    add_child "Kanto", "Gunma-ken"
    add_child "Gunma-ken", "Maebashi-shi"
    add_synonym  "Maebashi-shi", "Maebashi"
    add_child "Kanto", "Ibaraki-ken"
    add_child "Ibaraki-ken", "Mito-shi"
    add_synonym  "Mito-shi", "Mito"
    add_child "Kanto", "Kanagawa-ken"
    add_child "Kanagawa-ken", "Yokohama-shi"
    add_synonym  "Yokohama-shi", "Yokohama"
    add_child "Kanto", "Saitama-ken"
    add_child "Saitama-ken", "Urawa-shi"
    add_synonym  "Urawa-shi", "Urawa"
    add_child "Kanto", "Tochigi-ken"
    add_child "Tochigi-ken", "Utsunomiya-shi"
    add_synonym  "Utsunomiya-shi", "Utsunomiya"
    add_child "Kanto", "Tokyo-to"
    add_child "Tokyo-to", "Tokyo"

    ## Kinki Region
    add_child "honshu", "Kinki" 
    add_child "kinki", "Hyogo-ken"
    add_child "Hyogo-ken", "Kobe-shi"
    add_synonym  "Kobe-shi", "Kobe"
    add_child "kinki", "Kyoto-fu"
    add_child "Kyoto-fu", "Kyoto-shi"
    add_synonym  "Kyoto-shi", "Kyoto"
    add_child "kinki", "Mie-ken"
    add_child "Mie-ken", "Tsu-shi"
    add_synonym  "Tsu-shi", "Tsu"
    add_child "kinki", "Nara-ken"
    add_child "Nara-ken", "Nara-shi"
    add_synonym  "Nara-shi", "Nara"
    add_child "kinki", "Osaka-fu"
    add_child "Osaka-fu", "Osaka-shi"
    add_synonym  "Osaka-shi", "Osaka"
    add_child "kinki", "Shiga-ken"
    add_child "Shiga-ken", "Otsu-shi"
    add_synonym  "Otsu-shi", "Otsu"
    add_child "Shiga-ken", "Kusatsu"
    add_child "kinki", "Wakayama-ken"
    add_child "Wakayama-ken", "Wakayama-shi"
    add_synonym  "Wakayama-shi", "Wakayama"

    ## Tohoku Region
    add_child "Honshu", "Tohoku"
    add_child "Tohoku", "Akita-ken"
    add_child "Akita-ken", "Akita-shi"
    add_synonym  "Akita-shi", "Akita"
    add_child "Tohoku", "Aomori-ken"
    add_child "Aomori-ken", "Aomori-shi"
    add_synonym  "Aomori-shi", "Aomori"
    add_child "Tohoku", "Fukushima-ken"
    add_child "Fukushima-ken", "Fukushima-shi"
    add_synonym  "Fukushima-shi", "Fukushima"
    add_child "Tohoku", "Iwate-ken"
    add_child "Iwate-ken", "Morioka-shi"
    add_synonym  "Morioka-shi", "Morioka"
    add_child "Tohoku", "Miyagi-ken"
    add_child "Miyagi-ken", "Sendai-shi"
    add_synonym  "Sendai-shi", "Sendai"
    add_child "Tohoku", "Yamagata-ken"
    add_child "Yamagata-ken", "Yamagata-shi"
    add_synonym  "Yamagata-shi", "Yamagata"

    # Hokkaido Island
    add_child "Hokkaido", "Sapporo-shi"
    add_synonym  "Sapporo-shi", "Sapporo"
    add_child "Hokkaido", "Niseko"
    add_child "Niseko", "Niseko-Hirafu Ski Resort"

    # Kyushu lies south of Honshu and west of Shikoku. The island is home to the following 7 prefectures:
    add_child "Kyushu", "Fukuoka-ken"
    add_child "Fukuoka-ken", "Fukuoka-shi"
    add_synonym  "Fukuoka-shi", "Fukuoka"
    add_child "Kyushu", "Kagoshima-ken"
    add_child "Kagoshima-ken", "Kagoshima-shi"
    add_synonym  "Kagoshima-shi", "Kagoshima"
    add_child "Kyushu", "Kumamoto-ken"
    add_child "Kumamoto-ken", "Kumamoto-shi"
    add_synonym  "Kumamoto-shi", "Kumamoto"
    add_child "Kyushu", "Miyazaki-ken"
    add_child "Miyazaki-ken", "Miyazaki-shi"
    add_synonym  "Miyazaki-shi", "Miyazaki"
    add_child "Kyushu", "Nagasaki-ken"
    add_child "Nagasaki-ken", "Nagasaki-shi"
    add_synonym  "Nagasaki-shi", "Nagasaki"
    add_child "Kyushu", "Oita-ken"
    add_child "Oita-ken", "Oita-shi"
    add_synonym  "Oita-shi", "Oita"
    add_child "Kyushu", "Saga-ken"
    add_child "Saga-ken", "Saga-shi"
    add_synonym  "Saga-shi", "Saga"

    # Shikoku lies south of Honshu and east of Kyushu. The island is home to the following 4 prefectures:
    add_child "Shikoku", "Ehime-ken"
    add_child "Ehime-ken", "Matsuyama-shi"
    add_synonym  "Matsuyama-shi", "Matsuyama"
    add_child "Shikoku", "Kagawa-ken"
    add_child "Kagawa-ken", "Takamatsu-shi"
    add_synonym  "Takamatsu-shi", "Takamatsu"
    add_child "Shikoku", "Kochi-ken"
    add_child "Kochi-ken", "Kochi-shi"
    add_synonym  "Kochi-shi", "Kochi"
    add_child "Shikoku", "Tokushima-ken"
    add_child "Tokushima-ken", "Tokushima-shi"

    # Okinawa-ken Prefecture (prefectural capital is Naha-shi on the island of Okinawa)
    add_child "Okinawa", "Okinawa-ken"
    add_child "Okinawa-ken", "Naha-shi"
    add_synonym  "Naha-shi", "Naha"

    ## Others
    add_child "ubmrella", "parasol"
    add_synonym  "Fall", "Autumn"
    add_synonym  "barbeque", "bbq"
    add_child "flatware", "chopsticks"
    add_child "team sports", "Cricket"
    add_child "team sports", "Rugby"
    add_child "rugby", "Rugby League"
    add_child "rugby", "Rugby Union"
    add_child "team sports", "Australian Rules Football"
    add_child "church", "cloister"
    add_child "church", "crypt"
    add_child "church", "monastery"
    add_child "train", "very fast train"
    add_child "very fast train", "maglev"
    add_child "very fast train", "Shinkansen"
    add_synonym  "Shinkansen", "Bullet Train"
    add_child "very fast train", "Train Grand Vitesse"
    add_synonym  "Train Grand Vitesse", "TGV"
    add_child "chef", "cook"
    add_child "chef", "sous chef"
    add_child "chef", "pastry chef"
    add_child "boats", "houseboats"
    add_child "jet", "Boeing 747"
    add_synonym  "Boeing 747", "jumbo jet"
    add_child "jet", "Airbus A380"
    add_child "jet", "Boeing 777"
    add_child "chef", "saucier"
    add_child "scenery>water", "lagoon"
    add_child "plants", "[PLANT PARTS]"
    add_child "[PLANT PARTS]", "leaf"
    add_child "[PLANT PARTS]", "roots"
    add_child "[PLANT PARTS]", "trunk"
    add_child "[PLANT PARTS]", "branch"
    add_child "religion", "monk"
    add_child "railroad", "tram"

  end
end