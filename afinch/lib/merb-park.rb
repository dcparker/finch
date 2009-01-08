$:.push(File.dirname(__FILE__) / 'merb-park' / 'lib')
module MerbPark
  [ :Controller,
    :Model,
    :DM,
    :Ext,
    :Acl
  ].each {|c| autoload(c,"merb-park/#{c.to_s.snake_case}")}
end
