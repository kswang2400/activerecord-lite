
class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |n|
      define_method(n)       {         instance_variable_get(:"@#{n}") }
      define_method("#{n}=") { |value| instance_variable_set(:"@#{n}", value) }  
    end
  end
end

# had to google a lot...