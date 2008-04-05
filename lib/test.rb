module Test
  def howbig
    a = Asset.find(5)
    bits = 1
    num = 1
    while bits < 257
      a.publications = num
      a.save!
      a = Asset.find(5)
      puts "Bits: #{bits} => #{a.publications}"
      bits += 1
      num = num * 2
    end
  end
end