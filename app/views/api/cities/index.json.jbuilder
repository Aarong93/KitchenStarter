json.array! @cities do |city|
	json.extract! city, :name, :id
end
