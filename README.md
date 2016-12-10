##Introduction
The NPR Corpus is a web application designed for use with linguistic research into the large body of conversational English transcripts amassed by the National Public Radio over the years. It is developed and maintained by Bryan Li in collaboration with the UCLA Language Processing Lab.

The beta version is currently hosted on Heroku at https://nprcorpus.herokuapp.com, and the full version will be deployed onto a UCLA webpage in early 2017. The beta version has about 5000 articles indexed from 2006 to 2007, and is quite usable. To deploy a local instance of the application, so that you may create a local database (faster + unlimited space), please follow the instructions below.

##Environment Setup
This application runs on Ruby on Rails and MongoDB. Once you have those installed, continue to the Local Installation section.

1. Install Ruby and Ruby on Rails:  
MacOS instructions with rbenv: https://gorails.com/setup/osx/10.11-el-capitan  (note: if brew install gnupg doesn't work, try ```brew install gnupg```)
Linux instructions with RVM: https://rvm.io/rvm/install  

2. Install MongoDB  
MacOS: https://docs.mongodb.com/v3.0/tutorial/install-mongodb-on-os-x/  
Linux: https://docs.mongodb.com/v3.0/administration/install-on-linux/ 

3. Start MongoDB in the background  
MacOS: ```brew services start mongodb```  
Linux: ```sudo service mongod start```

4. Clone the application locally  
Clone the project: ```git clone git@github.com:manestay/NPR-Corpus-Project.git```  
Change your directory to the folder that you cloned the project into, then install the required gems: ```bundle install```  
Seed the database: ```rake db:seed```

## Running the server
After steps 1-4, you have installed the project and its dependencies. To start the server, run ```rails server```  
Go to a browser and enter [localhost:3000](http://localhost:3000). You should see the NPR Corpus app running on your local machine.

## Downloading articles to your local database
The front end for the database downloading is not currently implemented, so in the meantime it can be done through rails console. In order to set up your app to make calls to the NPR API, you need an API key. See [their documentation](http://www.npr.org/api/index) on how to obtain one, or send an email to nprcorpus@gmail.com requesting the project's one. Once you have a key, type the following in the root directory:
```bash
mv .env.test .env  
echo "NPR_API_KEY = '{PUT KEY HERE}'" >> .env
```

To enter the console, make sure you are in the root directory of the application, and type ```rails console```  

Type the following commands into the console.  
1. Fetch the story_ids from NPR
Create a NPR Client object: ```@client = NPR::API::Client.new```  
Run the FetchIds script:
```ruby
fetcher = FetchIds.new(@client, start_date: 1.year.ago, duration: 1.month, file_name: 'import2016.txt')
fetcher.run
fetcher.export
```  
If you ```ls``` in a terminal outside of console, you should see a ```.txt``` file with the IDs in it. Each ID corresponds with an ID in the NPR library. Note that you can change the start_date and duration parameters above.

2. Add the IDs to the database
```ruby
id_add =  IdsToDb.new(@client)
id_add.parse_file('import2016.txt')
id_add.write_ids
```
After running the last command, you'll see the stories being added in the console. If you refresh your localhost:3000, you will see that the articles have been added.

MORE TO COME...
##Links
http://www.linguistics.ucla.edu/people/harris/lab/lab.html

http://www.npr.org/api/index.php

https://github.com/bricker/npr
