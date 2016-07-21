 #default.list.stories.each { |s| p s.id }
 
def get_story_ids(response) # pass in a query
  ids = []
  response.list.stories.each do |story|
    ids << story.id
   end
  ids
end
    